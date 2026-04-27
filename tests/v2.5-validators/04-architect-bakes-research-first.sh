#!/usr/bin/env bash
# 04-architect-bakes-research-first.sh
# Validates that agents/agent-architect.md Phase 5 instructs the meta-agent to bake
# v2.5+ enforcement patterns (research-first Step 2, dual-path build-log, conditional
# Step 0, batuta-agent-authoring rules 5-6 check) into specialists it generates at
# runtime. Contract introduced in v2.6 (PR #10).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="04-architect-bakes-research-first"
echo "[${case_name}] starting"

failed=0
file="agents/agent-architect.md"

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

# Phase 5 must instruct the meta-agent to bake research-first into code-writing specialists
check "Research-first Step 2 \(conditional, mandatory for code-writing specialists\)" "Phase 5: research-first MUST-include bullet"
check "implementer\.md.*Step 2.*post-v2\.5" "references implementer.md Step 2 as canonical source"
check "Context7 lookup" "names Context7 in the bake instruction"

# Phase 5 must instruct the meta-agent to bake conditional Step 0 into audit-gate specialists
check "Audit-scope Step 0 \(conditional, mandatory for audit-gate specialists\)" "Phase 5: audit-scope Step 0 MUST-include bullet"
check "code-reviewer\.md.*Step 0.*post-v2\.5" "references code-reviewer.md Step 0 as canonical source"
check "AUDIT RESULT: NOT APPLICABLE" "names the NOT APPLICABLE return string"

# Phase 5 must use dual-path for build-log
check "docs/plans/active/<slice-id>/build-log\.md.*preferred" "Phase 5: dual-path build-log (preferred)"
check "specs/current/<slice-id>/build-log\.md.*legacy" "Phase 5: dual-path build-log (legacy fallback)"
check "NEVER write .build-log\.md. to project root" "Phase 5: forbids project-root build-log"

# Phase 5 programmatic checks must include batuta-agent-authoring rules 5-6
check "batuta-agent-authoring. verification rules 5 and 6" "Programmatic checks: invoke batuta-agent-authoring rules 5-6"
check "Reject if the body hardcodes .specs/current/. as the only option" "Programmatic check rejects specs/current hardcode"

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
