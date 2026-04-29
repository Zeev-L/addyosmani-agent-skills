# Changelog

Versions of the `batuta-agent-skills` plugin (fork of `addyosmani/agent-skills`). Dates are operator-time; PR numbers reference [`jota-batuta/batuta-agent-skills`](https://github.com/jota-batuta/batuta-agent-skills) unless noted.

The roadmap with rationale per slice lives in [`docs/PRD.md`](docs/PRD.md) § Roadmap (rolling). Architectural decisions live in [`docs/adr/`](docs/adr/). This file is the chronological summary.

## [3.3.0] — 2026-04-29 (this PR)

Runtime E2E in GitHub Actions CI. The harness is now stable green per v3.2 (4/4 PASS), so this slice consumes that closure: every PR runs static validators, and (when the operator has set the `ANTHROPIC_API_KEY` repository secret) drives the E2E harness against `claude --print --model sonnet`.

- New `.github/workflows/ci.yml` with two jobs:
  - `static-validators` — runs `bash tests/v2.5-validators/run.sh` (9 cases). Always runs. ~seconds, no API tokens.
  - `e2e` — runs `bash tests/e2e/run.sh` after `static-validators` passes. Gated on the `ANTHROPIC_API_KEY` repository secret via a probe step that emits a `::warning::` and exits clean if the secret is missing. Fresh forks of the plugin do NOT see a red CI before the maintainer wires up the key.
- Concurrency configured so a new commit on the same branch cancels in-flight runs (saves tokens during fast iteration).
- `permissions: contents: read` set explicitly (least-privilege; the workflow does not need write access to anything).
- `tests/e2e/README.md` § "Running the harness in CI (v3.3+)" — documents the workflow, operator setup (one-time secret addition), cost per PR (~3 sonnet rounds), and three throttling options if cost becomes a concern.
- `plugin.json` 3.2.0 → 3.3.0.

The candidate list in PRD § Roadmap (rolling) shifts: runtime-CI moves from "Unblocked" to shipped; `--signer-workflow` binding stays as the next paranoid hardening; interactive-session harness deferred per ADR-0009 § Alt δ.

## [3.2.0] — 2026-04-29 (PR [#19](https://github.com/jota-batuta/agent-skills/pull/19), commit `63fd520`)

Closes the v3.0 E2E methodology question that scenarios 02 and 04 surfaced. Both scenarios now PASS against `HEAD` of the repo (4/4 instead of 2/4).

- **`--plugin-dir "$REPO_ROOT"`** added to scenarios 02, 03, 04. Loads the local checkout instead of the marketplace cache (which can lag releases by N versions and was at `2.7.0` while v3.x shipped). The harness now tests `HEAD`, not stale cache.
- **Scenario 04 verifier relaxed** to a case-insensitive `NOT[-\s]+APPLICABLE` regex. Sonnet in `--print` mode reproduces the *semantics* of the Step 0 NOT-APPLICABLE contract but often paraphrases the exact wording. The literal-string contract is still enforced by static validator `01-auditor-not-applicable.sh` against the agent prompt files, and observed in interactive subagent invocations during the actual audit chain.
- **`--agent code-reviewer`** added to scenario 04. Activates the agent's prompt as the session's primary system prompt so the contract context is in front of the model.
- **`tests/e2e/README.md` § Methodology** documents the invocation pattern (`--print + --plugin-dir + --agent`), the explicit limitation (`--print` does not exercise the audit chain end-to-end), and the boundary with the static validator suite.
- **ADR-0009** documents the architectural decision and the 4 rejected alternatives (cache pre-update, prompt-engineering for literal strings, dropping the scenarios, interactive harness).
- **PRD roadmap**: v3.2 added as shipped; v3.2+ candidates restructured. The runtime-CI candidate is unblocked now that E2E is stable green.
- **Plugin version 3.1.0 → 3.2.0.**

E2E result on the merge tree: 4/4 PASS, 0 SKIP, 0 FAIL.

ADR added: docs/adr/0009-e2e-print-mode-methodology.md.

## [3.1.0] — 2026-04-29 (PR [#17](https://github.com/jota-batuta/batuta-agent-skills/pull/17), commit `86a34b4`)

Cryptographic provenance verification on top of v2.9's SHA-256 + v2.8's release pinning. The third gate of the codebase-memory-mcp install pipeline. PRD candidates list pruned (Colombian specialists removed per operator decision; PyPI hash-pinning and runtime CI postponed with documented rationale).

- **`gh attestation verify`** added to `tools/setup-code-graph.sh` immediately after the SHA-256 check. Verifies that the binary's GitHub Actions provenance attestation chains back to a workflow run on `DeusData/codebase-memory-mcp`. Defense in depth against a maintainer-account compromise that re-uploads BOTH the asset and `checksums.txt` (the case SHA-256-alone cannot detect).
- **Graceful-degrade**: if `gh` CLI is missing or `gh auth status` fails, bootstrap warns and continues with SHA-256-only. A failed attestation (non-zero exit) is hard-abort — `CBM_STATUS=BROKEN`. The first two are absence-of-evidence; the third is positive evidence of tampering.
- **Asymmetric trust posture refined** in ADR-0007 (third amendment). codebase-memory-mcp now has 3 gates (release pin + SHA-256 + attestation); graphifyy still has 1 (version pin only). The asymmetry remains intentional.
- **Validator 07 extended**: enforces presence of `gh attestation verify`, `gh auth status` probe, hard-abort path with `CBM_STATUS=BROKEN`, and both graceful-degrade warnings (gh missing / gh unauthenticated).
- **PRD roadmap pruned**: Colombian specialists candidate removed (operator decision). PyPI hash-pinning postponed with reference to upstream `uv` issue. Runtime E2E in CI postponed pending `claude --print` plugin-loading investigation. New candidate added: investigate `claude --print` plugin loading (the methodology question E2E scenarios 02 and 04 surfaced in v3.0).
- **Plugin version 3.0.0 → 3.1.0.**

ADR amended: [0007 § Update 2026-04-29 — v3.1 attestation closure](docs/adr/0007-code-graph-dual-engine.md). Validators: 07 extended.

## [3.0.0] — 2026-04-29 (PR [#15](https://github.com/jota-batuta/batuta-agent-skills/pull/15), commit `812a580`)

Closes the v2.8 open question (audit chain consults the code-graph), the v2.9 audit follow-ups, and adds an end-to-end test harness that drives `claude --model sonnet` against sandbox repositories. Plugin version catches up after v2.7→v2.8→v2.9 shipped without bumps.

- **Audit-chain × code-graph integration**. `code-reviewer` and `security-auditor` gain Step 0.5 (between Step 0 NOT-APPLICABLE and the existing review framework): if a code-graph engine is available, enumerate the **blast-radius set** (callers/callees/symbol references for the diff) or **attack-surface set** (call paths from the diff to trust-boundary sinks) and read those files in addition to the diff hunks. Non-blocking: graceful-degrade to v2.9 behavior when no engine is available. `test-engineer` is intentionally NOT modified — its scope is bounded by test files, not call paths. ADR-0008 documents the rationale and rejected alternatives. Static validator 09 enforces the prompt structure.
- **v2.9 audit follow-ups closed**. Linux tarball extraction now uses a dedicated `extracted/` subdir for symmetry with the Windows path; `tar -xzf` invoked with `--no-same-owner --no-same-permissions` for legacy-tar hardening; new behavior tests (`08-code-graph-helpers-behavior.sh`) source the bootstrap with `SOURCING_FOR_TESTS=1` and unit-test `detect_platform_tag()` (8 fixture pairs) and `sha256_of()` (consistency across `sha256sum`/`shasum`/`certutil` backends).
- **E2E test harness**. New `tests/e2e/` with `run.sh` orchestrator and 4 scenarios driving `claude --print --model sonnet` against sandbox repositories: engines-state roundtrip (no CLI required), skill-discovery, research-first citation, and audit-chain NOT APPLICABLE on clean tree. Skipped scenarios (missing CLI/auth/network) report 77, not failure. `--keep` flag preserves sandboxes for inspection. Why sonnet: the operator default-runs the medium model for cost; the plugin must be useful with sonnet, not only with opus.
- **Plugin version 3.0.0**. v2.7→v2.8→v2.9 shipped without bumping `plugin.json`; this slice catches up. Description updated to mention the dual-engine code-graph layer.

ADRs: [0008](docs/adr/0008-audit-chain-code-graph-integration.md). New validators: 08, 09. PR (this one).

## [2.9.0] — 2026-04-29 (PR [#14](https://github.com/jota-batuta/batuta-agent-skills/pull/14), commit `c3ef89c`)

Closes M1 from the v2.8 GATE 3 security audit. Replaces mutable-branch `install.sh` fetches with release-pinned binary downloads + SHA-256 verification against the release's signed `checksums.txt`.

- **Pinned codebase-memory-mcp install**. Skips `install.sh` entirely; downloads the platform-specific binary from `releases/download/v0.6.0/`, verifies SHA-256, extracts in-process to `~/.local/bin/`. Mismatch hard-aborts with `CBM_STATUS=BROKEN`.
- **Pinned graphifyy version**. Install command uses `graphifyy==0.5.4`. Hash-pinning at PyPI deferred (uv/pipx do not expose `--require-hashes` ergonomically).
- **Asymmetric trust posture documented** in ADR-0007 (amended). codebase-memory-mcp gets release-asset + signed-checksums verification; graphifyy gets PyPI version pin only. The asymmetry reflects different distribution channels.
- **New validator 07 checks**: `GRAPHIFY_PIN` and `CBM_PIN_TAG` declared, version pin in install command, no fetch from `main` branch, `checksums.txt` reference, SHA-256 verification logic, mismatch sets BROKEN.

Plugin version: did NOT bump (caught up in v3.0.0).

## [2.8.0] — 2026-04-29 (PR [#13](https://github.com/jota-batuta/batuta-agent-skills/pull/13) and PR [#12](https://github.com/jota-batuta/batuta-agent-skills/pull/12), commit `f56bfc9`)

Adds a **dual-engine code knowledge graph layer** so architecture/onboarding/refactor questions consult a persisted graph instead of re-reading the repo.

- **graphify** ([safishamsi/graphify@0.5.4](https://github.com/safishamsi/graphify)) — multimodal (code + docs + PDFs + images), primary engine.
- **codebase-memory-mcp** ([DeusData/codebase-memory-mcp@0.6.0](https://github.com/DeusData/codebase-memory-mcp)) — code-only MCP server, fallback engine. Critical on Windows where graphify has 3 open blocking install issues.
- Skill `code-graph` (auto-trigger) governs which engine runs based on cached state in `~/.claude/code-graph-engines.json`. Bootstrap is operator-side via `tools/setup-code-graph.sh`, chained from `tools/setup-rules.sh --all`. Slash command `/code-graph` for explicit operator control. Rule `rules/integrations/code-graph-usage.md` declares the contract.
- Kill-switch v2.7 intact: nothing writes to `.claude/settings*.json`; `graphify claude install` is forbidden across skill, slash, rule, and validator.
- ADR-0007 documents the dual-engine rationale and rejected alternatives (wait, switch entirely, third engine, run upstream auto-installer).
- New validator 07 enforces the SKILL.md / rule / setup-script invariants.

Plugin version: did NOT bump (caught up in v3.0.0).

## [2.7.0] — 2026-04-27 (PR [#11](https://github.com/jota-batuta/batuta-agent-skills/pull/11), commit `605d8c0`)

Realignment with Anthropic's Claude Code design pattern: PreToolUse hooks for hard constraints (kill-switches), native judgment for workflow.

- Path-whitelist removed from `hooks/delegation-guard.sh`; kept only kill-switch surfaces (`.claude/settings*.json`, `.claude/hooks/*`, `.claude/agents/*`, `.env`, `.envrc`, `secrets/*`).
- Audit chain (`test-engineer → code-reviewer → security-auditor`) is the post-edit gate for all diffs regardless of authorship.
- Subagent bypass via `agent_id` + dual-guard on `event_name`.
- ADR-0006 documents the decision and the N=2 evidence (BBVA Corriente debug friction + plugin repo dogfood).

## [2.6.0] — 2026-04-27 (PR [#10](https://github.com/jota-batuta/batuta-agent-skills/pull/10), commit `135086f`)

Closes the meta-agent leak plus operator-invoked plan-mode persistence.

- `agent-architect` Phase 5 bakes v2.5 enforcement patterns into every generated specialist (research-first Step 2, audit-scope Step 0, dual-path build-log).
- New `/save-plan <slug>` slash command at `.claude/commands/save-plan.md`. ADR-0005 explains why a slash command instead of a runtime hook.
- New `tests/v2.5-validators/` static contract validator suite (cases 01–05).

## [2.5.0] — 2026-04-27 (PR [#9](https://github.com/jota-batuta/batuta-agent-skills/pull/9), commit `30f8dc2`)

Closes two audit-chain enforcement gaps observed in real use.

- Audit chain Step 0 NOT-APPLICABLE on clean working tree — defends against the chain firing during exploration / planning / ad-hoc queries.
- Research-first Step 2 wired into `implementer` (mandatory) and `implementer-haiku` (conditional) — no more "I already know that library" skipping the lookup.
- `batuta-agent-authoring` verification rules 5–6 enforce both wirings on new agent definitions.

## [2.4.0] — 2026-04-27 (PR [#7](https://github.com/jota-batuta/batuta-agent-skills/pull/7))

Closes the phantom-SHA / stale cache failure mode.

- `batuta-project-hygiene` gains `mode=project-retrofit` — additively completes missing doc skeleton on projects with pre-existing CLAUDE.md.
- `implementer` and `implementer-haiku` gain Step 0 pre-flight that BLOCKERs on missing `docs/plans/active/`, refusing to improvise.
- User-global CLAUDE.md gains explicit reminder to persist plan-mode plans to `<project>/docs/plans/active/`.

## [2.3.0] — 2026-04-26 (PR [#5](https://github.com/jota-batuta/batuta-agent-skills/pull/5))

User-level memory backup in `user-settings/`. Architectural maturity inflection — post-v2 the plugin ships a complete delegation system + audit chain + doc graph + rules layer + memory persistence.

## [1.3.0] — 2026-04-26 (PR [#4](https://github.com/jota-batuta/batuta-agent-skills/pull/4))

`rules/` layer: declarative engineering invariants library importable à la carte by consumer projects via `@<path>` symlinks through `tools/setup-rules.sh`.

## [1.2.0] — 2026-04-26

E2E test harness for the delegation chain (3 calibrated prompts; documented in `docs/sessions/2026-04-26-rule-zero-implementation.md`). Predecessor of the v3.0 `tests/e2e/` harness.

## [1.1.0] — 2026-04-26 (PR [#3](https://github.com/jota-batuta/batuta-agent-skills/pull/3))

Project-wide documentation scaffolding: PRD, SPEC, ADRs, session-handoff convention, cross-tool portability.

## [1.0.0] — 2026-04-26 (PR [#2](https://github.com/jota-batuta/batuta-agent-skills/pull/2))

Rule #0 enforcement, 5 base agents (`implementer`, `implementer-haiku`, `code-reviewer`, `test-engineer`, `security-auditor`), `agent-architect` meta-agent, plugin-level PreToolUse hook, delegation rule docs.

---

[3.3.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v2.7.0...v3.0.0
[2.7.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v1.3.0...v2.3.0
[1.3.0]: https://github.com/jota-batuta/batuta-agent-skills/compare/v1.2.0...v1.3.0
[1.0.0]: https://github.com/jota-batuta/batuta-agent-skills/releases/tag/v1.0.0
