---
name: feedback_sanitize_public_repos
description: Abstract Batuta client names and CO-specific vendor names before any public-repo commit; verified during PR #3 round 2 review
type: feedback
---

# Sanitize PII and commercial relationships in public repos

## The rule

For any commit going to a PUBLIC repo (e.g. `jota-batuta/batuta-agent-skills`), abstract:

1. **Specific Batuta client names** (the operator knows the actual names; NOT enumerated here so this memory itself is safe to back up to public repos) → abstract to "Batuta consulting clients across regulated and operational domains in Colombia"
2. **Specific CO vendor names** (DIAN, Bancolombia, BBVA, Bold) → "Colombian e-invoicing authority", "Colombian banks", "payment processors"
3. **Specific specialist names** that imply a specific vendor (e.g. `bancolombia-statement-parser`) → keep as technical agent name if needed but in narrative prose use "Colombian bank-statement parser specialist"

## Why

- Clients did not consent to having their names publicly associated with internal Batuta tooling
- Public repo content is indexed by search engines and AI training crawlers — once leaked, irreversible
- Commercial relationship metadata (who is/was a client) is non-public information by default
- Operator's GitHub handle `jota-batuta` IS public and intentional, so it stays

## How to apply

- **Before any commit to a public repo**, grep the staged diff for client names and CO-specific vendor names. Sanitize before commit.
- The operator's `~/.claude/CLAUDE.md` itself was sanitized following this rule (PRD/SPEC/DELEGATION docs in PR #2 + PR #3 round 2)
- For PRIVATE repos (default for client-facing projects), no sanitization needed — full names are fine.

## Confirmed during PR #3 round 2

After security-auditor flagged 14 occurrences across PRD.md / DELEGATION-RULE-SPECIALISTS.md / ADR 0002 / session journal, the operator chose the abstract-roles option for all of them (decisions preserved in `docs/sessions/2026-04-26-rule-zero-implementation.md`).
