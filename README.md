# perfex-crm-skills

**Agent skills for building on [Perfex CRM](https://www.perfexcrm.com/).** A focused set of [Agent Skills](https://agentskills.io/specification) that encode the conventions, APIs, and hard-won gotchas of the Perfex CodeIgniter-3-based CRM platform.

Works with any AI coding agent that supports the skills spec — Claude Code, Cursor, Codex, and others.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Spec: agentskills.io](https://img.shields.io/badge/spec-agentskills.io-green.svg)](https://agentskills.io/specification)

---

## What this is

Perfex is a commercial CRM with deep, sometimes surprising conventions — `get_option()` silently ignores its second argument, foreign keys must be signed `INT`, a core column is spelled `disalow_client_to_edit` and always will be. Without context, a coding agent will "fix" these, break the module, and waste everyone's time.

This repo ships **7 focused Agent Skills** that tell your agent exactly what to do (and not do) when working on a Perfex module.

## Install

```bash
npx skills add https://github.com/yasserstudio/perfex-crm-skills
```

Or clone into your skills directory:

```bash
git clone https://github.com/yasserstudio/perfex-crm-skills ~/.claude/skills/perfex-crm-skills
```

## The skills

| Skill | Triggers on |
|---|---|
| **perfex-core-apis** | `get_option`, `update_option`, `hooks()`, `do_action`, `apply_filters`, `$this->load`, `get_instance()`, `db_prefix()`, auth helpers, logging |
| **perfex-module-dev** | Creating/modifying modules — `module.php`, `install.php`, controllers, routes, views, language files |
| **perfex-database** | DDL for `tbl*` tables, foreign keys to `tblcontacts`/`tblstaff`/`tblclients`, migrations, schema drift |
| **perfex-security** | Single-use tokens, rate limiting, open-redirect guards, PII logging, CSRF exclusions, AJAX enumeration oracles |
| **perfex-email** | `send_simple_email`, email templates, admin-recipient fallback, retry queues |
| **perfex-customfields** | `tblcustomfields`, field types, `only_admin`, the `disalow_client_to_edit` typo, programmatic install |
| **perfex-theme** | Custom client-area themes, asset hooks, jQuery Validate submit-button-name bug, dark mode, RTL |

Each skill is independently triggered — Claude (or your agent of choice) inspects the `description` field of every available skill and loads the matching one on demand.

## Hard rules (apply across every skill)

These rules are duplicated inside each relevant sub-skill because they fire regardless of which one is loaded first. They exist because their absence caused real production incidents.

1. **`get_option('key') ?: 'default'`** — never `get_option('key', 'default')`. Perfex silently ignores the second argument. #1 source of silent bugs.
2. **FKs to core tables must be signed `INT`** — `tblcontacts`, `tblstaff`, `tblclients` all use signed `INT` (not `UNSIGNED`). Mismatched FK types fail constraint creation on strict MySQL or drop silently on older MariaDB.
3. **Production schema may differ from `install.php`.** Years of manual migrations drift the live DB away from committed DDL. Verify with `SHOW CREATE TABLE` before assuming.
4. **`tblcustomfields.disalow_client_to_edit`** — yes, it's misspelled. Preserve the typo. Core queries the exact column name.
5. **`tblcustomfields.only_admin`** (not `only_admin_area`). Some older community docs get this wrong.
6. **Every `target="_blank"` pairs with `rel="noopener noreferrer"`** — no exceptions.
7. **Migrations are idempotent** — wrap DDL in `field_exists()` / `table_exists()` checks. `app_init` runs on every page load.
8. **Email failures must not fail the user flow** — try/catch, log, continue. Enqueue for retry.

## Design principles

1. **Distilled, not copied.** These skills contain our own explanations and patterns. We link to [Perfex's official docs](https://help.perfexcrm.com/) rather than mirroring them. Perfex is commercial software under CodeCanyon license — respect the license.
2. **Failure-driven.** Every gotcha exists because an absence caused a real bug. No speculative advice.
3. **Conservative.** Skills tell agents what's safe and what will break. They don't encourage refactors or "improvements" — surgical changes only.
4. **Spec-compliant.** Conforms to [agentskills.io/specification](https://agentskills.io/specification): each skill has `name` + `description` frontmatter, SKILL.md under 500 lines, proper directory naming.

## Not covered (yet)

- **Perfex REST API / webhooks** — separate domain, likely a future `perfex-api` skill
- **CodeCanyon third-party modules** — those authors own their conventions; you'll need to share their source
- **Perfex SaaS multi-tenant fork** — a different product with different schemas
- **CI3 generic patterns** — use a general CodeIgniter skill for those

## Contributing

PRs welcome. New gotchas should cite a real incident — speculative advice gets rejected. Keep each SKILL.md tight; split into a new skill rather than bloating an existing one. Validate with [`skills-ref validate`](https://github.com/agentskills/agentskills/tree/main/skills-ref) before opening a PR.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

Battle-tested on the [Fennec360](https://fennec360.com) Perfex installation over ~3 years of production use. Extracted here so others don't rediscover the same bugs.

**Not affiliated with Perfex CRM or its vendor.** "Perfex" is a trademark of its respective owner; this repo is an independent community skill collection.
