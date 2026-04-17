---
name: build
description: Runs the agent-skills build workflow as an explicit compatibility alias. Use when you want the `agent-skills:build` or `/build` lifecycle entrypoint, not for generic compilation or bundling tasks.
---

# Build

> Generated from `.claude/commands/build.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/build.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:build`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:incremental-implementation skill alongside agent-skills:test-driven-development.

Pick the next pending task from the plan. For each task:

1. Read the task's acceptance criteria
2. Load relevant context (existing code, patterns, types)
3. Write a failing test for the expected behavior (RED)
4. Implement the minimum code to pass the test (GREEN)
5. Run the full test suite to check for regressions
6. Run the build to verify compilation
7. Commit with a descriptive message
8. Mark the task complete and move to the next one

If any step fails, follow the agent-skills:debugging-and-error-recovery skill.
