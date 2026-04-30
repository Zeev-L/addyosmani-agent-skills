#!/usr/bin/env bash
# 01: Write to a new SKILL.md inside batuta-agent-skills repo without any marker
#     should be BLOCKED (exit 1 with "RULE violated").
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
target="$PLUGIN_ROOT/skills/new-skill/SKILL.md"
out=$(run_hook "pre-write-skill-gate.sh" "$target") || rc=$? && rc=${rc:-0}
echo "01-skill-no-marker-blocks: $out"
if echo "$out" | grep -q 'EXIT=1' && echo "$out" | grep -q 'RULE violated'; then
  echo "PASS: 01-skill-no-marker-blocks"
  exit 0
fi
echo "FAIL: 01-skill-no-marker-blocks"
exit 1
