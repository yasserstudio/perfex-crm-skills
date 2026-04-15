---
name: perfex-database
description: Use whenever the user writes SQL DDL for a Perfex CRM module, adds a foreign key referencing `tblcontacts`, `tblstaff`, `tblclients`, `tblinvoices`, or any `tbl*` core table, designs `tbl<module>_<entity>` schema, writes `install.php` / `uninstall.php` DDL, writes a migration or `ALTER TABLE`, or debugs "Cannot add foreign key constraint" / "incompatible" errors. Also trigger when the user says "FK won't create in Perfex", "my module's table has wrong collation", "schema in staging differs from prod", "add a column to my Perfex module table", or mentions `db_prefix()` in a DDL context, `utf8mb4_unicode_ci`, or `VARCHAR(191)` vs `VARCHAR(255)`. Prevents the UNSIGNED-INT-vs-signed-INT trap that silently drops foreign-key constraints pointing at Perfex core tables.
license: MIT
metadata:
  author: yasserstudio
  version: "1.1.0"
---

# Perfex Database Patterns

You are a Perfex CRM database engineer. Your job is to design module-owned tables and migrations that integrate cleanly with Perfex core — matching signed-INT foreign-key conventions, utf8mb4 collation, idempotent DDL — and to handle real-world schema drift between committed `install.php` and the production database.

Perfex uses MySQL/MariaDB with InnoDB, utf8mb4_unicode_ci, and a configurable table prefix (default `tbl`). All custom tables live in the same database as core — namespace them by module name to avoid collisions.

## Table naming

```
tbl<module>_<entity>
```

Examples: `tblmymodule_sessions`, `tblmymodule_logs`. Always use `db_prefix()` in code — the prefix is user-configurable.

## Foreign keys to core tables — the #1 trap

**Perfex core uses signed `INT`, not `UNSIGNED`.** If you create a FK on `UNSIGNED INT` pointing at `tblcontacts.id`, MySQL will reject the constraint with "incompatible" error or silently skip it on older MariaDB versions.

```sql
-- ❌ WRONG — will fail or silently drop the constraint
CREATE TABLE `tblmymodule_items` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `contact_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_mymodule_contact` FOREIGN KEY (`contact_id`)
    REFERENCES `tblcontacts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ✅ RIGHT — match core's signed INT
CREATE TABLE `tblmymodule_items` (
  `id`         INT NOT NULL AUTO_INCREMENT,
  `contact_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_mymodule_contact` FOREIGN KEY (`contact_id`)
    REFERENCES `tblcontacts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Core tables that are common FK targets:
| Table | PK column | Type |
|---|---|---|
| `tblcontacts` | `id` | `INT` |
| `tblstaff` | `staffid` | `INT` |
| `tblclients` | `userid` | `INT` |
| `tblinvoices` | `id` | `INT` |
| `tblcontracts` | `id` | `INT` |
| `tblleads` | `id` | `INT` |

## Charset/collation

Always `utf8mb4 / utf8mb4_unicode_ci` to match Perfex core. Mismatched collation on a FK column also fails constraint creation.

## `install.php` DDL

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

$CI =& get_instance();

if (!$CI->db->table_exists(db_prefix() . 'mymodule_items')) {
    $CI->db->query('
        CREATE TABLE `' . db_prefix() . 'mymodule_items` (
            `id`         INT NOT NULL AUTO_INCREMENT,
            `contact_id` INT NOT NULL,
            `name`       VARCHAR(191) NOT NULL,
            `created_at` DATETIME NOT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_contact` (`contact_id`),
            CONSTRAINT `fk_mymodule_contact` FOREIGN KEY (`contact_id`)
                REFERENCES `' . db_prefix() . 'contacts`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ');
}
```

Always `if (!table_exists(...))` — activation hooks can run twice if the admin clicks twice or a module is re-activated.

## VARCHAR length: use 191, not 255

MySQL's default `utf8mb4` index-key limit is 767 bytes. `VARCHAR(255)` on a utf8mb4 indexed column overflows. Use `VARCHAR(191)` on any column that will be indexed (unique keys, FKs, lookups). Non-indexed columns can be longer.

## Production drift is real

The `install.php` committed to the repo is the schema at the moment the module was first activated. Over a multi-year lifespan:
- Columns get added manually via phpMyAdmin
- Columns get renamed on staging and never reconciled
- Indexes disappear after a mysqldump/restore

**Before assuming a column exists in production, verify.** Use `SHOW CREATE TABLE` against the live DB. Don't trust `install.php`. Don't trust even a schema migration log.

## Migration pattern

Perfex has no built-in migration system. Roll your own:

```php
// In module_name.php
hooks()->add_action('app_init', 'my_module_maybe_migrate');

function my_module_maybe_migrate() {
    $installed = get_option('my_module_schema_version') ?: '0';
    if (version_compare($installed, '1.1.0', '<')) {
        my_module_migrate_to_110();
        update_option('my_module_schema_version', '1.1.0');
    }
}

function my_module_migrate_to_110() {
    $CI =& get_instance();
    if (!$CI->db->field_exists('new_column', db_prefix() . 'mymodule_items')) {
        $CI->db->query('ALTER TABLE `' . db_prefix() . 'mymodule_items` ADD `new_column` VARCHAR(191) NULL');
    }
}
```

Always check `field_exists()` / `table_exists()` before DDL — migrations MUST be idempotent. Admins will re-run `app_init` on every page load.

## Query builder vs raw SQL

Prefer CI's query builder — it parameterizes automatically:

```php
// ✅ safe
$CI->db->where('contact_id', $id);
$CI->db->insert(db_prefix() . 'mymodule_items', $data);

// ❌ SQL injection risk
$CI->db->query("SELECT * FROM " . db_prefix() . "mymodule_items WHERE id = $id");
```

If you must use raw SQL (complex JOINs, DDL), use `$CI->db->escape()` or bind parameters:
```php
$CI->db->query('SELECT * FROM `' . db_prefix() . 'mymodule_items` WHERE id = ?', [$id]);
```

## Atomic updates for race safety

Whenever you're consuming a one-time token or claiming a lock, update-then-check:

```php
$CI->db->where('token', $token);
$CI->db->where('used', 0);
$CI->db->update(db_prefix() . 'mymodule_tokens', ['used' => 1, 'used_at' => date('Y-m-d H:i:s')]);

if ($CI->db->affected_rows() !== 1) {
    // token was already consumed in a concurrent request
    return false;
}
```

See `perfex-security` for the full token lifecycle pattern.

## Backup before destructive ops

Before any `ALTER TABLE`, `DROP COLUMN`, or `UPDATE` without WHERE, dump the target table:
```bash
mysqldump -u USER -p DB tblmymodule_items > /tmp/pre_migration_$(date +%s).sql
```

## Related skills

- **`perfex-module-dev`** — `install.php` is where module schema lives; this skill covers the DDL inside it.
- **`perfex-customfields`** — `tblcustomfields` schema quirks (`only_admin`, the `disalow_client_to_edit` typo) that affect DDL generation.
- **`perfex-security`** — the atomic-UPDATE-with-`affected_rows()` pattern for race-safe token consumption.

## Upstream docs

- CI3 database: https://codeigniter.com/userguide3/database/
- MySQL utf8mb4 index limit: https://dev.mysql.com/doc/refman/8.0/en/innodb-limits.html
