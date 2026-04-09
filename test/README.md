# Evaluation Framework

Measures whether agent-skills actually improve agent performance. Aligned with [superpowers](https://github.com/obra/superpowers/tree/main/tests) testing patterns, [Anthropic's evaluation methodology](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), and [SkillsBench](https://arxiv.org/abs/2602.12670).

## Components

### 1. Structural Validator

Validates SKILL.md files against repo conventions that `claude plugin validate` does not check.

```bash
bash test/validate-skills.sh          # warnings don't fail
bash test/validate-skills.sh --strict  # warnings = failures
```

Checks: description <250 chars, "Use when" trigger conditions, required sections (When to Use, Common Rationalizations, Red Flags, Verification), table format.

### 2. Scenario-Based Evaluation

Test scenarios for skills, using `claude -p` in headless mode. Two tiers:

**Fast — Skill triggering (~2 min):** Does a neutral prompt activate the right skill?
```bash
bash test/run-test.sh tdd-new-feature.json --triggering
```

**Full — Integration + grading:** Does the agent produce correct results with the skill?
```bash
bash test/run-test.sh tdd-new-feature.json
```

**Full + baseline delta:** Compare with-skill vs without-skill.
```bash
bash test/run-test.sh tdd-new-feature.json --baseline
```

**Grade only:** Grade an existing workspace without re-running Claude.
```bash
bash test/run-test.sh tdd-new-feature.json --grade-only
```

**Model-specific testing:** Anthropic recommends testing skills with all models.
```bash
EVAL_MODEL=haiku bash test/run-test.sh tdd-new-feature.json    # enough guidance?
EVAL_MODEL=sonnet bash test/run-test.sh tdd-new-feature.json   # clear and efficient?
EVAL_MODEL=opus bash test/run-test.sh tdd-new-feature.json     # avoids over-explaining?
```
Source: "Test your Skill with all the models you plan to use it with." — platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

**Run all scenarios:**
```bash
bash test/run-all.sh                  # all with skill
bash test/run-all.sh --triggering     # fast skill activation check
bash test/run-all.sh --baseline       # all with delta
bash test/run-all.sh --list           # list scenarios
bash test/run-all.sh --validate       # validate JSON + prompt files
```

### 3. Process Graders

Deterministic checks on the workspace after the agent finishes:

```bash
bash test/graders/process-checks.sh <workspace> <scenario.json>
```

Check types: `file_order`, `test_result`, `file_contains`, `file_exists`, `no_code_changes`.

## Directory Structure

```
test/
├── validate-skills.sh      # Repo convention validator
├── test-helpers.sh          # Shared assertions + Claude execution helpers
├── run-test.sh              # Run single scenario
├── run-all.sh               # Run all scenarios
├── scenarios/               # Scenario definitions (JSON metadata + checks)
├── prompts/                 # One .txt file per scenario (neutral task prompt)
├── fixtures/                # Mini-apps for agent to work on
│   ├── feature-app/         # Clean app for TDD/spec scenarios
│   └── buggy-app/           # App with known bugs for debugging scenarios
└── graders/
    └── process-checks.sh    # Deterministic grading
```

## Prompt Design

Prompts in `prompts/*.txt` are **intentionally neutral** — they describe only the task, never the process. The skill is the sole source of process guidance.

Sources:
- Anthropic skill-creator: "Same prompt, no skill path" for baseline
- SkillsBench: "Instructions must not reference which Skills to use"
- agentskills.io: Baseline and with-skill runs use identical prompts

## CLI Flags

| Flag | Purpose | Used in |
|------|---------|---------|
| `--plugin-dir <path>` | Load agent-skills as plugin | With-skill run |
| `--disable-slash-commands` | Disable all slash commands | Baseline run |
| `--disallowedTools "Skill"` | Remove Skill tool entirely | Baseline run |
| `--dangerously-skip-permissions` | Bypass permission prompts (safe in /tmp/) | Both runs |
| `-p` | Non-interactive print mode | Both runs |
| `--output-format stream-json --verbose` | Structured output for parsing | Both runs |
| `claude plugin disable --all` | Disable installed plugins | Before runs |

## Methodology

Based on:
- **Superpowers** (github.com/obra/superpowers/tree/main/tests): Bash + `claude -p` + stream-json, two test tiers, skill triggering, premature action detection
- **Anthropic** (platform.claude.com best-practices): "Create evaluations BEFORE writing documentation", baseline comparison, iterative testing
- **SkillsBench** (arxiv.org/abs/2602.12670): Curated skills +16.2pp, neutral prompts, 3-5 trials for statistical rigor
- **agentskills.io** (agentskills.io/skill-creation/evaluating-skills): JSON scenario format, verification scripts

## Adding New Scenarios

1. Create `scenarios/<name>.json` with id, skill, description, prompt, expected_behaviors, process_checks
2. Create `prompts/<name>.txt` with the neutral task prompt
3. Add fixtures in `fixtures/` if needed
4. Run: `bash test/run-all.sh --validate`
5. Test: `bash test/run-test.sh <name>.json --triggering`
