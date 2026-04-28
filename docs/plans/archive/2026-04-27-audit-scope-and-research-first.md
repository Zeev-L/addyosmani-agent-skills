# Plan: Audit chain scope + Research-first wired into subagents

**Slice ID:** `audit-scope-and-research-first`
**Branch:** `fix/audit-scope-and-research-first`
**Target version:** v2.5.0

## Context

Two complementary subagent-enforcement gaps surfaced from real use:

1. **Audit chain ran during exploration.** During an ad-hoc data-analysis session in a banking project the operator delegated to a domain specialist; the main agent then proactively fired the audit chain (`test-engineer → code-reviewer → security-auditor`) even though no code was produced. Operator had to interrupt and ask the main to stop. Root cause: `docs/DELEGATION-RULE.md` describes the chain as mandatory after any delegation, without scoping language that distinguishes implementation slices from exploration / planning / spec-writing / database queries.

2. **Research-first lives in CLAUDE.md but is not wired into subagent prompts.** The user-global `~/.claude/CLAUDE.md` has a non-negotiable "Research-first" rule (Context7 → web search → `// Source:` citation comment). It is meant to apply to every code-writing action. But neither `agents/implementer.md` nor `agents/implementer-haiku.md` has an explicit step for it — they inherit the rule through nested CLAUDE.md loading. When a subagent decides "I already know this library", it skips the lookup and ships outdated API usage. Same drift pattern as the audit chain bug: rule exists, no explicit step, no runtime guard.

Both bugs share the same shape: **a CLAUDE.md rule that isn't cabled into the subagent's prompt as a Step 0/0.5 produces drift**. Closing both in one PR keeps the theme tight and avoids two cycles of the audit chain on near-identical surfaces.

## Decisions

- **Audit chain scope is post-implementation only.** The chain runs after `implementer` / `implementer-haiku` / specialist returns code-touching work. During exploration, planning, ad-hoc DB queries, data analysis, spec-writing, ADR drafting, or pure conversation, the chain does NOT run.
- **Defense in depth, two layers.** (a) Documentary: new "Audit chain scope" section in `DELEGATION-RULE.md` with explicit "runs when" / "does not run when" tables. (b) Runtime: each auditor (`code-reviewer`, `test-engineer`, `security-auditor`) gains a Step 0 pre-flight that returns `AUDIT RESULT: NOT APPLICABLE` if `git diff --staged` and `git diff HEAD` both report no changes. The auditor refuses to invent findings.
- **Research-first is a Step 2 in implementer prompts.** Inserted between "read spec/plan/tasks" (Step 1) and "implement each task" (Step 3). Lookup is per-library mentioned in `tasks.md` — Context7 first, web search if no coverage, source-citation comment at every import site touched. Applies to every language with adjusted comment syntax.
- **Implementer-haiku gets a conditional research-first.** Haiku tasks are usually trivial (CSS, copy edit, rename) and don't introduce imports. But version bumps and dep-manifest flips DO touch libraries. So Step 2 in haiku reads "if any task in this slice modifies imports or dependency manifests, run Context7 lookup; otherwise skip". Cheaper than mandating it always.
- **`batuta-agent-authoring` gains a verification step.** Any new agent declaring `Edit`/`Write` in its tools list MUST include an explicit research-first instruction in its body (mirroring implementer/implementer-haiku) before the verification check passes. This stops new specialists created via `agent-architect` from re-introducing the gap.
- **No PostToolUse hook (deferred).** A regex-based hook that scans diffs for `import|require|use|from\s+\w+\s+import` lines without a nearby `// Source:` comment was discussed and rejected for v2.5: it adds runtime parsing surface, is language-fragile, and the documentary + Step 2 + agent-authoring trio is sufficient defense without it. Revisit if drift continues after v2.5 ships.

## Out of scope

- Hook-level research-first enforcement (deferred to potential v2.6 if drift continues)
- Updating `agents/agent-architect.md` template to mandate research-first in generated specialists (deferred — `batuta-agent-authoring` enforcement covers it for plugin agents; project-local specialists are handled by the hygiene of the skill)
- Changes to vendored skills under `skills/_vendored/`
- Runtime hook to detect audit-chain invocation outside of an implementation slice (the documentary contract + auditor Step 0 NOT-APPLICABLE return is sufficient)

## Files to create or modify

### NEW

- `docs/plans/active/2026-04-27-audit-scope-and-research-first.md` — this plan (dogfooding the v2.4 convention)

### MODIFIED

- `docs/DELEGATION-RULE.md` — add §"Audit chain scope" between current §"The mandatory chain" and §"Roles in one line each". Tables: "Runs when" (post-implementation, code diff present) / "Does not run when" (exploration, planning, spec-writing, ad-hoc queries). Reference the new auditor Step 0 as the runtime defense.
- `agents/code-reviewer.md` — add Step 0 pre-flight returning `AUDIT RESULT: NOT APPLICABLE` if no code diff. Re-numbered: Step 0 added; existing content unchanged.
- `agents/test-engineer.md` — same Step 0 pre-flight.
- `agents/security-auditor.md` — same Step 0 pre-flight.
- `agents/implementer.md` — insert Step 2 "Research-first lookup" between current Step 1 (read spec/plan/tasks) and current Step 2 (renumbered to Step 3). Add corresponding Absolute rule "every new or modified import has a `// Source:` citation comment".
- `agents/implementer-haiku.md` — insert conditional Step 2 "Research-first lookup if version bump or import change".
- `skills/batuta-agent-authoring/SKILL.md` — Verification step 5: "if the new agent declares `Edit`/`Write`/`MultiEdit` in `tools`, the body MUST include an explicit research-first instruction before any code-writing step".
- `user-settings/CLAUDE.md` — add a paragraph in §"Delegation-only main agent (Rule #0)" clarifying audit-chain-is-post-implementation-only. Sync to `~/.claude/CLAUDE.md` real.
- `.claude-plugin/plugin.json` — version 2.4.0 → 2.5.0. Description updated to reflect new scope.
- `docs/PRD.md` — roadmap entry for v2.5; bump "Last reviewed" to 2026-04-27.

## Verification

1. **Auditor NOT-APPLICABLE path** — invoke `code-reviewer` against a clean working tree (no `git diff`). Expect `AUDIT RESULT: NOT APPLICABLE` with the citation pointing at §"Audit chain scope". Repeat for `test-engineer` and `security-auditor`.
2. **Auditor normal path** — invoke after a real implementation slice (staged code changes). Expect normal review output ending with `AUDIT RESULT: APPROVED` or `BLOCKED`.
3. **Implementer research-first** — give the implementer a tasks file that mentions an external library (e.g. `requests`). Confirm the build-log shows a Context7 lookup was performed and the produced code has the `# Source: <url>` comment at the import.
4. **Implementer-haiku conditional path** — give haiku a CSS-only task. Expect it to skip research-first. Give haiku a version bump task. Expect it to run Context7.
5. **batuta-agent-authoring** — propose a fake new agent with `tools: [Edit]` but no research-first section. Expect the verification step to flag it.
6. **DELEGATION-RULE.md** — section parses as Markdown, tables render, link to auditor Step 0 is correct.
7. **Plugin version** — `plugin.json` reports 2.5.0, `docs/PRD.md` lists v2.5 entry.
8. **Audit chain on this slice** — `test-engineer`, `code-reviewer`, `security-auditor` all return APPROVED on the slice itself.

## Open questions

None at session start. The agent-architect template question was discussed and resolved as out-of-scope for v2.5 (covered by `batuta-agent-authoring` for plugin-level agents; project-local specialists rely on the same skill being invoked when authored).
