#!/usr/bin/env bash
# 02: Write to a new SKILL.md with a fresh skill marker (<60min) should ALLOW (exit 0).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
write_fresh_marker "skill"
target="$PLUGIN_ROOT/skills/new-skill/SKILL.md"
out=$(run_hook "pre-write-skill-gate.sh" "$target")
echo "02-skill-fresh-marker-allows: $out"
if echo "$out" | grep -q 'EXIT=0'; then
  echo "PASS: 02-skill-fresh-marker-allows"
  exit 0
fi
echo "FAIL: 02-skill-fresh-marker-allows"
exit 1
