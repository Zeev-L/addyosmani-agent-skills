Run the `kb-curate` skill (`skills/kb-curate/SKILL.md`) with the operator-supplied scope.

Argument syntax: `/kb-curate [--scope session|all-pending|week|since-YYYY-MM-DD] [--feature <branch>]`. Default `--scope all-pending`.

Steps:

1. Read `.claude/kb-config.json` from the project root. If absent, exit with `kb-curate: this project has no .claude/kb-config.json — run batuta-project-hygiene mode=project-retrofit first`.
2. Resolve the scope from `$ARGUMENTS`:
   - `--feature <branch>`: list bullets in `docs/sessions/*.md` whose `branch:` line matches.
   - `--scope session`: only today's `docs/sessions/<YYYY-MM-DD>-*.md`.
   - `--scope week`: journals modified in the last 7 days.
   - `--scope all-pending` (default): every bullet in `docs/sessions/` lacking `curated_into:` frontmatter.
   - `--since YYYY-MM-DD`: journals modified after the date.
3. Delegate to `kb-curator` agent via Task with the bullet list. The agent classifies each bullet and writes outputs per the hybrid control matrix.
4. After kb-curator returns, append `curated_into: [paths]` and `curated_at: <ISO>` sub-bullets to the source journal AND its vault mirror.
5. `cd <vault_root> && git add . && git commit -m "kb-curate: <scope>, <N> bullets, <M> drafts, <K> auto-applies"`. Do NOT push.
6. Print summary: drafts pending review (paths), auto-applies committed (hashes), noise count, errors.

Constraints:
- NEVER auto-apply `decision-*`, `gotcha-update`, or `playbook-candidate` — those land as `.draft` files.
- Idempotent: re-running on the same scope produces 0 changes.
- If `vault_root` is unreachable (Drive offline), skip vault mirror and log to `.claude/kb-debug.log`.

See full process in `skills/kb-curate/SKILL.md`. ADR-0011 D2 documents the decision rationale.
