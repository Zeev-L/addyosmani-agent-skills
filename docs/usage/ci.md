# Wiring CI to a consumer repo

The plugin ships its own GitHub Actions CI in [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml). It validates the plugin itself on every PR. This guide covers how to copy that pattern into a **consumer repo** that wants the same gates: static contracts (validators) + behavioral E2E (sonnet-driven scenarios) + workflow lint (actionlint).

For the architectural decision on the harness methodology, see [ADR-0009](../adr/0009-e2e-print-mode-methodology.md).

## What you get

Three gated jobs:

| Job | Always runs? | Cost per PR | What it catches |
|---|---|---|---|
| `actionlint` | Yes | Free | Malformed workflow YAML before it lands in main |
| `static-validators` | Yes (after actionlint) | Free | Contract regressions in agent prompts, skills, rules |
| `e2e` | Only if `ANTHROPIC_API_KEY` is set | ~3 sonnet rounds + few thousand tokens | Behavioral regressions in plugin response under medium model |

Fork PRs without the secret skip `e2e` cleanly (no red CI on contributors).

## Decision: do you actually need this?

The plugin's CI exists because the plugin **is** a Claude Code artifact — its quality gate has to test the model. Most consumer repos do NOT need the `e2e` job: they need a normal language-specific test suite (pytest, jest, cargo test, go test) that doesn't drive `claude`.

Adopt this pattern only if:

- Your repo IS a Claude Code plugin / skills extension / agent definition.
- Your repo has prompt files that are part of the contract (e.g. an MCP server with custom prompts).
- You want to validate that a specific plugin you depend on still behaves correctly under the medium model on every PR.

For everything else: write a normal CI workflow with your language's test runner. The `actionlint` job from this guide is still useful as a low-cost smoke test on the workflow YAML itself.

## Copy the pattern

In your consumer repo, create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches:
      - main
  pull_request:
  workflow_dispatch:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  actionlint:
    name: Lint workflow YAML
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
      - uses: raven-actions/actionlint@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2

  test:
    name: Project tests
    runs-on: ubuntu-latest
    needs: actionlint
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
      # Replace with your test runner:
      - name: Run tests
        run: |
          # python: pytest
          # node: npm test
          # rust: cargo test
          # go: go test ./...
          echo "REPLACE WITH YOUR PROJECT'S TEST COMMAND"
```

**Update SHAs periodically.** Run `gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq .object.sha` to get the latest stable SHA for a given tag, and bump the `# vX.Y.Z` comment alongside.

## If you DO want the E2E job (plugin-style repo)

Add this third job below `test` and adapt the harness path to your repo's layout:

```yaml
  e2e:
    name: E2E harness (claude --model sonnet)
    runs-on: ubuntu-latest
    needs: [actionlint, test]
    timeout-minutes: 15

    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: Probe ANTHROPIC_API_KEY
        id: probe
        env:
          KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          if [ -z "${KEY}" ]; then
            echo "::warning::ANTHROPIC_API_KEY not set; e2e skipped"
            echo "has_key=false" >> "$GITHUB_OUTPUT"
          else
            echo "has_key=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Setup Node.js
        if: steps.probe.outputs.has_key == 'true'
        uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
        with:
          node-version: '20'

      - name: Install Claude Code CLI (pinned)
        if: steps.probe.outputs.has_key == 'true'
        run: |
          npm install -g @anthropic-ai/claude-code@2.1.123
          claude --version

      - name: Run E2E harness
        if: steps.probe.outputs.has_key == 'true'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: bash tests/e2e/run.sh   # or wherever your harness lives
```

## Operator setup (one-time per repo, if `e2e` is included)

1. Create an Anthropic API key at [console.anthropic.com](https://console.anthropic.com/) (or use an existing one).
2. Add it as a repo secret: Settings → Secrets and variables → Actions → "New repository secret". Name it `ANTHROPIC_API_KEY`.
3. The next PR triggers the `e2e` job with the secret available.

The probe pattern (env injection + `[ -z "$KEY" ]` test) is the documented GitHub-Actions-safe way to test for a secret's presence without leaking it to logs. **Never** put `${{ secrets.X }}` directly in `if:` conditions or shell `run:` blocks — the `env:` injection is the safe surface.

## Cost control options

If the `e2e` job's token spend becomes a concern:

| Strategy | How |
|---|---|
| **Manual trigger only** | Remove `pull_request` from `on:`, keep `workflow_dispatch:`. Operator runs the workflow only before mergeable PRs. |
| **Label gate** | Add `if: contains(github.event.pull_request.labels.*.name, 'ci-e2e')` to the `e2e` job. Only PRs labeled `ci-e2e` trigger the harness. |
| **Reduce scenarios** | Comment out scenarios that aren't critical for your repo. Each scenario = ~1 sonnet round. |
| **Cap with `--max-budget-usd`** | Pass `--max-budget-usd 0.50` to `claude --print` invocations inside scenarios. |

The plugin's own CI uses none of these — full coverage on every PR is acceptable for a small repo with infrequent merges. Your math may differ.

## What the plugin's CI does NOT do (so you don't either)

- **No write permissions.** `permissions: contents: read` at workflow level. The CI never pushes commits, never comments on PRs, never modifies state. If you need a bot for those, build it as a separate workflow with explicit `permissions:`.
- **No `pull_request_target`.** Fork PRs run in fork context with no secret access. `pull_request_target` would expose maintainer secrets to fork code; intentionally avoided. (See the comment in the plugin's `ci.yml` for the deterrent text.)
- **No artifact uploads.** Test outputs are reported in the job logs. If you need persistent artifacts, add an `actions/upload-artifact` step (and pin its SHA).

## Updating the pinned SHAs

The plugin pins its third-party actions and the Claude CLI for supply-chain hardening (see [v3.4 in CHANGELOG](../../CHANGELOG.md)). Quarterly, or on a security advisory, refresh:

```bash
gh api repos/actions/checkout/git/refs/tags/v6 --jq .object.sha       # actions/checkout
gh api repos/actions/setup-node/git/refs/tags/v4 --jq .object.sha     # actions/setup-node
gh api repos/raven-actions/actionlint/git/refs/tags/v2.1.2 --jq .object.sha  # actionlint
npm view @anthropic-ai/claude-code version                            # CLI latest
```

Update the SHAs and the `# vX.Y.Z` comments. Re-run E2E locally before pushing the bump.
