# Plan: project-retrofit mode + implementer pre-flight + plan-mode persistence

**Slice ID:** retrofit-and-preflight
**Branch:** feature/retrofit-and-implementer-preflight
**Started:** 2026-04-27
**Status:** active
**Triggered by:** real-world bug discovered when operator opened a new project (BBVA Corriente) using plugin v2.3.0 — `batuta-project-hygiene` ran against a stale plugin cache (phantom SHA), partial bootstrap left `docs/` missing, implementer improvised `build-log.md` in project root, plan-mode plan never persisted to repo.

## Context

PR #4 added step 4 (doc skeleton) to `batuta-project-hygiene` `mode=project-init`, but the skill auto-trigger fires only when **`CLAUDE.md` is missing**. A project bootstrapped against an old plugin cache (without step 4) gets a partial CLAUDE.md but no `docs/` — and is stuck because re-running hygiene is gated by the existing CLAUDE.md.

PR #2 added the `implementer` agent. Its workflow says "write `specs/current/<slice-id>/build-log.md`" but has no pre-flight check that those paths exist. When called against a project missing the doc skeleton, the agent improvises (writes to project root) instead of blocking.

Plan mode in Claude Code 2.x writes the plan file to `~/.claude/plans/<auto-name>.md` (user-global). The convention in `CLAUDE.md` global expects `docs/plans/active/<slice>.md` (project-local). The convention is documented but not automated; the main agent must explicitly write the plan to the project after exiting plan mode — a step that currently has no reminder.

This slice closes all three gaps.

## Decisions

- **Add `mode=project-retrofit` to `batuta-project-hygiene`.** Detects projects where CLAUDE.md exists but the doc skeleton is missing, completes what's missing without overwriting what's there.
- **Add pre-flight check to `implementer` and `implementer-haiku`.** Before any work, verify `docs/plans/active/<slice-id>/` (or equivalent SDD root) exists. If not, BLOCKER with explicit message "run batuta-project-hygiene mode=project-retrofit first".
- **Add explicit reminder to user-global `CLAUDE.md`** under the existing "Delegation-only main agent (Rule #0)" section: after exiting plan mode, the plan file must be written to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md`. Sync to both real `~/.claude/CLAUDE.md` and `user-settings/CLAUDE.md` backup.
- **Bump version to 2.4.0** to mark the operator-detected gap closed.

## Out of scope

- Auto-running retrofit at session start (would require a SessionStart hook that detects partial state — adding hooks always raises the surface; defer to a future slice if v2.4 doesn't fully resolve the issue)
- Solving the phantom-SHA cache issue (Claude Code-level, not plugin-level)
- Migrating projects with stray build-logs to use the new structure (operator-side per-project work; documented in a follow-up runbook)

## Files to create / modify

### MODIFIED

- `skills/batuta-project-hygiene/SKILL.md` — add `Mode: project-retrofit` section between existing `Mode: project-init` and `Mode: feature-init`. The mode:
  - Triggers: `CLAUDE.md` exists at root AND any of {`docs/PRD.md`, `docs/SPEC.md`, `docs/plans/active`} is missing
  - Actions: run only the steps from `mode=project-init` that haven't been done (idempotent merges, never overwrite existing files)
  - Reports what was added vs preserved
- `agents/implementer.md` — add Pre-flight section to Workflow:
  - Step 0 (before reading spec/plan/tasks): verify `docs/plans/active/` exists (or `specs/current/` for legacy projects). If neither exists, return `BLOCKER: project lacks doc skeleton, run batuta-project-hygiene mode=project-retrofit before delegating implementation work`
  - Reject improvising build-log location: `build-log.md` must live in `docs/plans/active/<slice-id>/` or `docs/plans/archive/<slice-id>/`, never at project root
- `agents/implementer-haiku.md` — same pre-flight check (Haiku tier inherits the same boundary)
- `user-settings/CLAUDE.md` — add to the "Delegation-only main agent (Rule #0)" section a sentence: "**After exiting plan mode**, write the plan to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md` so it persists with the repo. Plan mode's default location (`~/.claude/plans/`) is user-global ephemera; the project-local plan is canonical."
- `~/.claude/CLAUDE.md` (real, operator-local) — same change applied to keep backup and real in sync
- `.claude-plugin/plugin.json` — version bump 2.3.0 → 2.4.0; refine description if needed
- `docs/PRD.md` — roadmap entry: `v2.4 (this slice)` describes the retrofit + pre-flight + plan-mode reminder

## Verification

1. `wc -l skills/batuta-project-hygiene/SKILL.md` ≤ 600 (currently ~470, target with retrofit ≤ 550)
2. `bash -n` on any new shell snippets the skill embeds (none expected; skill body is prose)
3. `agents/implementer.md` and `agents/implementer-haiku.md` line counts still ≤ 150
4. The new paragraphs added in this slice match between `~/.claude/CLAUDE.md` (real, operator-local) and `user-settings/CLAUDE.md` (backup in repo). Full files are not necessarily byte-identical (operator may have local-only sections) — what must match is the slice's specific additions to the "Delegation-only main agent (Rule #0)" section and the "Autonomous project hygiene" section.
5. `docs/PRD.md` roadmap line for v2.4 matches PRD.md style
6. `.claude-plugin/plugin.json` version is `"2.4.0"`; description still under 200 chars
7. Audit chain: code-reviewer + security-auditor return APPROVED
8. Manual smoke test in a fresh project: invoke `batuta-project-hygiene mode=project-retrofit` (after creating a fake CLAUDE.md without docs/), verify it adds docs/ skeleton and reports correctly

## Closing line

When this slice merges, move this plan file to `docs/plans/archive/2026-04-27-retrofit-and-preflight.md` and write a session journal at `docs/sessions/2026-04-27-retrofit-and-preflight-shipping.md`.

---

## Round 1 implementation

**Date:** 2026-04-27
**Agent:** implementer (Sonnet)

### Files modified

| File | Lines before | Lines after | Delta |
|---|---|---|---|
| `skills/batuta-project-hygiene/SKILL.md` | 455 | 490 | +35 |
| `agents/implementer.md` | 68 | 80 | +12 |
| `agents/implementer-haiku.md` | 72 | 84 | +12 |

All three files remain within their line-count ceilings (SKILL.md ≤ 600; agents ≤ 150).

### Changes applied

- **Edit 1** — Inserted `Mode: project-retrofit` section (35 lines) between the `project-init` verification block and the `Mode: feature-init` heading in `skills/batuta-project-hygiene/SKILL.md`. Includes trigger conditions, 4-step process, report format, and idempotent verification note.
- **Edit 2** — Added step 0 (Pre-flight check) to `## Workflow` in `agents/implementer.md` and appended the `build-log.md` root-write prohibition to `## Absolute rules`.
- **Edit 3** — Applied identical step 0 and absolute rule to `agents/implementer-haiku.md`.

### Deviations from plan

None. All three edits match the plan spec exactly.

### Escalation BLOCKERs

None.
