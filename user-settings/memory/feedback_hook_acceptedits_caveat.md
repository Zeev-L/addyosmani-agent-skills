---
name: feedback_hook_acceptedits_caveat
description: Rule #0 PreToolUse hook is bypassed under --permission-mode acceptEdits; convention still holds via CLAUDE.md but no runtime enforcement under that flag
type: feedback
---

# `--permission-mode acceptEdits` bypasses the Rule #0 hook

## What we discovered

During the E2E test of PR #2 (delegation-enforcement) on 2026-04-26, the `tools/setup-rules.sh` hook (`hooks/delegation-guard.sh`) of plugin `batuta-agent-skills` did NOT block direct edits from the main agent when the session was launched with `claude -p --permission-mode acceptEdits`.

Evidence: tested by explicitly asking the main agent to edit `src/server.js` directly without delegating. Under `--permission-mode acceptEdits` the edit went through. Under default mode the hook blocked correctly with the actionable Rule #0 error message.

## Why this matters

The hook is the ONLY runtime enforcement layer of Rule #0 (the main agent never edits source code). Documentary contracts in CLAUDE.md hold by convention but are not enforced.

When `--permission-mode acceptEdits` is in use, Rule #0 is **convention-only**. The system prompt instruction (Rule #0 section in `~/.claude/CLAUDE.md`) is sufficient for Sonnet/Opus to delegate correctly in normal cases — that is what kept the E2E prompts A and B passing — but if the model rationalizes around the rule, there is nothing to stop it.

## How to apply

- **For interactive sessions:** prefer default permission mode. The hook fires and enforces.
- **For headless `claude -p` runs:** if you must use `acceptEdits`, treat Rule #0 as convention-only. Do not assume the hook is enforcing.
- **For E2E tests of the audit chain:** use default mode, accept the per-edit prompts. `acceptEdits` is convenient for cost control but breaks the test's assumption.
- **If you observe the main editing source code in any session:** that is a Rule #0 violation regardless of mode. Report it; the operator may want to harden the hook so it works under `acceptEdits` too (future plugin work).

## Status

Documented as a known caveat in `docs/PORTABILITY.md` and `docs/DELEGATION-RULE.md`. A future plugin slice may add a `Stop` hook or a `permissions.deny` rule as additional defense-in-depth, but as of 2026-04-26 the gap exists.
