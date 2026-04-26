# Plan: Layer `rules/` para batuta-agent-skills

**Slice ID:** rules-layer
**Branch:** feature/rules-layer
**Started:** 2026-04-26
**Status:** active

## Context

PR #2 (delegation system) y PR #3 (doc graph + cross-tool portability) ya mergeados. El plugin v1.2.0 distribuye Rule #0 enforcement + 6 agents + audit chain + project-wide doc graph.

Esta slice agrega un layer `rules/` complementario a `skills/`:

- `skills/` = workflows auto-invocables ("¿qué hago cuando ocurre X?")
- `rules/` = invariantes declarativas importables a la carta ("¿cómo debe verse el código siempre?")

`rules/` permite a un proyecto cualquiera consumir convenciones de ingeniería reusables sin copiar contenido entre `CLAUDE.md` de cada proyecto. El consumo es vía `@<path>` import en CLAUDE.md, con symlinks `.claude/rules/<rule>.md` → plugin/rules/<rule>.md como puente portable cross-developer.

## Decisiones (resueltas con el operador)

- D-1: Symlinks `.claude/rules/` + setup script
- D-2: Mínimo viable — 3-4 rules core extraídas de material existente
- D-3: N=2 proyectos (rules del global cuentan como universales)
- D-4: Cadencia trimestral

## Out of scope explícito

- Slice B3 (rollout a proyectos vivos uno por uno) — trabajo per-proyecto post-merge
- Rules de `stack/` y `domain-co/` — los seeds quedan vacíos hasta cumplir N=2
- Migración de `references/` a `rules/` — los 4 checklists existentes siguen donde están
- Cambios al hook `delegation-guard.sh` — `.claude/*` ya está en el whitelist

## Files to create / modify

### NEW

- `rules/README.md` — propósito + boundary con skills/ + índice
- `rules/_meta/how-to-import.md` — protocolo de consumo (Parte B en formato user-doc)
- `rules/_meta/rule-template.md` — formato canónico §A.4 vacío
- `rules/_meta/templates/CLAUDE.md.template` — plantilla CLAUDE.md consumidor
- `rules/core/research-first-citations.md` — extraído de `~/.claude/CLAUDE.md` Research-first
- `rules/core/secrets-and-pii.md` — invariante de seguridad universal
- `rules/core/code-style.md` — convenciones de código universales
- `rules/delivery/orta-checklist.md` (opcional) — pendiente confirmación operator
- `rules/stack/.gitkeep`, `rules/domain-co/.gitkeep`
- `tools/setup-rules.sh` — script symlink consumidor (≤80 líneas)
- `tools/README.md` — cómo usar tools/
- `skills/batuta-rule-authoring/SKILL.md` — gatekeeper para crear rules (≤150 líneas)

### MODIFIED

- `README.md` (raíz) — sección "Layers" + Project Structure tree update
- `docs/SPEC.md` — agregar `rules/` al component map y "Layer 6 — Engineering invariants"
- `docs/PRD.md` roadmap — registrar v1.3 = rules/ layer
- `CLAUDE.md` (plugin) — pointer a `rules/README.md` + `### batuta-rule-authoring` en Mandatory Skills

## Verification

1. `tree rules/` muestra layout esperado
2. Cada rule del seed cumple §A.4 (Anti-patrones obligatorios)
3. `setup-rules.sh` corrido en proyecto fresh crea symlinks idempotentes
4. `@.claude/rules/<rule>.md` resuelve en sesión Claude Code (Slice B2 post-merge)
5. Audit chain: code-reviewer + security-auditor APPROVED

## Riesgos

- Symlinks en Windows requieren Developer Mode/admin (documentado en how-to-import.md)
- Approval dialog de Claude Code en primer import (documentado)
- 5 hops max de recursión (las rules del seed NO se importan entre sí)

## Closing line

Cuando esta slice mergee, mover este archivo a `docs/plans/archive/2026-04-26-rules-layer.md` y escribir session journal en `docs/sessions/`.

---

## Round 1 implementation — 2026-04-26

Implementer agent (Sonnet) completed slices A2.5, A3, B1.

**Files created:**

- `skills/batuta-rule-authoring/SKILL.md` — 105 lines; gatekeeper skill with §A.4/§A.5/§A.6 validation steps, anti-rationalizations table (4 entries), and self-verification checklist.
- `rules/core/research-first-citations.md` — 70 lines; derived from `~/.claude/CLAUDE.md` Research-first section; passes §A.6 as universally applied global rule.
- `rules/core/secrets-and-pii.md` — 89 lines; 4 inviolable rules, allowed patterns in Python + TypeScript, 5 anti-patterns, 3 documented exceptions.
- `rules/core/code-style.md` — 104 lines; 4 inviolable rules, allowed patterns with WHY comment example, 5 anti-patterns, 3 documented exceptions.
- `tools/setup-rules.sh` — 80 lines; idempotent symlink script; supports --all, --rule, interactive; Windows Git Bash detection with Developer Mode guidance.
- `tools/README.md` — 30 lines; documents setup-rules.sh usage and points to how-to-import.md.
- `rules/_meta/templates/CLAUDE.md.template` — 46 lines; consumer project CLAUDE.md scaffold with import placeholders and exception template.

**Validation results:** All frontmatter parses; all rules have non-empty Anti-patterns section; no `name:`/`description:` keys in rule frontmatter; SKILL.md `description` ≤150 chars; setup-rules.sh exactly 80 lines.

**Staged (7 files):** confirmed with `git status --short`; no unexpected files in staging area.

---

## Round 2 fixes — 2026-04-26

Implementer agent (Sonnet) applied GATE 2 code-reviewer findings.

**Files modified:**

- `tools/setup-rules.sh` — Fix 1: replaced broken Windows-branch if/else with single `ln -s` attempt + conditional error message. Fix 2: added `case` pattern guard rejecting `..`, absolute, and >2-segment rule names; added POSIX realpath-confine check before symlink creation. Fix 3: replaced `find … | head -1` plugin-path detection with deterministic path + structural validation (exits 4 if `rules/` or `setup-rules.sh` absent). Fix 4: replaced `grep -v "_meta\|README"` string filter with `find -not -path '*/_meta/*' -not -name 'README.md'` path/name flags. `bash -n` syntax check: PASS.
- `rules/_meta/how-to-import.md` — Fix 5: replaced non-existent `claude --reset-trust` flag with instructions to edit `settings.local.json` / use `/permissions`. Fix 6: replaced specific future-rule names in selection table with canonical placeholder phrase.
- `rules/README.md` — Fix 6: replaced specific future-rule names in `stack/`, `domain-co/`, `delivery/` sections with canonical placeholder phrase.
- `rules/_meta/rule-template.md` — Fix 7: moved tag vocabulary to inline comment on `applies-to:` line in frontmatter; removed duplicate list from bottom Notes section.
- `rules/core/secrets-and-pii.md` — Fix 8: split rule 2 into 2a (PII never at INFO/DEBUG) and 2b (WARNING/ERROR minimum-identifier + pipeline redaction).
- `CLAUDE.md` — Fix 9: corrected typo "destilled" → "distilled".

---

## Round 3 — 2026-04-26

Implementer agent (Sonnet) added substep 4b to `skills/batuta-project-hygiene/SKILL.md`.

### (a) User-settings sync

Operator manually synced both CLAUDE.md files (global `~/.claude/CLAUDE.md` and plugin root `CLAUDE.md`) outside of this agent round. No automated changes were made to those files in Round 3.

### (b) New substep 4b — Engineering invariants bootstrap

Inserted after existing substep 4a ("Cross-tool bootstrap") in `Mode: project-init`:

- Prompts operator to bootstrap engineering invariants from batuta-agent-skills (default Y).
- On Y: runs `setup-rules.sh --all` via `find`-based plugin path resolution, appends `## Engineering invariants` section with three `@.claude/rules/` imports to `CLAUDE.md`, and appends `.claude/rules/` to `.gitignore`.
- On n: skips silently with reminder of manual invocation path.
- Verification: `test -L .claude/rules/research-first-citations.md` + `grep -q "@.claude/rules/" CLAUDE.md`.

Updated `## Verification / After project-init` block with three opt-in checks:
- symlink exists (`test -L .claude/rules/research-first-citations.md`)
- invariants import present in CLAUDE.md
- `.claude/rules/` is gitignored

### (c) Other

- Final line count: 448 lines (was 426). Within the ≤500 soft limit.
- YAML frontmatter unchanged; `name` and `description` fields intact.
