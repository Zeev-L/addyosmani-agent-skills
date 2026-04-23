# OpenCode Setup

This repository is structured as a native OpenCode project.

## What OpenCode Uses

OpenCode will use these project assets directly:

- `AGENTS.md` for project instructions
- `.opencode/commands/` for custom slash commands
- `.opencode/skills/` for native skill discovery via the `skill` tool
- `.opencode/agents/` for specialist subagents
- `.opencode/plugins/` for optional runtime extensions

## Installation

1. Clone the repository.
2. Open it in OpenCode.
3. Start working.

No plugin marketplace or external packaging step is required.

## Commands

The repository provides these OpenCode commands:

- `/spec`
- `/plan`
- `/build`
- `/test`
- `/review`
- `/code-simplify`
- `/ship`

They are defined in `.opencode/commands/` and use OpenCode's native command system.

## Skills

Skills live in `.opencode/skills/<name>/SKILL.md`.

OpenCode exposes available skills through the native `skill` tool. Agents can load them on demand instead of keeping every workflow in prompt context at once.

## Agents

Specialist agents live in `.opencode/agents/`.

- `code-reviewer` for structured code review
- `test-engineer` for test strategy and implementation
- `security-auditor` for security review

Commands can target these agents directly. For example, `/review` is configured to run through the `code-reviewer` subagent.

## Plugins

OpenCode plugins are JavaScript or TypeScript files in `.opencode/plugins/`.

This repository includes a lightweight startup plugin that adds a reminder to use the skill-driven workflow.

## Notes For Migrating From Claude Code

- Claude command files are not used by OpenCode. Their OpenCode equivalents live in `.opencode/commands/`.
- Claude plugin manifests are not portable to OpenCode. Equivalent behavior must be rewritten as OpenCode plugins.
- OpenCode discovers native skills from `.opencode/skills/`, so the repository stores skills there directly.
