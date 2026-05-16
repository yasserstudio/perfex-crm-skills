---
name: perfex-customfields
description: Use whenever the user is reading, writing, installing, or debugging Perfex CRM custom fields — `tblcustomfields` (definitions), `tblcustomfieldsvalues` (values keyed by `relid`), field types (`input`, `textarea`, `select`, `multiselect`, `checkbox`, `date`, `datetime`, `link`, `colorpicker`, `file`), `fieldto` values (`contacts`, `customers`, `leads`, `invoice`, `estimate`, `contracts`, `tasks`, `tickets`, etc.), `only_admin` visibility, `show_on_client_portal`, `bs_column`, the intentionally-misspelled `disalow_client_to_edit` column, or `render_custom_fields()`. Also trigger when the user says "my custom field isn't showing in the client portal", "I added a custom field in code but it doesn't appear", "custom field value not saving", "only_admin isn't respected", or "Perfex custom field types". Preserves the `disalow_client_to_edit` typo that Perfex core queries by exact name.
license: MIT
metadata:
  author: yasserstudio
  version: "1.4.0"
---

# Perfex Custom Fields

You are a Perfex CRM custom-fields specialist. Your job is to read, write, and install custom fields against `tblcustomfields` and `tblcustomfieldsvalues` without tripping over Perfex's quirks — the misspelled `disalow_client_to_edit` column, `only_admin` visibility, `bs_column` Bootstrap sizing, and module-prefixed slug conventions.

Custom fields are Perfex's extensibility mechanism for adding user-defined fields to contacts, clients, leads, invoices, tickets, and most core entities. Two tables: `tblcustomfields` (definitions) and `tblcustomfieldsvalues` (values keyed by `relid`).

## Schema gotchas (critical)

### `only_admin` — NOT `only_admin_area`

The column is `only_admin`. Some older docs and Stack Overflow answers refer to `only_admin_area` — that's wrong. Don't alias, don't "fix".

### `disalow_client_to_edit` — the typo is canonical

Yes, it's misspelled (missing 'l' after 'disa'). **Preserve it.** Perfex core queries this exact column name. If you rename it, core breaks. If you write an abstraction over it, leave the DB column alone and only alias in PHP.

### Full definition-row shape

When inserting a custom field programmatically:

```php
$CI->db->insert(db_prefix() . 'customfields', [
    'fieldto'               => 'contacts',           // 'customers', 'contacts', 'leads', 'invoice', 'estimate', 'contracts', 'tasks', 'expenses', 'tickets', 'proposal', 'subscriptions', 'items'
    'name'                  => 'Study Program',
    'slug'                  => 'contacts_study_program',  // must be unique per fieldto
    'required'              => 0,
    'type'                  => 'input',              // input | textarea | select | multiselect | checkbox | number | date | date_picker | datetime | link | colorpicker | file
    'options'               => '',                   // newline-separated for select types; null for input
    'display_inline'        => 0,
    'field_order'           => 0,
    'active'                => 1,
    'disalow_client_to_edit'=> 0,                    // ← preserve the typo
    'only_admin'            => 0,                    // 1 = hide from client area
    'show_on_pdf'           => 0,
    'show_on_client_portal' => 1,
    'show_on_table'         => 0,
    'show_on_picker'        => 0,                    // on invoice/estimate item picker
    'default_value'         => '',
    'bs_column'             => '12',                 // '12' | '6' | '4' | '3' — Bootstrap grid width
    'has_permission_view'   => 0,                    // 0 = all staff can view
    'permission_view'       => '',                   // comma-separated staff IDs if has_permission_view=1
]);
```

### Module-owned custom fields — convention

Prefix your module's slugs with the module name and the entity:

```
onboarding_passport_number      → contacts.onboarding_passport_number
mymodule_plan_type              → customers.mymodule_plan_type
```

This prevents slug collisions with core and other modules.

## Reading values

Values live in `tblcustomfieldsvalues` with `(fieldid, relid)` as the natural key. `relid` is the ID of the parent record (contact ID, invoice ID, etc.).

```php
public function get_custom_field_value($fieldto, $relid, $slug) {
    $this->db->select('v.value');
    $this->db->from(db_prefix() . 'customfieldsvalues v');
    $this->db->join(db_prefix() . 'customfields f', 'f.id = v.fieldid');
    $this->db->where('v.relid', $relid);
    $this->db->where('f.fieldto', $fieldto);
    $this->db->where('f.slug', $slug);
    $row = $this->db->get()->row();
    return $row ? $row->value : null;
}
```

Perfex also provides `get_custom_field_value($relid, $field_id, $field_to)` as a helper — but you need the field ID. Looking up by slug is usually more maintainable.

## Writing values

There's no simple "set" helper. Pattern: upsert via delete+insert, or check-then-update:

```php
public function set_custom_field_value($fieldto, $relid, $slug, $value) {
    $field = $this->db->select('id')
        ->where(['fieldto' => $fieldto, 'slug' => $slug])
        ->get(db_prefix() . 'customfields')->row();
    if (!$field) return false;

    $existing = $this->db->where(['fieldid' => $field->id, 'relid' => $relid])
        ->get(db_prefix() . 'customfieldsvalues')->row();

    if ($existing) {
        $this->db->where(['fieldid' => $field->id, 'relid' => $relid]);
        $this->db->update(db_prefix() . 'customfieldsvalues', ['value' => $value]);
    } else {
        $this->db->insert(db_prefix() . 'customfieldsvalues', [
            'fieldid' => $field->id,
            'relid'   => $relid,
            'value'   => $value,
        ]);
    }
    return true;
}
```

## Field types — what the `type` column means

| type          | `options` format | Storage in value column |
|---------------|------------------|-------------------------|
| `input`       | null             | plain string |
| `textarea`    | null             | plain string |
| `select`      | `Opt1\nOpt2\n…`  | the selected string |
| `multiselect` | `Opt1\nOpt2\n…`  | comma-separated strings |
| `checkbox`    | `Opt1\nOpt2\n…`  | comma-separated strings |
| `number`      | null             | numeric string |
| `date`        | null             | `YYYY-MM-DD` |
| `date_picker` | null             | `YYYY-MM-DD` |
| `datetime`    | null             | `YYYY-MM-DD HH:MM:SS` |
| `link`        | null             | URL string |
| `colorpicker` | null             | hex string `#rrggbb` |
| `file`        | null             | filename relative to `uploads/` |

`options` is plain newlines — not JSON, not comma-separated. Perfex explodes by `\n` at render time.

## Bootstrap column width (`bs_column`)

Controls visual width in the admin/client form. Allowed values: `'12'`, `'6'`, `'4'`, `'3'`. Stored as a string. Sets the Bootstrap 3 grid class `col-md-N`.

## Programmatically installing fields in a module

In your `install.php`:

```php
$fields = [
    [
        'fieldto' => 'contacts',
        'slug'    => 'mymodule_plan',
        'name'    => 'Plan',
        'type'    => 'select',
        'options' => "Basic\nPro\nEnterprise",
        'bs_column' => '6',
    ],
    // ...
];

foreach ($fields as $f) {
    $exists = $CI->db->where(['fieldto' => $f['fieldto'], 'slug' => $f['slug']])
        ->get(db_prefix() . 'customfields')->num_rows();
    if ($exists) continue;

    $CI->db->insert(db_prefix() . 'customfields', array_merge([
        'required' => 0, 'active' => 1, 'only_admin' => 0,
        'disalow_client_to_edit' => 0, 'show_on_client_portal' => 1,
        'display_inline' => 0, 'field_order' => 0, 'show_on_pdf' => 0,
        'show_on_table' => 0, 'show_on_picker' => 0,
        'default_value' => '', 'has_permission_view' => 0, 'permission_view' => '',
        'bs_column' => '12', 'options' => '',
    ], $f));
}
```

## Rendering in a custom view

Perfex ships `render_custom_fields()`:

```php
<?= render_custom_fields('contacts', $contact_id, [
    'print_only_required' => false,
    'only_customer_portal' => false,
]); ?>
```

In client-area views, pass `'only_customer_portal' => true` to respect `only_admin` and `show_on_client_portal`.

## Required item custom fields (Perfex 3.3.0+)

As of Perfex 3.3.0, **required item custom fields on select inputs are now enforced** server-side. Previously, marking an item custom field as `required` only triggered client-side validation (which could be bypassed). Now:

- If `fieldto = 'items'` and `required = 1` and `type = 'select'`, Perfex validates on save
- Empty select values are rejected with a validation error
- This applies to invoice items, estimate items, and proposal items

If your module programmatically creates invoice items, ensure you populate all required item custom fields or the save will fail silently in older code paths that don't check for validation errors.

## Don't assume core columns haven't drifted

Older Perfex installs (pre-2.9) may lack `show_on_client_portal` and `bs_column`. Before writing migration or install code that references them, run:

```sql
SHOW COLUMNS FROM `tblcustomfields`;
```

If your code will run on older installs, wrap inserts with defensive column inclusion (only set a column if it exists).

## Related skills

- **`perfex-database`** — `tblcustomfields` schema (`only_admin`, `disalow_client_to_edit`) and why you can't "fix" the typo.
- **`perfex-module-dev`** — programmatically installing fields in a module's `install.php`.
- **`perfex-core-apis`** — `_l()` for localized field labels when rendering.

## Upstream docs

- Perfex custom fields: https://help.perfexcrm.com/custom-fields/
