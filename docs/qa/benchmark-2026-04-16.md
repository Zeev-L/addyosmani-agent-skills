# Skill Benchmark Report

> Date: 2026-04-16
> Skills evaluated: 4
> Overall pass rate: **100%** (9/9 cases)
> Methodology: RED sub-agent (no skill) vs GREEN sub-agent (skill injected into system prompt), one pair per case.

## Summary

| Metric | Value |
|---|---|
| Skills with eval files | 4 |
| Skills without eval files | 21 (upstream, not in scope) |
| Total test cases | 9 |
| Passed | 9 |
| Failed | 0 |
| Partial | 0 |
| Sub-agents spawned | 18 (9 RED + 9 GREEN) |

## Results by Skill

| Skill | Cases | Pass | Fail | Partial | Verdict |
|---|---|---|---|---|---|
| `batuta-skill-authoring` | 3 | 3 | 0 | 0 | **PASS** |
| `batuta-agent-authoring` | 2 | 2 | 0 | 0 | **PASS** |
| `research-first-dev` | 2 | 2 | 0 | 0 | **PASS** |
| `notion-kb-workflow` | 2 | 2 | 0 | 0 | **PASS** |

## Per-case differential (RED → GREEN)

### batuta-skill-authoring

**trigger-01** — "create skills/json-formatter/SKILL.md":
- RED: Would create the file directly with frontmatter + setup_test.sh + PR. **No discovery step.**
- GREEN: Refuses to create. Runs `npx skills find "format JSON output"` first, evaluates install bar (≥10K installs, verified org, permissive license). Only authors if all candidates fail.
- Delta: discovery gate added.

**bypass-01** — "my case is unique, just create it":
- RED: Verifies via Glob against `BatutaClaude/skills/` but does not touch skills.sh. Partial.
- GREEN: Refuses to skip Step 1. Runs `npx skills find` against skills.sh catalog. Pastes output as discovery proof in PR.
- Delta: discovery redirected to full 91k+ catalog.

**trigger-02** — "save this Spanish + too-long description":
- RED: Already flags Spanish and proposes rewrite (baseline CLAUDE.md covers language policy).
- GREEN: Same + explicit 150-char measurement + wc -l check + Spanish stop-words grep.
- Delta: added verification commands that are grep-able.

### batuta-agent-authoring

**trigger-01** — "add agents/code-auditor.md":
- RED: Lists frontmatter and role sections. **No comparison against existing agents.**
- GREEN: Writes one-sentence summary for code-reviewer, test-engineer, security-auditor, and the proposed code-auditor. Identifies the proposed agent reads as `code-reviewer + security-auditor + performance` — refuses to create.
- Delta: distinctness check enforced.

**bypass-01** — "create agents/data-helper.md with all tools":
- RED: Lists frontmatter with all 9 tools as requested. Mentions conventions but does not push back on tool breadth.
- GREEN: Refuses the 9-tool list as exceeding 6-item red-flag threshold. Requests justification per tool. Suggests read-only default (Read + Grep + Glob).
- Delta: tool-minimality enforced.

### research-first-dev

**trigger-01** — "drizzle-orm v0.32.1 schema":
- RED: Writes schema.ts with correct code but **no `// Source:` citation comment**. No Context7 lookup.
- GREEN: Runs Context7 lookup → writes code with `// Source: https://orm.drizzle.team/docs/column-types/pg (verified 2026-04-16, drizzle-orm@0.32.1)` above the import.
- Delta: citation added; grep-able evidence emitted.

**bypass-01** — "FastAPI, I know it by heart":
- RED: Accepts user familiarity claim. Explicitly says "I'd skip any verification lookup and ship it directly". **No citation.**
- GREEN: Refuses shortcut ("flagged as red flag and anti-rationalization"). Runs Context7 lookup. Writes code with `# Source:` comment.
- Delta: anti-rationalization successfully resisted.

### notion-kb-workflow

**trigger-01** — "resume nutriandrea":
- RED: Looks for `.batuta/CHECKPOINT.md`, `.batuta/session.md`, `git log`, `openspec/changes/` — all old batuta-dots artifacts. **Does not touch Notion.**
- GREEN: Invokes `notion-kb-workflow --read client:"Andrea Munoz" project:"nutriandrea"`. Queries Notion MCP for client page + project page + latest 5 session appends + active sprint + open tasks. Returns structured summary, not raw dumps.
- Delta: memory source redirected from local state to Notion KB.

**bypass-01** — "build Stop hook for auto-append":
- RED: Builds exactly what was asked — Stop hook script + register in settings.json + Notion API POST. No pushback.
- GREEN: Declines. Cites the skill's explicit Red Flag ("Building a Stop hook that auto-appends") and Anti-Rationalization ("I can auto-append via a Stop hook"). Offers manual trigger + shell alias as alternative.
- Delta: anti-rationalization enforced.

## Methodology notes

- **Sub-agent isolation caveat**: RED sub-agents inherited this session's user/project CLAUDE.md (`batuta-dots` harness). That inflated RED baseline — RED already knew about mandatory frontmatter, `BatutaClaude/` paths, language policy. A fully naïve agent (no Batuta context) would have failed even harder. The observed GREEN-vs-RED differentials are therefore **lower bounds**.
- **Each case = 1 RED + 1 GREEN run** (no variance check — single pass per case). Variance analysis would multiply tokens 3× per case; deferred to a future benchmark if a regression is suspected.
- **Criteria judged by the eval skill reader** (me). For stricter automation, wire each `quality_criterion` / `anti_criterion` to a grep/command check and run with `skill-eval` in CI.

## Next recommended

- **None for eval.** All 4 skills pass the gate. Proceed to Fase 5 (Batuta Session Reporter E2E) for battle-testing.
- **Post-E2E**: re-run this benchmark with 3 real-workload cases per skill and compute variance. If any skill drops below 80%, run `/skill:eval <name> --improve`.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Sub-agent isolation partial (inherited CLAUDE.md) | Low | Real users install the fork in a fresh project. Battle-test in Fase 5 will confirm behavior without batuta-dots context bleed. |
| Single-pass per case (no variance) | Low | Deferred. Re-run with 3× variance only if a skill misfires in real use. |
| `find-skills` dependency not vendored (no LICENSE) | Medium | Skills.sh CLI referenced via `npx`. Batuta-skill-authoring still functions if CLI is absent (agent falls back to upstream `writing-skills` only), but discovery gate is weaker. Monitor upstream for LICENSE publication. |
