#!/usr/bin/env bash
# delegation-guard.sh
# PreToolUse hook that enforces Rule #0: the main agent never edits source code directly.
# Blocks Write/Edit/MultiEdit/NotebookEdit when the target path is outside the allowed
# whitelist. Subagents (identified by agent_id in stdin JSON when hook_event_name is
# PreToolUse) are always allowed — they are bound by their own tools: declarations.
#
# Output protocol (per official Claude Code hooks reference):
# - exit 0: allow the tool call
# - exit 2: block the tool call. stderr is shown to the model as the block reason.
#
# Fail-soft: if jq is missing or input is unparseable, allow but warn to stderr — better to
# let work continue than to lock the operator out of their own configuration.
#
# Security invariants maintained by this script (regressions on these MUST be flagged):
# - file_path and agent_id NEVER reach a shell-execution context (no eval/$(...)/backticks).
#   They are only consumed by `case` patterns, `echo`/heredoc, and parameter expansion.
# - Subagent detection requires BOTH non-empty agent_id AND hook_event_name == "PreToolUse"
#   to avoid bypass via stdin spoofing in non-PreToolUse contexts.
# - The whitelist excludes the hook's own kill-switches (.claude/settings.json,
#   .claude/hooks/*, .claude/agents/*). Those surfaces are edited by the operator manually
#   or by subagents that bypass this script via agent_id.
#
# Known caveats (lexical guard, not semantic):
# - Symlinks under specs/ or docs/ resolving to src/ are NOT followed; the path string is
#   matched as-is. If symlink-traversal becomes a real attack surface, add `realpath` and
#   re-check against whitelist roots.

set -uo pipefail

input=$(cat)

# Fail-soft: jq is required to parse stdin JSON. If missing, allow with warning.
if ! command -v jq >/dev/null 2>&1; then
  echo "delegation-guard.sh WARN: jq not installed; hook is permissive. Install with 'winget install jqlang.jq'." >&2
  exit 0
fi

# Subagent detection: the official schema places agent_id in the stdin JSON when the hook
# fires inside a subagent (Task delegation). To prevent bypass via crafted JSON, we ALSO
# require that hook_event_name is the expected "PreToolUse" — anything else means the
# producer of stdin is not Claude Code's PreToolUse path and we should not honor agent_id.
event_name=$(echo "$input" | jq -r '.hook_event_name // empty' 2>/dev/null)
agent_id=$(echo "$input" | jq -r '.agent_id // empty' 2>/dev/null)
if [[ "$event_name" == "PreToolUse" && -n "$agent_id" ]]; then
  exit 0
fi

# Extract target path. Different tools use different keys.
# Source: https://code.claude.com/docs/en/hooks (verified 2026-04-26, Claude Code 1.x).
# Write/Edit/MultiEdit expose tool_input.file_path; NotebookEdit exposes tool_input.notebook_path.
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null)

# Empty path = unknown tool input shape; allow with warning rather than lock the operator.
if [[ -z "$file_path" ]]; then
  echo "delegation-guard.sh WARN: tool input had no file_path/notebook_path; allowing." >&2
  exit 0
fi

# Defensive normalization: convert backslashes to forward slashes so Windows-shaped paths
# (D:\proj\specs\...) match the same case patterns as POSIX paths. The official docs
# guarantee POSIX normalization for permission rule matching, but do not explicitly cover
# hook stdin on Windows — this is defense in depth.
file_path="${file_path//\\//}"

# Path-traversal guard: refuse paths where ".." appears as a path SEGMENT
# (e.g. specs/../src/secret.js or ../etc/passwd). Filenames that happen to
# embed two consecutive dots (eslint..rc, my..config.md) are NOT blocked.
case "$file_path" in
  ../*|*/..|*/../*|..)
    echo "RULE #0: path contains '..' as a segment (potential traversal). Refusing for safety." >&2
    echo "Path received: $file_path" >&2
    exit 2
    ;;
esac

# BLOCKLIST: paths the main agent must NEVER write to even if they syntactically fall
# under .claude/. These are the hook's own kill-switches — allowing the main to edit
# them would let it disable itself with one Edit. Operators edit these manually; subagents
# that legitimately need to write to them (e.g. agent-architect creating .claude/agents/<x>.md)
# bypass this script via agent_id.
case "$file_path" in
  */.claude/settings*.json|.claude/settings*.json|\
  */.claude/hooks/*|.claude/hooks/*|\
  */.claude/agents/*|.claude/agents/*)
    cat >&2 <<EOF
RULE #0: this path is a delegation-guard kill-switch. The main agent does not edit it.

Path attempted: $file_path

These paths control the hook itself or the agent registry. They must be edited:
- by the operator manually (settings, hooks/*.sh)
- by agent-architect via Task (for .claude/agents/<specialist>.md — agent-architect bypasses this hook via agent_id)

If you genuinely need the operator to update one of these, ask them in a message instead of editing.
EOF
    exit 2
    ;;
esac

# Whitelist: paths the main agent is allowed to write to.
# Match anywhere in the path (covers absolute Windows paths via Git Bash and bare relative paths).
case "$file_path" in
  */specs/*|specs/*|\
  */docs/*|docs/*|\
  */.claude/commands/*|.claude/commands/*|\
  */.claude/CLAUDE.md|.claude/CLAUDE.md|\
  */CLAUDE.md|CLAUDE.md|\
  */AGENTS.md|AGENTS.md|\
  */MEMORY.md|MEMORY.md|\
  */memory/*|memory/*|\
  */build-log.md|build-log.md|\
  */lessons-learned.md|lessons-learned.md)
    exit 0
    ;;
esac

# Block. Send actionable reason to stderr — Claude Code shows this to the main agent.
cat >&2 <<EOF
RULE #0 violated: the main agent does not edit project source code directly.

Path attempted: $file_path

Options:
1. If this is implementation work → Task with implementer (Sonnet) or implementer-haiku (Haiku for trivial changes). Pass the slice spec and DoD.
2. If this is a test → Task with test-engineer (Sonnet).
3. If this is a fix following a review → Task with implementer again, including the audit report as input.
4. If this is an SDD artifact (spec/plan/tasks/build-log/lessons-learned/review) → ensure the path is under specs/current/<slice-id>/ and retry.

Allowed paths for the main: specs/, docs/, .claude/, CLAUDE.md, AGENTS.md, MEMORY.md, memory/, build-log.md, lessons-learned.md.

See plugin batuta-agent-skills, docs/DELEGATION-RULE.md, for the full contract.
EOF

exit 2
