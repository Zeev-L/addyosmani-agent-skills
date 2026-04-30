#!/usr/bin/env bash
# 10: Write to a new agents/<x>.md with BATUTA_AGENT_AUTHORING_BYPASS=1 → ALLOW.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
target="$PLUGIN_ROOT/agents/new-agent.md"
input=$(printf '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"%s"}}' "$target")
stderr_capture=$(mktemp)
echo "$input" | BATUTA_AGENT_AUTHORING_BYPASS=1 bash "$REPO_ROOT/hooks/pre-write-agent-gate.sh" 2>"$stderr_capture"
rc=$?
err=$(cat "$stderr_capture")
rm -f "$stderr_capture"

echo "10-agent-bypass-env-allows: EXIT=$rc STDERR=$err"
if [[ $rc -eq 0 ]] && echo "$err" | grep -q 'BATUTA_AGENT_AUTHORING_BYPASS=1'; then
  echo "PASS: 10-agent-bypass-env-allows"
  exit 0
fi
echo "FAIL: 10-agent-bypass-env-allows"
exit 1
