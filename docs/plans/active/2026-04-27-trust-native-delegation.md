# Plan: v2.7 — Trust Claude's native delegation, enforce only what matters

## Context

El operador encontró fricción real en BBVA Corriente: debug iterativo de DataFrames pasaba de 2 min a 30 min porque el main no podía editar `pipeline.py` directo. La causa raíz no es la delegación — es que el contrato actual del plugin **es más fuerte que la guía de Anthropic**.

**Hallazgo clave del research** (claude-code-guide agent, fuentes citadas):

1. Claude Code (Opus 4.7 / Sonnet 4.6) **tiene delegación nativa**. La doc oficial dice: *"Quick targeted fixes (1 file, <20 lines), changes to files already open in conversation context"* → el main edita directo. *"Overhead of spawning and coordinating agents is real. For quick tasks, direct execution is faster"*.
2. El subagent system es **reactivo, no prescriptivo**: *"Claude uses each subagent's description to decide when to delegate tasks"*. No hay heurísticas built-in tipo "delegar si > N archivos" — Claude lee la descripción del subagent y decide cuándo invocarlo.
3. **PreToolUse hooks son para hard constraints** (secretos, archivos protegidos), no para workflow enforcement. La doc explícitamente: *"Hook decisions do not bypass permission rules"* — los hooks son una capa de defensa en profundidad, no un sistema de routing.
4. Ningún permission mode (`default`, `acceptEdits`, `plan`, `auto`, `dontAsk`) impone "delegate-only". El platform asume que el main edita en flujos normales.

**Reformulación del operador**: *"el main agent debería poder tener un sistema de tradeoff que le permita identificar qué delegar y qué no. claude ya lo tiene de manera natural. solo debería hacer enforcement de eso."*

**Diagnóstico actual del plugin**:
- `hooks/delegation-guard.sh` blanquea Write/Edit/MultiEdit/NotebookEdit del main contra **toda** la fuente del proyecto, dejando solo carve-outs de docs/specs/CLAUDE.md.
- Esto **sobreescribe la judgment nativa** de Claude. Para un fix de 5 líneas en `pipeline.py`, fuerza un round-trip a `implementer` que cuesta 5–10 min de latencia + cache miss.
- N=2 evidence de drift: BBVA Corriente (debug pesado) + plugin repo dogfood (este propio session report).

**Estado del repo** (post-PR #10):
- Plugin v2.6.0, main = `135086f`.
- PR #11 housekeeping pendiente.
- `hooks/delegation-guard.sh` actualmente bloquea path-based + tiene kill-switches contra self-disable.

## Out of scope (explícitamente diferido)

- **Mode switches `strict | advisory | off`** — descartado en favor del simple "trust native, enforce post". Si en el futuro un proyecto compliance necesita strict, se vuelve a evaluar (v2.8 candidate).
- **Detección heurística por keywords** ("debug" vs "implement"). Demasiado mágico, hard to predict.
- **Eliminar audit chain**. El audit chain es valioso post-edit y no se toca. La v2.5 NOT-APPLICABLE en clean tree ya cubre el caso "no hay diff".
- **Reescribir agent contracts** (implementer, haiku, code-reviewer, etc.). Sus contratos siguen vigentes — son la opción de delegación de alta calidad cuando Claude decide invocarlos.
- **Permission mode forced**. El plugin no fuerza `acceptEdits` global; eso es decisión del operador en `~/.claude/settings.json`.

## Recommended scope para v2.7 (PR #12)

Cuatro cambios. Principio único: **el plugin enforcerá solo (a) hard constraints reales y (b) audit chain post-edit. El "qué delegar" lo decide Claude con su judgment nativo + descripciones de subagents.**

### Item 1 — `hooks/delegation-guard.sh` rewritten: kill-switch only (~50 LOC change, mostly subtraction)

El hook **deja de bloquear** edits del main contra paths del proyecto.

El hook **sigue bloqueando** solo paths que serían self-disabling o sensitive:

```
HARD-BLOCK list (no main writes these, regardless of mode):
  .claude/settings*.json     — prevents disabling audit triggers
  .claude/hooks/*            — prevents disabling the hook itself
  .claude/agents/*           — prevents overwriting agent contracts
  .env, .env.*               — prevents committing secrets
  secrets/*                  — prevents committing secrets
```

Todo lo demás (incluyendo `pipeline.py`, `io.py`, código fuente del proyecto) → permitido al main. Claude usa su judgment para decidir delegar via Task() vs editar directo.

**Subagent bypass mantenido**: agents (`agent_id` en stdin) bypass total. El kill-switch list aplica solo a edits del main.

**Failure mode**: si la JSON parse falla, fallback a "permitir todo excepto kill-switches" (no fallback a "bloquear todo"). El propósito del hook ya no es workflow — es kill-switch protection. JSON parse error no debería bloquear la sesión.

Stderr message cuando bloquea (solo en kill-switch hits):
```
RULE #0 violated (kill-switch): the main agent cannot modify <path> directly.
This file controls plugin enforcement; modifying it from the main would self-disable safeguards.
Delegate to a subagent (haiku for trivial edits, implementer for substantive changes), or update via the plugin's installation flow.
```

### Item 2 — `docs/DELEGATION-RULE.md` reframed (~50 LOC, mostly rewrite)

Reescritura del § principal:

> **Goal**: The main agent uses Claude's native delegation judgment to decide when to delegate vs edit directly. The plugin reinforces this by:
> 1. Providing high-quality subagents (implementer, implementer-haiku, code-reviewer, test-engineer, security-auditor) so when Claude DECIDES to delegate, the destination is well-defined.
> 2. Running the audit chain post-edit on any staged diff (regardless of whether main or subagent produced it).
> 3. Hard-blocking only kill-switch paths and secrets.
>
> **What Claude's native judgment looks like** (from Anthropic's docs):
> - Direct edit when: ≤ ~20 lines, single file, file already in context, debugging existing behavior, exploratory iteration.
> - Delegate (Task) when: spans multiple files, deep research/exploration (Explore subagent), parallel work, task matches a specialist's domain (compliance, security, data engineering).
> - Default to delegate when context cost is high (large file reads, multi-step analysis) — round-trip is cheaper than polluting the main's window.
>
> The plugin does NOT block direct edits. The plugin runs the audit chain on commit / pre-merge to verify the resulting diff.

Reemplaza la formulación actual ("main NEVER edits"). Mantiene el catálogo de subagents como destinos de calidad cuando Claude decide delegar.

Agrega tabla "When Claude typically delegates vs edits" (informativa, no normativa):

| Situación | Comportamiento esperado |
|---|---|
| Implementing a new module | Delegate (implementer) |
| Adding tests for new code | Delegate (test-engineer) |
| Bug fix found via test, < 10 LOC | Edit directly (faster than round-trip) |
| Bug spans 3 files, root-cause unclear | Delegate (implementer + Explore for analysis) |
| Renaming a function across the repo | Delegate (haiku for mechanical) |
| Adjusting a single string for retest | Edit directly |
| Editing CLAUDE.md / docs / specs / ADRs | Edit directly (always) |
| Modifying `.env`, `.claude/settings.json`, `.claude/hooks/*` | Hard-blocked (kill-switch) |

### Item 3 — Audit chain trigger pattern documented (~20 LOC change in DELEGATION-RULE.md + agents)

El audit chain corre post-edit, no pre-edit. El trigger explícito es:

1. El main (o un subagent) produjo cambios staged (`git diff --staged --stat` no vacío).
2. La sesión está cerrando un slice (commit imminent, o el operador pide review).
3. El main invoca `Task(test-engineer)` → `Task(code-reviewer)` → `Task(security-auditor)` en secuencia.

Si no hay diff, los auditores ya retornan `NOT APPLICABLE` (v2.5 contract). No hay regresión.

Cambio en `agents/code-reviewer.md`, `test-engineer.md`, `security-auditor.md`: una línea agregada al pre-flight Step 0 que aclara *"This audit applies whether the diff was produced by the main agent or by another subagent — the audit reads `git diff` regardless of authorship."*

### Item 4 — `user-settings/CLAUDE.md` + `~/.claude/CLAUDE.md` realignment (~30 LOC, mostly rewrite of Rule #0 §)

El § "Delegation-only main agent (Rule #0)" se renombra a **"Native delegation + post-edit audit"** y se reescribe:

> The main agent uses Claude's native judgment for the delegate-vs-edit decision. The plugin provides high-quality subagents as the destination when delegation is chosen, and enforces an audit chain post-edit on any staged diff.
>
> **Subagent destinations** (when Claude delegates):
> - `implementer` (Sonnet) — multi-file slices, control flow, async, integrations
> - `implementer-haiku` (Haiku) — trivial edits ≤ 3 files no new conditional/async
> - `code-reviewer`, `test-engineer`, `security-auditor` (Sonnet) — sequential audit chain
> - `agent-architect` (Sonnet) — meta-agent that creates project-local specialists
>
> **Post-edit audit chain** (always runs when there's a staged diff):
> ```
> implementer | implementer-haiku | <specialist> | <main edits> → test-engineer → code-reviewer → security-auditor
> ```
>
> The chain is sequential and each gate reads `git diff`. NOT-APPLICABLE returns immediately on a clean tree.
>
> **Hard kill-switches** (plugin-enforced, not negotiable):
> - `.claude/settings*.json`, `.claude/hooks/*`, `.claude/agents/*`
> - `.env`, `.env.*`, `secrets/*`
>
> Everything else: Claude's native judgment.

## Files to modify or create

### MODIFIED

| File | Change | Lines |
|---|---|---|
| `hooks/delegation-guard.sh` | Remove path-whitelist; keep only kill-switch list; flip failure mode to "allow on parse error"; rewrite stderr message | ~50 |
| `docs/DELEGATION-RULE.md` | Full reframe: "trust native, enforce post". New decision table. Audit-chain trigger documented. | ~50 |
| `agents/code-reviewer.md`, `test-engineer.md`, `security-auditor.md` | One-line clarification in Step 0 ("regardless of diff authorship") | ~3 each (9 total) |
| `user-settings/CLAUDE.md` + `~/.claude/CLAUDE.md` | Rule #0 § renombrado y reescrito | ~30 |
| `.claude-plugin/plugin.json` | 2.6.0 → 2.7.0; description: "audit chain + kill-switch enforcement; trusts Claude's native delegation" | ~2 |
| `docs/PRD.md` | v2.7 entry: realignment with Anthropic's design pattern | ~5 |
| `docs/SPEC.md` | Layer 2 (delegation enforcement) reescrita: workflow-enforcement removed, kill-switch + audit-chain documented | ~15 |
| `tests/v2.5-validators/01-auditor-not-applicable.sh` | Update assertion: ya cubre el caso correcto, solo verificar que sigue vigente | 0 (re-verify only) |

### NEW

| File | Lines | Purpose |
|---|---|---|
| `docs/adr/0006-trust-native-delegation.md` | ~80 | Records why the plugin moved from absolute Rule #0 to kill-switch + audit-chain. Cites Anthropic docs. Records N=2 evidence. |
| `docs/plans/active/2026-04-27-trust-native-delegation.md` | ~150 | Slice plan (este file, copiado vía /save-plan) |
| `tests/v2.5-validators/06-delegation-guard-killswitch.sh` | ~60 | Static check: hooks/delegation-guard.sh references the kill-switch paths and rejects `.claude/settings.json` writes from main while allowing project source paths. |

Total: ~200 LOC net change. Más subtraction que addition (el hook se simplifica).

### POST-MERGE

Ningún cambio manual en BBVA Corriente — al simplificar el hook universalmente, el debug iterativo se desbloquea apenas v2.7 está en marketplaces. No hay setting per-project que el operador deba flippear.

## Reuse of existing utilities

- **`hooks/delegation-guard.sh` actual** — la mayoría se elimina (path-whitelist), se preserva solo kill-switch + subagent bypass (`agent_id` detection).
- **`tests/v2.5-validators/run.sh`** — patrón existente para case 06.
- **`docs/adr/0005-plan-mode-persistence-mechanism.md`** — shape para ADR-0006.
- **agent-architect Phase 5 (post-PR-10)** — sigue válido; los specialists generados heredan el nuevo contrato a través de `batuta-agent-authoring` rules 5–6 sin cambio.

## Verification

1. **Hook static check** — `bash tests/v2.5-validators/run.sh` debe pasar 6/6 (case 06 nuevo).
2. **Hook functional check — kill-switch hit**: intentar `Edit` desde el main contra `.claude/settings.json` → bloqueado, exit 1, stderr explica kill-switch.
3. **Hook functional check — project source allowed**: intentar `Edit` desde el main contra `pipeline.py` (en un repo de prueba) → permitido, sin warning.
4. **Hook functional check — failure mode**: simular JSON parse error en el hook → fallback a "permitir todo excepto kill-switches", no a "bloquear todo".
5. **Audit chain still triggers post-edit**: en un repo con un staged diff, invocar `code-reviewer` → corre el five-axis review (no NOT-APPLICABLE). El audit chain aplica al diff sin importar autoría.
6. **Native delegation observed**: en sesión de prueba, dar al main una tarea de un solo archivo ≤ 20 líneas → main edita directo (no delega). Dar tarea de 4 archivos con tests → main delega a implementer. Confirma judgment nativo intacto.
7. **Plugin version reports correctly** — `.claude-plugin/plugin.json` muestra 2.7.0; `docs/PRD.md` lista v2.7 entry shipped.
8. **Audit chain on this slice** — el slice toca `hooks/`, `agents/`, `docs/`, `.claude-plugin/`, `tests/`, `user-settings/` → no en GATE 3 skip allowlist → test-engineer + code-reviewer + security-auditor APPROVED. Security-auditor especialmente: el cambio amplía superficie de edición del main; verificar que kill-switches efectivamente cubren los riesgos críticos.

## Order of execution

```
PR #11 (housekeeping post-PR-10) merge          ← prerequisito
                ↓
Branch feat/trust-native-delegation off main
                ↓
Read hooks/delegation-guard.sh end-to-end
Read docs/DELEGATION-RULE.md end-to-end
                ↓
[Item 1] Rewrite hooks/delegation-guard.sh — solo kill-switches
[Item 1] Manual test de los tres casos (kill-switch hit, project path, parse error)
[Item 2] Rewrite docs/DELEGATION-RULE.md
[Item 3] Update Step 0 en code-reviewer/test-engineer/security-auditor
[Item 4] Rewrite Rule #0 § en user-settings/CLAUDE.md + sync ~/.claude/CLAUDE.md
                ↓
Bump plugin.json a 2.7.0 + PRD entry
                ↓
Write ADR-0006 explicando la realineación con Anthropic
                ↓
Write tests/v2.5-validators/06-delegation-guard-killswitch.sh
                ↓
Run tests/v2.5-validators/run.sh — 6/6 PASS antes de abrir PR
                ↓
Audit chain (test-engineer + code-reviewer + security-auditor)
                ↓
Commit + push + open PR #12
                ↓
Operator merges
                ↓
Verify febrero unblock: en BBVA Corriente, debug iterativo
de pipeline.py pasa de 30 min/iter a < 5 min/iter sin
configuración manual.
```

## Risks identified

1. **El main puede sobre-editar y saltarse el audit chain accidentalmente**. Mitigación: la audit chain sigue corriendo pre-merge (operator ejecuta gates). Si el main pushea sin gates, el operator lo ve en el PR y reabre. La regla "audit chain pre-merge" sigue documentada.
2. **Kill-switches incompletos** — algún path crítico no listado deja una superficie de auto-disable. Mitigación: ADR-0006 lista los kill-switches; security-auditor revisa exhaustivamente. Lista explícita es más fácil de auditar que un whitelist.
3. **Sesiones existentes con la formulación vieja en memoria continúan asumiendo "main never edits"**. Mitigación: el cambio del hook libera al main; las sesiones viejas que intenten edits directo simplemente funcionarán (no fallback worse). MEMORY.md del operador puede tener bullets viejos que documenten "Rule #0 absoluto" — sweep manual al sincronizar el plugin.
4. **El cambio podría leerse como "el plugin se rinde"**. Mitigación: el ADR enfatiza que el plugin sigue enforciendo lo que importa (audit chain post-edit, kill-switches, research-first via subagents) — solo se alinea con la guía de Anthropic en lugar de imponer un contrato más estricto. La diferencia es kill-switches + audits, no path-whitelist + pre-block.
5. **Compliance projects (Colombian e-invoicing, GDPR) podrían querer strict back**. Mitigación: deferred a v2.8 si aparece la necesidad real. La v2.7 cubre el 90% del uso; el 10% compliance puede agregarse con un mode-switch posterior si N=2 evidence aparece.

## Open questions answered during planning

- **Q: Por qué eliminar el block en lugar de hacerlo opt-in (mode switch)?** — Porque la guía de Anthropic explícitamente dice que pre-edit blocks son para hard constraints, no workflow. Hacer mode switch sería seguir desalineado con el platform pattern. Más simple alinear y, si compliance lo necesita, agregar después con N=2 evidence.
- **Q: El audit chain todavía corre si el main editó sin delegar?** — Sí. El audit chain lee `git diff`, no le importa quién editó. La v2.5 NOT-APPLICABLE Step 0 ya cubre el caso clean tree. La nueva línea aclaratoria en Step 0 explicita esto.
- **Q: Y si Claude tiene un "mal día" y edita un módulo entero directo en vez de delegar?** — Posible. Mitigación: audit chain post-edit lo cataloga como un slice grande sin tests/research-first. El operador lo ve y reopen. La frecuencia esperada es baja (Claude tiende a delegar para slices grandes — la doc cita esto). Si N=2 evidence de over-editing aparece, v2.8 puede agregar un soft-warning hook (advisory, no block).
- **Q: Por qué eliminar la formulación "Rule #0" en lugar de mantenerla con nuevo significado?** — El número y la palabra "Rule #0" cargan connotación de inviolable. Reformular el § sin renombrarlo crearía ambigüedad. Mejor renombrar a "Native delegation + post-edit audit" — describe lo que el plugin hace, no lo que prohíbe.
