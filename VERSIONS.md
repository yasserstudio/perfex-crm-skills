# Versions

Per-skill versions, aligned to repo tags. Agents consuming these skills can compare against local versions to detect upgrades.

| Skill | Version | Last Updated | Repo Tag |
|---|---|---|---|
| `perfex-core-apis` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-module-dev` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-database` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-security` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-email` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-customfields` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-theme` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-payment-gateway` | 1.4.0 | 2026-05-16 | v1.4.0 |
| `perfex-pdf` | 1.4.0 | 2026-05-16 | v1.4.0 |

Repo-wide tag in the last column reflects the release where this skill last appeared at its current version. See [CHANGELOG.md](CHANGELOG.md) for full repo release notes.

## Recent changes

### 2026-05-16 — v1.4.0

Major content release. Two new skills, all existing skills updated with Perfex 3.2.0–3.4.1 coverage.

- **New skill:** `perfex-payment-gateway` — `App_gateway` class, `register_payment_gateway()`, encrypted settings, webhook CSRF exclusion, Stripe Basil API changes.
- **New skill:** `perfex-pdf` — TCPDF templates, `my_` prefix override convention, `App_items_table`, font selection, e-invoice JSON/XML (3.4.0+).
- **Updated:** `perfex-core-apis` — 6 new hooks from 3.2.0/3.3.0, `after_invoice_added` timing change, `register_cron_task()`, `register_language_files()`, `module_dir_url/path`, `module_libs_path`.
- **Updated:** `perfex-module-dev` — PHP 8.1 minimum (3.2.0), PHP 8.4 session compat (3.3.0), `register_cron_task()` pattern, `Requires at least:` version header.
- **Updated:** `perfex-database` — version bump for cross-skill consistency.
- **Updated:** `perfex-security` — deserialization CVE (3.4.1), CSRF filter hook pattern, cross-ref to payment-gateway skill.
- **Updated:** `perfex-email` — email language fallback chain (customer → staff → system default → skip).
- **Updated:** `perfex-customfields` — required item custom field validation enforcement (3.3.0).
- **Updated:** `perfex-theme` — `assets/css/custom.css` update-safe path, Theme Style module documentation.

### 2026-04-22 — v1.3.0

- **Added:** `perfex-database` — `dbforge->add_column` prefix trap, dynamic column pattern, `list_fields` vs `field_exists`.
- **Added:** `perfex-core-apis` — `render_*` form helpers, `total_rows()` UI gate gotcha.

### 2026-04-15 — v1.2.0

Mixed patch/minor release. Same-day as v1.1.0 because a real runtime bug was found via dry-run testing against a client Perfex install and shipped alongside the legal pass and README reorg.

- **Fixed:** `app_hash()` → `app_generate_hash()` (runtime bug — `app_hash()` does not exist in Perfex core; agents following v1.1.0 guidance would hit fatal PHP errors).
- **Added:** `THIRD_PARTY_NOTICES.md`, README "Trademarks and affiliation" section, CONTRIBUTING "Contributor license" section.
- **Changed:** LICENSE copyright tightened ("Yasser's studio"); README reorganized (install split into 3 options + try-it, FAQ consolidated, version-coverage/not-covered merged in, broken anchor fixed).
- **Repo metadata:** added `claude-plugin` + `codex` topics (12 total), homepage URL → `/releases/latest`, description tightened, Wiki + Projects disabled.

### 2026-04-15 — v1.1.0

Real content release: factual hook-name corrections, broken-link fixes, 5 new official-doc citations, 3 new content sections (inter-module deps, SMTP pitfalls, Bootstrap specificity), pain-first README hero, FAQ, 10 GitHub topics. All 7 skills bumped 1.0.0 → 1.1.0.

### 2026-04-15 — v1.0.0

First tagged release. All 7 skills debut at 1.0.0. See [CHANGELOG.md](CHANGELOG.md#100--2026-04-15) for the full list of what each skill covers and the 8 hard rules enforced across all of them.

## How to interpret this table

- **Skill version** bumps on a skill-by-skill basis when that skill's `SKILL.md` meaningfully changes. Description changes (triggering behavior) count; typo fixes don't.
- **Repo tag** is where the CURRENT skill version last appeared. If a skill has been at 1.2.0 since the v1.4.0 repo tag, that's still 1.2.0 here — it didn't change in v1.5.0, v1.6.0, etc.
- **Last updated** is the date of the most recent `SKILL.md` edit, whether or not the version changed.

See [CONTRIBUTING.md](CONTRIBUTING.md#release-cadence--build-in-public) for the MAJOR/MINOR/PATCH semantics and release cadence.
