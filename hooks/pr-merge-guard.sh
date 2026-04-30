#!/usr/bin/env bash
# pr-merge-guard.sh
# PreToolUse hook — blocks `gh pr merge` from any Claude tool call by default.
# Operator-explicit override: set BATUTA_ALLOW_PR_MERGE=1 in the shell that
# launches Claude Code. The env var is operator-side and cannot be set from
# inside an agent's tool call — that is the design.
#
# The "Claude never merges PRs" rule has no observed runtime violations to
# date; this hook exists as a backstop against drift, not as a defense
# against an active threat. Shipped in v3.6 (PR #...).
#
# Subagent behavior: this hook applies to ALL contexts (main agent and any
# subagent). Unlike delegation-guard.sh, no subagent legitimately needs to
# merge PRs — auditors are read-only on PRs, agent-architect creates agents,
# implementers do not have merge in their tool scope. So no agent_id bypass.
#
# Output protocol:
#   exit 0 → allow the tool call
#   exit 1 → block the tool call (stderr is shown to the model as the block reason)
#
# Source: https://code.claude.com/docs/en/hooks (verified 2026-04-29, Claude Code 1.x)

set -uo pipefail

input=$(cat)

# Fail-soft: jq is required to parse stdin JSON. If missing, allow with warning.
# Same fail-open philosophy as delegation-guard.sh — a parse error should not
# lock the session. Worst case: a `gh pr merge` slips through, which the
# operator catches in the PR list anyway.
if ! command -v jq >/dev/null 2>&1; then
  echo "pr-merge-guard.sh WARN: jq not installed; hook is permissive." >&2
  exit 0
fi

# Extract the Bash command. Other tools' hooks won't reach this matcher; this
# is registered only for the `Bash` matcher in hooks.json.
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Empty command: nothing to inspect, allow.
if [[ -z "$command" ]]; then
  exit 0
fi

# Match `gh pr merge` with optional whitespace variations. Handles:
#   gh pr merge
#   gh   pr   merge
#   gh pr merge --squash
#   gh pr merge 123 --merge
#   gh\tpr\tmerge
# Does NOT match (correctly):
#   gh pr list
#   gh pr view
#   gh pr review
#   git merge   (different command entirely)
if ! echo "$command" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
  exit 0
fi

# Operator-side opt-in. Env var must be set on the shell launching claude.
# Cannot be set from inside an agent's tool call — that is the deliberate
# design that makes this hook resistant to bypass-by-prompt-injection.
if [[ "${BATUTA_ALLOW_PR_MERGE:-0}" == "1" ]]; then
  echo "pr-merge-guard: 'gh pr merge' allowed by BATUTA_ALLOW_PR_MERGE=1" >&2
  exit 0
fi

cat >&2 <<EOF
RULE violated: 'gh pr merge' is blocked by default.

The "Claude never merges PRs" rule (documented in CLAUDE.md global): the
operator merges PRs manually via the GitHub web UI or terminal outside Claude.
This hook is a backstop against drift — it has not been triggered by an
observed violation.

To authorize merging from this Claude Code session, restart with the
operator-side env var set:

  BATUTA_ALLOW_PR_MERGE=1 claude

Or export it for the shell:

  export BATUTA_ALLOW_PR_MERGE=1
  claude

The env var is operator-side and cannot be set from inside an agent — that
is the design. If you (the agent) believe this merge is legitimate, surface
the request to the operator and stop.

Command attempted: ${command}
EOF
exit 1
