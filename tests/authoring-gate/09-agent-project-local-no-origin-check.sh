#!/usr/bin/env bash
# 09: Write to a new <project>/.claude/agents/<x>.md (project-local) without marker →
#     should still BLOCK (no origin-check bypass). The path skips origin check but
#     still requires a marker.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

# Set up a non-batuta repo (a downstream project that imported the rule).
PLUGIN_ROOT="$(mktemp -d)"
mkdir -p "$PLUGIN_ROOT/.claude-plugin" "$PLUGIN_ROOT/.claude/agents"
echo '{}' > "$PLUGIN_ROOT/.claude-plugin/plugin.json"
( cd "$PLUGIN_ROOT" && git init -q && git remote add origin "https://github.com/jota-batuta/some-other-project.git" )
trap 'rm -rf "$PLUGIN_ROOT"' EXIT

target="$PLUGIN_ROOT/.claude/agents/new-specialist.md"
out=$(run_hook "pre-write-agent-gate.sh" "$target") || true
echo "09-agent-project-local-no-origin-check: $out"
if echo "$out" | grep -q 'EXIT=1' && echo "$out" | grep -q 'RULE violated'; then
  echo "PASS: 09-agent-project-local-no-origin-check"
  exit 0
fi
echo "FAIL: 09-agent-project-local-no-origin-check"
exit 1
