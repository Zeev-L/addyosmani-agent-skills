---
description: Run a TDD workflow for feature work or bug fixes
agent: build
---

Load and follow the `test-driven-development` skill using the native `skill` tool.

For new features:

1. Write tests that describe the expected behavior and confirm they fail
2. Implement the code to make them pass
3. Refactor while keeping tests green

For bug fixes:

1. Write a test that reproduces the bug and confirm it fails
2. Implement the fix
3. Confirm the new test passes
4. Run the full test suite for regressions

For browser-related issues, also load `browser-testing-with-devtools` and verify the behavior in a real browser.
