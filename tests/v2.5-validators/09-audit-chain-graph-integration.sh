#!/usr/bin/env bash
# 09-audit-chain-graph-integration.sh
# Validates the v3.0 audit-chain x code-graph integration:
#   (a) code-reviewer.md and security-auditor.md declare Step 0.5
#       with graceful-degrade clause and engine citation requirement.
#   (b) test-engineer.md does NOT have Step 0.5 (scope guard per ADR-0008).
#   (c) Both Step 0.5 sections explicitly call check-code-graph-engines.sh
#       (so auditors gate on the same shared availability check).
#   (d) Both Step 0.5 sections are non-blocking
#       (no path that returns BLOCKED from Step 0.5 itself).
# Contract introduced in v3.0 (ADR-0008).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="09-audit-chain-graph-integration"
echo "[${case_name}] starting"

CR="${REPO_ROOT}/agents/code-reviewer.md"
SA="${REPO_ROOT}/agents/security-auditor.md"
TE="${REPO_ROOT}/agents/test-engineer.md"

failed=0

ok()    { echo "  OK   $1"; }
miss()  { echo "  MISS $1"; failed=1; }
drift() { echo "  DRIFT $1"; failed=1; }

check_present() {
  local file="$1" pattern="$2" label="$3"
  if grep -qE "$pattern" "$file"; then
    ok "$(basename "$file") — $label"
  else
    miss "$(basename "$file") — $label"
  fi
}

check_absent() {
  local file="$1" pattern="$2" label="$3"
  if grep -qE "$pattern" "$file"; then
    drift "$(basename "$file") — $label (should NOT be present)"
  else
    ok "$(basename "$file") — $label absent (correct)"
  fi
}

# --- (a) code-reviewer.md must have Step 0.5 ---
if [[ ! -f "$CR" ]]; then
  miss "agents/code-reviewer.md missing"
else
  check_present "$CR" '## Step 0\.5 — Blast-radius enumeration via code-graph' "Step 0.5 heading"
  check_present "$CR" 'non-blocking'                         "Step 0.5 declared non-blocking"
  check_present "$CR" 'check-code-graph-engines\.sh'         "Step 0.5 calls check-code-graph-engines.sh"
  check_present "$CR" 'falling back to diff-only review'     "Step 0.5 graceful-degrade fallback string"
  check_present "$CR" '\[blast radius via'                   "Step 0.5 mandates engine citation"
  # Step 0.5 must come AFTER Step 0 and BEFORE Review Framework
  s0_line=$(grep -nE '^## Step 0 — Pre-flight scope check'           "$CR" | head -n1 | cut -d: -f1)
  s05_line=$(grep -nE '^## Step 0\.5 — Blast-radius enumeration'      "$CR" | head -n1 | cut -d: -f1)
  rf_line=$(grep -nE '^## Review Framework'                           "$CR" | head -n1 | cut -d: -f1)
  if [[ -n "$s0_line" && -n "$s05_line" && -n "$rf_line" \
        && $s0_line -lt $s05_line && $s05_line -lt $rf_line ]]; then
    ok "code-reviewer.md — Step 0.5 ordered between Step 0 and Review Framework"
  else
    miss "code-reviewer.md — Step 0.5 must sit between Step 0 and Review Framework (got s0=$s0_line s0.5=$s05_line rf=$rf_line)"
  fi
fi

# --- (a') security-auditor.md must have Step 0.5 ---
if [[ ! -f "$SA" ]]; then
  miss "agents/security-auditor.md missing"
else
  check_present "$SA" '## Step 0\.5 — Attack-surface enumeration via code-graph' "Step 0.5 heading"
  check_present "$SA" 'non-blocking'                         "Step 0.5 declared non-blocking"
  check_present "$SA" 'check-code-graph-engines\.sh'         "Step 0.5 calls check-code-graph-engines.sh"
  check_present "$SA" 'falling back to diff-only audit'      "Step 0.5 graceful-degrade fallback string"
  check_present "$SA" '\[attack surface via'                 "Step 0.5 mandates engine citation"
  s0_line=$(grep -nE '^## Step 0 — Pre-flight scope check'           "$SA" | head -n1 | cut -d: -f1)
  s05_line=$(grep -nE '^## Step 0\.5 — Attack-surface enumeration'    "$SA" | head -n1 | cut -d: -f1)
  rs_line=$(grep -nE '^## Review Scope'                               "$SA" | head -n1 | cut -d: -f1)
  if [[ -n "$s0_line" && -n "$s05_line" && -n "$rs_line" \
        && $s0_line -lt $s05_line && $s05_line -lt $rs_line ]]; then
    ok "security-auditor.md — Step 0.5 ordered between Step 0 and Review Scope"
  else
    miss "security-auditor.md — Step 0.5 must sit between Step 0 and Review Scope (got s0=$s0_line s0.5=$s05_line rs=$rs_line)"
  fi
fi

# --- (b) test-engineer.md must NOT have Step 0.5 (scope guard per ADR-0008) ---
if [[ ! -f "$TE" ]]; then
  miss "agents/test-engineer.md missing"
else
  check_absent "$TE" '## Step 0\.5'                        "Step 0.5 heading (test-engineer scope guard)"
  check_absent "$TE" 'Blast-radius enumeration'            "blast-radius logic"
  check_absent "$TE" 'Attack-surface enumeration'          "attack-surface logic"
fi

# --- (c) ADR-0008 must exist and be referenced by both Step 0.5 blocks indirectly ---
ADR="${REPO_ROOT}/docs/adr/0008-audit-chain-code-graph-integration.md"
[[ -f "$ADR" ]] && ok "docs/adr/0008-audit-chain-code-graph-integration.md exists" || miss "ADR-0008 missing"

# --- (d) Step 0.5 must NOT contain a path that returns BLOCKED ---
# The verdict line for both auditors is `AUDIT RESULT: APPROVED|BLOCKED|...`.
# Step 0.5 must not produce a BLOCKED verdict on its own.
for f in "$CR" "$SA"; do
  if [[ -f "$f" ]]; then
    s05_block=$(awk '/^## Step 0\.5 /,/^## /' "$f")
    if echo "$s05_block" | grep -qE '^- *`AUDIT RESULT: BLOCKED'; then
      drift "$(basename "$f") — Step 0.5 contains BLOCKED verdict (must be non-blocking)"
    else
      ok "$(basename "$f") — Step 0.5 does not produce BLOCKED verdict directly"
    fi
  fi
done

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
