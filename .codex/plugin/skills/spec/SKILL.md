---
name: spec
description: Starts the agent-skills spec workflow as an explicit compatibility alias. Use when you want the `agent-skills:spec` or `/spec` lifecycle entrypoint, not a generic request to describe something.
---

# Spec

> Generated from `.claude/commands/spec.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/spec.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:spec`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:spec-driven-development skill.

Begin by understanding what the user wants to build. Ask clarifying questions about:
1. The objective and target users
2. Core features and acceptance criteria
3. Tech stack preferences and constraints
4. Known boundaries (what to always do, ask first about, and never do)

Then generate a structured spec covering all six core areas: objective, commands, project structure, code style, testing strategy, and boundaries.

Save the spec as SPEC.md in the project root and confirm with the user before proceeding.
