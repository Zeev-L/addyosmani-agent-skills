#!/usr/bin/env bash
# 07: Write to a new agents/<x>.md with a fresh agent marker → ALLOW.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
write_fresh_marker "agent"
target="$PLUGIN_ROOT/agents/new-agent.md"
out=$(run_hook "pre-write-agent-gate.sh" "$target")
echo "07-agent-fresh-marker-allows: $out"
if echo "$out" | grep -q 'EXIT=0'; then
  echo "PASS: 07-agent-fresh-marker-allows"
  exit 0
fi
echo "FAIL: 07-agent-fresh-marker-allows"
exit 1
