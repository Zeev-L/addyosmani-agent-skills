# Code-graph: dual-engine setup

The `code-graph` skill (shipped in v2.8, hardened in v2.9 + v3.1, integrated with the audit chain in v3.0) lets the agent consult a persisted graph of your codebase instead of doing rounds of `Glob` + `Grep` + `Read` over dozens of files. This guide covers what it does, how to install the engines, and how to apply it to old repos.

For the **why** and **architecture**, see [ADR-0007](../adr/0007-code-graph-dual-engine.md) and [ADR-0008](../adr/0008-audit-chain-code-graph-integration.md).

## What it does

Two engines, picked per question:

- **graphify** ([github.com/safishamsi/graphify](https://github.com/safishamsi/graphify)) — multimodal: code (25 languages via tree-sitter) + docs + PDFs + images + audio (Whisper local). Primary engine when functional.
- **codebase-memory-mcp** ([github.com/DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)) — code-only, native C MCP server, 99% token reduction reported. Fallback engine. Critical on Windows where graphify currently has open install issues.

The skill auto-triggers on prompts about architecture, dependencies, blast radius, refactor scope, onboarding. Two auditors (`code-reviewer`, `security-auditor`) consult the graph in their **Step 0.5** for blast-radius / attack-surface enumeration on every diff. `test-engineer` is intentionally NOT consulting the graph (scope guard, see ADR-0008).

## Why there's NO per-repo retrofit

Unlike `batuta-project-hygiene` (which scaffolds `CLAUDE.md`, `docs/`, `.claude/rules/` files inside each repo), code-graph **does not insert any files into the consumer repo**. Its components live in 3 separate places:

| Layer | Where | Setup frequency |
|---|---|---|
| Skill, slash, rule | `~/.claude/plugins/cache/...` | Comes with `claude plugin install/update` |
| graphify CLI + codebase-memory-mcp binary | `~/.local/bin/` and `~/.claude.json` | **1 time per machine** via `setup-code-graph.sh` |
| Per-repo graph cache | `<repo>/graphify-out/` or `~/.cache/codebase-memory-mcp/` | Auto-generated on first architecture question |

So for old repos: there's nothing to retrofit. **Run the bootstrap once, every old repo can use it.**

## Bootstrap (1 time per machine)

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh
```

This installs:

1. `graphifyy==0.5.4` via uv > pipx > pip (operator-side, Python 3.10+)
2. `codebase-memory-mcp` v0.6.0 binary, downloaded from the pinned GitHub Release, SHA-256 verified against the release's signed `checksums.txt`, and provenance-attested via `gh attestation verify` if `gh` CLI is authenticated (graceful-degrade otherwise).
3. MCP server registration via `claude mcp add --scope user --transport stdio codebase-memory -- <binary>`. Writes to `~/.claude.json` — outside the v2.7 kill-switch.

State persists at `~/.claude/code-graph-engines.json`. Re-running the script is idempotent.

## Verify the install

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/check-code-graph-engines.sh
# Expected: graphify=OK + codebase-memory-mcp=OK + best=graphify
# (or graphify=BROKEN on Windows — codebase-memory-mcp takes over automatically)
```

## Use it in any repo (old or new)

After the bootstrap is done, **no per-repo setup is required**. Open Claude Code in the repo, ask an architecture question:

```
> explain the architecture of this repo
> where is process_payment called from?
> what depends on the auth service?
```

The skill auto-triggers, picks the engine, runs `--scan` if no graph exists, and answers citing `[via graphify]` or `[via codebase-memory-mcp]`. The graph cache is generated once per repo (and incrementally updated on watch mode).

For explicit control:

```
> /code-graph                      # one-shot scan
> /code-graph --watch ./src        # daemon mode (graphify) or auto_index true (codebase-memory)
> /code-graph --query "callers of process_payment"
> /code-graph --engine codebase-memory  # override the heuristic, force fallback engine
```

## Optional: import the rule into a consumer repo

If you want the project's `CLAUDE.md` to formally adopt the code-graph contract (citing the engine in answers, not committing `graphify-out/`, etc.), import the rule:

```bash
cd /path/to/your-repo
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --rule integrations/code-graph-usage
```

This creates a symlink at `<your-repo>/.claude/rules/code-graph-usage.md` and instructs you to add `@.claude/rules/code-graph-usage.md` to the project's CLAUDE.md.

Or run `--all` to get every rule in one go (includes `code-graph-usage` plus the universal core rules):

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --all
```

`--all` also chains into `setup-code-graph.sh` automatically (idempotent — does nothing if engines are already installed). So this single command covers both rule import AND engine bootstrap.

## NDA-strict projects: force code-only engine

If a client project's contract forbids sending docs/images to an LLM (graphify's multimodal path uses the project's LLM provider for `*.md`, `*.pdf`, images), declare in that project's `CLAUDE.md`:

```yaml
code-graph-engine: codebase-memory
```

The skill's Step 0 reads this and forces the code-only fallback engine, even when graphify is healthy. graphify's tree-sitter AST pass (code-only) and codebase-memory-mcp are 100% local — no LLM calls — so they are safe under NDA.

## Common pitfalls

| Symptom | Diagnosis | Fix |
|---|---|---|
| Skill not auto-triggering | Plugin cache is stale (still on a pre-v2.8 version) | Run [`upgrading.md`](upgrading.md) — `claude plugin update batuta-agent-skills` + restart |
| `code-graph-engines.json` missing | Bootstrap never ran on this machine | Run `bash setup-code-graph.sh` once |
| Skill says both engines BROKEN | Network failure during install OR Windows graphify install issues | Re-run bootstrap; on Windows, accept `graphify=BROKEN` and let codebase-memory-mcp take over |
| `graphify-out/` showing in git status | Auto-`.gitignore` step didn't fire | Add `graphify-out/` to your repo's `.gitignore` manually |
| Different model gives different answers | Graph is stale (commits after last scan) | Re-run `/code-graph --scan` or enable watch mode |

## Forbidden pattern (kill-switch v2.7)

**Never** run `graphify claude install`. The upstream auto-installer modifies `.claude/settings*.json` to inject a PreToolUse hook, which is on the v2.7 kill-switch. The skill, slash, rule, and validator 07 all enforce this prohibition. The plugin's setup script gives you the same end-result (working code-graph in your sessions) without touching settings.json.
