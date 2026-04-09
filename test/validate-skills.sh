#!/bin/bash
# validate-skills.sh — Structural validator for SKILL.md files
#
# Checks all skills against the canonical format defined in docs/skill-anatomy.md
# and the agentskills.io specification. Run on every PR to catch format regressions.
#
# Usage: bash test/validate-skills.sh [--strict]
#   --strict: treat warnings as failures (for CI)
#
# Exit: 0 if all checks pass, 1 if any fail

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

PASS=0 FAIL=0 WARN=0

# ── Helpers ──────────────────────────────────────────────────────────────────

pass() {
  PASS=$((PASS + 1))
  printf '  PASS: %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  FAIL: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2
}

warn() {
  WARN=$((WARN + 1))
  printf '  WARN: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2
  [ "$STRICT" -eq 1 ] && FAIL=$((FAIL + 1))
}

# Extract YAML frontmatter value (simple single-line fields only)
frontmatter() {
  local file="$1" key="$2"
  # Read between first and second --- lines, find the key
  awk -v k="$key" '
    /^---$/ { fm++; next }
    fm == 1 && $0 ~ "^"k": " { sub("^"k": *", ""); print; exit }
  ' "$file"
}

# ── Per-Skill Checks ────────────────────────────────────────────────────────

check_skill() {
  local dir="$1"
  local skill_name
  skill_name=$(basename "$dir")
  local skill_file="$dir/SKILL.md"

  printf '\n%s\n' "$skill_name"

  # 1. SKILL.md exists
  if [ ! -f "$skill_file" ]; then
    fail "SKILL.md missing"
    return
  fi
  pass "SKILL.md exists"

  # 2. Frontmatter: name field present and matches directory
  local name
  name=$(frontmatter "$skill_file" "name")
  if [ -z "$name" ]; then
    fail "frontmatter: name field missing"
  elif [ "$name" != "$skill_name" ]; then
    fail "frontmatter: name '$name' does not match directory '$skill_name'"
  else
    pass "frontmatter: name matches directory"
  fi

  # 3. Name format: agentskills.io spec (lowercase, hyphens, max 64, no consecutive --)
  if [ -n "$name" ]; then
    if [ ${#name} -gt 64 ]; then
      fail "name exceeds 64 characters (${#name})"
    elif echo "$name" | grep -qE '[^a-z0-9-]'; then
      fail "name contains invalid characters (must be lowercase alphanumeric + hyphens)"
    elif echo "$name" | grep -q '^-\|^.*-$'; then
      fail "name starts or ends with hyphen"
    elif echo "$name" | grep -q '\-\-'; then
      fail "name contains consecutive hyphens"
    else
      pass "name format valid (agentskills.io spec)"
    fi
  fi

  # 4. Frontmatter: description field present
  local desc
  desc=$(frontmatter "$skill_file" "description")
  if [ -z "$desc" ]; then
    fail "frontmatter: description field missing"
    return
  fi
  pass "frontmatter: description present"

  # 5. Description length: Anthropic recommends <250 chars to avoid truncation
  local desc_len=${#desc}
  if [ "$desc_len" -gt 250 ]; then
    warn "description is $desc_len chars (>250, may be truncated in skill listing)" \
      "Source: platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices"
  else
    pass "description length OK ($desc_len chars)"
  fi

  # 6. Description contains trigger conditions ("Use when" or "Use " pattern)
  if echo "$desc" | grep -qi 'Use when\|Use .*to'; then
    pass "description contains trigger conditions"
  else
    warn "description lacks 'Use when' trigger conditions" \
      "Source: agentskills.io spec — description should say what + when"
  fi

  # 7. Line count: Anthropic recommends <500 lines
  local lines
  lines=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$lines" -gt 500 ]; then
    fail "SKILL.md is $lines lines (>500, split into supporting files)"
  else
    pass "line count OK ($lines lines)"
  fi

  # 8. Required sections (skip for meta-skill — not a workflow skill)
  if [ "$skill_name" = "using-agent-skills" ]; then
    pass "meta-skill — section checks skipped"
  else
    local section_checks=0
    for section in "When to Use" "Red Flags" "Verification"; do
      if grep -q "^## .*${section}" "$skill_file" 2>/dev/null; then
        pass "section: $section"
      else
        warn "section missing: $section"
        section_checks=$((section_checks + 1))
      fi
    done

    # 9. Common Rationalizations table (skip for idea-refine — owner uses Anti-patterns format)
    if [ "$skill_name" = "idea-refine" ]; then
      pass "Common Rationalizations — skipped (uses 'Anti-patterns to Avoid' by owner choice)"
    elif grep -q '^## Common Rationalizations' "$skill_file" 2>/dev/null; then
      if grep -q '| Rationalization | Reality |' "$skill_file" 2>/dev/null; then
        pass "section: Common Rationalizations (table format)"
      else
        warn "Common Rationalizations section exists but not in table format" \
          "Expected: | Rationalization | Reality | (per docs/skill-anatomy.md)"
      fi
    else
      warn "section missing: Common Rationalizations" \
        "Source: docs/skill-anatomy.md — 'the most distinctive feature of well-crafted skills'"
    fi
  fi

}

# ── Global Checks ───────────────────────────────────────────────────────────

printf '══════════════════════════════════════════\n'
printf 'Structural Validation: agent-skills\n'
printf '══════════════════════════════════════════\n'

# Check that skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
  printf 'FATAL: skills/ directory not found at %s\n' "$SKILLS_DIR" >&2
  exit 1
fi

# Run checks on each skill
for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  check_skill "$dir"
done

# ── Summary ─────────────────────────────────────────────────────────────────

printf '\n══════════════════════════════════════════\n'
printf 'Results: %d passed, %d failed, %d warnings\n' "$PASS" "$FAIL" "$WARN"
if [ "$STRICT" -eq 1 ]; then
  printf '(strict mode: warnings counted as failures)\n'
fi
printf '══════════════════════════════════════════\n'

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
