# Agent Skills

**Production-grade engineering skills for AI coding agents.**

Skills encode the workflows, quality gates, and best practices that senior engineers use when building software. These ones are packaged so AI agents follow them consistently across every phase of development.

```
  DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │ Idea │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
  /spec          /plan          /build        /test         /review       /ship
```

---

## Commands

7 slash commands that map to the development lifecycle. Each one activates the right skills automatically.

| What you're doing | Command | Key principle |
|-------------------|---------|---------------|
| Define what to build | `/spec` | Spec before code |
| Plan how to build it | `/plan` | Small, atomic tasks |
| Build incrementally | `/build` | One slice at a time |
| Prove it works | `/test` | Tests are proof |
| Review before merge | `/review` | Improve code health |
| Simplify the code | `/code-simplify` | Clarity over cleverness |
| Ship to production | `/ship` | Faster is safer |

Skills also activate automatically based on what you're doing — designing an API triggers `api-and-interface-design`, building UI triggers `frontend-ui-engineering`, and so on.

---

## Quick Start

<details>
<summary><b>Claude Code (recommended)</b></summary>

**Marketplace install:**

```
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

> **SSH errors?** The marketplace clones repos via SSH. If you don't have SSH keys set up on GitHub, either [add your SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) or use the full HTTPS URL to force the HTTPS cloning:
> ```bash
> /plugin marketplace add https://github.com/addyosmani/agent-skills.git
> /plugin install agent-skills@addy-agent-skills
> ```

**Local / development:**

```bash
git clone https://github.com/addyosmani/agent-skills.git
claude --plugin-dir /path/to/agent-skills
```

</details>

<details>
<summary><b>Cursor</b></summary>

Copy any `SKILL.md` into `.cursor/rules/`, or reference the full `skills/` directory. See [docs/cursor-setup.md](docs/cursor-setup.md).

</details>

<details>
<summary><b>Gemini CLI</b></summary>

Install as native skills for auto-discovery, or add to `GEMINI.md` for persistent context. See [docs/gemini-cli-setup.md](docs/gemini-cli-setup.md).

**Install from the repo:**

```bash
gemini skills install https://github.com/addyosmani/agent-skills.git --path skills
```

**Install from a local clone:**

```bash
gemini skills install ./agent-skills/skills/
```

</details>

<details>
<summary><b>Windsurf</b></summary>

Add skill contents to your Windsurf rules configuration. See [docs/windsurf-setup.md](docs/windsurf-setup.md).

</details>

<details>
<summary><b>OpenCode</b></summary>

Uses agent-driven skill execution via AGENTS.md and the `skill` tool.

See [docs/opencode-setup.md](docs/opencode-setup.md).

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

Use agent definitions from `agents/` as Copilot personas and skill content in `.github/copilot-instructions.md`. See [docs/copilot-setup.md](docs/copilot-setup.md).

</details>

<details>
  <summary><b>Kiro IDE & CLI </b></summary>
  Skills for Kiro reside under ".kiro/skills/" and can be stored under Project or Global level. Kiro also supports Agents.md. See Kiro docs at https://kiro.dev/docs/skills/
</details>

<details>
<summary><b>Codex / Other Agents</b></summary>

Skills are plain Markdown - they work with any agent that accepts system prompts or instruction files. See [docs/getting-started.md](docs/getting-started.md).

</details>



---

## All 21 Skills

The commands above are entry points. The pack includes 21 skills total — each a structured workflow with steps, verification gates, and anti-rationalization tables. You can also reference any skill directly.

### Meta - Discover which skill applies

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [using-agent-skills](skills/using-agent-skills/SKILL.md) | Maps incoming work to the right skill workflow and defines shared operating rules | Starting a session or deciding which skill applies |

### Define - Clarify what to build

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [idea-refine](skills/idea-refine/SKILL.md) | Structured divergent/convergent thinking to turn vague ideas into concrete proposals | You have a rough concept that needs exploration |
| [spec-driven-development](skills/spec-driven-development/SKILL.md) | Write a PRD covering objectives, commands, structure, code style, testing, and boundaries before any code | Starting a new project, feature, or significant change |

### Plan - Break it down

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [planning-and-task-breakdown](skills/planning-and-task-breakdown/SKILL.md) | Decompose specs into small, verifiable tasks with acceptance criteria and dependency ordering | You have a spec and need implementable units |

### Build - Write the code

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [incremental-implementation](skills/incremental-implementation/SKILL.md) | Thin vertical slices - implement, test, verify, commit. Feature flags, safe defaults, rollback-friendly changes | Any change touching more than one file |
| [test-driven-development](skills/test-driven-development/SKILL.md) | Red-Green-Refactor, test pyramid (80/15/5), test sizes, DAMP over DRY, Beyonce Rule, browser testing | Implementing logic, fixing bugs, or changing behavior |
| [context-engineering](skills/context-engineering/SKILL.md) | Feed agents the right information at the right time - rules files, context packing, MCP integrations | Starting a session, switching tasks, or when output quality drops |
| [source-driven-development](skills/source-driven-development/SKILL.md) | Ground every framework decision in official documentation - verify, cite sources, flag what's unverified | You want authoritative, source-cited code for any framework or library |
| [doubt-driven-development](skills/doubt-driven-development/SKILL.md) | Adversarial fresh-context review of every non-trivial decision in-flight - CLAIM → EXTRACT → DOUBT → RECONCILE → STOP, with optional user-authorized cross-model escalation | Stakes are high (production, security, irreversible), working in unfamiliar code, or a confident output is cheaper to verify now than to debug later |
| [frontend-ui-engineering](skills/frontend-ui-engineering/SKILL.md) | Component architecture, design systems, state management, responsive design, WCAG 2.1 AA accessibility | Building or modifying user-facing interfaces |
| [api-and-interface-design](skills/api-and-interface-design/SKILL.md) | Contract-first design, Hyrum's Law, One-Version Rule, error semantics, boundary validation | Designing APIs, module boundaries, or public interfaces |

### Verify - Prove it works

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [browser-testing-with-devtools](skills/browser-testing-with-devtools/SKILL.md) | Chrome DevTools MCP for live runtime data - DOM inspection, console logs, network traces, performance profiling | Building or debugging anything that runs in a browser |
| [debugging-and-error-recovery](skills/debugging-and-error-recovery/SKILL.md) | Five-step triage: reproduce, localize, reduce, fix, guard. Stop-the-line rule, safe fallbacks | Tests fail, builds break, or behavior is unexpected |

### Review - Quality gates before merge

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [code-review-and-quality](skills/code-review-and-quality/SKILL.md) | Five-axis review, change sizing (~100 lines), severity labels (Nit/Optional/FYI), review speed norms, splitting strategies | Before merging any change |
| [code-simplification](skills/code-simplification/SKILL.md) | Chesterton's Fence, Rule of 500, reduce complexity while preserving exact behavior | Code works but is harder to read or maintain than it should be |
| [security-and-hardening](skills/security-and-hardening/SKILL.md) | OWASP Top 10 prevention, auth patterns, secrets management, dependency auditing, three-tier boundary system | Handling user input, auth, data storage, or external integrations |
| [performance-optimization](skills/performance-optimization/SKILL.md) | Measure-first approach - Core Web Vitals targets, profiling workflows, bundle analysis, anti-pattern detection | Performance requirements exist or you suspect regressions |

### Ship - Deploy with confidence

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [git-workflow-and-versioning](skills/git-workflow-and-versioning/SKILL.md) | Trunk-based development, atomic commits, change sizing (~100 lines), the commit-as-save-point pattern | Making any code change (always) |
| [ci-cd-and-automation](skills/ci-cd-and-automation/SKILL.md) | Shift Left, Faster is Safer, feature flags, quality gate pipelines, failure feedback loops | Setting up or modifying build and deploy pipelines |
| [deprecation-and-migration](skills/deprecation-and-migration/SKILL.md) | Code-as-liability mindset, compulsory vs advisory deprecation, migration patterns, zombie code removal | Removing old systems, migrating users, or sunsetting features |
| [documentation-and-adrs](skills/documentation-and-adrs/SKILL.md) | Architecture Decision Records, API docs, inline documentation standards - document the *why* | Making architectural decisions, changing APIs, or shipping features |
| [shipping-and-launch](skills/shipping-and-launch/SKILL.md) | Pre-launch checklists, feature flag lifecycle, staged rollouts, rollback procedures, monitoring setup | Preparing to deploy to production |

---

## Agent Personas

Pre-configured specialist personas for targeted reviews:

| Agent | Role | Perspective |
|-------|------|-------------|
| [code-reviewer](agents/code-reviewer.md) | Senior Staff Engineer | Five-axis code review with "would a staff engineer approve this?" standard |
| [test-engineer](agents/test-engineer.md) | QA Specialist | Test strategy, coverage analysis, and the Prove-It pattern |
| [security-auditor](agents/security-auditor.md) | Security Engineer | Vulnerability detection, threat modeling, OWASP assessment |

---

## Reference Checklists

Quick-reference material that skills pull in when needed:

| Reference | Covers |
|-----------|--------|
| [testing-patterns.md](references/testing-patterns.md) | Test structure, naming, mocking, React/API/E2E examples, anti-patterns |
| [security-checklist.md](references/security-checklist.md) | Pre-commit checks, auth, input validation, headers, CORS, OWASP Top 10 |
| [performance-checklist.md](references/performance-checklist.md) | Core Web Vitals targets, frontend/backend checklists, measurement commands |
| [accessibility-checklist.md](references/accessibility-checklist.md) | Keyboard nav, screen readers, visual design, ARIA, testing tools |

---

## How Skills Work

Every skill follows a consistent anatomy:

```
┌─────────────────────────────────────────────────┐
│  SKILL.md                                       │
│                                                 │
│  ┌─ Frontmatter ─────────────────────────────┐  │
│  │ name: lowercase-hyphen-name               │  │
│  │ description: Guides agents through [task].│  │
│  │              Use when…                    │  │
│  └───────────────────────────────────────────┘  │                                                                                                
│  Overview         → What this skill does        │
│  When to Use      → Triggering conditions       │
│  Process          → Step-by-step workflow       │
│  Rationalizations → Excuses + rebuttals         │
│  Red Flags        → Signs something's wrong     │
│  Verification     → Evidence requirements       │
└─────────────────────────────────────────────────┘
```

**Key design choices:**

- **Process, not prose.** Skills are workflows agents follow, not reference docs they read. Each has steps, checkpoints, and exit criteria.
- **Anti-rationalization.** Every skill includes a table of common excuses agents use to skip steps (e.g., "I'll add tests later") with documented counter-arguments.
- **Verification is non-negotiable.** Every skill ends with evidence requirements - tests passing, build output, runtime data. "Seems right" is never sufficient.
- **Progressive disclosure.** The `SKILL.md` is the entry point. Supporting references load only when needed, keeping token usage minimal.

---

## Project Structure

```
agent-skills/
├── skills/                            # 21 core skills (SKILL.md per directory)
│   ├── idea-refine/                   #   Define
│   ├── spec-driven-development/       #   Define
│   ├── planning-and-task-breakdown/   #   Plan
│   ├── incremental-implementation/    #   Build
│   ├── context-engineering/           #   Build
│   ├── source-driven-development/     #   Build
│   ├── doubt-driven-development/      #   Build
│   ├── frontend-ui-engineering/       #   Build
│   ├── test-driven-development/       #   Build
│   ├── api-and-interface-design/      #   Build
│   ├── browser-testing-with-devtools/ #   Verify
│   ├── debugging-and-error-recovery/  #   Verify
│   ├── code-review-and-quality/       #   Review
│   ├── code-simplification/          #   Review
│   ├── security-and-hardening/        #   Review
│   ├── performance-optimization/      #   Review
│   ├── git-workflow-and-versioning/   #   Ship
│   ├── ci-cd-and-automation/          #   Ship
│   ├── deprecation-and-migration/     #   Ship
│   ├── documentation-and-adrs/        #   Ship
│   ├── shipping-and-launch/           #   Ship
│   └── using-agent-skills/            #   Meta: how to use this pack
├── agents/                            # 3 specialist personas
├── references/                        # 4 supplementary checklists
├── hooks/                             # Session lifecycle hooks
├── .claude/commands/                  # 7 slash commands (Claude Code)
├── .gemini/commands/                  # 7 slash commands (Gemini CLI)
└── docs/                              # Setup guides per tool
```

---
name: prompt-engineering
description: >
  Craft reliable, maintainable prompts for LLM-powered features inside your
  codebase. Covers system prompt design, few-shot examples, output contracts,
  hallucination guards, token budgeting, and prompt versioning.
  Use when building any feature that calls an LLM, or when AI output quality
  is inconsistent or unreliable.
---

# Prompt Engineering

## Overview

Prompts are code. They have inputs, outputs, failure modes, and need versioning.
This skill treats prompt authoring with the same rigour as any other engineering
discipline: define the contract first, test against it, and gate changes on
measurable quality metrics.

## When to Use

- Adding a new LLM call to a feature
- AI output is inconsistent, hallucinating, or off-format
- Upgrading or swapping the underlying model
- Reviewing an AI-powered feature before merge
- Writing a system prompt for an agent or assistant

## Process

### Step 1 — Define the output contract before writing any prompt

Answer these before touching the prompt text:

- What is the exact output format? (JSON schema, markdown, plain text, structured XML)
- What are the hard constraints? (max length, forbidden content, required fields)
- What does a failing output look like vs. a passing one?
- What is the latency budget and token cost ceiling?

Document the contract in a comment block above the prompt constant. If you cannot
define done, stop and clarify requirements.

**Checkpoint:** Output contract written and reviewed. ✓

### Step 2 — Write the system prompt using the ROLE-TASK-FORMAT pattern

```
ROLE:   Who the model is. Be specific. "You are a senior tax attorney" beats "You are a helpful assistant."
TASK:   What the model must do. One job per prompt. Split multi-step work into chained calls.
FORMAT: Exact output structure. Show an example. Do not just describe it.
```

Rules:
- One instruction per sentence. Compound instructions get partially ignored.
- Negative constraints are mandatory: `Do not include explanatory text.` `Never fabricate citations.`
- If the answer might not be in the context, give the model an explicit out: `If you cannot determine X from the provided text, return {"result": null, "reason": "insufficient context"}.`
- Keep system prompts under 800 tokens unless you have a measured reason to exceed this.

**Checkpoint:** System prompt follows ROLE-TASK-FORMAT. Negative constraints present. ✓

### Step 3 — Write few-shot examples for every non-trivial output type

- Minimum 2 examples: one canonical success, one edge case.
- Examples must match the output contract exactly — they are the ground truth.
- Include at least one example where the model should return a null/error result.
- Store examples in a versioned fixture file, not inline in application code.

**Checkpoint:** At least 2 examples written. Edge case covered. ✓

### Step 4 — Add hallucination guards

Every production prompt needs at least one of:

| Guard type | Implementation |
|------------|---------------|
| Grounding | "Answer only using the text provided below." |
| Confidence gate | "If you are not confident, return confidence: low and explain why." |
| Citation requirement | "Every factual claim must cite a line number from the source." |
| Schema validation | Parse and validate the JSON output; reject on schema mismatch. |
| Post-hoc verification | Run a second cheap LLM call to verify the first output. |

**Checkpoint:** At least one hallucination guard implemented and tested. ✓

### Step 5 — Token budget and cost audit

- Count worst-case input tokens: system prompt + max context + examples + user input.
- Ensure output max_tokens is set explicitly — never rely on model defaults.
- If total cost per call exceeds budget, trim: shorten examples first, then system prompt, then context window.
- Log input + output token counts in production.

**Checkpoint:** Token budget calculated. max_tokens set. Logging in place. ✓

### Step 6 — Version and test the prompt

- Store prompts in a dedicated `prompts/` directory as versioned constants, not hardcoded strings.
- Write at least 3 automated eval cases per prompt: happy path, edge case, failure case.
- Pin the model name explicitly (`gpt-4o-2024-05-13` not `gpt-4o`) — model aliases change.
- Add a regression test that runs evals on prompt changes in CI.

**Checkpoint:** Prompt versioned. Evals written. Model pinned. CI gate added. ✓

### Step 7 — Review and simplify

- Read the prompt aloud. If a sentence is ambiguous to you, it is ambiguous to the model.
- Remove every instruction that does not change output behaviour (test by removing it).
- Confirm the prompt still passes all evals after trimming.

**Checkpoint:** Prompt passes all evals after simplification pass. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "The output looks right in testing." | Anecdotal. Run structured evals with pass/fail criteria. |
| "I'll add examples later." | Few-shot examples are the highest ROI prompt improvement. Do it now. |
| "The model is smart, it'll figure out the format." | It won't — not consistently. Specify format explicitly and validate in code. |
| "Pinning the model version is premature." | Unpinned model aliases silently change behaviour on provider upgrades. |
| "We don't need evals for a simple prompt." | Simple prompts break in simple ways that only evals catch. |
| "This prompt works fine." | Works for which inputs? Define the distribution and test against it. |

---

## Red Flags

- Prompt is assembled by string concatenation across multiple files with no single source of truth
- No automated evals — quality is assessed by eyeballing outputs
- `max_tokens` not set, or set to the model maximum as a default
- Model alias used instead of pinned version string
- Output parsing has no error handling for malformed responses
- System prompt exceeds 1,500 tokens with no documented reason
- Different prompt versions in dev and production
- No negative constraints ("do not", "never", "if unknown return…")

---

## Verification

Before shipping any LLM-powered feature:

- [ ] Output contract documented above the prompt
- [ ] ROLE-TASK-FORMAT structure present in system prompt
- [ ] At least 2 few-shot examples including an edge/failure case
- [ ] At least one hallucination guard implemented and exercised by a test
- [ ] Token budget calculated; `max_tokens` set explicitly
- [ ] Model version pinned (not an alias)
- [ ] Automated evals pass in CI
- [ ] Output parsing handles malformed/unexpected responses gracefully
- [ ] Prompt stored in versioned constant, not inline string







---
name: observability-and-monitoring
description: >
  Structured approach to logging, distributed tracing, metrics, and alerting.
  Defines what to instrument, SLO/SLI targets, on-call runbooks, and the
  difference between logs-for-humans vs logs-for-machines.
  Use when shipping any service to production, or when debugging production
  issues takes longer than it should.
---

# Observability and Monitoring

## Overview

Observability is the ability to understand a system's internal state from its
external outputs — logs, metrics, and traces. This skill ensures you instrument
the right things before shipping, not after an incident forces you to.

The three pillars:
- **Logs** — what happened (structured, machine-readable)
- **Metrics** — how much / how often (aggregatable numbers over time)
- **Traces** — where time was spent (distributed request journeys)

## When to Use

- Shipping any service or background job to production
- Debugging production issues that require more than `console.log`
- Onboarding a service to an on-call rotation
- Setting up alerting for a new feature or endpoint
- After a postmortem identifies a visibility gap

## Process

### Step 1 — Define SLIs and SLOs before writing any instrumentation

A Service Level Indicator (SLI) is a quantitative measure of service behaviour.
A Service Level Objective (SLO) is the target for that measure.

Minimum required SLIs for any user-facing service:

| SLI | Suggested SLO |
|-----|---------------|
| Request success rate | ≥ 99.5% over 7d rolling window |
| P99 latency | < 1s for reads, < 3s for writes |
| Availability | ≥ 99.9% uptime |

Define these before instrumentation. If you cannot define success, you cannot
alert on failure.

**Checkpoint:** SLIs defined. SLO targets agreed with stakeholders. ✓

### Step 2 — Instrument logs in structured JSON

Every log line must be machine-parseable. Use structured logging from day one.

Required fields on every log event:
```json
{
  "timestamp": "ISO8601",
  "level": "info|warn|error",
  "service": "service-name",
  "trace_id": "abc123",
  "msg": "human readable summary",
  "...context fields"
}
```

Rules:
- Log at boundaries: request in, response out, external call start/end.
- `ERROR` level for anything requiring human action. `WARN` for recoverable anomalies. `INFO` for normal operations. `DEBUG` off in production by default.
- Never log PII (names, emails, tokens, passwords) — log anonymised identifiers.
- Log errors with stack traces AND the input that caused them.
- Do not use `console.log` in production services — use a structured logger.

**Checkpoint:** Structured JSON logging in place. PII audit done. ✓

### Step 3 — Add metrics for the USE method (Utilisation, Saturation, Errors)

For every resource your service owns or depends on:

| Metric type | Examples |
|------------|----------|
| Utilisation | CPU %, memory %, DB connection pool usage |
| Saturation | Queue depth, thread pool backlog, rate limit headroom |
| Errors | HTTP 5xx rate, DB query error rate, cache miss rate |

For request-handling services, also instrument RED metrics:
- **Rate** — requests per second
- **Errors** — error rate
- **Duration** — latency histogram (P50, P95, P99)

Use histograms for latency, not averages. Averages hide tail latency problems.

**Checkpoint:** USE and RED metrics instrumented. Histograms used for latency. ✓

### Step 4 — Add distributed tracing

Every cross-service request must carry a `trace_id` from entry point to all
downstream calls. Propagate via request headers (W3C `traceparent` standard).

Minimum spans to create:
- Incoming HTTP/gRPC request (root span)
- Every outbound HTTP/gRPC call
- Every database query exceeding 100ms
- Every background job execution

Attach to every span: service name, operation name, outcome (ok/error), duration.

**Checkpoint:** Trace IDs propagated across service boundaries. Key spans created. ✓

### Step 5 — Write alerts that require action, not awareness

Alert = something a human must do right now. Everything else is a dashboard.

Alert rules:
- Alert on symptoms (high error rate, slow P99), not causes (high CPU).
- Every alert must have a documented runbook linked from the alert body.
- Alerts must be actionable within 5 minutes by someone on call.
- Start with a 5-minute burn rate alert on your primary SLO.
- No alert without a clear owner team.

Minimum alert set for any production service:
1. SLO error budget burn rate > 2× for 5 minutes
2. Service down / no healthy instances
3. P99 latency > SLO threshold for 5 minutes
4. Dependency down (critical external services)

**Checkpoint:** Alert rules written. Each links to a runbook. Owner team set. ✓

### Step 6 — Write the runbook

Every alert requires a runbook with:
1. What this alert means
2. Immediate mitigation steps (copy-pasteable commands)
3. How to confirm the issue is resolved
4. Escalation path if mitigation fails
5. Link to the last incident this alert fired for

**Checkpoint:** Runbook exists, linked from alert, tested by someone other than the author. ✓

### Step 7 — Validate in staging before shipping

- Trigger each alert condition artificially and confirm it fires.
- Confirm trace IDs flow end-to-end through a real request in staging.
- Check log output in staging matches expected structure.
- Load test to validate latency metrics appear correctly in dashboards.

**Checkpoint:** All alerts verified to fire in staging. Traces visible. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "We'll add monitoring after launch." | You are on call after launch. Add it before. |
| "The logs are readable, that's enough." | Unstructured logs cannot be queried at scale. |
| "Alerts are too noisy so we ignore them." | Fix the alerts. Ignored alerts are worse than no alerts. |
| "We don't need tracing, it's a simple service." | Simple services call other services. Trace the full path. |
| "Average latency is fine." | P99 is what your worst 1% of users experience. Measure it. |
| "We'll define SLOs when we know more." | Without SLOs, alerting thresholds are arbitrary. Define them now. |

---

## Red Flags

- Logs are unstructured strings (`"Error: " + err.message`)
- PII visible in log output
- Latency tracked as averages only — no histogram/percentiles
- Alerts fire without a linked runbook
- `trace_id` not propagated across service calls
- Metrics are only checked when an incident occurs (no proactive dashboards)
- Alert thresholds set to arbitrary round numbers with no SLO basis
- No one on the team knows which alerts are currently firing

---

## Verification

Before a service goes on-call:

- [ ] SLIs and SLO targets documented and agreed
- [ ] Structured JSON logging in place; PII audit completed
- [ ] USE metrics and RED metrics instrumented for all critical paths
- [ ] Latency tracked as histogram (P50/P95/P99), not average
- [ ] Distributed trace IDs propagated across all service boundaries
- [ ] Minimum 4 production alerts configured (SLO burn, availability, latency, dependency)
- [ ] Every alert has a runbook linked from the alert body
- [ ] Alerts verified to fire in staging under synthetic conditions
- [ ] Dashboard with SLO status, request rate, error rate, and latency visible to team




---
name: error-handling-and-resilience
description: >
  Design services to survive and recover from failure. Covers retry policies,
  exponential backoff, circuit breakers, bulkheads, graceful degradation,
  fallback chains, and error classification.
  Use when calling any external API, queue, or database — anything that can
  fail transiently.
---

# Error Handling and Resilience

## Overview

External failures are not exceptions — they are scheduled events. Every network
call, database query, and third-party API will fail. The question is not if, but
when, and whether your service recovers gracefully or cascades into a broader
outage.

This skill treats failure as a first-class design concern: classify errors before
handling them, bound the blast radius, and ensure every failure mode has a
defined recovery path.

## When to Use

- Implementing any call to an external service, database, or queue
- Designing a new service that has downstream dependencies
- Reviewing existing error handling for correctness and completeness
- After an incident where a transient failure caused cascading problems
- Before enabling a feature for high-traffic production load

## Process

### Step 1 — Classify errors before writing any handling code

Not all errors are equal. Applying the wrong strategy to the wrong error class
causes more damage than the original error.

| Class | Definition | Strategy |
|-------|-----------|----------|
| **Transient** | Temporary, likely to succeed on retry (timeout, 503, network blip) | Retry with backoff |
| **Rate-limited** | Server is healthy but telling you to slow down (429) | Retry with backoff + respect `Retry-After` header |
| **Client error** | Your request is wrong (400, 422, 401) | Do not retry. Fix the request. |
| **Fatal** | Unrecoverable (404 on a required resource, data corruption) | Fail fast. Alert. |
| **Partial** | Some work succeeded, some failed (batch jobs, multi-step writes) | Idempotent retry of failed subset only |

**Checkpoint:** Every error type your code can encounter is classified. ✓

### Step 2 — Implement retry with exponential backoff and jitter

Only retry transient and rate-limited errors. Never retry client errors.

```
base_delay = 100ms
max_delay  = 30s
max_attempts = 5

delay = min(base_delay * 2^attempt, max_delay)
delay = delay + random_jitter(0, delay * 0.1)   # prevents thundering herd
```

Rules:
- Always set a maximum number of attempts. Infinite retry loops cause outages.
- Always set a maximum total timeout, independent of per-attempt timeout.
- Log every retry attempt with attempt number, delay, and error cause.
- Respect `Retry-After` response headers when present — honour the server's signal.
- Retries must be idempotent. If your operation is not idempotent, use an idempotency key.

**Checkpoint:** Retry implemented with backoff, jitter, attempt cap, and total timeout. ✓

### Step 3 — Add circuit breakers for dependencies that can sustain failure

A circuit breaker stops sending requests to a failing dependency, giving it time
to recover and preventing your service from accumulating queued work.

States:
- **Closed** — requests flow normally. Count failures.
- **Open** — dependency is unhealthy. Fail fast; do not send requests. Start timer.
- **Half-open** — timer expired. Send one probe request. If it succeeds, close. If not, reopen.

Threshold guidance (tune to your SLO):
- Open circuit when: error rate > 50% over last 10 requests, or 5 consecutive failures
- Half-open probe after: 10–30 seconds
- Close after: 2 consecutive successful probes

Use existing libraries (resilience4j, cockatiel, go-circuit-breaker) — do not
implement circuit breakers from scratch.

**Checkpoint:** Circuit breaker configured for every non-trivial external dependency. ✓

### Step 4 — Scope blast radius with bulkheads

A bulkhead isolates one dependency's failures from affecting other parts of your
service (named after ship compartments that contain flooding).

Implementation options:
- **Thread pool isolation** — each dependency gets its own thread/connection pool
- **Process isolation** — separate worker process per dependency
- **Rate limiting per caller** — upstream services cannot monopolise shared resources

Minimum: separate connection pools for each downstream service and database.
Never share a single connection pool across dependencies with different SLAs.

**Checkpoint:** Critical dependencies use isolated pools. Pool sizes documented. ✓

### Step 5 — Design fallbacks and graceful degradation

When a dependency is unavailable, the system should degrade gracefully — not fail
completely.

Fallback options (in order of preference):
1. **Cached data** — serve last-known-good response with a staleness indicator
2. **Default / static response** — return a safe, minimal response
3. **Feature flag off** — disable the feature; serve the rest of the page
4. **Partial response** — return what is available; omit the unavailable section
5. **Error with context** — tell the user what is unavailable and why

Design fallbacks at feature design time, not during incidents.

**Checkpoint:** Every dependency has a defined fallback. Fallback tested in staging. ✓

### Step 6 — Handle partial failures in batch operations

Batch operations (processing a list, writing to multiple destinations) must not
be all-or-nothing unless transactionality is explicitly required.

Rules:
- Track success and failure per item, not per batch.
- Return a structured result: `{ succeeded: [...], failed: [...] }`.
- Failed items must be retryable independently — do not re-process succeeded items.
- Use a dead-letter queue for items that exhaust all retries.
- Alert when dead-letter queue depth exceeds a threshold.

**Checkpoint:** Batch operations return per-item results. Dead-letter queue in place. ✓

### Step 7 — Test failure modes explicitly

Resilience code that is not tested is not resilience — it is hope.

Required tests:
- Unit test: correct error class returned for each error type
- Unit test: retry logic fires correct number of times with correct delays
- Integration test: circuit breaker opens and closes under simulated failure
- Integration test: fallback is served when dependency is unavailable
- Chaos test (in staging): kill a dependency mid-request; confirm service degrades gracefully

**Checkpoint:** All failure modes covered by automated tests. Chaos test run in staging. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "We'll add retries later." | The first production timeout will happen before "later." |
| "This call never fails." | Every external call fails. Budget is when, not if. |
| "Circuit breakers are complex." | Use a library. The complexity of a cascading failure is higher. |
| "We just catch all exceptions and log them." | Catching all exceptions masks error classes and prevents correct handling. |
| "The retry loop is fine without a cap." | An uncapped retry loop under load is a self-inflicted DDoS. |
| "We'll test the happy path." | The happy path works. Test the failures — that is where production diverges. |

---

## Red Flags

- `catch (Exception e) { log(e); }` — swallowing errors without action
- Retry loops with no maximum attempt count
- No timeout set on external HTTP calls (default is often infinite)
- Retrying 400/401/404 errors (client errors are not transient)
- Single shared connection pool for all downstream services
- No fallback defined for any external dependency
- Timeouts set to the same value for all dependencies regardless of their SLA
- Batch operations fail entirely on a single item failure
- Error handling code with no automated tests

---

## Verification

Before shipping code with external dependencies:

- [ ] All error types classified: transient, client error, fatal, partial
- [ ] Retries only on transient/rate-limited errors; capped at max attempts + total timeout
- [ ] Backoff uses exponential growth with jitter
- [ ] Circuit breaker configured for each non-trivial downstream dependency
- [ ] Isolated connection/thread pools per dependency (bulkheads)
- [ ] Fallback or graceful degradation defined and tested for each dependency
- [ ] Batch operations return per-item results; dead-letter queue in place
- [ ] Idempotency keys used on retried write operations
- [ ] All failure modes covered by automated tests
- [ ] Chaos test run in staging confirming graceful degradation





---
name: data-modeling-and-schema-design
description: >
  Relational and document schema design, normalization trade-offs, migration
  strategies, index planning, and soft-delete vs hard-delete patterns.
  Treats schema changes as irreversible by default.
  Use when designing a new table or collection, or making any breaking schema
  change on live data.
---

# Data Modeling and Schema Design

## Overview

Schema decisions are the hardest to undo in production. A bad API can be versioned.
A bad schema forces a migration, and migrations on live data with millions of rows
are expensive, risky, and slow. This skill front-loads the design work so that
schema changes are deliberate, reversible where possible, and safe when not.

Core principle: **treat every schema change as if it cannot be rolled back.**

## When to Use

- Designing a new table, collection, or data store
- Adding, removing, or renaming a column or field
- Changing a column's type or nullability
- Adding a foreign key, unique constraint, or index
- Planning a migration on a table with more than 10,000 rows
- Designing the persistence layer for a new feature

## Process

### Step 1 — Model the domain before touching SQL or code

Write out entities, attributes, and relationships in plain language before
opening a migration file.

For each entity ask:
- What uniquely identifies this entity? (candidate keys)
- What attributes belong to this entity vs. a related entity?
- What are the cardinalities? (one-to-one, one-to-many, many-to-many)
- What queries will this data need to serve? (read patterns drive index design)
- How will this data grow? (row count in 1 month, 1 year, 5 years)

Draw an entity-relationship diagram (even informally). Reviewing a diagram takes
minutes. Reviewing a production migration takes hours.

**Checkpoint:** Entities, relationships, and cardinalities documented. ✓

### Step 2 — Apply normalisation to at least 3NF by default

Aim for Third Normal Form (3NF) unless you have a measured performance reason
to denormalise.

| Normal Form | Rule | Violation example |
|-------------|------|------------------|
| 1NF | No repeating groups; atomic values | `tags VARCHAR` storing comma-separated list |
| 2NF | No partial dependencies on composite key | `order_item` storing `customer_name` (depends only on `customer_id`) |
| 3NF | No transitive dependencies | `employee` storing `department_name` alongside `department_id` |

Denormalise only after:
1. A query performance problem is measured (not predicted)
2. Normalised design has been profiled and found to be the bottleneck
3. The denormalisation strategy is documented as an ADR

**Checkpoint:** Schema is 3NF or higher. Any denormalisation is documented with measured justification. ✓

### Step 3 — Design columns with future changes in mind

Rules:
- **Default nullable over NOT NULL** for new columns added to existing tables — NOT NULL with no default requires a table lock on large tables.
- **Never store multiple values in one column** — no comma-separated lists, no JSON blobs hiding relational data.
- **Use explicit types** — `BOOLEAN` not `TINYINT(1)`. `TIMESTAMP WITH TIME ZONE` not `VARCHAR`. `DECIMAL(10,2)` not `FLOAT` for money.
- **Name columns for their meaning** — `created_at` not `ts`. `user_id` not `uid`. `is_active` not `flag`.
- **Reserve `id` for surrogate primary keys** — use `uuid` or `bigserial`. Expose natural keys as unique constraints, not PKs.
- **Include `created_at` and `updated_at`** on every table by default.

**Checkpoint:** Column types, names, and nullability reviewed against these rules. ✓

### Step 4 — Plan indexes against query patterns

Write out every query this table will serve before adding indexes.

Index rules:
- Add an index for every foreign key (most databases do not do this automatically).
- Add a composite index when queries filter on multiple columns together — order matters: highest-selectivity column first.
- Do not index columns with fewer than 10 distinct values (low-selectivity indexes hurt write performance with no read benefit).
- Partial indexes (WHERE clause on the index) for filtered queries on large tables.
- Every unique constraint creates an index — prefer `UNIQUE CONSTRAINT` over a separate unique index.
- Maximum 5 indexes per table as a starting guideline — more than this usually signals denormalisation or query design issues.

**Checkpoint:** Indexes planned against documented query patterns. Each index has a named query it serves. ✓

### Step 5 — Choose an explicit delete strategy

Never delete without a strategy. Options:

| Strategy | When to use | Implementation |
|----------|------------|----------------|
| **Hard delete** | PII, GDPR-required erasure, truly temporary data | `DELETE FROM` — add cascade rules to foreign keys |
| **Soft delete** | Audit trail required, undo needed, references from other tables | `deleted_at TIMESTAMP` column; filter in application layer; add partial index on `WHERE deleted_at IS NULL` |
| **Archive** | Regulatory retention, high-volume operational tables | Move to archive table or cold storage on schedule |
| **Tombstone** | Event-sourced or CDC systems | Insert a deletion event record; never mutate past records |

Soft delete pitfalls to prevent:
- Unique constraints must include `deleted_at` or use a partial unique index on `WHERE deleted_at IS NULL`
- Every query must filter on `deleted_at IS NULL` — enforce via a view or ORM default scope
- Soft-deleted rows that reference still-active records cause phantom FK violations

**Checkpoint:** Delete strategy chosen, documented, and implemented consistently across all queries. ✓

### Step 6 — Write migrations as zero-downtime operations

Every migration must be deployable without taking the application offline.

Safe migration patterns:

| Operation | Safe approach |
|-----------|--------------|
| Add column | Add as nullable with no default. Backfill. Add constraint/default after. |
| Remove column | Phase 1: stop reading/writing. Phase 2: drop. Never in one step. |
| Rename column | Phase 1: add new column. Phase 2: dual-write. Phase 3: backfill. Phase 4: cut over reads. Phase 5: drop old column. |
| Change type | Same phase approach as rename. Never `ALTER COLUMN TYPE` on a populated column in a lock-sensitive table. |
| Add NOT NULL | Add nullable → backfill → add CHECK constraint → add NOT NULL. |
| Add index | Use `CREATE INDEX CONCURRENTLY` (PostgreSQL) or equivalent. Never lock the table. |

**Every migration must be reversible.** Write the down migration before the up migration.
If a migration cannot be reversed, document why and get explicit sign-off.

**Checkpoint:** Migration is zero-downtime safe. Down migration written. Tested on a copy of production data. ✓

### Step 7 — Test the migration on production-scale data

A migration that takes 30 seconds on a 1,000-row test database can take 8 hours
on a 500-million-row production table. Test at production scale before running.

Steps:
1. Restore a recent production backup to a staging environment
2. Run the migration with `EXPLAIN ANALYZE` on affected queries before and after
3. Measure migration duration — if > 30 seconds, re-evaluate strategy
4. Verify the application works correctly against the migrated schema
5. Run the down migration and verify it restores the prior state

**Checkpoint:** Migration tested on production-scale data. Duration measured. Application verified. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "We'll refactor the schema later." | Schema refactors on live data are expensive. Get it right now. |
| "JSON column is flexible." | Flexible means unindexed, unvalidated, and opaque to the query planner. |
| "We don't need soft delete, we'll just be careful." | Being careful is not a database constraint. |
| "I'll add indexes after we see slow queries." | Some missing indexes cannot be added concurrently without planning. Plan indexes at design time. |
| "The migration will be fast." | On 100 rows. Test at production scale before declaring this. |
| "We can't write a down migration for this." | Then you cannot safely deploy this migration. Redesign. |

---

## Red Flags

- `data TEXT` or `payload JSON` columns hiding relational structure
- Comma-separated or pipe-delimited values in a column
- Boolean/status stored as `TINYINT` or unbounded `VARCHAR`
- Timestamps stored as Unix epoch integers instead of proper timestamp types
- Money stored as `FLOAT` or `DOUBLE`
- Foreign keys with no corresponding index
- `DELETE FROM` with no documented delete strategy
- Migrations that run `ALTER TABLE` without `CONCURRENTLY` equivalent
- No down migration written
- Schema changes never tested on production-scale data

---

## Verification

Before merging any schema change:

- [ ] Entity-relationship diagram or written domain model reviewed
- [ ] Schema is 3NF or higher; any denormalisation documented with measured justification
- [ ] Column names, types, and nullability follow naming and type rules
- [ ] Indexes planned against documented query patterns; each has a named justification
- [ ] Delete strategy chosen and implemented consistently (hard / soft / archive / tombstone)
- [ ] Migration uses zero-downtime patterns (no full table locks, no blocking ALTER)
- [ ] Down migration written and tested
- [ ] Migration tested on production-scale data; duration measured
- [ ] Application smoke-tested against migrated schema in staging







---
name: accessibility-driven-development
description: >
  WCAG 2.1 AA as a first-class build gate, not an afterthought. Covers keyboard
  navigation contracts, ARIA roles, focus management, colour contrast, and
  screen-reader testing steps. Extends the existing accessibility-checklist into
  a full development workflow.
  Use when building or modifying any user-facing UI — not just when accessibility
  bugs are reported.
---

# Accessibility-Driven Development

## Overview

Accessibility is a build constraint, not a post-launch audit. WCAG 2.1 AA
compliance is the legal minimum in most jurisdictions, and inaccessible
interfaces exclude a meaningful proportion of every user base — permanently.

This skill integrates accessibility into the development workflow so it is
verified at the component level before it reaches QA, rather than discovered
during an audit after ship.

## When to Use

- Building a new UI component or page
- Modifying an existing component's markup, focus behaviour, or colour
- Reviewing a pull request that changes user-facing HTML or ARIA
- Fixing an accessibility bug report
- Preparing a feature for production launch

## Process

### Step 1 — Define the interaction contract before writing markup

For any interactive component, document before coding:

1. **Keyboard interaction pattern** — which keys trigger which actions? Reference the [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) for your component type.
2. **Focus behaviour** — where does focus go on open, on close, on action?
3. **Screen reader announcement** — what will a screen reader announce when this element receives focus or state changes?
4. **Colour-independent meaning** — does the UI convey all meaning without relying on colour alone?

Do not begin writing markup or component code until these are written down.

**Checkpoint:** Interaction contract documented for every interactive element. ✓

### Step 2 — Use semantic HTML before reaching for ARIA

The first rule of ARIA: do not use ARIA if you can use native HTML.

| Need | Correct element | Do not use |
|------|----------------|-----------|
| Button | `<button>` | `<div onclick>`, `<span onclick>` |
| Navigation | `<nav>` | `<div role="navigation">` |
| Main content | `<main>` | `<div id="main">` |
| Form label | `<label for="...">` | `placeholder` only |
| Heading hierarchy | `<h1>`–`<h6>` in order | Styled `<div>` or `<p>` |
| Link (navigates) | `<a href="...">` | `<button>` for navigation |
| Form (action on submit) | `<form>` | `<div>` with JavaScript submit |
| Required field | `required` attribute | ARIA only |
| Disabled control | `disabled` attribute | `aria-disabled` alone |

ARIA is for roles and states that HTML cannot express natively (e.g., `role="combobox"`, `aria-expanded`, `aria-live`).

**Checkpoint:** All native HTML alternatives exhausted before adding ARIA. ✓

### Step 3 — Implement complete keyboard navigation

Every user interaction must be reachable and operable by keyboard alone.

Required for all interactive components:
- All interactive elements are reachable via `Tab` / `Shift+Tab`
- Custom widgets follow APG keyboard patterns (arrow keys in menus, `Escape` to close)
- No keyboard trap — focus can always move away from any component
- Skip links provided for long navigation sequences (`<a href="#main">Skip to main content</a>`)
- Focus order follows the visual reading order (no `tabindex` values > 0)
- `tabindex="0"` only on custom interactive elements; never on non-interactive elements

Test by unplugging the mouse and completing every user journey using only the keyboard.

**Checkpoint:** All interactions completed successfully using keyboard only. ✓

### Step 4 — Implement focus management for dynamic content

When UI changes dynamically (modal opens, page section updates, navigation changes)
focus must be programmatically managed.

| Trigger | Focus destination |
|---------|------------------|
| Modal opens | First focusable element inside modal, or modal heading |
| Modal closes | Element that triggered the modal |
| Page navigation (SPA) | Page heading (`h1`) or top of new content |
| Inline error appears | Error message element, or field with error |
| Toast / notification | Not moved to toast (use `aria-live` instead) |
| Accordion expands | Panel heading or first focusable element inside panel |

Focus trap in modals:
- `Tab` and `Shift+Tab` must cycle within the modal while it is open
- `Escape` must close the modal and return focus to the trigger

**Checkpoint:** Focus management verified for all dynamic UI changes. ✓

### Step 5 — Verify colour contrast and non-colour cues

Minimum contrast ratios (WCAG 2.1 AA):
- Normal text (< 18pt or < 14pt bold): **4.5:1**
- Large text (≥ 18pt or ≥ 14pt bold): **3:1**
- UI components and graphical objects (icons, chart lines, input borders): **3:1**
- Decorative elements: no requirement

Tools for checking contrast: browser DevTools accessibility panel, axe, WebAIM
Contrast Checker.

Non-colour requirements:
- Error states must use an icon or text label alongside colour — not colour alone
- Required fields must use text ("required") or symbol (`*` with legend) alongside colour
- Links within body text must be underlined or distinguishable without colour
- Charts and graphs must use patterns or labels alongside colour coding

**Checkpoint:** All text and UI elements pass contrast ratios. No information conveyed by colour alone. ✓

### Step 6 — Write and name ARIA correctly

When ARIA is genuinely needed:

| Pattern | Correct usage |
|---------|--------------|
| Name a control | `aria-label="Close dialog"` or `aria-labelledby="heading-id"` |
| Describe a control | `aria-describedby="error-id"` for error messages and hints |
| Dynamic updates | `aria-live="polite"` for non-urgent, `aria-live="assertive"` for urgent-only |
| Expandable widget | `aria-expanded="true/false"` on the trigger element |
| Required field | `aria-required="true"` (use native `required` where possible) |
| Invalid field | `aria-invalid="true"` with `aria-describedby` pointing to error message |
| Hidden decorative | `aria-hidden="true"` on decorative icons and images |
| Loading state | `aria-busy="true"` on the container being loaded |

ARIA mistakes to avoid:
- `aria-label` on non-interactive elements (labels non-interactive content silently)
- Overriding a native role with `role` (e.g., `role="button"` on `<a>`)
- `aria-live="assertive"` for non-urgent updates (interrupts screen reader mid-sentence)
- Labelling a group of controls at the parent when each control needs its own label

**Checkpoint:** All ARIA attributes are correct and tested with a screen reader. ✓

### Step 7 — Run automated and manual tests before marking done

**Automated (run in CI):**
- axe-core or equivalent: zero violations at impact level `critical` or `serious`
- Lighthouse accessibility score ≥ 90

**Manual checklist (cannot be automated):**
- [ ] Keyboard-only navigation: complete all user journeys without a mouse
- [ ] 200% zoom: all content remains usable and no horizontal scroll at 1280px
- [ ] Screen reader (NVDA+Firefox or VoiceOver+Safari): all interactive elements announced correctly; dynamic content changes announced via live regions
- [ ] Forced colours mode (Windows High Contrast): UI remains usable
- [ ] Disable CSS: content reads in a logical order

**Checkpoint:** Automated: zero critical/serious axe violations. Manual: all 5 checks passed. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "We'll do an accessibility pass before launch." | Remediating inaccessible components is 10× more expensive than building them accessibly. |
| "Our users don't use screen readers." | You do not know this. Accessibility also helps keyboard users, low-vision users, and users on poor connections. |
| "ARIA fixes it." | ARIA does not fix bad HTML. It adds a layer on top that is equally broken. Fix the HTML first. |
| "It looks right visually." | Visual appearance is not accessible experience. Test with a keyboard and screen reader. |
| "The design team didn't spec accessibility." | Accessibility is an engineering responsibility as much as a design one. Raise it in design review and implement it regardless. |
| "Automated tests pass." | Automated tools catch ~30–40% of accessibility issues. Manual testing is mandatory. |

---

## Red Flags

- Interactive elements are `<div>` or `<span>` with `onclick` handlers
- `tabindex` values greater than 0
- Form inputs without associated `<label>` elements
- Colour contrast below 4.5:1 for normal text
- Modals that do not trap focus and do not return focus on close
- `aria-label` on every element regardless of whether it is needed
- No skip link on pages with lengthy navigation
- Zero screen reader testing performed by the developer
- Accessibility testing deferred to QA or a separate audit
- Images without `alt` attributes (decorative images need `alt=""`)

---

## Verification

Before marking any UI feature done:

- [ ] Interaction contract documented (keyboard pattern, focus behaviour, screen reader announcement)
- [ ] Native HTML elements used; ARIA only added where HTML cannot express the required semantics
- [ ] All interactive elements reachable and operable by keyboard alone
- [ ] Focus programmatically managed for all dynamic UI changes (modals, navigation, errors)
- [ ] Skip link present on pages with lengthy navigation
- [ ] All text contrast ≥ 4.5:1 (normal) or 3:1 (large); UI component contrast ≥ 3:1
- [ ] No information conveyed by colour alone
- [ ] ARIA attributes correct and tested with a real screen reader
- [ ] Zero critical/serious axe-core violations in CI
- [ ] Keyboard-only user journey completed successfully
- [ ] Screen reader smoke test completed







---
name: agentic-ai-safety
description: >
  Guardrails for autonomous AI agents that take real-world actions. Covers
  human-in-the-loop checkpoints, blast-radius scoping, action reversibility
  checks, rate limiting, audit logging, and kill-switch design.
  Use when building or deploying any agent that can take real-world actions
  (file writes, API calls, emails, purchases, database mutations).
---

# Agentic AI Safety

## Overview

An AI agent that acts autonomously — browsing the web, sending emails, writing
files, calling APIs, or executing code — is fundamentally different from a
chatbot. It can cause real harm at automation speed before a human notices.

The failure mode is not the agent being malicious. It is the agent being
relentlessly competent at the wrong thing, with no natural stopping point.

This skill defines the engineering guardrails that keep autonomous agents within
their intended blast radius, auditable, interruptible, and safe to operate in
production.

## When to Use

- Building any agent that executes actions beyond reading/generating text
- Adding new action types to an existing agent
- Reviewing an agent system before production deployment
- After any incident where an agent performed an unintended action
- Designing the tool/function set available to an LLM

## Process

### Step 1 — Classify every action by reversibility before building

Before implementing any agent action, classify it:

| Class | Definition | Examples | Required confirmation |
|-------|-----------|----------|----------------------|
| **Read-only** | No state change | Search, fetch, list, read file | None |
| **Reversible write** | Can be undone | Create draft, add to cart, write temp file | Low (log only) |
| **Difficult to reverse** | Undone with effort | Send notification, create record | Medium (dry-run + confirm) |
| **Irreversible** | Cannot be undone | Send email, delete record, charge payment, POST to external API | High (explicit human approval) |
| **Catastrophic-risk** | Wide blast radius | Mass email, bulk delete, infrastructure change | Block: require explicit human-initiated trigger |

Never allow an agent to reach `Irreversible` or `Catastrophic-risk` actions
without a human confirmation checkpoint. This is non-negotiable.

**Checkpoint:** Every action in the agent's tool set is classified. ✓

### Step 2 — Define and enforce the minimum permission set

Agents must operate with the minimum permissions required for their task —
not the permissions of the user who invoked them.

For each agent:
- List every resource it can access (files, databases, APIs, email accounts)
- For each resource, list the minimum permission needed (read / write / delete)
- Deny everything not on the list at the infrastructure level, not just in the prompt
- Create a dedicated service account for the agent — never reuse human credentials
- Rotate the service account credentials on a schedule

The prompt alone is not a permission boundary. Prompt injection attacks can
override instructions. Infrastructure-level restrictions cannot be overridden
by the model.

**Checkpoint:** Agent service account created with minimum required permissions. Infrastructure-level restrictions in place. ✓

### Step 3 — Implement human-in-the-loop checkpoints

Define checkpoints where the agent pauses and requires human confirmation before
proceeding.

Mandatory checkpoint triggers:
- Any irreversible action (see Step 1 classification)
- Accumulative impact exceeds a threshold (e.g., more than 10 records modified, cost > $50)
- Confidence score of the action plan falls below a configured threshold
- The action target is outside a pre-approved allow-list (e.g., sending email to a domain not in the approved list)
- The agent has been running for longer than the expected task duration

Checkpoint implementation:
```
1. Agent produces an action plan (dry-run output showing what it will do)
2. Plan is presented to a human for approval
3. Human approves, rejects, or edits the plan
4. Agent executes approved plan only — no improvisation after approval
5. Agent reports outcome; deviations from approved plan are flagged
```

**Checkpoint:** Confirmation checkpoints implemented for all irreversible and high-impact actions. ✓

### Step 4 — Implement a kill switch and rate limits

Every agent in production must be interruptible at any time without side effects.

Kill switch requirements:
- A single flag (feature flag, environment variable, or database row) that stops all agent execution immediately
- The kill switch must take effect within one action cycle — not eventually
- Killing the agent must not leave resources in a partially-modified state — use transactions or compensating actions
- The kill switch must be testable in staging without affecting production

Rate limits — hard limits per time window that the agent cannot override:
- Maximum actions per minute and per hour
- Maximum spend / cost per day
- Maximum emails / messages sent per hour
- Maximum records modified per run
- Maximum external API calls per minute

Rate limits are implemented in the execution layer, not the prompt.

**Checkpoint:** Kill switch implemented and tested. Rate limits configured and enforced at the execution layer. ✓

### Step 5 — Log every action with full provenance

Every action an agent takes must be logged with enough context to reconstruct
exactly what happened, why, and what the outcome was.

Required fields per action log entry:
```json
{
  "agent_id": "...",
  "run_id": "...",
  "timestamp": "ISO8601",
  "action_type": "send_email | write_file | call_api | ...",
  "reversibility_class": "reversible | difficult | irreversible",
  "input": { "...": "full input parameters" },
  "output": { "...": "full output or error" },
  "approved_by": "user_id or null (if auto-approved)",
  "model_reasoning": "verbatim rationale from model if available",
  "duration_ms": 142
}
```

Rules:
- Logs must be append-only — no agent process may delete or modify its own logs
- Logs must be stored outside the agent's permission scope
- Audit logs must be retained for a minimum of 90 days
- Log the model's stated reasoning for every non-trivial decision

**Checkpoint:** Full action audit log in place. Logs are append-only and outside agent's write scope. ✓

### Step 6 — Scope the agent's context window and tool set to the task

An agent with access to all tools and all data is an agent that can cause harm
in unexpected ways. Scope tightly.

- Expose only the tools required for the current task — not the full tool catalogue
- Limit the context window to data relevant to the current task
- Do not pass credentials, secrets, or user PII into the agent's context unless the task explicitly requires it
- Use task-scoped tokens where possible (a token that expires after one task session)
- Validate all tool inputs against a schema before execution — the model's output is untrusted input

**Checkpoint:** Tool set scoped to current task. No unnecessary credentials or PII in context. All tool inputs schema-validated. ✓

### Step 7 — Test adversarial inputs and failure modes

Agents face attack vectors that traditional software does not.

Required tests:

| Test | What it verifies |
|------|-----------------|
| Prompt injection via tool output | Tool returns malicious instructions; agent must not follow them |
| Conflicting instructions | System prompt and user input conflict; agent follows system prompt |
| Exceeding rate limits | Rate limiter triggers; agent stops cleanly |
| Kill switch activation mid-task | Agent stops within one cycle; no partial state left |
| Irreversible action without approval | Agent must not proceed without checkpoint confirmation |
| Out-of-scope resource access | Infrastructure blocks access; agent reports error, does not improvise |
| Malformed tool output | Agent handles gracefully; does not retry indefinitely |

**Checkpoint:** All 7 adversarial test scenarios pass. ✓

---

## Common Rationalizations

| Excuse | Rebuttal |
|--------|----------|
| "The prompt says not to do harmful things." | Prompt instructions are overridable by prompt injection and adversarial inputs. Use infrastructure controls. |
| "We can review logs after the fact." | Irreversible actions cannot be undone by reviewing logs. Block before, not audit after. |
| "The agent is only used internally." | Internal users make mistakes. Internal credentials are also phishing targets. |
| "Rate limits will slow the agent down." | An agent without rate limits is one runaway loop from a production incident. |
| "We'll add safety features when we scale." | Safety is cheaper to add before the first real-world action than after the first incident. |
| "The model is smart enough to know when to stop." | The model does not know when it has sent 10,000 emails. Your rate limiter does. |

---

## Red Flags

- Agent reuses a human user's credentials or session token
- No kill switch — the only way to stop the agent is to terminate the process
- Irreversible actions (send, delete, charge) with no human confirmation step
- Rate limits set in the system prompt rather than enforced in code
- Audit logs are stored in a location the agent can modify or delete
- Tools exposed to the agent include capabilities not needed for the task
- No schema validation on tool inputs before execution
- Prompt injection via external content (web pages, emails, documents the agent reads) is not tested
- No test for what happens when the agent is killed mid-task

---

## Verification

Before deploying any agent to production:

- [ ] Every action classified by reversibility; irreversible actions require human confirmation checkpoint
- [ ] Dedicated service account with minimum required permissions; infrastructure-level access controls in place
- [ ] Human-in-the-loop checkpoints implemented for all irreversible and threshold-exceeding actions
- [ ] Kill switch implemented, tested, and confirmed to stop agent within one cycle
- [ ] Rate limits enforced in execution layer (not prompt) for actions, cost, messages, and API calls
- [ ] Full action audit log with provenance, append-only, stored outside agent's write scope
- [ ] Tool set scoped to task; no unnecessary credentials or PII in context; tool inputs schema-validated
- [ ] All 7 adversarial test scenarios pass including prompt injection and kill switch mid-task
- [ ] Runbook written for: agent goes rogue, rate limit exceeded, agent stuck in loop, kill switch activated







---

## Why Agent Skills?

AI coding agents default to the shortest path - which often means skipping specs, tests, security reviews, and the practices that make software reliable. Agent Skills gives agents structured workflows that enforce the same discipline senior engineers bring to production code.

Each skill encodes hard-won engineering judgment: *when* to write a spec, *what* to test, *how* to review, and *when* to ship. These aren't generic prompts - they're the kind of opinionated, process-driven workflows that separate production-quality work from prototype-quality work.

Skills bake in best practices from Google's engineering culture — including concepts from [Software Engineering at Google](https://abseil.io/resources/swe-book) and Google's [engineering practices guide](https://google.github.io/eng-practices/). You'll find Hyrum's Law in API design, the Beyonce Rule and test pyramid in testing, change sizing and review speed norms in code review, Chesterton's Fence in simplification, trunk-based development in git workflow, Shift Left and feature flags in CI/CD, and a dedicated deprecation skill treating code as a liability. These aren't abstract principles — they're embedded directly into the step-by-step workflows agents follow.

---

## Contributing

Skills should be **specific** (actionable steps, not vague advice), **verifiable** (clear exit criteria with evidence requirements), **battle-tested** (based on real workflows), and **minimal** (only what's needed to guide the agent).

See [docs/skill-anatomy.md](docs/skill-anatomy.md) for the format specification and [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT - use these skills in your projects, teams, and tools.
