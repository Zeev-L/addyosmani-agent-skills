---
name: feedback_hook_acceptedits_caveat
description: v2.7 hook is kill-switch only; acceptEdits no longer bypasses meaningful enforcement. Hook semantics changed from workflow gate to self-disable defense.
type: feedback
---

# `--permission-mode acceptEdits` and the v2.7 kill-switch hook

## What changed in v2.7

The `hooks/delegation-guard.sh` hook shifted from workflow-enforcement (the old v1/v2.6 model that blocked main edits to any source file) to kill-switch only. The kill-switch list is exactly the paths where a bypass would be catastrophic:

- `.claude/settings*.json` — would let the main disable audit triggers
- `.claude/hooks/*` — would let the main disable the hook itself
- `.claude/agents/*` — would let the main overwrite agent contracts
- `.env*` — would let the main commit secrets
- `secrets/*` — would let the main commit secrets

All other paths (including project source files) are allowed; Claude uses its native judgment for the delegate-vs-edit decision.

## Why the memory file still matters

With v2.7, the hook's interaction with `--permission-mode acceptEdits` changed:

- **Before v2.7:** The hook blocked all main edits to source code, and `acceptEdits` bypassed the hook. Thus, `acceptEdits` = convention-only enforcement.
- **After v2.7:** The hook ONLY blocks kill-switch paths. `acceptEdits` still bypasses the hook, BUT the kill-switch paths should never be edited by the main anyway, so there is no longer a meaningful gap when `acceptEdits` is in use.

**However**, operators who set `acceptEdits` based on the v1 behavior should be aware that the hook's contract changed. If they were relying on the "accept all edits" escape hatch, they should understand that kill-switch paths are still dangerous and should be delegated (e.g., via `implementer-haiku` or a subagent).

## How to apply

- **Default enforcement:** prefer default permission mode. The hook fires for kill-switch checks.
- **Under `acceptEdits`:** the main agent can edit any path including source files. Convention-only rules apply; treat the delegation contract in `CLAUDE.md` and `DELEGATION-RULE.md` as non-binding. The audit chain (test → review → security) becomes critical to catch bad main edits before merge.
- **Kill-switch paths are still dangerous:** even under `acceptEdits`, editing `.env*`, `secrets/*`, `.claude/hooks/*`, etc. from the main is a self-disable risk. Delegate them.
- **For E2E tests of the audit chain:** use default mode if possible. `acceptEdits` skips the hook entirely, which limits what you can test about the runtime enforcement layer.

## Status

Documented in `docs/SPEC.md` (Layer 3) and `docs/adr/0006-trust-native-delegation.md`. The hook semantics as of 2026-04-27 are kill-switch only, not workflow enforcement.
