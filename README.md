# Perfex CRM Module Development Skills for AI Coding Agents

<!-- keywords: perfex crm, perfex module development, perfex custom fields, perfex payment gateway module, ai coding assistant, claude code perfex, cursor perfex, codex perfex, codeigniter 3 perfex -->

**Stop debugging the same Perfex bugs.** Nine skills that teach your AI coding agent what Perfex CRM actually does — so it stops shipping silently-broken code.

Covers 24 gotchas distilled from 3 years and 40+ modules of production Perfex development. Every rule traces to a real incident: a broken payment flow, a lost custom field value, a security hole that went unnoticed for weeks.

> **What's an Agent Skill?** A markdown file that injects domain knowledge into AI coding tools (Claude Code, Cursor, Codex) at the moment of code generation. No manual lookup, no copy-pasting docs. [Learn more →](https://agentskills.io/specification)

[![GitHub stars](https://img.shields.io/github/stars/yasserstudio/perfex-crm-skills?style=social)](https://github.com/yasserstudio/perfex-crm-skills)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Spec: agentskills.io](https://img.shields.io/badge/spec-agentskills.io-green.svg)](https://agentskills.io/specification)
[![Latest release](https://img.shields.io/github/v/release/yasserstudio/perfex-crm-skills?label=latest&color=blue)](https://github.com/yasserstudio/perfex-crm-skills/releases)
[![CI](https://github.com/yasserstudio/perfex-crm-skills/actions/workflows/validate-skills.yml/badge.svg)](https://github.com/yasserstudio/perfex-crm-skills/actions/workflows/validate-skills.yml)

**For freelancers and agencies building Perfex CRM modules who use AI coding assistants** (Claude Code, Cursor, Codex, and others). Not for Perfex SaaS forks or REST API work.

Latest: **[v1.4.0](https://github.com/yasserstudio/perfex-crm-skills/releases/tag/v1.4.0)** (2026-05-16) — 2 new skills (payment gateway, PDF), Perfex 3.2–3.4.1 coverage, 6 new hooks, PHP 8.1/8.4 compat notes. See [CHANGELOG](CHANGELOG.md).

---

## What this prevents

Every one of these caused a real production incident:

- **Silent `get_option()` default failures** — your agent writes `get_option('key', 'default')` which Perfex silently ignores
- **FK constraint failures** — unsigned INT vs Perfex core's signed INT, caught only on strict MySQL or dropped silently on MariaDB
- **Custom field queries breaking** — because the agent "fixed" the `disalow_client_to_edit` typo that Perfex core queries by exact name
- **Non-idempotent migrations crashing** — `app_init` runs on every page load; unwrapped DDL fires repeatedly
- **Payment webhook 403s** — CSRF blocks external POSTs; agent forgets to exclude the route
- **Blank PDFs in production** — wrong font for Arabic, or TCPDF swallowing fatal errors silently

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

Perfex's `get_option()` silently ignores its second argument — no warning, no error, just an empty string back. That's one of 24 Perfex-specific patterns these skills encode.

---

## Why not just paste Perfex docs into ChatGPT?

| | Paste docs manually | These skills |
|---|---|---|
| **Fires automatically** | No — you must remember to paste | Yes — triggers at the exact moment your agent writes Perfex code |
| **Covers silent gotchas** | Only if docs mention them (they often don't) | Every rule traces to a real production bug |
| **Stays current** | Stale the moment you paste | Updated with each Perfex release |
| **Covers production drift** | Never — docs describe ideal state | Documents real-world schema drift, FK mismatches, hook timing changes |
| **Works across tools** | One tool at a time | Claude Code, Cursor, Codex, any spec-compliant agent |

A generic CodeIgniter 3 skill also won't help — it doesn't know Perfex's column typos, option-layer quirks, or module lifecycle conventions.

---

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

If this saved you a debugging session, [star the repo](https://github.com/yasserstudio/perfex-crm-skills) so others building Perfex modules can find it.

---

## What's included: 9 Perfex CRM development skills

Each skill is **independently triggered** — your agent inspects the `description` field of every available skill and loads the matching one on demand. No manual routing, no slash commands needed. The agent picks the right skill automatically based on what you're working on.

| Skill | Triggers on |
|---|---|
| **perfex-core-apis** | `get_option`, `update_option`, `hooks()`, `do_action`, `apply_filters`, `$this->load`, `get_instance()`, `db_prefix()`, auth helpers, logging |
| **perfex-module-dev** | Creating/modifying modules — `module.php`, `install.php`, controllers, routes, views, language files, cron tasks |
| **perfex-database** | DDL for `tbl*` tables, foreign keys to `tblcontacts`/`tblstaff`/`tblclients`, migrations, schema drift |
| **perfex-security** | Single-use tokens, rate limiting, open-redirect guards, PII logging, CSRF exclusions, deserialization defense |
| **perfex-email** | `send_simple_email`, email templates, language fallback, admin-recipient chains, retry queues, SMTP debugging |
| **perfex-customfields** | `tblcustomfields`, field types, `only_admin`, the `disalow_client_to_edit` typo, programmatic install |
| **perfex-theme** | Custom client-area themes, asset hooks, jQuery Validate submit-button-name bug, Bootstrap 3 specificity, dark mode, RTL |
| **perfex-payment-gateway** | `App_gateway` class, `register_payment_gateway`, encrypted settings, webhook CSRF exclusion, Stripe API changes |
| **perfex-pdf** | TCPDF templates, `my_` prefix override, `App_items_table`, font selection, e-invoice JSON/XML |

---

## Critical Perfex CRM rules every module must follow

These rules are duplicated inside each relevant skill because they fire regardless of which one is loaded first. They exist because their absence caused real production incidents.

1. **`get_option('key') ?: 'default'`** — never `get_option('key', 'default')`. Perfex silently ignores the second argument. #1 source of silent bugs.
2. **FKs to core tables must be signed `INT`** — `tblcontacts`, `tblstaff`, `tblclients` all use signed `INT` (not `UNSIGNED`). Mismatched FK types fail constraint creation on strict MySQL or drop silently on older MariaDB.
3. **Production schema may differ from `install.php`.** Years of manual migrations drift the live DB away from committed DDL. Verify with `SHOW CREATE TABLE` before assuming.
4. **`tblcustomfields.disalow_client_to_edit`** — yes, it's misspelled. Preserve the typo. Core queries the exact column name.
5. **`tblcustomfields.only_admin`** (not `only_admin_area`). Some older community docs get this wrong.
6. **Every `target="_blank"` pairs with `rel="noopener noreferrer"`** — no exceptions.
7. **Migrations are idempotent** — wrap DDL in `field_exists()` / `table_exists()` checks. `app_init` runs on every page load.
8. **Email failures must not fail the user flow** — try/catch, log, continue. Enqueue for retry.

---

## Why this works

1. **Distilled, not copied.** These skills contain our own explanations and patterns. We link to [Perfex's official docs](https://help.perfexcrm.com/) rather than mirroring them — Perfex is commercial software under CodeCanyon license.
2. **Failure-driven.** Every gotcha traces to a real production incident on a client Perfex install. No speculative advice.
3. **Verified.** Every factual claim is checked against live Perfex core source or official docs at release time. v1.1.0 caught and fixed three wrong hook names that earlier versions had carried over from community tutorials.
4. **Conservative.** Skills tell agents what's safe and what will break. They don't encourage refactors or "improvements" — surgical changes only.

---

## How is this different from Perfex docs?

Perfex's [official documentation](https://help.perfexcrm.com/) tells you the API surface. These skills tell you **what silently breaks**:

- **Docs say** `get_option($key, $default)` works. **Reality:** the second argument is ignored. No warning. Just empty string.
- **Docs describe** custom field columns. **Reality:** the column is misspelled `disalow_client_to_edit` and you must preserve the typo.
- **Docs assume** you read them before coding. **Skills inject** at the moment your AI agent writes the code — no manual lookup.
- **Docs don't cover** production schema drift, FK type mismatches, or `dbforge` auto-prefix traps. **Skills do** — every rule traces to a real incident.

---

## FAQ

### Which Perfex versions are covered?

Tested against **Perfex 2.9–3.4.x** on CodeIgniter 3. Most rules — signed-INT FKs, the `get_option()` trap, the `disalow_client_to_edit` typo, `only_admin` column, jQuery Validate submit-button bug — apply back to **Perfex 2.3+**. Individual skills call out version-specific gotchas where they exist (PHP 8.1 minimum from 3.2.0, session changes in 3.3.0, deserialization CVE in 3.4.1).

### What's NOT covered?

- **Perfex REST API / webhooks** — separate domain, candidate for a future `perfex-api` skill when we have ≥3 real incidents to distill.
- **CodeCanyon third-party modules** — those authors own their conventions; share the module source if you need help with it.
- **Perfex SaaS / multi-tenant forks** — a different product with reshaped schemas. Core gotchas (`get_option`, FK types) often still apply, but table-name / `emails_model` divergences won't be caught.
- **Generic CodeIgniter 3 patterns** — use a general CI3 skill for those. CI3 skills don't know Perfex's column typos, option-layer quirks, or module lifecycle conventions.

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

## Built by

[Yasser's studio](https://github.com/yasserstudio) — extracted from ~3 years of maintaining Perfex production installs (40+ custom modules across multiple client projects). We got tired of re-explaining the same gotchas to our AI tools, so we encoded them permanently.

## License

MIT. See [LICENSE](LICENSE). Third-party dependencies and their licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Trademarks and affiliation

**This repo is independent and not affiliated with, endorsed by, or sponsored by any of the products it mentions.** All trademarks are the property of their respective owners, referenced here nominatively to describe compatibility.

- **Perfex CRM®** is a product of its respective vendor, sold on CodeCanyon. This repo contains our own prose; we link to `help.perfexcrm.com` rather than mirroring it.
- **Claude™, Claude Code™, and Anthropic®** are trademarks of Anthropic, PBC.
- **Cursor®** is a trademark of Anysphere Inc.
- **Codex®** and **OpenAI®** are trademarks of OpenAI.
- **Agent Skills** and the specification at [agentskills.io](https://agentskills.io/specification) are maintained by the AgentSkills community; this repo implements that spec as a conforming skill collection.

Mention of a product name does not imply endorsement of, by, or any business relationship with that product's vendor.
