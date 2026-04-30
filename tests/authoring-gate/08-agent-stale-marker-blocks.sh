#!/usr/bin/env bash
# 08: Write to a new agents/<x>.md with only a stale agent marker → BLOCK.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
write_stale_marker "agent"
target="$PLUGIN_ROOT/agents/new-agent.md"
out=$(run_hook "pre-write-agent-gate.sh" "$target") || true
echo "08-agent-stale-marker-blocks: $out"
if echo "$out" | grep -q 'EXIT=1' && echo "$out" | grep -q 'RULE violated'; then
  echo "PASS: 08-agent-stale-marker-blocks"
  exit 0
fi
echo "FAIL: 08-agent-stale-marker-blocks"
exit 1
