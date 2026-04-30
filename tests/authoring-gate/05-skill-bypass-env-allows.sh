#!/usr/bin/env bash
# 05: Write to a new SKILL.md with BATUTA_SKILL_AUTHORING_BYPASS=1 set should ALLOW
#     even without a marker. A debug log entry should be written.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
target="$PLUGIN_ROOT/skills/new-skill/SKILL.md"
input=$(printf '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"%s"}}' "$target")
stderr_capture=$(mktemp)
BATUTA_SKILL_AUTHORING_BYPASS=1 echo "$input" | BATUTA_SKILL_AUTHORING_BYPASS=1 bash "$REPO_ROOT/hooks/pre-write-skill-gate.sh" 2>"$stderr_capture"
rc=$?
err=$(cat "$stderr_capture")
rm -f "$stderr_capture"

echo "05-skill-bypass-env-allows: EXIT=$rc STDERR=$err"
if [[ $rc -eq 0 ]] && echo "$err" | grep -q 'BATUTA_SKILL_AUTHORING_BYPASS=1'; then
  echo "PASS: 05-skill-bypass-env-allows"
  exit 0
fi
echo "FAIL: 05-skill-bypass-env-allows"
exit 1
