# ADR 0012 — Obsidian-only KB pipeline: deprecate Notion, single agent, async post-commit dispatch

**Status:** Accepted
**Date:** 2026-04-30
**Deciders:** jota-batuta
**Supersedes (in part):** ADR-0011 D2 — Notion as optional KB surface. D2 originally treated Notion as a valid capture inlet; this ADR removes that option for internal Batuta use. ADR-0011 D1 (commit-triggered persistence) and D3 (authoring gates) remain fully in effect and are not touched.

## Context

ADR-0011 (2026-04-29) established the L0–L3 vault structure and committed to implementing the KB pipeline in Sprints 1–4. Sprint 1 began on 2026-04-30 with an `--init` call to `notion-kb-workflow`. Three problems surfaced immediately that invalidated the design assumptions baked into ADR-0011 D2:

**1. Notion token cost is prohibitive for solo-developer KB workloads.**
The Notion MCP returns verbose JSON for every fetch: a single page read emits ~3–6 KB of metadata (properties, timestamps, block tree) vs. ~200–800 B for an equivalent markdown file read via `Read` tool. Empirical session observation during the 2026-04-30 sprint: `notion-kb-workflow --read` consumed approximately 3–5× more tokens than an equivalent `Read` of the target `.md` file in the Obsidian vault. At current Sonnet 4.6 pricing the difference is ~$15–25/month for daily KB reads across 8–10 active projects. Over a 12-month horizon that is $180–300 in token overhead to maintain parity with a local markdown file.

**2. Coexistence adds accidental complexity with no payoff.**
ADR-0011 kept Notion as an "optional" surface (L0 `_inbox/` drains from Notion exports; `notion-kb-workflow --append` mirrors bullets to Notion after the Obsidian write). In practice this created two divergence modes: (a) Notion DB lags when the operator skips `--append`, (b) the agent must decide which surface is authoritative when the two disagree. Neither mode is acceptable for a solo developer with no real-time collaboration requirements. The "optional" label removed clarity without removing complexity.

**3. Three-agent sequential pipeline has three single points of failure.**
The ADR-0011 Sprint 1 design specified three agents in sequence: `kb-capture` → `kb-curator` (already shipping) → `kb-writer`. Each agent hands off via a queue file (`_queue/<timestamp>.json`). On Windows with Git Bash, file locking and CRLF line endings on the queue files introduced a race condition in the 2026-04-30 test run. More fundamentally: a three-agent pipeline spends tokens on inter-agent context reconstruction — each agent re-reads the same session bullets to understand the prior agent's intent. A single agent with three internal phases eliminates both problems.

## Decision

Three coupled decisions that revise the ADR-0011 Sprint 1–4 implementation plan. Architecture is unchanged (L0–L3 vault, git post-commit hook); the delivery mechanism and platform mix change.

### D1 — Deprecate Notion for internal Batuta KB; migrate to Obsidian

Notion is removed as a target surface for the KB pipeline. Specifically:

- `notion-kb-workflow` skill status changes to **deprecated** for KB use. The skill remains in the plugin for operators who have Notion-first workflows, but is no longer invoked by Batuta's own session boundary protocol.
- The Batuta KB DB in Notion (sprint pages, decisions, retrospectives) is migrated to Obsidian during Sprint 1: sprint pages → `vault/meta/sprints/<YYYY-WNN>.md`; decisions → `vault/decisions/` (L2); retrospectives → `vault/journals/`.
- `~/.claude/CLAUDE.md` line "Use notion-kb-workflow at three points" is superseded by "Use batuta-kb-vault at session start/end." (User-global update tracked in Sprint 1 task list.)
- `.claude/kb-config.json` loses the `notion_db_id` field. Any project that has it ignores it after the sprint. No migration script needed — the field is simply unused.

**Why not keep Notion for sprint pages only?** The token overhead is incurred regardless of which pages are fetched — the MCP initializes a full workspace index on every tool call. Partial retention preserves the overhead while removing most of the value. Full deprecation is the only option that removes the cost.

### D2 — Single `kb-pipeline` agent with three internal phases (Capture / Curate / Write)

The three-agent sequential pipeline (`kb-capture` → `kb-curator` → `kb-writer`) is replaced with a single agent `kb-pipeline` that executes three phases internally:

| Phase | Input | Output | Logic |
|---|---|---|---|
| Capture | `git log -1 --pretty=...` + diff summary | structured bullet object in-memory | extract who/what/why from commit |
| Curate | in-memory bullet + L2 index | classification + action (auto-apply / draft / noise) | 7-category matrix from ADR-0011 D2 |
| Write | classified bullet + action | appended L1 journal file + optional L2 draft | atomic write to vault path |

The agent is invoked as: `nohup claude --print --no-interactive --permission-mode acceptEdits "<delegation prompt referencing kb-pipeline subagent + commit context>" >> "$LOG_FILE" 2>&1 & disown`. The prompt instructs the headless main agent to delegate to the `kb-pipeline` subagent via the Task tool; the subagent's workflow (defined in `agents/kb-pipeline.md`) governs the actual phases. See the actual implementation in `hooks/post-commit-kb.sh` for the canonical command.

No queue files. No inter-agent handoff. The three phases share one context window, so curate has full access to what capture extracted without re-reading.

**Agent footprint**: `kb-pipeline` reads at most 3 vault files per invocation (session journal for the day, L2 index of the affected L2 category, the L2 target file if updating). Estimated token cost per commit: 800–1,200 input tokens + 200–400 output tokens at Sonnet 4.6 prices ≈ $0.0015–0.003/commit. At 20 commits/day across all projects: ~$0.03–0.06/day — acceptable.

The existing `kb-curator` agent (already shipped in Sprint 0/1) is repurposed as the **interactive curate path** for operator-initiated `/kb-curate` slash and weekly cron — it still runs L1→L2 promotion for accumulated journals. `kb-pipeline` handles per-commit real-time capture only.

### D3 — Async post-commit dispatch via `claude --print --no-interactive ... &`

The `post-commit-kb.sh` hook (ADR-0011 D1) dispatches `kb-pipeline` as a background process:

Sketch (the canonical implementation is in `hooks/post-commit-kb.sh`):

```bash
# Opt-in gate
[ "$kb_pipeline_enabled" = "true" ] || exit 0

# Detached subprocess: hook returns immediately; commit is never blocked
nohup claude --print --no-interactive --permission-mode acceptEdits \
  "Use the Task tool to delegate to the kb-pipeline subagent. Pass: SHA=$SHA, REPO_ROOT=$REPO_ROOT, CLIENT=$CLIENT, PROJECT=$PROJECT, VAULT_ROOT=$VAULT_ROOT, LOG_FILE=$LOG_FILE..." \
  >> "$LOG_FILE" 2>&1 &
disown
```

The combination `nohup ... & disown` is the key invariant: the hook exits with code 0 immediately, and the agent runs in a fully detached subprocess (survives shell exit). Commits are never blocked by KB pipeline latency. If the agent fails, the failure is logged to `.claude/kb-debug.log` and the operator is notified on the next `/kb-end-session` invocation. `--permission-mode acceptEdits` prevents interactive permission prompts when the subagent writes vault files.

**Why `--print --no-interactive` and not `Task`?** `Task` runs inside an existing Claude Code session and shares the session's context window. A post-commit hook fires outside any session context — `claude --print` is the correct invocation for a headless, sessionless agent call. `--no-interactive` prevents the CLI from prompting for confirmation if it detects a TTY-less environment.

## Alternatives considered

### Alt 1 — Keep Notion for sprint pages; deprecate only KB DB

**Rejected.** The Notion MCP initializes a workspace index on every call regardless of which pages are queried. Retaining one Notion surface keeps the full token overhead while delivering only a fraction of the original Notion value. The sprint page format (`YYYY-WNN`) maps naturally to `vault/meta/sprints/<YYYY-WNN>.md` with Obsidian Dataview queries replacing Notion filtered views. Net migration cost: ~2 hours one-time. Net savings: full elimination of MCP overhead.

### Alt 2 — Three separate agents with queue files (`kb-capture` → `kb-curator` → `kb-writer`)

**Rejected.** Three failure points: if any agent fails or produces malformed queue JSON, the downstream agents silently skip the commit. Queue file orchestration adds ~60 lines of bash for locking, CRLF normalization, and retry — complexity that the single-agent design eliminates entirely. Inter-agent context reconstruction costs ~400–600 extra input tokens per handoff (two handoffs = 800–1,200 tokens/commit). Single agent with internal phases costs 0 handoff tokens. Rejected on correctness + cost grounds.

### Alt 3 — Notion sync from post-commit hook via `curl` (no MCP)

**Rejected.** Direct `curl` to the Notion REST API solves the MCP overhead but keeps the network dependency on the commit path. Even with `&` (async dispatch), network failures produce silent data loss unless the hook implements retry + dead-letter queue — equivalent complexity to the queue-file design rejected in Alt 2. More importantly: the Obsidian vault is already the source of truth; writing to Notion is a read-path optimization (Notion UI) that the operator confirmed is not needed for a solo developer workflow.

### Alt 4 — GitHub Actions for KB pipeline (triggered by push)

**Rejected.** GitHub Actions requires the Obsidian vault to be a remote-tracked repo AND the action runner to have vault write access. The vault is a private git repo (`jota-batuta/batuta-kb`) synced via Google Drive — adding a GH Action runner with write access creates a second write path that can conflict with local commits. Local hook with async dispatch is simpler and keeps vault writes to a single origin.

### Alt 5 — Cron-based batch capture (hourly/daily, not per-commit)

**Considered, not rejected as a future option, but not chosen as primary.** Batch capture loses the commit-message context that makes per-commit bullets useful (the message is the why; the diff stat is the what). A cron job reading `git log --since=1hour` recovers the message but not the diff context reliably across multiple repos with different remotes. Per-commit is strictly higher fidelity. Cron remains available as a fallback via `/kb-curate` weekly trigger already in ADR-0011.

## Consequences

### Positive

- **Token savings: ~$15–25/month** eliminated by removing Notion MCP from the session read path. Over 12 months: $180–300 recovered.
- **Single source of truth**: Obsidian vault is the only KB surface. No divergence modes, no "which surface is authoritative" ambiguity.
- **Agent-friendly format**: Obsidian markdown files are read by `Read` tool at ~1/4 the token cost of equivalent Notion JSON. `research-first-dev` Step 1.5 lookups are faster and cheaper.
- **Commit path is non-blocking**: the `&` dispatch means zero added latency to the developer commit loop. KB capture is a side effect, not a gate.
- **Reduced fragility**: one agent with three internal phases vs. three agents with two handoffs. Failure surface shrinks from 3 processes to 1.
- **Backlink graph**: Obsidian Dataview + Tasks + Templater plugins enable cross-project queries (e.g. "all gotchas tagged #prophet across clients") that Notion filtered views required per-DB configuration to replicate.

### Negative / Costs

- **Notion UI lost for non-technical stakeholders.** If a client or team member without Obsidian access needed to view sprint pages or decisions, Notion provided a shareable URL. Mitigation: none in scope — the operator confirmed solo developer workflow with no external stakeholders for internal KB.
- **Dataview literacy required.** Obsidian Dataview queries replace Notion filtered views. The operator must learn/maintain Dataview syntax for sprint dashboards. Estimated one-time cost: 2–4 hours.
- **One-time migration effort.** Notion DB contents (sprint pages, decisions) must be exported and reformatted into Obsidian markdown. Estimated: 2–3 hours for the existing content volume (< 50 pages).
- **`notion-kb-workflow` skill becomes dead code for Batuta's own workflow.** The skill remains in the plugin for external consumers but will not be exercised by Batuta sessions — a maintenance risk if the Notion MCP API changes and the skill silently breaks. Mitigation: deprecation notice in SKILL.md frontmatter; `batuta-status` will flag the skill as untested if no session invokes it for 30+ days.

### Risks

- **Google Drive + git corruption on `.git/objects`.** The Obsidian vault at `E:\Gdrive Batuta\My Drive\BATUTA AI\OBSIDIAN\BATUTA` is synced by Google Drive Desktop. Drive can corrupt git pack files if it syncs a partial write during a `git gc` or `git pack-objects` run. **Mitigation (Sprint 1, blocking):** add `.git/` to the Drive Desktop exclusion list for the vault directory OR move the vault outside the Drive-synced path to `E:\OBSIDIAN\BATUTA` and update `kb-config.json` vault root accordingly. Both options are documented in Sprint 1 task 1.1. The vault's primary backup is the remote `jota-batuta/batuta-kb` (private); Drive sync is secondary and optional.
- **`claude --print` CLI availability.** The post-commit hook calls `claude` binary. If the Claude Code CLI is not on PATH in the hook's environment (non-interactive shell), the hook exits 0 silently (no agent dispatch). Mitigation: Sprint 1 task 1.3 adds a PATH check with a warning logged to `~/.claude/kb-pipeline.log`; `/kb-end-session` surfaces the warning.
- **Vault corruption from concurrent writes.** Two rapid commits in the same second can dispatch two `kb-pipeline` agents that both try to append to the same session journal file. Mitigation: `kb-pipeline-prompt.txt` instructs the agent to use a file-level lock (`flock` on Linux/macOS; `Start-Sleep 1` + retry on Windows Git Bash) before appending. Low-probability event for a solo developer.

## Implementation

**Revised sprint plan** (supersedes ADR-0011 migration path for Sprints 1–4):

- **Sprint 1 (current, branching from `fix/kb`)**: vault git bootstrap + Drive exclusion fix + `post-commit-kb.sh` with async dispatch + `kb-pipeline` agent + `batuta-kb-vault` skill update to remove Notion init step. Plan: `docs/plans/active/2026-04-29-kb-pipeline.md`.
- **Sprint 2**: `kb-pipeline-prompt.txt` tuning + file-lock implementation + integration test (`bash tests/kb-pipeline/run.sh`). `kb-curator` agent repurposed for interactive `/kb-curate` path only.
- **Sprint 2.5**: `kb-backfill` for legacy repos (unchanged from ADR-0011 — 4 phases: README/commits/issues/code).
- **Sprint 3**: project-retrofit on 4 pending repos to add `.claude/kb-config.json`.
- **Sprint 4**: Notion content migration to Obsidian vault (`_inbox/` drain → L2 promotion via `/kb-curate`). `notion-kb-workflow` SKILL.md updated to deprecated status.

**Key artifacts**:
- `hooks/post-commit-kb.sh` — async dispatch script (Sprint 1) plus inline ADR auto-mirror function (`_mirror_adr`) gated on the new `adr_mirror_enabled` config key
- `agents/kb-pipeline.md` — single agent replacing the three-agent sequence (Sprint 1, requires `batuta-agent-authoring` gate)
- `skills/batuta-kb-vault/SKILL.md` — updated to remove Notion init path (Sprint 1, edit of existing file — no authoring gate needed)
- `tests/kb-pipeline/run.sh` — integration tests for capture/curate/write phases (Sprint 2)

**New `kb-config.json` keys (both opt-in, default `false`)**:
- `adr_mirror_enabled`: when `true`, every commit that touches `docs/adr/NNNN-*.md` also writes a mirror to `<vault_root>/decisions/adr-NNNN-<slug>.md` with Obsidian frontmatter (`adr_id`, `status`, `date`, `project`, `client`, `source_hash`, `tags: [adr]`). Idempotent via `source_hash` comparison; falls back to re-writing every commit when no hash tool is available (with WARN to debug log). Implemented synchronously inside the post-commit hook — no agent dispatch.
- `kb_pipeline_enabled`: when `true`, dispatches the `kb-pipeline` agent in background after each commit via `nohup claude --print --no-interactive --permission-mode acceptEdits ... & disown`. Requires the `claude` CLI in PATH and a kb-pipeline agent definition reachable at one of: `<repo>/.claude/agents/`, `<plugin-install>/agents/`, or `<repo>/agents/`. CLIENT/PROJECT slugs are validated against `^[a-z0-9][a-z0-9-]{0,60}$` before being interpolated into the LLM prompt to prevent prompt-injection from a poisoned `kb-config.json`.

**Plan file**: `docs/plans/active/2026-04-29-kb-pipeline.md` (already active; Sprint 1 tasks updated in place).

## Verification

- Sprint 1: `bash tests/kb-pipeline/run.sh` — exit 0 on capture, curate, write phases against a test vault.
- Sprint 1: make a commit in a repo with `.claude/kb-config.json` present; confirm `~/.claude/kb-pipeline.log` shows a successful write within 30 seconds; confirm session journal file in vault updated.
- Sprint 1: make a commit in a repo WITHOUT `.claude/kb-config.json`; confirm hook exits 0 with no log output (opt-in gate).
- Sprint 2: make two commits within 1 second; confirm session journal has two bullets, no corruption (file-lock test).
- Sprint 4: confirm `notion-kb-workflow` SKILL.md frontmatter shows `status: deprecated`; confirm `batuta-status` flags skill as inactive.
