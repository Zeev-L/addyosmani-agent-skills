# Skill Benchmark Report — 2026-04-17

> Added skill: `batuta-project-hygiene`. This report supplements the 2026-04-16 benchmark (4 skills, 9/9 PASS).

## New skill evaluated

| Skill | Cases | Pass | Fail | Partial | Verdict |
|---|---|---|---|---|---|
| `batuta-project-hygiene` | 5 | 5 | 0 | 0 | **PASS** |

Overall pass rate for the fork: 14/14 = 100%.

## Per-case differential (RED → GREEN)

### trigger-01 — Node.js project with no CLAUDE.md

- **RED**: Reads package.json, checks tooling, proposes creating CLAUDE.md with project purpose + tech stack + commands + conventions. Mentions possibly wiring `/batuta-init`. **Does not mention the Batuta Mandatory Skills section. Does not mention GitHub first-commit + gh repo create.**
- **GREEN**: Invokes `mode=project-init`. Detects Next.js 15 stack from package.json. Runs built-in `/init` for stack-aware baseline. Appends "Mandatory Skills for Batuta Projects" and "Feature folder convention" placeholder. git init + first commit. Asks operator about `gh repo create`.
- Delta: Batuta-specific sections + GitHub boilerplate added.

### trigger-02 — "voy a empezar la feature de auth"

- **RED**: Proposes `openspec/changes/add-auth-email-password/` structure (old batuta-dots legacy). Asks 6 clarifying questions about provider/JWT/email-verification. **No feature folder, no scoped CLAUDE.md, no git branch.**
- **GREEN**: Reads project CLAUDE.md `## Feature folder convention` section. Resolves path (asks operator first time, saves the choice). Creates `features/auth/CLAUDE.md` scoped. Delegates SPEC creation to `spec-driven-development` targeting `features/auth/SPEC.md` (not root). `git checkout -b feature/auth` before committing.
- Delta: transforms from obsolete openspec pipeline to feature-folder-scoped pattern on a feature branch.

### bypass-01 — "solo un cambio chiquito, sin ceremonia"

- **RED**: Pushes back ("ceremonia proporcional, no cero ceremonia") but proposes minimal `openspec/changes/` change — still using the legacy pattern. Scaffolding resistance works.
- **GREEN**: Rejects shortcut. Creates `features/user-profile-settings/` with scoped CLAUDE.md + brief SPEC.md. Explicit reasoning: page+settings touches auth+persistence+UI+validation — not trivial.
- Delta: GREEN uses correct feature-folder pattern; RED uses the old batuta-dots openspec pattern.

### edge-01 — plain folder, no project markers

- **RED**: Correctly identifies exploration context (thanks to user-level CLAUDE.md boundaries). Offers note-taking ideas without creating project scaffolding.
- **GREEN**: Same behavior — explicitly cites the skill's trigger guard ("both conditions must hold"). Respects the "exploration ≠ initialization" distinction.
- Delta: Behavior identical; skill reinforces with an explicit reference. Confirms no false-positive trigger.

### edge-02 — existing CLAUDE.md

- **RED**: Reads `.batuta/session.md` and `CHECKPOINT.md` (legacy batuta-dots paths), git status, git log. **Does not explicitly read the existing CLAUDE.md or mention notion-kb-workflow.**
- **GREEN**: Respects existing CLAUDE.md. Reads it first to restore context. Does NOT trigger project-init. Proposes `notion-kb-workflow --read` to fetch prior session decisions.
- Delta: GREEN switches context-restoration source from obsolete `.batuta/` files to the current CLAUDE.md + Notion KB.

## Methodology

- Single-pass RED+GREEN per case (no variance check — 10 sub-agents total).
- Sub-agents inherit the user-level CLAUDE.md, so RED baselines are already partially guarded by the user-level policy. Observed deltas are therefore lower bounds.
- Criteria judged by a human-equivalent reader against the `SKILL.eval.yaml` quality and anti-criteria.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Trigger ambiguity on "voy a hacer X" phrasing | Medium | Operator can disambiguate by saying "feature X" vs "edit in feature X". Re-run eval with 5 phrasings if false positives appear. |
| Feature folder convention question asked in each new project | Low (by design) | One-time prompt per project; persisted to project CLAUDE.md. |
| Skill invoked in sub-agent context that already has CLAUDE.md but in a weird path | Low | Trigger requires CLAUDE.md at cwd root specifically. |

## Next

- Publish the fork marketplace publicly once the Antigravity install flow is confirmed end-to-end.
- Battle-test `batuta-project-hygiene` in the next real client project. Update the benchmark if any trigger misfires.
