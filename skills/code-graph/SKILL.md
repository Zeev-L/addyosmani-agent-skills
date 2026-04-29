---
name: code-graph
description: Use to build or query a code knowledge graph before answering architecture, onboarding, or large-refactor questions. Auto-triggers when the operator asks about repo structure, dependencies, module relationships, or wants to understand a codebase quickly. Internally selects between graphify (multimodal, primary) and codebase-memory-mcp (code-only, fallback). Four modes — scan, watch, mcp, query.
---

# Code Graph

## Overview

**Re-reading the repo every time is the most expensive way to answer architecture questions.** When the operator asks "what does this repo do", "where is X called", "what depends on Y", or "explain this codebase", the cheapest correct answer comes from a persisted graph of the codebase — not from another round of `Glob` + `Grep` + `Read`.

This skill governs the use of two external engines that build and serve such a graph:

- **graphify** — multimodal (code + docs + PDFs + images), Python CLI, primary engine.
- **codebase-memory-mcp** — code-only, MCP server, fallback engine. Critical on Windows where graphify currently has open install issues.

The skill is engine-agnostic. It reads the cached engine state (written by `tools/setup-code-graph.sh`) and dispatches to whichever engine is functional and best suited for the question.

The skill does NOT install anything. Installation is operator-side via `tools/setup-code-graph.sh`. If both engines are missing, this skill instructs re-bootstrap and stops.

**Hard constraint**: this skill never causes an edit to `.claude/settings*.json`. The upstream `graphify claude install` command would do that and is therefore forbidden — see Red Flags.

## When to Use

Auto-trigger on any of:

- Operator asks an architecture question: "explain this repo", "what depends on X", "where is Y called", "find god-modules", "find circular dependencies", "are there cycles", "what's the module map".
- Operator starts onboarding into an unfamiliar codebase (> 5k LOC).
- Operator initiates a large refactor that crosses modules.
- A subagent in the audit chain (`code-reviewer`, `security-auditor`) requests a call-graph snapshot to evaluate a diff.

Do NOT use for:

- Trivial single-file edits.
- Questions about code the operator has just pasted into the conversation.
- Repos < 1k LOC where re-reading is faster than indexing.

The four user-facing modes:

| Mode | Operator intent | With graphify | With codebase-memory-mcp |
|---|---|---|---|
| `--scan` | First time in this repo, or index missing/stale | `graphify .` → `graphify-out/` | tool MCP `index_repository` → `~/.cache/codebase-memory-mcp/` |
| `--watch` | Long refactor session, keep index fresh | `graphify ./src --watch` (background daemon) | `codebase-memory-mcp config set auto_index true` (built-in watcher) |
| `--mcp` | Need structured queries (paths, neighbors) | `graphify ./src --mcp` (stand up server) | already running — codebase-memory-mcp is natively MCP |
| `--query` | Index is fresh, just need an answer | parse `graphify-out/GRAPH_REPORT.md` or call graphify MCP tools | call MCP tools `search_graph`, `query_graph`, `trace_call_path`, `get_architecture`, `get_code_snippet` |

## Process

### Step 0 — Engine selection (ALWAYS FIRST)

Read the cached state with `tools/check-code-graph-engines.sh`:

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/check-code-graph-engines.sh --field best
```

The output is one of `graphify`, `codebase-memory`, or `none`.

- If `none`: instruct the operator to run `bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh` and STOP. Do not attempt analysis blind.
- If a single engine is OK: use it.
- If both are OK: prefer the engine that matches the question shape:
  - Multimodal hint (PDFs in `docs/`, images in scope, "what does the RFC say", "diagram"): prefer **graphify**.
  - Pure code (call graph, definitions, usages, cycles, "where is X called"): prefer **codebase-memory-mcp** — faster and more precise for that shape.
- Operator override via `--engine graphify` or `--engine codebase-memory` (slash command flag) precedes any heuristic.

State which engine you picked and why in one short sentence to the operator before proceeding.

### Step 1 — Detect freshness

For graphify:

- Check `graphify-out/GRAPH_REPORT.md` mtime. If absent → recommend `--scan` first.
- If `git log --since="$(stat -c %y graphify-out/GRAPH_REPORT.md)"` is non-empty → graph is stale; recommend `--scan` first.

For codebase-memory-mcp:

- Call MCP tool `index_status` for the current project. If not indexed, or `last_indexed_at` is older than the latest commit on the active branch → recommend `--scan`.

If the operator says "go anyway with the stale graph", proceed with a caveat in the answer ("graph is N hours old; recent commits not yet reflected").

### Step 2 — Run

Invoke the chosen mode against the chosen engine. For background modes (`--watch`, `--mcp`), confirm the process started and report PID or status. For one-shot modes (`--scan`, `--query`), wait for completion and verify the expected artifact (graphify-out/ for graphify; index_status for codebase-memory-mcp).

### Step 3 — Read, don't dump

Synthesize the answer for the operator. Always include:

1. The motor used: `[via graphify]` or `[via codebase-memory-mcp]`.
2. Top findings (god-nodes, modules, cycles, hot paths) — at most 5 bullets.
3. Source pointers (file:line or graph node IDs) so the operator can click through.

Do NOT paste raw `graph.json`, raw `GRAPH_REPORT.md`, or raw MCP tool output. Context is finite.

### Step 4 — Cite the graph

Every architectural claim made in the rest of the session must reference either:

- A node in the graph (with the node ID or the `file:line`), or
- A direct quote from `GRAPH_REPORT.md` with the section name.

If a claim cannot be cited from the graph, fall back to reading the file directly — and note that in the answer ("graph did not cover this; read directly from `<path>:<line>`").

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "Graphify failed, no graph possible" | False. The fallback engine codebase-memory-mcp covers most pure-code questions. Check Step 0. |
| "The graph is stale but the answer is the same" | False by construction if there were commits. Re-scan or warn the operator. |
| "I'll just `Glob` + `Grep` + `Read`, it's faster" | Only true under ~1k LOC. Above that, the graph wins both on tokens and on completeness. |
| "I'll run `graphify claude install` once, then the graph is automatic" | Forbidden. That command writes to `.claude/settings.json` and the v2.7 kill-switch will block it. The plugin's bootstrap and skill replicate the useful behavior without touching settings. |
| "Both engines look broken; let me write my own AST scanner" | No. Re-bootstrap. We do not maintain a third engine. |

## Red Flags

- Running `graphify claude install` (kill-switch violation; the bootstrap script never invokes it).
- Editing `.claude/settings.json` to register a hook for graphify.
- Skipping Step 0 and assuming an engine is available.
- Pasting raw `graph.json` or full `GRAPH_REPORT.md` into the chat.
- Committing `graphify-out/` or `~/.cache/codebase-memory-mcp/` to git.
- Mixing engines in one answer without naming which engine produced which fact.
- Answering an architecture question without running Step 0 because "I already know this codebase".

## Verification

For graphify-engined runs:

```bash
test -f graphify-out/GRAPH_REPORT.md
jq '.nodes | length' graphify-out/graph.json     # > 0
git check-ignore graphify-out/                    # exit 0 → ignored
```

For codebase-memory-mcp-engined runs:

- `claude mcp list | grep -q '^codebase-memory'` (registered).
- An MCP `index_status` call returns a non-empty payload for the current project.
- A test query against `search_graph` with a known symbol returns at least one match.

For both:

- The answer to the operator names the engine in brackets (`[via ...]`).
- Every architectural claim cites a node ID or `file:line`.

If any check fails, do not deliver the answer. Re-run the relevant step or escalate to the operator.
