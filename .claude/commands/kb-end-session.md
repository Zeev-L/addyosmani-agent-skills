Close the current session journal and trigger `/kb-curate --scope session` for the just-closed bullets.

Steps:

1. Read `.claude/kb-config.json`. If absent, exit with `kb-end-session: project has no kb-config.json — run batuta-project-hygiene mode=project-retrofit first`.
2. Resolve today's journal: `docs/sessions/<YYYY-MM-DD>-<slug>.md`. If empty (no bullets) → exit with `no productive bullets today, nothing to close`.
3. Append a closing block to the journal:
   ```markdown

   ## Next

   Next session entry point: <docs/plans/active/<file>.md @ <task-id>> OR <no pending plans>
   ```
   Prompt the operator interactively for the entry point if uncertain.
4. Stage and commit the journal: `git add docs/sessions/<file>.md && git commit -m "chore(housekeeping): close session journal for <YYYY-MM-DD>"`.
5. Invoke `/kb-curate --scope session` to classify the bullets just written.
6. Print a short summary: bullet count in journal, drafts pending after curate, vault commit hash.

Constraints:
- Run AFTER all productive commits of the day (so the journal captures everything).
- Idempotent: re-running on a journal that already has `## Next` skips the append step but still runs `/kb-curate` (which is itself idempotent).

See `skills/kb-curate/SKILL.md` for the curate pipeline. Companion to `/save-plan` (which handles plan-mode artifacts).
