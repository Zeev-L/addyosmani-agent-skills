---
description: Simplify code for clarity without changing behavior
agent: build
---

Load and follow the `code-simplification` skill using the native `skill` tool.

Simplify recently changed code, or the explicitly requested scope, while preserving exact behavior.

1. Read `AGENTS.md` and study local conventions
2. Understand the target code, callers, edge cases, and tests before touching it
3. Identify simplification opportunities such as deep nesting, duplicated logic, generic names, or dead code
4. Apply each simplification incrementally
5. Run tests after each meaningful change
6. Verify tests still pass and the build still succeeds

If a simplification breaks behavior, revert that simplification and reconsider.
