#!/bin/bash
# agent-skills session start hook
# Injects the using-agent-skills meta-skill into every new session
#
# Output format: plain text stdout.
#
# Claude Code docs define two valid SessionStart output shapes:
#   1. Plain text stdout  → injected directly as additional context
#   2. {"hookSpecificOutput": {"additionalContext": "..."}}
#
# Shape 2 is broken for plugin-registered hooks (CC bug #16538: plugin
# SessionStart additionalContext is silently dropped). Plain text (shape 1)
# works reliably for both native and plugin hooks.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
META_SKILL="$SKILLS_DIR/using-agent-skills/SKILL.md"

if [ -f "$META_SKILL" ]; then
  printf 'agent-skills loaded. Use the skill discovery flowchart to find the right skill for your task.\n\n'
  cat "$META_SKILL"
else
  printf 'agent-skills: using-agent-skills meta-skill not found. Skills may still be available individually.\n'
fi
