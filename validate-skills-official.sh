#!/usr/bin/env bash
#
# Validate every skill using the canonical `skills-ref` Python library
# from https://github.com/agentskills/agentskills.
#
# Installs skills-ref into /tmp/agentskills on first run.
# Use validate-skills.sh for a zero-dependency fallback.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
REF_DIR="/tmp/agentskills"
REF_LIB="$REF_DIR/skills-ref"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}Validating with agentskills/skills-ref${NC}"

# Bootstrap skills-ref if missing
if [[ ! -d "$REF_LIB/.venv" ]]; then
  echo "Installing skills-ref..."
  if [[ ! -d "$REF_DIR" ]]; then
    git clone --depth=1 https://github.com/agentskills/agentskills.git "$REF_DIR"
  fi
  cd "$REF_LIB"
  if command -v uv >/dev/null 2>&1; then
    uv sync >/dev/null
  else
    python3 -m venv .venv
    # shellcheck disable=SC1091
    source .venv/bin/activate
    pip install --quiet -e .
    deactivate
  fi
  cd "$REPO_ROOT"
fi

# shellcheck disable=SC1091
source "$REF_LIB/.venv/bin/activate"

errors=0
for dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$dir")"
  echo -e "${BLUE}→${NC} $skill_name"
  if skills-ref validate "$dir" 2>&1 | sed 's/^/  /'; then
    echo -e "  ${GREEN}✓${NC} valid"
  else
    errors=$((errors + 1))
  fi
  echo
done

deactivate

if [[ $errors -gt 0 ]]; then
  echo -e "${RED}FAIL:${NC} $errors skill(s) failed"
  exit 1
fi
echo -e "${GREEN}All skills pass.${NC}"
