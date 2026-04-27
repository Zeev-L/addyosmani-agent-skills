# PRD — batuta-agent-skills

**Status:** living document
**Last reviewed:** 2026-04-27 (v2.6)
**Owner:** jota-batuta (Batuta)

## Problem

Operating an AI coding agent ecosystem at the Opus 4.7 tier produces three failure modes that compound over months:

1. **Premium model misuse.** The main agent does routine implementation in its own context window because it tends not to delegate by default. Every routine token is an Opus token. A typical engineering session burns 5–15× the necessary cost.
2. **Subagent inheritance footgun.** When the main does delegate via `Task`, subagents that don't declare `model:` in their frontmatter inherit Opus from the parent. Delegation alone provides no savings.
3. **Convention drift in long sessions.** Multi-phase sessions accumulate plans, decisions, and state in the conversation buffer. When context compacts or the operator returns the next day, the integrated plan is lost; only the last phase survives. The agent then improvises a partial view.

These are not workflow inconveniences. They translate to real business cost: a single operator running a small consulting practice (Batuta) sees $50–200/day in avoidable Opus tokens, plus rework cycles when partial-context decisions ship to production.

## Vision

**A plugin that turns any Claude Code session into a delegation-only architectural seat.**

The operator talks to Opus about architecture. Opus talks to Sonnet, Haiku, and project-local domain specialists about implementation. A runtime hook prevents the main from sliding back into hands-on coding. A persistent doc graph (PRD, SPEC, ADRs, plans, session journals) preserves context across sessions and across phases within a session.

## Users

- **Primary:** jota-batuta (Batuta consulting). Single-operator workflow serving multiple consulting clients across regulated and operational domains in Colombia, with recurring domain patterns (Colombian e-invoicing, banking integrations, OAuth flows, retail and ops automation).
- **Secondary:** other Anthropic Claude Code operators who want the same enforcement and don't want to wire it from scratch.

## Success metrics

Tracked per-month after plugin install in a project that adopts the convention:

| Metric | Baseline (no plugin) | Target (plugin enabled) | Verification |
|---|---|---|---|
| % session tokens consumed by Opus | 100% (default inheritance) | ≤ 25% | Anthropic billing dashboard tagged by session |
| Tasks closed without all 3 audit gates passing | high (no enforcement) | 0 | grep `AUDIT RESULT` in session transcripts |
| Context-window utilization at end of typical session | > 70% | < 50% | `/cost` and `/context` commands |
| Time spent re-explaining context after `/clear` or new session | minutes per session | seconds (read PRD + active plan) | self-reported, monthly retro |
| Routine tasks (CSS, rename, README) running on Sonnet instead of Haiku | high | < 10% | sample 20 random tasks/month from session transcripts |

## Non-goals

- **Replacing Claude Code's permissions system.** The plugin uses the existing PreToolUse hook surface; it does not redefine `permissions.allow`/`deny`.
- **Forcing Spanish-language artifacts.** Conventions follow operator's `~/.claude/CLAUDE.md` (English artifacts, Spanish conversation).
- **Cross-tool portability.** Designed for Claude Code 1.x. Cursor/Aider/Codex compatibility is incidental, not a goal.
- **Replacing the operator's judgment on PRs.** The plugin generates PRs but never merges; operator review remains the merge gate.
- **Generic Anthropic engineering best-practices.** This is opinionated for Batuta's workflow (multi-client, regulated domains in CO).

## Constraints

- Plugin must remain a thin layer over Claude Code's native primitives (hooks, agents, skills, slash commands). No external services for the core enforcement.
- All artifacts in English (operator preference for engineering deliverables).
- No `Co-Authored-By: Claude` in commits or PRs.
- Compatibility target: Claude Code 1.x (specifically validated on 2.1.119 as of 2026-04-26).
- Windows + Git Bash is a supported development environment (path handling must work on both POSIX and Windows-shaped paths).
- Backward compatibility with the upstream `addyosmani/agent-skills` patterns where they don't conflict; divergence is documented in ADRs.

## Architecture summary

For the technical architecture, see [`SPEC.md`](SPEC.md). For decision rationale on individual choices, see [`adr/`](adr/).

In one paragraph: the plugin ships five base agents (`implementer`, `implementer-haiku`, `code-reviewer`, `test-engineer`, `security-auditor`) with explicit `model:` declarations, a meta-agent (`agent-architect`) that creates project-local domain specialists on demand, a plugin-level PreToolUse hook (`delegation-guard.sh`) that enforces Rule #0 at runtime by blocking out-of-whitelist writes from the main agent, a sequential audit chain (test → review → security) that the main cannot bypass without ignoring three explicit blocking signals, and a documentation convention (PRD + SPEC + ADRs + active plans + session journals) that persists context across sessions.

## Roadmap (rolling)

- **v1.0 (shipped 2026-04-26, PR #2)** — Rule #0 enforcement, 5 base agents, agent-architect, plugin-level hook, delegation rule docs
- **v1.1 (shipped 2026-04-26, PR #3)** — Project-wide documentation scaffolding (PRD, SPEC, ADRs, session-handoff convention, cross-tool portability)
- **v1.2 (shipped 2026-04-26)** — E2E test harness for the delegation chain (run against PR #2 + PR #3 with three calibrated prompts; documented in `docs/sessions/2026-04-26-rule-zero-implementation.md`)
- **v1.3 (shipped 2026-04-26, PR #4)** — `rules/` layer: declarative engineering invariants library importable à la carte by consumer projects via `@<path>` symlinked through `tools/setup-rules.sh`. Includes `batuta-rule-authoring` skill as admission gate. Auto-bootstrap via `batuta-project-hygiene` `mode=project-init`.
- **v2.3 (shipped 2026-04-26, PR #5)** — User-level memory backup in `user-settings/` (MEMORY.md + 7 entries) so `~/.claude/MEMORY.md` and `~/.claude/memory/*.md` survive machine changes alongside the existing CLAUDE.md backup. Version bumps to 2.x to mark the architectural maturity inflection: post-v2 the plugin ships a complete delegation system + audit chain + doc graph + rules layer + memory persistence — the 1.x line was the bootstrap of those primitives.
- **v2.4 (shipped 2026-04-27, PR #7)** — Closes operator-detected gap: when a project bootstraps against a stale plugin cache (phantom-SHA scenario) the doc skeleton step never runs, leaving `docs/` missing; the implementer then improvises `build-log.md` in project root. Three structural fixes: (1) `batuta-project-hygiene` gains `mode=project-retrofit` to additively complete missing skeleton on projects with pre-existing `CLAUDE.md`; (2) `implementer` and `implementer-haiku` gain a Step 0 pre-flight that hard-fails with BLOCKER if `docs/plans/active/` is missing, refusing to improvise; (3) user-global `CLAUDE.md` and the `user-settings/` backup gain explicit reminder to persist plan-mode plans to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md` instead of leaving them at the user-global default `~/.claude/plans/`.
- **v2.5 (shipped 2026-04-27, PR #9)** — Closes two related subagent-enforcement gaps observed in real use: (1) the audit chain (`test-engineer → code-reviewer → security-auditor`) was firing during exploration / planning / ad-hoc database queries — phases that produce no code diff. Fix: new §"Audit chain scope" in `DELEGATION-RULE.md` defines runs-when vs does-not-run-when; each auditor gains a Step 0 pre-flight that returns `AUDIT RESULT: NOT APPLICABLE` when both `git diff --staged` and `git diff HEAD` are empty. (2) Research-first (Context7 lookup → web search → `// Source:` citation comment) lived in `~/.claude/CLAUDE.md` but was not wired into `implementer` / `implementer-haiku` prompts as an explicit step — subagents that "already knew" a library skipped the lookup and shipped outdated APIs. Fix: explicit Step 2 in `implementer` (mandatory) and conditional Step 2 in `implementer-haiku` (only on version bumps or import changes). `batuta-agent-authoring` gains verification rules 5–6 to enforce both wirings on any new agent definition.
- **v2.6 (this slice, PR #10)** — Closes the recurring leak in the meta-agent pipeline plus adds operator-invoked plan-mode persistence and static contract validators. Three deliverables: (1) `agents/agent-architect.md` Phase 5 now bakes the v2.5 enforcement patterns into every specialist it generates at runtime — research-first Step 2 (for code-writing specialists), conditional Step 0 NOT-APPLICABLE (for audit-gate specialists, rare), dual-path build-log resolution (`docs/plans/active/` preferred, `specs/current/` legacy), and a programmatic check that runs `batuta-agent-authoring` verification rules 5–6 against the generated file. Without this, every specialist created by `agent-architect` post-v2.5 reopened the gaps PR #9 just closed. (2) New `/save-plan <slug>` slash command at `.claude/commands/save-plan.md` that copies the most-recently-modified file from `~/.claude/plans/` to `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md`, refusing to overwrite existing targets. ADR-0005 documents why a slash command was chosen over a runtime hook on `ExitPlanMode` — the tool input does not expose the plan file path, making a hook fragile under concurrent sessions. (3) New `tests/v2.5-validators/` static contract validator suite (5 cases) that grep-checks agent prompts and skill files for the v2.5/v2.6 contract patterns; deterministic, fast, no `claude` CLI dependency. Run via `bash tests/v2.5-validators/run.sh`.
- **v2.7 (candidate)** — Runtime hook on `PreToolUse` for `ExitPlanMode` to make plan-mode persistence automatic instead of operator-invoked. Gated on Claude Code exposing the plan file path in the tool input (currently not available — see ADR-0005). If Claude Code surfaces the path, the hook becomes viable and supersedes the v2.6 slash command (which can stay as a manual fallback).
- **v2.7+ (candidate, deferred indefinitely)** — `gh pr merge` blocking hook for the main agent. Evaluated during v2.6 planning; rejected for shipping. Rationale: zero observed violations of "Claude never merges PRs" rule (single-operator workflow, operator merges via web UI), no kill-switch needed for a rule with no recurrence. Revisit if a violation appears.
- **v2.8 (candidate)** — First domain specialists promoted to user-global from project-local (candidates: Colombian e-invoicing validator and Colombian bank-statement parser specialists). Requires N=2 evidence of cross-project applicability per the `batuta-rule-authoring` admission gate.
- **v2.9 (candidate)** — Runtime E2E test harness invoking `claude` CLI on top of the v2.6 static validators. Builds on the static-checks foundation rather than replacing it. Gated on plugin growing CI infrastructure (GitHub Actions or equivalent).

Updates to this roadmap require an ADR if they change a v-numbered milestone's intent.
