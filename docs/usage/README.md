# `docs/usage/` — Operational guides

Brief, action-oriented guides for operators of the `batuta-agent-skills` plugin. Each one is **a recipe with copy-pasteable commands**, not architectural prose.

For the **why** behind these recipes, see [`docs/PRD.md`](../PRD.md). For the **how it's built**, see [`docs/SPEC.md`](../SPEC.md). For per-decision rationale, see [`docs/adr/`](../adr/).

## Index

| Guide | When you need it |
|---|---|
| [`upgrading.md`](upgrading.md) | A new plugin version shipped to `main`. Your local cache is stale. You need new skills (e.g. `code-graph`) in your interactive session. |
| [`code-graph.md`](code-graph.md) | You want to use the dual-engine code knowledge graph in a repo (architecture questions, blast-radius audits). Includes how to apply it to old repos. |
| [`consumer-projects.md`](consumer-projects.md) | You're starting work on an existing repo (yours or a client's) that should adopt the plugin's conventions. Covers retrofit, rules import, doc skeleton. |
| [`ci.md`](ci.md) | You want to wire the static validators + E2E harness into a consumer repo's GitHub Actions. Includes the `ANTHROPIC_API_KEY` setup and the cost gate. |

## Conventions across all guides

- Commands are POSIX shell unless explicitly marked as PowerShell. On Windows, run from Git Bash.
- Paths use forward slashes. The plugin's bootstrap scripts normalize Windows backslashes internally.
- Plugin install path is referenced as `~/.claude/plugins/marketplaces/batuta-agent-skills/` (the marketplace clone). Tools live there; bootstrap scripts use the relative `tools/setup-*.sh` path.
- Where a guide says "your repo", it means a consumer project (a client codebase, your own work, etc.) — not the plugin repo itself.

## When in doubt

The plugin is **operator-side**. Almost everything you need is one or two `bash setup-*.sh` invocations. If a guide tells you to run a command, that command is idempotent and safe to re-run.

If a guide refers to a feature you don't recognize, check the [`CHANGELOG.md`](../../CHANGELOG.md) for the version that introduced it. If the feature is in `main` but not in your interactive session, the [`upgrading.md`](upgrading.md) guide explains the cache-staleness pattern.
