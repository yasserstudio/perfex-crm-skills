---
name: perfex-email
description: Use when sending transactional emails from a Perfex module — using send_simple_email, rendering email templates, handling admin-recipient fallback, or implementing a retry queue for failed sends.
---

# Perfex Email System

Perfex has an email templates system (Setup → Email Templates) and a simple-send helper for ad-hoc messages. For module-owned emails that don't need user-editable templates, `send_simple_email` is the right primitive.

## The 3 send paths

| Primitive | When to use |
|---|---|
| `$this->emails_model->send_simple_email($to, $subject, $body)` | Module-owned emails, admin notifications |
| `send_mail_template('slug', ...)` | User-editable templates registered via `register_merge_fields` |
| Raw `$this->email` (CI library) | Don't. Use one of the above. |

## send_simple_email pattern

```php
public function notify_admin($contact_id, $event) {
    $this->load->model('emails_model');

    $to = $this->admin_email();
    if (!$to) return;

    $data = [
        'contact_name' => get_contact_full_name($contact_id),
        'event'        => $event,
    ];

    $body = $this->_render_email_template('admin_notification', $data);

    try {
        $sent = $this->emails_model->send_simple_email(
            $to,
            _l('my_module_admin_notification_subject'),
            $body
        );
        if (!$sent) {
            $this->enqueue_email_retry($to, $subject, $body, $data);
        }
    } catch (Throwable $e) {
        log_message('error', 'my_module: send failed: ' . $e->getMessage());
        $this->enqueue_email_retry($to, $subject, $body, $data);
    }
}
```

**Email failures MUST NOT fail the user flow.** Wrap in try/catch, log the error, continue. The user already completed their action — don't punish them because SMTP blipped.

## Admin-recipient fallback chain

When sending "notify the admin", fall back through configured options:

```php
private function admin_email() {
    return get_option('my_module_admin_email')
        ?: get_option('contact_form_notification_email')
        ?: get_option('smtp_email')
        ?: null;
}
```

Remember: `get_option('key') ?: fallback` — never pass a default as a second arg.

## Render email template with merge

Put templates in `modules/my_module/views/emails/`. Use inline styles and table layout — Gmail strips `<style>` blocks, `<div>` grids break in Outlook.

```php
private function _render_email_template($template, array $data = []) {
    extract($data);
    ob_start();
    include(__DIR__ . '/../views/emails/' . $template . '.php');
    return ob_get_clean();
}
```

Template example (`views/emails/admin_notification.php`):
```html
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4;padding:24px;">
    <tr><td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:8px;padding:32px;font-family:Arial,sans-serif;">
            <tr><td>
                <h1 style="margin:0 0 16px 0;font-size:20px;color:#111;">
                    New event from <?= htmlspecialchars($contact_name) ?>
                </h1>
                <p style="margin:0;color:#333;line-height:1.5;">
                    <?= htmlspecialchars($event) ?>
                </p>
            </td></tr>
        </table>
    </td></tr>
</table>
```

Always `htmlspecialchars()` user data. A newline in a name isn't a security issue but a `<script>` tag in one is.

## Retry queue pattern

SMTP can transiently fail. Don't drop the email — enqueue it:

### Schema

```sql
CREATE TABLE `tblmymodule_email_retries` (
    `id`            INT NOT NULL AUTO_INCREMENT,
    `to_email`      VARCHAR(191) NOT NULL,
    `subject`       VARCHAR(255) NOT NULL,
    `body`          LONGTEXT NOT NULL,
    `context_json`  TEXT NULL,
    `attempts`      TINYINT NOT NULL DEFAULT 0,
    `last_error`    TEXT NULL,
    `next_try_at`   DATETIME NOT NULL,
    `created_at`    DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_next_try` (`next_try_at`, `attempts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Enqueue

```php
private function enqueue_email_retry($to, $subject, $body, $context = []) {
    $this->db->insert(db_prefix() . 'mymodule_email_retries', [
        'to_email'     => $to,
        'subject'      => $subject,
        'body'         => $body,
        'context_json' => json_encode($context),
        'attempts'     => 0,
        'next_try_at'  => date('Y-m-d H:i:s', strtotime('+5 minutes')),
        'created_at'   => date('Y-m-d H:i:s'),
    ]);
}
```

### Process via cron

Register a Perfex cron hook:

```php
// module_name.php
hooks()->add_action('after_cron_run', 'my_module_process_email_retries');

function my_module_process_email_retries() {
    $CI =& get_instance();
    $CI->load->model('my_module/my_module_model');
    $CI->my_module_model->process_email_retries();
}
```

In the model:
```php
public function process_email_retries() {
    $this->load->model('emails_model');

    // Prune > 7 days old
    $this->db->where('created_at <', date('Y-m-d H:i:s', strtotime('-7 days')));
    $this->db->delete(db_prefix() . 'mymodule_email_retries');

    // Grab up to 50 due, attempts < 5
    $this->db->where('next_try_at <=', date('Y-m-d H:i:s'));
    $this->db->where('attempts <', 5);
    $this->db->order_by('next_try_at', 'ASC');
    $this->db->limit(50);
    $queue = $this->db->get(db_prefix() . 'mymodule_email_retries')->result();

    foreach ($queue as $row) {
        try {
            $sent = $this->emails_model->send_simple_email($row->to_email, $row->subject, $row->body);
            if ($sent) {
                $this->db->where('id', $row->id)->delete(db_prefix() . 'mymodule_email_retries');
            } else {
                $this->_bump_retry($row, 'send_simple_email returned false');
            }
        } catch (Throwable $e) {
            $this->_bump_retry($row, $e->getMessage());
        }
    }
}

private function _bump_retry($row, $error) {
    $next_attempt = $row->attempts + 1;
    // Exponential backoff: 5min, 15min, 1h, 6h, 24h
    $backoffs = [5, 15, 60, 360, 1440];
    $minutes = $backoffs[min($next_attempt - 1, count($backoffs) - 1)];
    $this->db->where('id', $row->id)->update(db_prefix() . 'mymodule_email_retries', [
        'attempts'    => $next_attempt,
        'last_error'  => $error,
        'next_try_at' => date('Y-m-d H:i:s', strtotime("+{$minutes} minutes")),
    ]);
}
```

Cap at 5 attempts. After that, alert the admin (another email!) or leave for manual review via the prune-at-7-days rule.

## SMTP configuration check

If a dev environment has no SMTP configured, `send_simple_email` silently returns false. In a module's activation hook, warn:
```php
if (!get_option('smtp_host')) {
    set_alert('warning', 'My Module: SMTP is not configured. Emails will queue but never send.');
}
```

## Upstream docs

- Perfex email templates: https://help.perfexcrm.com/email-templates/
- CI3 email library (underlying): https://codeigniter.com/userguide3/libraries/email.html
