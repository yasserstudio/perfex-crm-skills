# Perfex CRM Skills for AI Coding Agents

**Stop debugging the same Perfex bugs.** Seven [Agent Skills](https://agentskills.io/specification) that teach Claude Code, Cursor, and Codex what [Perfex CRM](https://www.perfexcrm.com/) actually does — its `get_option()` trap, signed-INT FK rule, the `disalow_client_to_edit` typo you can't fix, and two dozen other gotchas distilled from three years of production Perfex development.

[![GitHub stars](https://img.shields.io/github/stars/yasserstudio/perfex-crm-skills?style=social)](https://github.com/yasserstudio/perfex-crm-skills)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Spec: agentskills.io](https://img.shields.io/badge/spec-agentskills.io-green.svg)](https://agentskills.io/specification)
[![Latest release](https://img.shields.io/github/v/release/yasserstudio/perfex-crm-skills?label=latest&color=blue)](https://github.com/yasserstudio/perfex-crm-skills/releases)
[![CI](https://github.com/yasserstudio/perfex-crm-skills/actions/workflows/validate-skills.yml/badge.svg)](https://github.com/yasserstudio/perfex-crm-skills/actions/workflows/validate-skills.yml)

**For freelancers and agencies building Perfex CRM modules who use AI coding assistants** (Claude Code, Cursor, Codex, and others).

Latest: **[v1.1.0](https://github.com/yasserstudio/perfex-crm-skills/releases/tag/v1.1.0)** (2026-04-15) — real content release with factual corrections and three new sections. See [CHANGELOG](CHANGELOG.md).

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

### Via `npx skills` (recommended)

```bash
npx skills add https://github.com/yasserstudio/perfex-crm-skills
```

Installs to `~/.claude/skills/` and works with any Agent Skills-compatible AI coding tool — Claude Code, Cursor, Codex, and others.

### Via Claude Code plugin marketplace

```
/plugin marketplace add yasserstudio/perfex-crm-skills
/plugin install perfex-crm-skills
```

### Via git clone

```bash
git clone https://github.com/yasserstudio/perfex-crm-skills ~/.claude/skills/perfex-crm-skills
```

### Try it after install

Ask your agent something Perfex-specific — e.g. *"Add a `passport_number` custom field to Perfex contacts, hidden from the client portal."* You should see it use the correct `only_admin` column, preserve the `disalow_client_to_edit` typo, prefix the slug with the module name, and wrap the insert in `table_exists`-guarded DDL — all patterns it'd normally get wrong without the skill loaded.

## The seven skills

Each skill is **independently triggered** — Claude, Cursor, or Codex inspects the `description` field of every available skill and loads the matching one on demand. No manual routing, no slash commands needed. The agent picks the right skill automatically based on what you're working on.

| Skill | Triggers on |
|---|---|
| **perfex-core-apis** | `get_option`, `update_option`, `hooks()`, `do_action`, `apply_filters`, `$this->load`, `get_instance()`, `db_prefix()`, auth helpers, logging |
| **perfex-module-dev** | Creating/modifying modules — `module.php`, `install.php`, controllers, routes, views, language files, inter-module dependencies |
| **perfex-database** | DDL for `tbl*` tables, foreign keys to `tblcontacts`/`tblstaff`/`tblclients`, migrations, schema drift |
| **perfex-security** | Single-use tokens, rate limiting, open-redirect guards, PII logging, CSRF exclusions, AJAX enumeration oracles |
| **perfex-email** | `send_simple_email`, email templates, admin-recipient fallback, retry queues, SMTP debugging |
| **perfex-customfields** | `tblcustomfields`, field types, `only_admin`, the `disalow_client_to_edit` typo, programmatic install |
| **perfex-theme** | Custom client-area themes, asset hooks, jQuery Validate submit-button-name bug, Bootstrap 3 specificity, dark mode, RTL |

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

## Why this works

1. **Distilled, not copied.** These skills contain our own explanations and patterns. We link to [Perfex's official docs](https://help.perfexcrm.com/) rather than mirroring them — Perfex is commercial software under CodeCanyon license.
2. **Failure-driven.** Every gotcha traces to a real production incident on a client Perfex install. No speculative advice.
3. **Verified.** Every factual claim is checked against live Perfex core source or official docs at release time. v1.1.0 caught and fixed three wrong hook names that earlier versions had carried over from community tutorials.
4. **Conservative.** Skills tell agents what's safe and what will break. They don't encourage refactors or "improvements" — surgical changes only.

## How is this different from Perfex docs?

Perfex's [official documentation](https://help.perfexcrm.com/) tells you the API surface. These skills tell you **what silently breaks**:

- **Docs say** `get_option($key, $default)` works. **Reality:** the second argument is ignored. No warning. Just empty string.
- **Docs describe** custom field columns. **Reality:** the column is misspelled `disalow_client_to_edit` and you must preserve the typo.
- **Docs assume** you read them before coding. **Skills inject** at the moment your AI agent writes the code — no manual lookup.
- **Docs don't cover** production schema drift, FK type mismatches, or `dbforge` auto-prefix traps. **Skills do** — every rule traces to a real incident.

## FAQ

### What's an Agent Skill?

A markdown file (`SKILL.md`) with YAML frontmatter that tells an AI coding agent when and how to help with a specific task. The agent reads the `description` field of every available skill, decides which apply to the current task, and loads the matching skill's body as context. Skills work with Claude Code, Cursor, Codex, and any agent supporting the [agentskills.io specification](https://agentskills.io/specification).

### Which Perfex versions are covered?

Tested against **Perfex 2.9–3.x** on CodeIgniter 3. Most rules — signed-INT FKs, the `get_option()` trap, the `disalow_client_to_edit` typo, `only_admin` column, jQuery Validate submit-button bug — apply back to **Perfex 2.3+**. Individual skills call out version-specific gotchas where they exist.

### What's NOT covered?

- **Perfex REST API / webhooks** — separate domain, candidate for a future `perfex-api` skill when we have ≥3 real incidents to distill.
- **CodeCanyon third-party modules** — those authors own their conventions; share the module source if you need help with it.
- **Perfex SaaS / multi-tenant forks** — a different product with reshaped schemas. Core gotchas (`get_option`, FK types) often still apply, but table-name / `emails_model` divergences won't be caught.
- **Generic CodeIgniter 3 patterns** — use a general CI3 skill for those.

### Will this work with Cursor, Codex, or other agents — not just Claude?

Yes. The skills conform to the open [Agent Skills spec](https://agentskills.io/specification) and contain no Claude-Code-specific syntax. Any spec-compliant agent picks them up.

### Does this send data anywhere? Any telemetry?

**No.** Plain markdown files loaded into your agent's local context. Nothing phones home. No analytics, no usage tracking. Your Perfex code never leaves your machine.

### Does this need internet access at runtime?

No. Skills are local files; the agent loads them from `~/.claude/skills/` (or wherever you installed them) with no network calls.

### How often is this updated?

We ship in build-in-public mode — tags are public checkpoints of real shipped progress, not frozen pin targets. See [CHANGELOG.md](CHANGELOG.md) for what's landed and [CONTRIBUTING.md](CONTRIBUTING.md#release-cadence--build-in-public) for the release discipline. Most users `npx skills add` (tracks `main`) and get updates as they land.

### I found a Perfex gotcha that isn't here. How do I add it?

[Open a PR](CONTRIBUTING.md) or [file an issue](.github/ISSUE_TEMPLATE/new-gotcha.md) citing the real production bug it came from. Speculative advice gets rejected — every rule here traces to a real incident.

---

## Contributing

PRs welcome. New gotchas should cite a real incident — speculative advice gets rejected. Keep each SKILL.md tight; split into a new skill rather than bloating an existing one. Validate with [`skills-ref validate`](https://github.com/agentskills/agentskills/tree/main/skills-ref) before opening a PR.

## License

MIT. See [LICENSE](LICENSE). Third-party dependencies and their licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Acknowledgements

Battle-tested on a client's Perfex installation over ~3 years of production use. Extracted here so others don't rediscover the same bugs.

## Trademarks and affiliation

**This repo is independent and not affiliated with, endorsed by, or sponsored by any of the products it mentions.** All trademarks are the property of their respective owners, referenced here nominatively to describe compatibility.

- **Perfex CRM®** is a product of its respective vendor, sold on CodeCanyon. This repo contains our own prose; we link to `help.perfexcrm.com` rather than mirroring it.
- **Claude™, Claude Code™, and Anthropic®** are trademarks of Anthropic, PBC.
- **Cursor®** is a trademark of Anysphere Inc.
- **Codex®** and **OpenAI®** are trademarks of OpenAI.
- **Agent Skills** and the specification at [agentskills.io](https://agentskills.io/specification) are maintained by the AgentSkills community; this repo implements that spec as a conforming skill collection.

Mention of a product name does not imply endorsement of, by, or any business relationship with that product's vendor.
