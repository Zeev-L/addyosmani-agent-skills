# ADR 0006 — Trust Claude's native delegation; enforce only kill-switches + audit chain

**Status:** Accepted
**Date:** 2026-04-27
**Deciders:** jota-batuta
**Supersedes:** portions of ADR-0001 (the absolute "main NEVER edits" formulation)

## Context

The plugin shipped v1.0 with an absolute Rule #0: the main agent NEVER edits source code directly. This was enforced by `hooks/delegation-guard.sh` maintaining a path-whitelist that blocked all Write/Edit/MultiEdit/NotebookEdit from the main targeting anything outside `specs/`, `docs/`, `.claude/commands/`, `CLAUDE.md`, `AGENTS.md`, `MEMORY.md`, `memory/`, `build-log.md`, `lessons-learned.md`.

**N=2 evidence of friction** before this ADR was accepted:

1. **BBVA Corriente (client project)**: iterative DataFrame debugging in `pipeline.py`. Each debug iteration required the operator to wait for a round-trip to `implementer`, which included pre-flight checks, context load, and tool calls — taking 5–10 minutes per iteration instead of the < 2 minutes a direct 3-line edit would take. The main could see the fix, but the hook blocked it.

2. **Plugin repo dogfood (this session)**: implementing v2.6, the main discovered that editing `.claude/commands/save-plan.md` (a docs artifact by intent but not by path convention) required routing through `implementer` because the path-whitelist didn't cover `.claude/commands/` cleanly in all configurations. The plugin was blocking its own maintenance.

**Research finding** (from claude-code-guide analysis of official Anthropic documentation):

- Source: `https://code.claude.com/docs/en/sub-agents` (verified 2026-04-27, Claude Code 1.x)
- Source: `https://code.claude.com/docs/en/permissions` (verified 2026-04-27, Claude Code 1.x)

The official docs explicitly state:
- *"Quick targeted fixes (1 file, <20 lines), changes to files already open in conversation context"* → the main edits directly.
- *"Overhead of spawning and coordinating agents is real. For quick tasks, direct execution is faster."*
- PreToolUse hooks are documented as a mechanism for **hard constraints** (secret files, protected paths), not workflow enforcement routing.
- No permission mode (`default`, `acceptEdits`, `plan`, `auto`, `dontAsk`) imposes "delegate-only".

**Diagnosis**: the plugin's path-whitelist was more restrictive than the Anthropic platform pattern. It overwrote Claude's native delegation judgment for the "should I delegate or edit?" decision, which the platform explicitly says Claude should make itself.

## Decision

**Kill-switch-only enforcement + post-edit audit chain.**

The path-whitelist block is removed. The hook (`hooks/delegation-guard.sh`) blocks only paths that would result in plugin self-disable or secret leakage:

- `.claude/settings*.json` — disabling audit triggers
- `.claude/hooks/*` — disabling the hook itself
- `.claude/agents/*` — overwriting agent contracts
- `.env`, `.env.*` — committing secrets
- `secrets/*` — committing secrets

Everything else: the main agent decides whether to delegate (via `Task`) or edit directly, per Claude's native judgment.

The audit chain (test-engineer → code-reviewer → security-auditor) is the primary quality + security gate. It runs post-edit on `git diff` regardless of whether the main or a subagent produced the diff.

## Alternatives considered

### Alt 1 — Strict/advisory/off mode switch

**Rejected.** A mode switch would let projects opt in to the old path-whitelist behavior. Evaluated as over-engineering: (a) the framing "strict" vs "advisory" re-introduces the original misalignment with Anthropic's guidance for projects that opt strict; (b) no second use case has appeared for strict — v2.5 evidence is exactly two projects both pointing at friction; (c) adding a mode switch before N=2 evidence for strict is rule-invention without evidence. Deferred to v2.8 if compliance projects produce N=2 evidence for strict enforcement.

### Alt 2 — Keyword/heuristic detection

**Rejected.** Detecting "debug" vs "implement" in tool calls to decide whether to allow the main to edit is fragile and unpredictable. Claude's language is natural; a heuristic would block legitimate edits and pass illegitimate ones. Hard to test, easy to regress. The platform does this better natively.

### Alt 3 — Remove the hook entirely

**Rejected.** The kill-switch surfaces are genuinely dangerous: a main agent that can write `.claude/settings.json` can disable the audit-chain triggers with one Edit. The hook has real value protecting these surfaces. The correct scope is kill-switches only.

### Alt 4 — Keep the path-whitelist, add project-source paths to the allowlist

**Rejected.** The allowlist model requires maintenance every time a new project uses a different source layout (Django `activities/`, Next.js `app/`, FastAPI `services/`). Every new layout hits the block, requires an allowlist update, and re-introduces friction. The kill-switch model inverts the default to "allow with exceptions" which is correct for a hook that's not doing workflow enforcement.

## Consequences

### Positive

- **Aligns with Anthropic's Claude Code design pattern.** PreToolUse hooks for hard constraints, native judgment for workflow. The plugin no longer fights the platform.
- **Faster debug iteration.** Direct edits of ≤ 20 lines no longer require a 5–10 min round-trip. Estimated reclaim: BBVA Corriente debug sessions ~28 min/iteration saved.
- **Simpler hook.** `delegation-guard.sh` shrinks from ~136 LOC to ~95 LOC. Less code = fewer edge cases = easier to audit.
- **Audit chain quality unchanged.** The post-edit chain is the actual quality gate. It was always run post-edit; it now explicitly applies to main-produced diffs too.

### Negative

- **Main may over-edit and skip the audit chain accidentally.** Mitigation: audit chain still runs pre-merge (operator executes gates). If the main pushes without gates, the operator sees it in the PR and reopens. The one-line clarification added to each auditor's Step 0 ("this audit applies regardless of diff authorship") makes the expectation explicit.
- **Sessions with old memory of "Rule #0 absolute" may mis-cite the contract.** Mitigation: `DELEGATION-RULE.md`, `user-settings/CLAUDE.md`, and `~/.claude/CLAUDE.md` all updated; `CLAUDE.md` (project root) stale references updated. Memory files swept in this session journal.

### Neutral

- Agent contracts (`implementer`, `implementer-haiku`, `code-reviewer`, `test-engineer`, `security-auditor`) are unchanged. They remain the high-quality delegation destinations when Claude decides to delegate. The v2.5/v2.6 research-first Step 2 and audit-scope Step 0 contracts stand.

### What is intentionally NOT blocked

Some paths the main agent CAN edit despite being plugin-relevant. The audit chain (specifically `code-reviewer` + `security-auditor`) is the compensating control on these:

- **`skills/<name>/SKILL.md`** — skill definitions. A main-agent rewrite would alter the using-agent-skills flowchart; the audit chain catches the resulting diff.
- **`rules/<name>.md`** — engineering invariants. Same compensating control.
- **`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`** — plugin identity manifest. These do not affect runtime hook behavior; editing them does not bypass the kill-switch hook.
- **`MEMORY.md`, `memory/`** — auto-memory. A main-agent rewrite is visible in `git diff` at the next audit; memory is advisory text, not enforcement code.

This list captures intentional gaps so future auditors do not reconstruct the threat model from scratch. The audit chain (code-reviewer + security-auditor on staged diff) is the post-edit safeguard for all of these.

## References

- `https://code.claude.com/docs/en/sub-agents` (verified 2026-04-27, Claude Code 1.x) — native delegation guidance
- `https://code.claude.com/docs/en/permissions` (verified 2026-04-27, Claude Code 1.x) — PreToolUse hook scope
- [`hooks/delegation-guard.sh`](../../hooks/delegation-guard.sh) — the rewritten hook
- [`docs/DELEGATION-RULE.md`](../DELEGATION-RULE.md) — updated contract
- [`docs/adr/0001-rule-zero-delegation-only-main.md`](0001-rule-zero-delegation-only-main.md) — original Rule #0 ADR (context; this ADR narrows its scope, does not supersede its audit-chain component)
- [`docs/adr/0003-plugin-level-hook-vs-permissions-deny.md`](0003-plugin-level-hook-vs-permissions-deny.md) — why a hook; still valid for the kill-switch use case
