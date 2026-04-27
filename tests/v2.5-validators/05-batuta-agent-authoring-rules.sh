#!/usr/bin/env bash
# 05-batuta-agent-authoring-rules.sh
# Validates that skills/batuta-agent-authoring/SKILL.md has Verification rules 5 and 6
# (research-first wiring + audit-scope wiring) plus matching Red Flags entries.
# Contract introduced in v2.5 (PR #9).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="05-batuta-agent-authoring-rules"
echo "[${case_name}] starting"

failed=0
file="skills/batuta-agent-authoring/SKILL.md"

check() {
  local pattern="$1"
  local label="$2"
  if grep -qE "${pattern}" "${REPO_ROOT}/${file}"; then
    echo "  OK   ${file} — ${label}"
  else
    echo "  MISS ${file} — ${label}"
    failed=1
  fi
}

# Verification rule 5 — research-first wiring
check "5\. \*\*Research-first wiring \(mandatory for code-writing agents\)\*\*" "Verification rule 5 heading"
check "Edit.*Write.*MultiEdit.*NotebookEdit" "rule 5 names the trigger tools"
check "Mirror the wording used in .agents/implementer\.md. Step 2" "rule 5 references implementer.md Step 2 as canonical"

# Verification rule 6 — audit-scope wiring
check "6\. \*\*Audit chain scope wiring \(mandatory for audit-gate agents\)\*\*" "Verification rule 6 heading"
check "AUDIT RESULT:.*literal" "rule 6 trigger: agent closes with AUDIT RESULT:"
check "Step 0 pre-flight that checks .git diff --staged --stat" "rule 6 specifies the pre-flight check"
check "Mirror the wording used in .agents/code-reviewer\.md. Step 0" "rule 6 references code-reviewer.md Step 0 as canonical"

# Red Flags additions
check "Code-writing agent .* without an explicit research-first step" "Red Flag for missing research-first"
check "Audit-gate agent .* without a Step 0 NOT-APPLICABLE pre-flight" "Red Flag for missing Step 0"

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
