# Changelog

All notable changes to this repo are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as applied to agent skills — see [CONTRIBUTING.md](CONTRIBUTING.md#versioning-policy) for what constitutes MAJOR / MINOR / PATCH in this context.

> **Why versioning matters for skills:** the `description` field in each SKILL.md frontmatter is what Claude uses to decide when to trigger the skill. A description change is a behavior change. This changelog flags triggering-relevant changes explicitly so users who pin to a tag can audit what their agent will do differently after an upgrade.

## [Unreleased]

_Nothing yet._

## [1.1.0] — 2026-04-15

### Added

- `.claude-plugin/marketplace.json` — repo is now installable as a Claude Code plugin, not just a skills folder.
- `validate-skills.sh` — zero-dependency bash validator for the Agent Skills spec (frontmatter, name pattern, description length, body line count).
- `validate-skills-official.sh` — wrapper that runs the canonical `agentskills/skills-ref` validator.
- `.github/workflows/validate-skills.yml` — GitHub Actions CI runs both validators on every push and PR.
- `VERSIONS.md` — per-skill version table aligned to repo tags, plus dated change notes.
- `AGENTS.md` — instructions for AI agents editing this repo itself.
- `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/` — standard OSS contribution templates.

### Notes

- **Infrastructure-only release.** No skill content or descriptions changed. Per-skill versions remain at 1.0.0. Agents consuming these skills at v1.1.0 will trigger identically to v1.0.0.

## [1.0.0] — 2026-04-15

### Added

- Initial public release.
- **`perfex-core-apis`** — Perfex helper functions, hooks, CI loader, auth helpers, logging. Covers the `get_option('key', 'default')` trap.
- **`perfex-module-dev`** — Module lifecycle, `install.php`, controllers, routes, views, language files. Covers Linux case-sensitivity trap.
- **`perfex-database`** — Schema conventions, signed-INT FK rule for core tables, utf8mb4 index limit, idempotent migrations.
- **`perfex-security`** — TOCTOU-safe token consume, rate limiting, open-redirect guards, cross-module dependency loading, PII in logs, `target="_blank"` rules, CSRF exclusions.
- **`perfex-email`** — `send_simple_email`, template rendering, admin-recipient fallback chain, exponential-backoff retry queue.
- **`perfex-customfields`** — `tblcustomfields` schema quirks (`only_admin`, `disalow_client_to_edit` typo), field types, programmatic install, `render_custom_fields()`.
- **`perfex-theme`** — Custom client-area themes, asset hooks, jQuery Validate submit-button-name bug, dark mode with anti-FOUC, RTL support.
- Repo-level `README.md` with the 8 hard rules that apply across every skill.
- Spec-compliant structure: skills nested under `skills/`, each SKILL.md with `name` + `description` + `license` + `metadata` frontmatter, bodies under 500 lines, descriptions under 1024 chars per [agentskills.io specification](https://agentskills.io/specification).

[Unreleased]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/yasserstudio/perfex-crm-skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yasserstudio/perfex-crm-skills/releases/tag/v1.0.0
