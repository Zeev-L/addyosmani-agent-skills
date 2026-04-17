---
name: plan
description: Runs the agent-skills planning workflow as an explicit compatibility alias. Use when you want the `agent-skills:plan` or `/plan` lifecycle entrypoint, not for generic high-level discussion.
---

# Plan

> Generated from `.claude/commands/plan.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/plan.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:plan`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:planning-and-task-breakdown skill.

Read the existing spec (SPEC.md or equivalent) and the relevant codebase sections. Then:

1. Enter plan mode — read only, no code changes
2. Identify the dependency graph between components
3. Slice work vertically (one complete path per task, not horizontal layers)
4. Write tasks with acceptance criteria and verification steps
5. Add checkpoints between phases
6. Present the plan for human review

Save the plan to tasks/plan.md and task list to tasks/todo.md.
