#!/usr/bin/env bash
# 14-kb-backfill-shape.sh
# Static contract validator for the v3.8 Sprint 2.5 backfill pipeline:
# kb-backfill skill + kb-backfiller agent + slash command.

set -uo pipefail

cd "${REPO_ROOT:-$(pwd)}"

fail=0
pass=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  OK   $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL $desc"
    fail=$((fail + 1))
  fi
}

echo "[14-kb-backfill-shape] starting"

# Skill exists and conforms.
check "skills/kb-backfill/SKILL.md exists" "test -f skills/kb-backfill/SKILL.md"
check "kb-backfill frontmatter has name" "grep -qE '^name: kb-backfill' skills/kb-backfill/SKILL.md"
check "kb-backfill description starts with Use" "grep -qE '^description: Use' skills/kb-backfill/SKILL.md"
check "kb-backfill body ≤ 200 lines" "test \$(wc -l < skills/kb-backfill/SKILL.md) -le 200"
check "kb-backfill documents 4 phases" "grep -cE 'Phase [1-4]' skills/kb-backfill/SKILL.md | awk '\$1 >= 4 {exit 0} {exit 1}'"
check "kb-backfill documents Haiku/Sonnet heuristic" "grep -qE 'Haiku|Sonnet' skills/kb-backfill/SKILL.md"
check "kb-backfill documents idempotency via manifest" "grep -qE 'manifest\\.yaml' skills/kb-backfill/SKILL.md"
check "kb-backfill writes to _inbox/backfill-" "grep -qE '_inbox/backfill-' skills/kb-backfill/SKILL.md"
check "kb-backfill phase 4 is opt-in only" "grep -qE 'Phase 4.*opt-in|opt-in.*Phase 4|--scope.*code' skills/kb-backfill/SKILL.md"
check "kb-backfill mentions /kb-curate as next step" "grep -qE '/kb-curate' skills/kb-backfill/SKILL.md"

# Agent exists and conforms.
check "agents/kb-backfiller.md exists" "test -f agents/kb-backfiller.md"
check "kb-backfiller frontmatter name" "grep -qE '^name: kb-backfiller' agents/kb-backfiller.md"
check "kb-backfiller frontmatter model: sonnet" "grep -qE '^model: sonnet' agents/kb-backfiller.md"
check "kb-backfiller description ≤ 150 chars" "head -4 agents/kb-backfiller.md | grep description | awk -F': ' '{print length(\$2)}' | awk '\$1 <= 150 {exit 0} {exit 1}'"
check "kb-backfiller body ≤ 150 lines" "test \$(wc -l < agents/kb-backfiller.md) -le 150"
check "kb-backfiller has Step 0 NOT-APPLICABLE" "grep -qE 'NOT-APPLICABLE|Pre-flight' agents/kb-backfiller.md"
check "kb-backfiller emits BACKFILL_PHASE_COMPLETE literal" "grep -qE 'BACKFILL_PHASE_COMPLETE' agents/kb-backfiller.md"
check "kb-backfiller has When NOT to invoke" "grep -qE '^## When NOT to invoke' agents/kb-backfiller.md"
check "kb-backfiller declares minimal tools" "grep -qE '^tools:' agents/kb-backfiller.md"
check "kb-backfiller writes only to vault inbox + sessions" "grep -qE 'NEVER write outside.*_inbox|never modify' agents/kb-backfiller.md || grep -qE 'NEVER modify.*source' agents/kb-backfiller.md"

# Slash command.
check ".claude/commands/kb-backfill.md exists" "test -f .claude/commands/kb-backfill.md"
check "kb-backfill.md references the skill" "grep -q 'skills/kb-backfill' .claude/commands/kb-backfill.md"
check "kb-backfill.md documents --force flag" "grep -qE -- '--force' .claude/commands/kb-backfill.md"
check "kb-backfill.md documents --scope flag" "grep -qE -- '--scope' .claude/commands/kb-backfill.md"
check "kb-backfill.md mentions Sprint 3 retrofit ordering" "grep -qE 'bato-cajas|Sprint 3' .claude/commands/kb-backfill.md"

# Cross-references.
check "kb-backfill skill references kb-backfiller agent" "grep -q 'kb-backfiller' skills/kb-backfill/SKILL.md"
check "kb-backfiller agent references kb-backfill skill" "grep -q 'kb-backfill' agents/kb-backfiller.md"

# Distinctness vs kb-curator (must be orthogonal).
check "kb-backfiller distinct from kb-curator (read-only on source repo)" "grep -qE 'read-only|distinct from kb-curator' agents/kb-backfiller.md"

if [[ $fail -gt 0 ]]; then
  echo "[14-kb-backfill-shape] FAIL — $fail check(s) failed, $pass passed"
  exit 1
fi

echo "[14-kb-backfill-shape] PASS — $pass checks"
exit 0
