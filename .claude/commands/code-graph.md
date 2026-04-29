---
description: Build or query the code knowledge graph using whichever engine is available (graphify or codebase-memory-mcp). Operator-invoked complement to the auto-trigger code-graph skill.
---

You will run a code-graph operation against the active engine (graphify or codebase-memory-mcp), respecting the operator's explicit `--engine` override if given. This is the manual counterpart to the `code-graph` skill — invoked by the operator via `/code-graph <args>` for explicit control.

`$ARGUMENTS` may contain (in any order, with sensible defaults):

- A path: `<path>` (default `.`)
- `--scan` (default action — index the path one-shot)
- `--watch` (daemon mode — graphify uses `--watch`, codebase-memory-mcp uses `auto_index true`)
- `--mcp` (graphify only — stand up the MCP server; codebase-memory-mcp is already MCP)
- `--query "<expr>"` (run a query against the active index — see Step 5 for engine-specific tool dispatch)
- `--engine graphify|codebase-memory` (override engine selection)

If `$ARGUMENTS` is empty: equivalent to `--scan .`.

## Steps

1. **Verify engines** (Bash):

   ```bash
   bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/check-code-graph-engines.sh
   ```

   If exit code is 2 (state file missing) or 1 (both engines `MISSING|BROKEN`): instruct the operator to run `bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh` and stop. Do not improvise.

2. **Resolve engine**:

   - If `--engine <name>` is in `$ARGUMENTS`, use that name. Verify the requested engine's status is `OK` via `--field <engine>.status`. If not OK, abort with: "Operator requested engine `X` but its status is `Y`. Run setup-code-graph.sh or pick the other engine."
   - Otherwise, take `--field best` from `check-code-graph-engines.sh` as the chosen engine.
   - Echo the choice to the operator: `Using engine: <name>`.

3. **Ensure ignore entries** (idempotent):

   - For graphify: ensure `.gitignore` contains `graphify-out/`. If absent and the file is tracked, append it via `Edit` or `Bash echo`.
   - For codebase-memory-mcp: the cache lives at `~/.cache/codebase-memory-mcp/` (outside the repo) — no `.gitignore` change needed unless `CBM_CACHE_DIR` was overridden into the repo, in which case ignore that path.

4. **Dispatch the action**:

   - **`--scan`** (default):
     - graphify: `graphify <path>` (synchronous, foreground) — verify `graphify-out/GRAPH_REPORT.md` exists after.
     - codebase-memory-mcp: invoke MCP tool `index_repository` with the path. Wait for completion, then call `index_status` to confirm.

   - **`--watch`**:
     - graphify: `graphify <path> --watch` with `run_in_background: true`. Capture the PID, write to `.graphify.pid` in the project, and tell the operator how to stop it (`kill $(cat .graphify.pid)`).
     - codebase-memory-mcp: run `codebase-memory-mcp config set auto_index true`. The watcher is internal to the server; no PID to manage. Tell the operator to disable with `codebase-memory-mcp config set auto_index false`.

   - **`--mcp`** (graphify only — codebase-memory is already an MCP server):
     - graphify: `graphify <path> --mcp` with `run_in_background: true`. Confirm the server is reachable.
     - codebase-memory: emit "codebase-memory-mcp is always running as an MCP server; this flag is a no-op for that engine."

   - **`--query "<expr>"`**:
     - graphify: parse `graphify-out/GRAPH_REPORT.md` for the query, or — if the graphify MCP server is up — call its tools (`query_graph`, `get_node`, `get_neighbors`, `shortest_path`).
     - codebase-memory-mcp: dispatch to the matching MCP tool based on intent:
       - "find symbol X" → `search_graph` or `search_code`
       - "what calls X" / "what does X call" → `trace_call_path`
       - "high-level architecture" → `get_architecture`
       - "show the code at <path:line>" → `get_code_snippet`
       - "list all projects indexed" → `list_projects`

5. **Confirm to the operator**: print a one-line summary including the engine used and the path/result. Format:

   ```
   Done via <engine>. Output: <path-or-tool-call-result>.
   ```

## Constraints

- The slash command never edits `.claude/settings.json`. The kill-switch v2.7 in `hooks/delegation-guard.sh` would block it anyway, but the command should not even attempt it. If the operator's intent appears to require that, refuse and explain.
- Do NOT invoke `graphify claude install` under any circumstances. If the operator types something that maps to that command, refuse and point to `tools/setup-code-graph.sh`.
- Do NOT auto-install. Installation is the responsibility of `tools/setup-code-graph.sh`, run by the operator. If a needed engine is missing, instruct re-bootstrap, do not call the installer from here.
- For `--watch` and background `--mcp`, the operator owns lifecycle. Always emit the stop command in your confirmation.

## Why this is a slash command and not just a skill

The skill (`skills/code-graph/SKILL.md`) auto-triggers when Claude detects an architecture question. The slash command exists for two cases the skill does not cover well:

1. **Operator wants explicit control**. Background daemons, engine overrides, or a one-shot scan that the operator wants triggered now (not on next architecture question).
2. **Imperative invocation in shell-like flow**. `/code-graph --watch ./src` is a clearer affordance than relying on description-matching.

Both paths converge on the same engine state and the same kill-switch discipline.
