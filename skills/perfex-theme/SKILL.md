---
name: perfex-theme
description: Use whenever the user is building or debugging a Perfex CRM custom client-area theme — files under `assets/themes/<theme>/` and `application/views/themes/<theme>/`, asset injection via `app_customers_head` / `app_customers_footer` / `app_admin_head` / `app_admin_footer` hooks, overriding core views, dark-mode with `[data-theme="dark"]` plus anti-FOUC inline `<head>` scripts, RTL/Arabic support, theme language strings via `json_encode(_l(...))`, or the jQuery Validate bug where a submit button's `name` attribute is stripped from POST (breaks "Pay Now" / "Save Draft" button detection). Trigger on "Perfex theme", "customer area theme", "client area theme", "jQuery Validate submit", `rel="noopener noreferrer"`, cache-busting theme assets via `filemtime()`, or stale CSS after deploy.
license: MIT
metadata:
  author: yasserstudio
  version: "1.0.0"
---

# Perfex Custom Themes & Client Area

Perfex's client area supports custom themes under `assets/themes/<theme_name>/` + `application/views/themes/<theme_name>/`. Themes override core views and can inject their own CSS/JS via hooks.

## Theme folder layout

```
assets/themes/my_theme/
├── css/
│   └── theme.css
├── js/
│   └── theme.js
└── images/
    └── logo.svg

application/views/themes/my_theme/
├── includes/
│   └── head.php
├── layouts/
│   └── default.php
└── (override any core view by matching path)
```

Activate via Setup → Settings → Customer Area Theme.

## Asset loading — use the hooks, not raw `<link>`

```php
// In your theme's functions.php or a companion module
hooks()->add_action('app_customers_head', 'my_theme_inject_css');
hooks()->add_action('app_customers_footer', 'my_theme_inject_js');

function my_theme_inject_css() {
    $url = base_url('assets/themes/my_theme/css/theme.css');
    echo '<link rel="stylesheet" href="' . $url . '?v=' . filemtime(FCPATH . 'assets/themes/my_theme/css/theme.css') . '">';
}

function my_theme_inject_js() {
    $url = base_url('assets/themes/my_theme/js/theme.js');
    echo '<script src="' . $url . '?v=' . filemtime(FCPATH . 'assets/themes/my_theme/js/theme.js') . '" defer></script>';
}
```

Why cache-bust with `filemtime()`: Perfex does NOT version theme assets. Without a cache-buster, browsers will serve stale CSS to signed-in users across deploys.

## jQuery Validate + submit button name — the "Pay Now" bug

Perfex uses jQuery Validate on most forms. jQuery Validate's default behaviour **strips the submit button's `name` attribute from the POST body** when submitting programmatically. This breaks forms that rely on detecting which button was clicked:

```html
<form method="post">
    <button type="submit" name="pay_now" value="1">Pay Now</button>
    <button type="submit" name="save_draft" value="1">Save</button>
</form>
```

PHP sees neither `$_POST['pay_now']` nor `$_POST['save_draft']` on submit.

### Fix: mirror intent into a hidden input

```html
<form method="post">
    <input type="hidden" name="action" id="form_action" value="">
    <button type="submit" onclick="document.getElementById('form_action').value='pay_now'">Pay Now</button>
    <button type="submit" onclick="document.getElementById('form_action').value='save_draft'">Save</button>
</form>
```

Then check `$_POST['action']` server-side. This is the pattern used in fennec360-v2's Pay Now fix.

## Overriding a core view

Perfex resolves views by this order:
1. `application/views/themes/<active_theme>/<path>`
2. `application/views/<path>`

To override the client dashboard, copy `application/views/themes/perfex/clients/dashboard.php` (or the default theme) to `application/views/themes/my_theme/clients/dashboard.php` and edit.

**Don't edit core views in place.** They'll be blown away on Perfex update.

## Language strings in themes

Themes can't register language keys directly (no `module_name.php` hook point). Either:
- Package the theme with a companion module that registers keys, OR
- Use inline strings and maintain a manual i18n dict in JS:
  ```php
  <script>
  window.THEME_STRINGS = <?= json_encode([
      'save' => _l('save'),
      'cancel' => _l('cancel'),
      // ... using core keys that already exist
  ]) ?>;
  </script>
  ```

For custom module-owned JS strings, use `json_encode(_l('key'))` — never raw concat — to avoid quote-escape bugs and XSS.

## Dark mode pattern

Use semantic CSS custom properties, switch via `[data-theme="dark"]`:

```css
:root {
    --bg-primary: #fff;
    --text-primary: #111;
    --brand-primary: #2A5189;
}
[data-theme="dark"] {
    --bg-primary: #0f1115;
    --text-primary: #e8e8e8;
    --brand-primary: #8eaadd;  /* lift lighter in dark for contrast */
}
```

Apply `data-theme` attribute BEFORE first paint to avoid FOUC:

```html
<head>
    <script>
    (function() {
        var t = localStorage.getItem('my_theme_mode');
        if (t) document.documentElement.setAttribute('data-theme', t);
    })();
</script>
</head>
```

Toggle logic lives in your theme's JS; persist choice under a namespaced key like `my_theme_mode`.

## RTL / Arabic support

Perfex supports RTL via language settings. In your theme CSS:

```css
[dir="rtl"] .my-component {
    /* flip margins, text-align */
}
```

Ship both LTR and RTL icon variants if your icons have directional meaning (chevrons, arrows).

## Forms with Bootstrap + Perfex

Perfex ships Bootstrap 3.x in the client area and admin. For new themes, you can ship a newer Bootstrap but watch for conflicts with inline admin code. Scope newer styles by adding a wrapper class on your custom views.

## Accessibility baseline

- Every `<input>` needs an `id` + `<label for="...">`.
- `aria-describedby` linking to error containers.
- Decorative icons: `aria-hidden="true"`.
- Required: `<span aria-label="required">*</span>`.
- Error containers: `role="alert" aria-live="polite"`.
- Add `<main id="main-content">` + a skip link.

## Debugging checklist

| Symptom | Likely cause |
|---|---|
| Stale CSS after deploy | Missing `?v=filemtime()` cache-bust |
| POST missing submit button name | jQuery Validate stripping; use hidden action input |
| View not picked up | Wrong theme active, or path case mismatch on Linux |
| Language key shows raw (`onboarding_save` literal) | Language file not loaded, or cached by CI loader |
| FOUC on dark mode | Theme attribute applied after first paint — move to `<head>` inline script |

## Upstream docs

- Perfex theme dev: https://help.perfexcrm.com/custom-theme/
- jQuery Validate: https://jqueryvalidation.org/
