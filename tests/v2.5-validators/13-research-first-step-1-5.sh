#!/usr/bin/env bash
# 13-research-first-step-1-5.sh
# Validates the v3.8 Sprint 2 addition of Step 1.5 (Local KB lookup) to
# research-first-dev SKILL.md, ensuring the staleness policy is encoded and
# the lookup ordering (L2 > L3 > L1) is documented.

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

skill="skills/research-first-dev/SKILL.md"

echo "[13-research-first-step-1-5] starting"

check "research-first-dev/SKILL.md exists" "test -f $skill"
check "Step 1.5 heading exists" "grep -qE '^### Step 1\\.5' $skill"
check "Step 1.5 documents L2 > L3 > L1 priority" "grep -qE 'L2.*>.*L3.*>.*L1|priority L2' $skill"
check "Step 1.5 references vault_root" "grep -qE 'vault_root|VAULT_ROOT' $skill"
check "Step 1.5 references kb-config.json" "grep -qE 'kb-config\\.json' $skill"
check "Step 1.5 documents staleness policy" "grep -qE 'last_verified.*4 mes|< 4 meses|4–12 meses|> 12 meses' $skill"
check "Step 1.5 mentions structural decisions always need Step 2" "grep -qE 'always run Step 2|Always run Step 2|cannot substitute' $skill"
check "Step 1.5 documents fallback when vault unreachable" "grep -qE 'unreachable|Drive offline|skip Step 1\\.5' $skill"
check "Step 1.5 has L1 disclaimer 'no curado'" "grep -qE 'no curado|verificá' $skill"
check "Step 1.5 documents dual-cite format" "grep -qE 'Cross-checked' $skill"
check "Step 1.5 documents local-only cite format" "grep -qE 'Source: ~/batuta-kb|Source: \\\$VAULT_ROOT|Source: <vault_root>' $skill"
check "Step 1.5 ordered between Step 1 and Step 2" "awk '/^### Step 1:/,/^### Step 2/' $skill | grep -qE '^### Step 1\\.5'"
check "Step 2 still present after Step 1.5" "grep -qE '^### Step 2' $skill"
check "Step 4 (citation) still present" "grep -qE '^### Step 4' $skill"

# Companion sanity: Anti-Rationalizations and Red Flags untouched in shape.
check "Anti-Rationalizations section intact" "grep -qE '^## Anti-Rationalizations' $skill"
check "Red Flags section intact" "grep -qE '^## Red Flags' $skill"
check "Verification section intact" "grep -qE '^## Verification' $skill"

if [[ $fail -gt 0 ]]; then
  echo "[13-research-first-step-1-5] FAIL — $fail check(s) failed, $pass passed"
  exit 1
fi

echo "[13-research-first-step-1-5] PASS — $pass checks"
exit 0
