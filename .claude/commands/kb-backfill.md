Run the `kb-backfill` skill (`skills/kb-backfill/SKILL.md`) against a legacy repo.

Argument syntax: `/kb-backfill --repo <abs-path> [--scope readme,commits,issues,code] [--model haiku|sonnet] [--force]`. Default `--scope readme,commits,issues`.

Steps:

1. Parse `$ARGUMENTS`. Validate `--repo <path>`: must exist, be a git repo, have `.claude/kb-config.json` with `client` + `project`. Vault root reachable.
2. Read repo size — commit count and `*.md` count. Propose model: Haiku if both small (< 500 commits AND < 50 markdown files), otherwise Sonnet. Operator override via `--model`.
3. Read or create `<vault_root>/_inbox/backfill-<repo-slug>-<date>/manifest.yaml`. Determine which phases from `--scope` are NOT yet run. With `--force`, ignore the manifest and re-run.
4. For each pending phase, dispatch `kb-backfiller` agent (using the proposed/chosen model) with the phase name and the repo path. Aggregate per-phase counts.
5. After all phases: write/update `manifest.yaml` with `phases_run`, `last_processed_sha`, `files_written`, `ran_at`.
6. Print summary: per-phase counts, total inbox files written, location, next step (`/kb-curate --scope inbox-backfill`).

Constraints:
- Phase 4 (code analysis) only runs when `--scope` explicitly includes `code` (it is expensive — 50-150k tokens for a medium repo).
- Idempotent: re-running with the same args produces 0 new files unless `--force`.
- NEVER modify the source repo. Only writes to `<vault_root>/_inbox/backfill-*` and `<vault_root>/clients/<c>/projects/<p>/sessions/`.
- Recommended order for Sprint 3 retrofit: bato-cajas (smallest, has rules baseline) → BATO2 (gh remote, validates Phase 3) → BATO (oldest, validates empty cases) → batuta-portal (no remote) → Batuta APP.

See full process in `skills/kb-backfill/SKILL.md`. ADR-0011 D2 documents the L0 capture rationale.
