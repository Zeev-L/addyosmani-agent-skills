# DELEGATION-RULE.md — Regla #0

> The main agent is the architect, not the implementer. This document defines the contract that keeps it that way.

## The rule

**The main agent NEVER writes code directly.** Every implementation, every test, every audit goes through a `Task` invocation to a subagent whose `model:` field is declared explicitly in its frontmatter.

The main agent's window is reserved for architectural conversation — refining ideas, writing specs, breaking down work, choosing between approaches, and coordinating the audit chain. Implementation work runs in subagent windows where it does not pollute the main's context and where each subagent runs at the lowest model tier that fits the task.

## Why this matters

When the main agent runs Opus 4.7 and writes code itself:

1. Every implementation token costs Opus pricing — typically 5× to 15× more than Sonnet for the same output quality on routine code work.
2. The main's context window fills with file contents, test output, and error traces, leaving no room for the architectural deliberation that actually justifies running Opus.
3. Subagents that the main does invoke inherit Opus by default unless `model:` is declared in their frontmatter — so even delegation does not help if the chain is not built correctly.

The combined effect: a main session that should have been an architectural review consumes a working day of premium tokens on routine implementation. This is the failure mode this rule prevents.

## The mandatory chain

Every non-trivial slice flows through this sequence. Each step blocks the next; if a gate fails, the cycle reopens at the implementation step with the auditor's findings.

```
main agent
  ├── /spec                              (defines what)
  ├── /plan                              (decomposes into tasks)
  ├── Task → agent-architect             (only if a domain specialist is needed and not yet created — see DELEGATION-RULE-SPECIALISTS.md)
  ├── Task → implementer | <specialist>  (executes the slice)
  ├── Task → test-engineer               (GATE 1: tests must pass)
  ├── Task → code-reviewer               (GATE 2: review must approve)
  ├── Task → security-auditor            (GATE 3: audit must approve. Default-on. Skippable ONLY for slices on the explicit allowlist below.)
  ├── main consolidates results and writes lessons-learned.md
  └── ship
```

### Closing rule (non-negotiable)

The main agent does NOT mark a task as complete until gates 1, 2, and 3 have returned `AUDIT RESULT: APPROVED`. If any gate returns `AUDIT RESULT: BLOCKED`, the main reopens the cycle by re-invoking the implementer or specialist with the auditor's report attached. Audits are sequential — each agent reads the output of the previous one. Parallel auditing is forbidden because reviewers need to see what tests passed and security needs to see what review accepted.

A task closed without three APPROVED verdicts is a violation of this rule and must be reopened.

### Audit chain scope (when the chain runs vs. when it does not)

The chain is **post-implementation**. It exists to validate that code produced by `implementer`, `implementer-haiku`, or a specialist meets the project's quality and security bar before merging. It does **not** apply to exploration, planning, conversation, or any phase that does not produce code.

**The chain runs when:**

| Phase | Why the chain applies |
|---|---|
| `implementer` returns staged code changes | New or modified source needs review, tests, and security scan before merge. |
| `implementer-haiku` returns trivial changes | Even trivial changes (CSS, version bump, copy edit) can introduce regressions or supply-chain risk; the chain runs but auditors typically pass quickly. |
| A specialist returns staged code changes | Specialists are subject to the same gates as the generic implementer. Domain knowledge is not a license to skip review. |
| A docs-only slice modifies `agents/`, `skills/`, `hooks/`, or any agent/skill prompt | Agent definitions are runtime contracts — code-reviewer evaluates clarity and distinctness; security-auditor checks for prompt-injection surface. |

**The chain does NOT run when:**

| Phase | Why the chain does not apply |
|---|---|
| Exploration / research / discovery | No code is produced. Reading files, running `git log`, asking questions, browsing the codebase — there is nothing to audit. |
| Planning / spec-writing / ADR drafting | Outputs are docs, captured in `docs/plans/active/` and `docs/adr/`. The audit chain is for code; doc reviews happen at PR time by the operator. |
| Ad-hoc database queries / data analysis | A specialist running read-only SQL or analyzing a parquet file produces a report, not a diff. No code to review. |
| Conversation with the operator | Architectural deliberation, scope negotiation, tradeoff discussion — pure dialogue, no diff. |
| Pre-flight BLOCKERs from a subagent | If the implementer or a specialist returns BLOCKER (missing skeleton, missing dep, contradictory spec), the chain does NOT run. The main resolves the BLOCKER and re-delegates; the chain runs on the *next* return that produces a diff. |

**Rule of thumb:** if `git diff --staged --stat` and `git diff HEAD --stat` both report zero changes after the subagent returns, the chain is not applicable. Skip directly to "main consolidates results" or to the next conversation turn.

**Runtime defense.** Each auditor (`code-reviewer`, `test-engineer`, `security-auditor`) runs a Step 0 pre-flight at the top of its workflow that checks for staged or unstaged diff. If both are empty, the auditor returns `AUDIT RESULT: NOT APPLICABLE — no code diff to audit; the audit chain runs only after an implementation slice produces changes` and stops. This stops the main from accidentally firing the chain mid-exploration.

**Anti-rationalization for the main agent:**

| Excuse | Reality |
|---|---|
| "We just had a long conversation, let's run the audit chain to be safe" | The chain has nothing to audit if no code changed. Running it produces no value and burns Sonnet tokens. |
| "The specialist did some analysis, audit it just in case" | If the specialist produced a markdown report (no diff), there is nothing for `code-reviewer` to read. Audit the report content yourself or in conversation; the chain doesn't apply. |
| "The plan changed mid-session, run security on the new plan" | Plans are docs. Security review of a plan is the operator's job at PR time, not the security-auditor agent's. |

### GATE 3 skip allowlist

GATE 3 (security-auditor) is default-on. The main may skip it ONLY when ALL of the following hold:

- The slice modifies only files under `docs/`, `README*`, `*.md` outside `agents/` and `skills/`
- No code, no configuration, no dependency manifest, no agent definition, no hook is touched
- No environment variable or secret reference is added or changed

If even one condition fails, GATE 3 runs. The main does not self-judge "low risk" — the allowlist is exhaustive.

### Anti-rationalization table for the main agent

The main agent will be tempted to skip gates. Reject these excuses:

| Excuse | Reality |
|---|---|
| "The change is docs-only, audit is overkill" | Check the GATE 3 skip allowlist. If the file is `agents/*.md`, `skills/*.md`, `hooks/*`, or any code, GATE 3 still runs. |
| "Tests already ran inside the implementer, GATE 1 is redundant" | Implementer ran tests against its own implementation; `test-engineer` validates coverage gaps and intent. Different lens. Run it. |
| "This is a hotfix, no time for the full chain" | Hotfixes touching production are exactly when audit-chain skipping causes incidents. Run the chain — Sonnet gates take seconds. |
| "Security has already reviewed this pattern before" | Reviewed the pattern, not this slice's wiring. Run GATE 3. |
| "Reviewer will catch security too, no need for both" | Code-reviewer covers OWASP at a high level; security-auditor goes deeper. They are GATE 2 and GATE 3, not interchangeable. |
| "Audit is documentation-only, no hook will catch me" | Correct, and that is exactly why this rule depends on the main holding the line. The day the rule is violated is the day the hook gets shipped. |

## Roles in one line each

| Agent | Model | Role |
|---|---|---|
| `implementer` | sonnet | Generic builder. Reads spec/plan/tasks, produces code, writes build-log, hands off to audit chain. |
| `agent-architect` | sonnet | Meta-agent. Creates domain specialists on demand with discovery-first. Never implements. |
| `<specialist>` | sonnet (haiku/opus by exception) | Domain expert created by `agent-architect` when a recurring pattern justifies persistence. |
| `test-engineer` | sonnet | GATE 1. Writes or runs tests, reports coverage gaps, blocks on failing tests. |
| `code-reviewer` | sonnet | GATE 2. Five-axis review (correctness, readability, architecture, security, performance). Blocks on Critical findings. |
| `security-auditor` | sonnet | GATE 3. OWASP-grounded vulnerability scan. Blocks on Critical or High findings. |

## What the main agent does directly

Only these:

1. Conversation with the operator (architectural deliberation, scope negotiation, tradeoff discussion)
2. Running `/spec`, `/plan`, and the other planning skills
3. Invoking subagents via `Task`
4. Reading audit reports and deciding whether the gate passed
5. Writing `lessons-learned.md` after the slice closes

Anything else — reading source files in detail, editing code, running test suites, manipulating git history at the file level — goes to a subagent.

## What the main agent does NOT do directly

- Edit or write source files (delegate to `implementer` or a specialist)
- Run test suites against the new code (delegate to `test-engineer`)
- Read the diff line-by-line for review (delegate to `code-reviewer`)
- Hunt for vulnerabilities (delegate to `security-auditor`)
- Search the codebase for patterns when the search will return more than a handful of files (delegate to an Explore subagent or a specialist)

## Enforcement

This rule is currently a documented contract that the main agent reads at session start. If the contract is violated in practice — the main edits a source file directly, or closes a task without invoking the audit chain — the next iteration adds a hook that blocks `Edit`/`Write` from the main agent's tool set, forcing the delegation. For now, the contract is the enforcement.

**Plan-mode persistence:** Claude Code defaults plan-mode plans to `~/.claude/plans/<auto-name>.md` (user-global). This convention requires plans to live at `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md` so they travel with the repo via git and the implementer pre-flight finds them. After exiting plan mode, run `/save-plan <slug>` to copy the plan project-local. ADR-0005 documents why this is operator-invoked (slash command) rather than runtime-automatic (hook on `ExitPlanMode`).

See [DELEGATION-RULE-SPECIALISTS.md](DELEGATION-RULE-SPECIALISTS.md) for the dynamic specialist creation flow that extends this rule.
