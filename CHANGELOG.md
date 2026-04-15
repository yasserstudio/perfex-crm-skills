# Changelog

All notable changes to this repo are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as applied to agent skills — see [CONTRIBUTING.md](CONTRIBUTING.md#versioning-policy) for what constitutes MAJOR / MINOR / PATCH in this context.

> **Why versioning matters for skills:** the `description` field in each SKILL.md frontmatter is what Claude uses to decide when to trigger the skill. A description change is a behavior change. This changelog flags triggering-relevant changes explicitly so users who pin to a tag can audit what their agent will do differently after an upgrade.

## [Unreleased]

### Fixed

- **`perfex-core-apis`: corrected 3 wrong hook names.** Previously documented `after_contact_added`, `after_contact_updated`, `before_contact_deleted` — **these hooks do not exist in Perfex core**. The real names are `contact_created`, `contact_updated`, `before_delete_contact`. Verified against live Perfex core source (`application/models/Contacts_model.php`). Also expanded the hook list to include the parallel client-company events (`after_client_created`, `client_updated`, `before_client_deleted`) and a note about Perfex's naming inconsistency between entity types.
- **Broken upstream-docs links replaced** (both returned 404 before this release):
  - `perfex-core-apis` and `perfex-module-dev`: `/custom-modules/` → `/module-basics/`
  - `perfex-theme`: `/custom-theme/` → `/category/customization/`

### Changed

- **README hero rewritten** to lead with pain and specificity. Old hero was a feature-list; new hero names the `get_option()` trap, FK rule, and `disalow_client_to_edit` typo inline.
- **Repo GitHub description** rewritten to match hero tone.
- **GitHub topics set** (10 tags): `perfex`, `perfex-crm`, `agent-skills`, `claude-code`, `claude-ai`, `anthropic`, `codeigniter`, `php`, `cursor`, `skill`.
- **Homepage URL set** to `agentskills.io/specification`.

### Added

- **5 new upstream-doc references** cited directly in the relevant skills' "Upstream docs" footers, from an audit against https://help.perfexcrm.com/:
  - `perfex-core-apis` now cites `/action-hooks/`
  - `perfex-module-dev` now cites `/common-module-functions/`, `/module-file-headers/`, and `/module-security/`
  - `perfex-theme` now cites `/applying-custom-css-styles/`
  - `perfex-security` now cites `/module-security/`
- **`perfex-module-dev` — new "Inter-module dependencies" section.** Documents the `Requires Module:` header convention, runtime defensive-load pattern, the activation-order problem (neither order works without guards), what happens when a dependency uninstalls (no hook fires — guard every call), and why cross-module path hardcoding breaks.
- **`perfex-email` — new "Common SMTP pitfalls" section.** Six failure modes that look like application bugs but aren't: misleading `smtp_host`/`smtp_port` errors, enabling `mail_debug` for setup visibility, Gmail/Workspace DMARC `From:` rejection, using `print_debugger()` to see actual SMTP responses, CI's 5-second default `smtp_timeout`, and the `false`-return-without-exception trap.
- **`perfex-theme` — new "Overriding Perfex's Bootstrap 3 — specificity wars" section.** Three strategies (wrapper class, namespaced `!important`, CSS layers) plus three anti-patterns (blanket `!important`, relying on core-internal IDs, editing the default theme in place).
- **README "See the difference" section** — side-by-side `get_option()` broken-vs-correct comparison at the top.
- **README FAQ section** — 7 Qs covering Agent Skill basics, Perfex version coverage, Cursor/Codex compatibility, no-telemetry assurance, CodeCanyon-fork handling, offline operation, release cadence, contribution path.
- **README "Perfex version coverage" callout** — explicit coverage statement (2.9–3.x tested, most rules apply back to 2.3+, SaaS forks not covered).

### Verified

Audit against https://help.perfexcrm.com/ (2026-04-15) confirmed the following specific claims hold against official docs or live Perfex core source:
- `get_option()` doesn't accept a default parameter
- `tblcustomfields` uses `only_admin` and preserves the `disalow_client_to_edit` typo
- `$this->emails_model->send_simple_email($to, $subject, $body)` signature
- Signed-INT FK convention for core tables
- Module file header format (`Version:`, `Requires at least:`)

No factual conflicts found beyond the 3 corrected hook names.

## [1.0.0] — 2026-04-15

First tagged release.

### Skills

Seven Agent Skills, each spec-compliant per [agentskills.io/specification](https://agentskills.io/specification), each triggered independently by Claude / Cursor / Codex / any spec-compatible agent:

- **`perfex-core-apis`** — Perfex helper functions, hooks (`do_action`/`apply_filters`), CI loader, auth helpers, logging. Prevents the `get_option('key', 'default')` trap where the second argument is silently ignored.
- **`perfex-module-dev`** — Module lifecycle, `install.php`, controllers extending `AdminController`/`ClientsController`, routes, views, language files, Linux case-sensitivity trap.
- **`perfex-database`** — Schema conventions, signed-INT FK rule for core tables (`tblcontacts`/`tblstaff`/`tblclients`), utf8mb4 index limit, idempotent migrations, production schema-drift handling.
- **`perfex-security`** — TOCTOU-safe single-use tokens, rate-limited enumeration-oracle endpoints, open-redirect guards, cross-module dependency loading, PII-safe logging, `target="_blank"` rules, CSRF exclusions for webhooks.
- **`perfex-email`** — `$this->emails_model->send_simple_email`, template rendering, admin-recipient fallback chain, exponential-backoff retry queue via `after_cron_run`.
- **`perfex-customfields`** — `tblcustomfields` schema quirks (`only_admin`, the `disalow_client_to_edit` typo preserved), field types, `fieldto` values, `bs_column`, programmatic install, `render_custom_fields()`.
- **`perfex-theme`** — Custom client-area themes, asset hooks (`app_customers_head`/`app_customers_footer`), dark mode with anti-FOUC, RTL support, jQuery Validate submit-button-name bug, `filemtime()` cache-busting.

Each SKILL.md:
- Frontmatter: `name` + `description` (under 1024 chars, with colloquial trigger phrases) + `license: MIT` + `metadata.author`/`metadata.version`
- Body opens with a second-person persona paragraph
- Ends with a `## Related skills` section for cross-skill discovery

### Infrastructure

- **`.claude-plugin/marketplace.json`** — repo is installable as a Claude Code plugin
- **`validate-skills.sh`** — zero-dependency bash validator for the Agent Skills spec
- **`validate-skills-official.sh`** — wrapper around the canonical `agentskills/skills-ref` library
- **`.github/workflows/validate-skills.yml`** — CI runs both validators on every push and PR
- **`VERSIONS.md`** — per-skill version table aligned to repo tags
- **`AGENTS.md`** — instructions for AI agents editing this repo
- **`CONTRIBUTING.md`** — versioning policy (description-as-public-API framing, MAJOR/MINOR/PATCH semantics, release cadence — "when NOT to cut a tag")
- **`README.md`** — public intro + 8 hard rules that apply across every skill
- **Issue + PR templates** under `.github/`

### The 8 hard rules enforced across every skill

1. `get_option('key') ?: 'default'` — never `get_option('key', 'default')`
2. FKs to core tables (`tblcontacts`/`tblstaff`/`tblclients`) must be signed `INT`
3. Production schema may differ from `install.php` — verify with `SHOW CREATE TABLE`
4. `tblcustomfields.disalow_client_to_edit` — preserve the typo
5. `tblcustomfields.only_admin` — not `only_admin_area`
6. Every `target="_blank"` pairs with `rel="noopener noreferrer"`
7. Migrations are idempotent (`field_exists`/`table_exists` guards)
8. Email failures must not fail the user flow

### Provenance

Distilled from ~3 years of [Fennec360](https://fennec360.com) Perfex production. Every rule traces to a real incident.

[Unreleased]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yasserstudio/perfex-crm-skills/releases/tag/v1.0.0
