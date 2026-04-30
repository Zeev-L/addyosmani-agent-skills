---
name: Discover command/workflow wrapper
about: Implement a command wrapper for discovery that invokes the design-sprint skill.
title: "feat(commands): add /discover wrapper for design-sprint"
labels: [enhancement, workflow]
assignees: []
---

## Summary

Implement a convenience command/workflow wrapper for discovery that maps to `design-sprint`.

Primary target:

- `/discover`

Optional alias:

- `/sprint`

This issue is for wrapper orchestration only. The `design-sprint` skill remains the source of truth.

## Problem

Discovery is currently intent-driven (`AGENTS.md` lifecycle mapping). This works, but command-first users may expect an explicit entry point.

## Goals

- Add a clear command wrapper for discovery in Claude command workflows.
- Keep behavior aligned with `skills/design-sprint/SKILL.md`.
- Avoid duplicating sprint logic in command files.

## Non-Goals

- No redesign of the `design-sprint` skill process.
- No OpenCode-specific command implementation requirement.
- No changes to lifecycle routing semantics in `AGENTS.md` beyond command docs.

## Proposed Approach

1. Add `.claude/commands/discover.md`.
2. Wrapper should invoke `agent-skills:design-sprint`.
3. Wrapper should confirm track + depth if not provided:
   - Track: Design Creative or Development Creative
   - Depth: Quick / Standard / Deep
4. Wrapper should enforce sprint handoff behavior:
   - Ship → `spec-driven-development`
   - Iterate/Pivot → loop back to appropriate sprint phase
5. If alias is desired, add `.claude/commands/sprint.md` that forwards to the same workflow.

## Task Checklist

- [ ] Create `.claude/commands/discover.md`
- [ ] (Optional) Create `.claude/commands/sprint.md` alias
- [ ] Keep wrapper thin (no duplicated process logic from `SKILL.md`)
- [ ] Update docs command table(s):
  - [ ] `docs/getting-started.md`
  - [ ] `CLAUDE.md`
- [ ] Confirm OpenCode docs still describe intent-driven discovery (`docs/opencode-setup.md`)
- [ ] Validate markdown formatting/lint for changed files

## Acceptance Criteria

- Invoking `/discover` consistently starts discovery via `design-sprint`.
- Wrapper prompts for missing track/depth inputs before phase execution.
- Wrapper routes next steps based on sprint decision outcome.
- Docs clearly distinguish:
  - command wrapper UX (Claude)
  - intent-based routing (OpenCode)
- No behavior drift between command wrapper and skill definition.

## Risks / Considerations

- Wrapper drift from `SKILL.md` if logic is duplicated.
- Confusion if `/discover` and `/sprint` semantics diverge.
- Over-triggering if users use command for trivial tasks.

## Verification Notes

- Manual run-through of command entry path with:
  - low-uncertainty task (should suggest Quick mode)
  - high-uncertainty task (should suggest Standard/Deep)
- Validate that generated artifacts match expected sprint outputs.
