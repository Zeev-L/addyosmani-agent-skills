#!/bin/bash
# validate-skills.sh — Check project conventions not covered by `claude plugin validate`
#
# `claude plugin validate .` (CI) handles: frontmatter, name format, description length.
# This script checks only what it doesn't: required sections per docs/skill-anatomy.md.
#
# Usage: bash test/validate-skills.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
PASS=0 FAIL=0 WARN=0

pass() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1" >&2; }
warn() { WARN=$((WARN + 1)); printf '  WARN: %s\n' "$1" >&2; }

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  skill=$(basename "$dir")
  file="$dir/SKILL.md"
  printf '\n%s\n' "$skill"

  [ ! -f "$file" ] && { fail "SKILL.md missing"; continue; }

  # Line count (Anthropic recommends <500)
  lines=$(wc -l < "$file" | tr -d ' ')
  [ "$lines" -gt 500 ] && fail "SKILL.md is $lines lines (>500)" || pass "line count OK ($lines)"

  # Meta-skill — no workflow sections expected
  [ "$skill" = "using-agent-skills" ] && { pass "meta-skill — section checks skipped"; continue; }

  # Required sections (docs/skill-anatomy.md)
  for section in "When to Use" "Red Flags" "Verification"; do
    grep -q "^## .*${section}" "$file" 2>/dev/null && pass "section: $section" || warn "section missing: $section"
  done

  # Common Rationalizations (idea-refine uses Anti-patterns format by owner choice)
  if [ "$skill" = "idea-refine" ]; then
    pass "Common Rationalizations — skipped (uses Anti-patterns format)"
  elif grep -q '^## Common Rationalizations' "$file" 2>/dev/null; then
    grep -q '| Rationalization | Reality |' "$file" 2>/dev/null \
      && pass "section: Common Rationalizations (table format)" \
      || warn "Common Rationalizations not in table format"
  else
    warn "section missing: Common Rationalizations"
  fi
done

printf '\n══════════════════════════════════════════\n'
printf 'Results: %d passed, %d failed, %d warnings\n' "$PASS" "$FAIL" "$WARN"
printf '══════════════════════════════════════════\n'
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
