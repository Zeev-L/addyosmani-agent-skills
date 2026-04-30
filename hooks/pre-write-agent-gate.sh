#!/usr/bin/env bash
# pre-write-agent-gate.sh
# PreToolUse hook — enforces rule `rules/authoring/agent-authoring-required.md`.
# Blocks Write/Edit/MultiEdit on **/agents/**.md when the path does not already
# exist (creation, not edit) AND the target sits inside the batuta-agent-skills
# plugin repository AND no fresh authoring marker is found.
#
# Marker contract: `${CLAUDE_PLUGIN_ROOT}/.claude/.authoring-marker-agent-<ISO>`
#   - Written by `skills/batuta-agent-authoring` Step 5 OR by
#     `agents/agent-architect.md` Phase 5.0.
#   - Valid for 60 minutes (mtime-based, not filename-based).
#
# Bypass: BATUTA_AGENT_AUTHORING_BYPASS=1 (operator-side env var).
#
# Output protocol:
#   exit 0 → allow the tool call
#   exit 1 → block the tool call (stderr is shown to the model)
#
# Source: https://code.claude.com/docs/en/hooks (verified 2026-04-29, Claude Code 1.x)

set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "pre-write-agent-gate.sh WARN: jq not installed; gate is permissive." >&2
  exit 0
fi

file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
if [[ -z "$file_path" ]]; then
  exit 0
fi

file_path="${file_path//\\//}"

case "$file_path" in
  ../*|*/..|*/../*|..)
    echo "pre-write-agent-gate.sh: path contains '..' as a segment. Refusing." >&2
    exit 1
    ;;
esac

# Match scope: only **/agents/**.md (plugin agents/ AND project-local
# .claude/agents/). Exclude README and other non-agent .md files.
case "$file_path" in
  */agents/README.md|agents/README.md)
    exit 0  # readme is metadata, not an agent
    ;;
  */agents/*.md|agents/*.md)
    : # in scope
    ;;
  *)
    exit 0  # not an agent file
    ;;
esac

if [[ -e "$file_path" ]]; then
  exit 0  # editing existing agent, no marker required
fi

# Resolve the plugin root via .claude-plugin/ marker walk.
plugin_root=""
search_dir="$(dirname "$file_path")"
for _ in 1 2 3 4 5 6 7 8; do
  if [[ -d "$search_dir/.claude-plugin" ]]; then
    plugin_root="$search_dir"
    break
  fi
  parent="$(dirname "$search_dir")"
  if [[ "$parent" == "$search_dir" ]]; then
    break
  fi
  search_dir="$parent"
done

# For project-local agents at <project>/.claude/agents/<x>.md, the .claude-plugin/
# walk-up will not find a plugin root. Fall back to ${CLAUDE_PLUGIN_ROOT} env so
# the marker location is consistent across plugin-shipped and project-local
# agents — the gate cares about the marker, not which surface the agent lives on.
if [[ -z "$plugin_root" && -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  plugin_root="${CLAUDE_PLUGIN_ROOT//\\//}"
fi

if [[ -z "$plugin_root" ]]; then
  exit 0  # cannot resolve plugin root, out of scope
fi

# Repo-scope guard for plugin-shipped agents (path contains /agents/ at the
# plugin root, not /.claude/agents/). Project-local agents (<project>/.claude/
# agents/) do not need the origin check — they are governed by the rule once
# the project imports `@.claude/rules/authoring/agent-authoring-required.md`.
case "$file_path" in
  */.claude/agents/*)
    : # project-local, no origin check needed
    ;;
  *)
    origin=$(git -C "$plugin_root" remote get-url origin 2>/dev/null || echo "")
    case "$origin" in
      *batuta-agent-skills*|*batuta-agent-skills.git*)
        : # in scope
        ;;
      *)
        exit 0  # different plugin, gate does not apply
        ;;
    esac
    ;;
esac

if [[ "${BATUTA_AGENT_AUTHORING_BYPASS:-0}" == "1" ]]; then
  echo "pre-write-agent-gate.sh: BATUTA_AGENT_AUTHORING_BYPASS=1 — allowing creation of $file_path" >&2
  mkdir -p "$plugin_root/.claude" 2>/dev/null
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) BYPASS agent-gate file=$file_path" >> "$plugin_root/.claude/kb-debug.log" 2>/dev/null
  exit 0
fi

marker_dir="$plugin_root/.claude"
fresh_marker=""
if [[ -d "$marker_dir" ]]; then
  fresh_marker=$(find "$marker_dir" -maxdepth 1 -name '.authoring-marker-agent-*' -mmin -60 -print -quit 2>/dev/null)
fi

if [[ -n "$fresh_marker" ]]; then
  exit 0
fi

cat >&2 <<EOF
RULE violated (agent-authoring gate, v3.8): cannot create new agent file at:
  $file_path

No fresh authoring marker found at $marker_dir/.authoring-marker-agent-* (expires after 60 minutes).

Required workflow before creating an agent file:

  Plugin-shipped agent (under agents/ in the plugin repo):
    1. Invoke /skill batuta-agent-authoring and complete its workflow.
    2. Step 5 of the skill writes the marker.

  Project-local specialist (under <project>/.claude/agents/):
    1. Invoke agent-architect via Task. Its Phase 5.0 writes the marker.
    2. Phase 5 then writes the specialist file.

To bypass for legitimate cosmetic edits, restart Claude Code with:

  BATUTA_AGENT_AUTHORING_BYPASS=1 claude

Full rule: $plugin_root/rules/authoring/agent-authoring-required.md
EOF
exit 1
