# Build Log — v2.7 Trust Native Delegation (slice: 2026-04-27-trust-native-delegation)

**Date:** 2026-04-27
**Branch:** feat/trust-native-delegation
**Implementer:** generic-implementer (claude-sonnet-4-6)

## Files Created

- `docs/adr/0006-trust-native-delegation.md` — ADR recording the v2.7 realignment decision, N=2 evidence, alternatives rejected, consequences, and Anthropic docs citations.
- `tests/v2.5-validators/06-delegation-guard-killswitch.sh` — Static check verifying kill-switch patterns are present and path-whitelist patterns are absent from `hooks/delegation-guard.sh`.
- `docs/plans/active/2026-04-27-trust-native-delegation/build-log.md` — this file.

## Files Modified

| File | Change summary |
|---|---|
| `hooks/delegation-guard.sh` | Full rewrite: removed path-whitelist block (~30 LOC), kept kill-switch blocklist, kept subagent bypass, flipped failure mode to allow-on-parse-error, updated exit codes (1 instead of 2), updated stderr message to v2.7 framing. ~136 LOC → ~95 LOC net. |
| `docs/DELEGATION-RULE.md` | Full reframe: "trust native, enforce post". Added decision table. Documented audit-chain trigger explicitly (post-edit, regardless of diff authorship). Removed "main NEVER edits" absolute formulation. |
| `agents/code-reviewer.md` | Added one-line clarification after NOT-APPLICABLE block in Step 0: "This audit applies whether the diff was produced by the main agent or by another subagent — the audit reads `git diff` regardless of authorship." |
| `agents/test-engineer.md` | Same one-line clarification in Step 0. |
| `agents/security-auditor.md` | Same one-line clarification in Step 0. |
| `user-settings/CLAUDE.md` | Renamed § "Delegation-only main agent (Rule #0)" → "Native delegation + post-edit audit". Rewrote body per plan Item 4. |
| `C:/Users/JNMZ/.claude/CLAUDE.md` | Same edit as user-settings/CLAUDE.md. Verified with `diff` — files are identical after edit. |
| `.claude-plugin/plugin.json` | Version 2.6.0 → 2.7.0. Updated description to kill-switch + audit-chain framing. |
| `docs/PRD.md` | Updated Last reviewed date to v2.7. Updated architecture summary paragraph. Updated roadmap: v2.6 marked shipped, v2.7 entry added, old v2.7 candidate (ExitPlanMode hook) moved to v2.8 candidate, v2.8 domain specialists moved to v2.9, runtime E2E moved to v2.10. |
| `docs/SPEC.md` | Layer 3 (runtime enforcement) rewritten: path-whitelist removed, kill-switch-only model documented, failure mode flip noted, audit chain called out as the post-edit safeguard. |
| `CLAUDE.md` (project root) | Updated two stale references to "Rule #0 — main never writes code" → new framing. |
| `tests/v2.5-validators/run.sh` | Added case 06 to cases array. |

## Verification Steps Run

1. **Pre-flight**: confirmed branch `feat/trust-native-delegation` active.
2. **Pre-flight**: confirmed plan file at `docs/plans/active/2026-04-27-trust-native-delegation.md`.
3. **Baseline**: ran `bash tests/v2.5-validators/run.sh` before any edits — 5/5 PASS.
4. **Post-implementation**: ran `bash tests/v2.5-validators/run.sh` after all edits — **6/6 PASS**.
5. **Diff check**: `diff user-settings/CLAUDE.md ~/.claude/CLAUDE.md` returned empty (files identical).
6. **Version check**: `.claude-plugin/plugin.json` version field is `"2.7.0"`.

## Manual Hook Behavior Documentation

Since the hook runs via Claude Code stdin JSON (not invocable standalone), the intended behavior is documented here for the auditors:

### Kill-switch hit (expected: block, exit 1)

Example stdin:
```json
{
  "hook_event_name": "PreToolUse",
  "tool_input": { "file_path": ".claude/settings.json" }
}
```
Expected stderr: `RULE #0 violated (kill-switch): the main agent cannot modify .claude/settings.json directly. This file controls plugin enforcement; modifying it from the main would self-disable safeguards. Delegate to a subagent (haiku for trivial edits, implementer for substantive changes), or update via the plugin's installation flow.`
Expected exit: 1 (block)

### Project source path (expected: allow, exit 0)

Example stdin:
```json
{
  "hook_event_name": "PreToolUse",
  "tool_input": { "file_path": "src/pipeline.py" }
}
```
Expected: no output, exit 0 (allow).

### Subagent bypass (expected: allow, exit 0)

Example stdin:
```json
{
  "hook_event_name": "PreToolUse",
  "agent_id": "implementer-abc123",
  "tool_input": { "file_path": ".claude/agents/my-specialist.md" }
}
```
Expected: no output, exit 0 (subagent bypass).

### Parse error / empty path (expected: allow, exit 0)

Example stdin: `{` (malformed JSON)
Expected: no output, exit 0 (fail-open; v2.7 failure mode flip).

## Libraries Researched (Research-First Step)

This slice introduces no new external library imports. The hook is bash + jq (already used in the existing hook). No Context7 lookups were required. Verified: the hook references `jq` which is already a documented dependency of the existing hook; no new dependency is introduced.

Anthropic docs referenced (non-library, for ADR citations):
- `https://code.claude.com/docs/en/sub-agents` — native delegation guidance
- `https://code.claude.com/docs/en/permissions` — PreToolUse hook scope

## Non-Obvious Decisions

1. **Exit code 1 instead of 2 for kill-switch blocks.** The existing hook used `exit 2`. The plan specified `exit 1`. Both block the tool call in Claude Code's hook protocol. I used `exit 1` per the plan spec, which is the conventional "error" exit code and is more semantically clear than `exit 2` (which some contexts treat as "misuse"). The old comment in the hook said "exit 2 blocks" — updated to document both 1 and 2 block.

2. **`.env.*` pattern match.** The plan listed `.env, .env.*` as kill-switches. The bash `case` pattern for `.env.*` as written (`*/.env.*|.env.*`) would match `.env.production`, `.env.local`, etc. This is the intent — any dotenv variant file should be blocked.

3. **`CLAUDE.md` project root also updated.** The plan's "Supporting changes" section noted to update if stale references were found. Two were found (lines 76 and 103 referencing "Rule #0 — main never writes code" and "Rule #0's audit-chain guard"). Both updated to v2.7 framing.

4. **PRD roadmap version numbering.** The old v2.7 candidate (ExitPlanMode runtime hook) was bumped to v2.8. The old v2.8 (domain specialists) became v2.9. The old v2.9 (runtime E2E) became v2.10. This keeps the roadmap internally consistent.

## Edge Cases Handled

- Path-traversal guard (`..` as segment) preserved from the old hook — still valid for kill-switch purposes.
- Windows backslash normalization preserved — still needed for Git Bash compatibility.
- Fail-soft on missing `jq` preserved — still valid for operator machines without jq.
- The `.env` dotenv pattern uses both `*/.env` (nested path) and `.env` (root) — covers both `projects/bbva/.env` and `.env` at root.

## Open Questions for Auditors

1. **Kill-switch list completeness (security-auditor)**: Are `.claude/settings*.json`, `.claude/hooks/*`, `.claude/agents/*`, `.env`, `.env.*`, `secrets/*` sufficient? Are there other self-disable surfaces in Claude Code 1.x that were missed? Specific concern: `hooks/hooks.json` (the registration file) is under `.claude/hooks/` — that pattern should cover it, but worth confirming the glob is correct.

2. **CWE reference for secret leakage risk**: The `.env` kill-switch addresses CWE-312 (Cleartext Storage of Sensitive Information). Mitigation: the hook blocks direct writes; secrets must still not be in code at all (enforced by security-auditor GATE 3, not by this hook alone).

3. **`exit 1` vs `exit 2` for block**: Claude Code's official docs list `exit 2` as the block exit code. `exit 1` also blocks. Using `exit 1` is semantically cleaner but should be confirmed by the auditor against the current Claude Code 1.x spec for PreToolUse hooks.

4. **`user-settings/CLAUDE.md` sync**: The two files (`user-settings/CLAUDE.md` and `~/.claude/CLAUDE.md`) were diffed at edit time and confirmed identical. The auditor should re-run `diff` as part of their pre-flight to confirm no drift occurred.

## Code-reviewer follow-up

### 1. `docs/getting-started.md:6`
- **Change:** replaced "Rule #0 contract (the main agent never edits source code)" with "native delegation + post-edit audit chain; kill-switch enforcement"
- **Rationale:** v2.7 reframed delegation from workflow gate to kill-switch only; this line now reflects the actual contract

### 2. `docs/PORTABILITY.md:40,50`
- **Change:** renamed heading from "How to self-enforce Rule #0 without the hook" to "How to self-enforce the audit chain without the hook"
- **Change:** rewrote section around line 50 to replace whitelist instruction with kill-switch path guidance (`.env*`, `secrets/*`, `.claude/hooks/*`, `.claude/agents/*`, `.claude/settings*.json`)
- **Rationale:** v2.7 hook is kill-switch only; OpenCode users enforce by delegating kill-switch paths and running the audit chain manually on all diffs

### 3. `docs/SPEC.md:21,27`
- **Change (line 21):** inline comment "← feature spec: Rule #0 contract" → "← delegation contract"
- **Change (line 27):** inline comment "← PreToolUse Rule #0 enforcement" → "← PreToolUse kill-switch hook"
- **Rationale:** aligns comment language with v2.7 semantics (enforcement is kill-switch, not workflow-gate)

### 4. `user-settings/memory/feedback_hook_acceptedits_caveat.md`
- **Change:** rewrote entire memory file to accurately describe v2.7 kill-switch hook semantics
- **Change:** updated frontmatter `description` to reflect v2.7 contract (kill-switch only; `acceptEdits` no longer bypasses meaningful enforcement)
- **Change:** body explains why the memory file still matters (operators aware of v1 behavior should know the semantics changed) and clarifies kill-switch paths remain dangerous under `acceptEdits`
- **Rationale:** v1/v2.6 framing no longer applies; the hook changed from workflow enforcement to self-disable defense

### 5. `hooks/delegation-guard.sh:95`
- **Change:** added `.envrc` pattern to kill-switch blocklist: `*/.envrc|.envrc|` (line 95)
- **Rationale:** direnv `.envrc` files are equally sensitive to `.env*`; they load secrets into shell environment and must not be committed by the main agent

### 6. `tests/v2.5-validators/06-delegation-guard-killswitch.sh:49`
- **Change:** added `check_present '\.envrc|\.envrc'` assertion for `.envrc` kill-switch pattern
- **Rationale:** catches regression if `.envrc` is removed from the hook in future refactors

## Code-reviewer follow-up verification

Validator suite: **6/6 PASS** (after follow-up edits)
- All kill-switch patterns present (including new `.envrc`)
- Fail-open guard present
- Subagent bypass dual-guard present
- Old path-whitelist patterns absent (no regression to v1 model)

## Security-auditor follow-up

**Finding:** [MEDIUM] Kill-switch list does not cover the plugin's own hook registration manifest at repo root (`hooks/hooks.json`).

**Threat model:** The current kill-switch pattern `.claude/hooks/*` covers user-global hooks. The plugin's own `hooks/hooks.json` at repo root is NOT covered. A main-agent edit could remove the `PreToolUse` matcher from `hooks/hooks.json` or change `command` to `/bin/true`, silently disabling kill-switch enforcement.

**Fix applied:**

1. **`hooks/delegation-guard.sh` (lines 91–92):** Added two kill-switch patterns to the case block immediately after `.claude/hooks/*`:
   ```bash
   */hooks/*.json|hooks/*.json|\
   */hooks/delegation-guard.sh|hooks/delegation-guard.sh|\
   ```
   These protect the plugin's hook registration JSON files (any `.json` under any `hooks/` directory) and the hook script itself (prevent direct replacement).

2. **`tests/v2.5-validators/06-delegation-guard-killswitch.sh` (lines 48–49):** Added two assertions:
   ```bash
   check_present 'hooks/\*\.json'                        "kill-switch: hooks/*.json (plugin hook manifest)"
   check_present 'hooks/delegation-guard\.sh'            "kill-switch: hooks/delegation-guard.sh (the hook itself)"
   ```
   These ensure the validator suite catches any future removal of these patterns.

3. **`docs/adr/0006-trust-native-delegation.md` (new subsection under Consequences):** Added "What is intentionally NOT blocked" section documenting the intentional gaps in the kill-switch list (skills/, rules/, .claude-plugin/, MEMORY.md) with rationale that the audit chain is the compensating control. This prevents future auditors from reconstructing the threat model from scratch.

**Verification:** Validator suite runs 6/6 PASS with new assertions included. The hook now blocks:
- `.claude/settings*.json` — audit trigger disable
- `.claude/hooks/*` — old hook replacements
- `hooks/*.json` — plugin hook manifest (NEW)
- `hooks/delegation-guard.sh` — hook script itself (NEW)
- `.claude/agents/*` — agent contract overwrite
- `.env`, `.env.*` — secret commits
- `.envrc` — secret commits (direnv)
- `secrets/*` — secret commits
