# SPEC — batuta-agent-skills

**Status:** living document
**Last reviewed:** 2026-04-26
**Companion documents:** [`PRD.md`](PRD.md) (why), [`adr/`](adr/) (per-decision rationale), feature-scoped specs in `docs/<feature>.md` and `skills/<skill>/SKILL.md` (how each module works)

This is a project-wide architecture overview. It describes what the plugin contains, how the pieces fit, and what constraints they enforce. Per-module behavior lives in feature-scoped specs (cross-referenced from each section below).

## Component map

```
batuta-agent-skills/
├── CLAUDE.md                  ← project conventions (rules, not architecture)
├── docs/
│   ├── PRD.md                 ← problem, vision, success metrics
│   ├── SPEC.md                ← this file
│   ├── adr/                   ← per-decision rationale (numbered, dated, immutable once accepted)
│   ├── plans/active/          ← exactly one active plan per feature branch
│   ├── plans/archive/         ← completed plans, dated
│   ├── sessions/              ← session journals (YYYY-MM-DD-<slug>.md)
│   ├── DELEGATION-RULE.md            ← feature spec: Rule #0 contract
│   └── DELEGATION-RULE-SPECIALISTS.md ← feature spec: agent-architect + Haiku/Sonnet calibration
├── agents/                    ← 6 plugin-shipped agents (5 base + 1 meta), all with explicit model:
├── hooks/
│   ├── hooks.json             ← SessionStart + PreToolUse registration
│   ├── session-start.sh       ← session-start advice hook
│   └── delegation-guard.sh    ← PreToolUse Rule #0 enforcement
├── skills/                    ← invocable skills (build, plan, spec, test, review, etc.)
├── .claude/commands/          ← slash commands (/spec, /plan, /build, ...)
└── references/                ← supplementary checklists
```

## Layer 1 — Agents (six shipped, all with explicit `model:`)

| Agent | Model | Role | Tool grants |
|---|---|---|---|
| `implementer` | sonnet | Generic implementer for spec-driven slices | Read, Write, Edit, Bash, Grep, Glob |
| `implementer-haiku` | haiku | Trivial-change executor (CSS, rename, README, config flips) | Read, Write, Edit, Bash, Grep, Glob |
| `code-reviewer` | sonnet | GATE 2 — five-axis review with `AUDIT RESULT` contract | Read, Grep, Glob, Bash |
| `security-auditor` | sonnet | GATE 3 — OWASP-grounded vulnerability scan | Read, Grep, Glob, Bash |
| `test-engineer` | sonnet | GATE 1 — test design + coverage; `Write` scoped to test paths | Read, Write, Bash, Grep, Glob |
| `agent-architect` | sonnet | Meta-agent: creates project-local specialists on demand | Read, Write, Glob, Grep, WebSearch, WebFetch |

The five base agents form the audit chain (test → review → security after implementation). `agent-architect` is the meta-layer for dynamic specialist creation; it does not execute work itself. See [`adr/0001-rule-zero-delegation-only-main.md`](adr/0001-rule-zero-delegation-only-main.md) for why these specific roles, [`adr/0002-implementer-haiku-separate-agent.md`](adr/0002-implementer-haiku-separate-agent.md) for why the Haiku tier is a separate agent, and [`DELEGATION-RULE-SPECIALISTS.md`](DELEGATION-RULE-SPECIALISTS.md) for the task-complexity calibration that picks the model.

## Layer 2 — Project-local specialists (created at runtime by `agent-architect`)

`agent-architect` materializes `<project>/.claude/agents/<name>.md` files when a slice needs domain expertise the base agents don't cover. Each specialist gets:

- Explicit `model:` (Haiku, Sonnet, or Opus by the calibration table)
- Minimal `tools:` list (per role: implementer / auditor / researcher)
- Workflow ending with the literal `READY FOR AUDIT: test-engineer → code-reviewer → security-auditor`
- Reserved-name guard prevents shadowing of base agents

See [`DELEGATION-RULE-SPECIALISTS.md`](DELEGATION-RULE-SPECIALISTS.md) for the full creation contract, sanitization rules, promotion path (project-local → user-global), and fleet maintenance.

## Layer 3 — Runtime enforcement (PreToolUse hook)

`hooks/delegation-guard.sh` registered in `hooks/hooks.json` with matcher `Write|Edit|MultiEdit|NotebookEdit`. Behavior:

- Subagent detection: requires non-empty `agent_id` AND `hook_event_name == "PreToolUse"` in stdin JSON. Subagents bypass the path check; their tool scope is enforced by their own frontmatter.
- Whitelist for the main agent: `specs/`, `docs/`, `.claude/commands/`, `.claude/CLAUDE.md`, `CLAUDE.md`, `AGENTS.md`, `MEMORY.md`, `memory/`, `build-log.md`, `lessons-learned.md`.
- Blocklist (kill-switches, even within `.claude/`): `.claude/settings*.json`, `.claude/hooks/`, `.claude/agents/`. The hook cannot be disabled by the main editing one Edit away.
- Path-traversal guard: matches `..` only as a path segment.
- Defensive Windows backslash normalization for Git Bash compatibility.
- Fail-soft on missing `jq` (warns to stderr, allows). Operator install hint provided.
- Output protocol: `exit 0` allows; `exit 2` blocks with stderr message. No legacy JSON `decision: block` shape.

See [`adr/0003-plugin-level-hook-vs-permissions-deny.md`](adr/0003-plugin-level-hook-vs-permissions-deny.md) for why a hook and not the `permissions.deny` system.

## Layer 4 — Audit chain (sequential, blocking)

After the implementer (or specialist) writes code:

```
GATE 1: test-engineer       → AUDIT RESULT: APPROVED | BLOCKED
GATE 2: code-reviewer       → AUDIT RESULT: APPROVED | BLOCKED
GATE 3: security-auditor    → AUDIT RESULT: APPROVED | BLOCKED  (default-on; skip allowlist in DELEGATION-RULE.md)
```

Sequential, not parallel — each gate reads the previous one's output. The main agent does NOT close a task until all applicable gates return APPROVED. A BLOCKED verdict reopens the cycle with the auditor's report attached. See [`adr/0004-audit-chain-sequential-not-parallel.md`](adr/0004-audit-chain-sequential-not-parallel.md) for the rationale.

The contract is documented in [`DELEGATION-RULE.md`](DELEGATION-RULE.md) including the GATE 3 skip allowlist (4 narrow conditions, exhaustive) and the anti-rationalization table for the main.

## Layer 5 — Documentation graph (this layer)

The doc graph mirrors the four-quadrant model of the industry consensus:

| Question | Project-wide | Feature-scoped |
|---|---|---|
| Why (vision/metrics) | `docs/PRD.md` | `docs/features/<feature>/PRD.md` (when warranted; not yet present) |
| What/how (architecture) | `docs/SPEC.md` (this file) | `docs/<feature>.md`, `skills/<skill>/SKILL.md` |
| Why-this-how (decisions) | `docs/adr/NNNN-*.md` | (rare; major decisions promote up) |
| How-we-work (rules) | `CLAUDE.md` | `src/<feature>/CLAUDE.md` |

Plans and session journals augment this:

- `docs/plans/active/<date>-<slug>.md` — exactly one active plan per feature branch
- `docs/plans/archive/<date>-<slug>.md` — completed plans (moved at PR merge)
- `docs/sessions/<date>-<slug>.md` — session journal with `Context | Decisions | Changes | Next` sections; the `Next` line is the entry point for the next session

See `CLAUDE.md` section "Session-handoff protocol" for how the operator and the main agent interact with these files.

## Skills (invocable workflows)

The plugin ships skills organized by development phase. Each skill has a `SKILL.md` in `skills/<name>/`. Phases:

| Phase | Skills |
|---|---|
| Define | `idea-refine`, `spec-driven-development` |
| Plan | `planning-and-task-breakdown` |
| Build | `incremental-implementation`, `test-driven-development`, `context-engineering`, `source-driven-development`, `frontend-ui-engineering`, `api-and-interface-design` |
| Verify | `browser-testing-with-devtools`, `debugging-and-error-recovery` |
| Review | `code-review-and-quality`, `code-simplification`, `security-and-hardening`, `performance-optimization` |
| Ship | `git-workflow-and-versioning`, `ci-cd-and-automation`, `deprecation-and-migration`, `documentation-and-adrs`, `shipping-and-launch` |
| Meta (Batuta-specific) | `batuta-project-hygiene`, `batuta-skill-authoring`, `batuta-agent-authoring`, `research-first-dev`, `notion-kb-workflow`, `using-agent-skills` |

Each skill is auto-discoverable via the `using-agent-skills` flowchart. The Batuta-specific meta-skills are mandatory triggers documented in `CLAUDE.md`.

## Cross-cutting constraints

- All agent files ≤ 150 lines (enforced via `batuta-agent-authoring`).
- All description fields ≤ 150 characters.
- All artifacts in English; conversation in Spanish (operator preference).
- No `Co-Authored-By: Claude` in commits.
- Plugin operates only on Claude Code's native primitives (hooks, agents, skills, slash commands). No external services for core enforcement.
- Windows + Git Bash compatibility: paths normalized at every boundary.

## What this plugin does NOT do

- Does not redefine `permissions.allow`/`deny`. Those remain the operator's domain.
- Does not auto-merge PRs. The operator merges manually after review.
- Does not run on systems without Claude Code 1.x.
- Does not provide UI surfacing of metrics. Metrics are observed via Anthropic billing + transcript inspection.

For the historical and motivational backing of these constraints, see [`PRD.md`](PRD.md). For each major decision and the alternatives rejected, see [`adr/`](adr/).
