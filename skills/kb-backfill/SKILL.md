---
name: kb-backfill
description: Use to extract historical knowledge from a legacy repo (READMEs, useful commit messages, gh issues/PRs, optional code analysis) into the vault inbox. 4-phase pipeline, idempotent, configurable scope.
---

# KB backfill

## Overview

Sprint 1 captures forward (every new commit → journal). This skill captures backward: extracts knowledge that already exists in legacy repos but was never written to the vault. Output lands in `<vault_root>/_inbox/backfill-<repo-slug>-<date>/` as L0 entries that the operator drains incrementally via `kb-curate --scope inbox-backfill`.

ADR-0011 D2 documents the intent. Bounded scope: this is per-repo, idempotent, and the operator drives the drain — not automatic.

## When to Use

- Legacy repo joining the v3.8 KB pipeline for the first time (Sprint 3 retrofit precedes a backfill pass)
- After a substantial codebase audit reveals undocumented gotchas or decisions
- Operator-invoked one-off via `/kb-backfill --repo <path>`

Do NOT use for: ongoing capture (that's `post-commit-kb.sh` Sprint 1), curation (that's `kb-curate` Sprint 2), or projects without `.claude/kb-config.json` (run `batuta-project-hygiene mode=project-retrofit` first).

## Process

### Step 1: Resolve target

Parse `--repo <path>` (required) and `--scope readme,commits,issues,code` (default `readme,commits,issues`). Verify:

- The path exists and is a git repo
- It has `.claude/kb-config.json` with `client` + `project` slugs
- The vault root is reachable

If any check fails, report and stop.

### Step 2: Choose model heuristically

Read repo size: commit count (`git rev-list --count HEAD`) and `*.md` count (`find -name '*.md' | wc -l`).

- < 500 commits AND < 50 markdown files → propose **Haiku** (fast path; cheap)
- otherwise → propose **Sonnet** (default)

Operator overrides via `--model haiku|sonnet`. Surface the proposal and proceed.

### Step 3: Run phases (per `--scope`)

Each phase writes outputs to `<vault_root>/_inbox/backfill-<repo-slug>-<date>/`. Manifest tracks progress.

#### Phase 1: README + docs/

For each `.md` in `README.md`, `CONTRIBUTING.md`, `docs/`, `notes/`, files matching `ADR-*.md`, `DECISIONS.md`, `NOTES.md`:

```yaml
---
type: backfill
source: readme
source_path: <repo>/<rel>
backfill_phase: readme
backfilled: true
confidence: high
---

<file content verbatim>
```

Low-cost copy with frontmatter. No synthesis. Filename: `<source-slug>.md`.

#### Phase 2: commit messages

`git -C <repo> log --since='2 years ago' --pretty='%H|%h|%ai|%an|%s|%b'`. Filter by heuristic:

- Subject length > 30 chars
- NOT matching `^(chore|wip|fix typo|build|ci|deps|bump|docs):` 
- Body present, OR subject contains keywords (`refactor`, `breaking`, `decision`, `migrate`, `deprecate`, `rationale`, `discovered`, `learned`)

For each surviving commit, write a journal-style bullet to `<vault_root>/clients/<c>/projects/<p>/sessions/<commit-date>.md` with `backfilled: true` frontmatter so the curator recognizes them.

#### Phase 3: issues / PRs (gh)

If the repo has a github remote:

```
gh -R <owner>/<repo> issue list --state all --label decision,gotcha,breaking,question --limit 200 --json number,title,body,createdAt,author,labels
gh -R <owner>/<repo> pr list --state merged --search 'in:body decision OR rationale OR fixes-bug' --limit 200 --json number,title,body,mergedAt,author
```

Each hit → `_inbox/<...>/issue-<N>.md` or `pr-<N>.md` with frontmatter (`type: backfill, source: issue, issue: <N>, ...`).

If no gh remote: skip Phase 3 silently.

#### Phase 4: code analysis (opt-in, costly)

Only if `--scope` includes `code`. Delegate to `kb-backfiller` agent:

- Comments matching `// TODO|FIXME|HACK|XXX|WORKAROUND` with ±5 lines context
- `.env.example` keys vs production refs (config criticality)
- Files matching `**/migrations/`, `**/legacy/`, `**/compat/`, `**/polyfill/`
- Dependencies pinned with `==` / `@` exact (vs ranges) — suggests intentional pin

Outputs to `_inbox/.../code-analysis-<repo>/` with `confidence: low|medium|high`.

### Step 4: Write manifest + idempotency

`<vault_root>/_inbox/backfill-<repo-slug>-<date>/manifest.yaml`:

```yaml
repo: <path>
client: <client>
project: <project>
phases_run:
  - readme
  - commits
  - issues
last_processed_sha: <sha>
files_written: <count>
ran_at: <ISO>
```

Re-running with the same repo + date: skip phases listed in the manifest unless `--force`. With a different `--scope`, run only the phases not in the manifest.

### Step 5: Report

Print summary:

```
backfill complete for <repo>
  phase readme: 12 files
  phase commits: 47 bullets across 23 journal files
  phase issues: 8 issues, 3 PRs
  phase code: SKIPPED (--scope did not include code)
output: <vault_root>/_inbox/backfill-<repo>-<date>/

next: /kb-curate --scope inbox-backfill
```

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "Skip Phase 1 — READMEs are fine where they are" | The vault is for cross-project lookup. A README staying in its repo is invisible to research-first Step 1.5 in any other project. Bring it in. |
| "Run Phase 4 always — code analysis catches the most" | Phase 4 is 50-150k tokens. Run 1+2+3 first; only escalate to 4 when those don't surface enough signal. |
| "Filter commits more aggressively (subject > 60 chars)" | The heuristic intentionally errs broad — false positives are cheap (operator marks noise during curate). False negatives lose history forever. |
| "Auto-curate the _inbox/ output to L2" | No. Backfill is L0/L1 only; promotion goes through `kb-curate` with operator review. Auto-promotion bypasses the hybrid control matrix. |

## Red Flags

- `_inbox/backfill-*` directory exceeds 500 files (Phase 4 ran on a giant repo without pruning — re-evaluate)
- Phase 3 returned 0 hits AND the repo has open issues with `decision` labels (the gh search filter may be too narrow)
- `last_processed_sha` in manifest does not match `git log -1 --format='%H'` after rerun (idempotency broken)
- Wikilinks in backfilled entries point to nonexistent glossary entries (Phase 1 should have triggered glossary-entry candidates — surface to curator)

## Verification

- `find <vault_root>/_inbox/backfill-<repo>-* -type f | wc -l` > 0 after a non-empty run
- `cat <vault_root>/_inbox/backfill-<repo>-<date>/manifest.yaml` shows `phases_run:` with the requested scope
- Re-running with the same args produces 0 new files (idempotent)
- After `/kb-curate --scope inbox-backfill`, drafts/auto-applies appear with `backfilled: true` in their frontmatter (auditability)
- Phase 4 only ran when `--scope` included `code` (verified by absence of `code-analysis-<repo>/` subdir otherwise)
