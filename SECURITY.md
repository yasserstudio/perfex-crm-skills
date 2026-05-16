# Security Policy

## Scope

This repository contains **markdown skill files only** — no executable code, no dependencies, no runtime. The attack surface is limited to:

1. **Incorrect security guidance** in skill content that could lead an AI agent to generate vulnerable Perfex code
2. **Malicious content injection** via pull requests that could mislead AI agents into producing insecure code

## Supported versions

| Version | Supported |
|---|---|
| Latest release (currently v1.4.0) | Yes |
| Previous minor (v1.3.x) | Security fixes only |
| Older versions | No |

## Reporting a vulnerability

If you find incorrect security guidance in any skill (e.g., a pattern that introduces SQL injection, XSS, CSRF bypass, or other vulnerabilities when an AI agent follows it):

1. **Do NOT open a public issue** — the incorrect guidance could be followed by agents before it's fixed
2. **Email:** gorthidz@gmail.com with subject line `[SECURITY] perfex-crm-skills`
3. **Include:**
   - Which skill file and section
   - What the current guidance produces (the vulnerable code)
   - What the correct guidance should be
   - A brief explanation of the exploit scenario

## Response timeline

- **Acknowledgment:** Within 48 hours
- **Fix:** Within 7 days for confirmed issues
- **Disclosure:** After fix is released, credited in CHANGELOG unless you prefer anonymity

## What qualifies

- A skill pattern that produces code vulnerable to OWASP Top 10
- A security rule that is factually wrong for the stated Perfex version
- Missing security guidance where the absence leads to a common vulnerability (e.g., no mention of input validation in a section about handling user input)

## What does NOT qualify

- Generic PHP/CI3 security issues not specific to Perfex
- Theoretical vulnerabilities that require non-standard Perfex configurations
- Issues in Perfex CRM core itself (report those to the Perfex vendor)
