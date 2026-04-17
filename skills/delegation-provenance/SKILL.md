---
name: delegation-provenance
description: Preserves scoped authorization across delegated execution. Use only when building software that delegates actions across agent, tool, or service hops where authorization must survive trust-boundary crossings and remain auditable.
---

# Delegation Provenance

## Overview

Treat human approval as something that travels with the work, not a sentence that got said once and then disappeared into chat history. When an agent delegates, calls a tool, or crosses a trust boundary, it must carry proof of who authorized the action, what scope was granted, and whether the current step still fits. This skill prevents invisible scope expansion, unaudited handoffs, and "the model decided" from quietly becoming a substitute for authorization.

This skill is intentionally narrow: it is not part of ordinary app development unless the software itself delegates authority across agent or tool hops.

## When to Use

- Building multi-agent workflows with explicit handoffs and scoped delegation
- Building delegated tool-execution systems where authorization must survive multiple hops
- Designing provenance and reauthorization flows for agentic systems that cross trust boundaries
- Reviewing multi-agent or multi-tool workflows for authorization continuity gaps, silent scope expansion, or missing auditability

**When NOT to use:**

- Building ordinary React/UI features or other app code with no delegated execution model
- Building standard REST or CRUD endpoints where one service handles the action directly
- Calling a third-party API directly from one agent or service without downstream delegation or authorization propagation
- Using tools in a single-agent workflow where approval does not need to survive multiple hops
- The user is asking for a thought experiment or architecture discussion, not an executable delegated workflow

## The Process

```
CLASSIFY ──→ VERIFY ──→ PROPAGATE ──→ REAUTHORIZE
   │            │            │              │
   ▼            ▼            ▼              ▼
 What trust   Is this       Carry the      Get fresh
 boundary?    action in     receipt and    approval when
              scope?        append a hop   scope expands
```

### Step 1: Classify the Trust Boundary

Before any agent handoff or tool call, classify what kind of boundary is being crossed and what could go wrong if the action is out of scope.

| Boundary | Example | What must be checked |
|---|---|---|
| Agent handoff | planner -> researcher | Allowed delegatees, delegation depth, action summary |
| External tool | agent -> CRM, Stripe, GitHub, email API | Credential identity, allowed operation, target resource |
| Sensitive data | reading PII, finance, health, source repos | Data scope, purpose, retention, redaction |
| Persistent state | DB write, ticket update, file mutation | Write permission, idempotency, rollback path |
| Real-world / financial | refund, purchase, robot action | Explicit approval, hard limits, ceilings, geofencing |

State the boundary explicitly:

```
TRUST BOUNDARY DETECTED:
- Boundary: External billing tool
- Requested action: issue_refund
- Resource: order_1234
- Side effect: customer receives money
→ Verifying authorization before proceeding.
```

If you cannot say what boundary is being crossed, you are not ready to run the step yet.

### Step 2: Verify Authorization and Scope

Every boundary-crossing action must have a durable authorization artifact that survives delegation. Prompt text alone is not enough.

Minimum checks:

- **Who authorized this?** Principal or controlling user
- **Who issued the artifact, and can you verify it?** Trusted issuer, signature or MAC, and trust anchor or key resolution
- **What is allowed?** Actions, tools, resources, data domains
- **What is forbidden?** Explicit exclusions matter as much as inclusions
- **How long is it valid?** Expiry or session bound
- **How far can it delegate?** Delegation depth, allowed sub-agents, tool allowlist
- **Which identity executes it?** User auth, agent auth, service account, API key

Do not invent an unsigned JSON receipt just because it is convenient to sketch. A plain object that says `allowed_actions: ["*"]` is not an authorization artifact; it is just data.

Prefer an existing verifiable format or protocol layer:

- **OAuth 2.0 Token Exchange** ([RFC 8693](https://datatracker.ietf.org/doc/rfc8693/)) when delegation needs to flow through an authorization server
- **Signed JWTs** ([RFC 7519](https://datatracker.ietf.org/doc/rfc7519/), [RFC 8725](https://datatracker.ietf.org/doc/rfc8725/)) when claims, issuer identity, audience, and expiry must be verifiable
- **UCAN**, **Macaroons**, or a protocol like **HDP** when your system already uses capability-style or provenance-aware delegation

The critical property is not the syntax. It is that the consumer can verify issuer, integrity, audience, expiry, and delegation-related claims before trusting the artifact.

Structural example:

```typescript
function authorize(artifact, action, delegatee, serviceId, trustAnchors, depth) {
  const claims = verifyAuthorizationArtifact(artifact, trustAnchors);
  if (!claims) throw new Error('AUTHORIZATION_INVALID');
  if (Date.now() > claims.expiresAt) throw new Error('AUTHORIZATION_EXPIRED');
  if (!claims.audience.includes(serviceId)) throw new Error('WRONG_AUDIENCE');
  if (!claims.allowedActions.includes(action)) throw new Error('OUT_OF_SCOPE');
  if (!claims.allowedDelegatees.includes(delegatee)) throw new Error('DELEGATEE_NOT_ALLOWED');
  if (depth > claims.maxDelegationDepth) throw new Error('DELEGATION_LIMIT_EXCEEDED');
}
```

`verifyAuthorizationArtifact(...)` is intentionally out of scope for this skill. Use a vetted library or protocol implementation for your artifact format, such as `jose` for JWT/JWS verification, and treat rolling your own verifier as a red flag.

If your system cannot answer "who signed or issued this, and why do I trust them?" then it is not ready to rely on delegation artifacts for enforcement.

If the receiving agent or tool cannot inspect the receipt before acting, do not delegate directly. Add a policy wrapper or stop the workflow there.

When declared authorization and runtime permissions disagree, trust neither blindly. A broad credential does not expand scope, and a narrow credential does not prove the receipt is correct. Surface the mismatch, fail closed, and have the workflow owner resolve it before anything proceeds.

### Step 3: Propagate Provenance on Every Hop

Every handoff must carry both the task and the authorization context. Do not overwrite the original approval context; extend it with an append-only hop record.

For each hop, record:

- Acting agent or tool
- Receiving agent or tool
- Action summary
- Timestamp
- Authorization ID used
- Parent hop or previous hop reference

Example:

```
DELEGATION CHAIN:
1. human-support-manager -> triage-agent
   "Classify refund request for delayed order"
2. triage-agent -> policy-agent
   "Check whether order_1234 qualifies under refund policy"
3. policy-agent -> refund-tool
   "Issue refund up to $50 for delayed shipment"
```

The downstream participant must be able to answer:

- Who originally authorized this workflow?
- Which hop delegated this specific action?
- Which scope was in force at this point in the chain?
- Is this action still within that scope?

If those answers require reconstructing chat history by hand, the provenance model is too weak for the job.

### Step 4: Reauthorize on Scope Change

Fresh human approval is required whenever the workflow expands beyond the current receipt.

Common reauthorization triggers:

- Read-only becomes write
- Draft-only becomes send/execute
- Internal data access becomes external disclosure
- A higher-privilege credential is required
- A new tool, agent, or dataset appears
- Delegation depth increases
- A financial, legal, or physical action appears
- Time horizon extends beyond the original approval window

Surface scope expansion explicitly:

```
SCOPE CHANGE DETECTED:
Current authorization covers:
- Read order history
- Draft a refund recommendation
- Issue refunds up to $50 via refund-tool

Requested next action:
- Send a customer-facing confirmation email
- Use notification-service credentials
- Add a new delegatee: comms-agent

→ Requires fresh human approval before proceeding.
```

The new receipt should supersede the previous one, link back to it, and restart execution from the newly approved scope.

## Implementation Patterns

- Prefer self-contained, inspectable receipts over hidden mutable server state
- Prefer least-privileged credentials per tool over one broad shared credential
- Separate approval to **analyze**, **draft**, **send**, and **mutate** — those are different powers
- Include explicit ceilings for risky actions (`<= $50`, `read-only`, `zone_A`, `repo:issues only`)
- Combine this skill with `security-and-hardening` for credential handling and `source-driven-development` when integrating with specific agent frameworks or callback APIs

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The user asked for it in the prompt" | Prompts are intent, not durable authorization. They do not survive delegation cleanly and they do not constrain downstream tools by themselves. |
| "This is a trusted agent, it doesn't need a receipt" | Trusted agents still drift, retry, recurse, and delegate. Provenance is what lets you verify what happened after the workflow spreads across more agents and tools. |
| "We'll log it after the fact" | Logging without pre-execution checks does not prevent unauthorized actions. Auditability is not a substitute for enforcement. |
| "It's only a read" | Reads can expose sensitive data, trigger retention issues, or create downstream write opportunities. Treat data access as a scoped action. |
| "The next step is basically the same action" | "Basically the same" is how silent scope expansion happens. New tool, new credential, new side effect, new approval. |
| "We can reuse the same approval for the whole session" | Long-lived blanket approvals accumulate risk. Authorization should narrow to the task and expire. |

## Red Flags

- Tool calls carry task text but no explicit authorization artifact
- A read-only approval is later used for a write or send action
- Agent handoffs drop the principal, expiry, or scope metadata
- Delegation depth is unlimited or untracked
- The most privileged credential is used for every tool call
- Human approval exists only as chat history or UI text
- New tools or delegatees appear without any reauthorization step
- Downstream systems cannot verify whether the action was in scope
- Audit records cannot reconstruct who approved what through which hops

## Verification

After implementing delegation provenance:

- [ ] Every trust-boundary action is classified before execution
- [ ] Boundary-crossing actions fail closed when authorization is missing, expired, or out of scope
- [ ] Authorization artifacts include principal, scope, expiry, and delegation limits
- [ ] Each agent handoff or tool call carries the authorization context forward
- [ ] The workflow records an append-only delegation chain or equivalent audit trail
- [ ] Scope expansion triggers fresh human approval instead of silent escalation
- [ ] Downstream agents and tools can inspect authorization before acting
- [ ] Least-privileged credentials are used for external actions
- [ ] No approval depends solely on prompt text or manual chat reconstruction
