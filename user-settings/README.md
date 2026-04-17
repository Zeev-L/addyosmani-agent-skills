# user-settings

Backup of the user-level `~/.claude/CLAUDE.md` for `jota-batuta`. Stored in this repo so the file survives machine changes and can be reviewed alongside the skills it references.

## How to restore on a new machine

```bash
mkdir -p ~/.claude
cp user-settings/CLAUDE.md ~/.claude/CLAUDE.md
```

## How to keep in sync

When you edit `~/.claude/CLAUDE.md` on any machine, copy the result back into this folder and commit:

```bash
cp ~/.claude/CLAUDE.md user-settings/CLAUDE.md
git add user-settings/CLAUDE.md
git commit -m "chore(user-settings): sync user-level CLAUDE.md"
git push
```

## Scope

This folder is for **user-level** rules — things that apply to every project on every machine you use. Project-specific rules live in each project's own `./CLAUDE.md`, never here.
