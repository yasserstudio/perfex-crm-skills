# perfex-crm-skills

**Stop debugging the same Perfex bugs.** Seven [Agent Skills](https://agentskills.io/specification) that teach Claude, Cursor, and Codex what [Perfex CRM](https://www.perfexcrm.com/) actually does — its `get_option()` trap, signed-INT FK rule, the `disalow_client_to_edit` typo you can't fix, and two dozen other gotchas distilled from three years of production on [Fennec360](https://fennec360.com).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Spec: agentskills.io](https://img.shields.io/badge/spec-agentskills.io-green.svg)](https://agentskills.io/specification)

---

## See the difference

Without the skill, your AI agent writes what looks right:

```php
$value = get_option('my_module_setting', 'default');   // ✗ silently broken
```

With the skill loaded, it writes what actually works:

```php
$value = get_option('my_module_setting') ?: 'default';  // ✓ correct
```

Perfex's `get_option()` silently ignores its second argument — no warning, no error, just an empty string back. That's one of roughly two dozen Perfex-specific patterns this repo encodes so your agent stops shipping silently-broken Perfex code.

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

## Perfex version coverage

Patterns are tested against **Perfex 2.9–3.x** on CodeIgniter 3. Most rules — signed-INT FKs, the `get_option()` trap, the `disalow_client_to_edit` typo, `only_admin` column, jQuery Validate submit-button bug — apply back to **Perfex 2.3+**. Individual skills call out version-specific gotchas where they exist. SaaS / multi-tenant forks of Perfex that reshape the core schema are **not covered** — those authors own their own conventions.

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

## FAQ

### What's an Agent Skill?

A markdown file (`SKILL.md`) with YAML frontmatter that tells an AI coding agent when and how to help with a specific task. The agent reads the frontmatter `description` of every available skill, decides which ones apply to the current task, and loads the matching skill's body as context. Skills work with Claude Code, Cursor, Codex, and any agent supporting the [agentskills.io specification](https://agentskills.io/specification).

### Which Perfex versions does this cover?

The gotchas were distilled against Perfex **2.9–3.x** on CodeIgniter 3. Most rules (signed-INT FKs, the `get_option()` trap, the `disalow_client_to_edit` typo, `only_admin` column) apply to every Perfex install since ~2018. When a rule is version-specific, the skill calls it out.

### Will this work with Cursor, Codex, or other AI agents — not just Claude?

Yes. The skills conform to the open [Agent Skills spec](https://agentskills.io/specification) and contain no Claude-Code-specific syntax. Any agent that reads the spec picks them up.

### Does this send data anywhere? Any telemetry?

**No.** These are plain markdown files loaded into your agent's local context. Nothing in this repo phones home, no analytics, no usage tracking. Your Perfex code never leaves your machine.

### Can I use this with a CodeCanyon-forked Perfex (multi-tenant SaaS, custom builds)?

Mostly yes — the core gotchas (`get_option`, FK types, `tblcustomfields` schema) apply to any install with Perfex's schema underneath. SaaS forks that reshaped the schema, renamed tables, or replaced `emails_model` will need their own skills; ours won't catch those divergences.

### Does this need internet access at runtime?

No. Skills are local files. Your agent loads them from `~/.claude/skills/` (or wherever you installed them) with no network calls.

### How often is this updated?

Shipped on meaningful changes, not on a schedule. See [CHANGELOG.md](CHANGELOG.md) and [CONTRIBUTING.md](CONTRIBUTING.md#release-cadence--when-not-to-cut-a-tag) for the release discipline. Most users just `npx skills add` (tracks `main`) and get updates as they land.

### I found a Perfex gotcha that isn't here. How do I add it?

[Open a PR](CONTRIBUTING.md) or [an issue using the "new-gotcha" template](.github/ISSUE_TEMPLATE/new-gotcha.md) citing the real production bug it came from. Speculative advice ("it would be good to mention…") gets rejected — every rule here traces to a real incident.

---

## Contributing

PRs welcome. New gotchas should cite a real incident — speculative advice gets rejected. Keep each SKILL.md tight; split into a new skill rather than bloating an existing one. Validate with [`skills-ref validate`](https://github.com/agentskills/agentskills/tree/main/skills-ref) before opening a PR.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

Battle-tested on the [Fennec360](https://fennec360.com) Perfex installation over ~3 years of production use. Extracted here so others don't rediscover the same bugs.

**Not affiliated with Perfex CRM or its vendor.** "Perfex" is a trademark of its respective owner; this repo is an independent community skill collection.
