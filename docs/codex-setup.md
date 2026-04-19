# Using agent-skills with Codex

This repository is also a [Codex plugin](https://developers.openai.com/codex/plugins/build). The same `skills/` directory used by Claude Code is consumed by Codex — no files are copied or duplicated.

## Install (one command)

```bash
codex marketplace add addyosmani/agent-skills
```

Codex clones the repo into `~/.codex/plugins/agent-skills/`, registers the marketplace in `~/.codex/config.toml`, and makes the plugin available. Restart Codex if it's already running.

Local clones work too:

```bash
codex marketplace add /path/to/your/clone
```

## Usage

After install, invoke a skill in Codex chat with `@` (e.g. `@spec-driven-development`) or just describe the task and let Codex pick the right skill. All 21 skills under `skills/` are available.

## How it works

- `codex/.codex-plugin/plugin.json` — Codex plugin manifest. Points `skills` at `./skills/`.
- `codex/skills` — git-tracked symlink to `../skills` (9 bytes, mode `120000`). Keeps the plugin directory self-contained without duplicating the skills themselves. macOS and Linux handle this natively.
- `.agents/plugins/marketplace.json` — marketplace entry declaring the plugin at `./codex`. Codex requires plugins to live in a subdirectory of the marketplace root.
- `skills/<name>/SKILL.md` — unchanged. Codex and Claude Code share the same `name` + `description` frontmatter format, so one file serves both platforms.

Slash commands in `.claude/commands/` and personas in `agents/` stay Claude Code-specific — Codex has no native equivalent for either. On Codex, invoke the underlying skill directly instead of the slash command (e.g. `@spec-driven-development` instead of `/spec`).

## No symlinks (Windows or personal preference)

If symlinks don't work on your machine, replace the symlink with a real copy of the skills inside the plugin directory. Run this from the repo root after cloning:

```bash
rm codex/skills
cp -R skills codex/skills
```

This is a **local-only** change — don't commit it. The upstream repo keeps the symlink so `codex marketplace add addyosmani/agent-skills` stays a one-liner for everyone else.
