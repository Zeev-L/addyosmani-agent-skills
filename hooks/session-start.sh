#!/bin/bash
# agent-skills session start hook
# Injects the using-agent-skills meta-skill into every new session

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
META_SKILL="$SKILLS_DIR/using-agent-skills/SKILL.md"

if [ -f "$META_SKILL" ]; then
  # Use JSON.stringify so quotes, backslashes, and newlines in SKILL.md cannot
  # break Claude Code's hook payload parser.
  META_SKILL="$META_SKILL" node <<'NODE'
const fs = require('fs');

const content = fs.readFileSync(process.env.META_SKILL, 'utf8');
const message = `agent-skills loaded. Use the skill discovery flowchart to find the right skill for your task.\n\n${content}`;

process.stdout.write(JSON.stringify({ priority: 'IMPORTANT', message }) + '\n');
NODE
else
  echo '{"priority": "INFO", "message": "agent-skills: using-agent-skills meta-skill not found. Skills may still be available individually."}'
fi
