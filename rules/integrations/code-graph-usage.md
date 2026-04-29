---
title: Code knowledge graph usage
applies-to: ["any-language-with-imports", "regulated-data"]
last-reviewed: 2026-04-29
---

# Code knowledge graph usage

Architecture questions over a non-trivial codebase ("how does X work?", "what depends on Y?", "where is Z called?") are answered against a persisted graph, not by re-reading files. The plugin ships two engines (`graphify`, `codebase-memory-mcp`) and the `code-graph` skill governs which one is used. This rule defines the inviolable contract any consumer project agrees to when it imports the rule.

## Inviolable rules

1. Before answering any architecture, dependency, or large-refactor question, the agent runs the `code-graph` skill (Step 0 — engine selection). If neither engine is functional, the agent instructs `bash tools/setup-code-graph.sh` and stops; it does not improvise from `Glob` + `Grep`.
2. Every architectural claim made in a session that has consulted the graph cites either a graph node ID or a `file:line` reference. Claims without a source are rejected in code review.
3. Every answer that relied on the graph names the engine in brackets (`[via graphify]` or `[via codebase-memory-mcp]`). Mixing engines in one answer without naming each fact's source is a violation.
4. The `graphify claude install` command is never invoked, in any context — it modifies `.claude/settings.json` and the v2.7 kill-switch in `hooks/delegation-guard.sh` blocks it. Engine integration goes through `tools/setup-code-graph.sh` only.
5. Generated index artifacts (`graphify-out/`, `~/.cache/codebase-memory-mcp/`, or any `CBM_CACHE_DIR` override pointing inside the repo) are listed in the project `.gitignore`. They are never committed.

## Allowed patterns

```text
# Good — answer cites engine and sources
[via codebase-memory-mcp] The payment flow has three entry points:
  - api/checkout.py:42 (POST /checkout)
  - api/webhook.py:18 (POST /webhook/stripe)
  - workers/retry.py:73 (cron retry)
Top called modules from those entries: services/orders.py (12 paths),
services/inventory.py (5 paths). Source: trace_call_path tool with depth=4.
```

```text
# Good — answer flags graph staleness rather than ignoring it
[via graphify] graphify-out is 38 hours old and there are 4 commits since.
Re-running scan first. (Then: actual answer.)
```

```bash
# Good — engines installed via the bootstrap, not via upstream auto-config
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh
```

## Anti-patterns

**Mandatory section.**

```text
# Bad — violates rule 1 (architecture answer without consulting the graph)
"This codebase uses a pub/sub model with three queues" ← no node ID, no file:line, no engine cited
```

```text
# Bad — violates rule 2 (claim without source)
"The retry worker depends on the payments service." ← no file:line, no graph node
```

```text
# Bad — violates rule 3 (engine not named)
"There are two cycles between orders and inventory." ← which engine produced this? graphify or codebase-memory? unclear
```

```bash
# Bad — violates rule 4 (running graphify's auto-installer that edits settings.json)
graphify claude install
```

```text
# Bad — violates rule 5 (graphify-out committed)
$ git log --oneline graphify-out/
abc1234 feat: add graph snapshot   ← should never be committed
```

## Documented exceptions

- **Repos under 1,000 LOC**: rule 1 is relaxed. For very small codebases, re-reading is faster than indexing. The skill detects this and skips Step 2 with a note to the operator.
- **Strict-NDA projects** that explicitly opt out of multimodal extraction (graphify sends `*.md`, `*.pdf`, and image content to the project's LLM provider): such projects declare `code-graph-engine: codebase-memory` in their project-level `CLAUDE.md`. Rule 1 then forces the code-only fallback engine even when graphify is `OK`. Rules 2, 3, 4, and 5 still apply.
- **Audit chain subagents** (`code-reviewer`, `security-auditor`, `test-engineer`): when the diff is empty (NOT-APPLICABLE in their Step 0), they do not need to consult the graph. Rule 1 fires only when there is a diff or an architecture question to answer.
