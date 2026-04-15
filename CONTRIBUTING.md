# Contributing

Thanks for thinking about contributing. This repo is small on purpose — one router + seven focused skills — and the bar for adding content is intentionally high. Read this before opening a PR.

## The bar for new content

Every rule, pattern, or gotcha in these skills exists because its absence caused a real production bug on a real Perfex install. Speculative advice, "it would be nice if the agent knew…", and stylistic preferences get rejected. If you're adding a gotcha, cite:

1. What the symptom was (error message, silent failure, bug behavior).
2. What the root cause was.
3. Why a general coding agent would get this wrong without the skill.

If you can't write those three things, the gotcha probably isn't ready for the skill yet.

## Repo layout

```
perfex-crm-skills/
├── README.md              # Hard rules + skills table + install
├── CONTRIBUTING.md        # This file
├── CHANGELOG.md           # Keep-a-changelog, SemVer tagged
├── LICENSE                # MIT
└── skills/
    ├── perfex-core-apis/SKILL.md
    ├── perfex-module-dev/SKILL.md
    ├── ...
```

Each skill is a directory containing a single `SKILL.md`. If a skill grows beyond 500 lines, split reference material into a sibling `references/` folder inside that skill — don't fork it into a new skill unless it's genuinely a different class of work.

## SKILL.md requirements

Each SKILL.md must conform to [agentskills.io/specification](https://agentskills.io/specification):

- Frontmatter has `name` (lowercase + hyphens, matches parent directory) and `description` (under 1024 chars)
- Body under ~500 lines
- `license: MIT` and `metadata.author` / `metadata.version` preserved

Before opening a PR, validate with:

```bash
npx skills-ref validate ./skills/<your-skill>
```

## Versioning policy

This repo uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html), adapted for agent skills. The non-obvious part: **a skill's `description` field is its public API** — it determines when Claude triggers the skill. Description changes are behavior changes, and the bump level reflects that.

| Change | Bump | Example |
|---|---|---|
| Remove or rename a skill | **MAJOR** | Merging `perfex-email` into `perfex-core-apis` |
| Restructure repo layout | **MAJOR** | Un-nesting `skills/`, breaking existing `npx skills add` installs |
| Materially rewrite a hard rule | **MAJOR** | Telling the agent to do the opposite of what v1 said |
| Narrow a description | **MAJOR** | Removing trigger keywords so the skill stops firing on phrases it used to cover |
| Add a new skill | **MINOR** | Shipping `perfex-api` for REST endpoints |
| Add a new section to an existing SKILL.md | **MINOR** | New "Common pitfalls" subsection |
| Broaden a description | **MINOR** | Adding new trigger keywords, no removals |
| Typo fixes, clarifications, examples | **PATCH** | Fixing a copy-paste error in a code sample |
| Added external doc links | **PATCH** | Linking to a new Perfex help article |
| Tightened wording (no triggering change) | **PATCH** | Shortening a paragraph without changing what it says |

All seven skills share a single repo version. Per-skill `metadata.version` in each SKILL.md is bumped together with the repo tag — this is simpler than per-skill versioning and 7 skills isn't enough volume to justify the overhead.

## Release process

1. Update `CHANGELOG.md` — move relevant items from `[Unreleased]` into a new dated version section.
2. Bump `metadata.version` in every SKILL.md that changed (or all of them, to keep them aligned).
3. Commit with message like `Release v1.2.0: <short summary>`.
4. Tag:
   ```bash
   git tag -a v1.2.0 -m "v1.2.0: <short summary>"
   git push origin main --tags
   ```
5. Create a GitHub Release from the tag, pasting the changelog section as the body:
   ```bash
   gh release create v1.2.0 --title "v1.2.0" --notes-from-tag
   ```

Tags are cut on meaningful changes, not on a time schedule. Most users will `npx skills add <repo>` (which tracks `main`); tags give people who want stability a pin target and give everyone a clear audit trail for triggering changes.

## PR checklist

- [ ] Change cites a real production bug / gotcha (not hypothetical).
- [ ] SKILL.md validates (`npx skills-ref validate`).
- [ ] SKILL.md body still under 500 lines.
- [ ] Description still under 1024 chars.
- [ ] CHANGELOG.md `[Unreleased]` section updated.
- [ ] If description was changed, note whether it broadens or narrows triggering (this dictates MINOR vs MAJOR on next release).
- [ ] No copied content from `perfexcrm.com` / `help.perfexcrm.com` — link out, don't mirror. Perfex is commercial software.

## What not to contribute

- **Copied Perfex documentation.** Perfex is sold on CodeCanyon under a commercial license. We link to their docs; we don't mirror them.
- **Secrets or PII in examples.** Even fake-looking credentials get picked up by scanners.
- **Generic CodeIgniter 3 advice.** Use a general CI3 skill for that. This repo is Perfex-specific.
- **Third-party CodeCanyon module patterns.** Those authors own their conventions.

## Questions

Open an issue. For anything security-sensitive (a gotcha that would let someone exploit a real Perfex install), email the maintainer privately before opening a public issue.
