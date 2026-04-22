# Versions

Per-skill versions, aligned to repo tags. Agents consuming these skills can compare against local versions to detect upgrades.

| Skill | Version | Last Updated | Repo Tag |
|---|---|---|---|
| `perfex-core-apis` | 1.3.0 | 2026-04-22 | v1.3.0 |
| `perfex-module-dev` | 1.2.0 | 2026-04-15 | v1.2.0 |
| `perfex-database` | 1.3.0 | 2026-04-22 | v1.3.0 |
| `perfex-security` | 1.2.0 | 2026-04-15 | v1.2.0 |
| `perfex-email` | 1.2.0 | 2026-04-15 | v1.2.0 |
| `perfex-customfields` | 1.2.0 | 2026-04-15 | v1.2.0 |
| `perfex-theme` | 1.2.0 | 2026-04-15 | v1.2.0 |

Repo-wide tag in the last column reflects the release where this skill last appeared at its current version. See [CHANGELOG.md](CHANGELOG.md) for full repo release notes.

## Recent changes

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
