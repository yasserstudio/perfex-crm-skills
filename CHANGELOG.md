# Changelog

All notable changes to this repo are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as applied to agent skills — see [CONTRIBUTING.md](CONTRIBUTING.md#versioning-policy) for what constitutes MAJOR / MINOR / PATCH in this context.

> **Why versioning matters for skills:** the `description` field in each SKILL.md frontmatter is what Claude uses to decide when to trigger the skill. A description change is a behavior change. This changelog flags triggering-relevant changes explicitly so users who pin to a tag can audit what their agent will do differently after an upgrade.

## [Unreleased]

_Nothing yet._

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
