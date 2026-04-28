# Plan: v2.6 — Bundle completo (close all enforceable gaps post-v2.5)

**Slice ID:** `bundle-completo`
**Branch:** `fix/bundle-completo` (stacked on `fix/audit-scope-and-research-first` until PR #9 merges, then rebase onto main)
**Target version:** v2.6.0

## Context

After PR #9 (v2.5 — audit chain scope + research-first wired into base agents), the operator asked "qué nos falta para cubrir todas las brechas". Two parallel Explore audits identified:

1. **Critical recurring leak**: `agents/agent-architect.md` does not bake v2.5 enforcement patterns into its specialist-generation template. Every specialist created at runtime by the meta-agent re-introduces the gaps PR #9 just closed for `implementer` / `implementer-haiku` (research-first Step 2, dual-path build-log).
2. **Inheritance-only rule worth automating**: plan-mode persistence — Claude Code defaults plans to `~/.claude/plans/<auto-name>.md` instead of `<project>/docs/plans/active/<YYYY-MM-DD>-<slug>.md`. v2.4 chose convention; the implementer pre-flight catches the symptom, but the root cause persists per session.
3. **Verification gap**: PR #9 shipped four enforcement changes with no automated regression tests. v1.2 had an E2E harness for the delegation chain; v2.5 does not.
4. **Marginal**: `gh pr merge` blocking hook — analyzed and rejected (zero observed violations, single-operator workflow).

Operator decision: bundle completo. Ship items 1–3 in PR #10. Item 4 documented as deferred.

## Decisions taken during planning

- **Stop hook for plan-mode persistence is deferred to v2.7.** The hook was approved in the original plan but during execution-context analysis, hook surface for `ExitPlanMode` proved fragile: the tool's input does not expose the plan file path, so a hook would have to scan `~/.claude/plans/` for the most-recently-modified file — flaky under concurrent sessions or machine clock drift. Documented in ADR-0005. The slash command `/save-plan` ships as the primary mechanism.
- **E2E harness simplified to static validators.** Rather than invoking `claude` CLI in tests (flaky on model latency, version drift, headless flag changes), the harness is a set of bash scripts that grep-check the agent prompt files and skill files for the v2.5 contract patterns (Step 0 NOT-APPLICABLE block, Step 2 research-first block, dual-path build-log wording, batuta-agent-authoring verification rules 5–6 references). Static checks catch the highest-value regression case (someone removes a Step) without depending on live model behavior.
- **agent-architect remains a single file.** Considered splitting into `agent-architect.md` + a referenced `specialist-template.md`. Rejected: the meta-agent is already 138 lines and the inline template is more readable than indirect reference. Keep as is.

## Out of scope

- **Stop hook for plan-mode persistence (deferred to v2.7)** — fragile detection of the plan file path; revisit if the slash command proves insufficient
- **`gh pr merge` blocking hook (deferred indefinitely)** — single-operator workflow, zero violations observed; not worth a kill-switch
- **Runtime E2E harness invoking `claude` CLI** — replaced with static validators; revisit when CI infrastructure is in place
- Divergent-thinking, commit-discipline, GitHub-day-0, language-policy enforcement (operator habits, no automation viable without friction)
- Permission-mode awareness, CLAUDE.md sync automation, memory system audit (out of plugin scope or marginal value)

## Files to create or modify

### NEW

| File | Lines | Purpose |
|---|---|---|
| `.claude/commands/save-plan.md` | ~50 | Slash command that copies most-recent `~/.claude/plans/*.md` to `docs/plans/active/<YYYY-MM-DD>-<slug>.md` |
| `tests/v2.5-validators/README.md` | ~30 | Suite docs |
| `tests/v2.5-validators/run.sh` | ~40 | Orchestration — runs all validators, summarizes |
| `tests/v2.5-validators/01-auditor-not-applicable.sh` | ~30 | Validates code-reviewer/test-engineer/security-auditor each have Step 0 NOT-APPLICABLE block |
| `tests/v2.5-validators/02-implementer-research-first.sh` | ~30 | Validates implementer.md Step 2 has Context7 + `// Source:` markers |
| `tests/v2.5-validators/03-implementer-haiku-conditional.sh` | ~30 | Validates implementer-haiku.md Step 2 is conditional (mentions "if any task ... bumps a version" or similar) |
| `tests/v2.5-validators/04-architect-bakes-research-first.sh` | ~30 | Validates agent-architect.md Phase 5 includes research-first instruction for generated specialists |
| `tests/v2.5-validators/05-batuta-agent-authoring-rules.sh` | ~30 | Validates SKILL.md has verification rules 5–6 + 2 red flags |
| `docs/adr/0005-plan-mode-persistence-mechanism.md` | ~60 | ADR documenting why slash command over runtime hook |
| `docs/plans/active/2026-04-27-bundle-completo.md` | this file | Slice plan |

### MODIFIED

| File | Change |
|---|---|
| `agents/agent-architect.md` | Phase 5 gains 4 surgical edits: (1) dual-path build-log replaces hardcoded `specs/current/`; (2) new MUST-include bullet for research-first Step 2 in code-writing specialists; (3) new conditional bullet for Step 0 NOT-APPLICABLE in audit-gate specialists; (4) new programmatic check referencing `batuta-agent-authoring` verification rules 5–6 |
| `.claude-plugin/plugin.json` | Version 2.5.0 → 2.6.0; description updated |
| `docs/PRD.md` | v2.6 entry shipped; v2.7 candidate entry for plan-mode-persistence Stop hook with ADR-0005 reference; Last reviewed bumped |
| `docs/SPEC.md` | New "Layer 7 — Static contract validators" mirroring Layer 5/6 pattern |
| `docs/DELEGATION-RULE.md` | One-line reference to `/save-plan` in §"Audit chain scope" or §"Enforcement" |
| `CLAUDE.md` (project) | Mention `tests/v2.5-validators/run.sh` in §"Commands" |
| `user-settings/CLAUDE.md` + `~/.claude/CLAUDE.md` | Update plan-mode persistence paragraph: "v2.6 ships `/save-plan <slug>` slash command — run it after exiting plan mode to copy the plan to project-local `docs/plans/active/`" |

## Verification

1. **agent-architect static check**: post-edit `agents/agent-architect.md` Phase 5 contains research-first instruction, dual-path build-log, references to batuta-agent-authoring rules 5–6, conditional Step 0 instruction. Validator script `tests/v2.5-validators/04-architect-bakes-research-first.sh` returns PASS.
2. **agent-architect functional check (manual, post-merge)**: invoke meta-agent with a fake slice ("specialist for parsing BBVA bank statements"). Confirm generated `<project>/.claude/agents/<name>.md` has Step 2 research-first block, dual-path build-log, no `specs/current/` hardcode. Run batuta-agent-authoring rules 5–6 manually — both PASS.
3. **`/save-plan` integration check (manual)**: from a project with `docs/plans/active/`, exit plan mode (with a fake plan in `~/.claude/plans/`), run `/save-plan my-slug`. Confirm file appears at `docs/plans/active/<today>-my-slug.md` with correct content. Idempotency: re-run with same slug → error "file exists, choose different slug".
4. **Static validators**: `bash tests/v2.5-validators/run.sh` from repo root — all 5 cases PASS, exit code 0.
5. **Audit chain on this slice**: code-reviewer + security-auditor APPROVED. test-engineer can opt-in (the validators ARE tests). Slice touches `agents/`, `.claude/commands/`, `tests/`, `docs/`, `.claude-plugin/`, so it is NOT in the GATE 3 skip allowlist.
6. **Plugin version**: `plugin.json` reports 2.6.0; `docs/PRD.md` lists v2.6 entry.

## Open questions

None at session start. The runtime-hook-vs-slash-command decision is captured in ADR-0005.

## Order of execution

```
1. Persist this slice plan ✓ (just done)
2. Edit agents/agent-architect.md (4 surgical edits)
3. Write .claude/commands/save-plan.md
4. Write docs/adr/0005-plan-mode-persistence-mechanism.md
5. Write tests/v2.5-validators/ (8 files: README, run.sh, 5 cases, fixtures if needed)
6. Update docs/PRD.md, docs/SPEC.md, docs/DELEGATION-RULE.md, CLAUDE.md (project), user-settings/CLAUDE.md, ~/.claude/CLAUDE.md
7. Bump .claude-plugin/plugin.json
8. Run bash tests/v2.5-validators/run.sh — all PASS
9. Commit, push, open PR #10
```
