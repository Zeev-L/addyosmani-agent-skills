# Plan: Global docs skeleton + session-handoff protocol

**Slice ID:** global-docs-skeleton
**Branch:** feature/global-docs-skeleton
**Started:** 2026-04-26
**Status:** active

## Context

The plugin shipped Rule #0 enforcement (PR #2, merged) without project-wide documentation scaffolding. Today's session exposed the gap concretely: with 4 phases in flight, the main agent's context window was the only persistent memory of the integrated plan, and re-entering plan mode caused regression to a partial view (only Phase 3 was reproduced when the operator asked for the full plan). The fix is structural: persist the architecture and the active plan as repo artifacts, not in conversation history.

Industry consensus (validated against Spec Kit, Anthropic best-practices guidance, AGENTS.md standard) converges on a four-quadrant doc model:

| | Project-wide | Feature-scoped |
|---|---|---|
| Why (vision/metrics) | `docs/PRD.md` | `docs/features/<feature>/PRD.md` (optional) |
| How (architecture) | `docs/SPEC.md` | `src/<feature>/SPEC.md` |
| Why-this-how (decisions) | `docs/adr/NNNN-*.md` | (rare; major decisions promote up) |
| How-we-work (rules) | `CLAUDE.md` | `src/<feature>/CLAUDE.md` |

We have three of four quadrants for the feature level. We have only the `CLAUDE.md` quadrant for project level. This slice fills the missing three quadrants and adds session-handoff conventions so future long sessions don't drift the way today's did.

## Out of scope (explicit)

- E2E test of the plugin (Phase 4.3) — runs after this slice merges and `/plugin update` is run
- Refactor of existing `docs/DELEGATION-RULE.md` or `DELEGATION-RULE-SPECIALISTS.md` — they stay as feature-scoped specs
- Per-feature PRDs — only project-level PRD in this slice
- Implementing the session-handoff protocol as a hook or skill enforcement — this slice documents the convention only

## Files to create / modify

### NEW

1. `docs/plans/active/2026-04-26-global-docs-skeleton.md` — this file (dogfood the new convention)
2. `docs/PRD.md` — vision, problem, success metrics, non-goals
3. `docs/SPEC.md` — architecture overview ≤200 lines: 5 base agents + agent-architect + hook layer + audit chain + doc graph; references feature-scoped specs
4. `docs/adr/0001-rule-zero-delegation-only-main.md`
5. `docs/adr/0002-implementer-haiku-separate-agent.md`
6. `docs/adr/0003-plugin-level-hook-vs-permissions-deny.md`
7. `docs/adr/0004-audit-chain-sequential-not-parallel.md`
8. `docs/sessions/2026-04-26-rule-zero-implementation.md` — journal of today's work (what was decided, what changed, next entry point)

### MODIFIED

9. `CLAUDE.md` — extract "Project Structure" and "Skills by Phase" sections to `docs/SPEC.md`. Add `## Session-handoff protocol` section documenting `docs/plans/active|archive/`, `docs/sessions/`, TodoWrite hierarchy convention, and the "next entry point" line obligation.
10. `skills/batuta-project-hygiene/SKILL.md` — `mode=project-init` also creates the doc skeleton (PRD.md, SPEC.md, adr/0001-template.md, plans/active/, sessions/) when none exist. **This file is outside the main agent's hook whitelist; delegate to `implementer` (Sonnet).**

## Verification

1. **Doc graph integrity** — every link in `docs/SPEC.md` resolves; PRD references match SPEC; ADRs are numbered consecutively without gaps.
2. **CLAUDE.md slimmed** — removed Project Structure and Skills by Phase sections, kept conventions; added Session-handoff section.
3. **Skill extension end-to-end** — manually run the extended `batuta-project-hygiene` skill in a temp project; verify doc skeleton appears.
4. **Audit chain** — `code-reviewer` + `security-auditor` both return `AUDIT RESULT: APPROVED`.
5. **Dogfooding self-check** — at PR merge, this plan file moves to `docs/plans/archive/2026-04-26-global-docs-skeleton.md` along with its build-log sibling. The move is consistent with the rule defined in the new `CLAUDE.md` "Session-handoff protocol" section. Session journal `docs/sessions/2026-04-26-rule-zero-implementation.md` ends with "Next session entry point" line pointing at the next active plan or "no pending plans".

## Open questions / decisions deferred

- Whether to make session-handoff protocol auto-enforced via a Stop hook in a future slice. This slice documents only.
- Whether per-feature PRDs make sense. Project-level only for now.
- Whether to add `docs/CHANGELOG.md` (project-level changelog) — deferred to a follow-up slice.
