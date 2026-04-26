# AGENTS.md

This file is the cross-tool entry point for AI coding agents working in this repository. It is the standard companion to tool-specific files (`CLAUDE.md`, `.cursor/rules/`, `.aider.conf.yml`, `GEMINI.md`, etc.) and is read natively by OpenAI Codex CLI, Cursor (as complement), Aider (via `read:`), Gemini CLI, OpenCode, and as fallback by Claude Code.

## Repository Overview

`batuta-agent-skills` is a Claude Code plugin that ships:

- **Six agents** with explicit `model:` declarations (5 base + `agent-architect` meta-agent)
- A **plugin-level PreToolUse hook** that enforces Rule #0 (the main agent never edits source code; everything goes through delegation)
- A **sequential audit chain** (`test-engineer` → `code-reviewer` → `security-auditor`) with literal `AUDIT RESULT: APPROVED|BLOCKED` contract
- A **project-wide doc graph** (`docs/PRD.md`, `docs/SPEC.md`, `docs/adr/`, `docs/plans/`, `docs/sessions/`)
- 26 skills (20 upstream engineering skills + 6 Batuta-specific)

## Rule #0 — delegation-only main agent (Claude Code-specific runtime)

**The main agent NEVER edits source code directly.** All implementation, testing, and audit work is delegated via the `Task` tool to subagents whose `model:` field is declared explicitly. The audit chain runs sequentially, blocking, before any task closes. This is enforced at runtime in Claude Code by the PreToolUse hook in `hooks/delegation-guard.sh`.

The full contract lives in [`docs/DELEGATION-RULE.md`](docs/DELEGATION-RULE.md). The Haiku/Sonnet/Opus calibration table for choosing which agent to delegate to lives in [`docs/DELEGATION-RULE-SPECIALISTS.md`](docs/DELEGATION-RULE-SPECIALISTS.md).

## Cross-tool note (Codex CLI, Cursor, Aider, Gemini CLI, Windsurf)

Tools other than Claude Code 1.x do not support PreToolUse hooks, the `Task` subagent model, or the runtime audit chain. **The doc graph (`docs/PRD.md`, `docs/SPEC.md`, `docs/adr/`, `docs/plans/`, `docs/sessions/`) is plain Markdown and ports 100%.** The agent definitions in `agents/*.md` describe the contract but cannot be invoked as Tasks outside Claude Code.

If you are running this repository in a tool other than Claude Code:

1. Read `docs/PRD.md` first (project vision)
2. Read `docs/SPEC.md` second (architecture)
3. Read `docs/plans/active/*.md` (in-flight work)
4. Read the most recent `docs/sessions/*.md` and follow its `Next:` line
5. **Self-enforce Rule #0** — do not edit source code; produce the same artifacts the agents would have produced (build-log, audit report) by hand. The doc graph survives the lack of runtime enforcement.

Full handoff checklist: [`docs/PORTABILITY.md`](docs/PORTABILITY.md).

## OpenCode Integration

OpenCode uses a **skill-driven execution model** powered by the `skill` tool and this repository's `/skills` directory.

### Core Rules

- If a task matches a skill, you MUST invoke it
- Skills are located in `skills/<skill-name>/SKILL.md`
- Never implement directly if a skill applies
- Always follow the skill instructions exactly (do not partially apply them)

### Intent → Skill Mapping

The agent should automatically map user intent to skills:

- Feature / new functionality → `spec-driven-development`, then `incremental-implementation`, `test-driven-development`
- Planning / breakdown → `planning-and-task-breakdown`
- Bug / failure / unexpected behavior → `debugging-and-error-recovery`
- Code review → `code-review-and-quality`
- Refactoring / simplification → `code-simplification`
- API or interface design → `api-and-interface-design`
- UI work → `frontend-ui-engineering`

### Lifecycle Mapping (Implicit Commands)

OpenCode does not support slash commands like `/spec` or `/plan`.

Instead, the agent must internally follow this lifecycle:

- DEFINE → `spec-driven-development`
- PLAN → `planning-and-task-breakdown`
- BUILD → `incremental-implementation` + `test-driven-development`
- VERIFY → `debugging-and-error-recovery`
- REVIEW → `code-review-and-quality`
- SHIP → `shipping-and-launch`

### Execution Model

For every request:

1. Determine if any skill applies (even 1% chance)
2. Invoke the appropriate skill using the `skill` tool
3. Follow the skill workflow strictly
4. Only proceed to implementation after required steps (spec, plan, etc.) are complete

### Anti-Rationalization

The following thoughts are incorrect and must be ignored:

- "This is too small for a skill"
- "I can just quickly implement this"
- "I’ll gather context first"

Correct behavior:

- Always check for and use skills first

This ensures OpenCode behaves similarly to Claude Code with full workflow enforcement.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name
    SKILL.md              # Required: skill definition
    scripts/              # Required: executable scripts
      {script-name}.sh    # Bash scripts (preferred)
  {skill-name}.zip        # Required: packaged for distribution
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g. `web-quality`)
- **SKILL.md**: Always uppercase, always this exact filename
- **Scripts**: `kebab-case.sh` (e.g., `deploy.sh`, `fetch-logs.sh`)
- **Zip file**: Must match directory name exactly: `{skill-name}.zip`

### SKILL.md Format

```markdown
---
name: {skill-name}
description: {One sentence describing when to use this skill. Include trigger phrases like "Deploy my app", "Check logs", etc.}
---

# {Skill Title}

{Brief description of what the skill does.}

## How It Works

{Numbered list explaining the skill's workflow}

## Usage

```bash
bash /mnt/skills/user/{skill-name}/scripts/{script}.sh [args]
```

**Arguments:**
- `arg1` - Description (defaults to X)

**Examples:**
{Show 2-3 common usage patterns}

## Output

{Show example output users will see}

## Present Results to User

{Template for how Claude should format results when presenting to users}

## Troubleshooting

{Common issues and solutions, especially network/permissions errors}
```

### Best Practices for Context Efficiency

Skills are loaded on-demand — only the skill name and description are loaded at startup. The full `SKILL.md` loads into context only when the agent decides the skill is relevant. To minimize context usage:

- **Keep SKILL.md under 500 lines** — put detailed reference material in separate files
- **Write specific descriptions** — helps the agent know exactly when to activate the skill
- **Use progressive disclosure** — reference supporting files that get read only when needed
- **Prefer scripts over inline code** — script execution doesn't consume context (only output does)
- **File references work one level deep** — link directly from SKILL.md to supporting files

### Script Requirements

- Use `#!/bin/bash` shebang
- Use `set -e` for fail-fast behavior
- Write status messages to stderr: `echo "Message" >&2`
- Write machine-readable output (JSON) to stdout
- Include a cleanup trap for temp files
- Reference the script path as `/mnt/skills/user/{skill-name}/scripts/{script}.sh`

### Creating the Zip Package

After creating or updating a skill:

```bash
cd skills
zip -r {skill-name}.zip {skill-name}/
```

### End-User Installation

Document these two installation methods for users:

**Claude Code:**
```bash
cp -r skills/{skill-name} ~/.claude/skills/
```

**claude.ai:**
Add the skill to project knowledge or paste SKILL.md contents into the conversation.

If the skill requires network access, instruct users to add required domains at `claude.ai/settings/capabilities`.
