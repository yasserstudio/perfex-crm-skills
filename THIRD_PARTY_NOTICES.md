# Third-party notices

This repo's own content — the skills themselves, the validator scripts, the documentation — is licensed under [MIT](LICENSE). Some parts of the build and validation toolchain depend on third-party code that ships separately under its own license. This file acknowledges those dependencies.

Nothing in this file is a legal agreement on behalf of those third parties. It's a courtesy acknowledgement so users and contributors can track the licensing chain.

---

## Agent Skills reference library (`agentskills/skills-ref`)

- **Project:** [`agentskills/agentskills`](https://github.com/agentskills/agentskills) (the `skills-ref` Python package within)
- **License:** Apache License 2.0
- **How we use it:** `validate-skills-official.sh` clones the repo into `/tmp/agentskills/` on first run and invokes the `skills-ref` CLI to validate each skill against the canonical [agentskills.io specification](https://agentskills.io/specification).
- **We do not redistribute their code.** Our script fetches it at runtime on the user's machine.
- **Users who run the validator** will have a local copy of `skills-ref` under `/tmp/agentskills/` covered by its own Apache-2.0 license.

## Agent Skills specification

- **Spec:** [agentskills.io/specification](https://agentskills.io/specification)
- **Stewardship:** maintained by the AgentSkills community (see their [GitHub org](https://github.com/agentskills) for current governance).
- **How we use it:** this repo's skills are written to conform to the spec. We cite the spec URL throughout; we don't redistribute the spec text.

## Anthropic skill-creator reference implementation

- **Project:** [`anthropics/skills`](https://github.com/anthropics/skills), specifically the `skills/skill-creator/SKILL.md` document
- **License:** MIT (per repo LICENSE at time of writing)
- **How we use it:** we **studied** it during our initial audit to understand canonical skill structure (frontmatter fields, layout conventions, `references/` pattern). No code or prose was copied into our repo.

## `coreyhaines31/marketingskills`

- **Project:** [`coreyhaines31/marketingskills`](https://github.com/coreyhaines31/marketingskills)
- **License:** MIT
- **How we use it:** we audited our README and skills against the `page-cro`, `copywriting`, `seo-audit`, and `ai-seo` frameworks in that repo. We applied the frameworks to our own content — no text was copied. CHANGELOG credits this audit as the origin of several improvements.

## Perfex CRM documentation

- **Site:** [help.perfexcrm.com](https://help.perfexcrm.com/)
- **License:** commercial; Perfex is sold on CodeCanyon under the Envato commercial license.
- **How we use it:** we **link** to specific pages as "upstream docs" for readers who want official citations. We never mirror, scrape, or republish their content. All prose in this repo is our own, written from production experience maintaining a client's Perfex install.

## Perfex CRM core source (runtime verification)

- **Source:** a live Perfex install on the maintainer's local machine (not part of this repo).
- **License:** commercial (licensed to the client via CodeCanyon purchase).
- **How we use it:** we `grep` it during audits to verify factual claims (hook names, table schemas, function signatures). No core code is copied into this repo.

---

## What's NOT third-party

Every SKILL.md, scripts (`validate-skills.sh`), GitHub Actions workflows, templates under `.github/`, and docs (`README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `CHANGELOG.md`, `VERSIONS.md`, and this file) are **our own work**, licensed MIT.

If you believe something in this repo infringes third-party rights, please open an issue or email the maintainer.
