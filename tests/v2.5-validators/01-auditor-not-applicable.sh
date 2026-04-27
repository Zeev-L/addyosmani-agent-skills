#!/usr/bin/env bash
# 01-auditor-not-applicable.sh
# Validates that all three audit-gate agents (code-reviewer, test-engineer, security-auditor)
# have a Step 0 pre-flight scope check that returns AUDIT RESULT: NOT APPLICABLE on a clean
# working tree. Contract introduced in v2.5 (PR #9).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="01-auditor-not-applicable"
echo "[${case_name}] starting"

failed=0

check() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "${pattern}" "${REPO_ROOT}/${file}"; then
    echo "  OK   ${file} — ${label}"
  else
    echo "  MISS ${file} — ${label}"
    failed=1
  fi
}

for auditor in "agents/code-reviewer.md" "agents/test-engineer.md" "agents/security-auditor.md"; do
  check "${auditor}" "Step 0.*Pre-flight scope check" "has Step 0 pre-flight section"
  check "${auditor}" "git diff --staged --stat" "checks git diff --staged"
  check "${auditor}" "git diff HEAD --stat" "checks git diff HEAD"
  check "${auditor}" "AUDIT RESULT: NOT APPLICABLE" "returns NOT APPLICABLE on clean tree"
  check "${auditor}" "audit chain runs only after an implementation slice" "explains scope rationale"
done

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
