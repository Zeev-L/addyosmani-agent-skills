---
name: research-first-dev
description: Use before writing code that calls any external library or API not verified this session. Forces Context7 lookup, web-search fallback, and a source-citation comment on every new import site.
---

# Research First Dev

## Overview

**The cheapest bug is the one caught by reading docs.** Most library misuses come from assuming an API that matches the model's training data — which may be months or years out of date. This skill makes documentation lookup a gate, and the proof lives in the code as a citation comment.

This skill delegates the lookup mechanic to `skills/_vendored/context7/` (CC0, from intellectronica/agent-skills). The Batuta layer adds:

1. A mandatory trigger: "before writing code that uses library X"
2. A web-search fallback when Context7 has no coverage
3. An evidence requirement: a `Source:` comment at the import site

## When to Use

Trigger on any of:

- About to write `import`, `require`, `from ... import`, `use ...`, or equivalent for a library not yet cited in this session
- About to call a new HTTP API endpoint
- About to use a CLI tool that has version-specific flags
- User asks "does library X support Y?" and the answer is not in the conversation history

Do NOT use for:
- Language built-ins (JS/TS `Array.map`, Python `dict`, etc.)
- Libraries already cited in this session with the same version

## Process

### Step 1: Resolve version

Before anything else, read the project's dependency manifest:

- `package.json` → `dependencies` + `devDependencies`
- `requirements.txt` or `pyproject.toml` → pinned versions
- `Cargo.toml`, `go.mod`, etc.

Record the exact version string. If the project has no pinned version yet, state that in the citation as `version: unpinned`.

### Step 2: Context7 lookup (primary)

Follow `skills/_vendored/context7/SKILL.md`:

```
/mcp context7 resolve-library-id "<library-name>"
/mcp context7 get-library-docs "<resolved-id>" --topic "<specific-api>"
```

If Context7 returns results for the required version:
- Extract the relevant snippet
- Proceed to Step 4

If Context7 has no coverage for the version (outdated by > 1 minor, or library not indexed):
- Proceed to Step 3

### Step 3: Web-search fallback

Use web search with queries like:
- `site:<official-docs-url> <api-name>`
- `<library-name> <version> <api-name> changelog`

Required: the source URL must be one of:
- The library's official documentation domain
- The library's GitHub repository (README, CHANGELOG, or source file)
- Published release notes

Reject as sources: blog posts, StackOverflow answers older than 1 year, AI-generated summaries.

### Step 4: Cite at the import site

When writing the code, include a single-line comment at or above the import / call site:

```ts
// Source: https://orm.drizzle.team/docs/column-types/pg (verified 2026-04-16, drizzle-orm@0.32.1)
import { pgTable, integer } from "drizzle-orm/pg-core";
```

Python:
```python
# Source: https://fastapi.tiangolo.com/tutorial/first-steps/ (verified 2026-04-16, fastapi==0.115.0)
from fastapi import FastAPI
```

The comment is the proof. Without it, the gate has not been passed.

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "The API is stable, I've used it for years" | Libraries break APIs. `verified YYYY-MM-DD` is proof, not trust. |
| "I'll add the citation later" | Later means never. Add it at the same commit as the import. |
| "Context7 didn't have the version, so I guessed" | Step 3 exists for this case. Guessing is the bug. |
| "It's a one-line call, citing is overhead" | One-line calls are the most common source of silent breakage. Cite. |

## Red Flags

- Writing `import` statement without reading any docs this session
- Citation URL is a blog or StackOverflow
- Citation has no version pinning
- Citation is copy-pasted from another file without re-verifying for current version
- Dependency manifest was not opened before citing

## Verification

For every PR / commit that touches code:

1. **Grep for citations**:
   ```bash
   git diff --staged -- '*.ts' '*.py' '*.js' | grep -c '^+.*Source: http'
   ```
   Number must equal the count of new `import` statements for external libraries in the diff.

2. **Spot-check one citation**: pick one Source URL from the diff. Open it. Confirm the API still exists and the signature matches.

3. **Version match**: the version in the comment must match the version in the dependency manifest.

If any check fails, do not commit. Add or fix citations.
