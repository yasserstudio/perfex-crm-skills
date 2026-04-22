---
name: perfex-core-apis
description: Use whenever the user is working inside a Perfex CRM codebase and touches `get_option`, `update_option`, `add_option`, `delete_option`, `hooks()`, `do_action`, `apply_filters`, `register_activation_hook`, `$this->load`, `get_instance()`, `$CI`, `db_prefix()`, auth helpers like `is_staff_logged_in` / `get_staff_user_id` / `staff_can`, or `_l()`. Also trigger when the user says "my Perfex get_option returns empty", "the hook isn't firing", "how do I hook into Perfex", "module-wide option", "Perfex helper function", "CI loader inside Perfex", or "$CI doesn't work outside a controller". This skill prevents the #1 Perfex bug — silently using `get_option('key', 'default')` which ignores the second argument.
license: MIT
metadata:
  author: yasserstudio
  version: "1.3.0"
---

# Perfex Core APIs

You are a senior Perfex CRM developer who knows its CodeIgniter-3 foundation cold. Your job on any Perfex task is to reach for Perfex's own abstractions — options, hooks, the CI loader, auth helpers — before writing raw SQL or raw CI3, and to catch the specific traps that silently break custom Perfex code.

Perfex sits on CodeIgniter 3. It adds its own options layer, hook system, and auth helpers on top. Use the Perfex helpers — not raw CI or raw SQL — whenever one exists.

## The `get_option` trap (critical)

```php
// ❌ WRONG — Perfex get_option does NOT accept a default parameter
$value = get_option('my_module_setting', 'fallback');

// ✅ RIGHT
$value = get_option('my_module_setting') ?: 'fallback';
```

The second argument is silently ignored. You get `''` (empty string) when the option doesn't exist, which then evaluates truthy-false and passes the `?:`. This is the single most common bug in custom Perfex code.

Set options with:
```php
update_option('my_module_setting', $value);
add_option('my_module_setting', $default);  // only inserts if missing
```

## The CI loader inside Perfex

Inside a controller or model, `$this` is the CI super-object. Elsewhere, use `get_instance()`:

```php
$CI =& get_instance();
$CI->load->model('my_module/my_model');
$CI->db->where('id', 1)->get(db_prefix() . 'mytable');
```

`db_prefix()` returns the configured table prefix (usually `tbl`). Always use it — never hardcode `tbl`.

## Hook system

Perfex hooks mirror WordPress's action/filter pattern:

```php
// In your module's module_name.php
hooks()->add_action('app_init', 'my_module_init');
hooks()->add_filter('before_invoice_added', 'my_module_filter_invoice');

function my_module_init() { /* runs on every request, after app bootstraps */ }
function my_module_filter_invoice($data) { return $data; }
```

Trigger your own:
```php
hooks()->do_action('my_module_after_save', $id);
$data = hooks()->apply_filters('my_module_data', $data);
```

Common core hooks to know:
- `app_init` — every request, after core bootstrap
- `app_admin_head`, `app_admin_footer` — inject into admin layout
- `app_customers_head`, `app_customers_footer` — client area
- **Individual contacts** (people): `contact_created`, `contact_updated`, `before_delete_contact`, `contact_status_changed`
- **Client companies**: `after_client_created`, `client_updated`, `before_client_deleted`, `client_status_changed`
- `clients_register_form_fields` — add fields to client signup

**Note the naming inconsistency:** Perfex core uses *both* `after_<thing>_created` *and* plain `<thing>_created` forms inconsistently across entities (e.g., `after_client_created` but `contact_created`). When in doubt, grep the Perfex core source for `do_action\('`. Some community tutorials reference `after_contact_added` — that hook **does not exist in core**; the real name is `contact_created`.

## Auth helpers

```php
is_staff_logged_in()        // bool
is_client_logged_in()       // bool
get_staff_user_id()         // int | null
get_contact_user_id()       // int | null (contact = a person on a client company)
get_client_user_id()        // int | null
staff_can('view', 'invoices', $staff_id);  // permission check
```

Never trust `$_SESSION` directly. Always go through these helpers — they handle impersonation and API key auth correctly.

## CI loader inside hook callbacks

Hook callbacks run outside the current controller. To use the DB or models:

```php
function my_module_init() {
    $CI =& get_instance();
    $CI->load->model('my_module/my_model');
    // ...
}
```

## Logging

Use CI's `log_message()` — writes to `application/logs/`:

```php
log_message('error', 'My module: something broke: ' . $e->getMessage());
log_message('debug', 'My module: processed ' . $count . ' items');
```

**Never** `file_put_contents` to dev paths for production debugging. PII and secrets will leak.

## Common helper reference

| Helper | Purpose |
|---|---|
| `db_prefix()` | Table prefix (use for every query) |
| `site_url($path)` | Absolute URL inside the install |
| `admin_url($path)` | Absolute URL to admin area |
| `_l('key', $args)` | Translate a language key |
| `format_money($amount)` | Currency-format with user locale |
| `get_company_name($client_id)` | Company name from client ID |
| `html_purify($html)` | HTMLPurifier-clean user-supplied HTML |
| `app_generate_hash()` | Random secure hash (password-resets etc.) |

## Gotchas

- **`$this->db->last_query()`** only works if `save_queries => TRUE` in config. In production it may return empty.
- **`$this->db->affected_rows()`** — always check this after atomic UPDATEs for race-safe token consumption (see `perfex-security`).
- Model names are loaded singular by default; if a filename is `My_model.php` it loads as `$this->my_model`. Match the filename's case exactly or loader fails silently on case-sensitive filesystems (not macOS, but yes Linux production).
- **`total_rows()` as a UI gate** — Perfex core views sometimes use `total_rows(db_prefix() . 'table', ['column' => $val]) > 0` to conditionally show form fields or UI elements (e.g., only showing a currency rate field if at least one client uses that currency). This creates chicken-and-egg problems: you can't configure a feature until a dependent record exists. When you see a `total_rows()` check gating a UI element in a core view, consider whether it should be removed or relaxed for your use case.
- **`_l()` always runs `sprintf()` internally, even without a label.** `application/helpers/general_helper.php::_l()` unconditionally calls `sprintf($raw_string, $label)` where `$label` defaults to `''`. This means for a lang string like `'Hey %s,'`, calling `_l('greeting')` with NO second arg returns `'Hey ,'` — the `%s` is silently consumed with empty string. The common mistake is wrapping in another sprintf: `sprintf(_l('greeting'), $name)` — by the time sprintf sees the string, there's no `%s` left, so `$name` is dropped. **Correct pattern: pass args to `_l()` directly.** `_l('greeting', $name)` for single-arg, `_l('key', [$a, $b])` for multi-arg (uses `vsprintf` when `$label` is an array). PHP 8 throws `ArgumentCountError` on mismatch which Perfex catches → returns raw string unchanged; that's why `sprintf(_l('key'), $a, $b)` *accidentally* works for multi-%s keys but not single-%s.

## Related skills

- **`perfex-module-dev`** — module lifecycle, `install.php`, controllers, and activation hooks all use the helpers in this skill.
- **`perfex-database`** — when you drop from Perfex helpers down to raw SQL or schema design.
- **`perfex-security`** — `app_generate_hash()` for tokens, `staff_can()` for permissions, and CSRF rules.

## Upstream docs

- Perfex action hooks: https://help.perfexcrm.com/action-hooks/
- Perfex module basics: https://help.perfexcrm.com/module-basics/
- CI3 loader: https://codeigniter.com/userguide3/libraries/loader.html
- CI3 database: https://codeigniter.com/userguide3/database/
