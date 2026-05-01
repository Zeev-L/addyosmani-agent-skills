# Plan — KB Batuta: vault Obsidian central + persistencia automática por commit + research-first con lookup local

## Contexto

El operador convocó una sesión de pensamiento crítico sobre tres ejes entrelazados: estructura de Notion, persistencia real del hook, migración a Obsidian. Tras Fase 1 (descubrimiento) y resolver cuatro decisiones operador, el cuadro real es:

- **El plugin `batuta-agent-skills` está instalado a nivel user** en `C:/Users/JNMZ/.claude/plugins/marketplaces/batuta-agent-skills/`. Todos los repos del operador lo heredan. La "no adopción" en 5 proyectos (bato-cajas, BATO, BATO2, batuta-portal, Batuta APP) es proyecto-level: faltan rules como symlinks, `docs/PRD.md`, `docs/SPEC.md`, `docs/plans/active/`, `docs/sessions/`, CLAUDE.md scoped per-feature.
- **La persistencia a Notion es 100% manual por diseño** (`skills/notion-kb-workflow/SKILL.md:18,104` + ADR-0005). El "must" del CLAUDE.md global es disciplina, no enforcement.
- **`research-first-dev` no consulta historia local**. Workflow lineal manifest → Context7 → Web. 0 menciones de Obsidian/vault/sessions previas en todo el plugin.
- **Pain point real**: conectar puntos cross-project (Prophet/SAP vs Prophet/ICG). No es problema de persistencia — es problema de **descubrimiento cross-project**. Notion permite relations explícitas pero sin backlinks emergentes; Obsidian al revés.

Decisiones del operador resueltas:
1. **Notion no se usa con clientes** → migración no rompe workflow cliente-facing.
2. **Roadmap: certificarse** (probable ISO 27001 / SOC 2) → favorece local-first / data residency / archivos versionables.
3. **Persistencia automática deseada en cada commit aceptado** — el commit es señal limpia (decisión intencional del operador), Stop hook es ruidoso (toda interrupción).
4. **NDA mixto pero quiere best practices**.

Outcome de esta sesión: aprobar este plan; ejecución arranca con Sprint 1.

## Definición de paths

- **`<vault_root>`** = `E:\Gdrive Batuta\My Drive\BATUTA AI\OBSIDIAN\BATUTA` (Google Drive Desktop + Obsidian; **ya existe**).
- **Remote git del vault**: `jota-batuta/batuta-kb` (private). Se hace `git init` dentro del vault preexistente y se conecta.
- **Riesgo Drive+git**: `.git/objects/` adentro de Drive sync genera I/O constante y conflictos potenciales. Mitigaciones tratadas en sección "Bootstrap del vault".

## Decisiones tomadas

1. **El vault ya existe en `<vault_root>`** (Drive + Obsidian configurado). Bootstrap consiste en `git init` + `gh repo create jota-batuta/batuta-kb --private` + primer commit + push. Es la KB primaria del operador. Notion deja de ser source-of-truth — queda disponible vía MCP para casos cliente-facing minoritarios.
2. **Persistencia automática vía git post-commit hook**, NO Claude Code Stop hook. El git hook captura todo commit (incluyendo los hechos sin Claude — operador en VS Code, GitHub Desktop, gh CLI). Stop hook descartado: dispara en cualquier turno, falsos positivos altos.
3. **`research-first-dev` gana Step 1.5: Local KB lookup** entre Step 1 (manifest) y Step 2 (Context7). Política de staleness por edad de `last_verified`. **Step 1.5 prioriza L2 (curado) sobre L1 (journals)**; hits L1 llegan con disclaimer "no curado, verificá".
4. **Vault de tres niveles, curación explícita L1→L2** (ver §"Curación" abajo). El git hook escribe SOLO a L1. La promoción a L2 es acción humana asistida por agente. Sin esto, ADRs y gotchas se acumulan flat sin síntesis — ese era el agujero del diseño v1.
5. **ADR nuevo 0011** — "Automatic persistence on commit + L1/L2/L3 vault curation pipeline" (asume que `0007-code-graph-dual-engine.md` ya está ocupado). Supersede parcial de ADR-0005. ADR-0005 sigue vigente para `/save-plan`; ADR-0011 cubre persistencia + curación.
6. **`notion-kb-workflow` no se elimina** — se reescribe Overview como "modo opcional cliente-facing". `--read`/`--init`/`--append` quedan disponibles pero marcadas optional.
7. **Adopción proyecto-level en los 5 pendientes** vía `batuta-project-hygiene mode=project-retrofit`. NO instalar el plugin (ya está user-level); solo retrofit del session-handoff y del nuevo git hook.

## Curación: niveles del vault y pipeline L1→L2

**El problema que resuelve**: ADR-001 (JWT) y ADR-002 (OAuth supersede 001) no pueden coexistir como dos archivos con igual peso. Sin curación, cada commit deja huella pero nadie sintetiza. Step 1.5 devolvería ruido.

### Niveles

| Nivel | Carpetas | Quién escribe | Volatilidad |
|---|---|---|---|
| **L0** | `_inbox/` | Operador manual (export Notion, captura libre) | Alta — drenar incremental |
| **L1** | `journals/`, `clients/<c>/projects/<p>/sessions/`, mirrors de `docs/sessions/` | git post-commit hook | Append-only |
| **L2** | `decisions/`, `gotchas/`, `playbooks/`, `clients/<c>/projects/<p>/{decisions,gotchas}/` | skill `kb-curate` (asistida) | Una sola fuente de verdad por tema |
| **L3** | `glossary/{products,domains,people}/` | Operador + auto-promotion del curator | Estable — referenciado por L2 |

Step 1.5 de research-first-dev prioriza **L2 fuerte**, después L3. Solo cae a L1 si no hay hits y devuelve con disclaimer.

### Pipeline `kb-curate`

Una sola skill `kb-curate` con cuatro modos de invocación, todos convergen a la misma lógica:

| Disparador | Cómo se invoca | Scope |
|---|---|---|
| **on-PR-merge** | GitHub Action en el repo del proyecto (post-merge) que dispara `/kb-curate --feature <branch>` | Todos los journals del branch mergeado |
| **slash manual** | `/kb-curate [--scope <feature\|session\|all-pending\|since-YYYY-MM-DD>]` | Definido por operador |
| **cron semanal** | Routine `/schedule cron=0 9 * * 1` que invoca `/kb-curate --scope week` | Journals últimos 7 días |
| **on-session-end** | `/kb-end-session` (nueva, complementa `/save-plan`) cierra journal y dispara `/kb-curate --scope session` | Bullets nuevos del journal del día |

Lógica común:
1. Listar bullets de journal sin frontmatter `curated_into:` en el scope.
2. Pasar al **agente nuevo `kb-curator`** (Sonnet, especialista) — clasifica cada bullet en categoría: decision-new, decision-supersede, gotcha-new, gotcha-update, playbook-candidate, glossary-entry, noise.
3. Aplicar matriz de control por categoría.
4. Marcar bullets curados con `curated_into: [<paths>]` y `curated_at: <ISO>` en el journal.
5. Producir un commit en el vault (no en el repo proyecto) con resumen de la curación.

### Matriz de control por categoría (operador eligió híbrido)

| Categoría | Acción |
|---|---|
| `decision-new` | Escribe a `<vault>/.../decisions/<topic>.md.draft` → review manual del operador → operador renombra a `.md` |
| `decision-supersede` | Igual — `.draft` review obligatorio. Updates a `Superseded by` del archivo viejo se aplican solo tras aprobación |
| `gotcha-new` | Auto-apply a `<vault>/.../gotchas/<topic>.md`. Commit pending review (`status/needs-review` tag) |
| `gotcha-update` | Review manual — modificar gotcha existente cambia semántica |
| `playbook-candidate` | `.draft` review — los playbooks son sintéticos, alta sensibilidad |
| `glossary-entry` | Auto-apply a `<vault>/glossary/...`. Bajo riesgo, alto valor para backlinks Obsidian |
| `noise` | Skipear pero igual marcar `curated_into: []` para no re-procesar |

### Marcado de curación (recomendación firme: frontmatter por bullet)

El operador no tenía preferencia. Recomiendo **frontmatter por bullet, no por archivo, no archivar**. Ejemplo en un journal del día:

```markdown
- **14:32 · abc1234** · feat: oauth migration
  - branch: feature/oauth-v2
  - files: 12 (`src/auth/*`, `docs/SPEC.md`)
  - plan: docs/plans/active/2026-04-29-oauth.md
  - curated_into: ["decisions/auth-oauth.md", "gotchas/jwt-token-rotation.md"]
  - curated_at: 2026-04-29T18:00:00Z
```

Razones:
- **Granular**: una entry de journal puede contribuir a 1+ archivos L2; un journal puede tener entries no-curadas y sí-curadas mezcladas. Mover el journal entero (opción "archived/") perdería esa granularidad.
- **Auditable**: 6 meses después puedo abrir el journal y ver "este commit se sintetizó en estos archivos".
- **Idempotente**: el curator skipea bullets con `curated_into:` ya presente. Si se desea re-curar (ej. el gotcha cambió), operador borra el frontmatter manualmente — acción explícita.
- **No recurre**: la opción "agente decide cada vez" cuesta tokens y no es auditable.

### Riesgo de drift L1↔L2

Si el operador edita L2 manualmente, los próximos commits siguen escribiendo a L1 sin reflejar el cambio. Política firme: **L2 es source-of-truth siempre**. El curator lee el state actual de L2 antes de proponer cambios; si L2 ya cubre el bullet, marca `curated_into` apuntando al archivo existente sin proponer update.

## Arquitectura del vault `<vault_root>/`

```
<vault_root>/
├── README.md
├── .obsidian/                       # config commiteada, sin workspace.json
├── .gitignore                       # workspace.json, .DS_Store, *.tmp, **/secrets/
├── _inbox/                          # capturas sin clasificar (drenado periódico)
├── clients/<client-slug>/
│   ├── README.md                    # contexto cliente (NDA scope, stack)
│   ├── projects/<project-slug>/
│   │   ├── decisions/               # ADRs migrados / decisiones cruzadas
│   │   ├── gotchas/                 # workarounds, bugs proveedor
│   │   └── sessions/                # mirror de docs/sessions/<file>.md
│   └── glossary.md
├── decisions/                       # cross-cliente
├── gotchas/                         # cross-cliente
├── glossary/{products,domains,people}/
├── playbooks/
├── journals/2026/04/2026-04-29.md   # journal personal del operador
├── adr-index.md                     # backlinks
└── templates/{session-journal,decision,gotcha}.md
```

**Relación archivo-proyecto ↔ vault**: copia con metadata enriquecida, no symlink. El proyecto sigue siendo source-of-truth de su `docs/sessions/`. El git post-commit hook hace mirror al vault. Si hay drift, el repo gana.

**Tagueo**: wikilinks Obsidian (`[[Prophet]]`, `[[ERP/SAP]]`, `[[ERP/ICG]]`) + hashtags taxonómicos (`#decision`, `#gotcha`, `#playbook`, `#client/<slug>`, `#sev/{blocker,workaround,cosmetic}`, `#status/verified-2026-04`). Habilita `grep -r "Prophet" <vault_root>` para encontrar todo cross-project.

**Frontmatter YAML mínimo** (sessions, decisions, gotchas):
- `type`, `date`, `client`, `project`, `tags`, `last_verified`
- `commits: [<sha>]` y `files_changed: <n>` para sessions
- `severity`, `product` para gotchas
- `id`, `status`, `supersedes` para decisions

`last_verified` es campo crítico — lo lee Step 1.5 de research-first-dev para política de staleness. Dataview de Obsidian audita stale entries con `LIST FROM #gotcha WHERE last_verified < date(today) - dur(4 months)`.

## Persistencia automática: git post-commit hook

**Script**: `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\post-commit-kb.sh`. Lógica:

1. Salir `exit 0` silencioso si `.claude/kb-config.json` no existe o `enabled:false` (repos no-Batuta no afectados).
2. Capturar metadata: `git log -1 --format='%H|%s|%an|%ai'` + `git diff-tree --no-commit-id --name-only -r HEAD`.
3. Detectar rebase: si existe `.git/rebase-merge/` o `.git/rebase-apply/`, salir; reconciliar al final con `tools/kb-resync.sh`.
4. Determinar journal del día: `docs/sessions/<YYYY-MM-DD>-<slug>.md`. Slug viene de (a) branch `feature/<x>`, (b) primer plan en `docs/plans/active/`, (c) fallback `daily`. Crear con frontmatter si no existe.
5. Append entrada (timestamp, abbrev SHA, subject, branch, files, plan-link).
6. Si `vault_root` está configurado, mirror al vault: `<vault_root>/clients/<c>/projects/<p>/sessions/<YYYY-MM-DD>.md`.
7. Idempotencia: parsear journal, buscar SHA antes de append. Para amend, reemplazar línea (mismo SHA padre, subject distinto).
8. Nunca fallar el commit: `set +e` + `trap 'exit 0' ERR`. Errores van a `.claude/kb-debug.log`.

**Configuración por proyecto**: `.claude/kb-config.json` (commiteado al repo):
```json
{
  "enabled": true,
  "client": "bato-cajas",
  "project": "bato-cajas",
  "vault_root": "<vault_root>",
  "session_slug_strategy": "branch-or-plan-or-daily"
}
```

**Instalación**: `batuta-project-hygiene` agrega paso 4c en `mode=project-init` y `mode=project-retrofit` que copia el script a `.git/hooks/post-commit` (o referencia vía `core.hooksPath` global — TODO Sprint 1) y crea `kb-config.json` con prompts.

## Step 1.5 en `research-first-dev`

Inserción entre Step 1 (manifest) y Step 2 (Context7), titulada `### Step 1.5: Local KB lookup`.

1. Construir query: `<lib>` + tema (`<api>` o `<lib> integration`).
2. Grep en orden: `<project-root>/docs/`, `<vault_root>/clients/<this-client>/`, `<vault_root>/{decisions,gotchas}/`.
3. Política de staleness por `last_verified`:
   | Edad | Acción |
   |---|---|
   | < 4 meses | Hit local gana. Cita local. Skip Context7. |
   | 4–12 meses | Hit local es señal. Correr Context7. Cita doble. |
   | > 12 meses | Hit local solo informa contexto. Cita Context7. Update `last_verified`. |
4. Decisiones estructurales (instalar lib nueva, bump major) **siempre** corren Context7 incluso con hit fresco.
5. Cita local: `// Source: <vault_root>/clients/<c>/gotchas/<file>.md (verified 2026-03-15)`. Con cross-check: agrega segunda línea `// Cross-checked: https://...`.

## Files to create or modify

| Path | Cambio |
|---|---|
| `e:\BATUTA PROJECTS\batuta-agent-skills\rules\authoring\skill-authoring-required.md` | **Nuevo (Sprint 0, MUST-A)** — rule canónica skill gate |
| `e:\BATUTA PROJECTS\batuta-agent-skills\rules\authoring\agent-authoring-required.md` | **Nuevo (Sprint 0, MUST-B)** — rule canónica agent gate |
| `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\pre-write-skill-gate.sh` | **Nuevo (Sprint 0, MUST-A)** — hook condicional, marker `.authoring-marker-skill-<ISO>` |
| `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\pre-write-agent-gate.sh` | **Nuevo (Sprint 0, MUST-B)** — hook condicional, marker `.authoring-marker-agent-<ISO>` |
| `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\hooks.json` | Registrar ambos `PreToolUse` (skill + agent) con matchers de path |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\batuta-skill-authoring\SKILL.md` | Paso final: dejar marker skill |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\batuta-agent-authoring\SKILL.md` | Paso final: dejar marker agent |
| `e:\BATUTA PROJECTS\batuta-agent-skills\agents\agent-architect.md` | Paso al iniciar: dejar marker agent (excepción documentada) |
| `e:\BATUTA PROJECTS\batuta-agent-skills\tests\authoring-gate\skill\` | **Nuevo (Sprint 0, MUST-A)** — 5 test cases |
| `e:\BATUTA PROJECTS\batuta-agent-skills\tests\authoring-gate\agent\` | **Nuevo (Sprint 0, MUST-B)** — 6 test cases |
| `e:\BATUTA PROJECTS\batuta-agent-skills\tests\authoring-gate\run.sh` | **Nuevo (Sprint 0)** — runner que invoca ambos sets |
| `~/.claude/CLAUDE.md` | **(Sprint 0)** — secciones "Skill authoring gate" y "Agent authoring gate", separadas |
| `~/.claude/settings.json` | **(Sprint 0)** — registrar ambos `PreToolUse` user-global con matchers condicionales |
| `e:\BATUTA PROJECTS\batuta-agent-skills\CLAUDE.md` | **(Sprint 0)** — re-anclar MUST-A y MUST-B apuntando a hooks + rules respectivos |
| `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\post-commit-kb.sh` | **Nuevo** — script git post-commit (escribe SOLO a L1) |
| `e:\BATUTA PROJECTS\batuta-agent-skills\tools\kb-resync.sh` | **Nuevo** — reconcilia journal post-rebase |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\<batuta-kb-vault\|reused>\SKILL.md` | **Candidato** (Sprint 0 decide nombre/existencia) — convenciones vault, niveles L0-L3, tagueo, drenaje inbox |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\<kb-curate\|reused>\SKILL.md` | **Candidato** (Sprint 0 decide) — pipeline L1→L2 con 4 disparadores |
| `e:\BATUTA PROJECTS\batuta-agent-skills\agents\<kb-curator\|reused>.md` | **Candidato** (Sprint 0 decide vs reuso de agent existente) — clasifica bullets y propone updates L2 |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\<kb-backfill\|reused>\SKILL.md` | **Candidato Sprint 2.5** — pipeline 4 fases (readme/commits/issues/code) sobre repo legacy |
| `e:\BATUTA PROJECTS\batuta-agent-skills\agents\<kb-backfiller\|reused>.md` | **Candidato Sprint 2.5** — Sonnet por default, Haiku fast-path. Lee repo viejo, produce entries L0/L1 retroactivas |
| `e:\BATUTA PROJECTS\batuta-agent-skills\.claude\commands\kb-backfill.md` | **Nuevo Sprint 2.5** — slash `/kb-backfill --repo <path> [--scope readme,commits,issues,code]` |
| `e:\BATUTA PROJECTS\batuta-agent-skills\.claude\commands\kb-curate.md` | **Nuevo** — slash `/kb-curate [--scope ...]` |
| `e:\BATUTA PROJECTS\batuta-agent-skills\.claude\commands\kb-end-session.md` | **Nuevo** — `/kb-end-session` cierra journal + dispara curate scope=session |
| `e:\BATUTA PROJECTS\batuta-agent-skills\.claude\commands\batuta-status.md` | **Nuevo** — `/batuta-status [--scope]` resumen rápido en chat |
| `<vault_root>/STATUS.md` | **Auto-generado** por cron lunes — vista profunda semanal |
| `<vault_root>/_dashboard.md` | **Nuevo manual** — queries Dataview interactivas |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\research-first-dev\SKILL.md` | Insertar Step 1.5 priorizando L2 > L3 > L1 con disclaimer + Anti-Rationalizations + Verification |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\batuta-project-hygiene\SKILL.md` | Paso 4c "KB hook installation" en init y retrofit |
| `e:\BATUTA PROJECTS\batuta-agent-skills\skills\notion-kb-workflow\SKILL.md` | Reescribir Overview: "Notion modo opcional cliente-facing post ADR-0011" |
| `e:\BATUTA PROJECTS\batuta-agent-skills\docs\adr\0011-automatic-persistence-and-curation.md` | **Nuevo** — supersede parcial de 0005 + pipeline curación L1/L2/L3 |
| `e:\BATUTA PROJECTS\batuta-agent-skills\docs\adr\0005-...md` | Status: `Superseded in part by 0011` |
| `<vault_root>/` | **Nuevo repo** privado en `jota-batuta/batuta-kb` |
| `~/.claude/CLAUDE.md` | Update sección Notion-KB: KB primario = vault, Notion = optional. Agregar referencia al pipeline de curación |
| `<cada-proyecto>/.github/workflows/kb-curate-on-merge.yml` | **Nuevo** (template) — GitHub Action que dispara `/kb-curate --feature <branch>` al merge de PR |

## Visibilidad — dónde ver el progreso

Tres superficies complementarias, no alternativas. Cada una resuelve una pregunta distinta del operador:

### 1. `/batuta-status [--scope project|all|client:<slug>]` — vista rápida en chat
Slash command del plugin que produce un resumen en N líneas dentro de la conversación Claude. Bueno para "antes de empezar la sesión, dame el panorama".

Output ejemplo (`--scope all`):
```
3 proyectos activos esta semana
─ bato-cajas (D:\bato-cajas) · feature/conciliacion-v2 · 5 commits 7d · journal hoy ✓ · 2 drafts pending
─ BATO2 (D:\BATO2) · main · 1 commit 7d · journal hoy ✗
─ batuta-portal · feature/v3 · 12 commits 7d · journal hoy ✓ · 1 draft pending

Drafts pendientes review: 3 (decisions/auth-oauth.md.draft, decisions/sap-tax.md.draft, gotchas/icg-pos-sync.md.draft)
Gotchas stale (>4 meses): 4
_inbox sin clasificar: 12 archivos
```

Implementación: lee `<vault_root>/`, recorre `clients/*/projects/*`, agrega métricas calculadas con `git log --since=7days` y grep de frontmatter.

### 2. `<vault_root>/STATUS.md` — vista profunda auto-generada
Archivo en el vault, regenerado completamente por la routine cron lunes 9am (la misma del Sprint 2). Contiene:
- Por cliente → por proyecto: actividad última semana + mes, drafts pendientes, gotchas stale, plan activo.
- Cross-project: top 5 productos con actividad ([[Prophet]], [[ICG]]…), decisions modificadas, sesiones que tocaron > 1 proyecto (señal de aprendizaje cross-pollinable).
- Health del vault: % bullets curados, edad media de `last_verified`, tamaño `_inbox/`.

Es archivo Obsidian — wikilinks vivos, navegable. El operador lo abre en Obsidian cuando quiere "el estado de la operación, no de un proyecto".

### 3. `<vault_root>/_dashboard.md` — vista interactiva Dataview
Archivo del vault con queries Dataview que **se ejecutan al abrir el archivo en Obsidian**. Bueno para exploración: filtrar drafts por cliente, listar gotchas por producto, ver journals de la última semana.

Queries iniciales:
```dataview
LIST FROM #status/needs-review
LIST FROM #gotcha WHERE last_verified < date(today) - dur(4 months)
TABLE date, client, project FROM #session WHERE date >= date(today) - dur(7 days)
TABLE supersedes, status FROM "decisions" WHERE status = "accepted"
```

No requiere cron — es vivo. Requiere plugin Dataview de Obsidian (recomendado en Sprint 1).

### Cómo conviven

| Pregunta operador | Superficie |
|---|---|
| "¿Cómo está todo ahora?" (chat, antes de empezar) | `/batuta-status` |
| "¿Qué pasó la semana pasada?" (review semanal) | `STATUS.md` (cron) |
| "Filtrar/explorar por X" (research mode) | `_dashboard.md` (Dataview) |

## Sprint 0 — Enforcement de los authoring gates + discovery (obligatorio, bloqueante)

### Problema raíz que corrige

CLAUDE.md del proyecto declara dos MUST distintos:

- **MUST-A**: `batuta-skill-authoring` antes de crear cualquier SKILL.md.
- **MUST-B**: `batuta-agent-authoring` antes de crear cualquier agente en `agents/`.

Ambos son solo texto. **Yo mismo, con todas las skills disponibles, violé MUST-A al diseñar el plan v2** — listé skills nuevas sin discovery. Y el plan v2 también listó un agente nuevo (`kb-curator`) sin haber pasado por `batuta-agent-authoring`, violando MUST-B. El sistema permitió ambas violaciones. Si me pasó a mí, va a pasar otra vez. Necesita enforcement real para los DOS gates, simétrico, no anidado.

Sprint 0 implementa ambos enforcements en paralelo. Cada uno con su rule, su hook (o branch del hook), su marker, y sus tests propios.

### MUST-A: Enforcement skill-authoring

**Capa 1 (texto declarativo, soft)**:
- Nueva rule canónica: `e:\BATUTA PROJECTS\batuta-agent-skills\rules\authoring\skill-authoring-required.md`. Estructura del rule layer (Anti-patterns, ≤200 líneas, importable vía `@.claude/rules/authoring/skill-authoring-required.md`).
- Update `~/.claude/CLAUDE.md` (user-global): sección "Skill authoring gate" que cita la rule.
- Update `e:\BATUTA PROJECTS\batuta-agent-skills\CLAUDE.md` (proyecto): re-anclar MUST-A apuntando al hook + rule.

**Capa 2 (hook PreToolUse, hard)**:
- Hook nuevo: `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\pre-write-skill-gate.sh`.
- Matcher: `Write`/`Edit` sobre `**/skills/**/SKILL.md`.
- **Condicional al repo**: lee `git remote get-url origin`; solo enforce si matchea regex `(jota-batuta|batuta)/.*agent-skills`.
- **Marker**: `batuta-skill-authoring` SKILL.md gana paso final que escribe `.claude/.authoring-marker-skill-<ISO>` al completar el workflow.
- **Lógica**: marker más reciente edad < 60 min → permite; sino → bloquea con `"Invocá batuta-skill-authoring primero. Marker faltante o expirado."`.
- **Bypass**: env var `BATUTA_SKILL_AUTHORING_BYPASS=1` para casos legítimos (rebase, edit cosmético). Documentado en la rule.
- Registrado en `hooks/hooks.json` (plugin) Y en `~/.claude/settings.json` (user-global, redundancia para cuando plugin-local queda desincronizado).

**Tests** (`e:\BATUTA PROJECTS\batuta-agent-skills\tests\authoring-gate\skill\`):
- `t1-no-marker.bats` — Write SKILL.md sin marker → exit-code de bloqueo.
- `t2-fresh-marker.bats` — Write SKILL.md con marker <60 min → permitido.
- `t3-stale-marker.bats` — Write con marker >60 min → bloqueado.
- `t4-non-batuta-repo.bats` — Write SKILL.md en repo cuyo origin no matchea → permitido (hook condicional).
- `t5-bypass-env.bats` — Write con `BATUTA_SKILL_AUTHORING_BYPASS=1` y sin marker → permitido + warning logueado.

### MUST-B: Enforcement agent-authoring

**Capa 1 (texto declarativo, soft)**:
- Nueva rule canónica: `e:\BATUTA PROJECTS\batuta-agent-skills\rules\authoring\agent-authoring-required.md`. Estructura del rule layer.
- Update `~/.claude/CLAUDE.md` (user-global): sección "Agent authoring gate".
- Update `e:\BATUTA PROJECTS\batuta-agent-skills\CLAUDE.md` (proyecto): re-anclar MUST-B.

**Capa 2 (hook PreToolUse, hard)**:
- Hook nuevo: `e:\BATUTA PROJECTS\batuta-agent-skills\hooks\pre-write-agent-gate.sh` (separado del de skill — paths distintos, markers distintos, mantener responsabilidad atómica).
- Matcher: `Write`/`Edit` sobre `**/agents/**.md`.
- **Condicional al repo**: igual que MUST-A.
- **Marker**: `batuta-agent-authoring` SKILL.md gana paso final que escribe `.claude/.authoring-marker-agent-<ISO>`.
- **Lógica**: marker más reciente edad < 60 min → permite; sino → bloquea con `"Invocá batuta-agent-authoring primero. Marker faltante o expirado."`.
- **Bypass**: env var `BATUTA_AGENT_AUTHORING_BYPASS=1` (separado del bypass de skill — un bypass cualquiera no debe levantar el otro gate).
- Registrado en `hooks/hooks.json` Y en `~/.claude/settings.json`.

**Excepción importante para agentes**: el agente `agent-architect` puede crear agentes project-local en `<project>/.claude/agents/<name>.md` como parte de su workflow normal (documentado en CLAUDE.md proyecto). El hook debe NO bloquear ese caso. Implementación: el `agent-architect` SKILL.md gana el mismo paso de marker (`.authoring-marker-agent-<ISO>`) al iniciar — el agent-architect ES el authoring gate runtime.

**Tests** (`e:\BATUTA PROJECTS\batuta-agent-skills\tests\authoring-gate\agent\`):
- `t1-no-marker.bats` — Write agents/<x>.md sin marker → bloqueado.
- `t2-fresh-marker-from-authoring.bats` — Write con marker dejado por `batuta-agent-authoring` <60 min → permitido.
- `t3-fresh-marker-from-architect.bats` — Write con marker dejado por `agent-architect` <60 min → permitido.
- `t4-stale-marker.bats` — marker >60 min → bloqueado.
- `t5-non-batuta-repo.bats` — repo distinto → permitido.
- `t6-bypass-env.bats` — `BATUTA_AGENT_AUTHORING_BYPASS=1` → permitido + warning.

### Estructura compartida (ambos gates)

| Aspecto | MUST-A (skill) | MUST-B (agent) |
|---|---|---|
| Rule | `rules/authoring/skill-authoring-required.md` | `rules/authoring/agent-authoring-required.md` |
| Hook | `hooks/pre-write-skill-gate.sh` | `hooks/pre-write-agent-gate.sh` |
| Path matcher | `**/skills/**/SKILL.md` | `**/agents/**.md` |
| Skill que da marker | `batuta-skill-authoring` | `batuta-agent-authoring` + `agent-architect` |
| Marker file | `.claude/.authoring-marker-skill-<ISO>` | `.claude/.authoring-marker-agent-<ISO>` |
| Bypass env | `BATUTA_SKILL_AUTHORING_BYPASS` | `BATUTA_AGENT_AUTHORING_BYPASS` |
| Tests dir | `tests/authoring-gate/skill/` | `tests/authoring-gate/agent/` |

### Orden de ejecución del Sprint 0

1. Escribir las dos rules (`rules/authoring/skill-...` y `rules/authoring/agent-...`).
2. Update `e:\BATUTA PROJECTS\batuta-agent-skills\CLAUDE.md` para re-anclar MUST-A y MUST-B.
3. Update `~/.claude/CLAUDE.md` (user-global) con ambas secciones.
4. Update `skills/batuta-skill-authoring/SKILL.md` para escribir el marker de skill al finalizar su workflow.
5. Update `skills/batuta-agent-authoring/SKILL.md` idem para marker de agent.
6. Update `agents/agent-architect.md` idem para marker de agent al iniciar (es authoring gate runtime).
7. Escribir los dos hooks (`pre-write-skill-gate.sh`, `pre-write-agent-gate.sh`).
8. Registrar ambos en `hooks/hooks.json` (plugin).
9. Registrar ambos en `~/.claude/settings.json` (user-global).
10. Escribir los 11 test cases (5 skill + 6 agent).
11. Correr suite completa: `tests/v2.5-validators/run.sh` (existente) + nueva `tests/authoring-gate/run.sh`. Todos deben pasar.
12. **Discovery con enforcement activo** — invocar `batuta-skill-authoring` para los 3 candidatos skill y `batuta-agent-authoring` para el candidato agent. Tabla de decisiones:

| Candidato | Gate a invocar | Búsqueda |
|---|---|---|
| `batuta-kb-vault` | `batuta-skill-authoring` | "knowledge base", "vault", "obsidian", "documentation index" |
| `kb-curate` | `batuta-skill-authoring` | "curate", "synthesize", "knowledge promotion", "documentation rollup" |
| `batuta-status` | `batuta-skill-authoring` | "status", "dashboard", "project overview" |
| `kb-backfill` | `batuta-skill-authoring` | "backfill", "import legacy", "retrofit knowledge", "git log to docs" |
| `kb-curator` | `batuta-agent-authoring` | distinctness vs implementer / code-reviewer / agent-architect |
| `kb-backfiller` | `batuta-agent-authoring` | distinctness vs implementer / kb-curator (decide modelo Sonnet vs Haiku heurísticamente) |

13. Capturar decisiones (`create | fork-from-X | reuse-X`) y actualizar la tabla "Files to create or modify".

### Salida del Sprint 0

- 0 SKILL.md / agent.md nuevos creados (solo modificados los existentes para el marker).
- 2 hooks activos, testeados (5 + 6 cases pasando).
- 2 rules en `rules/authoring/` y re-linked vía `setup-rules.sh --all` en consumers que las importen.
- `~/.claude/CLAUDE.md` y `~/.claude/settings.json` updated.
- `e:\BATUTA PROJECTS\batuta-agent-skills\CLAUDE.md` updated.
- Decisiones de discovery tomadas para los 4 candidatos.

**Sprint 0 bloquea Sprint 1**. Hasta que ambos enforcements estén verdes, no se crea ningún SKILL.md o agent.md nuevo.

## Bootstrap del vault (vault preexistente)

El vault ya existe en `<vault_root>` con Obsidian configurado. Bootstrap = versionarlo + completar estructura faltante.

```bash
cd "E:/Gdrive Batuta/My Drive/BATUTA AI/OBSIDIAN/BATUTA"
mkdir -p clients decisions gotchas glossary/products glossary/domains glossary/people \
         playbooks journals templates _inbox status

cat > .gitignore <<'EOF'
.obsidian/workspace*.json
.obsidian/cache/
.DS_Store
*.tmp
.trash/
**/secrets/
**/.env
EOF

git init
git add .gitignore .obsidian clients decisions gotchas glossary playbooks journals templates _inbox status
git commit -m "chore: vault git bootstrap (atop preexisting Obsidian vault)"
gh repo create jota-batuta/batuta-kb --private --source=. --remote=origin --push
```

### Mitigación Drive + git (decidir Sprint 1)

`.git/objects/` con cientos de blobs adentro de Google Drive sync es ruidoso (Drive intenta sincronizar cada uno; conflictos raros pero existen). Dos opciones:

**Opción 1 — Excluir `.git/` de Drive sync (recomendada por simpleza)**:
- Drive Desktop > Preferences > seleccionar carpeta vault > "Choose folders to sync" > excluir `.git/`.
- **TODO Sprint 1**: confirmar que Drive Desktop versión 2026 permite exclusión por subfolder. Si no, fallback Opción 2.

**Opción 2 — Bare repo afuera de Drive + worktree adentro**:
```bash
git init --bare ~/batuta-kb-bare.git
cd "$VAULT_ROOT"
git init && rm -rf .git
echo "gitdir: $HOME/batuta-kb-bare.git" > .git
git remote add origin https://github.com/jota-batuta/batuta-kb.git
```
Drive solo ve los `.md`. Setup menos estándar; clones desde otra máquina requieren replicar el patrón.

## Sprints de ejecución

### Sprint 1 — Captura L1 + bootstrap + piloto (3-5 días, post-Sprint 0)
- ADR-0011 escrito y mergeado vía PR (no merge directo — política operador).
- `hooks/post-commit-kb.sh` + `tools/kb-resync.sh`.
- Update `batuta-project-hygiene` paso 4c.
- Nueva skill `batuta-kb-vault` (incluye doc de niveles L0-L3 y convenciones del vault preexistente).
- Bootstrap del vault (`git init` + `gh repo create`) según sección anterior. Decidir Drive+git Opción 1 vs 2.
- Piloto en **bato-cajas** (rules semilla → menor riesgo). 5+ commits reales para validar journal + mirror a L1 en `<vault_root>/clients/bato-cajas/projects/bato-cajas/sessions/`.

### Sprint 2 — Curación L1→L2 + visibilidad (4-6 días)
- Nueva skill `kb-curate` + agente `kb-curator` + slash `/kb-curate` (nombres definitivos pueden cambiar tras Sprint 0).
- Slash `/kb-end-session` (complementa `/save-plan`).
- Slash `/batuta-status` (visibilidad rápida).
- Matriz de control por categoría implementada.
- Routine `/schedule cron=0 9 * * 1` que (a) corre `/kb-curate --scope week`, (b) regenera `<vault_root>/STATUS.md`.
- `<vault_root>/_dashboard.md` con queries Dataview iniciales.
- Template GitHub Action `kb-curate-on-merge.yml`.
- `research-first-dev` Step 1.5 con priorización L2 > L3 > L1.
- Test de curación end-to-end en bato-cajas: hacer commits que generen las 7 categorías de bullets, correr `/kb-curate`, validar drafts y auto-applies.

### Sprint 2.5 — KB backfill de repos legacy (3-5 días)

Función análoga a `mode=project-retrofit` de hygiene, pero para **conocimiento histórico**: respaldar lo que existe en repos viejos pero nunca pasó por Notion. Operación per-repo, idempotente.

**Slash nuevo**: `/kb-backfill --repo <path> [--scope readme,commits,issues,code]`. Default: `--scope readme,commits,issues`. Análisis de código solo si se solicita explícitamente (caro en tokens).

**Agente candidato**: `kb-backfiller` (pasa por `batuta-agent-authoring` en Sprint 0). Modelo: **Sonnet** por default; Haiku como fast-path si el repo es chico (<500 commits, <50 archivos `.md`) o bien-conocido. La skill detecta heurísticamente y propone modelo, operador override con `--model haiku|sonnet`.

**Pipeline del backfill** (4 fases configurables):

1. **Fase READMEs + docs/** (siempre):
   - Leer `README.md`, `CONTRIBUTING.md`, todo `.md` en `docs/`, `notes/`, archivos `ADR-*.md`, `DECISIONS.md`, `NOTES.md`, etc.
   - Producir entries L0 en `<vault_root>/_inbox/backfill-<repo>-<date>/<file>.md` con frontmatter `source: backfill, source_path: <repo>/<rel>, backfill_phase: readme`.
   - Bajo costo, alta precisión, baja síntesis. Es copia-con-frontmatter.

2. **Fase commit messages útiles**:
   - `git -C <repo> log --since="2 years ago" --pretty='%H|%ai|%an|%s%n%b'`.
   - Filtros (heurística): mensaje > 30 chars, no matchea `^(chore|wip|fix typo|build|ci):`, body presente o subject con keywords (`refactor`, `breaking`, `decision`, `migrate`, `deprecate`, `rationale`).
   - Para cada commit pasa-filtro: extraer archivos cambiados (`git show --stat <sha>`); generar bullet L1 retroactivo en `<vault_root>/clients/<c>/projects/<p>/sessions/<commit-date>.md`.
   - Bullets marcados `backfilled: true` para que el curator los priorize.

3. **Fase issues / PRs** (si gh remote presente):
   - `gh -R <owner>/<repo> issue list --state all --label decision,gotcha,breaking,question --limit 200`.
   - `gh -R <owner>/<repo> pr list --state merged --search "in:body decision OR rationale OR fixes-bug" --limit 200`.
   - Para cada hit: producir entry L0 en `_inbox/` con frontmatter rico (issue number, autor, fecha, link). Operador (con `kb-curator`) cura después.

4. **Fase análisis del código** (opt-in, costoso):
   - Sub-agente `kb-backfiller` (Sonnet) lee:
     - Comments `// TODO|FIXME|HACK|XXX|WORKAROUND` con contexto ±5 líneas.
     - `.env.example` y comparar con `.env.production` references → entries de "config críticas".
     - Archivos sospechosos de gotcha: `**/migrations/`, `**/legacy/`, `**/compat/`, `**/polyfill/`.
     - `package.json` / `pyproject.toml`: dependencies con `@`-pin específico vs ranges → sugiere "decision pin lib X@version Y por razón Z".
   - Output: entries L0 en `_inbox/code-analysis-<repo>/`, taggeadas `#status/needs-curation` con confianza `low|medium|high` por la heurística.

**Output del backfill por repo**: directorio `<vault_root>/_inbox/backfill-<repo-slug>-<YYYY-MM-DD>/` con todos los entries por fase, listo para drenar con `/kb-curate --scope inbox-backfill`.

**Idempotencia**: el slash escribe un manifest `<vault_root>/_inbox/backfill-<repo>-<date>/manifest.yaml` con qué fases corrieron y SHA del último commit procesado. Re-correr el slash con el mismo repo: skip de fases ya corridas (operador override con `--force`).

**Repos candidatos para Sprint 2.5** (orden sugerido):
1. `D:\bato-cajas` — más reciente, rules semilla → mejor input para validar el pipeline.
2. `D:\BATO2` — mediano, gh remote disponible → valida fase issues/PRs.
3. `D:\BATO` — más viejo, posiblemente sin docs → valida que el backfill maneja vacíos sin error.
4. `E:\BATUTA PROJECTS\batuta-portal` y `Batuta APP` — sin remote → solo fases 1, 2, 4 (no 3).
5. Cualquier otro repo en `D:\` y `E:\BATUTA PROJECTS\` con valor — operador decide cuáles.

**Costos estimados** (rough): por repo, fase 1 + 2 ≈ 5-15k tokens (cheap, Sonnet). Fase 3 ≈ 10-30k tokens. Fase 4 ≈ 50-150k tokens. El operador puede correr fases 1+2+3 en bulk y fase 4 selectiva.

### Sprint 3 — Retrofit en proyectos pendientes (2-3 días)
- `mode=project-retrofit` en BATO, BATO2, batuta-portal, Batuta APP.
- `.claude/kb-config.json` + GitHub Action por proyecto.
- Smoke test: 1 commit + 1 curación por proyecto.

### Sprint 4 — Migración Notion + deprecación (1-2 semanas elapsed, async)
- Export Notion → `<vault_root>/_inbox/notion-export-2026-04-29/`.
- Drenaje incremental (3-5 páginas por sesión, asistido por `kb-curator`).
- Reescribir `notion-kb-workflow` SKILL como modo opcional cliente-facing.
- Update user-global CLAUDE.md.

## Verification

Piloto: **bato-cajas**. Test cases:

1. Commit normal en main → journal del día tiene entry; vault mirror correcto.
2. Commit en feature branch → slug del journal proviene del branch.
3. `git commit --amend` → línea reemplazada, no duplicada.
4. Rebase 3 commits → hook silencia durante rebase; tras `--continue` correr `kb-resync.sh`; journal queda con 3 entries reordenadas.
5. `commit --no-verify` → post-commit corre igual (correcto, --no-verify solo skipea pre-commit/commit-msg).
6. Repo sin `kb-config.json` → `exit 0` silencioso.
7. Vault path borrado → journal proyecto SÍ se escribe; mirror omitido con warning en debug.log.
8. Step 1.5 hit fresco en L2 (`last_verified` 2026-03) → cita local sola, no llama Context7.
9. Step 1.5 hit stale en L2 (`last_verified` 2025-01) → fuerza Context7, cita doble, actualiza `last_verified`.
10. Step 1.5 con hit solo en L1 (no curado) → devuelve con disclaimer "no curado, verificá", procede a Context7 igual.
11. `/kb-curate --scope session` después de 5 commits con: 1 decision-new, 1 decision-supersede, 1 gotcha-new, 1 gotcha-update, 1 noise → produce 2 `.draft.md` (decisions), 1 commit auto a vault (gotcha-new), 1 `.draft.md` (gotcha-update), bullet noise marcado `curated_into: []`.
12. `/kb-curate` re-corrida sobre el mismo journal → 0 cambios (idempotente, ve `curated_into:` ya presente).
13. PR mergeado en bato-cajas con feature branch → GitHub Action dispara `/kb-curate --feature <branch>`; vault recibe commit con resumen.
14. Cron lunes 9am → routine corre, encuentra 0-N journals sin curar, produce drafts, regenera `STATUS.md`.
15. `/batuta-status --scope all` después de hacer 5 commits en bato-cajas + 1 en BATO2 → output muestra ambos proyectos con métricas correctas, drafts pendientes contados.
16. Abrir `<vault_root>/_dashboard.md` en Obsidian → queries Dataview computan en vivo (`#status/needs-review` lista los `.draft.md` activos).
17. `/kb-backfill --repo D:\bato-cajas --scope readme,commits` → produce `<vault_root>/_inbox/backfill-bato-cajas-2026-04-29/` con entries por fase + manifest. Re-correr el slash → idempotente (skip).
18. `/kb-backfill --repo D:\BATO2 --scope readme,commits,issues` → fase issues activa (gh remote), trae issues cerrados con label `decision`/`gotcha`/`breaking`.
19. `/kb-curate --scope inbox-backfill` después de 18 → cura entries L0 del backfill, propone drafts L2 con tag `backfilled: true` en frontmatter para auditabilidad.
20. Test crítico Drive+git: hacer 10 commits en el vault desde Obsidian Git plugin sobre filesystem en Drive. Verificar que no hay conflictos de `.git/objects/` ni archivos duplicados estilo `(jota-batuta@machine).md`.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Hook falla y bloquea commit | `set +e` + `trap 'exit 0' ERR` + explícito `exit 0` siempre |
| Vault en Google Drive (FS sync) introduce conflictos `.md` o ruido en `.git/` | Excluir `.git/` de Drive sync (Opción 1) o bare-repo afuera (Opción 2). Audit: `gh repo view jota-batuta/batuta-kb` debe coincidir con `git log` local. **TODO Sprint 1 validar** |
| Backfill produce ruido masivo en `_inbox/` | `kb-curator` prioriza entries `backfilled: true` con flag `confidence:` para que el operador filtre. Drenaje incremental (3-5 entries/sesión); no procesar todo de golpe. |
| Repo del vault público por error | `gh repo create --private`. Audit: `gh repo view jota-batuta/batuta-kb --json visibility` |
| PII / NDA en commits del vault | `.gitignore` template + convención (iniciales en lugar de nombres). NDA-sealed → `clients/<c>/sealed/` con gitignore por-cliente |
| Cumplimiento ISO 27001 / SOC 2 | Cumple parte: data residency local + audit trail git + versionado. No cumple sin trabajo extra: backup off-site formal, key rotation, access review (TODO en ADR-0011) |
| Hook se pierde al clonar | TODO: decidir entre per-repo install vs `core.hooksPath` global apuntando a `~/.config/git/batuta-hooks/` poblado por `setup-rules.sh --all` |
| Operador commitea con `--no-verify` | --no-verify NO skipea post-commit. Sin riesgo. |

## TODOs explícitos por Sprint

**Sprint 1**:
1. Validar en runtime real Windows que `.git/hooks/post-commit` con shebang bash ejecuta sin fricción en GitHub Desktop + VS Code source control + git CLI.
2. Decidir entre per-repo hook copy vs `core.hooksPath` global. Recomendación: `core.hooksPath` para evitar drift cuando el script cambia, pero requiere un primer install global (`setup-rules.sh --all` lo cubriría).
3. Confirmar con el operador si quiere journal-por-día único o journal-por-feature (afecta `session_slug_strategy` default).
4. Verificar el número de ADR siguiente disponible — si `0007-code-graph-dual-engine.md` no existe, ajustar.

**Sprint 2**:
5. Definir prompts del agente `kb-curator` con ejemplos few-shot por las 7 categorías (decision-new/supersede, gotcha-new/update, playbook, glossary, noise).
6. Decidir formato del bullet de journal para que el curator pueda parsearlo confiablemente (ej. enforce indentación, sub-bullets explícitos para `branch:`, `files:`, `plan:`).
7. Validar GitHub Action: `gh pr merge --squash --auto` en un repo del operador NO tiene permisos para invocar Claude Code. Alternativa: la action solo agrega un label `kb-curate-pending` que el operador procesa con `/kb-curate --scope all-pending`. **TODO**: confirmar si Claude Code se puede invocar en GitHub Actions o si la action es solo "marcador".

**Sprint 2.5**:
8. Confirmar el orden de repos a backfilear con el operador. Default: bato-cajas → BATO2 → BATO → batuta-portal → Batuta APP, fases 1+2+3 en bulk; fase 4 selectiva.
9. Validar costos reales en bato-cajas (fase 1+2+3) antes de escalar a los otros 4 repos. Si fase 3 (gh issues/PRs) no aporta porque los repos del operador no usan issues — desactivarla por default.
10. Definir cuándo `kb-backfiller` propone Haiku vs Sonnet. Heurística inicial: <500 commits AND <50 archivos `.md` → Haiku; sino Sonnet. Operador override siempre disponible.

**Sprint 4**:
11. Auditar contenido Notion actual antes de migración para dimensionar el drenaje del `_inbox/`.

**Sprint 1 (riesgo Drive+git)**:
12. Validar que Google Drive Desktop versión actual permite excluir `.git/` por subfolder (Opción 1 del bootstrap). Si no, ejecutar Opción 2 (bare repo + worktree).

## Open questions resueltas en esta sesión

- ✅ Notion vs Obsidian → Obsidian primario, Notion opcional cliente-facing.
- ✅ Stop hook vs commit hook → git post-commit hook (no Claude Code).
- ✅ Adopción primero o KB primero → orden lógico cubierto por Sprints 1-2-3.
- ✅ NDA cloud → vault local + repo privado en GitHub cumple best practices iniciales.
