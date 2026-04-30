#!/usr/bin/env bash
# 11: Write to an existing SKILL.md (file already on disk) → ALLOW even without
#     marker. Edits are not gated; only creation of new SKILL.md is.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

setup_batuta_plugin_root
mkdir -p "$PLUGIN_ROOT/skills/existing"
echo "# already exists" > "$PLUGIN_ROOT/skills/existing/SKILL.md"
target="$PLUGIN_ROOT/skills/existing/SKILL.md"
out=$(run_hook "pre-write-skill-gate.sh" "$target")
echo "11-skill-edit-existing-allows: $out"
if echo "$out" | grep -q 'EXIT=0'; then
  echo "PASS: 11-skill-edit-existing-allows"
  exit 0
fi
echo "FAIL: 11-skill-edit-existing-allows"
exit 1
