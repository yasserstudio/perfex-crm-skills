---
name: perfex-theme
description: Use whenever the user is building or debugging a Perfex CRM custom client-area theme — files under `assets/themes/<theme>/` and `application/views/themes/<theme>/`, asset injection via `app_customers_head`/`app_customers_footer`/`app_admin_head`/`app_admin_footer` hooks, overriding core views, dark mode with `[data-theme="dark"]` plus anti-FOUC `<head>` scripts, RTL/Arabic support, or the jQuery Validate bug where a submit button's `name` is stripped from POST (breaks "Pay Now" / "Save Draft" detection). Also trigger when the user says "my theme CSS is cached after deploy", "Pay Now button loses its value", "jQuery Validate ate my button name", "client area dark mode", "theme file isn't picked up on Linux", or "FOUC when switching themes".
license: MIT
metadata:
  author: yasserstudio
  version: "1.0.0"
---

# Perfex Custom Themes & Client Area

You are a Perfex CRM theme developer. Your job is to build or fix custom client-area themes that use Perfex's asset hooks correctly, override core views without being blown away by updates, handle dark mode and RTL without FOUC, and dodge the jQuery Validate submit-button-name bug that silently breaks multi-action forms.

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

## Overriding Perfex's Bootstrap 3 — specificity wars

Perfex ships Bootstrap 3.x across admin and client areas, plus inline styles on many core views. Your custom theme CSS will lose most specificity battles by default because:

1. Perfex loads its CSS *after* your custom theme injection (depending on hook order), which means same-specificity selectors favor Perfex.
2. Many Perfex core components use inline `style=""` attributes, which only `!important` overrides.
3. Bootstrap 3 uses `.btn-primary`, `.form-control` etc. — shallow single-class selectors that your `:root` semantic variables won't touch.

### Strategy 1 — scope with a wrapper class (preferred)

Add a theme-root class to your overridden views and scope everything:

```html
<!-- application/views/themes/my_theme/layouts/default.php -->
<body class="my-theme-v2">
```

```css
.my-theme-v2 .btn-primary {
    background: var(--brand-primary);
    border-color: var(--brand-primary);
}
.my-theme-v2 .form-control {
    border-radius: 8px;
    border-color: #e2e8f0;
}
```

Two classes of specificity (`.wrapper .target`) beats Bootstrap's single class (`.target`) without needing `!important`. Scales to any depth.

### Strategy 2 — `!important` with a namespaced helper class

When you can't wrap the parent (e.g., Perfex renders the `<body>` from core):

```css
.my-theme-btn--override {
    background: var(--brand-primary) !important;
}
```

Apply via override of the specific button's view. `!important` on a single namespaced class is safer than `!important` sprinkled across `.btn-primary` globally — the namespace makes it grep-able and removable later.

### Strategy 3 — CSS layer (modern browsers only)

If you know your audience uses modern browsers, `@layer` lets Perfex's styles sit in one layer and yours in a higher one:

```css
@layer perfex, mytheme;
@layer mytheme {
    .btn-primary { background: var(--brand-primary); }
}
```

Doesn't need Perfex to opt in — your `@layer mytheme` wins against any unlayered Perfex CSS. **Caveat:** client-area IE/Safari <15.4 fall back to normal specificity. Perfex admin is power-user territory and usually Chrome/Firefox, but check your audience.

### Anti-patterns

- **Blanket `!important` on every rule.** Quickly becomes a specificity ceiling you can't escape — next override needs `!important` too, then the next. Scope with a wrapper class instead.
- **Using `#wrapper` or other core-internal IDs as your specificity anchor.** Perfex may rename these across versions; your CSS silently breaks.
- **Editing Perfex's `application/views/themes/perfex/` directly.** Blown away on upgrade. Copy to your theme's subtree and edit there — the override mechanism is designed for this.

## Debugging checklist

| Symptom | Likely cause |
|---|---|
| Stale CSS after deploy | Missing `?v=filemtime()` cache-bust |
| POST missing submit button name | jQuery Validate stripping; use hidden action input |
| View not picked up | Wrong theme active, or path case mismatch on Linux |
| Language key shows raw (`onboarding_save` literal) | Language file not loaded, or cached by CI loader |
| FOUC on dark mode | Theme attribute applied after first paint — move to `<head>` inline script |

## Related skills

- **`perfex-core-apis`** — `app_customers_head` / `app_admin_head` hooks are the supported asset-injection points.
- **`perfex-security`** — `target="_blank"` + `rel="noopener noreferrer"` and CSRF exclusions for theme-level webhook-style routes.
- **`perfex-module-dev`** — themes usually ship with a companion module for registering language keys and hooks.

## Upstream docs

- Perfex customization guides: https://help.perfexcrm.com/category/customization/
- Applying custom CSS styles (`custom.css` + Theme Style module): https://help.perfexcrm.com/applying-custom-css-styles/
- jQuery Validate: https://jqueryvalidation.org/
