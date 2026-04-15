#!/usr/bin/env bash
#
# Validate every SKILL.md in skills/ against the Agent Skills spec
# (https://agentskills.io/specification) — no external dependencies.
#
# Use validate-skills-official.sh for validation via the canonical
# `skills-ref` Python library.
#
# Checks:
#   • directory name matches `name` frontmatter field
#   • `name` is 1–64 chars, /^[a-z0-9](-?[a-z0-9]+)*$/ (no leading/trailing/consecutive hyphens)
#   • `description` is 1–1024 chars
#   • SKILL.md body is ≤ 500 lines
#   • `license` and `metadata` present (soft-warning if missing)
#
# Exits 1 on any hard error, 0 otherwise.

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

errors=0
warnings=0
passed=0

echo -e "${BLUE}Validating skills in:${NC} $SKILLS_DIR"
echo "Ref: https://agentskills.io/specification"
echo

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo -e "${RED}ERROR:${NC} skills/ directory not found"
  exit 1
fi

for dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$dir")"
  skill_md="$dir/SKILL.md"
  local_errors=0
  local_warnings=0

  echo -e "${BLUE}→${NC} $skill_name"

  # 1. SKILL.md exists
  if [[ ! -f "$skill_md" ]]; then
    echo -e "  ${RED}✗${NC} missing SKILL.md"
    errors=$((errors + 1))
    continue
  fi

  # 2. Frontmatter delimiters
  if ! head -n 1 "$skill_md" | grep -q '^---$'; then
    echo -e "  ${RED}✗${NC} SKILL.md does not start with YAML frontmatter (---)"
    local_errors=$((local_errors + 1))
  fi

  # Extract frontmatter (between first two ---)
  frontmatter="$(awk '/^---$/{c++; next} c==1{print} c==2{exit}' "$skill_md")"

  # 3. name field
  name_val="$(echo "$frontmatter" | awk -F': *' '/^name:/ {print $2; exit}')"
  if [[ -z "$name_val" ]]; then
    echo -e "  ${RED}✗${NC} missing 'name' in frontmatter"
    local_errors=$((local_errors + 1))
  else
    # Length 1-64
    if [[ ${#name_val} -lt 1 || ${#name_val} -gt 64 ]]; then
      echo -e "  ${RED}✗${NC} name length (${#name_val}) must be 1-64"
      local_errors=$((local_errors + 1))
    fi
    # Pattern: lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens
    if ! [[ "$name_val" =~ ^[a-z0-9]([a-z0-9]|-[a-z0-9])*$ ]]; then
      echo -e "  ${RED}✗${NC} name '$name_val' violates pattern (lowercase a-z/0-9, single hyphens, no leading/trailing)"
      local_errors=$((local_errors + 1))
    fi
    # Must match directory name
    if [[ "$name_val" != "$skill_name" ]]; then
      echo -e "  ${RED}✗${NC} name '$name_val' does not match directory '$skill_name'"
      local_errors=$((local_errors + 1))
    fi
  fi

  # 4. description field (may span multiple lines if wrapped, but in our convention it's single-line)
  desc_val="$(echo "$frontmatter" | awk '/^description:/{sub(/^description: */, ""); print; exit}')"
  if [[ -z "$desc_val" ]]; then
    echo -e "  ${RED}✗${NC} missing 'description' in frontmatter"
    local_errors=$((local_errors + 1))
  else
    desc_len=${#desc_val}
    if [[ $desc_len -lt 1 || $desc_len -gt 1024 ]]; then
      echo -e "  ${RED}✗${NC} description length ($desc_len) must be 1-1024"
      local_errors=$((local_errors + 1))
    fi
  fi

  # 5. Body line count (≤ 500 lines recommended)
  body_lines="$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$skill_md" | wc -l | tr -d ' ')"
  if [[ $body_lines -gt 500 ]]; then
    echo -e "  ${YELLOW}⚠${NC} body is $body_lines lines (recommended: ≤ 500)"
    local_warnings=$((local_warnings + 1))
  fi

  # 6. Soft: license / metadata present
  if ! echo "$frontmatter" | grep -q '^license:'; then
    echo -e "  ${YELLOW}⚠${NC} no 'license' field (optional but recommended)"
    local_warnings=$((local_warnings + 1))
  fi
  if ! echo "$frontmatter" | grep -q '^metadata:'; then
    echo -e "  ${YELLOW}⚠${NC} no 'metadata' field (optional but recommended)"
    local_warnings=$((local_warnings + 1))
  fi

  if [[ $local_errors -eq 0 ]]; then
    if [[ $local_warnings -eq 0 ]]; then
      echo -e "  ${GREEN}✓${NC} valid"
    else
      echo -e "  ${GREEN}✓${NC} valid ($local_warnings warning$( [[ $local_warnings -eq 1 ]] || echo s))"
    fi
    passed=$((passed + 1))
  fi
  errors=$((errors + local_errors))
  warnings=$((warnings + local_warnings))

  echo
done

echo "───────────────────────────────────"
echo -e "${GREEN}Passed:${NC}   $passed"
echo -e "${YELLOW}Warnings:${NC} $warnings"
echo -e "${RED}Errors:${NC}   $errors"

[[ $errors -eq 0 ]] || exit 1
