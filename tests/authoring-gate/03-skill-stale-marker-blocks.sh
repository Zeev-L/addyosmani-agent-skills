#!/usr/bin/env bash
# 03: Write to a new SKILL.md with only a stale marker (>60min) should BLOCK (exit 1).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
write_stale_marker "skill"
target="$PLUGIN_ROOT/skills/new-skill/SKILL.md"
out=$(run_hook "pre-write-skill-gate.sh" "$target") || true
echo "03-skill-stale-marker-blocks: $out"
if echo "$out" | grep -q 'EXIT=1' && echo "$out" | grep -q 'RULE violated'; then
  echo "PASS: 03-skill-stale-marker-blocks"
  exit 0
fi
echo "FAIL: 03-skill-stale-marker-blocks"
exit 1
