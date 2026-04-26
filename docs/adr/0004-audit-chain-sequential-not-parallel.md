# ADR 0004 — Audit chain runs sequentially, not in parallel

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** jota-batuta
**Supersedes:** none

## Context

After an `implementer` (or domain specialist) writes code, three audit gates run before the main agent closes the task:

- **GATE 1 — `test-engineer`:** verifies tests cover the slice and pass
- **GATE 2 — `code-reviewer`:** five-axis review (correctness, readability, architecture, security, performance)
- **GATE 3 — `security-auditor`:** OWASP-grounded vulnerability scan

The question: should these run in parallel (faster, but each auditor sees only the implementer's output) or sequentially (slower, but each auditor sees the previous gate's verdict)?

Claude Code supports parallel `Task` invocations from a single message. Both architectures are technically feasible.

## Decision

**Sequential. Each gate reads the previous gate's output before producing its own verdict.**

The order is fixed: `test-engineer` → `code-reviewer` → `security-auditor`. The main agent does not move to the next gate until the previous one returns `AUDIT RESULT: APPROVED`. A `BLOCKED` verdict reopens the cycle by re-invoking the implementer (or specialist) with the auditor's report attached, and the chain restarts from GATE 1.

## Alternatives considered

### Alt 1 — Parallel audit (all three fire simultaneously after implementer)
**Rejected.** Three concrete failure modes:

- **Reviewer can't validate test coverage.** When `code-reviewer` runs without seeing the test-engineer's verdict, it cannot tell whether the slice has tests at all (the implementer might have skipped them). Code review's first principle is "review the tests before reviewing the code" — that requires the test gate's output.
- **Security can't validate review's acceptance.** When `security-auditor` runs without seeing the code-reviewer's verdict, its OWASP findings can land on top of code that the reviewer already flagged for refactor. Two auditors flagging different facets of the same code creates conflicting reports the main has to reconcile, often by ignoring one.
- **No coherent BLOCKED state.** With parallel audits, three independent verdicts arrive at once. If GATE 1 says BLOCKED but GATE 2 says APPROVED, what does the main do? The cycle reopen with all three reports attached is messier than a single sequential failure that pinpoints the gate that stopped progress.

### Alt 2 — Sequential but with fast-fail (skip later gates on first BLOCKED)
**Considered, partially adopted.** The current decision *does* fast-fail: when GATE 1 blocks, GATE 2 and GATE 3 do not run. The main reopens the cycle from GATE 1 after the implementer fixes. This is implicit in the sequential design — there was no separate decision needed. Documented here so future readers don't think the alternative was rejected.

### Alt 3 — Concurrent within gate, sequential between gates
**Rejected.** Within a gate (e.g., GATE 2), there is only one auditor — no concurrency to exploit. Within GATE 1, multiple test runs could conceivably parallelize, but the test-engineer agent already sequences its own work internally. Adding plugin-level concurrency inside a gate creates surface area without payoff.

## Consequences

### Positive

- Each auditor gets full upstream context. `code-reviewer` reads `test-engineer`'s verdict and can comment on test quality; `security-auditor` reads `code-reviewer`'s and can defer code-quality findings to focus on exploitable vulnerabilities.
- BLOCKED states are unambiguous. The main knows exactly which gate stopped progress and which auditor's report to feed back to the implementer.
- The main agent's output stays clean. Three audit reports arriving sequentially are three short messages; three arriving in parallel are one long blob the operator has to reconcile.

### Negative

- Total audit time is the sum of three agent-call latencies (~30-90s in practice for non-trivial slices) instead of the max. For a slice with all gates approving on first pass, parallel execution would be roughly 2-3× faster.
- The main has to wait between gates, which appears slower in operator-facing reports. Mitigation: the report includes a clear "GATE 1: APPROVED → GATE 2: APPROVED → GATE 3: APPROVED" trail that makes the sequential progress visible.

### Neutral

- The skip allowlist for GATE 3 (defined in [`DELEGATION-RULE.md`](../DELEGATION-RULE.md)) means trivial doc-only slices skip security audit, which compensates for some of the sequential overhead on those changes.

## References

- [ADR 0001](0001-rule-zero-delegation-only-main.md) — Rule #0 contract
- [`DELEGATION-RULE.md`](../DELEGATION-RULE.md) — the chain itself, including GATE 3 skip allowlist and the closing rule
- [`agents/code-reviewer.md`](../../agents/code-reviewer.md) — Rule 1 in its body: "Review the tests first — they reveal intent and coverage"
- [`agents/security-auditor.md`](../../agents/security-auditor.md) — audit-gate-contract section
