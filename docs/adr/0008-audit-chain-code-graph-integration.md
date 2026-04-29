# ADR 0008 — Audit chain consults the code-graph for blast radius / attack surface (v3.0)

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** jota-batuta

## Context

After v2.8 (code-graph dual engine) and v2.9 (supply-chain hardening), the plugin has a code-graph layer but the audit chain itself does not consult it. Today `code-reviewer` and `security-auditor` re-read individual files in the diff. They miss cross-file impacts that the diff does not surface — a renamed function used in 12 places, a new SQL query reachable from an unvalidated route handler, a refactor that changes the contract of a public symbol used by other modules.

The code-graph already encodes the relationships needed to surface these impacts: callers/callees, symbol references, call paths to sinks. Not consulting it is leaving leverage on the table.

The decision is **how** to wire the integration without breaking the existing audit chain or making it depend on the engines.

## Decision

Add **Step 0.5 — Blast-radius / Attack-surface enumeration** to `code-reviewer` and `security-auditor`. Step 0.5 sits between the existing Step 0 (NOT-APPLICABLE on clean tree) and the existing review framework. It is **strictly additive and non-blocking**:

1. **Availability check first**: `bash tools/check-code-graph-engines.sh >/dev/null 2>&1`. Non-zero exit → log "code-graph unavailable; falling back to diff-only review" and skip Step 0.5 entirely. The auditor proceeds with v2.9 behavior unchanged. The plugin never installs anything from inside an audit.

2. **If available**: enumerate the **blast-radius set** (code-reviewer) or **attack-surface set** (security-auditor), bounded at ~30 files (code-reviewer) / call paths of length ≤ 5 (security-auditor). Read those files in addition to the diff hunks. The 5-axis review (code-reviewer) or severity-classification flow (security-auditor) runs unchanged but with broader context.

3. **Cite the engine** in the final report (`[blast radius via codebase-memory-mcp: 14 files]` / `[attack surface via graphify: 8 files, 3 paths to sinks]`). Operator and reviewers can see at a glance whether the audit was diff-only or graph-augmented.

4. **Step 0.5 never returns BLOCKED.** All findings still funnel through the existing severity classification. Step 0.5 only changes WHAT the auditor reads, not the verdict shape.

## What is intentionally NOT done

- **`test-engineer` is not modified.** Test scope is bounded by the test files themselves, not by call paths. Adding blast-radius logic there would broaden test scope beyond its mandate (and conflict with the rule "test behavior, not implementation"). The graph could surface test files that exercise the modified code, but the existing approach (read tests under the changed module's directory) catches that already.

- **No new hook.** Step 0.5 is doctrinal in the agent prompt, not enforced by a runtime hook. Consistent with [ADR-0006](0006-trust-native-delegation.md).

- **No engine selection logic in the auditors.** They call `check-code-graph-engines.sh` and use whichever engine is reported as `best`. Auditor prompts do not duplicate the skill's heuristic.

- **No fallback to skill-mediated graph queries.** The auditors call the engine's MCP tools (or read graphify-out/) directly, not via the `code-graph` skill. Reason: the skill is for the operator-conversation path; auditors are subagents with structured context, not interactive users.

- **No backfill of prior PRs.** PRs already merged are not re-audited. Step 0.5 applies to future audits only.

## Alternatives considered

### Alt α — Make Step 0.5 mandatory (block on missing graph)

**Rejected.** The plugin already has graceful-degrade discipline ([ADR-0006](0006-trust-native-delegation.md)). Forcing the audit chain to fail when the graph is missing creates a hard dependency on a layer that itself can be partially broken (graphify on Windows). Worse, it would introduce circular gating: a slice that fixes the code-graph engine setup couldn't be reviewed without the engine being functional.

### Alt β — Inject blast-radius results into the diff itself (synthetic patch)

**Rejected.** Mutating the input the auditor reads is more confusing than expanding what it reads alongside the diff. Diffs are for humans; the auditor's input expansion is for the auditor's own reasoning.

### Alt γ — Add Step 0.5 to all three auditors including `test-engineer`

**Rejected.** See "intentionally NOT done" above. test-engineer's scope guard is intentional; broadening it would dilute the gate.

### Alt δ — Run Step 0.5 in the main agent and pass the result to subagents

**Rejected.** The main agent does not always know whether subagents will run; running the engine query speculatively wastes tokens. Subagents already have the context to know they need the graph.

## Consequences

### Positive

- **Catches cross-file regressions** that diff-only review misses (a function renamed in the diff used in 12 untouched files).
- **Surfaces hidden attack surface** for the security auditor (a new SQL execute reachable via 3-hop call chain from an unvalidated handler).
- **Graceful degrade** — the audit chain works exactly as v2.9 when the graph is missing. No regression risk.
- **Aligns the existing layers**: v2.8 built the graph, v3.0 makes the audit chain use it. Closes the loop opened by v2.8's open question "wire `code-reviewer` / `security-auditor` to consult the graph."

### Negative

- **More tokens per audit** when the graph is available. The auditor reads ~10–30 additional files per slice. Mitigated by the 30-file cap (code-reviewer) and 5-hop path cap (security-auditor); operator can disable via `code-graph-engine: none` in project CLAUDE.md if the cost is unacceptable.
- **Auditor prompts grow** by ~30 lines each. Mitigated by extracting the boilerplate into one Step 0.5 block per auditor; static validator 09 enforces the structure.

### Neutral

- The `code-graph` skill is unchanged. The auditors call the engines directly (not via the skill). Consistent with the skill being the operator-facing entry point and the auditors being structured subagents.
- ADR-0007's open question on audit-chain integration is closed by this ADR.

## Verification

- [tests/v2.5-validators/09-audit-chain-graph-integration.sh](../../tests/v2.5-validators/09-audit-chain-graph-integration.sh): static check that `code-reviewer.md` and `security-auditor.md` declare Step 0.5 with the graceful-degrade clause and engine citation, and that `test-engineer.md` does NOT (scope guard).
- E2E (slice v3.0c, [tests/e2e/](../../tests/e2e/)): `scenarios/04-audit-chain-clean-tree.sh` confirms the auditor still returns NOT APPLICABLE on a clean tree (Step 0 short-circuits before Step 0.5 runs, as intended).

## References

- [`agents/code-reviewer.md`](../../agents/code-reviewer.md) — modified
- [`agents/security-auditor.md`](../../agents/security-auditor.md) — modified
- [`agents/test-engineer.md`](../../agents/test-engineer.md) — intentionally NOT modified
- [`tools/check-code-graph-engines.sh`](../../tools/check-code-graph-engines.sh) — availability gate used by Step 0.5
- [ADR-0006](0006-trust-native-delegation.md) — establishes the graceful-degrade discipline
- [ADR-0007](0007-code-graph-dual-engine.md) — establishes the dual-engine code-graph this ADR consumes
