# ADR 0007 — Code knowledge graph as a dual-engine layer (graphify + codebase-memory-mcp)

**Status:** Accepted (amended 2026-04-29 with M1 closure; amended 2026-04-29 with v3.1 attestation closure)
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

## Update 2026-04-29 — M1 closure: supply-chain hardening

GATE 3 of v2.8's audit chain flagged one MEDIUM finding: the bootstrap fetched `install.sh` from `raw.githubusercontent.com/.../main/` without integrity pinning. This amendment documents the v2.9 fix.

### What changed

- **codebase-memory-mcp**: instead of fetching `install.sh` from a mutable branch and executing it, [`tools/setup-code-graph.sh`](../../tools/setup-code-graph.sh) now downloads the platform-specific binary tarball directly from the pinned GitHub Release (`v0.6.0`) and verifies it against the release's `checksums.txt`. `install.sh` is no longer a trust surface for this engine. The release is immutable, attached SHA-256 manifests are signed via GitHub Actions provenance attestation, and the binary is extracted in-process to `~/.local/bin/`. MCP registration via `claude mcp add --scope user` is unchanged.
- **graphify**: pinned to PyPI version `==0.5.4` in the install command. Hash-pinning at the PyPI layer is intentionally not done — `uv tool` and `pipx` do not expose `--require-hashes` ergonomically, and adding a separate `requirements.txt` is more surface than the value warrants. PyPI's TLS + signed-distribution chain is the implicit trust anchor.

### Asymmetric trust posture (intentional)

The two engines now have different trust models:

| Engine | Pinning | Verification | Trust anchor |
|---|---|---|---|
| codebase-memory-mcp | release tag `v0.6.0` | SHA-256 against signed `checksums.txt` from same release | GitHub Releases immutability + signed checksums.txt |
| graphifyy | PyPI version `==0.5.4` | none beyond TLS | PyPI signed-distribution chain |

The asymmetry is acceptable because:

1. The two engines have different distribution channels (GitHub Releases vs PyPI) that already differ in their threat models. Forcing identical rigor would mean either (a) running our own PyPI mirror with checksums (out of scope), or (b) downgrading the GitHub side to match PyPI's lower bar (regression).
2. graphify is the **secondary** engine (multimodal, but not the fallback path). On Windows where graphify is currently broken anyway, codebase-memory-mcp — the engine with stronger pinning — carries the load.
3. PyPI compromises and version-yanks are visible (PEP 458 / PEP 480 in progress). A graphifyy version-pin still defeats accidental upgrade-to-malicious-X.0; pin-by-hash adds friction without strongly defending against the same attacks.

### What this does NOT change

- The dual-engine selection logic in the skill is unchanged.
- The kill-switch contract is unchanged: nothing writes to `.claude/settings*.json`.
- The MCP registration flow is unchanged — still `claude mcp add --scope user --transport stdio codebase-memory -- "$CBM_BINARY"` against `~/.claude.json`.
- Graphify install behavior on the operator's machine is unchanged except for the version pin.

### Update on the "alternatives considered"

The original ADR's Alt ε ("run `graphify claude install` from a setup script") still stands as rejected — but a new Alt was tested and dropped during M1 closure:

**Alt ζ — pin install.sh by commit SHA on raw.githubusercontent.com.**

**Rejected.** Research-first dispatch revealed `install.sh` and `install.ps1` are NOT published as release assets — they live only on the `main` branch. Pinning them by commit SHA would technically work (`raw.githubusercontent.com/.../<SHA>/install.sh`) but inherits the install script's full surface (~hundreds of lines of bash that operate on the operator's PATH, `~/.local/bin`, and various configs). Skipping the install script entirely and downloading the release-asset binary directly cuts that surface. Same security posture, less code we did not write.

### Future hardening (not in v2.9)

- Verify `checksums.txt.bundle` (the `.bundle` files in the release are the GitHub Actions attestations). Would require `gh attestation verify` and an authenticated GitHub CLI; deferred until the operator's main workflows route through `gh` reliably.
- Verify `sbom.json` against a known-good SBOM. Lower priority — the SBOM helps audit but does not directly prevent supply-chain attacks the SHA pin already covers.
- Pin graphifyy by hash via a generated `requirements.txt`. Reconsider if PyPI's threat model changes or if a specific incident prompts it.

## Update 2026-04-29 — v3.1 attestation closure: cryptographic provenance verification

The M1 closure (above) shipped SHA-256 verification against the release's `checksums.txt`. That defends against a network MITM and against a release-asset re-upload by the maintainer that did NOT also re-upload `checksums.txt`. It does NOT defend against a coordinated re-upload of BOTH the asset and `checksums.txt` from a compromised maintainer account.

This v3.1 amendment closes that residual risk by adding a third gate: **GitHub Actions provenance attestation verification** via `gh attestation verify`.

### What changed

In [`tools/setup-code-graph.sh`](../../tools/setup-code-graph.sh), immediately after the SHA-256 verify and before the extraction:

```bash
if have gh; then
  if gh auth status >/dev/null 2>&1; then
    if gh attestation verify "$asset" --repo DeusData/codebase-memory-mcp; then
      log "✓ attestation verified"
    else
      err "attestation verification failed"
      CBM_STATUS="BROKEN"
      return
    fi
  else
    warn "gh CLI present but not authenticated; skipping attestation verify"
  fi
else
  warn "gh CLI not installed; skipping attestation verify"
fi
```

The verification is **online** by default — `gh attestation verify` consults Sigstore + GitHub's certificate transparency log to validate that the asset's signature chains back to a workflow run on `DeusData/codebase-memory-mcp`. The `.bundle` files in the release (`*.tar.gz.bundle`) carry the attestations; `gh attestation verify` finds them automatically when `--repo` is provided.

Validator 07 enforces:

- The string `gh attestation verify` is present.
- The script probes `gh auth status` before invoking verify (graceful degrade).
- The failure path sets `CBM_STATUS=BROKEN` and returns within 6 lines.
- The two graceful-degrade paths (gh missing / gh unauthenticated) emit warnings and continue rather than aborting.

### Asymmetric trust posture (refined)

| Gate | codebase-memory-mcp | graphifyy |
|---|---|---|
| Version pin | release tag `v0.6.0` | PyPI `==0.5.4` |
| Hash verification | SHA-256 from signed `checksums.txt` | none (uv tool / pipx don't expose --require-hashes) |
| Provenance attestation | `gh attestation verify` (graceful — warn if gh missing) | none |

The asymmetry is intentional. graphifyy is the secondary engine; PyPI's threat model is different (signed-distribution + yank + version registry); upgrading graphifyy to attestation parity is **postponed** indefinitely. See [PRD § Roadmap](../PRD.md) "v3.2+ candidates" — PyPI hash-pinning is gated on either an upstream `uv tool --require-hashes` flag or a real PyPI incident motivating the migration.

### Graceful-degrade contract

The skill, slash, and rule treat the engines as opt-in (NDA projects can force `code-graph-engine: codebase-memory`). The bootstrap treats the verifications as **layered**: each layer is added if the tool is available, and missing tools downgrade rather than abort.

Specifically for v3.1:

1. **`gh` CLI not installed** — bootstrap warns, continues with SHA-256-only. The operator sees a downgrade banner. Suggested remediation in the warning: install `gh` from `https://cli.github.com/`.
2. **`gh` installed but not authenticated** — bootstrap warns, continues with SHA-256-only. Suggested remediation: `gh auth login`.
3. **`gh attestation verify` returns non-zero** — bootstrap **hard-aborts**. This is NOT a graceful-degrade case — a failed attestation is positive evidence of tampering, not absence of evidence. CBM_STATUS=BROKEN, no install.

### Transient-error policy (intentional, security-relevant)

`gh attestation verify` non-zero is treated as a hard-abort regardless of cause. Network blips, Sigstore rate-limits, GitHub API outages, DNS resolution failures — all funnel into `CBM_STATUS=BROKEN`. This is intentional: any graceful path on verify-failure would be the exact bypass an attacker would force (e.g., DNS-poisoning Sigstore endpoints to error-out, then exploiting the fallback). The two graceful-degrade cases (gh missing, gh unauthenticated) are categorically different — they are *absence of evidence*, not failed evidence. Operators encountering transient errors retry the bootstrap; that friction is acceptable in exchange for closing the bypass.

### Future hardening (still open)

- **Offline-bundle verification** for air-gapped operator workstations. `gh attestation verify --bundle <path>` accepts a pre-downloaded `.bundle` file and verifies without contacting Sigstore at run time. Deferred — none of Batuta's current operators run air-gapped; revisit if a regulated client requires it.
- Pin the verification to a specific signer workflow (`--signer-workflow .github/workflows/release.yml@refs/tags/v0.6.0`) for paranoid binding to a specific release path. Deferred — requires inspecting upstream's release workflow to confirm the path is stable.
- SBOM verification against `sbom.json` (the release ships one). The attestation verify already covers integrity; SBOM gives audit-trail value but does not directly close additional attack surface. Deferred unless an audit requirement (client) motivates it.
- PyPI hash-pinning for graphifyy. See PRD; postponed.

## References

- [github.com/safishamsi/graphify](https://github.com/safishamsi/graphify) (verified 2026-04-29, graphifyy@0.5.4) — primary engine source
- [github.com/DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) (verified 2026-04-29, codebase-memory-mcp@0.6.0) — fallback engine source
- [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp) (verified 2026-04-29) — `claude mcp add` semantics, scope persistence to `~/.claude.json`
- [`docs/adr/0006-trust-native-delegation.md`](0006-trust-native-delegation.md) — kill-switch scope; this ADR honors the same boundary
- [`docs/plans/active/2026-04-29-code-graph-dual-engine.md`](../plans/active/2026-04-29-code-graph-dual-engine.md) — the slice plan
- [`hooks/delegation-guard.sh`](../../hooks/delegation-guard.sh) — kill-switch enforcement (unchanged by this slice)
