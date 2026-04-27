# Session journal — 2026-04-26 (rules layer shipping)

**Slice IDs touched:** `rules-layer` (PR #4 merged), `user-settings-memory-backup` (PR #5 merged), `housekeeping-2026-04-26` (PR #6 in flight)
**Operator:** jota-batuta
**Branch at session end:** `chore/housekeeping-2026-04-26`
**Plugin version at session end:** 2.3.0

## Context

Session continued from `2026-04-26-rule-zero-implementation.md`. Entry point that morning was the merged delegation system (PRs #2-#3) and an open question about the missing `rules/` layer. By session end three more PRs shipped (#4, #5, #6), the plugin reached architectural maturity at v2.3.0, and the user-level memory state was bootstrapped + backed up. Slice B2 (post-merge validation) confirmed that the `rules/` layer loads correctly via `@<path>` imports in real consumer projects.

## Decisions

- **`rules/` layer is the second plugin layer alongside `skills/`.** Boundary: skills auto-invoke on triggers; rules are declarative invariants imported à la carte. Documented in `rules/README.md`. ADRs not added for the layer itself (it's an additive feature, not a controversial decision); the boundary explanation in the README is sufficient.
- **Symlink-based consumer protocol** (`tools/setup-rules.sh` creates `.claude/rules/<rule>.md` → `<plugin>/rules/<rule>.md`) chosen over absolute home-relative paths for cross-developer portability. Trade-off: requires Developer Mode on Windows (or falls back to file copy, which works but breaks idempotency).
- **`batuta-rule-authoring` skill completes the trío** of Batuta authoring meta-skills (`-skill-authoring`, `-agent-authoring`, `-rule-authoring`). Gate is structure-only; content review is the operator's responsibility at PR time. Documented explicitly in the skill body to prevent future agents from assuming the gate substitutes for review.
- **Auto-bootstrap rules in `batuta-project-hygiene`**: a new substep 4b prompts the operator at `mode=project-init` with default Y. On Y, runs `setup-rules.sh --all`, appends `@.claude/rules/<rule>.md` imports to the project's `CLAUDE.md`, adds `.claude/rules/` to `.gitignore`. This eliminates the friction of remembering to run the script manually for every new project.
- **User-level memory backup in `user-settings/`** mirrors the `CLAUDE.md` backup pattern: a public-repo backup that survives machine changes. Sync is manual (operator runs `cp` after editing `~/.claude/`); future automation deferred until the manual flow proves insufficient.
- **Plugin version bumped 1.2.0 → 2.3.0** to mark the architectural maturity inflection. Operator-chosen jump (skipping minor numbers) — when the operator runs `/plugin update batuta-agent-skills` and sees 2.3.0 reported, that confirms all primitives are present (delegation system + audit chain + doc graph + rules layer + memory backup).

## Changes

### PR #4 — `rules/` layer (commit `1341634`, merged 2026-04-26 PM)

- 17 files, 1012 insertions: `rules/` directory with 3 seed rules in `core/`, `_meta/` consumer protocol + rule template + CLAUDE.md template, empty `stack/` and `domain-co/` with `.gitkeep`
- `tools/setup-rules.sh` (idempotent symlink script with two-layer path-traversal defense, Windows Git Bash detection, deterministic plugin-path validation)
- `skills/batuta-rule-authoring/SKILL.md` (gatekeeper for new rules)
- README.md, CLAUDE.md, docs/SPEC.md, docs/PRD.md updates documenting Layer 6 (Engineering invariants)
- Round 2 (commit `1760403`): synced `user-settings/CLAUDE.md` (was missing Rule #0 since Phase 2), added "Engineering invariants from rules/" section to user-level CLAUDE.md, extended `batuta-project-hygiene` with substep 4b for auto-bootstrap
- Audit chain: 3 rounds, all APPROVED (1 Critical + 1 HIGH + 1 MEDIUM hardenings applied)

### PR #5 — User-level memory backup (commit `7c37c13`, merged 2026-04-26 evening)

- 10 files: 8 NEW (`user-settings/MEMORY.md` + `user-settings/memory/{user_operator_profile, feedback_*, reference_*}.md`)
- `user-settings/README.md` MODIFIED to document two-artifact-family backup, restore + sync workflow, scope, sanitization commitment
- `user-settings/CLAUDE.md` MODIFIED: replaced "DIAN, laboral CO" narrative with "Colombian e-invoicing compliance, Colombian labor law" (audit MEDIUM finding)
- Plugin version bumped 1.2.0 → 2.3.0 in `.claude-plugin/plugin.json`
- Audit chain: code-reviewer + security-auditor combined, APPROVED after 1 fix round (1 MEDIUM + 1 LOW applied)

### PR #6 (this commit) — Housekeeping

- Plans moved from `docs/plans/active/` to `docs/plans/archive/`:
  - `2026-04-26-global-docs-skeleton.md` (and its build-log)
  - `2026-04-26-rules-layer.md`
- `docs/plans/active/.gitkeep` added to preserve empty directory
- Session journal (this file) added
- `user-settings/memory/reference_paths.md` re-sanitized: `e:/BATUTA PROJECTS/...` paths replaced with `<projects-root>/` placeholder (this fix was applied locally during PR #5 round 2 but never staged — caught during housekeeping)

### Slice B2 validation (pre-housekeeping)

- Plugin v2.3.0 confirmed in `~/.claude/plugins/installed_plugins.json` and `marketplaces/batuta-agent-skills/.claude-plugin/plugin.json`
- `~/test-delegation-2026-04-26/` (project from prior E2E) used as validation target
- Ran `bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --all` — 3 files created in `.claude/rules/`
- Updated test project's `CLAUDE.md` to import the 3 rules via `@.claude/rules/<rule>.md`
- Added `.claude/rules/` to `.gitignore`
- Validated via `claude -p` headless: agent quoted the 3 inviolable rules from `research-first-citations.md` verbatim. Test cost: $0.10. Pass.

### Operator-local edits (not in any PR)

- `~/.claude/MEMORY.md` initialized with index pointing at 7 user-global memory entries
- `~/.claude/memory/` directory created and populated (mirror of `user-settings/memory/`)
- `~/.claude/projects/e--BATUTA-PROJECTS-batuta-agent-skills/memory/MEMORY.md` initialized with index pointing at 9 project-scoped memory entries
- `~/.claude/projects/e--BATUTA-PROJECTS-batuta-agent-skills/memory/` populated with 9 project entries (shape, repo, plans, decisions x3, patterns x2, baseline)

## Findings worth recording

### Windows + setup-rules.sh idempotency caveat

In Git Bash on Windows **without Developer Mode enabled**, `ln -s` does not create a real symlink — it copies the file. First-run output is correct (3 rules in `.claude/rules/`), but on re-run the script detects "non-symlink file exists" and reports `SKIP (remove manually)` with exit 1. Functionally OK (rules load via `@` imports because content is correct), but breaks the script's idempotency contract.

**Status:** documented; not blocking. Future plugin work could add an `OS == Windows && !DeveloperMode` branch that uses `cp` explicitly instead of `ln -s`, avoiding the cosmetic exit-1 on re-run. Tracked in this journal pending an Issue.

### Plan-file flow lessons learned

- **The plan file should move to archive at PR merge time**, but in practice it took until housekeeping. The convention says "the move is part of the same commit that closes the slice or a follow-up housekeeping commit" — we ended up with two completed slices (`global-docs-skeleton` and `rules-layer`) sitting in `active/` until this PR. Going forward: include the move in the slice's own audit chain checklist so it's not deferred.
- **Build-logs siblings live in `active/` next to the plan**, but only `global-docs-skeleton` had one (`rules-layer` did not). Build-logs are ephemera; if they exist they archive with the plan. If they don't, no harm. The `batuta-project-hygiene` skill's substep 4 doesn't currently template a build-log; the implementer agent creates it on demand.

### Memory bootstrap as a session-end artifact

The user-level memory entries (`feedback_*`, `reference_*`, `user_operator_profile`) and the project-level entries (`project_*`) are essentially distilled from the conversation history of this session and the prior session. They are not invented; they are encoded learnings. Pattern to repeat on future productive sessions: at the end of a session that taught something new (a feedback correction, a discovered caveat, a finished decision), add a memory entry. The cost is small (~80 lines per entry); the payoff compounds because future sessions read them at start.

## Next

Next session entry point: no pending plans. The plugin is at v2.3.0, the user-level memory is bootstrapped and backed up, and B2 validation confirmed the rules layer works end-to-end. Suggested next session topics (not commitments):

1. Apply the **Windows symlink fallback fix** to `tools/setup-rules.sh` (use `cp` explicitly when symlink test fails) — small, contained, audit chain trivial. Estimated 1 hour.
2. **First domain specialist** for a real Batuta project (Colombian e-invoicing validator or Colombian bank-statement parser per PRD v2.5 milestone). Requires the operator to identify the specific repeating pattern (N=2 evidence) — out of plugin scope until the pattern surfaces.
3. **`Stop` hook for session-handoff** (PRD v2.4 milestone) — auto-enforces journal-writing at session end. Defer until an operator drift instance proves the convention isn't holding.

If the operator returns tomorrow without a specific direction: read this journal, confirm `Next:` is "no pending plans", then ask the operator what they want to do next. The plugin is in a stable state — no slice MUST advance.
