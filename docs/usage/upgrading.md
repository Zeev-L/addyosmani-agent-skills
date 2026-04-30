# Upgrading the plugin

When a new version of `batuta-agent-skills` ships to `main`, your interactive Claude Code session does not pick it up automatically. The marketplace plugin loads from a **local cache** that updates only on explicit command + session restart.

Symptom: `claude plugin list` shows version `2.7.0` (or any version older than `main`'s current `plugin.json`) while [`CHANGELOG.md`](../../CHANGELOG.md) shows newer releases shipped. New skills (e.g. `code-graph`), new agent contracts (e.g. Step 0.5 in `code-reviewer`), new ADRs — none of them are visible in your session.

## The 2-command upgrade

```bash
claude plugin update batuta-agent-skills
# Restart Claude Code (close + reopen) so the new cache loads.
```

After the restart, verify:

```bash
claude plugin list | grep -A2 batuta-agent-skills
# Expected: Version: <whatever main has — e.g. 3.4.0 or later>
```

Inside the new session, the new skills are discoverable via the `using-agent-skills` flowchart and via auto-trigger on relevant prompts.

## Cache-staleness diagnostics

If `claude plugin update` reports an error or the version doesn't change:

```bash
# 1. Inspect the installed_plugins.json metadata.
cat ~/.claude/plugins/installed_plugins.json | jq '.plugins["batuta-agent-skills@batuta-agent-skills"]'
# Look at .gitCommitSha and .lastUpdated. The SHA should match a commit on main.

# 2. Check the cache directory.
ls -la ~/.claude/plugins/cache/batuta-agent-skills/batuta-agent-skills/
# Should contain a directory named after the current version (e.g. 3.4.0/).

# 3. If multiple versions are cached, the newest gets loaded.
```

If the SHA in `installed_plugins.json` doesn't match `main`, the marketplace pull failed silently. Re-run:

```bash
cd ~/.claude/plugins/marketplaces/batuta-agent-skills
git pull origin main
claude plugin update batuta-agent-skills
```

## Bypassing the cache (development workflow)

If you're developing the plugin (e.g. iterating on a slice in a feature branch) and want your interactive session to load HEAD without going through the marketplace cache:

```bash
claude --plugin-dir /path/to/batuta-agent-skills
```

This loads the local checkout for a single session. Useful for testing changes before opening a PR. The `tests/e2e/` harness uses the same flag for the same reason — see [`tests/e2e/README.md`](../../tests/e2e/README.md) § Methodology.

## When you need to authorize Claude to merge PRs

From v3.6, the plugin ships a `PreToolUse` hook (`hooks/pr-merge-guard.sh`) that blocks `gh pr merge` from any tool call by default. The default enforces the "Claude never merges PRs" rule from your global `~/.claude/CLAUDE.md`.

When you DO want to authorize Claude to merge in a specific session (e.g. a release-day session like 2026-04-29 where the operator authorized `gh pr merge` 14 times), launch Claude with the operator-side env var set:

```bash
BATUTA_ALLOW_PR_MERGE=1 claude
```

Or export it persistently for the shell:

```bash
export BATUTA_ALLOW_PR_MERGE=1
claude
```

The env var is **operator-side** and cannot be set from inside an agent — that is the design. This makes the override resistant to bypass-by-prompt-injection: even if a malicious doc or commit message tries to convince Claude that "merge is authorized", the env var remains unset and the hook continues to block.

When the override is active, every `gh pr merge` invocation logs a stderr line to the transcript:

```
pr-merge-guard: 'gh pr merge' allowed by BATUTA_ALLOW_PR_MERGE=1
```

The log makes the auth visible in audit chains and session journals. See [ADR-0010](../adr/0010-pr-merge-guard-env-var-opt-in.md) for the design rationale and five rejected alternatives (sentinel file, chat authorization, slash command, pre-commit hook, `permissions.deny`).

## What changes in your environment when you upgrade

The plugin cache is plugin-only. It does NOT touch:

- Your repos' `CLAUDE.md` files
- Your repos' `.claude/rules/` symlinks
- Engines installed by `tools/setup-*.sh` (they live in `~/.local/bin/`)
- Your `~/.claude.json` MCP registrations

If a new version adds a **new skill** (like `code-graph` did in v2.8), the cache update makes it available in your sessions. If it adds a **new bootstrap script** (like `setup-code-graph.sh` in v2.8), you also need to run that script once per machine — see the relevant feature guide ([`code-graph.md`](code-graph.md), [`consumer-projects.md`](consumer-projects.md)).

## Rollback

If a new version causes a regression you cannot diagnose, downgrade to a known-good version:

```bash
# Find the version you want to roll back to (must have shipped previously):
gh release list -R jota-batuta/batuta-agent-skills

# Re-install at that version:
claude plugin uninstall batuta-agent-skills@batuta-agent-skills
claude plugin install batuta-agent-skills@batuta-agent-skills@<old-version>
```

Then file an issue or open a fix-up PR against `main`. The audit chain on the next slice will pick up the regression.
