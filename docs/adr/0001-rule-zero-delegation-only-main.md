# ADR 0001 — Rule #0: the main agent never edits source code directly

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** jota-batuta
**Supersedes:** none

## Context

A typical Claude Code session running on Opus 4.7 burns tokens at premium rates because the main agent does routine implementation in its own context window instead of delegating. Even when the operator manually invokes `Task` to delegate, the subagents historically did not declare `model:` in their frontmatter, so they inherited Opus from the parent — delegation alone provided no savings. Multi-phase sessions also drift: when context compacts or the operator returns the next day, the integrated plan is lost.

The team needed a contract that:
1. Forbids the main agent from editing source code, period
2. Routes all implementation to subagents with explicit `model:` declarations
3. Persists across sessions so the rule does not regress when context compacts
4. Is enforceable beyond a documentary contract — the operator wanted runtime teeth

## Decision

The plugin adopts **Rule #0**: the main agent NEVER edits source code directly. All implementation, testing, and audit work is delegated via `Task` to subagents whose `model:` field is declared explicitly in their frontmatter.

The rule is materialized at three layers:

1. **Documentary contract:** [`../DELEGATION-RULE.md`](../DELEGATION-RULE.md) defines the mandatory chain (`implementer | specialist → test-engineer → code-reviewer → security-auditor`), the GATE 3 skip allowlist, and the anti-rationalization table for the main.
2. **Agent layer:** five base agents (`implementer`, `implementer-haiku`, `code-reviewer`, `security-auditor`, `test-engineer`) ship with explicit `model:` declarations, no Opus inheritance possible.
3. **Runtime enforcement:** `hooks/delegation-guard.sh` (PreToolUse) blocks Write/Edit/MultiEdit/NotebookEdit from the main agent unless the path is in a narrow whitelist (`specs/`, `docs/`, `.claude/commands/`, `.claude/CLAUDE.md`, `CLAUDE.md`, `AGENTS.md`, `MEMORY.md`, `memory/`, `build-log.md`, `lessons-learned.md`).

The main agent's surface is reserved for: conversation with the operator, `/spec` and `/plan` artifacts, invocation of subagents via `Task`, reading audit reports, deciding gate verdicts, and writing `lessons-learned.md` after a slice closes.

## Alternatives considered

### Alt 1 — Heuristic prompt in CLAUDE.md, no enforcement
**Rejected.** This is the failure mode the plugin exists to fix. A prompt that says "delegate, please" is ignored under context pressure. Documented contracts without enforcement degrade the moment the agent rationalizes a single exception.

### Alt 2 — `permissions.deny` for Write/Edit/MultiEdit globally
**Rejected.** The native `permissions.deny` system applies to all tool calls regardless of caller. Subagents would also be blocked, which defeats the purpose: implementation must happen *somewhere*. The plugin needs a per-caller distinction (main blocked, subagents allowed), and that requires the PreToolUse hook surface (see [ADR 0003](0003-plugin-level-hook-vs-permissions-deny.md)).

### Alt 3 — Single-tier subagent model (only Sonnet, no Haiku)
**Rejected.** Calibration data showed ~20–30% of tasks (CSS changes, renames, README edits, config flips) are mechanical enough that Haiku produces equivalent output at ~5× lower cost. Forcing all delegations to Sonnet is over-spend on the trivial tail. See [ADR 0002](0002-implementer-haiku-separate-agent.md) for the Haiku tier decision.

### Alt 4 — Ship without runtime enforcement, only documentary
**Rejected.** Considered seriously because hooks add complexity. Rejected because the operator's specific concern was that previous documentary-only attempts at delegation discipline had drifted within weeks. The hook is a forcing function the operator explicitly requested.

## Consequences

### Positive

- The main agent's context window stays focused on architecture; implementation tokens move to Sonnet/Haiku contexts.
- Subagents declare `model:` upfront — no silent Opus inheritance.
- Runtime enforcement means the rule survives compaction, operator absence, and re-entry into plan mode.
- The whitelist is narrow enough that violations are loud (the hook produces an actionable error message) and the operator notices immediately.

### Negative

- The hook adds a small latency to every Write/Edit call (one `bash` + one `jq` invocation, < 50ms typical).
- Operators who don't follow the convention (e.g., installing the plugin in a project that has source code at the repo root, not under a feature folder) will be blocked from editing and need to either restructure or disable the plugin.
- The kill-switch blocklist (`.claude/settings*.json`, `.claude/hooks/`, `.claude/agents/`) means the operator must edit those files via terminal, not through Claude Code itself.

### Neutral

- The contract is verbose. New operators need to read [`PRD.md`](../PRD.md), [`SPEC.md`](../SPEC.md), [`DELEGATION-RULE.md`](../DELEGATION-RULE.md), and the audit-chain conventions before contributing. Documented up-front rather than encountered as friction.

## References

- [`PRD.md`](../PRD.md) — problem statement and success metrics
- [`SPEC.md`](../SPEC.md) — architecture summary
- [`DELEGATION-RULE.md`](../DELEGATION-RULE.md) — mandatory chain contract
- [ADR 0002](0002-implementer-haiku-separate-agent.md) — Haiku tier decision
- [ADR 0003](0003-plugin-level-hook-vs-permissions-deny.md) — hook vs permissions
- [ADR 0004](0004-audit-chain-sequential-not-parallel.md) — sequential audit chain
- Anthropic engineering blog post "Claude Code best practices" — context budget and sub-agent guidance
