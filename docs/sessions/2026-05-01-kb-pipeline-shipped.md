---
type: session
date: 2026-05-01
client: jota-batuta
project: batuta-agent-skills
repo: jota-batuta/batuta-agent-skills
branch: feat/obsidian-only-kb-pipeline + docs/deprecate-notion-claudemd
tags: [session, client/jota-batuta, kb-pipeline, shipping]
last_verified: 2026-05-01
---

# Session journal — 2026-05-01 — KB pipeline shipped

## Context

Entry point: `docs/plans/active/2026-04-29-kb-pipeline.md` (revised in plan-mode at `~/.claude/plans/tenemos-un-problema-en-structured-lantern.md`). Prior session (2026-04-30) had landed Sprint 0 (vault git bootstrap) and started Sprint 1 (post-commit hook + ADR-0011/0012 design). This session closed Sprints 1–4 in one shipping pass: ADR-0012 written, `kb-pipeline` agent created, post-commit hook extended with ADR auto-mirror + agent dispatch, session-start hook extended with vault context loader, `batuta-project-hygiene` extended with vault client discovery menu, project + user CLAUDE.md updated, plugin install refreshed, vault `.git/` migrated outside Drive sync.

## Decisions

- **Single agent with 3 internal phases (D2 in ADR-0012)** instead of three sequential agents with queue files. Eliminates inter-agent token cost and the Windows file-locking race condition that broke the original three-agent design. Distinct from `kb-curator` (batch L1→L2 manual classifier) and `kb-backfiller` (one-shot historical extraction).
- **Per-commit async dispatch via `nohup timeout 120 claude --print ... & disown` (D3)** instead of synchronous Notion API call from the hook. The commit path must never depend on network or LLM API. `timeout 120` is the watchdog against runaway token cost.
- **Slug + path validation gate before LLM prompt interpolation.** All values that enter the dispatch prompt (`client`, `project`, `repo_root`, `vault_root_resolved`, `log_file`, `sha_full`, `adr_id`, `adr_slug`) pass an explicit regex gate. Prevents prompt injection from a poisoned `.claude/kb-config.json`. Each gate logs a WARN to `kb-debug.log` and skips dispatch on failure.
- **Three-tier `kb-pipeline` agent lookup** (project-local → plugin-install → plugin-repo) so consumer projects find the plugin-shipped agent at `~/.claude/plugins/marketplaces/batuta-agent-skills/agents/`, not the absent path inside their own repo. Caught by the code-reviewer gate during the audit chain.
- **Notion deprecation gradual, not abrupt.** `notion-kb-workflow` SKILL.md remains in place but the project + user CLAUDE.md mark it as DEPRECATED with explicit replacements; Sprint 4 will actually rewrite the SKILL frontmatter to `status: deprecated`.
- **Vault `.git/` separated to local SSD via `git init --separate-git-dir`.** The vault working tree stays on Google Drive (Obsidian still works on multiple machines). The `.git/` directory (objects/, refs/, pack/) lives at `C:/Users/JNMZ/git-vaults/batuta-kb` and only the `.git` pointer file (43 bytes) syncs through Drive. Cross-volume rename failed (E: → C:), so the actual move was manual: `cp -a .git → ~/git-vaults/batuta-kb/`, `rm -rf .git`, `echo "gitdir: C:/..." > .git`, then `git config core.worktree "..."` to record the worktree path. Single-machine setup; cross-machine git would require the same `~/git-vaults/` path on each replica.

## Changes

**PR #36 (merged `03d611a`)** — Obsidian-only KB pipeline + ADR-0012:

- `5462601` feat(kb): add ADR-0012 + kb-pipeline agent for Obsidian-only KB
- `b444480` feat(kb): add ADR auto-mirror + kb-pipeline dispatch to post-commit hook
- `7de338f` feat(kb): load Obsidian vault context at session start
- `cbf7896` feat(hygiene): vault client discovery menu in mode=project-init

**PR #37 (merged `cebca8a`)** — docs follow-up to PR #36:

- `d511283` docs(claude): deprecate notion-kb-workflow, add kb-pipeline + vault entry sequence

**Audit chain ran sequentially on the diff before each PR opened**:

| Gate | Initial result | After fixes |
|---|---|---|
| `test-engineer` | 2 BLOCKERS, 8 warnings | PASS |
| `code-reviewer` | 2 CRITICAL, 5 important | PASS |
| `security-auditor` | 1 HIGH, 3 MEDIUM, 2 LOW | PASS WITH WARNINGS (LOW/INFO addressed) |

Notable hardening applied during the chain: `CHERRY_PICK_HEAD`/`MERGE_HEAD` `-d`→`-f` fix, env-var pattern for `python3 -c` (eliminates code-injection from vault content), all prompt values regex-gated, `adr_status` allowlist, `nohup timeout 120` watchdog, `kb_block` 4000-char cap, log auto-rotation at 5000 lines.

**User-level `~/.claude/CLAUDE.md`**: edited in-place — replaced "Notion KB as durable memory" with "Obsidian KB as durable memory (ADR-0012)". Documents the auto-trigger flows (session-start vault context, post-commit ADR mirror + kb-pipeline dispatch) and the deprecated status of `notion-kb-workflow`.

**Plugin install refresh**: `claude plugin update batuta-agent-skills@batuta-agent-skills` pulled the merged code into `~/.claude/plugins/marketplaces/batuta-agent-skills/`. Verified `agents/kb-pipeline.md` and `docs/adr/0012-*.md` are present, `hooks/post-commit-kb.sh` has the new flags, `skills/batuta-project-hygiene/SKILL.md` has the vault discovery menu.

**Vault `jota-batuta/batuta-kb` migration** (separate repo, not this one): 40 KB entries migrated from Notion DB "Batuta Knowledge Base" to `<vault>/glossary/domains/`. 3 sprint pages from Notion DB "Proyectos" migrated to `<vault>/clients/<c>/projects/<p>/sprints/`. New client `kiro` created with `_metadata.md`. `task.md` template + per-project `_status.md` with Dataview queries written. `.git/` migrated outside Drive sync (see Decisions above) — backup at `~/git-backups/batuta-kb-git-20260501T160651Z.tar.gz`.

## Next

Next session entry point: no pending plans. Sprints 1–4 of `2026-04-29-kb-pipeline.md` shipped via PR #36 + #37; the plan can be moved from `docs/plans/active/` to `docs/plans/archive/` in the next housekeeping commit. Open follow-ups (not blocking):

1. Operator activates the opt-in flags in some Batuta project's `.claude/kb-config.json` to validate the pipeline end-to-end with a real commit (`adr_mirror_enabled` first, then `kb_pipeline_enabled`).
2. Sprint 4 (Notion SKILL deprecation): rewrite `skills/notion-kb-workflow/SKILL.md` frontmatter to `status: deprecated`.
3. Sprint 5 (vault query agent): create a `vault-query` skill that reads the curated vault to answer natural-language questions ("¿por qué dejamos de usar Pydantic?").
4. Vault untracked content (40+ glossary entries, 3 client folders, `_meta/`, `templates/task.md`) needs a commit in `jota-batuta/batuta-kb` — currently sitting in working tree only.
