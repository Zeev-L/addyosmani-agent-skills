# ADR 0002 — `implementer-haiku` ships as a separate agent (not a parameter on `implementer`)

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** jota-batuta
**Supersedes:** none

## Context

Roughly 20–30% of routine tasks an operator delegates are mechanical: change a CSS class, rename a symbol, fix a typo in a string, bump a dependency version, edit a README. These tasks have no control flow, no async, no error handling — pattern matching against the task description is sufficient. Haiku 4.5 produces equivalent output to Sonnet on these tasks at roughly 5× lower cost.

To capture that saving, the plugin needs a way for the main agent to invoke "trivial-tier implementation". Three patterns were considered:

- A: Ship `implementer-haiku.md` as a separate agent file with `model: haiku` and a narrow scope contract.
- B: Keep one `implementer.md` (Sonnet) and pass `model: haiku` as an override at `Task` invocation time.
- C: Have `agent-architect` create per-project Haiku specialists ad-hoc when the recurring trivial pattern shows up.

## Decision

**Option A.** Ship `agents/implementer-haiku.md` as a separate plugin agent with `model: haiku` declared in frontmatter and an explicit "when to invoke / when NOT to invoke" contract scoped to trivial changes only. The agent has identical tool grants to `implementer` (Read, Write, Edit, Bash, Grep, Glob) but its body enforces a contractual boundary: if the task drifts beyond trivial during execution, it returns `BLOCKER: not trivial, escalate to implementer` and stops.

The main agent picks between `implementer-haiku` and `implementer` at delegation time using the task-complexity calibration table in [`DELEGATION-RULE-SPECIALISTS.md`](../DELEGATION-RULE-SPECIALISTS.md).

## Alternatives considered

### Alt B — Single `implementer` with model override at Task invocation
**Rejected.** Claude Code's `Task` tool resolves the model from the agent's frontmatter at invocation time. Per official documentation as of 2026-04-26 (Claude Code 1.x, validated against 2.1.119), no documented mechanism in this version overrides `model:` from the calling context — agents define their own tier and the caller selects which agent. Even if such an override existed, embedding tier choice in invocation prompts (rather than in the agent definition) would scatter the decision logic across hundreds of `Task` calls and lose the ability to enforce trivial-only boundaries via the agent's own body rules.

### Alt C — Per-project Haiku specialists via `agent-architect`
**Rejected.** `agent-architect` is justified when a *recurring domain pattern* shows up at least twice in a project (OAuth flows, e-invoicing parsing for the Colombian context, payment-processor webhooks). Trivial implementation is not a domain — it is a tier of work that applies to every project. Forcing each project to pay the cost of `agent-architect` invocation for what should be a default capability is friction without payoff. `agent-architect` remains for genuine domain specialists (which themselves can choose `model: haiku` if their domain's tasks are trivial — see the model table in [`DELEGATION-RULE-SPECIALISTS.md`](../DELEGATION-RULE-SPECIALISTS.md)).

## Consequences

### Positive

- Trivial-tier implementation is a first-class plugin capability with the same lifecycle as `implementer` (audit chain still applies, closing-line contract still required).
- The "trivial-only" boundary is enforced by the agent's body rules and its own anti-rationalization table — Haiku has explicit license to escalate via `BLOCKER` if the task surprises it.
- Calibration lives in one place: the task-complexity table in `DELEGATION-RULE-SPECIALISTS.md`. The main agent reads that to pick between agents.

### Negative

- Two implementer agents instead of one. New operators must learn the distinction. Mitigation: the agent's `description` field is short and explicit ("Trivial-change implementer for tasks with no logic"), and the calibration table provides 12 worked examples.
- `implementer-haiku` has identical tool grants to `implementer` (Write/Edit/Bash). A miscalibrated Haiku call could write logic-heavy code anyway. The contract is documentary-only at the agent level. Mitigation: the audit chain (test-engineer + code-reviewer + security-auditor) catches non-trivial output downstream and reopens the cycle. Risk is bounded.

### Neutral

- The reserved-name guard in `agent-architect` includes `implementer-haiku` so a project-local specialist cannot shadow it.

## References

- [ADR 0001](0001-rule-zero-delegation-only-main.md) — Rule #0 contract
- [`DELEGATION-RULE-SPECIALISTS.md`](../DELEGATION-RULE-SPECIALISTS.md) — calibration table by task complexity
- [`agents/implementer-haiku.md`](../../agents/implementer-haiku.md) — the agent itself
- [`agents/implementer.md`](../../agents/implementer.md) — the Sonnet sibling
