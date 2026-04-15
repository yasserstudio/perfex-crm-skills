# AGENTS.md — instructions for agents editing this repo

This file tells AI coding agents (Claude Code, Cursor, Codex, etc.) how to work on *this repo itself* — i.e. when you're adding a new Perfex gotcha, fixing a typo, or shipping a new skill. It's not for agents *consuming* these skills at runtime; those agents read the individual `SKILL.md` files under `skills/`.

## Ground rules

1. **Every new rule must cite a real production bug.** Speculative advice gets rejected. If you can't write "symptom → root cause → why a general agent would get it wrong," the rule isn't ready.

2. **Don't copy Perfex docs.** Perfex is commercial software sold on CodeCanyon. Link to `help.perfexcrm.com`; don't mirror their content into `references/`.

3. **Keep each SKILL.md under 500 lines and each description under 1024 chars.** The Agent Skills spec limits these, and the validator will fail the PR if you bust them.

4. **Run the validator before committing.**
   ```bash
   ./validate-skills.sh
   ```
   CI will also run this on every PR.

## Where things live

| Path | Purpose |
|---|---|
| `skills/<name>/SKILL.md` | The skill itself — frontmatter + instructions |
| `skills/<name>/references/*.md` | (optional) overflow content loaded on demand |
| `skills/<name>/scripts/` | (optional) executable helpers |
| `skills/<name>/assets/` | (optional) templates, fixtures |
| `.claude-plugin/marketplace.json` | Plugin manifest — list any new skill here |
| `README.md` | Public-facing intro + the 8 hard rules |
| `CHANGELOG.md` | Keep-a-changelog, one section per tagged release |
| `VERSIONS.md` | Per-skill version table + dated change notes |
| `CONTRIBUTING.md` | Versioning policy, PR checklist |
| `validate-skills.sh` | Zero-dep validator |
| `validate-skills-official.sh` | Runs the canonical `agentskills/skills-ref` validator |

## Frontmatter required shape

```yaml
---
name: perfex-xxx          # must match dir name, lowercase + hyphens, 1-64 chars
description: ...          # 1-1024 chars, pushy, with concrete trigger keywords
license: MIT
metadata:
  author: yasserstudio
  version: "1.0.0"
---
```

## Adding a new skill

1. Create `skills/<new-skill>/SKILL.md` with full frontmatter.
2. Add `"./skills/<new-skill>"` to the `skills` array in `.claude-plugin/marketplace.json`.
3. Add a row to `VERSIONS.md`.
4. Add a skill entry to the README's skills table.
5. Add a CHANGELOG entry under `[Unreleased]` → `### Added`.
6. Run `./validate-skills.sh`.
7. On release, bump `metadata.version` to `1.0.0`, tag the repo (MINOR bump).

## Editing an existing skill

- **Triggering-relevant changes** (description, name): bump skill's `metadata.version` appropriately (see CONTRIBUTING.md semantics) and update VERSIONS.md.
- **Body-only changes** (new section, typo, example): update `Last Updated` in VERSIONS.md, bump skill version if material.
- Always add a CHANGELOG entry.

## Release workflow

See [CONTRIBUTING.md#release-process](CONTRIBUTING.md#release-process). TL;DR:

```bash
# After merging the release PR:
git tag -a vX.Y.Z -m "vX.Y.Z: <summary>"
git push origin main --tags
gh release create vX.Y.Z --title "vX.Y.Z — <summary>" --notes-from-tag
```

## What NOT to do

- Don't add a skill for a domain this repo doesn't cover (e.g. a generic CodeIgniter skill, a WordPress-Perfex bridge). Open an issue first.
- Don't refactor skill layouts or rename skills without flagging it as a MAJOR bump — those changes break anyone pinned to an earlier tag.
- Don't add `references/` material unless a SKILL.md has genuinely hit the 500-line limit. Consolidated content is easier for humans to read.
- Don't commit credentials, PII, or real tokens even in examples.

## Memory note for AI agents

If you're working on this repo across multiple sessions, nothing here needs persistent memory — this file and CONTRIBUTING.md are the source of truth. Don't save "how to work on perfex-crm-skills" as a memory; read this file fresh each time.
