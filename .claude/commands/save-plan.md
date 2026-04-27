---
description: Copy the most recently modified plan-mode plan from ~/.claude/plans/ to <project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md so it persists with the repo
---

You will persist the most recent plan-mode plan from the user-global location (`~/.claude/plans/`) to the project-local canonical location (`<project>/docs/plans/active/`). Plan-mode in Claude Code defaults to writing plans to the user-global path; this command copies the file project-local so it travels with the repo via git.

The slug for the target filename comes from `$ARGUMENTS`. If `$ARGUMENTS` is empty, derive the slug from the source filename basename.

## Steps

1. **Locate source plan**: run `ls -t ~/.claude/plans/*.md 2>/dev/null | head -1` (Bash) to find the most recently modified plan. If empty, abort with: "No plan found in ~/.claude/plans/. Run plan mode first."

2. **Verify project skeleton**: confirm `docs/plans/active/` exists in the current project root. If it does not exist, instruct the operator: "Project lacks doc skeleton. Run `batuta-project-hygiene mode=project-retrofit` first, then re-run /save-plan." Stop.

3. **Compute target path**:
   - Date: `date +%Y-%m-%d` (Bash)
   - Slug: if `$ARGUMENTS` is non-empty, use it (kebab-case, ≤ 50 chars, strip leading/trailing hyphens). If empty, take the source filename basename (strip `.md`), keep only the first 3–4 words separated by hyphens (drop the random Claude Code suffix like `-refactored-lobster`).
   - Target: `docs/plans/active/<YYYY-MM-DD>-<slug>.md`

4. **Idempotency check**: if the target file already exists, abort with: "File exists at `<target>`. Choose a different slug or rename the existing file first." Do NOT overwrite — overwriting silently destroys the previous plan, which the audit chain may have referenced.

5. **Copy**: `cp "<source>" "<target>"` (Bash). Verify target file size matches source (`wc -c` on both, expect identical bytes).

6. **Confirm to operator**: print `Plan saved to <target>. Source preserved at <source> as user-global backup.` Suggest next steps: "If this plan kicks off implementation, the implementer pre-flight will pick it up automatically. The user-global copy can be deleted manually if desired (`rm <source>`)."

## Constraints

- The target path is under `docs/plans/active/`, which is in the Rule #0 hook whitelist. The main agent can write to it directly via Bash `cp` without delegation.
- Do NOT modify the source file in `~/.claude/plans/`. Treat it as read-only.
- Do NOT auto-archive: this command moves the plan into `active/`, not `archive/`. Archival happens after the slice ships, as a separate housekeeping step.
- If the operator wants to rename the target after copying, use `mv` — do not re-run /save-plan with a different slug (that would create two copies of the same plan).

## Why this is a slash command and not a runtime hook

Plan-mode persistence was originally designed as a `PreToolUse` hook on `ExitPlanMode`. During v2.6 implementation, hook surface analysis showed that `ExitPlanMode`'s tool input does not expose the plan file path, so the hook would have to scan `~/.claude/plans/*.md` for the most-recently-modified file — fragile under concurrent sessions and clock drift. The slash command is operator-invoked but deterministic, idempotent, and easy to verify. See `docs/adr/0005-plan-mode-persistence-mechanism.md`.

If you want this automated rather than operator-invoked, either:
1. Add `/save-plan` to your end-of-plan-mode habit (run it immediately after exiting plan mode), or
2. Wait for v2.7 — Claude Code may expose the plan path in `ExitPlanMode` tool input by then, making the hook viable.
