---
name: perfex-module-dev
description: Use whenever the user is creating, modifying, or debugging a Perfex CRM module — anything under `modules/<module_name>/` including `module_name.php`, `install.php`, `uninstall.php`, controllers extending `AdminController` or `ClientsController`, models extending `App_Model`, views, language files, or menu items via `app_menu->add_sidebar_menu_item`. Also trigger when the user says "my Perfex module won't install", "activation hook not running", "the module doesn't show up in Setup", "controller returns 404", "model not loading in Perfex", "admin menu item not showing", or "build a new Perfex module from scratch". Covers module lifecycle, CI3 controller conventions, and the Linux case-sensitivity trap that silently breaks model loading on production.
license: MIT
metadata:
  author: yasserstudio
  version: "1.1.0"
---

# Perfex Module Development

You are a Perfex CRM module architect. Your job is to scaffold modules that respect Perfex's lifecycle — activation/deactivation hooks, idempotent installs, correctly-named controllers and models, and Perfex's menu and permission conventions — so they survive across Perfex upgrades and work identically on macOS dev and Linux production.

A Perfex module is a self-contained folder in `modules/<module_name>/` that registers controllers, models, views, language keys, and DB tables through Perfex's module lifecycle. Modules are activated from Setup → Modules in the admin.

## Minimum module structure

```
modules/my_module/
├── my_module.php              # entry point: hooks, menu registration, activation/deactivation
├── install.php                # DDL for module-owned tables, initial options
├── uninstall.php              # drop tables, delete options (optional but recommended)
├── controllers/
│   ├── My_module.php          # admin controller (class MUST match filename, capitalized)
│   └── clients/
│       └── My_module.php      # client-area controller
├── models/
│   └── My_module_model.php    # class MUST match: class My_module_model extends App_Model
├── views/
│   ├── index.php
│   └── clients/
│       └── index.php
├── language/
│   ├── english.php            # returns `$lang` array
│   ├── french.php
│   └── arabic.php
├── assets/
│   ├── css/
│   └── js/
└── config/
    └── my_module.php          # optional config array
```

## Module entry file (`my_module.php`)

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

/*
Module Name: My Module
Description: What it does
Version: 1.0.0
Requires at least: 2.9.*
Author: Your Name
*/

define('MY_MODULE_NAME', 'my_module');

hooks()->add_action('admin_init', 'my_module_init_menu_items');
hooks()->add_action('app_init', 'my_module_load_language');

register_activation_hook(MY_MODULE_NAME, 'my_module_activation_hook');
register_deactivation_hook(MY_MODULE_NAME, 'my_module_deactivation_hook');
register_uninstall_hook(MY_MODULE_NAME, 'my_module_uninstall');

function my_module_activation_hook() {
    require_once(__DIR__ . '/install.php');
}

function my_module_init_menu_items() {
    $CI =& get_instance();
    $CI->app_menu->add_sidebar_menu_item('my-module', [
        'name'     => _l('my_module'),
        'href'     => admin_url('my_module'),
        'position' => 30,
        'icon'     => 'fa fa-cogs',
    ]);
}

function my_module_load_language() {
    $CI =& get_instance();
    $CI->lang->load('my_module/my_module');
}
```

The comment block at the top is **not optional** — Perfex parses it to display module metadata. Missing `Version:` and the module won't show up as installable.

## Controller pattern

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

class My_module extends AdminController {
    public function __construct() {
        parent::__construct();
        $this->load->model('my_module_model');
    }

    public function index() {
        if (!has_permission('my_module', '', 'view')) {
            access_denied('my_module');
        }
        $data['title'] = _l('my_module');
        $data['items'] = $this->my_module_model->get();
        $this->load->view('my_module/index', $data);
    }
}
```

- Admin controllers extend `AdminController`.
- Client area controllers extend `ClientsController`.
- API controllers extend `REST_Controller`.
- **Controller class name MUST match filename**, capitalized. `my_module.php` → `class My_module`.

## Routes

Perfex auto-routes based on CI convention: `modules/my_module/controllers/My_module.php::index()` is reachable at `admin/my_module`. For custom routes, edit `application/config/routes.php` OR use `hooks()->add_filter('app_routes', ...)`:

```php
hooks()->add_filter('app_routes', 'my_module_routes');

function my_module_routes($routes) {
    $routes['my_module/custom/(:num)'] = 'my_module/custom/$1';
    return $routes;
}
```

## Views

Pass data to views as an array:
```php
$data['foo'] = 'bar';
$this->load->view('my_module/index', $data);
```

Inside `views/my_module/index.php`:
```php
<?php init_head(); ?>
<div id="wrapper">
    <div class="content">
        <h1><?= $title ?></h1>
    </div>
</div>
<?php init_tail(); ?>
```

`init_head()` and `init_tail()` inject the admin shell. Skip them on partials/AJAX responses.

## Language files

```php
// modules/my_module/language/english/my_module_lang.php
$lang['my_module']                = 'My Module';
$lang['my_module_save']           = 'Save';
$lang['my_module_confirm_delete'] = 'Delete this item?';
```

**Never** leave a closing `?>` tag in a language file — if you append keys programmatically later, the closing tag will break the append. This is explicitly a Perfex convention.

Load a file with `$this->lang->load('my_module/my_module');`.

**CI loader caches by filename.** If you force-reload a language file for multi-locale switching, use direct `include()` and merge into `$this->lang->language` yourself — `$this->lang->load()` will return cached strings on second call.

## Adding to the Setup → Modules list

No action needed. Any folder in `modules/` with a valid header comment block shows up automatically. The activation link runs `install.php` via `register_activation_hook()`.

## Uninstalling

```php
// uninstall.php
defined('BASEPATH') or exit('No direct script access allowed');

$CI =& get_instance();
$CI->db->query('DROP TABLE IF EXISTS ' . db_prefix() . 'my_module_items');
delete_option('my_module_setting');
```

## Module version bumping

Bump `Version:` in the header comment whenever you change install.php. Perfex stores installed version in `tbloptions` (key `my_module_module`) and runs an upgrade path if versions differ — you must implement that path yourself.

## Inter-module dependencies

Perfex has no formal dependency system. If your module depends on another module's model or helpers, you own the graceful-degradation path.

### Declaring the dependency (for humans)

Add it to your module's header comment so admins know:

```php
/*
Module Name: My Module
Description: Sends custom invoices based on Billing module data.
Requires Module: billing
Version: 1.0.0
*/
```

`Requires Module:` is **not enforced** by Perfex — it's documentation for the admin. You must still handle the runtime case where the required module is missing.

### Runtime load with defensive guard

```php
// ✅ Guard every cross-module load
$other_path = APPPATH . 'modules/billing/models/Billing_model.php';
if (!file_exists($other_path)) {
    log_message('info', 'my_module: billing module not installed, feature disabled');
    return;
}
$this->load->model('billing/billing_model');
$this->billing_model->do_something();
```

### Activation-order problem

Modules activate in the order the admin clicks them. If `my_module` activates before `billing`, your `app_init` hook runs but `billing/billing_model` doesn't exist yet. Two patterns:

1. **Lazy-load on use.** Don't call the other module in `app_init`; wait until a real request needs it. Then the `file_exists` guard protects you.
2. **Check both activation orders.** If your activation hook needs the other module, gate it:
   ```php
   function my_module_activation_hook() {
       if (!file_exists(APPPATH . 'modules/billing/module.php')) {
           set_alert('warning', 'My Module: install and activate Billing first, then reactivate My Module.');
           return;
       }
       require_once(__DIR__ . '/install.php');
   }
   ```

### When the other module uninstalls

Perfex doesn't fire a "module X uninstalled" hook to dependent modules. The only safe pattern is: **every cross-module call is guarded.** There is no way to register a disable-callback. Assume the other module can vanish between any two requests.

### Don't hardcode paths across modules

```php
// ❌ fragile — breaks if the admin renames the module
include(APPPATH . 'modules/billing/helpers/billing_helper.php');

// ✅ use the loader which respects the module system
$this->load->helper('billing/billing');
```

## Common pitfalls

- **Capitalization**: Linux production is case-sensitive. `my_model.php` loads as `$this->my_model`, but `My_model.php` works on Mac and fails on Linux if you call `$this->load->model('my_model')` vs `$this->load->model('My_model')` incorrectly.
- **Circular dependencies**: If your module loads another module's model, wrap with `file_exists(APPPATH . 'modules/other/models/Other_model.php')` — users may uninstall `other` while your module still references it.
- **Permissions**: Register permissions via `register_staff_capabilities()` in your activation hook, or the ACL will silently deny.

## Related skills

- **`perfex-core-apis`** — every module registers hooks and uses the CI loader patterns documented there.
- **`perfex-database`** — `install.php` DDL conventions and foreign-key-to-core-table rules.
- **`perfex-customfields`** — programmatic custom-field install inside `install.php`.
- **`perfex-email`** — module-owned cron hooks for email retry processing.

## Upstream docs

- Perfex module basics: https://help.perfexcrm.com/module-basics/
- Module file headers (the `Version:` format): https://help.perfexcrm.com/module-file-headers/
- Common module functions (`register_activation_hook`, `register_cron_task`, `register_payment_gateway`): https://help.perfexcrm.com/common-module-functions/
- Module security (direct-access prevention, path-traversal guards): https://help.perfexcrm.com/module-security/
- CI3 controllers: https://codeigniter.com/userguide3/general/controllers.html
