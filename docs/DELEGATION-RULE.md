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

See [DELEGATION-RULE-SPECIALISTS.md](DELEGATION-RULE-SPECIALISTS.md) for the dynamic specialist creation flow that extends this rule.
