# `tools/` — Project tooling scripts

Scripts in this directory are run by consumer projects (not by the plugin itself).

## `setup-rules.sh`

Creates symlinks from a consumer project's `.claude/rules/` directory into the plugin's `rules/` directory. This is the recommended way to import engineering invariants without copying content.

### Usage

Run from the consumer project root:

```bash
# Symlink all available rules
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --all

# Symlink a single rule
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --rule core/secrets-and-pii

# Interactive mode — prompts y/n for each available rule
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh
```

The script is idempotent: re-running it produces the same state without duplicating or erroring on existing symlinks.

**Windows note**: symlinks require Developer Mode enabled (Settings → System → For developers). If the script exits with a symlink error, enable Developer Mode and re-run.

### After running

Add `@.claude/rules/<rule-name>.md` import lines to the project's `CLAUDE.md`. See [`../rules/_meta/how-to-import.md`](../rules/_meta/how-to-import.md) for the full consumer protocol, including the exception-documentation pattern and a starter `CLAUDE.md` template.
