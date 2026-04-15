# Versions

Per-skill versions, aligned to repo tags. Agents consuming these skills can compare against local versions to detect upgrades.

| Skill | Version | Last Updated | Repo Tag |
|---|---|---|---|
| `perfex-core-apis` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-module-dev` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-database` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-security` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-email` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-customfields` | 1.1.0 | 2026-04-15 | v1.1.0 |
| `perfex-theme` | 1.1.0 | 2026-04-15 | v1.1.0 |

Repo-wide tag in the last column reflects the release where this skill last appeared at its current version. See [CHANGELOG.md](CHANGELOG.md) for full repo release notes.

## Recent changes

### 2026-04-15 — v1.1.0

Real content release with factual corrections and new material.

- **Factual fixes:** `perfex-core-apis` had 3 wrong hook names (`after_contact_added` etc.); corrected to core-verified names (`contact_created`, `contact_updated`, `before_delete_contact`) plus parallel client-company hooks added.
- **Fixed 2 broken `help.perfexcrm.com` links** (404s) in upstream-docs footers.
- **5 new official-doc citations** added across skills from audit vs https://help.perfexcrm.com/.
- **3 new content sections:** Inter-module dependencies (`perfex-module-dev`), Common SMTP pitfalls (`perfex-email`), Bootstrap 3 specificity wars (`perfex-theme`).
- **Marketing polish:** pain-first README hero, "See the difference" code comparison, FAQ section (7 Qs), 10 GitHub topics set, homepage URL set, repo description rewritten.

All 7 skills bumped 1.0.0 → 1.1.0 together.

### 2026-04-15 — v1.0.0

First tagged release. All 7 skills debut at 1.0.0. See [CHANGELOG.md](CHANGELOG.md#100--2026-04-15) for the full list of what each skill covers and the 8 hard rules enforced across all of them.

## How to interpret this table

- **Skill version** bumps on a skill-by-skill basis when that skill's `SKILL.md` meaningfully changes. Description changes (triggering behavior) count; typo fixes don't.
- **Repo tag** is where the CURRENT skill version last appeared. If a skill has been at 1.2.0 since the v1.4.0 repo tag, that's still 1.2.0 here — it didn't change in v1.5.0, v1.6.0, etc.
- **Last updated** is the date of the most recent `SKILL.md` edit, whether or not the version changed.

See [CONTRIBUTING.md](CONTRIBUTING.md#release-cadence--build-in-public) for the MAJOR/MINOR/PATCH semantics and release cadence.
