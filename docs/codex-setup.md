# Using agent-skills with Codex

## Setup

Codex supports local plugins through either a repo-scoped marketplace or a personal marketplace.
This guide uses the personal marketplace path by default, so the repo does not need to commit
workspace-specific `.agents/` metadata.

### 1. Clone the repository

```bash
git clone https://github.com/addyosmani/agent-skills.git
cd agent-skills
```

### 2. Run the installer

```bash
./.codex/scripts/install-plugin.sh
```

This does four things:

1. Builds a personal plugin bundle at `~/.codex/plugins/agent-skills`
2. Generates fresh wrapper skills inside that personal plugin bundle
3. Updates `~/.agents/plugins/marketplace.json` to point Codex at that generated plugin directory
4. Registers the personal marketplace and plugin in `~/.codex/config.toml`

### 3. Finish installation in Codex

1. Fully quit Codex, then start it again
2. Open `/plugins`
3. Choose your personal marketplace
4. Install or reinstall `agent-skills`
5. Start a new thread

If you are using the Codex CLI, fully stop the running `codex` process and start a fresh terminal
session. In practice, opening a new prompt in an already-running session is not always enough for
new marketplace entries to appear.

## What Gets Installed

- Plugin template in this repo: `.codex/plugin/`
- Codex-only wrapper skills in this repo: `.codex/plugin/skills/`
- Generated personal plugin root: `~/.codex/plugins/agent-skills`
- Generated plugin manifest: `~/.codex/plugins/agent-skills/.codex-plugin/plugin.json`
- Generated plugin skills: `~/.codex/plugins/agent-skills/skills/`
- Generated plugin references: `~/.codex/plugins/agent-skills/references/`
- Generated plugin agents: `~/.codex/plugins/agent-skills/agents/`
- Personal marketplace entry: `~/.agents/plugins/marketplace.json`
- Codex marketplace/plugin registration: `~/.codex/config.toml`

The repository only keeps the Codex-specific wrappers under `.codex/plugin/skills/`. The
installer assembles the final personal plugin by combining:

- the shared skills from `skills/`
- the shared reference docs from `references/`
- the shared agent personas from `agents/`
- freshly generated Codex-only wrappers based on `.claude/commands/`

Codex then loads from that generated personal plugin directory and may also cache the plugin under
`~/.codex/plugins/cache/...`.

## Usage

The plugin identifier is `agent-skills`, so bundled skills can be invoked under the
`agent-skills:*` namespace.

Common examples:

- `@agent-skills:spec` — Start spec-driven development from the compatibility alias
- `@agent-skills:plan` — Break work into tasks with acceptance criteria
- `@agent-skills:build` — Run the build workflow alias for incremental implementation
- `@agent-skills:test` — Run the test workflow alias
- `@agent-skills:review` — Run the review workflow alias before merge
- `@agent-skills:ship` — Run the pre-launch checklist
- `@agent-skills:code-simplify` — Run the simplification workflow alias

You can also reference the original long-form skills directly when that is more precise.

## Troubleshooting

### The plugin does not appear in `/plugins`

- Fully quit Codex after adding or changing a marketplace file, then start it again
- If you are using the Codex CLI, close the terminal window or stop the existing `codex` process
  and start a fresh terminal session
- Confirm the personal marketplace exists at `~/.agents/plugins/marketplace.json`
- Confirm `~/.codex/config.toml` contains both:
  - a `[marketplaces.<name>]` entry for the personal marketplace
  - a `[plugins."agent-skills@<name>"]` entry with `enabled = true`
- Validate that the marketplace entry points at `./.codex/plugins/agent-skills`
- Confirm `~/.codex/plugins/agent-skills/.codex-plugin/plugin.json` exists

### A command alias looks stale after editing `.claude/commands`

The wrapper set is generated. Re-run:

```bash
python3 .codex/scripts/sync-wrapper-skills.py
./.codex/scripts/install-plugin.sh
```

To verify the generated wrappers without installing:

```bash
python3 .codex/scripts/sync-wrapper-skills.py --check
```

### Why generate `~/.codex/plugins/agent-skills` at all?

Codex expects a self-contained plugin directory. Keeping only the wrappers in the repo avoids
maintaining two full copies of the shared skills in version control, while still producing the
complete plugin bundle Codex needs at install time. The installer builds that bundle without
modifying the repo-tracked wrapper files.

## Advanced: Repo-Scoped Marketplace

OpenAI's official docs also support a repo-scoped marketplace at
`$REPO_ROOT/.agents/plugins/marketplace.json`.

If you specifically want that workflow, follow the official docs and point the marketplace entry at
a repo-local plugin directory of your own. This repository does not generate or commit a
repo-scoped plugin directory by default, because it is workspace-specific metadata and not required
for the personal install flow documented above.

## References

- [Codex plugins overview](https://developers.openai.com/codex/plugins)
- [Build Codex plugins](https://developers.openai.com/codex/plugins/build)
