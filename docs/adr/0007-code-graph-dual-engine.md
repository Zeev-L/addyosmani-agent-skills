# ADR 0007 — Code knowledge graph as a dual-engine layer (graphify + codebase-memory-mcp)

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** jota-batuta

## Context

Architecture questions over a non-trivial codebase ("what does this repo do?", "where is X called?", "what depends on Y?", "find module cycles") are answered today by Claude doing rounds of `Glob` + `Grep` + `Read` over dozens of files. That is the most expensive correct answer: it burns tokens, raises latency, and the agent's reasoning suffers from window fatigue. Persisting a code graph and consulting it is a strictly cheaper baseline.

Two viable upstream tools exist in the AI-coding ecosystem:

- **graphify** ([github.com/safishamsi/graphify](https://github.com/safishamsi/graphify)) — Python CLI, MIT, v0.5.4 as of 2026-04-29, multimodal (code + docs + PDFs + images + audio). Single maintainer (`safishamsi`), 119 PRs unmerged, three open issues blocking install on Windows ([#378](https://github.com/safishamsi/graphify/issues/378), [#244](https://github.com/safishamsi/graphify/issues/244), [#501](https://github.com/safishamsi/graphify/issues/501)).
- **codebase-memory-mcp** ([github.com/DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)) — native C MCP server, MIT, v0.6.0 as of 2026-04-06, 1.9k⭐, code-only, org-backed (DeusData), zero dependencies, indexes Linux kernel in ~3 minutes.

Three constraints from the operator shape the decision:

1. The operator works on Windows 11 — graphify is currently broken there.
2. Some client projects hold strict NDAs; multimodal extraction sends docs/images to the LLM provider, which is acceptable for some clients and not others.
3. The operator does not want to remember per-project install steps; bootstrap must be automatic.

A fourth constraint comes from the plugin: graphify ships an upstream `graphify claude install` command that injects a PreToolUse hook into `.claude/settings.json`. That path is on the v2.7 kill-switch ([ADR-0006](0006-trust-native-delegation.md), [`hooks/delegation-guard.sh`](../../hooks/delegation-guard.sh)). The upstream auto-integration cannot be used.

## Decision

Ship a **dual-engine code-graph layer**:

- **graphify** is the primary engine when functional and the question benefits from multimodal coverage.
- **codebase-memory-mcp** is the fallback engine — used when graphify is unavailable (Windows install issues), when the question is pure code, or when a project explicitly opts into code-only via `code-graph-engine: codebase-memory` in its CLAUDE.md.

Concrete components delivered in this slice (v2.8):

- [`tools/setup-code-graph.sh`](../../tools/setup-code-graph.sh) — operator-side installer for both engines. Probes uv > pipx > pip for graphify; runs the official codebase-memory-mcp installer with `--skip-config`; registers it via `claude mcp add --scope user --transport stdio` (writes to `~/.claude.json` — outside the kill-switch). Persists status to `~/.claude/code-graph-engines.json`.
- [`tools/check-code-graph-engines.sh`](../../tools/check-code-graph-engines.sh) — read-only state lookup used by the skill and slash.
- [`skills/code-graph/SKILL.md`](../../skills/code-graph/SKILL.md) — auto-trigger skill with engine selection (Step 0 reads cached state; preference rules: multimodal hint → graphify, pure code → codebase-memory-mcp, override via `--engine`).
- [`.claude/commands/code-graph.md`](../../.claude/commands/code-graph.md) — operator-invoked slash for `--scan`, `--watch`, `--mcp`, `--query`, `--engine` modes.
- [`rules/integrations/code-graph-usage.md`](../../rules/integrations/code-graph-usage.md) — declarative contract for consumer projects.
- Wiring in [`tools/setup-rules.sh`](../../tools/setup-rules.sh), [`skills/batuta-project-hygiene/SKILL.md`](../../skills/batuta-project-hygiene/SKILL.md), and [`CLAUDE.md`](../../CLAUDE.md) so a single bootstrap (`setup-rules.sh --all`, already invoked by `project-init` and `project-retrofit`) installs both engines without an extra step.

## Alternatives considered

### Alt α — Wait for graphify to fix Windows; integrate graphify only

**Rejected.** Bus factor of 1 with 119 PRs unmerged and panic-driven release cadence (5 releases in 5 days, security SSRF fixes mid-stream) make a single-vendor bet uncomfortable for a plugin that aims to ship to client projects on tight timelines. The operator's day-to-day work is on Windows, where graphify is currently unusable. Waiting is not "wait one week" — it is "wait until 3 open Windows issues close on a single-maintainer project".

### Alt β — Switch to codebase-memory-mcp only; drop graphify

**Rejected.** Multimodal coverage (docs, PDFs, images, audio) is graphify's unique value. Some Batuta deliverables need this (RFC PDFs, architecture diagrams, transcribed call notes). Eliminating graphify removes a capability with no equivalent in any alternative we evaluated (codegraph, ast-grep, ctags, Sourcegraph Cody, Aider repo-map, Cursor codebase indexing — all code-only or organization-locked).

### Alt δ — Integrate graphify with a Windows shim that falls back to ast-grep or ctags

**Rejected.** That is a third engine to maintain, and ast-grep/ctags are not designed to expose graph queries to an LLM agent. We would be reinventing codebase-memory-mcp poorly. If we need a code-only fallback, use the one with org backing and 99% token-reduction benchmarks already published.

### Alt ε — Run `graphify claude install` from a setup script (operator-side bash, outside the hook)

**Rejected as primary mechanism, used as comparison point.** Letting the operator-side script invoke graphify's auto-installer would technically bypass the hook (the hook only fires on Claude tool calls). But the resulting `PreToolUse` hook in `.claude/settings.json` then governs Glob/Grep behavior at runtime in a way the plugin does not control — graphify upstream defines the policy (when to consult the graph, what to inject). That breaks the plugin's audit chain reasoning, since gates would receive context they did not request. We want the **policy** to live in our skill, not in graphify upstream's hook. So: use graphify as a CLI/MCP-server engine, never auto-install its hook.

## Consequences

### Positive

- **Resilience.** A single-vendor failure (graphify abandoned, install broken on a new OS) does not leave the operator without a code graph. codebase-memory-mcp is org-backed and stable.
- **Multimodal when available, code-only always.** The operator can extract value from PDFs and images on the platforms where graphify works, and never loses code-graph coverage on platforms where it doesn't.
- **Aligned with v2.7 kill-switch discipline.** Neither engine touches `.claude/settings*.json`. Bootstrap writes only to operator-side paths (`$PATH` install dir + `~/.claude.json` via `claude mcp add`).
- **No new hook.** Engine selection is doctrinal (the skill's Step 0), not enforced by a runtime hook. Consistent with [ADR-0006](0006-trust-native-delegation.md).
- **Single-bootstrap UX.** Operator runs `setup-rules.sh --all` once per machine (or lets `batuta-project-hygiene` run it). Both engines installed and registered. Subsequent projects pick up the existing install.

### Negative

- **Two upstreams to track.** Mantainability cost ~doubles compared to a single-engine slice. Mitigated by the fact that we maintain neither — we orchestrate both. Open question in the plan: monthly check on graphify [#378](https://github.com/safishamsi/graphify/issues/378), [#244](https://github.com/safishamsi/graphify/issues/244) to revisit promotion or demotion.
- **Engine-selection heuristic can mispick.** A multimodal question routed to codebase-memory-mcp produces a poorer answer (no PDF context). Mitigated by `--engine graphify` operator override and by the skill's Step 0 heuristic (PDFs/images in scope → prefer graphify).
- **Cache footprint x2.** `graphify-out/` and `~/.cache/codebase-memory-mcp/` both consume disk. Mitigated by `.gitignore` discipline (rule 5 in the integrations rule).

### Neutral

- **Audit chain integration deferred.** This slice only exposes the skill + slash to operator-driven flows. Wiring `code-reviewer` / `security-auditor` to consult the graph is a future slice (open question in the plan, candidate v2.9).
- **The `code-graph-engine: codebase-memory` escape-hatch in project CLAUDE.md** is documented in the rule but not yet honored by automation. The skill's Step 0 reads it manually. If escape-hatch usage becomes common, harden it via `check-code-graph-engines.sh` accepting a project override.

## What is intentionally NOT done

- We do **not** invoke `graphify claude install` from any script (operator-side or otherwise). The kill-switch motivation is to keep `.claude/settings.json` immutable from any plugin's auto-config flow, not just from Claude tool calls.
- We do **not** ship a wrapper that translates queries into engine-specific tool calls inside the plugin code. That dispatch lives in the skill and slash command (declarative); rewriting it as code would create another layer to maintain.
- We do **not** auto-update the engines on a schedule. Upgrades are operator-triggered via `setup-code-graph.sh --upgrade`. Open question in the plan: candidate for SessionStart auto-check in a future slice.

## References

- [github.com/safishamsi/graphify](https://github.com/safishamsi/graphify) (verified 2026-04-29, graphifyy@0.5.4) — primary engine source
- [github.com/DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) (verified 2026-04-29, codebase-memory-mcp@0.6.0) — fallback engine source
- [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp) (verified 2026-04-29) — `claude mcp add` semantics, scope persistence to `~/.claude.json`
- [`docs/adr/0006-trust-native-delegation.md`](0006-trust-native-delegation.md) — kill-switch scope; this ADR honors the same boundary
- [`docs/plans/active/2026-04-29-code-graph-dual-engine.md`](../plans/active/2026-04-29-code-graph-dual-engine.md) — the slice plan
- [`hooks/delegation-guard.sh`](../../hooks/delegation-guard.sh) — kill-switch enforcement (unchanged by this slice)
