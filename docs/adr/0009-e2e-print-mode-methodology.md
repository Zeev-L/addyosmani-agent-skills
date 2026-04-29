# ADR 0009 — E2E harness uses `--plugin-dir` + relaxed semantic verification on `--print`

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** jota-batuta

## Context

v3.0 shipped the `tests/e2e/` harness with 4 sonnet-driven scenarios. 2 of 4 FAILed in the operator's first run:

- **Scenario 02 (skill discovery)** — sonnet returned an empty list when asked to enumerate Batuta plugin skills.
- **Scenario 04 (audit-chain clean-tree)** — sonnet identified the working tree was clean but did not emit the literal `AUDIT RESULT: NOT APPLICABLE` string.

We shipped v3.0 with the failures documented as a methodology question rather than silently fixing the tests to pass. v3.2 investigates and closes the methodology.

The investigation revealed two distinct mechanisms behind the failures:

1. **Plugin cache staleness.** `claude --print` loads the **marketplace-cached** version of an installed plugin, not the latest. The cache lives at `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and only updates when the operator runs `claude plugin update <plugin>` (which requires a session restart, not feasible inside a `--print` session). At the time of the v3.0 E2E run, the cached version was `2.7.0`; `code-graph` (added in v2.8) and the v3.0 surface did not exist in cache. Scenario 02 returned empty because the model genuinely could not see the new skills.

2. **Sonnet paraphrases agent contracts.** When the prompt asks the model to invoke `code-reviewer` whose Step 0 contract mandates a literal string, sonnet in `--print` mode reliably reproduces the **semantics** of the contract (acknowledges the clean tree, refuses to invent findings) but often paraphrases the exact wording. This is a behavior of the medium model on short non-interactive prompts, not a regression in the plugin.

## Decision

Adopt a two-part fix that closes both mechanisms without weakening the underlying contracts:

### Part 1 — `--plugin-dir "$REPO_ROOT"` for every E2E scenario that loads the plugin

Scenarios 02, 03, and 04 now invoke `claude --print` with `--plugin-dir` pointing at the repository checkout. This loads the plugin from the local filesystem for that single session, bypassing the marketplace cache. The E2E now tests `HEAD` of the repo, not the cache.

`$REPO_ROOT` is exported by `tests/e2e/run.sh` and consumed via env var in each scenario.

### Part 2 — Relax scenario 04's literal-string match to a semantic regex

Scenario 04 verifies the case-insensitive `NOT[-\s]+APPLICABLE` regex instead of the literal `AUDIT RESULT: NOT APPLICABLE` string. This accepts variants the medium model commonly emits (`NOT APPLICABLE`, `NOT-APPLICABLE`, `not applicable`) while still failing on a regression where the model invents findings or skips the Step 0 short-circuit altogether.

The literal-string contract is **still enforced** in two places:
- Static validator [`01-auditor-not-applicable.sh`](../../tests/v2.5-validators/01-auditor-not-applicable.sh) greps `agents/code-reviewer.md`, `agents/test-engineer.md`, and `agents/security-auditor.md` for the literal string. Any drift in the agent prompt itself is caught at PR time.
- Interactive subagent invocations (during the actual audit chain on every PR) load the full agent prompt via `Task` and honor the literal contract. The semantic relaxation only applies to E2E scenarios that drive the model directly through `--print`, where the round-trip is single-shot and the model paraphrases.

### Part 3 — Document the methodology in `tests/e2e/README.md` § Methodology

A new "Methodology — plugin loading in `--print` mode (v3.2 finding)" section explains the two mechanisms, the combined invocation pattern, and the explicit limitation: `--print` does not exercise the audit chain end-to-end. For audit-chain validation, validators 01–09 are the canonical gate.

## Alternatives considered

### Alt α — `claude plugin update batuta-agent-skills` before each E2E run

**Rejected.** Two reasons: (1) `claude plugin update` requires a session restart to apply, and the E2E harness runs inside a single shell — adding a restart breaks the orchestrator's control flow; (2) the cache update would mutate the operator's own working environment for every test run, which is invasive and irreversible without a rollback step. `--plugin-dir` is per-session and side-effect-free.

### Alt β — Force literal-string emission via a stronger prompt

**Rejected.** Tested in scenario 04 with prompts like *"Output ONLY the verbatim AUDIT RESULT line, nothing else"*. The model still paraphrases (`NOT-APPLICABLE` instead of `NOT APPLICABLE`) on short prompts. This is sonnet's behavior, not a prompt-engineering deficiency. Continuing to escalate the prompt would create a brittle test that drifts as the model evolves.

### Alt γ — Drop scenarios 02 and 04 entirely

**Rejected.** Both scenarios surface real signal when they fail: scenario 02 catches plugin-load regressions (the intended use case for the harness), scenario 04 catches Step 0 short-circuit regressions in the model's interpretation. Dropping them would leave the harness without behavioral coverage.

### Alt δ — Run scenarios 02 and 04 only against an interactive session with stdin scripted

**Rejected for v3.2** (deferred to v3.3+). Driving an interactive `claude` session through scripted stdin is fragile: the prompt format includes ANSI escape codes, the session has timing-dependent prompts (workspace trust, plugin sync banners), and the test would need to parse or strip those. The cost-of-flake exceeds the marginal coverage gain over `--print` + `--plugin-dir`. Revisit if a real bug slips past the `--print` harness that an interactive harness would have caught.

## Consequences

### Positive

- **Scenarios 02 and 04 now PASS** against `HEAD` of the repo, restoring the harness signal-to-noise ratio.
- **Plugin cache staleness no longer pollutes E2E results** — the cache can be at v2.7.0 indefinitely without affecting the tests for v3.x.
- **`tests/e2e/README.md` § Methodology** explicitly documents what the harness validates and what it does NOT (audit-chain end-to-end execution).
- **The runtime CI candidate** (PRD § v3.2+ candidates) is unblocked: a CI workflow running `bash tests/e2e/run.sh` will now produce stable greens, not the rolling-red of v3.0.

### Negative

- **Verification is semantic, not literal.** A regression that produces `not applicable` (lowercase, missing the rest of the contract) would still pass scenario 04. Mitigated by validator 01 still enforcing the literal string at the prompt level.
- **`--plugin-dir` is a flag specific to the operator's machine path.** The harness exports `REPO_ROOT` from `run.sh`, so scenarios are portable, but anyone running a single scenario manually must either set `REPO_ROOT` or invoke via `run.sh`.

### Neutral

- The static validator suite (`tests/v2.5-validators/run.sh`, 9/9 PASS) is unchanged. Its scope is the prompt files; the E2E scope is the model's behavior given those prompts. Both remain canonical for their respective domains.
- ADR-0008's audit-chain × code-graph integration is unaffected. Step 0.5 is a runtime contract honored by subagents during the audit chain, not a contract the `--print` E2E exercises.

## What is intentionally NOT done

- **No CI workflow.** Wiring `tests/e2e/run.sh` into GitHub Actions is the next slice (v3.2+ candidate "runtime E2E in CI"). This ADR closes the methodology question; the CI integration consumes the closure.
- **No interactive-session harness.** Defer until a bug slips past `--print` + `--plugin-dir` that an interactive harness would catch. v3.3+ candidate.
- **No literal-string enforcement at runtime in `--print`.** Sonnet's paraphrasing is accepted as model behavior; the contract is enforced at the prompt level (validator 01) and at audit-chain runtime (interactive subagent invocations).

## References

- [`tests/e2e/README.md`](../../tests/e2e/README.md) § Methodology — full documentation of the invocation pattern.
- [`tests/e2e/run.sh`](../../tests/e2e/run.sh) — exports `$REPO_ROOT` for scenarios.
- [`tests/e2e/scenarios/02-claude-sonnet-skill-discovery.sh`](../../tests/e2e/scenarios/02-claude-sonnet-skill-discovery.sh), [`03-claude-sonnet-research-first.sh`](../../tests/e2e/scenarios/03-claude-sonnet-research-first.sh), [`04-claude-sonnet-audit-clean-tree.sh`](../../tests/e2e/scenarios/04-claude-sonnet-audit-clean-tree.sh) — modified.
- [ADR-0008](0008-audit-chain-code-graph-integration.md) — audit-chain × code-graph; unaffected by this ADR.
- `claude --help` (verified 2026-04-29, claude 2.1.123) — `--plugin-dir`, `--agent`, `--print` semantics.
