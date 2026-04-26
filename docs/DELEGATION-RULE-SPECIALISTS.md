# DELEGATION-RULE-SPECIALISTS.md

> Extension of [DELEGATION-RULE.md](DELEGATION-RULE.md). Defines how the main agent creates domain specialist subagents on demand using a meta-agent, `agent-architect`. Compatible with **batuta-agent-skills**.

## The problem

The five base agents shipped with this plugin (`implementer`, `implementer-haiku`, `code-reviewer`, `test-engineer`, `security-auditor`) cover roughly 60% of routine work: implementing a spec at Sonnet or Haiku tier, generating tests, reviewing a diff, OWASP audit. The remaining 40% is **domain expertise** that justifies a dedicated specialist when a pattern shows up at least twice in a project:

- Google OAuth flows (refresh tokens, scopes, revocation)
- Node.js streams and backpressure
- Postgres zero-downtime migrations
- Payment-processor webhooks (idempotency, retries, signature validation)
- RAG with pgvector
- Colombian bank statement parsers
- Colombian e-invoicing

Building these by hand does not scale. Loading them all up front pollutes the main's context. The solution is a meta-agent that materializes them on demand.

## The rule

> When the main agent identifies that a slice (or a recurring pattern in the project) needs domain expertise that exceeds the five base agents, it does NOT improvise with a long `Task` prompt. It invokes the meta-agent `agent-architect` which (1) runs discovery-first to avoid duplicates, (2) researches the domain, (3) writes `<project>/.claude/agents/<name>.md` with correct frontmatter, (4) reports to the main so the main can delegate to the freshly created specialist.

**Two surfaces, two governance paths:**
- `<project>/.claude/agents/<name>.md` — *project-local user agents*, created at runtime by `agent-architect`. This is what this document is about.
- `<plugin>/agents/<name>.md` — *plugin-shipped agents* (the five base agents live here). New plugin-shipped agents are added by humans following the `batuta-agent-authoring` skill; `agent-architect` does NOT touch this surface.

Three consequences:

1. **The specialist persists in `.claude/agents/`.** Next time the slice touches that domain, the main invokes it directly without going through `agent-architect` again.
2. **Specialists are project-local by default.** Promotion to `~/.claude/agents/` global is manual, only when the agent has proven useful in ≥ 2 projects.
3. **Discovery-first is non-negotiable.** Before creating, `agent-architect` lists what already exists. If a reasonable match shows up, it reports the existing agent and does NOT create a duplicate. Same philosophy as the existing `batuta-agent-authoring` skill applies for skills.

## Triggers — when the main invokes `agent-architect`

The main calls `agent-architect` when at least one of these holds:

1. **Recurring pattern detected.** During `/spec` or `/plan`, the slice touches a domain that has appeared before in this project, and the base agents are not handling it well.
2. **Specific stack or protocol.** The slice depends on a library, framework, or protocol with enough complexity to deserve its own body of knowledge (OAuth 2.0, GraphQL federation, WebRTC, gRPC, WebSocket reconnection, etc.).
3. **Regulation or compliance.** The slice touches specific regulation (Colombian e-invoicing, GDPR, PCI-DSS, HIPAA, Colombian labor law). Here the specialist's model may justifiably be `opus`.
4. **Batuta client domain.** Slices for any consulting client that touch client-specific business logic (e.g. "how a payment processor reports electronic deposits with delay", "how a specific bank formats PDF statements") justify a per-client specialist.

**Anti-pattern to avoid:** creating specialists for one-off tasks. If the slice is "add an endpoint that returns the API version", you do not need `nodejs-versioning-expert`. A `Task` with a detailed prompt to `implementer` is enough.

**Rule of thumb:** *if you will invoke this agent ≥ 2 times in this project, persist it. If not, write a long prompt to `implementer`.*

## End-to-end example: adding Google OAuth

**Operator:** *"I need Google OAuth login on the backend. Handle refresh tokens and revocation."*

**Main agent (Opus, orchestrator mode):**

1. Activates `idea-refine`, asks 2–3 questions (backend only or frontend too? scopes? token persistence?).
2. Activates `spec-driven-development`, writes `specs/current/google-oauth-001/spec.md`.
3. Shows the spec to the operator, waits for OK.
4. Activates `planning-and-task-breakdown`. Identifies that the slice has domain complexity (OAuth flows, refresh rotation, Google-specific security considerations) that exceeds `implementer`.
5. **Detects trigger #2** (specific stack/protocol). Decides to invoke `agent-architect`.
6. `Task` → `agent-architect` (sonnet):
   ```
   Need a specialist subagent for Google OAuth 2.0 in this project.
   Triggers: token exchange, refresh rotation, scope validation, revocation, threat model.
   Stack: Node.js + Express, Postgres for persistence.
   ```
7. `agent-architect` runs:
   - Discovery: `ls .claude/agents/ ~/.claude/agents/` → no match
   - Research: WebSearch + Context7 on Google OAuth 2.0 spec, refresh token best practices, common pitfalls (PKCE, state param, revocation endpoint)
   - Designs: `name: google-oauth-expert`, `model: sonnet`, minimal tools
   - Writes `<project>/.claude/agents/google-oauth-expert.md`
   - Reports back: agent ready + Task prompt template
8. Main writes `tasks.md` breaking down the slice.
9. HUMAN GATE: shows spec + plan + tasks, waits for OK.
10. `Task` → `google-oauth-expert` (sonnet):
    ```
    Implement google-oauth-001 using OAuth 2.0 expertise.
    Spec: specs/current/google-oauth-001/spec.md
    Plan: specs/current/google-oauth-001/plan.md
    Tasks: specs/current/google-oauth-001/tasks.md
    DoD: 4 endpoints (initiate, callback, refresh, revoke) + tests + threat model in build-log.
    ```
11. `google-oauth-expert` implements, writes `build-log.md`, returns summary with `READY FOR AUDIT` line.
12. Main chains: `Task` → `test-engineer` (GATE 1) → `code-reviewer` (GATE 2) → `security-auditor` (GATE 3 — critical here because it is OAuth).
13. Main writes `lessons-learned.md`, moves `specs/current/google-oauth-001` → `specs/archive/`.

**Next slice that touches OAuth in this project:** the main already has `google-oauth-expert` available and invokes it directly, no `agent-architect` round-trip.

## Recommended model by task complexity (calibration)

The main agent picks the model when delegating to a base agent (`implementer-haiku`, `implementer`, or a domain specialist created by `agent-architect`). The decision is by **task complexity**, not by surface area or file count alone.

### Calibration by concrete task

| Task | Model | Why |
|---|---|---|
| "change submit button color from gray to blue" | `haiku` | CSS-only, no logic, 1 file |
| "rename `getCwd` to `getCurrentWorkingDirectory` across the codebase" | `haiku` | Mechanical rename, no semantic change |
| "add a new entry to the CHANGELOG for v1.4.0" | `haiku` | Copy edit |
| "bump dependency `react` from 18.2 to 18.3 in package.json" | `haiku` | Config flip |
| "list all routes registered in this Express app" | `haiku` | Read-only discovery |
| "add `/health` endpoint that returns 200 OK with an integration test" | `sonnet` | New control flow + test |
| "implement retry with exponential backoff for the Stripe client" | `sonnet` | Async + error handling |
| "refactor the auth module to extract token validation into middleware" | `sonnet` | Cross-module change with semantic preservation |
| "add pagination to the `/orders` list endpoint" | `sonnet` | New parameters + edge cases (empty, last page, invalid cursor) |
| "validate the Colombian e-invoicing XML against the 2026 schema" | `opus` | Compliance-critical, errors have legal cost |
| "review the GDPR data subject erasure flow for completeness" | `opus` | Regulatory + cross-cutting concerns |
| "fix typo in e-invoicing error message string from `ENVAINDO` to `ENVIANDO`" | `haiku` | Mechanical even when the surrounding domain is regulated — the change does not touch validation logic |

**Tiebreaker rule:** when a task sits between Haiku and Sonnet, choose Sonnet. The over-spend on a Haiku-eligible task is invisible (a few cents), but under-spending on a Sonnet-required task produces broken output that the audit chain catches and reopens — which costs more in total.

### Recommended model by specialist type

When `agent-architect` creates a project-local specialist, the model defaults follow this table:

| Specialist type | Model | Justification |
|---|---|---|
| Frameworks / languages (Node.js, Postgres, React, Django) | `sonnet` | Structured knowledge, Sonnet handles it well |
| Protocols (OAuth, gRPC, WebRTC, GraphQL) | `sonnet` | Spec-driven, Sonnet with the agent's context is enough |
| Integrations (payment processors, comms providers) | `sonnet` | Standard webhook/SDK patterns |
| Format parsers (bank statements, regulatory XML) | `sonnet` | Deterministic logic plus edge cases |
| Trivial-change executors (CSS/string/rename within a domain) | `haiku` | If the recurring pattern is genuinely trivial, persist as Haiku specialist |
| Compliance / regulation (Colombian e-invoicing, Colombian labor law, GDPR) | `opus` | **Justified exception**: errors here have legal cost. Opus pays for itself. |
| Forensic audit (legal, accounting) | `opus` | Critical analysis where Opus reasoning earns its keep |
| Read-only / discovery (schema mapping, file search) | `haiku` | 25× cheaper, enough for exploration |

Never use Opus for routine code implementers. Exception to the exception: if the domain is both critical and the implementation is non-trivial, combine — e.g. `dian-fe-expert` (opus) validates the logic, then `implementer` (sonnet) writes the code following what the first one validated.

## Minimal specialist template

This is what `agent-architect` produces. Concrete example for the OAuth flow above — `<project>/.claude/agents/google-oauth-expert.md`:

```markdown
---
name: google-oauth-expert
description: Use when implementing Google OAuth 2.0 flows in Node.js — token exchange, refresh token rotation, scope validation, revocation. Implements per Google's OAuth 2.0 spec and Discovery doc. Returns code, tests, and threat-model notes in build-log. Project-local agent.
model: sonnet
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - WebFetch
---

# Google OAuth Expert (Node.js)

## When to invoke
- New implementation of Google OAuth 2.0 (Authorization Code flow with PKCE)
- Refactor of refresh token handling (rotation, expiration)
- Audit of scopes against principle of least privilege
- Implementation of revocation endpoint or logout flow

## Domain knowledge
- Google OAuth 2.0 Discovery doc: https://accounts.google.com/.well-known/openid-configuration
- Refresh tokens at Google: rotation optional but recommended; expire if unused for 6 months; max 100 active refresh tokens per user/client
- PKCE is mandatory for public clients, recommended always
- `state` param for CSRF protection — unique per request, validated on callback
- Revocation: POST to `https://oauth2.googleapis.com/revoke` with the token (access or refresh)
- Anti-pattern: hardcoding `client_secret` in frontend code or committing it
- Anti-pattern: storing tokens in localStorage in an SPA (XSS leak); use httpOnly cookies

## Workflow
1. Read `specs/current/<slice-id>/{spec,plan,tasks}.md`
2. Activate `research-first-dev` to validate `google-auth-library` and `googleapis` versions via Context7
3. Implement endpoints in order: initiate → callback → refresh → revoke
4. Per endpoint: implement → test happy path → test error paths (`invalid_grant`, `expired_token`, mismatched `state`) → stage
5. Threat model: document in build-log identified risks (CSRF, token leak, scope creep) and applied mitigations
6. Write `specs/current/<slice-id>/build-log.md` with: files created, technical decisions (PKCE yes/no, storage decision, refresh strategy), Google docs references, threat model
7. Return control to the main with the closing line `READY FOR AUDIT: test-engineer → code-reviewer → security-auditor`

## Absolute rules
- NO hardcoded `client_secret` — always env var validated at startup
- NO refresh tokens stored without at-rest encryption
- NO implicit flow — deprecated by Google since 2022
- If the spec asks for broad scopes without justification (e.g. `https://www.googleapis.com/auth/drive` when only one file needs reading), stop and return `BLOCKER: scope creep, justify or reduce`
- NO modifications to `specs/` except `build-log.md`
- NEVER close the task on your own. The audit chain runs first.

## Verification
- initiate / callback / refresh / revoke endpoints with passing tests (happy + ≥ 2 error paths)
- `state` param validated on callback with explicit assertion
- Tokens encrypted at rest in DB (verifiable with SELECT)
- Threat model documented in build-log with ≥ 3 risks + mitigation
```

## Promotion: project-local → user-global

When a specialist proves useful across ≥ 2 distinct projects, promote it to `~/.claude/agents/` so it is globally available.

**Promotion criteria:**
1. Invoked successfully in ≥ 2 different projects
2. Description does NOT mention details specific to one project or client
3. System prompt is generalizable (no absolute paths from the original project)

**How to promote (manual, 30 seconds):**

```bash
cp .claude/agents/google-oauth-expert.md ~/.claude/agents/

# Edit the global file and remove origin-project-specific references
# (e.g. "in this Express + Postgres project" → "typically Express or Fastify + SQL persistence")

claude
> /agents
# Should list google-oauth-expert under user scope
```

**How to demote (if the global agent ends up biased by the original project):**

```bash
mv ~/.claude/agents/google-oauth-expert.md <other-project>/.claude/agents/
# Adjust to the new project context — repeated exposure surfaces more general patterns
```

## Maintaining the specialist fleet

Over time `<project>/.claude/agents/` and `~/.claude/agents/` accumulate. Apply this rule every ~ 2 months per project:

1. **List** all agents and when each was last used (check `git log` of `specs/archive/`).
2. **If an agent was not used in the last 2 months**, candidate for archival. Move to `<project>/.claude/agents/archive/` or delete if the domain no longer applies.
3. **If two agents have descriptions with > 70% semantic overlap**, merge them. Probably one was created because Discovery on day X did not work well.
4. **If an agent grew past 150 lines** (the limit set in `batuta-agent-authoring`), split it into two narrower specialists (e.g. `google-oauth-expert` → `google-oauth-flows` + `google-oauth-tokens`).

`agent-architect` can help here. Invoke it in audit mode — *"audit the agents in `.claude/agents/` and suggest merges, splits, and deprecations"* — and it returns a report without touching anything. You decide.

## Integration with Rule #0

This document does not contradict [DELEGATION-RULE.md](DELEGATION-RULE.md), it extends it. The full chain becomes:

```
operator → main (Opus, planner)
              │
              ├── /spec, /plan → writes specs/current/<slice>/
              │
              ├── slice needs specialist expertise? → YES
              │     └── Task → agent-architect (sonnet)
              │           ├── Discovery (already exists?)
              │           ├── Research (Context7 + WebSearch)
              │           └── Materializes <project>/.claude/agents/<name>.md
              │
              └── Task → <freshly created or existing specialist> (sonnet)
                         ├── Implements
                         ├── Tests locally
                         ├── build-log.md
                         └── returns READY FOR AUDIT
                      │
                      ▼
                    Task → test-engineer (sonnet)        [GATE 1]
                      │
                      ▼
                    Task → code-reviewer (sonnet)        [GATE 2]
                      │
                      ▼
                    Task → security-auditor (sonnet)     [GATE 3, when applicable]
                      │
                      ▼
              Main → writes lessons-learned.md
                     moves specs/current → specs/archive/
```

The main still **never touches code directly**. The audit chain still blocks closure. The only thing this extension adds is a formal way for the main to materialize specialists the plugin does not ship out of the box, without manual file editing each time.

## 1-day setup

**Step 1 (10 min):** confirm `agents/agent-architect.md` is present in this plugin. Restart Claude Code. Validate with `/agents` that it shows up with `model: sonnet`.

**Step 2 (5 min):** confirm the project's `CLAUDE.md` references this document under "Mandatory Skills". Without the reference, the main agent may not invoke `agent-architect` reliably.

**Step 3 (validation, 30 min):** pick the next real slice you have pending. If it touches a specific domain (payment-processor webhook, statement parsing, ERP integration), start the session and watch whether the main naturally invokes `agent-architect`. If it does not, prompt explicitly: *"this slice touches X, consider invoking agent-architect before delegating to implementer"*. After 2–3 sessions of nudging, the pattern settles.

**Step 4 (measurement, 1 week):** at the end of the first week using this pattern, count:
- How many specialists `agent-architect` created
- How many were reused (vs. single-use)
- How many remained unused after the original slice (deprecation candidates)

If < 50% of created specialists were reused, raise the trigger threshold (≥ 2 uses) to 3 — too many specialists are being created for single-use cases.

## What this resolves

1. **The system scales with your client and domain portfolio.** As you onboard more clients, specialists accumulate in `~/.claude/agents/` global, and new projects start with pre-loaded expertise.
2. **You stop reinventing prompts every slice.** Knowledge of "how to handle Google refresh tokens", "how to parse a specific bank's statement format", "what scopes to ask a given payment processor for" is encoded and versioned — it does not get lost in chat history.
3. **Discovery-first prevents duplicates.** Same philosophy already in place for skills via `batuta-skill-authoring`, now applied to agents.
4. **Each specialist runs at the right model tier.** Sonnet for 95% of cases. Opus only for compliance/legal where it pays for itself. Haiku for read-only. The savings of Rule #0 hold even as the fleet grows past 20 specialists.
5. **Reusable cross-project via manual promotion.** What one project learns can benefit the next without contaminating the first with foreign details.

---

*Version 1.0 · Extension of DELEGATION-RULE.md · Applies to batuta-agent-skills v0.x · Compatible with Claude Code v2.1+*
