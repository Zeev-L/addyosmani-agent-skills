---
name: reference_paths
description: Where things live on this machine — plugin install path, project dirs, plans/sessions conventions
type: reference
---

# Filesystem map — jota-batuta machine

## Plugin install (Claude Code 2.x marketplace)

```
~/.claude/plugins/marketplaces/batuta-agent-skills/    ← canonical install path
                                                       (used in setup-rules.sh, hook references,
                                                        and the @<path> imports from project CLAUDE.md
                                                        via .claude/rules/ symlinks)
```

The plugin's own `${CLAUDE_PLUGIN_ROOT}` env var resolves here at runtime, BUT only inside hooks (`hooks.json`). It does NOT expand inside CLAUDE.md `@<path>` imports. The official cross-developer pattern is symlinks `.claude/rules/<rule>.md` → `<plugin>/rules/<rule>.md`, then import via `@.claude/rules/<rule>.md` (project-relative).

## User-level config

```
~/.claude/CLAUDE.md          ← user-global rules (loaded at every session start)
~/.claude/MEMORY.md          ← user-global memory index (this file's index)
~/.claude/memory/            ← user-global memory entries (user|feedback|reference type)
~/.claude/settings.json      ← settings (NEVER edited by main per Rule #0; .claude/* is whitelisted but settings*.json is killswitch-blocklisted)
~/.claude/plans/             ← persisted plans across sessions (one active per branch)
~/.claude/projects/          ← per-project sessions, transcripts, memory
```

## Working tree (paths abstracted for public backup)

```
<projects-root>/batuta-agent-skills/   ← THIS plugin's repo (jota-batuta/batuta-agent-skills, public)
~/test-delegation-2026-04-26/          ← synthetic E2E test project (preserved post-test)
```

(Per-client and per-project paths are intentionally NOT enumerated here — see the operator's project inventory in `~/.claude/projects/`. The `<projects-root>` placeholder resolves to the actual drive/folder on the operator's machine; that mapping is local-only and not part of the public backup.)

## Backups

- `~/.claude.surgery-2026-04-26.bak/` — full snapshot before the cirugía (retain 7 days = until 2026-05-03)
- `~/Documents/claude-archive/<legacy-plugin-snapshot-2026-04-17>.tar.gz` — legacy plugin snapshot tarballed during 2026-04-26 cleanup (filename contains the specific plugin name; redacted here for the public backup)
- `~/.claude/archive/2026-04-26/` — settings.json.bak older than 2026-04-01 + temporal project shells

## Per-project memory in this plugin

```
~/.claude/projects/e--BATUTA-PROJECTS-batuta-agent-skills/memory/MEMORY.md  ← this project's index
~/.claude/projects/e--BATUTA-PROJECTS-batuta-agent-skills/memory/<entries>  ← project-scoped memories
```

## In-repo plan and session conventions

```
<projects-root>/batuta-agent-skills/docs/plans/active/<YYYY-MM-DD>-<slug>.md
                                    /docs/plans/archive/...
                                    /docs/sessions/<YYYY-MM-DD>-<slug>.md
```

`Next:` line at the end of each session journal is the entry point for the next session.
