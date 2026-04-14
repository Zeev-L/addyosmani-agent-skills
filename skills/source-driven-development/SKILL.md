---
name: source-driven-development
description: Grounds every implementation decision in official documentation. Use when you want authoritative, source-cited code free from outdated patterns. Use when building with any framework or library where correctness matters.
---

# Source-Driven Development

## Overview

Every framework-specific code decision must be backed by official documentation. Don't implement from memory — verify, cite, and let the user see your sources. Training data goes stale, APIs get deprecated, best practices evolve. This skill ensures the user gets code they can trust because every pattern traces back to an authoritative source they can check.

## When to Use

- The user wants code that follows current best practices for a given framework
- Building boilerplate, starter code, or patterns that will be copied across a project
- The user explicitly asks for documented, verified, or "correct" implementation
- Implementing features where the framework's recommended approach matters (forms, routing, data fetching, state management, auth)
- Reviewing or improving code that uses framework-specific patterns
- Any time you are about to write framework-specific code from memory

**When NOT to use:**

- Correctness does not depend on a specific version (renaming variables, fixing typos, moving files)
- Pure logic that works the same across all versions (loops, conditionals, data structures)
- The user explicitly wants speed over verification ("just do it quickly")

## The Process

```
DETECT ──→ RECALL ──→ FETCH ──→ IMPLEMENT ──→ CITE + CACHE
  │          │          │           │              │
  ▼          ▼          ▼           ▼              ▼
 What       Cache      Get the     Follow the    Show your
 stack?     hit?       relevant    documented    sources and
            Skip       docs        patterns      append the
            fetch                                citation
```

### Step 1: Detect Stack and Versions

Read the project's dependency file to identify exact versions:

```
package.json    → Node/React/Vue/Angular/Svelte
composer.json   → PHP/Symfony/Laravel
requirements.txt / pyproject.toml → Python/Django/Flask
go.mod          → Go
Cargo.toml      → Rust
Gemfile         → Ruby/Rails
```

State what you found explicitly:

```
STACK DETECTED:
- React 19.1.0 (from package.json)
- Vite 6.2.0
- Tailwind CSS 4.0.3
→ Fetching official docs for the relevant patterns.
```

If versions are missing or ambiguous, **ask the user**. Don't guess — the version determines which patterns are correct.

### Step 2: Check the Citation Cache, Then Fetch

**Check the cache first.** Read `.claude/sdd-citations.md` if it exists. If it contains a row matching `framework + version + pattern` for the exact version detected in Step 1, reuse that citation and skip the fetch. Match is **strict**: `react@19.1` does not satisfy `react@19.0`. See the Citation Cache Protocol section below for the format and lookup rules.

If no cache hit, fetch the specific documentation page for the feature you're implementing. Not the homepage, not the full docs — the relevant page.

**Source hierarchy (in order of authority):**

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Official documentation | react.dev, docs.djangoproject.com, symfony.com/doc |
| 2 | Official blog / changelog | react.dev/blog, nextjs.org/blog |
| 3 | Web standards references | MDN, web.dev, html.spec.whatwg.org |
| 4 | Browser/runtime compatibility | caniuse.com, node.green |

**Not authoritative — never cite as primary sources:**

- Stack Overflow answers
- Blog posts or tutorials (even popular ones)
- AI-generated documentation or summaries
- Your own training data (that is the whole point — verify it)

**Be precise with what you fetch:**

```
BAD:  Fetch the React homepage
GOOD: Fetch react.dev/reference/react/useActionState

BAD:  Search "django authentication best practices"
GOOD: Fetch docs.djangoproject.com/en/6.0/topics/auth/
```

After fetching, extract the key patterns and note any deprecation warnings or migration guidance.

When official sources conflict with each other (e.g. a migration guide contradicts the API reference), surface the discrepancy to the user and verify which pattern actually works against the detected version.

### Step 3: Implement Following Documented Patterns

Write code that matches what the documentation shows:

- Use the API signatures from the docs, not from memory
- If the docs show a new way to do something, use the new way
- If the docs deprecate a pattern, don't use the deprecated version
- If the docs don't cover something, flag it as unverified

**When docs conflict with existing project code:**

```
CONFLICT DETECTED:
The existing codebase uses useState for form loading state,
but React 19 docs recommend useActionState for this pattern.
(Source: react.dev/reference/react/useActionState)

Options:
A) Use the modern pattern (useActionState) — consistent with current docs
B) Match existing code (useState) — consistent with codebase
→ Which approach do you prefer?
```

Surface the conflict. Don't silently pick one.

### Step 4: Cite Your Sources

Every framework-specific pattern gets a citation. The user must be able to verify every decision.

**In code comments:**

```typescript
// React 19 form handling with useActionState
// Source: https://react.dev/reference/react/useActionState#usage
const [state, formAction, isPending] = useActionState(submitOrder, initialState);
```

**In conversation:**

```
I'm using useActionState instead of manual useState for the
form submission state. React 19 replaced the manual
isPending/setIsPending pattern with this hook.

Source: https://react.dev/blog/2024/12/05/react-19#actions
"useTransition now supports async functions [...] to handle
pending states automatically"
```

**Citation rules:**

- Full URLs, not shortened
- Prefer deep links with anchors where possible (e.g. `/useActionState#usage` over `/useActionState`) — anchors survive doc restructuring better than top-level pages
- Quote the relevant passage when it supports a non-obvious decision
- Include browser/runtime support data when recommending platform features
- If you cannot find documentation for a pattern, say so explicitly:

```
UNVERIFIED: I could not find official documentation for this
pattern. This is based on training data and may be outdated.
Verify before using in production.
```

Honesty about what you couldn't verify is more valuable than false confidence.

**Append to the cache.** After citing a fresh fetch, append a row to `.claude/sdd-citations.md` (create the file if missing). One row per `(framework, version, pattern)` triple. See the Citation Cache Protocol below.

## Citation Cache Protocol

A single markdown file at `.claude/sdd-citations.md` acts as the verified-citation cache. It is gitignored by default — opt in to commit only if your team wants a shared cache. The agent reads and writes it directly with Read and Edit; no scripts, no tooling.

### Format

Append-only markdown table, one row per verified citation:

```markdown
# SDD Citation Cache

| framework | version | pattern | url | verified_at | notes |
|---|---|---|---|---|---|
| react | 19.1 | useActionState | https://react.dev/reference/react/useActionState#usage | 2026-04-14 | replaces manual isPending |
| django | 6.0 | auth-middleware | https://docs.djangoproject.com/en/6.0/topics/auth/ | 2026-04-10 | |
```

**Field rules:**

- `framework`: lowercase canonical name (`react`, not `React` or `reactjs`)
- `version`: `major.minor` from the dependency file (`19.1`, not `^19.1.0`)
- `pattern`: short slug for the feature (`useActionState`, `auth-middleware`, `form-actions`)
- `url`: full URL with anchor where possible
- `verified_at`: ISO date `YYYY-MM-DD` from the day of the fetch
- `notes`: one-line free text — deprecations, version-specific caveats, or empty

### Lookup rules

- Match is **strict** on `framework + version + pattern`. Approximate matches are not hits.
- If the dependency file shows a newer version than any cached row, the cache is invalidated for that pattern — re-fetch and append a new row.
- If the user reports a cached citation is wrong, **delete the row**. Do not patch cached citations in place — re-verify and re-add.

### What NOT to put in the cache

- Citations from non-authoritative sources (the source hierarchy in Step 2 still applies)
- Patterns flagged as `UNVERIFIED` in Step 4
- Project-specific code snippets — the cache is for *citations*, not implementations

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident about this API" | Confidence is not evidence. Training data contains outdated patterns that look correct but break against current versions. Verify. |
| "Fetching docs wastes tokens" | Hallucinating an API wastes more. The user debugs for an hour, then discovers the function signature changed. One fetch prevents hours of rework. |
| "The docs won't have what I need" | If the docs don't cover it, that's valuable information — the pattern may not be officially recommended. |
| "I'll just mention it might be outdated" | A disclaimer doesn't help. Either verify and cite, or clearly flag it as unverified. Hedging is the worst option. |
| "This is a simple task, no need to check" | Simple tasks with wrong patterns become templates. The user copies your deprecated form handler into ten components before discovering the modern approach exists. |
| "I'll re-fetch even though it's cached, just to be safe" | If `framework + version + pattern` matches a cached row, the doc has not changed for that pattern. Re-fetching wastes tokens and time. The cache exists so you verify *once* per version, not every session. If you don't trust the cache, delete the row — don't bypass it. |

## Red Flags

- Writing framework-specific code without checking the docs for that version
- Using "I believe" or "I think" about an API instead of citing the source
- Implementing a pattern without knowing which version it applies to
- Citing Stack Overflow or blog posts instead of official documentation
- Using deprecated APIs because they appear in training data
- Not reading `package.json` / dependency files before implementing
- Delivering code without source citations for framework-specific decisions
- Fetching an entire docs site when only one page is relevant
- Fetching docs without first checking `.claude/sdd-citations.md` for the same `framework + version + pattern`
- Caching a citation from a non-authoritative source
- Treating `react@19.0` and `react@19.1` as equivalent cache hits (version match must be strict)
- Patching a cached row in place after the user flags it as wrong (delete and re-verify instead)

## Verification

After implementing with source-driven development:

- [ ] Framework and library versions were identified from the dependency file
- [ ] Official documentation was fetched for framework-specific patterns
- [ ] All sources are official documentation, not blog posts or training data
- [ ] Code follows the patterns shown in the current version's documentation
- [ ] Non-trivial decisions include source citations with full URLs
- [ ] No deprecated APIs are used (checked against migration guides)
- [ ] Conflicts between docs and existing code were surfaced to the user
- [ ] Anything that could not be verified is explicitly flagged as unverified
- [ ] `.claude/sdd-citations.md` was checked before any documentation fetch
- [ ] Every fresh fetch resulted in an appended cache row with full `framework + version + pattern + url + verified_at` fields
- [ ] No cached citation was reused when the dependency version no longer matches
