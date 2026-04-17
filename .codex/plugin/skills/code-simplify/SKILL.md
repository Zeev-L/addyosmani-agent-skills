---
name: code-simplify
description: Runs the agent-skills code simplification workflow as an explicit compatibility alias. Use when you want the `agent-skills:code-simplify` or `/code-simplify` lifecycle entrypoint.
---

# Code Simplify

> Generated from `.claude/commands/code-simplify.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/code-simplify.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:code-simplify`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:code-simplification skill.

Simplify recently changed code (or the specified scope) while preserving exact behavior:

1. Read CLAUDE.md and study project conventions
2. Identify the target code — recent changes unless a broader scope is specified
3. Understand the code's purpose, callers, edge cases, and test coverage before touching it
4. Scan for simplification opportunities:
   - Deep nesting → guard clauses or extracted helpers
   - Long functions → split by responsibility
   - Nested ternaries → if/else or switch
   - Generic names → descriptive names
   - Duplicated logic → shared functions
   - Dead code → remove after confirming
5. Apply each simplification incrementally — run tests after each change
6. Verify all tests pass, the build succeeds, and the diff is clean

If tests fail after a simplification, revert that change and reconsider. Use `code-review-and-quality` to review the result.
