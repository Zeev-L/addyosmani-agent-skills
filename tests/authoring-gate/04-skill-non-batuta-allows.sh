#!/usr/bin/env bash
# 04: Write to a SKILL.md inside a non-batuta plugin (origin does not match)
#     should ALLOW unconditionally — gate is repo-scoped.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_non_batuta_plugin_root
target="$PLUGIN_ROOT/skills/new-skill/SKILL.md"
out=$(run_hook "pre-write-skill-gate.sh" "$target")
echo "04-skill-non-batuta-allows: $out"
if echo "$out" | grep -q 'EXIT=0'; then
  echo "PASS: 04-skill-non-batuta-allows"
  exit 0
fi
echo "FAIL: 04-skill-non-batuta-allows"
exit 1
