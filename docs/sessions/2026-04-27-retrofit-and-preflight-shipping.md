# Session journal — 2026-04-27 (retrofit + pre-flight shipping)

**Slice IDs touched:** `retrofit-and-preflight` (PR #7 merged); `housekeeping-2026-04-27` (PR #8 in flight)
**Operator:** jota-batuta
**Branch at session end:** `chore/housekeeping-2026-04-27`
**Plugin version at session end:** 2.4.0

## Context

Session continued from `2026-04-26-rules-layer-shipping.md` (`Next:` was "no pending plans"). The operator opened a real client project (BBVA Corriente) with the v2.3.0 plugin and reported three failures: hygiene appeared partial, the plan generated in plan mode never persisted to the project repo, and the implementer wrote `build-log.md` to project root instead of `docs/plans/active/<slice>/`. Investigation traced this to a phantom-SHA cache scenario (the operator's `installed_plugins.json` reported a `gitCommitSha` that didn't yet exist in the marketplace tree, so the bootstrapping ran against an old skill version), compounded by the fact that hygiene's auto-trigger gates on missing `CLAUDE.md` — once a partial bootstrap creates `CLAUDE.md`, hygiene won't re-run.

Two parallel actions were taken:

- **Vía 1**: manual retrofit of BBVA Corriente from a separate session in this plugin's repo (created `docs/PRD.md`, `docs/SPEC.md`, the full plans/sessions/adr/ skeleton; recovered the lost plan from session transcript `3a8917f0...jsonl`; relocated `build-log.md` and `BUILD_LOG_RAPPI.md` from project root to `docs/plans/archive/<slug>/`; wrote a session journal documenting the bug)
- **Vía 2**: structural fix in the plugin via PR #7 — three changes that prevent recurrence in any project, current or future

PR #7 shipped. This journal closes the cycle and documents the housekeeping in PR #8.

## Decisions

- **Retrofit is a new mode, not a fix to existing modes.** `mode=project-init` keeps its strict "missing CLAUDE.md" guard so it never overwrites operator customizations. The new `mode=project-retrofit` adds capability without changing existing behavior. Idempotent.
- **Implementer pre-flight is a hard BLOCKER.** Both `implementer` and `implementer-haiku` refuse to do any work if `docs/plans/active/` and `specs/current/` are both missing. They name the exact retrofit command in the BLOCKER message. No improvising in project root.
- **Dual-path canonical resolution.** Both implementers accept either `docs/plans/active/<slice-id>/` (current convention) or `specs/current/<slice-id>/` (legacy SDD layout). Pre-flight Step 0 establishes which path applies; Steps 1 (read) and 3 (write build-log) use that resolved path.
- **Plan-mode persistence is convention, not automation.** The fix is a reminder in user-global `CLAUDE.md` ("after exiting plan mode, write the plan to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md`") synced to both backup and real. No hook automates this; the operator's discipline plus the implementer pre-flight (which BLOCKERs if the plan isn't where expected) does the enforcement together.
- **Phantom-SHA cache is a Claude Code-level bug.** The plugin can't fix the cache reporting a SHA that doesn't exist in the marketplace tree. Operator workaround: full plugin reinstall. Documented in the BBVA session journal; out of scope for this slice.

## Changes (today)

### PR #7 (merged as `3576b2f`) — v2.4 retrofit + pre-flight + plan-mode persistence

- `skills/batuta-project-hygiene/SKILL.md` (455→491 lines): new `Mode: project-retrofit`. Triggers when `CLAUDE.md` exists AND any of `docs/PRD.md`, `docs/SPEC.md`, `docs/plans/active/`, `docs/plans/archive/`, `docs/sessions/`, `docs/adr/`, `.claude/rules/` is missing. Process: detect missing items, run only the matching sub-steps from `project-init`, NEVER overwrite. Reports added vs preserved. Idempotent (re-run reports no action needed).
- `agents/implementer.md` (68→81 lines): Step 0 pre-flight check + Absolute rule against `build-log.md` in project root + dual-path resolution in Steps 1 and 3.
- `agents/implementer-haiku.md` (72→85 lines): identical Step 0 + identical Absolute rules + identical dual-path logic.
- `user-settings/CLAUDE.md` (193→196 lines): two new paragraphs in "Delegation-only main agent (Rule #0)" section about plan-mode persistence and project-retrofit usage. Third trigger paragraph in "Autonomous project hygiene" section listing project-retrofit alongside project-init and feature-init. Synced to `~/.claude/CLAUDE.md` real.
- `.claude-plugin/plugin.json`: version 2.3.0 → 2.4.0. Description trimmed to 196 chars.
- `docs/PRD.md`: roadmap entry for v2.4. Last reviewed bumped to 2026-04-27.
- `docs/plans/active/2026-04-27-retrofit-and-preflight.md`: slice plan persisted at session START (dogfooding the new convention this slice introduces).
- Audit chain: code-reviewer APPROVED after 1 fix round (1 Critical resolved: build-log path contradiction; 2 Important resolved; 2 Suggestions + 2 minor stylistic observations applied). security-auditor APPROVED with 1 Medium + 2 Low + 3 Info defense-in-depth. No new shell-injection or path-traversal surface.

### PR #8 (this commit) — Housekeeping

- `docs/plans/active/2026-04-27-retrofit-and-preflight.md` → `docs/plans/archive/2026-04-27-retrofit-and-preflight.md`
- `docs/plans/active/.gitkeep` restored
- This session journal added

### BBVA Corriente retrofit (operator-side, not in any plugin PR)

- Created `docs/PRD.md`, `docs/SPEC.md`, `docs/adr/`, `docs/plans/active/`, `docs/plans/archive/`, `docs/sessions/` skeletons with `.gitkeep`
- Recovered the architecture-by-variable plan from session transcript `3a8917f0-8e69-49f6-b27b-d77a80b7c13e.jsonl` (timestamp 2026-04-27 18:08:51) and persisted to `docs/plans/active/2026-04-27-architecture-by-variable.md`
- Moved `build-log.md` (root, GMF collision fix) → `docs/plans/archive/2026-04-27-gmf-collision-fix/build-log.md`
- Moved `BUILD_LOG_RAPPI.md` (root, legacy) → `docs/plans/archive/2026-04-27-rappi-legacy/build-log.md`
- Wrote `docs/sessions/2026-04-27-bootstrap-and-retrofit.md` documenting the bug + retrofit
- BBVA root is now clean (no build-logs), structure ready for next session continuing the architecture-by-variable slice

## Findings worth keeping

### Plugin cache phantom-SHA is a real failure mode

The operator's `installed_plugins.json` reported `gitCommitSha: c80e3801...` for the v2.3.0 install. That SHA later turned out to be the eventual PR #6 merge commit, not the version the plugin was installed against — meaning the cache and the marketplace tree were temporarily out of sync. Symptom: skills run old code despite the plugin reporting a current version. Recovery: `/plugin uninstall && /plugin install` resolves the cache state. Tracked as Claude Code-level concern; documented in the BBVA session journal and in this one.

### Pre-flight-as-BLOCKER + retrofit is a clean pattern

The cycle works: implementer detects missing skeleton → BLOCKER with exact remediation → main reads the message → main invokes `mode=project-retrofit` → retrofit completes the missing parts additively → main re-delegates the original task → pre-flight passes. No infinite loop; no improvising. The audit chain found it sound. This pattern can be reused for other "skill should refuse if precondition not met" cases.

### Plan-mode persistence is a convention gap, not a Claude Code bug

Claude Code's plan mode writes to `~/.claude/plans/` by design. Our convention asks for `<project>/docs/plans/active/`. There is no hook to bridge this. Closing the gap requires either (a) a Stop hook that detects plan-mode exit and copies the plan, or (b) operator discipline reinforced by reminder + downstream implementer enforcement. v2.4 chose (b). If drift is observed in real use, v2.5 can add (a) — the plan already names this as a deferred milestone.

## Next

Next session entry point: `no pending plans on plugin side`.

The plugin is at v2.4.0 with all three structural fixes shipped. BBVA Corriente's `architecture-by-variable` slice is plan-active and ready to be picked up — but that's BBVA-side work, not plugin-side.

Suggested next actions, in priority order:

1. **BBVA Corriente** — return to that project, open Claude Code there, follow `docs/sessions/2026-04-27-bootstrap-and-retrofit.md` `Next:` line which points at `docs/plans/active/2026-04-27-architecture-by-variable.md`. The pre-flight check will pass (docs/plans/active/ exists), the implementer can proceed without improvising. Estimated 2-4 hours to ship Stage 1 + features encoding/numoper.
2. **(Optional) Stop hook for session-handoff (v2.5 milestone)** — only if the plan-mode persistence reminder proves insufficient in practice. Wait for a real drift instance before building the hook.
3. **(Optional) Promote BBVA-specific learnings to plugin** — once Stage 1 ships in BBVA and stabilizes, evaluate whether any pattern (e.g. "stages-as-immutable-parquets discipline") is generalizable enough to become a `rules/stack/` rule. Requires N=2 evidence per the §A.6 admission gate.
