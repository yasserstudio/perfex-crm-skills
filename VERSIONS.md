# Versions

Per-skill versions, aligned to repo tags. Agents consuming these skills can compare against local versions to detect upgrades.

| Skill | Version | Last Updated | Repo Tag |
|---|---|---|---|
| `perfex-core-apis` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-module-dev` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-database` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-security` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-email` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-customfields` | 1.1.0 | 2026-04-15 | v1.2.0 |
| `perfex-theme` | 1.1.0 | 2026-04-15 | v1.2.0 |

Repo-wide tag in the last column reflects the release where this skill last appeared at its current version. See [CHANGELOG.md](CHANGELOG.md) for full repo release notes.

## Recent changes

### 2026-04-15 — v1.2.0

- **Content polish across all 7 skills.** Every SKILL.md description broadened with colloquial trigger phrases, every body opens with a second-person persona paragraph, every skill now ends with a `## Related skills` section for cross-skill discovery. Per-skill versions bump 1.0.0 → 1.1.0 on all 7.
- Triggering broadened (MINOR bump per policy): skills now fire on phrases like "my Perfex email isn't sending", "Pay Now button loses its value", "FK won't create in Perfex". No previously-covered triggers were removed.

### 2026-04-15 — v1.1.0

- Infrastructure-only release. No skill content changed; per-skill versions remain at 1.0.0.
- Added `.claude-plugin/marketplace.json` — repo is now installable as a Claude Code plugin.
- Added `validate-skills.sh` (zero-dep) and `validate-skills-official.sh` (uses `agentskills/skills-ref`).
- Added GitHub Actions workflow to validate every PR.
- Added `VERSIONS.md` (this file), issue/PR templates, `AGENTS.md`.

### 2026-04-15 — v1.0.0

- Initial public release. All 7 skills debut at 1.0.0.
- See [CHANGELOG.md](CHANGELOG.md#100--2026-04-15) for the full list of what's in each skill.

## How to interpret this table

- **Skill version** bumps on a skill-by-skill basis when that skill's `SKILL.md` meaningfully changes. Description changes (triggering behavior) count; typo fixes don't.
- **Repo tag** is where the CURRENT skill version last appeared. If a skill has been at 1.2.0 since the v1.4.0 repo tag, that's still 1.2.0 here — it didn't change in v1.5.0, v1.6.0, etc.
- **Last updated** is the date of the most recent `SKILL.md` edit, whether or not the version changed.

See [CONTRIBUTING.md](CONTRIBUTING.md#versioning-policy) for the MAJOR/MINOR/PATCH semantics.
