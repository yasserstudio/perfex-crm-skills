## Summary

<!-- One-liner: what this PR changes and why. -->

## Type of change

- [ ] New skill
- [ ] New gotcha / rule added to existing skill
- [ ] Description change (triggering behavior)
- [ ] Content fix (typo / clarification / example / link)
- [ ] Infrastructure (validator / CI / marketplace.json / docs)

## Real-bug citation (required for new rules)

<!-- Per CONTRIBUTING.md: every new rule must cite a real production bug. -->
<!-- Delete this section if this PR is infra/typo only. -->

**Symptom:**
**Root cause:**
**Why a general agent would get this wrong:**

## Checklist

- [ ] `./validate-skills.sh` passes locally
- [ ] SKILL.md body still under 500 lines
- [ ] Description still under 1024 chars
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `VERSIONS.md` updated if a skill's version bumped
- [ ] `.claude-plugin/marketplace.json` updated if a new skill was added
- [ ] If description changed, noted in PR body whether it broadens or narrows triggering
- [ ] No copied content from `perfexcrm.com` / `help.perfexcrm.com` (link out, don't mirror)

## Version bump (if releasing)

<!-- Per CONTRIBUTING.md#versioning-policy -->
- [ ] MAJOR — removed/renamed skill, narrowed description, rewrote hard rule
- [ ] MINOR — new skill, new section, broadened description
- [ ] PATCH — typo, clarification, link fix
- [ ] N/A — not a release PR
