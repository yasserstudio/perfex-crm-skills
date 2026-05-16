# Changelog

All notable changes to this repo are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as applied to agent skills — see [CONTRIBUTING.md](CONTRIBUTING.md#versioning-policy) for what constitutes MAJOR / MINOR / PATCH in this context.

> **Why versioning matters for skills:** the `description` field in each SKILL.md frontmatter is what Claude uses to decide when to trigger the skill. A description change is a behavior change. This changelog flags triggering-relevant changes explicitly so users who pin to a tag can audit what their agent will do differently after an upgrade.

## [1.4.0] — 2026-05-16

### Added

- **New skill: `perfex-payment-gateway`** — Complete guide to building Perfex payment gateway modules. Covers `App_gateway` class structure, `setId`/`setName`/`setSettings`, `process_payment($data)` implementation, encrypted settings with `decryptSetting()`, webhook CSRF exclusion via filter hook, webhook signature verification, Stripe API (Basil) breaking changes in 3.3.0, and the `register_payment_gateway()` registration pattern. Includes full skeleton with controller for webhook handling.
- **New skill: `perfex-pdf`** — Complete guide to PDF customization. Covers TCPDF template locations, the `my_` prefix override convention (update-safe), font selection for multi-language (freesans/dejavusans/droidsansfallback), `App_items_table` column customization via hooks, PDF heading language strings, logo configuration, paper size settings, adding custom field data to templates, e-invoice JSON/XML support (3.4.0+), and common pitfalls (blank PDF, RTL, TCPDF CSS limitations).
- **`perfex-core-apis`: 6 new hooks from Perfex 3.2.0/3.3.0** — `get_country`, `customers_navigation_before_logout`, `before_admin_ticket_addreply_tabpanel_content`, `after_total_summary_estimatehtml`, `after_total_summary_invoicehtml`, `estimatepdf_organization_info`.
- **`perfex-core-apis`: `after_invoice_added` timing change** — Documents that this hook now fires before email sending (changed in 3.2.0). Modules that assumed the invoice email was already sent when this hook fires need adjustment.
- **`perfex-core-apis`: 5 new helper functions** — `register_cron_task()`, `register_language_files()`, `module_dir_url()`, `module_dir_path()`, `module_libs_path()`.
- **`perfex-module-dev`: PHP version requirements table** — Documents minimum PHP 8.1 for Perfex 3.2.0+, PHP 8.4 session compatibility changes in 3.3.0 (all users logged out during update).
- **`perfex-module-dev`: `register_cron_task()` pattern** — Preferred over raw `after_cron_run` hook for module cron work. Includes cron URL and recommended interval.
- **`perfex-email`: email language fallback chain** — Documents resolution order (customer language → staff language → system default → skip if empty). Covers template-per-language disabling behavior.
- **`perfex-customfields`: required item custom field enforcement** — Perfex 3.3.0 now server-side validates required select-type item custom fields. Modules creating invoice items programmatically must populate these or save fails.
- **`perfex-theme`: update-safe CSS methods** — Documents `assets/css/custom.css` (auto-loaded, survives updates) and Theme Style module (DB-stored CSS editor with admin/client separation).
- **`perfex-security`: deserialization vulnerability note** — References the critical RCE patched in 3.4.1 (insecure deserialization in bundled library). Includes defensive guidance for module developers.
- **`perfex-security`: CSRF exclusion via filter hook** — Cleaner pattern using `hooks()->add_filter('csrf_exclude_uris', ...)` instead of manual config.php editing.

### Changed

- All 9 skills (7 existing + 2 new) now at version 1.4.0.
- README updated with 9 skills table, Perfex 3.4.x coverage note.
- Related skills sections updated across all skills to cross-reference new `perfex-payment-gateway` and `perfex-pdf` skills.

### Verified

Audit against https://help.perfexcrm.com/ (2026-05-16) confirmed:
- All 6 new hooks exist in documented changelogs for 3.2.0 and 3.3.0
- `register_payment_gateway` API matches official docs
- PDF `my_` prefix convention matches official docs
- `register_cron_task()` matches `/common-module-functions/` documentation
- PHP 8.1 minimum enforced from 3.2.0
- 3.4.1 security advisory confirmed (unauthenticated RCE via insecure deserialization)
- No new broken links in upstream doc references

## [1.3.0] — 2026-04-22

### Added

- **`perfex-database`: `dbforge->add_column` prefix trap** — CI3's `dbforge->add_column()` auto-prepends `dbprefix`, so passing `db_prefix() . 'table'` produces `tbltbltable`. Documented the asymmetry: `list_fields()` needs the prefix, `add_column()` does not. Includes correct/incorrect code examples.
- **`perfex-database`: `list_fields()` vs `field_exists()`** — when to use each for column existence checks. `field_exists()` for one-off guards, `list_fields()` when looping over multiple columns.
- **`perfex-database`: dynamic column pattern** — documented Perfex's `rate_currency_X` pattern for per-currency item pricing with auto-created columns via `dbforge`. Covers creation, deletion cleanup, import/export discovery, and when to use a junction table instead.
- **`perfex-core-apis`: `render_*` form helpers** — documented `render_input()`, `render_textarea()`, `render_select()` with signatures, label resolution (lang key vs raw string), and when to fall back to raw HTML.
- **`perfex-core-apis`: `total_rows()` UI gate gotcha** — Perfex core views sometimes use `total_rows()` checks to conditionally show form fields, creating chicken-and-egg problems (can't configure a feature until a dependent record exists). Documented the pattern and when to remove the check.

## [1.2.1] — 2026-04-22

### Changed

- **Anonymized the specific client name** across all public files in the repo. Every reference to the maintaining client now reads as "a client" / "a client project" / "a client's Perfex install" / similar. 11 mentions scrubbed across `README.md`, `CHANGELOG.md`, `VERSIONS.md`, `THIRD_PARTY_NOTICES.md`, and one skill body (`skills/perfex-theme/SKILL.md`). GitHub `v1.2.0` release notes edited via `gh release edit` to scrub one additional reference. `v1.0.0` and `v1.1.0` release notes were already clean.
- **Provenance language preserved.** Claims of "3 years of production" and "verified against live core source" are intact — the authority signal doesn't depend on naming the client.

### Note on commit history

Historical commit messages (before this commit) still reference the client name. Rewriting git history is destructive (invalidates existing clones, breaks GitHub permalinks, strips signatures). Forward-only scrub from this commit onward. Anyone performing a full `git log --all` audit can find the historical references; the bet is the active surface (README, CHANGELOG, release notes, search engines, LLM citations) is what matters.

## [1.2.0] — 2026-04-15

Mixed patch/minor release. Shipped same-day as v1.1.0 because a runtime bug was found via dry-run testing against a real client Perfex install and made sense to ship alongside the legal pass + README reorganization that had also accumulated. Zero pinners at v1.1.0 at release time; tight cadence didn't disrupt anyone.

### Fixed

- **`app_hash()` → `app_generate_hash()`** across `perfex-core-apis` and `perfex-security`. The `app_hash()` function **does not exist** in Perfex core (verified against `/application/helpers/general_helper.php` in a live client Perfex install) — the correct name is `app_generate_hash()`. Five references fixed: helper-reference table, two "Related skills" cross-refs, one code example (`$token = app_generate_hash()`), and the skill's `description` trigger-keywords. An agent following the previous guidance would have generated `$token = app_hash();` and hit a fatal PHP error at runtime. Same class of bug as the `after_contact_added` → `contact_created` hook-name fix in v1.1.0.

### Added

- **`THIRD_PARTY_NOTICES.md`** — acknowledges dependencies on `agentskills/skills-ref` (Apache-2.0, runtime-only), the Agent Skills specification, `anthropics/skills` (studied for structure), `coreyhaines31/marketingskills` (used for content audit), and upstream Perfex CRM docs/source (linked only, never mirrored).
- **README "Trademarks and affiliation" section** — nominatively credits Perfex CRM®, Claude™/Claude Code™/Anthropic®, Cursor®, Codex®/OpenAI®, and the AgentSkills spec. Clarifies the repo is independent and not affiliated with any named vendor.
- **CONTRIBUTING.md "Contributor license" section** — explicit statement that PR contributions are assumed MIT-licensed, without requiring a separate CLA.

### Changed

- **LICENSE copyright holder** tightened from "Yasser (yasserstudio)" to "Yasser's studio".

## [1.1.0] — 2026-04-15

**Real content release.** Factual corrections, new sections, improved discoverability. Shipped in build-in-public mode (see [CONTRIBUTING.md](CONTRIBUTING.md#release-cadence--build-in-public)).

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

Distilled from ~3 years of maintaining a client's Perfex production install. Every rule traces to a real incident.

[Unreleased]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yasserstudio/perfex-crm-skills/releases/tag/v1.0.0
