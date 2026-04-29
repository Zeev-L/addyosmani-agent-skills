# Session journal — 2026-04-29 — v2.8 code-graph dual engine shipping

## Context

Entry point: operator request to integrate **graphify** ([safishamsi/graphify](https://github.com/safishamsi/graphify)) into the plugin's automated workflow. No active plan at session start. v2.7 was already in flight on `feat/trust-native-delegation` (commit `d383bd1`) but had not yet landed on main.

The session ran end-to-end through plan mode → slice implementation → audit chain → PR. Plan written at `~/.claude/plans/quiero-implementar-graphify-en-velvet-stardust.md`, persisted to `docs/plans/active/2026-04-29-code-graph-dual-engine.md` (now archived as part of this commit).

## Decisions

- **Dual-engine over single-engine** (Ruta γ): integrate **graphify** (multimodal, primary) **+ codebase-memory-mcp** (code-only, fallback). Driven by graphify's bus factor of 1, 119 unmerged PRs, and three open Windows-blocking install issues ([#378](https://github.com/safishamsi/graphify/issues/378), [#244](https://github.com/safishamsi/graphify/issues/244), [#501](https://github.com/safishamsi/graphify/issues/501)). codebase-memory-mcp is org-backed (DeusData), 1.9k⭐, MIT, indexes Linux kernel in ~3 min, but processes only code. The two are complementary; the skill's Step 0 picks based on availability and question shape (PDFs/images → graphify; pure code → codebase-memory-mcp). Operator override via `/code-graph --engine <name>`. Full rationale in [ADR-0007](../adr/0007-code-graph-dual-engine.md).

- **Skill-governed over `graphify claude install`** (Ruta β): the upstream auto-integration command writes to `.claude/settings.json`, which is on the v2.7 kill-switch ([ADR-0006](../adr/0006-trust-native-delegation.md)). We replicate the useful behavior (auto-trigger before architecture questions) via a Batuta-owned skill instead. Bonus: policy (when to run, what to read, NDA mode) lives in our skill, not in graphify upstream's hook — so we can honor `code-graph-engine: codebase-memory` opt-out per project without patching settings.json. ε-alternative (run `graphify claude install` from a bash bypass) was considered and rejected for the same policy-governance reason.

- **Auto-install via bootstrap, not BYO**: operator explicitly rejected manual install ("no puedo estar sujeto a recordar que esta herramienta existe en cada proyecto nuevo"). `tools/setup-code-graph.sh` chains from `tools/setup-rules.sh --all`, which is already invoked by `batuta-project-hygiene` `project-init` and `project-retrofit`. Single bootstrap, both engines configured.

- **Obsidian explicitly out of scope**. Considered as a Notion replacement for KB durable memory (graphify's `--obsidian` exporter would mesh well). Rejected: Notion MCP is official and mature; Obsidian MCP is community; moving the KB layer is its own decision and would mix concerns with the code-graph slice. `notion-kb-workflow` untouched.

- **PR base `feat/trust-native-delegation`, not `main`**. v2.7 had not yet merged; targeting main would have shown a 2200-line diff mixing v2.7 and v2.8 changes. Targeting the integration branch kept the slice diff atomic at ~1400 lines.

- **`.gitattributes` introduced** for `*.sh text eol=lf`. Discovered during Capa 0 commit when Git on Windows under `core.autocrlf=true` warned about CRLF conversion of new shell scripts. Without the rule, scripts checked out on Windows with Git Bash become unrunnable. Existing `.sh` files keep their current EOL until next edit; no global renormalize.

## Changes

### v2.8 (PR #12, merged as `49ae3b5` to `feat/trust-native-delegation`; pending PR to `main`)

- `tools/setup-code-graph.sh` — operator-side dual installer. uv > pipx > pip for `graphifyy`; official curl/PowerShell installer with `--skip-config` for codebase-memory-mcp; registers MCP server via `claude mcp add --scope user --transport stdio` (writes to `~/.claude.json`, outside kill-switch). Idempotent. Persists per-engine status to `~/.claude/code-graph-engines.json`.
- `tools/check-code-graph-engines.sh` — read-only state lookup. `--json`, `--field`, summary modes.
- `skills/code-graph/SKILL.md` — auto-trigger skill. Step 0 reads cached state and dispatches to whichever engine is OK + best-suited. Four modes: `--scan`, `--watch`, `--mcp`, `--query`. Forbids `graphify claude install` in Red Flags. Cites engine name (`[via graphify]` / `[via codebase-memory-mcp]`) in every architecture answer.
- `.claude/commands/code-graph.md` — operator-invoked slash command with `--engine` override and the same four modes.
- `rules/integrations/code-graph-usage.md` — declarative contract for consumer projects. New `rules/integrations/` category (added to `rules/README.md` layout + index). Documents the kill-switch invariant and citation discipline.
- `CLAUDE.md` — new `### code-graph (auto + manual, dual-engine)` section under Mandatory Skills, between research-first-dev and notion-kb-workflow.
- `tools/setup-rules.sh` — chains into `setup-code-graph.sh` on `--all` mode.
- `skills/batuta-project-hygiene/SKILL.md` — documents the chained bootstrap behavior in step 4b and project-retrofit step 2.
- `docs/adr/0007-code-graph-dual-engine.md` — decision record (3 alternatives explicitly rejected, kill-switch reasoning, deferred follow-ups).
- `tests/v2.5-validators/07-code-graph-skill-shape.sh` — new validator (26 checks). Confirms frontmatter, required sections, prohibitive context for `graphify claude install`, kill-switch absence in setup script, `--skip-config` propagation, slash frontmatter. Registered in `run.sh` as case 7.
- `.gitattributes` — `*.sh text eol=lf` (one-line addition).

### Audit chain results

- **GATE 1 — test-engineer**: APPROVED. Validators 7/7 PASS. Identified two non-blocking hardening opportunities for v2.9 (semver_ge edge cases on pre-release tags; explicit unit test for engine-selection heuristic).
- **GATE 2 — code-reviewer**: CHANGES REQUESTED → resolved in `acf4ca7`. MUST-FIX was the new bootstrap scripts committed at mode `100644` instead of `100755` (operators outside Git Bash would get permission-denied). Fix: `git update-index --chmod=+x tools/setup-code-graph.sh tools/check-code-graph-engines.sh`. SHOULD-FIX was streaming `curl … | bash` directly on Linux/Mac; replaced with download-to-tempfile-then-exec mirroring the Windows path. Trap-cleanup on `RETURN`.
- **GATE 3 — security-auditor**: APPROVED with one MEDIUM follow-up (M1 — pin install.sh by SHA + checksum instead of `main` HEAD). Documented as v2.9 hardening, explicitly non-blocking. Confirmed kill-switch contract intact: zero writes to `.claude/settings*.json` across all 5 commits.

## Plan-mode workflow notes

- The slice exercised the full plan-mode → save-plan → implementation → audit chain → PR cycle without manual intervention beyond the operator's three pivot decisions (γ/β engine strategy, Obsidian out of scope, PR base = `feat/trust-native-delegation`).
- The plan canonical doc was updated mid-implementation when research-first dispatch surfaced corrections (codebase-memory-mcp is C native, not Node.js; tool names are `index_repository` / `search_graph` / `trace_call_path`, not `index_codebase` / `search_symbol`). The plan in `docs/plans/active/` was the source of truth, not the original `~/.claude/plans/` snapshot.
- `set -uo pipefail` (no `-e`) on the bootstrap scripts is intentional and now annotated with a comment block explaining why (per-engine status tracking; `-e` would defeat the fallback architecture). Future maintainers reading the script will not "fix" it back.

## Next

Next session entry point: open PR `feat/trust-native-delegation` → `main` to land v2.8 on main, then plan **v2.9 supply-chain hardening** (M1 from GATE 3: pin `install.sh` of codebase-memory-mcp to a release tag + verify SHA-256 before exec).

The v2.9 slice is small in scope (`tools/setup-code-graph.sh` Bloque 2 + ADR amendment + validator extension). Open question for that slice: do we keep `main` as a movable target during graphify-only platforms (since we cannot hash-pin a script we depend on through PyPI), or only pin the codebase-memory-mcp installer and document the asymmetric trust posture?
