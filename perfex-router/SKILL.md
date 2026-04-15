---
name: perfex-router
description: Use this skill FIRST whenever the user mentions Perfex CRM, a Perfex module, PerfexCRM, or a file path containing /modules/<name>/, tblcustomfields, get_option, Perfex hooks, or crm/ directory structure. Routes the task to the appropriate perfex-* sub-skill before any code is written.
---

# Perfex CRM Skill Router

You are working in a Perfex CRM codebase. Perfex is a CodeIgniter 3-based commercial CRM with its own module system, hook system, and conventions. Before writing code, classify the task and load the matching sub-skill. Mis-classifying leads to bugs (wrong FK types, wrong field names, bypassed security patterns).

## How to route

Read the user's request. Match the primary concern to ONE of the sub-skills below (you may load a second if the task crosses boundaries).

| Task looks like... | Load sub-skill |
|---|---|
| Using `get_option`, `hooks`, `$this->load->model`, accessing `$CI` / `get_instance()`, app_init hooks | `perfex-core-apis` |
| Creating a new module, writing `install.php`, adding routes, views, or language files | `perfex-module-dev` |
| Writing SQL DDL, adding a foreign key, migrating a table, inspecting schema | `perfex-database` |
| Handling tokens, redirects, rate limiting, logging PII, AJAX endpoints | `perfex-security` |
| Sending emails, email templates, retry queues, `send_simple_email` | `perfex-email` |
| Adding a custom field, reading `tblcustomfields`, field types, only_admin | `perfex-customfields` |
| Custom client/admin theme, asset hooks, jQuery Validate, form submit issues | `perfex-theme` |

## Hard rules (apply regardless of sub-skill)

1. **Perfex `get_option()` takes NO default argument.** Use `get_option('key') ?: 'default'` — never `get_option('key', 'default')`. This is the #1 source of silent bugs.
2. **Foreign keys to Perfex core tables (`tblcontacts`, `tblstaff`, `tblclients`) MUST be `INT` signed** — Perfex core uses signed INT, not UNSIGNED. FK type mismatch will fail constraint creation.
3. **Production schema may differ from `install.php`.** Always verify columns exist in the live DB before assuming. `SHOW CREATE TABLE` over trust.
4. **`tblcustomfields` has a typo in core: `disalow_client_to_edit`** (missing 'l'). Preserve it. Don't "fix" it.
5. **`tblcustomfields` uses `only_admin`** (not `only_admin_area`). Pre-5.x installs may differ.
6. **Every `target="_blank"` needs `rel="noopener noreferrer"`** — no exceptions.
7. **Never include Claude/Anthropic in git commit messages.**

## When the task doesn't fit

If the task is generic CodeIgniter 3 (not Perfex-specific), say so and use general CI3 knowledge. If it involves a third-party Perfex module from CodeCanyon, flag that you don't have that module's source and ask the user to share relevant files.

## Links (official, not mirrored)

- Perfex dev docs: https://www.perfexcrm.com/documentation/
- Perfex module development: https://help.perfexcrm.com/custom-modules/
- CodeIgniter 3 user guide: https://codeigniter.com/userguide3/

Do NOT scrape or copy content from `perfexcrm.com` — Perfex is commercial software under CodeCanyon license. Link out, don't mirror.
