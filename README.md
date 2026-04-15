# perfex-crm-skills

**Agent skills for building on [Perfex CRM](https://www.perfexcrm.com/).** A focused set of Claude Code / Cursor / Codex skills that encode the conventions, APIs, and hard-won gotchas of the Perfex CodeIgniter-3-based CRM platform.

Works with any AI coding agent that supports the skills spec.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What this is

Perfex is a commercial CRM with deep, sometimes surprising conventions — `get_option()` silently ignores its second argument, foreign keys must be signed `INT`, a core column is spelled `disalow_client_to_edit` and always will be. Without context, a coding agent will "fix" these, break the module, and waste everyone's time.

This repo ships **1 router + 7 focused sub-skills** that tell your agent exactly what to do (and not do) when working on a Perfex module.

## Install

```bash
npx skills add https://github.com/yasserstudio/perfex-crm-skills
```

Or clone into your skills directory:

```bash
git clone https://github.com/yasserstudio/perfex-crm-skills ~/.claude/skills/perfex-crm-skills
```

## The skills

| Skill | When it loads |
|---|---|
| **perfex-router** | First, whenever Perfex is mentioned. Classifies the task and loads the right sub-skill. |
| **perfex-core-apis** | `get_option`, hooks (`do_action` / `apply_filters`), CI loader, auth helpers, logging |
| **perfex-module-dev** | Creating modules: `install.php`, controllers, routes, views, language files |
| **perfex-database** | Schema design, FK rules (signed INT!), utf8mb4 index limit, idempotent migrations |
| **perfex-security** | Token consume (TOCTOU-safe), rate limiting, open redirects, PII logging, CSRF |
| **perfex-email** | `send_simple_email`, template rendering, retry queues with exponential backoff |
| **perfex-customfields** | `tblcustomfields` schema, field types, the `disalow_client_to_edit` typo, programmatic install |
| **perfex-theme** | Custom client themes, asset hooks, jQuery Validate + submit button name bug, dark mode, RTL |

## Design principles

1. **Router-first.** Perfex tasks cross boundaries (a module needs a table, a controller, an email, and security). The router loads only the sub-skill you need for the current step — no wasted context.
2. **Distilled, not copied.** These skills contain our own explanations and patterns. We link out to [Perfex's official docs](https://help.perfexcrm.com/) rather than mirroring them. Perfex is commercial software — respect the license.
3. **Failure-driven.** Every gotcha in these skills exists because an absence caused a real production bug. No speculative advice.
4. **Conservative.** We tell the agent what's safe (quiz `field_exists` before ALTER) and what will break (UNSIGNED FK to signed PK). We don't refactor or "improve" — surgical changes only.

## Hard rules (every sub-skill enforces)

- `get_option('key') ?: 'default'` — **never** `get_option('key', 'default')`
- FKs to `tblcontacts`/`tblstaff`/`tblclients` = **signed `INT`**
- `tblcustomfields`: `only_admin` (not `only_admin_area`), preserve `disalow_client_to_edit` typo
- `target="_blank"` always pairs with `rel="noopener noreferrer"`
- Migrations are **idempotent** (`field_exists`/`table_exists` guards)
- Email failures **never** break the user flow

## Contributing

PRs welcome. New gotchas should cite a real incident — speculative advice gets rejected. Keep each SKILL.md tight; split into a new skill rather than bloating an existing one.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

Battle-tested on the [Fennec360](https://fennec360.com) Perfex installation over ~3 years of production use. Extracted here so others don't rediscover the same bugs.

**Not affiliated with Perfex CRM or its vendor.** "Perfex" is a trademark of its respective owner; this repo is an independent community skill collection.
