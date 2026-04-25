---
name: autonomous-code-improvement
description: Drives unattended code-improvement passes through a multi-gate pipeline — scan, isolate, execute, self-review, adversarial check, domain guard, PR. Use when running an autonomous loop that opens PRs without a human in the loop, when you need to bound LLM spend per task, or when the codebase has zones that require human domain expertise the agent must not fabricate.
---

# Autonomous Code Improvement

## Overview

Autonomous coding agents fail in three predictable ways: they guess when they hit domain-specific code, they have no cost controls, and they let the model that wrote the change confirm the change is good. This skill defines the discipline that prevents all three. Every change goes through a pipeline of orthogonal gates — none of which the executing model can override on its own.

A reference TypeScript implementation lives at [asil-monorepo](https://github.com/dusan-milicevic/asil) (pending publish). This skill is the *process* — apply the gates regardless of language or framework.

## When to Use

- Running a recurring autonomous loop that opens PRs unattended (a "grind" pass)
- Building an agent that operates on a codebase without a synchronous human reviewer
- Wrapping any LLM-driven code generator that needs cost ceilings
- Operating on code that has domain-specific business rules an agent could plausibly fabricate
- Any agent design where you'd otherwise be tempted to skip review because the agent already "knows what it's doing"

**When NOT to use:**

- One-shot synchronous edits where a human is reading every diff before merge
- Pure refactoring tasks with strong existing test coverage and no new behavior
- Tasks fully covered by `incremental-implementation` and `test-driven-development` with a human at the keyboard

**Related:** Combine with `code-review-and-quality` (the persona prompts), `security-and-hardening` (the security auditor persona), and `git-workflow-and-versioning` (worktree isolation discipline).

## The Pipeline

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐
│   Scan   │─▶│ Triage   │─▶│ Isolate  │─▶│   Execute    │
│ codebase │  │ domain Q │  │ worktree │  │  LLM patch   │
└──────────┘  └──────────┘  └──────────┘  └──────┬───────┘
                                                 │
                  ┌──────────────────────────────▼──────┐
                  │ typecheck + tests in worktree       │
                  └──────────────────────────────┬──────┘
                                                 │
        ┌────────────────────────────────────────▼─────────────┐
        │  Self-review (3 personas, scoped to diff only):      │
        │   1. code reviewer    2. security    3. test-engineer │
        └────────────────────────────────────────┬─────────────┘
                                                 │
                  ┌──────────────────────────────▼──────┐
                  │ Adversarial gate                     │
                  │ — different LLM, different provider  │
                  │ — challenges the work cold           │
                  └──────────────────────────────┬──────┘
                                                 │
                  ┌──────────────────────────────▼──────┐
                  │ Domain guard                         │
                  │ — touches a DOMAIN_QUESTION zone?    │
                  │ — block until human triages          │
                  └──────────────────────────────┬──────┘
                                                 │
                                     ┌───────────▼────────┐
                                     │  Open PR           │
                                     │  (only if all gates │
                                     │   passed)          │
                                     └────────────────────┘
```

Every node is an independent veto. Any gate can return the task to the queue or kill it outright.

### Step 1: SCAN — Find candidate work

Pick categories your codebase produces signal on:

- Test failures (failing tests are a clear contract)
- Type errors (the compiler already disagrees)
- TODO resolution (text the maintainer left behind)
- Dead code (export-graph reachability)
- Coverage gaps (untested branches in changed files)

Don't scan for "things that could be better" — that's an unbounded category and the loop will churn. Stick to categories where ground truth exists.

### Step 2: TRIAGE — Pause on domain questions

Sprinkle `// DOMAIN_QUESTION: <one-line question>` markers in code paths where business rules live. Before any task runs, the loop must check whether the diff would touch a marker that has no resolved answer. If yes — **stop**, present the question to a human, persist the answer, and only then proceed.

The point: the agent must not invent a domain answer to keep going.

### Step 3: ISOLATE — One disposable worktree per task

```
git worktree add /tmp/<task-id> <branch>      # primary path
git clone <repo> /tmp/<task-id> && checkout   # fallback for FUSE/Drive
```

The main checkout is read-only from the loop's perspective. If a task fails halfway, the worktree gets deleted and the task is requeued — not retried in place.

### Step 4: EXECUTE — LLM-generated patch, applied programmatically

Send a scoped prompt that includes: the relevant skill markdown, project rules (configurable), the failing signal, and the file contents. Have the LLM emit complete file contents in `<<<FILE: path>>> … <<<END FILE>>>` blocks (NOT a unified diff — the model misreads line numbers).

Compute the diff yourself (`diff -u`), validate with `git apply --check`, then apply.

### Step 5: TYPECHECK + TESTS — In the worktree, on the patched code

`pnpm typecheck` and `pnpm test` (or your equivalent). Failure here returns the task to the queue with a `tests-failing` reason. Do not have the same model "fix the test" — it'll rationalize. Either let a different model try (next pass) or escalate.

### Step 6: SELF-REVIEW — Three personas, diff only

Run three independent review passes:

1. **Code reviewer** — diff hygiene, naming, consistency, dead code introduced
2. **Security auditor** — input validation, secrets, authz/authn, injection vectors
3. **Test engineer** — test depth, edge cases, real assertions vs. `toBeDefined()`

Each persona gets the diff and **only** the diff. No surrounding code. No prior context. Each can return `pass`, `concerns`, or `blocker`. Blockers stop the task. Concerns are logged on the PR.

### Step 7: ADVERSARIAL GATE — Different LLM, different provider

Send the diff to a model from a *different family* (e.g., OpenAI when the writer was Anthropic, or vice versa) with the prompt: "Try to break this. Find a reason it should NOT merge." Different families fail differently — what one family rationalizes the other often catches.

### Step 8: DOMAIN GUARD — Final check

Re-scan the diff for `DOMAIN_QUESTION` markers in any file the diff touches. If any such marker exists with no resolved answer, block the PR and surface to a human. This is the redundancy layer — Step 2 already triaged at queue time, but new markers can appear during execution.

### Step 9: OPEN PR — Only if every gate passed

The PR description includes: the original signal, the personas' notes, the adversarial gate's result, and the cost spent on this task.

## Cost Discipline

Every LLM call passes through a checkpoint bound to `(taskId, systemId, agentId)`:

```
checkpoint.recordAndCheck(inputTokens, outputTokens, model)
```

The checkpoint refuses the call if the task budget, the daily cap, or the kill switch threshold is breached. Spend is persisted to disk per task — reports and audits work after the fact.

Use `decimal.js` (or your language's exact-decimal type) for every cost number. Float drift on currency is a real bug.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Three reviews is overkill — the writer's review is fine" | The writer's review IS theater. Different personas catch different classes of bug. The adversarial gate especially. |
| "We can just trust the LLM on the domain logic" | This is exactly how silent regressions ship. The DOMAIN_QUESTION marker is cheap insurance. |
| "I'll add cost controls later" | "Later" is after a $200 spike. Costs compound silently — the kill switch must exist on day one. |
| "Worktree isolation is too much ceremony" | Until a half-applied patch corrupts your main checkout. Disposable worktrees ARE the ceremony — they save you. |
| "The adversarial gate keeps rejecting things, let me lower its threshold" | The gate has a real point. Lower thresholds correlate with regressions. Fix the underlying signal. |
| "Skip the gates for trivial diffs" | "Trivial" diffs ship the most regressions because nobody read them carefully. |
| "I'll have the same model self-review faster" | Same model, same blind spots. Cross-family review is non-optional. |
| "We don't need worktree isolation, the loop won't touch other files" | Until the LLM emits a file path that escapes scope. Isolation is a guarantee, not a hope. |

## Red Flags

- Pipeline that has the same model write the code and review the code
- No cost ceiling — task can run as long as the LLM stays in context
- No DOMAIN_QUESTION mechanism (or equivalent) for unknown business rules
- Patches applied to main checkout, not a worktree
- Self-review runs on the entire codebase, not just the diff
- Adversarial gate uses the same model family as the writer
- "All gates pass" announced before any gate has actually run
- Task is retried in place after a failure instead of being rolled back to a clean worktree
- Diff format requires the LLM to compute line numbers (it will hallucinate them)
- Domain answers stored only in conversation context — must be persisted to survive across runs

## Verification

Before considering an autonomous loop production-ready:

- [ ] A failing scan category short-circuits the run with a clear reason
- [ ] At least one DOMAIN_QUESTION marker has been triaged end-to-end (question presented, answer persisted, dependent file unblocked)
- [ ] The adversarial gate has rejected at least one task in dogfooding — if it never rejects anything, it's not actually challenging the writer
- [ ] The kill switch has been tested by setting an artificially low budget and confirming the loop stops mid-task
- [ ] A worktree creation failure (e.g., simulated disk full) results in the task being marked failed and the loop continuing — no main-checkout corruption
- [ ] Cost reports correctly attribute spend to `(taskId, systemId, agentId)` triples — not a single bucket
- [ ] PRs opened by the loop have a body that includes: the original signal, the persona notes, the adversarial result, and the task cost

## Reference Implementation

A working TypeScript reference is available as a four-package monorepo: [asil-monorepo](https://github.com/dusan-milicevic/asil). It implements every node of the pipeline described above:

- `asil-cost-controller` — token budget governor, checkpoints, kill switch
- `asil-thought-multiplier` — strategic thinking layer (router, thinkers, synthesizer, papa)
- `asil-improvement-loop` — the pipeline itself (scanner, executor, self-review, gates)
- `asil-runners` — Anthropic + OpenAI wirings, CLI entry points

Adopt the reference verbatim or extract the pieces you need. The interfaces (`LLMCaller`, `LoopDeps`) are deliberately tiny so providers and dependencies can be swapped.
