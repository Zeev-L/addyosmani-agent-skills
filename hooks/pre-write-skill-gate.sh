#!/usr/bin/env bash
# pre-write-skill-gate.sh
# PreToolUse hook — enforces rule `rules/authoring/skill-authoring-required.md`.
# Blocks Write/Edit/MultiEdit on **/skills/**/SKILL.md when the path does not
# already exist (creation, not edit) AND the target sits inside the
# batuta-agent-skills plugin repository AND no fresh authoring marker is found.
#
# Marker contract: `${CLAUDE_PLUGIN_ROOT}/.claude/.authoring-marker-skill-<ISO>`
#   - Written by `skills/batuta-skill-authoring` Step 4 (post-v3.8 SKILL.md).
#   - Valid for 60 minutes. Older markers are ignored.
#   - File `touch`-style mtime is the truth, not the filename ISO suffix —
#     `find` checks mtime so a stale marker with a fresh filename does not pass.
#
# Bypass: BATUTA_SKILL_AUTHORING_BYPASS=1 (operator-side env var, set on the
# shell launching Claude Code). Cannot be set from inside an agent's tool call.
#
# Output protocol:
#   exit 0 → allow the tool call
#   exit 1 → block the tool call (stderr is shown to the model as the block reason)
#
# Source: https://code.claude.com/docs/en/hooks (verified 2026-04-29, Claude Code 1.x)

set -uo pipefail

input=$(cat)

# Fail-soft: jq required to parse stdin JSON. Missing jq → allow with warning,
# matching delegation-guard.sh philosophy. The marker workflow plus operator
# review at PR time is the second line of defense.
if ! command -v jq >/dev/null 2>&1; then
  echo "pre-write-skill-gate.sh WARN: jq not installed; gate is permissive. Install with 'winget install jqlang.jq'." >&2
  exit 0
fi

# Extract the target path. Write/Edit/MultiEdit all expose tool_input.file_path.
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
if [[ -z "$file_path" ]]; then
  exit 0
fi

# Defensive normalization (handles Windows-shaped paths).
file_path="${file_path//\\//}"

# Path-traversal guard: refuse paths where ".." appears as a path SEGMENT.
case "$file_path" in
  ../*|*/..|*/../*|..)
    echo "pre-write-skill-gate.sh: path contains '..' as a segment. Refusing." >&2
    exit 1
    ;;
esac

# Match scope: only **/skills/**/SKILL.md, excluding the vendored mirror.
case "$file_path" in
  */skills/_vendored/*)
    exit 0  # vendored skills are mirrored from upstream, gate does not apply
    ;;
  */skills/*/SKILL.md|skills/*/SKILL.md)
    : # in scope, continue checks
    ;;
  *)
    exit 0  # not a SKILL.md path, out of scope
    ;;
esac

# Edit-vs-create boundary: if the file already exists on disk, it is an Edit
# (allowed without marker). If it does not exist, it is a Create (gated).
if [[ -e "$file_path" ]]; then
  exit 0
fi

# Resolve the plugin root from the target path. Walk up looking for
# `.claude-plugin/` (the marker for a Claude Code plugin repo). Fall back to
# the env var ${CLAUDE_PLUGIN_ROOT} if walking up does not find it (e.g. when
# the file is being created in a fresh layout).
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

if [[ -z "$plugin_root" && -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  plugin_root="${CLAUDE_PLUGIN_ROOT//\\//}"
fi

# If we still cannot find the plugin root, the file is being written somewhere
# outside a plugin repo — out of scope for this gate.
if [[ -z "$plugin_root" ]]; then
  exit 0
fi

# Repo-scope guard: only enforce when the plugin's git origin matches the
# batuta-agent-skills repo. Editing SKILL.md in any other plugin (forks,
# unrelated marketplaces) is out of scope for this rule.
origin=$(git -C "$plugin_root" remote get-url origin 2>/dev/null || echo "")
case "$origin" in
  *batuta-agent-skills*|*batuta-agent-skills.git*)
    : # in scope
    ;;
  *)
    exit 0  # different plugin repo, gate does not apply
    ;;
esac

# Operator-side bypass.
if [[ "${BATUTA_SKILL_AUTHORING_BYPASS:-0}" == "1" ]]; then
  echo "pre-write-skill-gate.sh: BATUTA_SKILL_AUTHORING_BYPASS=1 — allowing creation of $file_path" >&2
  mkdir -p "$plugin_root/.claude" 2>/dev/null
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) BYPASS skill-gate file=$file_path" >> "$plugin_root/.claude/kb-debug.log" 2>/dev/null
  exit 0
fi

# Look for a marker file less than 60 minutes old.
marker_dir="$plugin_root/.claude"
fresh_marker=""
if [[ -d "$marker_dir" ]]; then
  fresh_marker=$(find "$marker_dir" -maxdepth 1 -name '.authoring-marker-skill-*' -mmin -60 -print -quit 2>/dev/null)
fi

if [[ -n "$fresh_marker" ]]; then
  exit 0
fi

cat >&2 <<EOF
RULE violated (skill-authoring gate, v3.8): cannot create new SKILL.md at:
  $file_path

No fresh authoring marker found at $marker_dir/.authoring-marker-skill-* (markers expire after 60 minutes).

Required workflow before creating a SKILL.md:

  1. Invoke the skill: /skill batuta-skill-authoring
  2. Complete its workflow end-to-end (Steps 1–3: discovery, scaffolding, conventions).
  3. Step 4 of the skill writes the marker file. Do not skip it.
  4. Then re-attempt the Write — it will pass.

To bypass for legitimate cosmetic edits during a rebase, restart Claude Code
with the operator-side env var:

  BATUTA_SKILL_AUTHORING_BYPASS=1 claude

Full rule: $plugin_root/rules/authoring/skill-authoring-required.md
EOF
exit 1
