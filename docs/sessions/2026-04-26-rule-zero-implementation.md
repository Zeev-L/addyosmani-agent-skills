# Session Journal — 2026-04-26

**Slice IDs touched:** `delegation-enforcement` (PR #2 merged), `global-docs-skeleton` (PR for `feature/global-docs-skeleton`, in flight at session end, expected as PR #3)
**Operator:** jota-batuta
**Branch at session end:** `feature/global-docs-skeleton`

## Context

Session entered without an active plan persisted in `docs/plans/active/` — the convention being introduced in this very slice. The starting point was the conversation history: a multi-phase mission to (1) implement Rule #0 enforcement in the plugin, (2) update the user-global `~/.claude/CLAUDE.md`, (3) clean `~/.claude/` machine-wide, and (4) run an E2E test of the delegation chain.

Mid-session, the operator identified a structural gap: the plugin had per-feature SPEC documents but no project-wide PRD or SPEC, and no ADRs. The session also exposed a process gap: with four phases in flight, the main agent's context window was the only persistent memory of the integrated plan, and re-entering plan mode caused regression to a partial view (only Phase 3 was reproduced when the operator asked for the full plan). This session ends with both gaps closed: the architectural one via the slice now in flight, and the process one via the new session-handoff protocol documented in `CLAUDE.md`.

## Decisions

- **Rule #0 = three-layer enforcement.** Documentary contract (`docs/DELEGATION-RULE.md`), agent declarations (explicit `model:` on all six shipped agents), and runtime hook (`hooks/delegation-guard.sh`). Rationale captured in [`adr/0001-rule-zero-delegation-only-main.md`](../adr/0001-rule-zero-delegation-only-main.md).
- **Haiku tier ships as a separate agent.** `implementer-haiku.md` is its own file, not a parameter on `implementer`. Rationale: Claude Code's `Task` resolves model from frontmatter, no documented override at invocation time. See [`adr/0002-implementer-haiku-separate-agent.md`](../adr/0002-implementer-haiku-separate-agent.md).
- **PreToolUse hook over `permissions.deny`.** Permissions cannot distinguish caller (main vs subagent); the hook can via `agent_id` field. See [`adr/0003-plugin-level-hook-vs-permissions-deny.md`](../adr/0003-plugin-level-hook-vs-permissions-deny.md).
- **Audit chain runs sequentially, not in parallel.** Each gate reads the previous gate's output. See [`adr/0004-audit-chain-sequential-not-parallel.md`](../adr/0004-audit-chain-sequential-not-parallel.md).
- **Doc graph follows the four-quadrant model** (PRD = why, SPEC = how, ADR = why-this-how, CLAUDE.md = how-we-work). Project-wide PRD/SPEC/ADRs were missing; this slice fills them.
- **Session-handoff protocol** documented in `CLAUDE.md` with `docs/plans/active|archive/` and `docs/sessions/` conventions. The journal you are reading is the canonical example.
- **GATE 3 cannot be skipped** for this slice because it modifies `skills/`, which is outside the GATE 3 skip allowlist (only doc-only changes outside `agents/` and `skills/` qualify).

## Changes

### PR #2 (merged as `5cf4573`)
- 6 plugin agents with explicit `model:` declarations (5 base + `agent-architect`)
- `hooks/delegation-guard.sh` (PreToolUse) + registration in `hooks/hooks.json`
- `docs/DELEGATION-RULE.md` and `docs/DELEGATION-RULE-SPECIALISTS.md`
- Audit chain ran clean: code-reviewer APPROVED after 1 fix round, security-auditor APPROVED after 1 fix round (HIGH bypass-on-spoofed-agent_id, MEDIUM `.claude/` whitelist over-permissive, MEDIUM symlink caveat — all addressed before merge)

### PR for `feature/global-docs-skeleton` (in flight at session end, expected as PR #3)
- `docs/PRD.md` (NEW)
- `docs/SPEC.md` (NEW, 136 lines, ≤200 target)
- `docs/adr/0001-0004` (NEW, 4 ADRs)
- `docs/plans/active/2026-04-26-global-docs-skeleton.md` (NEW, dogfooded plan)
- `docs/sessions/2026-04-26-rule-zero-implementation.md` (this file, NEW)
- `CLAUDE.md` (MOD): removed Project Structure + Skills by Phase (moved to SPEC.md), added Session-handoff protocol section
- `skills/batuta-project-hygiene/SKILL.md` (MOD via implementer Sonnet delegation): `Mode: project-init` now creates the doc skeleton when bootstrapping a new project. Line count 292 → 372.

### `~/.claude/` machine-wide cleanup (operator-local, not in any PR)
- 90 `settings.json.bak*` from Feb–Mar archived to `~/.claude/archive/2026-04-26/settings-baks/`
- `~/.claude/backups/batuta-dots-legacy-2026-04-17-1624/` (678 KB, 48 files) tarballed to `~/Documents/claude-archive/batuta-dots-legacy-2026-04-17.tar.gz` and removed
- 3 temporal project shells (paths under `AppData-Temp`, `WINDOWS/system32`) archived
- 2 inactive projects (`E--BATUTA-PROJECTS-CONCILIADOR-BANCARIO`, `E--BATUTA-PROJECTS-claude`) deleted with operator OK; recoverable from `~/.claude.surgery-2026-04-26.bak` (retained 7 days)
- Total `~/.claude/` size: 424 MB → 391 MB (-33 MB)
- `settings.json` and `~/.claude/CLAUDE.md` md5 hashes preserved before/after (no accidental edits)

### `~/.claude/CLAUDE.md` global update (operator-local, not in any PR)
- New section "Delegation-only main agent (Rule #0)" appended at end
- File grew 144 → 169 lines
- Pre-existing 9 sections intact

## Next

Next session entry point: `docs/plans/active/2026-04-26-global-docs-skeleton.md` @ audit chain (currently mid-GATE-2). After PR #3 merges and operator runs `/plugin update batuta-agent-skills`, the next slice is the E2E test (Phase 4.3 of the original mission: 3 calibrated prompts targeting Haiku, Sonnet, and `agent-architect` specialist creation, with token-by-model accounting and verification of the delegation chain).
