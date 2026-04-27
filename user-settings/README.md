# user-settings

Backup of user-level configuration for `jota-batuta`. Stored in this repo so the files survive machine changes and can be reviewed alongside the skills they reference.

Two artifact families backed up here:

| Backup | Real location | Purpose |
|---|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | User-global rules loaded at every Claude Code session start (Rule #0, conventions, mandatory skills, session-handoff protocol) |
| `MEMORY.md` + `memory/*.md` | `~/.claude/MEMORY.md` + `~/.claude/memory/*.md` | User-global persistent memory entries: operator profile, feedback patterns, references |

## How to restore on a new machine

```bash
mkdir -p ~/.claude/memory
cp user-settings/CLAUDE.md ~/.claude/CLAUDE.md
cp user-settings/MEMORY.md ~/.claude/MEMORY.md
cp -r user-settings/memory/* ~/.claude/memory/
```

After restore, open Claude Code and the user-level rules + memory load automatically on the next session.

## How to keep in sync

When you edit `~/.claude/CLAUDE.md` or any `~/.claude/memory/<file>.md` on any machine, copy the result back into this folder and commit:

```bash
# Sync CLAUDE.md
cp ~/.claude/CLAUDE.md user-settings/CLAUDE.md

# Sync memory (overwrite all entries; faster than per-file)
cp ~/.claude/MEMORY.md user-settings/MEMORY.md
cp ~/.claude/memory/*.md user-settings/memory/

# Stage and commit
git add user-settings/
git commit -m "chore(user-settings): sync user-level config and memory"
git push
```

Sync is **manual**. If you forget, the backup drifts from the real file. Symptom of drift: a memory entry referenced in `~/.claude/MEMORY.md` does not exist in `user-settings/memory/`, or a real-file edit (e.g. adding Rule #0 to `~/.claude/CLAUDE.md`) does not appear in `user-settings/CLAUDE.md`. Fix: re-run the sync block above.

## Scope

This folder is for **user-level** configuration — things that apply to every project on every machine the operator uses.

- **Project-specific rules** live in each project's own `./CLAUDE.md` and never here
- **Project-specific memory** lives in `~/.claude/projects/<project>/memory/MEMORY.md` and the entries next to it; that is project-scoped state and does NOT belong in this user-level backup
- **Plugin-shipped rules** live in `<plugin>/rules/` and have their own `_meta/how-to-import.md` consumer protocol

## Sanitization commitment

This folder is committed to a PUBLIC repo (`jota-batuta/batuta-agent-skills`). Memory entries here MUST be sanitized of:

- Specific Batuta client names
- Specific CO-vendor names that imply a commercial relationship (DIAN, Bancolombia, BBVA, Bold)
- Specific internal project names with sensitive context

The user-level memory entry `feedback_sanitize_public_repos.md` documents the rule. Before any commit to this folder, grep the diff for client/vendor names and abstract them. The original `~/.claude/memory/<file>.md` may carry the same content as the backup since both are operator-readable, OR may carry a less-sanitized version locally with the public backup carrying the abstracted form. Today the two are identical (sanitized at source).

## When to NOT back up to this folder

- Anything that contains an actual secret (`.env` content, API keys, tokens) — those NEVER go in any committed file, regardless of repo visibility
- Per-project memory entries (use `~/.claude/projects/<project>/memory/`)
- Single-machine state that does not survive machine changes (e.g. session locks, scheduled tasks state)
