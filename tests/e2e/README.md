# `tests/e2e/` — End-to-end harness for the batuta-agent-skills plugin

The static contract validators in `tests/v2.5-validators/` exercise the plugin's *files* (frontmatter, sections, prohibited strings, kill-switch invariants). The E2E harness in this directory exercises the plugin's *behavior* — it drives an actual `claude --print --model sonnet` session against a sandbox repository and asserts on the outcome.

E2E tests are slower and have more failure modes (CLI version drift, model availability, network). They are **not** run as part of `tests/v2.5-validators/run.sh`. The operator runs the harness manually before tagging a release, and the [v3.0 audit chain](../../docs/adr/0008-audit-chain-code-graph-integration.md) consults its results when reviewing release PRs.

## Quick start

```bash
# All scenarios:
bash tests/e2e/run.sh

# Specific scenarios (by leading number):
bash tests/e2e/run.sh -- 02 03

# Keep the sandbox dirs around for inspection after a failure:
bash tests/e2e/run.sh --keep
```

Exit codes:

- `0` — all scenarios PASSed or SKIPped (skips are not failures).
- `1` — at least one scenario FAILed.

Per-scenario exit codes (consumed by `run.sh`):

- `0` — PASS
- `77` — SKIP (missing prerequisite, e.g. `claude` CLI not installed; not a failure)
- any other non-zero — FAIL

## Prerequisites

| Prerequisite | Required by | Notes |
|---|---|---|
| `bash >= 4` | all | Same as the rest of the plugin. |
| `jq` | scenarios 01+ | Used to parse `~/.claude/code-graph-engines.json`. |
| `git` | scenarios 04+ | Used to set up sandbox repos with a clean tree. |
| `claude` CLI | scenarios 02, 03, 04 | Must be installed AND authenticated. Auth is auto-probed; if a minimal `claude --print --model sonnet` invocation fails inside 30s, the scenario reports SKIP. |
| Network | scenarios 02, 03, 04 | The model call goes to Anthropic's API. Offline runs report SKIP. |

## Scenarios

### `01-engines-state-roundtrip.sh` (no claude CLI required)

Sanity check of the bootstrap → state → reader pipeline. Runs `tools/setup-code-graph.sh --skip-graphify --skip-cbm`, asserts exit 2, asserts `~/.claude/code-graph-engines.json` is valid JSON with both engines reported `MISSING`, asserts `tools/check-code-graph-engines.sh --field best` returns `none` and exits 1. Backs up and restores any pre-existing state file.

### `02-claude-sonnet-skill-discovery.sh` (claude CLI required)

Launches `claude --print --model sonnet` in a fresh Python sandbox and asks it to list the Batuta plugin skills it can see. Asserts that **at least 2** of the seven expected skill names (`batuta-project-hygiene`, `batuta-skill-authoring`, `batuta-agent-authoring`, `batuta-rule-authoring`, `code-graph`, `research-first-dev`, `notion-kb-workflow`) appear in the response. Confirms the medium model loads the plugin and is willing to acknowledge the skills are available.

### `03-claude-sonnet-research-first.sh` (claude CLI required)

Drives the medium model to add a FastAPI `hello world` endpoint to a sandbox file with the explicit hint to use `research-first-dev`. Asserts the resulting `src/api.py` contains a `# Source: <url>` citation comment, an import from `fastapi`, and a route decorator. Verifies the research-first contract on the medium model.

### `04-claude-sonnet-audit-clean-tree.sh` (claude CLI + git required)

Initializes a clean git sandbox and asks the model to run the `code-reviewer` agent. Asserts the literal string `AUDIT RESULT: NOT APPLICABLE` appears in the output (the v2.5 audit-chain contract on a clean working tree, [ADR-0008](../../docs/adr/0008-audit-chain-code-graph-integration.md) preserves this).

## Why `--model sonnet`?

The operator's day-to-day runs use the medium model for cost. The plugin must be useful with sonnet, not only with opus. Each scenario explicitly pins `--model sonnet` so a regression in plugin behavior under the medium model surfaces here before reaching client projects.

## Adding a new scenario

1. Create `scenarios/<NN>-<descriptive-name>.sh`. Make it executable.
2. Use exit codes per the contract (`0` PASS / `77` SKIP / non-zero FAIL).
3. If your scenario calls `claude`, gate on `command -v claude` and on a fast probe (`claude --print --model sonnet "say only: ready"`) — return 77 on either failure.
4. If your scenario writes outside the sandbox, document it in this README. Default: every scenario uses `mktemp -d` and cleans up unless `KEEP_SANDBOX=true`.
5. The orchestrator picks up new scenarios automatically (`find scenarios -name '*.sh'`).

## Failure-mode catalogue

| Symptom | Likely cause | Fix |
|---|---|---|
| All `claude` scenarios SKIP | CLI missing or unauth | `npm install -g @anthropic-ai/claude-code` and `claude login` |
| Scenario 02 hits SKIP on auth probe | API rate-limit or credit issue | Wait or check the API console |
| Scenario 03 FAILs on missing citation | sonnet did not invoke research-first-dev | Inspect the prompt; the skill auto-trigger may need adjustment for the medium model |
| Scenario 04 FAILs on missing NOT APPLICABLE | code-reviewer Step 0 contract regressed | Re-run static validator `01-auditor-not-applicable.sh` |
| Scenario 01 FAILs on JSON parse | `setup-code-graph.sh` state writer changed shape | Compare against the schema documented in `tools/setup-code-graph.sh` `write_state()` |

## Boundary with the static validator suite

| | Static validators (`tests/v2.5-validators/`) | E2E harness (`tests/e2e/`) |
|---|---|---|
| Speed | Seconds | Tens of seconds to minutes |
| Scope | Files (grep) | Behavior (CLI invocation) |
| Network | Never | Required for `claude` scenarios |
| Run on every PR | Yes (audit chain Step 0 enforces) | No (release-time only) |
| Failure semantics | Drift / contract violation | Behavior change in the model or plugin |
