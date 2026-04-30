#!/usr/bin/env bash
# 06-delegation-guard-killswitch.sh
# Validates that hooks/delegation-guard.sh:
#   (a) references each kill-switch pattern (kill-switch-only model, v2.7+)
#   (b) does NOT contain a path-whitelist block referencing project source paths like
#       'pipeline.py' or the old whitelist case patterns — those would be drift back to
#       the pre-v2.7 workflow-enforcement model.
#   (c) preserves the fail-open (exit 0) branch on empty/unparseable path (v2.7 failure-mode flip)
#   (d) preserves the subagent bypass via agent_id with an actual conditional exit 0 branch
# Contract introduced in v2.7 (PR #12).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="06-delegation-guard-killswitch"
echo "[${case_name}] starting"

HOOK="${REPO_ROOT}/hooks/delegation-guard.sh"
failed=0

check_present() {
  local pattern="$1"
  local label="$2"
  if grep -qE "${pattern}" "${HOOK}"; then
    echo "  OK   hooks/delegation-guard.sh — ${label}"
  else
    echo "  MISS hooks/delegation-guard.sh — ${label}"
    failed=1
  fi
}

check_absent() {
  local pattern="$1"
  local label="$2"
  if grep -qE "${pattern}" "${HOOK}"; then
    echo "  DRIFT hooks/delegation-guard.sh — ${label} (should NOT be present)"
    failed=1
  else
    echo "  OK   hooks/delegation-guard.sh — ${label} absent (correct)"
  fi
}

# --- Kill-switch patterns must be present ---
check_present '\.claude/settings\*\.json|settings\*\.json' "kill-switch: .claude/settings*.json"
check_present '\.claude/hooks/\*|\.claude/hooks/' "kill-switch: .claude/hooks/*"
check_present 'hooks/\*\.json' "kill-switch: hooks/*.json (plugin hook manifest)"
# v3.7+: broadened from /hooks/delegation-guard.sh specifically to /hooks/*.sh
# so any hook script (current pr-merge-guard.sh + future hooks) is kill-switched.
# The narrow form was a v3.6 GATE 3 HIGH finding — pr-merge-guard.sh was added
# without extending the kill-switch, leaving a self-disable surface.
check_present 'hooks/\*\.sh' "kill-switch: hooks/*.sh (any hook script, broadened in v3.7)"
check_present '\.claude/agents/\*|\.claude/agents/' "kill-switch: .claude/agents/*"
check_present '\.env\b|/\.env\b' "kill-switch: .env"
check_present '\.envrc|\.envrc' "kill-switch: .envrc"
check_present 'secrets/' "kill-switch: secrets/*"

# --- Failure-mode: fail-open (exit 0) on empty/unparseable path (v2.7 flip) ---
# The v2.7 hook must exit 0 (allow) when file_path is empty — which covers the case
# where jq could not parse stdin (jq returns "" on error with the // "" fallback).
# Checking for the guard condition ensures a regression to fail-closed (exit 1) is caught.
check_present '\[\[ -z.*file_path' "fail-open: conditional guard on empty file_path present"
# Regression check: the empty-path branch must not exit 1 (would lock the session on parse errors)
check_absent '\[\[ -z.*file_path[^#]*exit 1' "fail-open: empty-path branch must not exit 1 (fail-closed regression)"

# --- Subagent bypass: must be a conditional that uses both event_name and agent_id ---
# A regression could leave the agent_id string in a comment but remove the actual bypass logic.
# Checking for the dual-guard pattern ensures the conditional itself is present.
check_present '\-n.*agent_id' "subagent bypass: -n agent_id conditional present"
check_present 'event_name.*PreToolUse.*-n.*agent_id|-n.*agent_id.*event_name.*PreToolUse' "subagent bypass: dual guard (event_name + agent_id) present"

# --- Path-whitelist patterns must NOT be present (drift detection) ---
# The old model had a case block listing allowed paths; if those return, the hook
# has regressed to workflow enforcement instead of kill-switch only.
check_absent 'specs/\*\|specs/' "old path-whitelist: specs/"
check_absent 'docs/\*\|docs/' "old path-whitelist: docs/"
check_absent 'pipeline\.py' "old path-whitelist example: pipeline.py"
check_absent 'RULE #0 violated: the main agent does not edit' "old workflow-block stderr message"

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
