# Plan: integrar capa de Code Knowledge Graph a `batuta-agent-skills` (v2.8)

## Context

El problema que resuelve este plan: hoy, cuando un agente o el operador necesitan responder preguntas de arquitectura ("explicame este repo", "qué módulos están acoplados", "dónde se llama X"), Claude termina haciendo Glob+Grep+Read sobre decenas de archivos. Eso quema tokens, quema latencia, y la respuesta sufre de window-fatigue. La solución es persistir un grafo del codebase y consultarlo en lugar de releerlo.

**Decisiones tomadas con el operador**:
- **Doble motor con fallback** (Ruta γ): integramos **graphify** ([github.com/safishamsi/graphify](https://github.com/safishamsi/graphify) v0.5.4, multimodal, MIT) **+ codebase-memory-mcp** ([github.com/DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) v0.6.0, MCP server, 1.9k⭐, org backing) como respaldo. Razón: graphify tiene 3 issues abiertos bloqueantes en Windows ([#378](https://github.com/safishamsi/graphify/issues/378), [#244](https://github.com/safishamsi/graphify/issues/244), [#501](https://github.com/safishamsi/graphify/issues/501)) y bus factor 1; codebase-memory-mcp es estable en Win11 pero solo procesa código (no multimodal). El skill detecta cuál está disponible y funcional en runtime y usa el mejor.
- **Auto-trigger + slash command híbrido** para invocación.
- **Multimodal completo permitido** cuando el motor activo es graphify (proveedor LLM ya autorizado por contrato cliente).
- **Bootstrap operador-side** instala ambos motores. El operador no debe recordar que las herramientas existen — aplica a proyectos nuevos y antiguos vía retrofit.
- **Sin Obsidian.** Mantener `notion-kb-workflow` actual sin tocar. Obsidian queda fuera de scope (descartado a favor de continuar con Notion).
- **Bundle único en v2.8.** Un solo PR con todo: bootstrap dual + skill con engine detection + slash + rule + CLAUDE.md + ADR.

Hay un choque crítico que define el resto del diseño: el comando "oficial" `graphify claude install` modifica `.claude/settings.json` para inyectar un hook PreToolUse, lo cual cae directamente en el **kill-switch v2.7** de [hooks/delegation-guard.sh](hooks/delegation-guard.sh). Ergo: **NO usamos `graphify claude install`**. Integramos por capas controladas: bootstrap operador-side instala los binarios, y un skill propio gobierna la política sin tocar settings.json. Para codebase-memory-mcp, el registro como MCP server pasa por `claude mcp add` (escribe a `~/.claude.json`, fuera del kill-switch).

---

## 1. Los dos motores (hechos verificados)

### Motor primario — Graphify

| Campo | Valor |
|---|---|
| Repo | https://github.com/safishamsi/graphify (verificado 2026-04-29) |
| Última versión | `graphifyy@0.5.4` — release 2026-04-28 |
| Licencia | MIT |
| Runtime | Python 3.10+ |
| Instalación | `uv tool install graphifyy` o `pipx install graphifyy` |
| CLI | `graphify` |
| Lenguajes soportados | 25 vía tree-sitter (Python, JS/TS, Go, Rust, Java, C/C++, etc.) |
| Outputs por default | `graphify-out/{graph.json, graph.html, GRAPH_REPORT.md, cache/}` |
| Outputs opcionales | `--svg`, `--graphml`, `--neo4j`, `--wiki`, `--obsidian` |
| MCP server | `graphify ./raw --mcp` o `python -m graphify.serve` (tools: `query_graph`, `get_node`, `get_neighbors`, `shortest_path`) |
| Privacidad | Código fuente: solo AST local (no sale del equipo). Docs/PDFs/imágenes: van al LLM del proyecto. Audio/video: Whisper local. |
| Fortaleza única | **Multimodal**: cubre código + docs + PDFs + imágenes + audio. Único en su categoría. |
| Riesgos verificados | Bus factor = 1 (autor `safishamsi`, 119 PRs sin mergear). 3 issues abiertos bloqueantes en Windows. Cadencia panic-driven. |

### Motor de fallback — codebase-memory-mcp

Datos verificados contra el README oficial (2026-04-29 — research-first dispatch):

| Campo | Valor |
|---|---|
| Repo | https://github.com/DeusData/codebase-memory-mcp (verificado 2026-04-29) |
| Última versión | v0.6.0 (release 2026-04-06), 1.9k⭐ |
| Licencia | MIT |
| Runtime | **Binario C nativo, statically linked** — cero dependencias externas (NO requiere Node.js, Python, ni nada) |
| Instalación oficial Linux/Mac | `curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh \| bash` |
| Instalación oficial Windows | `Invoke-WebRequest -Uri https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 -OutFile install.ps1; .\install.ps1` |
| Flag crítico | `--skip-config` evita que el installer auto-modifique configs de agente. **Lo usamos siempre** y registramos manualmente con `claude mcp add` para no chocar con kill-switch. |
| Otras flags | `--ui` (visualizador), `--dir=<path>` (location custom) |
| Registro como MCP server | `claude mcp add --scope user --transport stdio codebase-memory -- <binary-path>` (verificado contra docs Claude Code 2026-04-29; escribe a `~/.claude.json`, fuera del kill-switch) |
| Cache local | `~/.cache/codebase-memory-mcp/` (SQLite). Override vía env `CBM_CACHE_DIR`. |
| Tipo | MCP server stdio, no CLI standalone para queries (queries pasan por el MCP) |
| Lenguajes soportados | 66 (más amplio que graphify) |
| API MCP — 14 tools, nombres exactos verificados | `index_repository`, `list_projects`, `delete_project`, `index_status`, `search_graph`, `trace_call_path`, `detect_changes`, `query_graph`, `get_graph_schema`, `get_code_snippet`, `get_architecture`, `search_code`, `manage_adr`, `ingest_traces` |
| Watch / auto-index | Sí. Habilitar con `codebase-memory-mcp config set auto_index true`. Configurable file limit con `auto_index_limit` (default 50000). |
| Privacidad | 100% local, código nunca sale del equipo. Sin API keys. |
| Fortaleza | Indexa el kernel de Linux (28M LOC) en ~3 minutos. **99% token reduction** en consultas vs Glob/Grep. Org backing (DeusData). |
| Limitación | Solo código. **No procesa** docs, PDFs, imágenes ni audio. |
| Windows caveat | SmartScreen warning en primera ejecución; verificar checksums.txt SHA-256 del release. |

**Nota — research-first dispatch aplicado**: la planeación inicial asumió Node.js como runtime y nombres de tools tipo `index_codebase`/`search_symbol`/`get_neighbors`/`read_chunk`. Ambos eran incorrectos. Fuente verificada: https://github.com/DeusData/codebase-memory-mcp (2026-04-29, codebase-memory-mcp@0.6.0). La arquitectura del slice no cambia, solo se actualizan los detalles de install y los nombres de tools que el skill invoca.

### Cómo deciden cuál usar

El skill de Claude Code (Capa 1, abajo) ejecuta detección al inicio:

1. **Repo tiene docs/PDFs/imágenes que importan** + **graphify CLI funcional** → graphify.
2. **Repo es solo código** **o** **graphify falla en este OS** (Windows con install incompleto) → codebase-memory-mcp.
3. **Operador override explícito** vía slash command `--engine graphify|codebase-memory` → respeta lo pedido.
4. **Ninguno funciona** → instruir al operador a re-correr el bootstrap; no proceder con análisis ciegamente.

## 2. Qué hace realmente cada motor (no mitos)

### Graphify

Tres pasadas independientes:

1. **AST determinístico local** — tree-sitter parsea funciones, clases, imports, call graphs de 25 lenguajes. Sin LLM. Sin red.
2. **Transcripción multimedia local** — `faster-whisper` (~2GB modelo, descarga on-demand) procesa audio/video sin enviar a cloud.
3. **Extracción semántica con LLM** — solo para `*.md`, `*.pdf`, imágenes y transcripciones. Construye relaciones tipo "esta función implementa lo descrito en este RFC".

Outputs útiles:
- `GRAPH_REPORT.md` — texto plano con god-nodes, conexiones inesperadas, comunidades detectadas (clustering Leiden).
- `graph.json` — grafo serializado consultable programáticamente.
- `graph.html` — visualización interactiva vis.js.
- MCP server opcional para consultas estructuradas en runtime.

### codebase-memory-mcp

Una sola pasada:

1. **Indexación AST + symbol table local** — recorre el codebase, construye un grafo de símbolos (definiciones, usos, llamadas) en cache local. Sin LLM en runtime.

Output: cache local indexado (no Markdown legible). Se consume **exclusivamente** vía MCP tools desde el agente. El operador no abre archivos para leer el grafo — pregunta a Claude y Claude consulta el MCP.

## 3. Por qué implementarlo (beneficios concretos)

- **Onboarding clientes nuevos** — nuevos devs (humanos o agentes) leen `GRAPH_REPORT.md` antes de tocar código. Reduce time-to-first-PR.
- **Audit chain más eficiente** — `code-reviewer` y `security-auditor` consultan el grafo en lugar de re-leer archivos. Menos tokens, mejor cobertura.
- **Refactor seguros** — detecta acoplamientos circulares y comunidades antes de mover código.
- **Documentación viva** — el grafo se persiste en el repo y actualiza incrementalmente (cache SHA256).
- **Cobertura multimodal** — PDFs de spec, diagramas en imágenes, transcripciones de calls (con permiso) entran al mismo grafo. Diferenciador vs herramientas solo-código.

## 4. Cómo se integra — diseño en 5 capas

### Capa 0 — Bootstrap dual ([tools/setup-code-graph.sh](tools/setup-code-graph.sh), nuevo)

**Por qué existe**: el operador pidió explícitamente "no puedo estar sujeto a recordar que esta herramienta existe en cada proyecto nuevo, y claro que lo usaré en proyectos antiguos". Solución: script bash idempotente que el operador (no Claude) ejecuta y deja **ambos motores** disponibles. Patrón ya consolidado en el plugin con [tools/setup-rules.sh](tools/setup-rules.sh).

Comportamiento:

**Bloque 1 — Instalar graphify**
1. Detectar gestor disponible en orden: `uv` → `pipx` → `pip --user`. Si ninguno existe, instalar `uv` vía script oficial Astral (≤ 5 segundos).
2. Detectar `graphify --version`. Si existe y es `>= 0.5.4`, saltar a Bloque 2.
3. Si falta o está desactualizado, ejecutar `<gestor> install graphifyy` (o `upgrade`).
4. Smoke test post-install: `graphify --version`. Si falla en Windows (issue [#378](https://github.com/safishamsi/graphify/issues/378)), marcar `GRAPHIFY_AVAILABLE=false` y continuar (no abortar — codebase-memory-mcp queda como respaldo).

**Bloque 2 — Instalar codebase-memory-mcp** (binario C nativo, sin runtime extra)
1. Detectar `command -v codebase-memory-mcp`. Si existe, saltar a paso 4.
2. Si falta, descargar el binario con el script oficial **y `--skip-config` siempre** para evitar que el installer toque configs de agente:
   - Linux/Mac: `curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash -s -- --skip-config`
   - Windows: invocar `install.ps1 --skip-config` vía `powershell.exe -ExecutionPolicy Bypass`
3. Resolver path absoluto del binario instalado (típicamente `~/.local/bin/codebase-memory-mcp` o `~/AppData/Local/...` en Win).
4. Verificar si ya está registrado: `claude mcp list | grep -q '^codebase-memory'`. Si no, registrar:
   ```bash
   claude mcp add --scope user --transport stdio codebase-memory -- "$BINARY_PATH"
   ```
   Escribe a `~/.claude.json` (fuera del kill-switch v2.7).
5. Smoke test: invocar el server y verificar que responde a `tools/list` con los 14 tools esperados.

**Bloque 3 — Reportar estado**
- Imprimir resumen: `graphify=OK|MISSING|BROKEN`, `codebase-memory-mcp=OK|MISSING|BROKEN`.
- Persistir el estado en `~/.claude/code-graph-engines.json` para que el skill (Capa 1) lo lea sin re-detectar.
- Exit 0 si al menos uno de los dos quedó funcional. Exit 1 si ambos fallan.

Integración con flujos existentes:

- [tools/setup-rules.sh](tools/setup-rules.sh) `--all` invoca también `setup-code-graph.sh`. Bootstrap único para el operador.
- La skill `batuta-project-hygiene` (`mode=project-init` y `mode=project-retrofit`) llama a `setup-code-graph.sh` como parte de su flujo. Cubre proyectos antiguos: `mode=project-retrofit` sobre un repo viejo deja ambos motores listos.
- Modo manual: `bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh`.

**Garantía clave**: este script lo ejecuta el operador o un script bash, **no Claude vía Edit/Write**. Por lo tanto no pasa por [hooks/delegation-guard.sh](hooks/delegation-guard.sh) y el kill-switch queda intacto. El script tampoco toca `.claude/settings.json`; el registro del MCP server escribe a `~/.claude.json` (vía `claude mcp add`) que **no** está en el kill-switch.

### Capa 1 — Skill auto-trigger ([skills/code-graph/SKILL.md](skills/code-graph/SKILL.md), nuevo)

Patrón híbrido inspirado en [skills/research-first-dev/SKILL.md](skills/research-first-dev/SKILL.md) (auto-trigger por descripción) y [skills/notion-kb-workflow/SKILL.md](skills/notion-kb-workflow/SKILL.md) (modos múltiples explícitos).

**Nombre del skill**: `code-graph` — genérico, no atado a un motor. Internamente despacha a graphify o codebase-memory-mcp según disponibilidad y necesidad.

Frontmatter:
```yaml
---
name: code-graph
description: Use to build or query a code knowledge graph before answering architecture, onboarding, or large-refactor questions. Auto-triggers when the operator asks about repo structure, dependencies, or module relationships. Internally selects between graphify (multimodal, when available) and codebase-memory-mcp (code-only fallback). Four user-facing modes — scan, watch, mcp, query.
---
```

**Engine selection (Step 0 reforzado)** antes de cualquier otra cosa:

1. Leer `~/.claude/code-graph-engines.json` (estado escrito por Capa 0). Si no existe, instruir al operador a correr `setup-code-graph.sh` y stop.
2. Determinar engine deseado:
   - Si la pregunta del operador menciona PDFs / docs / imágenes / arquitectura conceptual de alto nivel → preferir **graphify** (si está OK).
   - Si la pregunta es estricta sobre código (call graph, definiciones, usos) → preferir **codebase-memory-mcp** (más rápido, más preciso para esa tarea).
   - Override explícito vía slash command (`/code-graph --engine graphify` o `--engine codebase-memory`) tiene precedencia.
3. Si el engine preferido está `BROKEN` o `MISSING`, caer al otro. Si el otro también, instruir re-bootstrap.
4. Persistir la decisión en context (qué motor se usó) para que la respuesta al operador cite el motor.

Estructura del SKILL.md (secciones obligatorias del estándar Batuta):

- **Overview** — el problema (Claude releyendo el repo), la solución (grafo persistido), la restricción Batuta (no `graphify claude install`).
- **When to Use** — tabla con los 4 modos (cada uno se traduce al engine activo):

  | Modo | Trigger | Implementación con graphify | Implementación con codebase-memory-mcp |
  |---|---|---|---|
  | `--scan` | Primera vez en el repo, o índice ausente / stale > 24h | `graphify .` (genera `graphify-out/`) | invocar tool MCP `index_repository` (cache local SQLite) |
  | `--watch` | Sesión larga de refactor; operador lo pide explícito | `graphify ./src --watch` (background) | `codebase-memory-mcp config set auto_index true` (background watcher) |
  | `--mcp` | Queries estructuradas (shortest_path, neighbors, call paths) | `graphify ./src --mcp` (levanta server propio) | Ya está siempre disponible — es nativamente MCP |
  | `--query` | Índice fresco, solo hay que leer | parsear `GRAPH_REPORT.md` o consultar MCP graphify | invocar tools MCP `search_graph`, `query_graph`, `trace_call_path`, `get_architecture`, `get_code_snippet` según el tipo de pregunta |

- **Process** — pasos numerados:
  - **Step 0 — Engine selection** (descrito arriba): leer `~/.claude/code-graph-engines.json`, decidir engine, fallback.
  - **Step 1 — Detect freshness** — para graphify: chequear `graphify-out/GRAPH_REPORT.md` mtime y commits desde entonces. Para codebase-memory-mcp: invocar tool `last_indexed_at` (o equivalente, verificar API exacta).
  - **Step 2 — Run** — invocar el modo elegido contra el engine seleccionado. Esperar señal de éxito.
  - **Step 3 — Read, don't dump** — sintetizar resumen estructurado al operador (god-nodes, comunidades, ciclos detectados) **citando el motor usado**: `[via graphify]` o `[via codebase-memory-mcp]`. NO volcar JSON crudo.
  - **Step 4 — Cite the graph** — cualquier afirmación de arquitectura que se haga después en la sesión debe linkear al nodo del grafo o al archivo + línea exacta. El reporte es la fuente.

- **Anti-Rationalizations** — tabla con al menos 4 excusas (ej. "el grafo está stale pero sirve igual" → reality: stale = wrong arquitectura; "voy a leer los archivos directo" → reality: por eso existe el grafo; "graphify falla así que no uso nada" → reality: hay fallback).
- **Red Flags** — 5+ señales de mal uso (correr `graphify claude install`, ignorar warning de stale, commitear `graphify-out/` al repo, asumir un engine sin verificar `code-graph-engines.json`, etc.).
- **Verification** — comandos copiables para validar:
  - graphify: `test -f graphify-out/GRAPH_REPORT.md`, `jq '.nodes | length' graphify-out/graph.json`, `git check-ignore graphify-out/`.
  - codebase-memory-mcp: `claude mcp list | grep codebase-memory`, invocación de prueba a tool MCP `search_graph` con un símbolo conocido del repo, verificar `index_status` reporta el repo indexado.

### Capa 2 — Slash command ([.claude/commands/code-graph.md](.claude/commands/code-graph.md), nuevo)

Patrón canónico [.claude/commands/save-plan.md](.claude/commands/save-plan.md) (operador-invocado, idempotente, deterministic).

`$ARGUMENTS` admite:
- `<path>` — scan one-shot con engine auto-detectado
- `--watch <path>` — daemon. Con graphify usa `--watch` flag; con codebase-memory-mcp activa `auto_index true` (background watcher con file limit configurable).
- `--mcp <path>` — fuerza levantar MCP server graphify (con codebase-memory-mcp ya está activo, este flag no hace nada salvo confirmar)
- `--query "<expr>"` — query contra el índice activo
- `--engine graphify|codebase-memory` — override explícito del engine (precede a la auto-detección)
- vacío → scan del cwd con engine auto-detectado

Steps:
1. Verificar estado de motores (reusa [tools/check-code-graph-engines.sh](tools/check-code-graph-engines.sh)).
2. Aplicar override de `--engine` si está; si no, usar la lógica de Step 0 del skill.
3. Verificar `.gitignore` contiene `graphify-out/` (añadir si falta — está fuera del kill-switch path, OK). Para codebase-memory-mcp, su cache local también debe ignorarse (path exacto a verificar contra README).
4. Ejecutar comando contra el engine elegido.
5. En modo `--watch` con graphify, registrar PID en `.graphify.pid` y emitir comando para detenerlo. Con codebase-memory-mcp, el watcher es interno al server (no hay PID separado a manejar).
6. Confirmar al operador con path al output **y motor usado** (`Done via graphify` o `Done via codebase-memory-mcp`).

### Capa 3 — Rule importable ([rules/integrations/code-graph-usage.md](rules/integrations/code-graph-usage.md), nuevo)

Sigue el contrato de [rules/_meta/how-to-import.md](rules/_meta/how-to-import.md). Frontmatter: `title`, `applies-to: any-project`, `last-reviewed: 2026-04-29`.

Contenido (declarativo, no procedural — el procedural va en el SKILL):
- **Always**: leer el output del engine activo antes de afirmar nada de arquitectura. Para graphify es `GRAPH_REPORT.md`; para codebase-memory-mcp es invocar el tool MCP correspondiente.
- **Always**: ignorar `graphify-out/` y el cache local de codebase-memory-mcp en git (paths exactos a documentar al implementar).
- **Always**: citar el motor usado en cada respuesta de arquitectura (`[via graphify]` o `[via codebase-memory-mcp]`).
- **Never**: ejecutar `graphify claude install` (modifica `.claude/settings.json` → kill-switch v2.7).
- **Never**: commitear `graphify-out/` ni el cache de codebase-memory-mcp (binarios pesados, regenerables).
- **Never**: confiar en un índice > 24h en una rama activa con commits posteriores.
- **Never**: asumir que un engine está disponible. Siempre leer `~/.claude/code-graph-engines.json` o invocar `check-code-graph-engines.sh`.
- **Anti-patterns** (sección obligatoria por §A.4 del rule-authoring):
  1. "Voy a leer los archivos directo, es más rápido" — no en repos > 5k LOC; usá el grafo.
  2. "El grafo no se actualizó pero la respuesta es la misma" — falso por construcción si hubo commits.
  3. "Corro `graphify claude install` y listo" — bloqueado por kill-switch.
  4. "Graphify falló, no hay grafo posible" — no, hay fallback con codebase-memory-mcp.
  5. "Uso codebase-memory-mcp porque es más nuevo" — no es cuestión de novedad, es cuestión de qué tipo de pregunta se hace (multimodal vs solo código).

Proyectos consumidores la importan con `@.claude/rules/code-graph-usage.md` después de correr [tools/setup-rules.sh](tools/setup-rules.sh).

### Capa 4 — Update [CLAUDE.md](CLAUDE.md) raíz del plugin

En la sección `## Mandatory Skills for Batuta Projects`, añadir:

```markdown
### code-graph (auto + manual, dual-engine)
**MUST trigger** ante cualquiera de:
- Operador pregunta sobre arquitectura, dependencias, acoplamiento, refactor de scope amplio
- Inicio de sesión en repo > 5k LOC sin índice (graphify-out/ ni cache codebase-memory-mcp)
- `code-reviewer` o `security-auditor` necesitan mapa de llamadas para auditar el diff

Skill ubicada en `skills/code-graph/`, slash manual `/code-graph`.
**Dual-engine**: graphify (multimodal, primario) + codebase-memory-mcp (solo código, fallback). El skill detecta cuál está disponible y elige según la pregunta.
Bootstrap: `tools/setup-code-graph.sh` instala ambos motores. Invocado por `batuta-project-hygiene mode=project-init|project-retrofit` y por `tools/setup-rules.sh --all`.
Política: multimodal habilitado por default cuando graphify está activo — proveedor LLM autorizado por contrato cliente. Excepción: proyectos con NDA estricto declaran `code-graph-engine: codebase-memory` en su CLAUDE.md proyecto para forzar fallback solo-código.
NEVER ejecutar `graphify claude install` (kill-switch v2.7). El registro del MCP server pasa por `claude mcp add` (escribe a `~/.claude.json`, fuera del kill-switch).
```

Adicionalmente, en la sección `## Engineering invariants from \`rules/\`` (cerca del final), añadir una línea mencionando que `setup-rules.sh --all` también dispara `setup-code-graph.sh`. Una sola pasada de bootstrap, ambos motores listos.

## 5. Cómo se hace automático

Tres mecanismos en cascada, sin requerir hook nuevo:

1. **Skill description matching** (capa nativa Claude Code) — la `description` del SKILL.md menciona explícitamente "architecture, onboarding, large-refactor questions". Claude la elige sin slash.
2. **Doctrina MUST-trigger en CLAUDE.md raíz** — la sección nueva (Capa 4) garantiza que el agente principal sabe que graphify es obligatorio en los 3 supuestos. Igual mecanismo que `research-first-dev` y `batuta-project-hygiene`.
3. **using-agent-skills meta-skill** — ya cargado por [hooks/session-start.sh](hooks/session-start.sh). Apenas el SKILL.md existe en `skills/graphify/`, entra al routing automático.

No hay hook nuevo. **No tocamos [hooks/hooks.json](hooks/hooks.json) ni [hooks/delegation-guard.sh](hooks/delegation-guard.sh).** Eso es deliberado: el plugin v2.7 ya decidió que la enforcement de workflows va por descripción + doctrina, no por hooks (ver [docs/adr/0006-trust-native-delegation.md](docs/adr/0006-trust-native-delegation.md)).

## 6. Out of scope

- **Adoptar Obsidian como KB durable**. Decisión del operador: mantener `notion-kb-workflow` actual sin tocar. Obsidian descartado en este slice (puede revisarse en futuro si la coexistencia ofrece valor concreto).
- **Bundlear `graphifyy` como binario dentro del plugin**. Lo instalamos vía `uv tool install` desde el script bootstrap, no copiamos binarios.
- **Usar `graphify claude install`**. Bloqueado por kill-switch — el skill propio cumple la misma función con gobernanza nuestra.
- **Hook PreToolUse propio sobre Glob/Grep**. Sería duplicar lo que graphify/codebase-memory-mcp intentan hacer; complica audit chain.
- **MCP server graphify auto-levantado en SessionStart**. Operador lo levanta a mano si lo quiere (`/code-graph --mcp ./src`). codebase-memory-mcp sí queda registrado siempre porque es nativamente MCP.
- **Migrar agentes existentes** (`code-reviewer`, `test-engineer`, `security-auditor`) para que consulten el grafo automáticamente. Es slice futuro — primero queremos confirmar que el skill solo agrega valor sin romper nada.
- **Promover a `~/.claude/`** (user-global). Empieza project-local en este plugin; promoción cuando se valide.
- **Crear agente especialista `code-cartographer`**. `agent-architect` lo puede generar on-demand más adelante si el patrón se repite.
- (Eliminado del out-of-scope tras research-first dispatch: codebase-memory-mcp **sí** soporta watch via `auto_index true`. Ambos motores cubren el modo `--watch`.)

## 7. Files to create or modify

**Nuevos**:
- [tools/setup-code-graph.sh](tools/setup-code-graph.sh) — bootstrap operador-side. Instala `graphifyy` (vía uv/pipx/pip) **y** registra `codebase-memory-mcp` (vía `claude mcp add`). Idempotente. Persiste estado en `~/.claude/code-graph-engines.json`.
- [tools/check-code-graph-engines.sh](tools/check-code-graph-engines.sh) — script de detección reusable. Lee `~/.claude/code-graph-engines.json` y reporta `graphify=OK|MISSING|BROKEN` / `codebase-memory-mcp=OK|MISSING|BROKEN`.
- [skills/code-graph/SKILL.md](skills/code-graph/SKILL.md) — skill auto-trigger con engine selection (estructura estándar Batuta, 4 modos: scan/watch/mcp/query, dual-engine).
- [.claude/commands/code-graph.md](.claude/commands/code-graph.md) — slash command operador-invocado con override `--engine`.
- [rules/integrations/code-graph-usage.md](rules/integrations/code-graph-usage.md) — rule importable.
- [rules/integrations/README.md](rules/integrations/README.md) — meta del directorio si no existe.
- [docs/adr/0007-code-graph-dual-engine.md](docs/adr/0007-code-graph-dual-engine.md) — rationale: por qué dual-engine en lugar de uno solo, alternativas descartadas (graphify-only vs codebase-memory-only vs ruta α/β/γ), kill-switch decision, consequences.
- [tests/v2.5-validators/07-code-graph-skill-shape.sh](tests/v2.5-validators/07-code-graph-skill-shape.sh) — validador estático que falla si:
  - Frontmatter del skill falta `name` o `description`.
  - El SKILL.md menciona literal `graphify claude install` como instrucción positiva (debe estar solo como Red Flag).
  - Falta sección Anti-Rationalizations o Red Flags o Verification.
  - El skill no documenta engine selection o falta el fallback path.

**Modificar**:
- [CLAUDE.md](CLAUDE.md) — añadir sección `### code-graph (auto + manual, dual-engine)` en `## Mandatory Skills for Batuta Projects` y nota sobre `setup-code-graph.sh` en la sección de bootstrap.
- [tools/setup-rules.sh](tools/setup-rules.sh) — al final del flag `--all`, invocar `bash "$(dirname "$0")/setup-code-graph.sh"` para que un solo bootstrap deje ambos motores listos.
- [skills/batuta-project-hygiene/SKILL.md](skills/batuta-project-hygiene/SKILL.md) — añadir invocación de `setup-code-graph.sh` en `mode=project-init` (proyectos nuevos) y `mode=project-retrofit` (proyectos antiguos). Ambos modos ya invocan `setup-rules.sh --all`, así que basta con que ese script propague.
- [tests/v2.5-validators/run.sh](tests/v2.5-validators/run.sh) — registrar el validador 07.

**No modificar**:
- [hooks/hooks.json](hooks/hooks.json), [hooks/delegation-guard.sh](hooks/delegation-guard.sh) — kill-switch intacto.
- [agents/](agents/) — la audit chain queda igual; consulta del grafo es slice futuro.
- [skills/notion-kb-workflow/SKILL.md](skills/notion-kb-workflow/SKILL.md) — Notion-KB queda exactamente como está (Obsidian descartado).

## 8. Verification (E2E)

Probar contra un repo de prueba (sugerido: clonar uno de los proyectos cliente conocido como Mistral o Aliqua a un sandbox temporal). Estamos en Windows 11.

0. **Bootstrap fresh** — sandbox sin nada instalado. Ejecutar `bash tools/setup-code-graph.sh`. Verificar exit 0 y que `~/.claude/code-graph-engines.json` reporta el estado real de cada motor. Re-ejecutar: idempotente.
1. **Sin engines** — sabotear ambos (`uv tool uninstall graphifyy` + `claude mcp remove codebase-memory`). Abrir Claude Code y preguntar: "explicame la arquitectura". **Esperado**: skill detecta ambos faltantes, emite bloque `bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh`, **no procede**. Verificar `.claude/settings.json` intacto (`git diff .claude/`).
2. **Solo codebase-memory disponible (escenario Win11 con graphify roto)** — instalar solo codebase-memory-mcp; `graphifyy` instalado pero `graphify --version` falla por [#378](https://github.com/safishamsi/graphify/issues/378). El bootstrap debe marcar `graphify=BROKEN`. Preguntar arquitectura: skill cae a codebase-memory-mcp, responde con `[via codebase-memory-mcp]`. Esto es **el camino crítico** dado el estado actual de graphify en Windows.
3. **Solo graphify disponible (escenario Mac/Linux)** — sandbox sin Node.js o con MCP server desregistrado. Skill usa graphify y responde con `[via graphify]` y `graphify-out/GRAPH_REPORT.md` existente.
4. **Ambos disponibles + pregunta multimodal** — repo con PDFs en `docs/`. Preguntar "qué dice el RFC sobre la arquitectura de payments". Skill prefiere graphify (multimodal), responde con `[via graphify]`.
5. **Ambos disponibles + pregunta solo-código** — preguntar "dónde se llama la función `process_payment`". Skill prefiere codebase-memory-mcp (más rápido para call graph), responde con `[via codebase-memory-mcp]`.
6. **Override explícito** — `/code-graph --engine graphify` y `/code-graph --engine codebase-memory`. Cada uno respeta el flag aunque la heurística diría otra cosa.
7. **Stale detection** — borrar `graphify-out/` artificialmente, `touch -d "25 hours ago"` sobre el reporte. Re-preguntar arquitectura: skill detecta staleness y propone re-scan.
8. **Kill-switch respetado** — `cat hooks/delegation-guard.sh | grep settings` confirma kill-switch intacto. Verificar que en ningún paso de los anteriores se modificó `.claude/settings.json` ni `.claude/hooks/`. Confirmar que `~/.claude.json` sí fue modificado por `claude mcp add` (esperado, fuera del kill-switch).
9. **Audit chain limpio** — el diff completo (bootstrap + skill + comando + rule + CLAUDE.md + ADR + validador) pasa `test-engineer` → `code-reviewer` → `security-auditor` con `APPROVED`.
10. **Validador 07** — `bash tests/v2.5-validators/07-code-graph-skill-shape.sh` exit 0.
11. **Rule import** — desde un proyecto consumidor: `bash tools/setup-rules.sh --rule integrations/code-graph-usage` + `@.claude/rules/code-graph-usage.md` en su CLAUDE.md. Confirmar que la rule se carga al iniciar sesión ahí.
12. **Retrofit en proyecto antiguo** — repo viejo sin nada instalado. Invocar `batuta-project-hygiene mode=project-retrofit`. Esperado: el flujo de retrofit corre `setup-rules.sh --all` que a su vez dispara `setup-code-graph.sh`. Al finalizar, ambos motores quedan en estado `OK` (en Mac/Linux) o `graphify=BROKEN, codebase-memory=OK` (en Windows hasta que graphify resuelva [#378](https://github.com/safishamsi/graphify/issues/378)).
13. **Bootstrap unificado** — repo nuevo sin CLAUDE.md. Operador inicia sesión, `batuta-project-hygiene mode=project-init` se dispara automáticamente, propaga el bootstrap.

## 9. Tradeoffs (resumen ejecutable)

**Beneficios**
- 30–99× menos tokens en consultas arquitectura sobre repos > 10k LOC (graphify reporta 70×, codebase-memory-mcp reporta 99× en su benchmark Linux kernel — verificar en sandbox real durante implementación).
- Onboarding de agentes y humanos a clientes nuevos en minutos.
- Audit chain potencialmente más fuerte si en futuro slice los gates consultan el grafo.
- Multimodal cuando graphify funciona: cubre PDFs de RFCs, screenshots, diagramas.
- **Resiliencia dual**: si graphify cae (autor único `safishamsi`, bus factor 1, [#378](https://github.com/safishamsi/graphify/issues/378) en Windows), codebase-memory-mcp toma el relevo sin que el operador note. Reduce el riesgo de quedar sin grafo.
- Cero impacto en plugin v2.7 (kill-switch intacto, hooks intactos).

**Costos**
- Superficie de mantenimiento dual: dos motores distintos, dos APIs distintas, dos paths de install. Mitigado parcialmente porque ambos son externos (no los mantenemos), solo orquestamos.
- Bootstrap del plugin ahora instala dos cosas — añade ~60s la primera vez (descarga graphifyy + registro MCP). Re-ejecuciones idempotentes.
- Mantenimiento de versión: `setup-code-graph.sh --upgrade` debe invocarse periódicamente (mensual). Posible automatizar como parte de `setup-rules.sh --upgrade` en futuro slice.
- Una pasada multimodal con graphify cuesta tokens del provider (proporcional al volumen de docs / imágenes).
- `graphify-out/` puede pesar 10–100MB en repos grandes; el cache de codebase-memory-mcp también ocupa espacio. Toca `.gitignore` y disco local.
- Coordinación con audit chain queda diferida — gana hoy en consultas, no aún en gates.
- Engine selection puede equivocarse: si la heurística elige codebase-memory para una pregunta que tenía contenido multimodal, la respuesta será más pobre. Mitigación: el operador override con `--engine graphify`.
- Si tanto Astral (uv) como npm caen, el bootstrap falla. Mitigación: script falla soft (warning) y reporta cuál motor sí quedó funcional.

**Riesgos identificados y mitigados**
- *Choque kill-switch v2.7*: NO usamos `graphify claude install`. Skill explícitamente lo prohíbe; bootstrap solo toca `$PATH` del operador y `~/.claude.json` (fuera del kill-switch).
- *Graphify roto en Windows*: el operador trabaja en Win11 y graphify tiene 3 issues bloqueantes abiertos. Mitigación: el bootstrap detecta y marca `graphify=BROKEN`, codebase-memory-mcp toma el relevo automáticamente.
- *Bus factor 1 de graphify (autor único)*: si el proyecto se abandona, codebase-memory-mcp (org backing por DeusData) sigue funcionando. El skill no asume que graphify exista.
- *Leak de código fuente al LLM*: graphify procesa código solo localmente vía tree-sitter; codebase-memory-mcp ídem. Documentado como invariante.
- *Operador olvida instalar*: bootstrap del plugin lo hace automático; retrofit cubre proyectos antiguos. Step 0 del skill es solo red de seguridad.
- *Dos plugins compitiendo por hooks PreToolUse*: no integramos el hook de graphify ni hook propio. Coexistencia limpia.
- *Output sensible commiteado por accidente*: rule + slash command añaden las entradas a `.gitignore` automáticamente.

**Riesgos abiertos**
- Que el README oficial de codebase-memory-mcp cambie su comando de install entre la planeación y la implementación. Mitigación: el bootstrap script lee el comando del README al instalar, con fallback al valor congelado en una variable.
- Que la API de tools del MCP server (nombres exactos `index_codebase`, `search_symbol`, etc.) sea distinta a la documentada por el agente investigador. Mitigación: verificar contra el código fuente en el step de implementación, no asumir.

**Riesgos abiertos**
- Performance de Leiden clustering en repos > 50k funciones — sin datos propios todavía.
- Compatibilidad de la versión `graphifyy@0.5.4` con repos en lenguajes menos comunes (Elixir, Zig, Nim) — no probado.
- Estabilidad del autor (mantenedor único, no organizacional) — riesgo de abandono. Mitigación: tracker en backlog para chequear cada 3 meses.

## 10. Open questions (defaults propuestos, confirmar al implementar)

- **Threshold de staleness**: default 24h. Parametrizable vía rule en futuro.
- **Versión mínima de motores**: graphifyy `>= 0.5.4`, codebase-memory-mcp `>= 0.6.0`. Documentar override en rule.
- **Heurística de engine selection**: la versión inicial es simple (multimodal → graphify; solo código → codebase-memory). ¿Mejorarla con señales del prompt (NLP)? Diferido a iteración 2.
- **Heurística de fallback en pregunta multimodal con graphify roto**: si el operador pregunta sobre un PDF y graphify está `BROKEN`, ¿caer a codebase-memory-mcp con caveat ("no puedo procesar PDFs, solo código") o pedir bootstrap re-run? Default: caveat.
- **Promoción a user-global**: cuándo. Propuesta: cuando 2 proyectos cliente lo hayan usado en producción al menos 1 mes y el ADR-0007 cierre con éxito.
- **Audit chain integration**: ¿siguiente slice añade consulta al grafo en `code-reviewer` Step 0? Puede ser v2.9.
- **Upgrades automáticos del CLI**: ¿añadir `--upgrade` al `setup-code-graph.sh` y dispararlo cada N días vía SessionStart? Default: no, operador-side manual.
- **Nombre del skill / comando**: confirmar `code-graph` (genérico) vs `graphify` (reconocible pero atado a un motor). Default elegido en el plan: `code-graph`.
- **Monitoreo del proyecto graphify**: ¿abrir un task de observabilidad mensual para chequear si [#378](https://github.com/safishamsi/graphify/issues/378) y [#244](https://github.com/safishamsi/graphify/issues/244) cierran? Default: sí, agregar a backlog.

---

**Entry point para próxima sesión** (después de aprobar y mergear este plan): `docs/plans/active/2026-04-29-code-graph-dual-engine.md @ task-0` (Capa 0 — escribir `tools/setup-code-graph.sh` y verificar el comando real de install de codebase-memory-mcp contra su README).
