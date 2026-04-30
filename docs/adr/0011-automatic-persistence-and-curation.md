# ADR 0011 — Automatic persistence on commit + L1/L2/L3 vault curation pipeline + authoring-gate enforcement

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** jota-batuta
**Supersedes (in part):** ADR-0005 (`/save-plan`-only persistence model — see scope split below)

## Context

Three intertwined symptoms surfaced during the v3.8 strategic session (2026-04-29) and forced a single ADR:

1. **Persistence to Notion is 100% manual by design.** ADR-0005 deliberately rejected a Stop hook for plan persistence; the same logic was extended (informally) to skill `notion-kb-workflow`'s `--append` mode. The operator's `~/.claude/CLAUDE.md` declares "Use notion-kb-workflow at three points" as discipline, not enforcement. Audit of 33 repos in the operator's machines (`D:\` + `E:\BATUTA PROJECTS\`) confirmed that adoption is empirically zero outside the plugin's own repo: the gap between "must-trigger" text and runtime behavior is total.

2. **The vault is unstructured.** ADR-0011 planning treated captured journal entries as flat — the same level as curated decisions. The result was that supersede chains (e.g. `decisions/auth-001-jwt.md` followed by `decisions/auth-002-oauth.md`) coexist with equal weight, and `research-first-dev`'s lookup returns ambiguous hits. Knowledge captured is not knowledge curated.

3. **`MUST trigger X` declarations in CLAUDE.md are not enforcement.** During the v3.8 plan-mode session, the main agent itself violated `batuta-skill-authoring` and `batuta-agent-authoring` MUSTs by listing new skills/agents in the proposed plan without invoking the gates. The system permitted the violation. If the agent that helped write the rules can ignore them, downstream consumers will too.

## Decision

Three coupled decisions in one ADR because they are operationally inseparable: capture without curation is noise, persistence without enforcement is exhortation, and rules without runtime gates are documentation.

### D1 — Automatic persistence on `git commit` (not on `Stop`)

A new git `post-commit` hook (script: `hooks/post-commit-kb.sh`, **shipped in Sprint 1**) appends a structured bullet to `docs/sessions/<YYYY-MM-DD>-<slug>.md` for every accepted commit and mirrors the same bullet to a configured Obsidian vault at `<vault_root>/clients/<c>/projects/<p>/sessions/<YYYY-MM-DD>.md`. The hook is gated by `.claude/kb-config.json` per-project (opt-in; absent file = no-op).

**Why `git commit` and not `Stop`** — the `Stop` hook fires on every agent turn (interrupted, exploratory, dialogic). A `git commit` is an intentional event: the operator decided this work is worth keeping. ADR-0005's logic still holds for the `Stop` event, which is why ADR-0005 is NOT fully superseded — `/save-plan` remains the right mechanism for plan-mode persistence. ADR-0011 covers a different event (commit), with different semantics, and a different artifact (session journal, not plan).

### D2 — Vault structured in 4 levels (L0–L3) with explicit L1→L2 curation

| Level | Surface | Writer | Volatility |
|---|---|---|---|
| L0 | `_inbox/` | operator manual (Notion export, free capture) | high |
| L1 | `journals/`, `clients/<c>/projects/<p>/sessions/`, mirrors of `docs/sessions/` | git post-commit hook | append-only |
| L2 | `decisions/`, `gotchas/`, `playbooks/` (cross-cliente OR `clients/<c>/projects/<p>/{decisions,gotchas}/`) | skill `kb-curate` (operator-assisted) | one source-of-truth per topic |
| L3 | `glossary/{products,domains,people}/` | operator + auto-promotion | stable |

L1→L2 promotion is explicit, never automatic: the new skill `kb-curate` (Sprint 2) reads journal bullets without `curated_into:` frontmatter, classifies each into one of 7 categories (decision-new/supersede, gotcha-new/update, playbook-candidate, glossary-entry, noise), and applies a hybrid control matrix:

- decisions/playbooks/gotcha-update → `.draft.md` requires manual review
- gotcha-new/glossary → auto-apply (low risk, high value for backlinks)
- noise → marked `curated_into: []` for idempotency

`kb-curate` has 4 invocation triggers (all converge to the same logic): on-PR-merge (GitHub Action), `/kb-curate` slash, weekly cron Mondays 9am, and `/kb-end-session`. The new agent `kb-curator` (Sprint 2) runs the classification.

`research-first-dev` Step 1.5 (Sprint 2) prioritizes L2 strongly over L3, falls back to L1 only with disclaimer "no curado, verificá".

### D3 — Authoring-gate enforcement (Sprint 0, this PR)

Two MUSTs declared in `CLAUDE.md` are converted from text to runtime enforcement:

- **MUST-A (skill authoring)**: rule `rules/authoring/skill-authoring-required.md` + hook `hooks/pre-write-skill-gate.sh`. Marker: `.claude/.authoring-marker-skill-<ISO>` written by `batuta-skill-authoring` Step 4. 60-min TTL. Scope: `**/skills/**/SKILL.md` creation in repos whose origin matches `batuta-agent-skills`. Bypass: `BATUTA_SKILL_AUTHORING_BYPASS=1`.
- **MUST-B (agent authoring)**: rule `rules/authoring/agent-authoring-required.md` + hook `hooks/pre-write-agent-gate.sh`. Marker: `.claude/.authoring-marker-agent-<ISO>` written by `batuta-agent-authoring` Step 5 OR `agent-architect` Phase 5.0. 60-min TTL. Scope: `**/agents/**.md` creation. Bypass: `BATUTA_AGENT_AUTHORING_BYPASS=1`.

Both hooks are registered in `hooks/hooks.json` for the plugin runtime and validated by 11 test cases in `tests/authoring-gate/` (5 skill + 6 agent — including bypass, stale-marker, edit-vs-create boundary, and project-local scope). All 11 pass at PR open. The existing `tests/v2.5-validators/run.sh` continues to pass (10/10) — no regression.

The gates are repo-scoped: editing SKILL.md/agents in any repo other than `batuta-agent-skills` is unaffected (the hook walks up to find `.claude-plugin/` then verifies the git remote regex). Project-local agents under `<project>/.claude/agents/` are gated regardless of origin (rule applies to any repo that imports the rule via `@.claude/rules/authoring/agent-authoring-required.md`).

## Alternatives considered

### Alt 1 — Stop hook for journal persistence (rejected, see ADR-0005 reasoning)
Inherits ADR-0005's rejection: Stop fires on every turn, requires heuristic to detect intent, runs even when no commit was made. Commit-time hook is the correct event.

### Alt 2 — Runtime auto-curation L1→L2 without operator review
Rejected. Curation is a synthesis act with stakes (a wrong supersede entry shadows the right one in research-first lookup). Operator must own decisions/playbooks/gotcha-update updates. Auto-apply is reserved for low-risk categories (gotcha-new, glossary).

### Alt 3 — Move `agent-architect` to plugin-level enforcement (instead of marker-as-exception)
Rejected. `agent-architect` is a runtime sub-agent; making it the gate would couple two responsibilities (specialist creation + enforcement metadata) and break the analogous skill gate (`batuta-skill-authoring` already plays the same role for skills). Marker-as-exception keeps both paths symmetric.

### Alt 4 — Single rule "authoring required" covering both skills and agents
Rejected. Markers, paths, bypass env vars, and skills-that-leave-the-marker are distinct between the two surfaces. Splitting into MUST-A and MUST-B keeps each rule short (≤200 lines) and lets the operator bypass one without touching the other.

## Consequences

### Positive
- Authoring violations are now blockable at runtime, not just at code-review time.
- The vault structure makes "conectar puntos" between similar projects (Prophet/SAP vs Prophet/ICG) feasible via Obsidian backlinks + L2 curation.
- Persistence becomes proactive (every commit), removing the discipline tax on the operator.
- ADR-0005's `/save-plan` mechanism remains intact for plan-mode artifacts.

### Negative / Costs
- Two new hooks add ~5–10ms latency per `Write` to plugin paths (acceptable; same magnitude as `delegation-guard`).
- The git post-commit hook needs per-project `.claude/kb-config.json` to opt in (small one-time setup, handled by `batuta-project-hygiene` paso 4c — Sprint 1).
- Drive + git interaction (Obsidian vault on Google Drive Desktop) needs `.git/` excluded from sync — TODO Sprint 1.
- Compliance certification (ISO 27001 / SOC 2) requires backup off-site formal, key rotation, access review — out of scope for this ADR.

### Migration path
- Sprint 0 (this PR): authoring gates + tests + ADR.
- Sprint 1: vault git bootstrap + `post-commit-kb.sh` + `batuta-kb-vault` skill + ADR-0005 status update to `Superseded in part by 0011`.
- Sprint 2: curation pipeline (`kb-curate` + `kb-curator` + Step 1.5).
- Sprint 2.5: `kb-backfill` for legacy repos (4 phases: README/commits/issues/code).
- Sprint 3: project-retrofit on 4 pending repos.
- Sprint 4: Notion migration to `_inbox/` + drenaje + reescritura `notion-kb-workflow`.

## Verification

Verification of D3 (in this PR):
- 11/11 authoring-gate test cases pass: `bash tests/authoring-gate/run.sh`
- 10/10 v2.5-validators pass (no regression): `bash tests/v2.5-validators/run.sh`
- Manual: in a fresh batuta-agent-skills clone, attempt `Write skills/foo/SKILL.md` without invoking `batuta-skill-authoring` → blocked. Then invoke skill, write marker (Step 4), retry → allowed.

Verification of D1, D2 (Sprints 1–2): documented in `docs/plans/active/2026-04-29-kb-pipeline.md` Verification section, test cases 1–20.

## Discovery results (Sprint 0)

The authoring gates were used immediately to validate the 6 candidates from the v3.8 plan. All 6 produced **CREATE** decisions:

| Candidate | Type | Rationale |
|---|---|---|
| `batuta-kb-vault` | skill | Distinct from `notion-kb-workflow`: Obsidian + L0-L3 levels are net-new |
| `kb-curate` | skill | No equivalent — L1→L2 promotion with 7-category matrix is novel |
| `batuta-status` | skill | No equivalent — cross-project status with KB awareness |
| `kb-backfill` | skill | No equivalent — 4-phase legacy extraction (README + commits + issues + code) |
| `kb-curator` | agent | Distinct from implementer/code-reviewer (markdown classification, not code) |
| `kb-backfiller` | agent | Distinct from implementer (read-only legacy extraction); distinct from kb-curator (sources from repos, not journals) |

Implementation of these 6 happens in Sprints 1–2.5, each preceded by re-invoking the appropriate authoring gate (markers expire after 60 min).

## Post-merge follow-ups (operator)

1. Run `/plugin update batuta-agent-skills` to load the new hooks into the installed plugin (current session has source changes that are not yet active in the runtime).
2. Optional: register the hooks in `~/.claude/settings.json` user-global as redundancy. Path must point at the installed plugin: `bash "${HOME}/.claude/plugins/marketplaces/batuta-agent-skills/hooks/pre-write-skill-gate.sh"`.
3. Sprint 1 kickoff: bootstrap `<vault_root>` (`E:\Gdrive Batuta\My Drive\BATUTA AI\OBSIDIAN\BATUTA`) as `git init` + `gh repo create jota-batuta/batuta-kb --private`.
