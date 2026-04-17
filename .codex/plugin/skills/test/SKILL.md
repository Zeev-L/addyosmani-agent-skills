---
name: test
description: Runs the agent-skills test workflow as an explicit compatibility alias. Use when you want the `agent-skills:test` or `/test` lifecycle entrypoint, not for generic test runner commands.
---

# Test

> Generated from `.claude/commands/test.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/test.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:test`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:test-driven-development skill.

For new features:
1. Write tests that describe the expected behavior (they should FAIL)
2. Implement the code to make them pass
3. Refactor while keeping tests green

For bug fixes (Prove-It pattern):
1. Write a test that reproduces the bug (must FAIL)
2. Confirm the test fails
3. Implement the fix
4. Confirm the test passes
5. Run the full test suite for regressions

For browser-related issues, also invoke agent-skills:browser-testing-with-devtools to verify with Chrome DevTools MCP.
