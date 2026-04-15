---
name: perfex-security
description: Use whenever a Perfex CRM task touches security-sensitive code — issuing or consuming single-use tokens (password reset, magic link, confirmation), race-safe atomic UPDATE with `affected_rows()` check, handling user-controlled redirect URLs (`?next=`, `?redirect=`, `?return_to=`), rate-limiting an AJAX endpoint that leaks boolean state, cross-module model loads, logging PII, adding `target="_blank"` links, or excluding a webhook from CSRF. Also trigger when the user says "my magic link works twice", "password reset is racy", "someone can enumerate users by email", "open redirect in my module", "CSRF blocking my webhook", "rate limit this endpoint", or mentions "TOCTOU", "enumeration", `html_purify`, or `app_generate_hash()`. Every rule here exists because its absence caused a real Perfex production incident.
license: MIT
metadata:
  author: yasserstudio
  version: "1.1.0"
---

# Perfex Security Patterns

You are a Perfex CRM security engineer. Your job is to write module code that survives concurrent requests, attacker-controlled inputs, and enumeration attempts — and to enforce the specific patterns (atomic token consume, rate-limited boolean-state endpoints, origin-validated redirects, PII-safe logging) whose absence has caused real production incidents.

Patterns distilled from production Perfex deployments. Each one exists because an absence caused a real incident.

## 1. Open-redirect prevention

Any endpoint that redirects based on user input must validate the target.

```php
// ❌ WRONG — anyone can craft ?next=https://evil.com
$next = $this->input->get('next');
redirect($next);

// ✅ RIGHT — same-origin only, or a known relative path
$next = $this->input->get('next');
if (!$next || !preg_match('#^/[^/]#', $next)) {
    $next = admin_url();  // safe default
}
redirect($next);
```

Rules:
- Allow only relative paths starting with a single `/`.
- If you must allow absolute URLs, whitelist against `site_url()`:
  ```php
  if (strpos($next, site_url()) !== 0) $next = site_url();
  ```
- Protocol-relative URLs (`//evil.com`) are absolute — the check above rejects them via the second char.

## 2. One-time token consume — race-safe pattern

Tokens (password reset, magic-link login, confirmation links) must be single-use under concurrency.

```php
// ✅ Atomic UPDATE with WHERE used=0, then check affected_rows
public function consume_token($token) {
    $this->db->where('token', $token);
    $this->db->where('used', 0);
    $this->db->where('expires_at >=', date('Y-m-d H:i:s'));
    $this->db->update(db_prefix() . 'mymodule_tokens', [
        'used'    => 1,
        'used_at' => date('Y-m-d H:i:s'),
    ]);

    // affected_rows() === 1 proves WE consumed it, not a concurrent request
    return $this->db->affected_rows() === 1;
}
```

Never SELECT-then-UPDATE — that's a TOCTOU race. Two tabs opened simultaneously will both pass the SELECT and both execute the action.

## 3. Token issuance — don't over-rotate

Issuing a new token should NOT invalidate prior unused ones. Single-use + TTL is sufficient. Rotating invalidates magic links the user already clicked on in their email client, causing support tickets.

```php
public function issue_token($contact_id) {
    $token = app_generate_hash();  // Perfex's secure random
    $this->db->insert(db_prefix() . 'mymodule_tokens', [
        'contact_id' => $contact_id,
        'token'      => $token,
        'expires_at' => date('Y-m-d H:i:s', strtotime('+2 hours')),
        'used'       => 0,
        'created_at' => date('Y-m-d H:i:s'),
    ]);
    return $token;
}
```

Clean up expired tokens via a cron (`app_init` + once-per-day flag) rather than on every issue.

## 4. Rate limit boolean-state endpoints

Any AJAX endpoint that returns yes/no for an attacker-controlled input is an enumeration oracle. Common offenders:
- "Check if email exists" on signup
- "Check if username is taken"
- "Check if coupon is valid"

```php
public function email_exists() {
    if (!$this->rate_limit_ok($this->input->ip_address(), 'email_exists', 10, 60)) {
        $this->output->set_status_header(429);
        return $this->output->set_output(json_encode(['error' => 'Too many requests']));
    }
    // ... actual check
}

private function rate_limit_ok($key, $bucket, $max, $window_seconds) {
    // Implement with tbl<module>_rate_limits or a memory store.
    // Reject when count($bucket, $key) in last $window_seconds >= $max.
}
```

Rule of thumb: 10 attempts per 60s per IP is plenty for legitimate use, painful for enumeration.

## 5. Cross-module dependencies

Other modules may be uninstalled. Guard with `file_exists`:

```php
// ❌ fatal error if `billing` module is uninstalled
$this->load->model('billing/billing_model');

// ✅ defensive
$other_model = APPPATH . 'modules/billing/models/Billing_model.php';
if (file_exists($other_model)) {
    $this->load->model('billing/billing_model');
    $this->billing_model->do_something();
} else {
    log_message('info', 'my_module: billing module not installed, skipping');
}
```

## 6. PII in logs — never leak

```php
// ❌ NEVER
file_put_contents('/tmp/debug.log', print_r($user, true));

// ❌ Also bad — /tmp survives between requests on some hosts, get rotated nowhere
file_put_contents(APPPATH . 'logs/my_debug.log', $email . "\n");

// ✅ CI's logger respects threshold + rotation
log_message('debug', 'my_module: processed user id=' . $user_id);
```

Rules:
- Log user IDs, never email/phone/address/DOB.
- Never log passwords, tokens, card numbers, or their hashes.
- Production logs must be readable by ops but not public — check that `application/logs/` is behind a deny-from-all `.htaccess`.

## 7. `target="_blank"` links

Every `target="_blank"` needs `rel="noopener noreferrer"`. No exceptions.

```html
<!-- ❌ reverse-tabnabbing -->
<a href="https://external.com" target="_blank">External</a>

<!-- ✅ -->
<a href="https://external.com" target="_blank" rel="noopener noreferrer">External</a>
```

Applies to admin and client-area views.

## 8. CSRF

Perfex has CSRF built in (`config/config.php` → `$config['csrf_protection'] = TRUE`). It injects tokens into forms automatically via CI. BUT:

- Raw AJAX requests must include the CSRF token manually: read from `csrf_hash()` / `get_cookie('csrf_cookie_name')`.
- Webhook endpoints hit by external services need CSRF **excluded**. Add to `csrf_exclude_uris` in `config.php` — keyed per environment, not globally.

## 9. Input validation — don't trust client

CI's form validation library is your friend:
```php
$this->form_validation->set_rules('email', 'Email', 'required|valid_email|max_length[191]');
$this->form_validation->set_rules('amount', 'Amount', 'required|numeric|greater_than[0]');
if (!$this->form_validation->run()) {
    show_error(validation_errors(), 400);
    return;
}
```

Never `$this->input->post('amount')` then stuff it into an UPDATE without type-check.

## 10. HTML output

`html_purify()` over raw output of user-supplied HTML. `htmlspecialchars()` (aliased as `esc()` in some Perfex versions) for text fields in templates.

## Related skills

- **`perfex-core-apis`** — `app_generate_hash()` for secure random, `staff_can()` for permission checks, CI's session + CSRF libraries.
- **`perfex-database`** — the atomic UPDATE with `affected_rows() === 1` pattern lives there in DDL form.
- **`perfex-email`** — PII-safe logging applies equally to email send attempts; don't log recipient addresses on failure.
- **`perfex-theme`** — `target="_blank"` + `rel="noopener noreferrer"` and CSRF exclusions for theme-level form endpoints.

## Upstream refs

- Perfex module security (direct-access prevention, path-traversal guards): https://help.perfexcrm.com/module-security/
- OWASP token design: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- CI3 security: https://codeigniter.com/userguide3/libraries/security.html
