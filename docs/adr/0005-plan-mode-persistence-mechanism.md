# ADR 0005 — Plan-mode persistence is a slash command, not a runtime hook

**Status:** Accepted
**Date:** 2026-04-27
**Deciders:** jota-batuta
**Supersedes:** none

## Context

Claude Code's plan mode writes the integrated plan to `~/.claude/plans/<auto-name>.md` by default. The Batuta convention (documented in v2.4 user-global CLAUDE.md and enforced indirectly by the implementer pre-flight added in v2.4) requires the plan to live at `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md` so it travels with the repo via git.

v2.4 chose convention over automation: a reminder in user-global CLAUDE.md asking the operator to copy the plan project-local after exiting plan mode. The implementer pre-flight (also v2.4) catches the symptom by BLOCKING any slice whose `docs/plans/active/` is empty — but the root cause persists: every plan-mode session re-introduces the gap until the operator copies the file.

v2.5 deferred a Stop hook to v2.6. v2.6 considered two automation mechanisms:

1. **Runtime hook** — a `PreToolUse` hook on the `ExitPlanMode` tool that intercepts the plan content and copies it project-local automatically.
2. **Operator-invoked slash command** — `/save-plan <slug>` that the operator runs after exiting plan mode; performs the copy deterministically.

## Decision

**Slash command (`/save-plan`). Runtime hook deferred to v2.7 or later.**

The slash command lives at `.claude/commands/save-plan.md`. The operator invokes it with an optional slug argument; it copies the most recently modified file from `~/.claude/plans/*.md` to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md`, refusing to overwrite an existing target.

## Alternatives considered

### Alt 1 — Runtime hook on `PreToolUse` for `ExitPlanMode`

**Considered, rejected for v2.6.**

Implementation analysis surfaced two problems:

- **The `ExitPlanMode` tool does not expose the plan file path in its input.** The tool's documented schema (`allowedPrompts` field only) means the hook would receive a JSON payload with no reliable pointer to which file in `~/.claude/plans/` corresponds to this plan-mode exit. The hook would have to scan `~/.claude/plans/*.md` and pick the most-recently-modified file as a heuristic. This breaks under (a) concurrent plan-mode sessions (rare but possible), (b) clock skew between the hook process and the plan file's mtime, (c) any plan written before the hook fires (e.g. during `/loop` runs).
- **Hooks are non-interactive.** A runtime hook cannot prompt the operator for a slug; it must auto-derive one. Auto-derivation from the random Claude Code filename (`<words>-<adjective>-<noun>.md`) produces ugly slugs that the operator immediately wants to rename. Net result: a hook that runs automatically but produces output the operator has to clean up — worse than asking the operator to type a single command.

If a future Claude Code version exposes the plan file path in `ExitPlanMode` tool input, the hook becomes viable. Documented as a v2.7 candidate in `docs/PRD.md`.

### Alt 2 — Stop hook (fires when the agent stops responding)

**Rejected.** The Stop hook fires on *every* agent turn, not specifically on plan-mode exit. Distinguishing a plan-mode exit from a normal turn-end requires the same heuristic as Alt 1 (scan `~/.claude/plans/` for new files), with the additional cost of running on every turn even when no plan was written. Higher overhead, no advantage.

### Alt 3 — `SessionStart` hook that prompts about pending plans

**Rejected.** Detects the symptom (a plan in `~/.claude/plans/` not yet copied project-local) at the *next session*, not at the moment of plan-mode exit. By the time the next session starts, the operator has typically forgotten the slug they wanted. Catches drift but doesn't fix it.

### Alt 4 — Manual copy via the operator's terminal (no plugin support)

**Rejected — already the v2.4 status quo, and proved insufficient.** The whole reason v2.6 considered automation is that operators forget to copy after exiting plan mode. Status quo is what we are improving on.

## Consequences

### Positive

- **Deterministic.** The slash command does exactly what its body specifies, with no heuristic file-scanning. Idempotency check (refuses to overwrite) prevents silent destruction of a previously audited plan.
- **Operator controls the slug.** The operator types `/save-plan implementer-preflight` and gets the slug they want. Auto-derivation is a fallback for empty `$ARGUMENTS`, not the default.
- **Easy to test.** Static contract validation via `tests/v2.5-validators/` checks that the command file exists and has the expected steps. No runtime test needed.
- **Implementable today.** No dependency on Claude Code exposing the plan path in `ExitPlanMode` tool input.
- **Reversible.** When/if a runtime hook becomes viable in a future Claude Code version, the slash command can stay (operators can still invoke it manually) or be deprecated. Either way, no migration cost.

### Negative

- **Operator must remember to type the command.** This is the same drift risk that motivated automation in the first place. Mitigation: the implementer pre-flight (v2.4) still BLOCKS slices whose plan is missing project-local, so the cost of forgetting is "operator runs `/save-plan` then re-delegates" — minor friction, not lost work.
- **Adds one command to the operator's mental load.** Slash commands list grows by one. Mitigation: the command name is mnemonically aligned (`/save-plan` is what the operator wants to do) and the description in frontmatter shows in the slash-command picker.

### Neutral

- The user-global plan in `~/.claude/plans/` is preserved as a backup; the slash command does not delete it. Operators can `rm` the source manually if they want a clean user-global directory.

## References

- [`agents/implementer.md`](../../agents/implementer.md) — Step 0 pre-flight that BLOCKS on missing `docs/plans/active/`; this ADR's "negative consequence" mitigation depends on it
- [`agents/implementer-haiku.md`](../../agents/implementer-haiku.md) — same pre-flight for trivial-change implementer
- [`.claude/commands/save-plan.md`](../../.claude/commands/save-plan.md) — the slash command itself
- [`user-settings/CLAUDE.md`](../../user-settings/CLAUDE.md) and `~/.claude/CLAUDE.md` — operator reminder to invoke `/save-plan` after exiting plan mode (added in v2.6)
- [`docs/PRD.md`](../PRD.md) — v2.7 candidate entry for runtime hook, gated on Claude Code exposing plan path in `ExitPlanMode` input
