#!/bin/bash
# check-consistency.sh — Validates that the repo's documentation stays consistent
# with the actual skill directories and cross-file references.
#
# Checks:
#   1. Skill count in README matches actual skills/ directories
#   2. Every agent-skills:<name> reference resolves to a real skill
#   3. Both /ship command entrypoints have matching Phase B step counts
#   4. No lifecycle doc maps SHIP to shipping-and-launch alone (skipping observability)
#
# Exit codes: 0 = all checks pass, 1 = one or more checks failed
#
# Usage:
#   bash scripts/check-consistency.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

status=0

# ── helpers ──────────────────────────────────────────────────────────────────

pass() { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s\n' "$1" >&2; status=1; }
section() { printf '\n%s\n' "── $1 ──────────────────────────────────────────"; }

# Portable grep -o equivalent for ERE patterns (works on macOS and Linux)
grep_o() { grep -oE "$@"; }

# Extract lines between two section headers (inclusive of start, exclusive of end)
extract_section() {
  local file="$1" start_pat="$2" end_pat="$3"
  awk "/^$start_pat/{found=1} found; /^$end_pat/ && !first{first=1; next} /^$end_pat/{found=0}" \
    "$file" 2>/dev/null || true
}

# ── 1. Skill count consistency ────────────────────────────────────────────────

section "Skill count"

actual_count=$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')

# Only validate total-count claims, not sub-counts like "20 core lifecycle skills".
# Total counts appear in two specific places:
#   "## All N Skills"   (section heading)
#   "# N skills ("      (directory tree comment)
total_counts=$(grep -oE '## All [0-9]+ [Ss]kills?|# [0-9]+ skills \(' README.md \
  | grep_o '[0-9]+' | sort -u)

mismatch=0
while IFS= read -r n; do
  [ -z "$n" ] && continue
  if [ "$n" != "$actual_count" ]; then
    fail "README total skill count says '$n' but found $actual_count skill directories"
    mismatch=1
  fi
done <<< "$total_counts"

[ "$mismatch" -eq 0 ] && pass "README skill count matches directories ($actual_count)"

# ── 2. agent-skills:<name> references resolve ─────────────────────────────────

section "agent-skills: reference resolution"

# Collect all agent-skills:<name> references across docs and skill files.
# Uses ERE (-E) which is portable across macOS/BSD and GNU grep.
# The || true guards prevent set -e from aborting when grep finds no matches.
refs=$(
  find .claude/commands .gemini/commands skills docs references \
       -name "*.md" -o -name "*.toml" 2>/dev/null \
  | xargs grep -hoE 'agent-skills:[a-z-]+' 2>/dev/null \
  | sort -u || true
)

# Also check top-level markdown files
top_refs=$(grep -hoE 'agent-skills:[a-z-]+' AGENTS.md CLAUDE.md README.md 2>/dev/null | sort -u || true)

all_refs=$(printf '%s\n%s\n' "$refs" "$top_refs" | sort -u | grep -v '^$' || true)

unresolved=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  skill_name="${ref#agent-skills:}"
  if [ ! -f "skills/$skill_name/SKILL.md" ]; then
    fail "agent-skills:$skill_name → skills/$skill_name/SKILL.md not found"
    unresolved=1
  fi
done <<< "$all_refs"

[ "$unresolved" -eq 0 ] && pass "All agent-skills: references resolve"

# ── 3. /ship Phase B step count parity ───────────────────────────────────────

section "/ship Phase B parity"

# Count numbered bold steps inside the ## Phase B section only.
# Uses awk end-to-end so the pipeline always exits 0 and prints exactly
# one integer, even when Phase B is empty or the file doesn't exist.
phase_b_steps() {
  local file="$1"
  awk '/^## Phase B/{in_b=1} /^## Phase C/{in_b=0} in_b && /^[0-9]+\. \*\*/{c++} END{print c+0}' \
    "$file" 2>/dev/null || echo 0
}

claude_steps=$(phase_b_steps .claude/commands/ship.md)
gemini_steps=$(phase_b_steps .gemini/commands/ship.toml)

if [ "$claude_steps" -ne "$gemini_steps" ]; then
  fail "/ship Phase B: .claude has $claude_steps steps, .gemini has $gemini_steps steps"
else
  pass "/ship Phase B step count matches across harnesses ($claude_steps steps)"
fi

# ── 4. No bare shipping-and-launch in lifecycle docs ─────────────────────────
# Only runs when observability-and-monitoring skill exists in the repo —
# this check guards against regressions after the skill is merged.

section "SHIP lifecycle completeness"

if [ ! -f "skills/observability-and-monitoring/SKILL.md" ]; then
  pass "Skipped (observability-and-monitoring skill not yet present)"
else
  # Canonical lifecycle mapping patterns to check across all harness docs:
  #
  #   - SHIP → ...                    (AGENTS.md, opencode-setup.md)
  #   **Ship:** ...shipping-and-launch (CLAUDE.md)
  #   Before deploy: ...              (getting-started.md)
  #   | `/ship` | ...                 (getting-started.md command table)
  #   └── Deploying/launching? ...    (using-agent-skills routing tree)
  #
  # Does NOT flag mid-sequence numbered entries like "12. shipping-and-launch"
  # because those appear alongside observability on the preceding line.

  lifecycle_files=(
    AGENTS.md
    CLAUDE.md
    docs/getting-started.md
    docs/opencode-setup.md
    "skills/using-agent-skills/SKILL.md"
  )

  bare=0
  for f in "${lifecycle_files[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      # Match any line containing shipping-and-launch in a lifecycle-mapping context:
      #   - SHIP → ...                  (AGENTS.md, opencode-setup.md)
      #   **Ship:** ...                 (CLAUDE.md)
      #   Before deploy: ...            (getting-started.md)
      #   | `/ship` | ...               (getting-started.md command table)
      #   | Ship | shipping-and-launch  (using-agent-skills Quick Reference)
      #   Deploying/launching? ...      (using-agent-skills routing tree)
      if echo "$line" | grep -qE \
           '[-*] SHIP[[:space:]]+→|\*\*Ship:\*\*|Before deploy:|^\|[[:space:]]+`/ship`|\| Ship \|[[:space:]]+shipping-and-launch|Deploying/launching'; then
        if echo "$line" | grep -q "shipping-and-launch" && \
           ! echo "$line" | grep -q "observability-and-monitoring"; then
          fail "$f: lifecycle mapping omits observability-and-monitoring: $line"
          bare=1
        fi
      fi
    done < "$f"
  done

  [ "$bare" -eq 0 ] && pass "All lifecycle mappings include observability-and-monitoring"
fi

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n'
if [ "$status" -eq 0 ]; then
  printf '✓ All consistency checks passed.\n'
else
  printf '✗ One or more consistency checks failed.\n' >&2
fi

exit "$status"
