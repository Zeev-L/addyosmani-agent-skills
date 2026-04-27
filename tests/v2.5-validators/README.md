# Static contract validators for v2.5+ enforcement

This suite verifies that the v2.5 enforcement contracts (audit chain scope, research-first wiring) and the v2.6 agent-architect template fix are present in their respective files. The validators are static — they grep-check known patterns rather than invoking the `claude` CLI — so they are deterministic, fast, and CI-friendly.

## Why static checks instead of E2E tests

E2E tests that invoke `claude` against live agents flake on (a) model latency, (b) CLI version drift, (c) stochastic model output that may not contain the exact regex the test expects. Static validators catch the highest-value regression case (someone removes a Step from an agent prompt) without depending on live model behavior.

When the plugin grows CI infrastructure, a runtime E2E suite can be added on top of these validators. They are not mutually exclusive.

## Running

From the repo root:

```bash
bash tests/v2.5-validators/run.sh
```

Exit code 0 if all cases PASS. Non-zero otherwise.

## Cases

| Case | What it validates |
|---|---|
| `01-auditor-not-applicable.sh` | All three audit-gate agents (`code-reviewer`, `test-engineer`, `security-auditor`) have a `Step 0 — Pre-flight scope check` block returning `AUDIT RESULT: NOT APPLICABLE` on a clean working tree |
| `02-implementer-research-first.sh` | `agents/implementer.md` has an explicit Step 2 with Context7 lookup instruction and `Source:` citation comment requirement |
| `03-implementer-haiku-conditional.sh` | `agents/implementer-haiku.md` has a conditional Step 2 (skip on trivial tasks, run on version bumps or import changes) |
| `04-architect-bakes-research-first.sh` | `agents/agent-architect.md` Phase 5 instructs the meta-agent to bake research-first Step 2 + dual-path build-log + conditional Step 0 into generated specialists, and to run `batuta-agent-authoring` verification rules 5–6 |
| `05-batuta-agent-authoring-rules.sh` | `skills/batuta-agent-authoring/SKILL.md` has Verification rules 5–6 (research-first wiring + audit-scope wiring) and the matching Red Flags entries |

## When to add a new case

Add a new case under this directory whenever a new enforcement contract is wired into an agent prompt or skill. The case should grep-check for the canonical wording the contract uses, not paraphrase. If the wording in the source file changes, the test should fail and force the operator to update both the source and the test deliberately — not silently drift.

Naming convention: `<NN>-<short-name>.sh` where `NN` is a two-digit zero-padded sequence. Update the table above.

## When to remove a case

When the contract is superseded or deleted from the agent prompt. Removing a case without removing the contract is forbidden — the orphan contract immediately becomes drift-vulnerable.
