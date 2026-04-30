#!/usr/bin/env bash
# 06: Write to a new agents/<x>.md inside batuta plugin without marker → BLOCK.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
target="$PLUGIN_ROOT/agents/new-agent.md"
out=$(run_hook "pre-write-agent-gate.sh" "$target") || true
echo "06-agent-no-marker-blocks: $out"
if echo "$out" | grep -q 'EXIT=1' && echo "$out" | grep -q 'RULE violated'; then
  echo "PASS: 06-agent-no-marker-blocks"
  exit 0
fi
echo "FAIL: 06-agent-no-marker-blocks"
exit 1
