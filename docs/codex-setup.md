# Codex Setup

This guide explains how to use Agent Skills with Codex as native on-demand skills, while keeping the repository compatible with Claude Code and other agents.

## Installation

### Option 1: Use as a Codex Plugin

This repository includes a Codex plugin manifest at:

```text
.codex-plugin/plugin.json
```

The manifest points Codex at the existing skills directory:

```text
skills/
```

Use this option when your Codex environment supports local plugin installation or a marketplace entry that references a local plugin path. After installation, Codex can discover the skills from their frontmatter descriptions and load the full `SKILL.md` only when a task matches.

### Option 2: Install Skills Directly

For a lightweight setup, copy the skills into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills/agent-skills
cp -R /path/to/agent-skills/skills/* ~/.codex/skills/agent-skills/
```

Restart Codex after copying so the skill index is refreshed.

### Option 3: Use in a Project

For project-local behavior, keep these files in the repository root:

```text
AGENTS.md
skills/
```

`AGENTS.md` tells Codex how to map Claude-style concepts such as `Skill`, `Task`, `Read`, and `Edit` onto Codex-native behavior.

## How Codex Uses These Skills

Codex sees each skill as:

- A name and description from `skills/<skill-name>/SKILL.md` frontmatter
- A workflow to load only when the user request matches that description
- Optional supporting files and scripts resolved relative to the skill directory

When a skill applies, Codex should open the relevant `SKILL.md`, follow its workflow, and use the repo's normal verification commands.

## Command Parity

Claude Code uses slash commands from `.claude/commands/`. Codex does not need those commands to use this pack. Use plain-language prompts instead:

| Claude command | Codex prompt |
|---|---|
| `/spec` | `Write a spec for this feature.` |
| `/plan` | `Break this spec into implementation tasks.` |
| `/build` | `Implement the next task incrementally.` |
| `/test` | `Use the TDD workflow for this bug or feature.` |
| `/review` | `Review my current changes.` |
| `/code-simplify` | `Simplify this code without changing behavior.` |
| `/ship` | `Run the shipping checklist for this change.` |

## Compatibility Notes

- The Codex plugin manifest intentionally does not declare hooks. The existing hook files use Claude-specific environment variables and should stay Claude-only until a Codex hook contract is added.
- The `agents/` personas remain useful as prompt files, but Codex does not need them for skill discovery.
- The `.claude-plugin/` and `.claude/commands/` directories remain unchanged for Claude Code compatibility.

## Verify Compatibility

Run these checks from the repository root:

```bash
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/plugin.json >/dev/null
find skills -maxdepth 2 -name SKILL.md -print
```

The important checks are:

- `.codex-plugin/plugin.json` is valid JSON
- `skills` in the manifest points to `./skills/`
- every skill still has a `SKILL.md` file with `name` and `description` frontmatter
