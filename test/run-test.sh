#!/bin/bash
# run-test.sh — Run a single evaluation scenario
#
# Usage:
#   bash test/run-test.sh <scenario.json>               # With skill, grade
#   bash test/run-test.sh <scenario.json> --baseline     # With + without, delta
#   bash test/run-test.sh <scenario.json> --triggering   # Fast: just check skill activates
#   bash test/run-test.sh <scenario.json> --grade-only   # Grade existing workspace
#
# Model selection (Anthropic recommends testing with Haiku, Sonnet, and Opus):
#   EVAL_MODEL=haiku bash test/run-test.sh <scenario.json>
#   EVAL_MODEL=sonnet bash test/run-test.sh <scenario.json>
#   EVAL_MODEL=opus bash test/run-test.sh <scenario.json>

set -uo pipefail

source "$(dirname "$0")/test-helpers.sh"

if [ $# -lt 1 ]; then
  printf 'Usage: %s <scenario.json> [--baseline|--triggering|--grade-only]\n' "$(basename "$0")"
  exit 1
fi

# ── Resolve scenario ────────────────────────────────────────────────────────
SCENARIO="$1"
case "$SCENARIO" in
  /*) ;;
  *) SCENARIO="$EVAL_DIR/scenarios/$SCENARIO"
     [ ! -f "$SCENARIO" ] && SCENARIO="$1"
     ;;
esac

[ ! -f "$SCENARIO" ] && { printf 'Error: %s not found\n' "$SCENARIO" >&2; exit 1; }

SCENARIO_ID=$(jq -r '.id' "$SCENARIO")
SKILL=$(jq -r '.skill' "$SCENARIO")
WORKSPACE="/tmp/eval-${SCENARIO_ID}"
MODE="${2:-}"

# Resolve prompt: prefer .txt file, fallback to JSON
PROMPT_FILE="$EVAL_DIR/prompts/$(basename "$SCENARIO" .json).txt"
if [ -f "$PROMPT_FILE" ]; then
  PROMPT=$(cat "$PROMPT_FILE")
else
  PROMPT=$(jq -r '.prompt' "$SCENARIO")
fi

# ── Grade-only mode ─────────────────────────────────────────────────────────
if [ "$MODE" = "--grade-only" ]; then
  [ ! -d "$WORKSPACE" ] && { printf 'Error: workspace %s not found\n' "$WORKSPACE" >&2; exit 1; }
  exec bash "$EVAL_DIR/graders/process-checks.sh" "$WORKSPACE" "$SCENARIO"
fi

# ── Triggering mode (fast ~2 min) ──────────────────────────────────────────
if [ "$MODE" = "--triggering" ]; then
  printf '══════════════════════════════════════════\n'
  printf 'Skill Triggering Test: %s\n' "$SCENARIO_ID"
  printf '══════════════════════════════════════════\n\n'

  LOG="/tmp/eval-triggering-${SCENARIO_ID}.jsonl"
  setup_workspace "$SCENARIO" "$WORKSPACE"
  cd "$WORKSPACE"

  printf '▸ Running with neutral prompt...\n'
  run_claude "$PROMPT" "$LOG"

  printf '\n'
  assert_plugin_loaded "$LOG"
  assert_skill_triggered "$LOG" "$SKILL"
  assert_no_premature_action "$LOG"

  print_results
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi

# ── Full test mode ──────────────────────────────────────────────────────────
printf '══════════════════════════════════════════\n'
printf 'Evaluation: %s (%s)\n' "$SCENARIO_ID" "$SKILL"
printf '══════════════════════════════════════════\n\n'

# Save plugins and disable all for clean environment
printf '▸ Saving plugin state...\n'
save_plugins
printf '▸ Disabling all plugins...\n'
claude plugin disable --all >/dev/null 2>&1

# ── WITH SKILL ──────────────────────────────────────────────────────────────
printf '\n▸ Running WITH skill...\n'
setup_workspace "$SCENARIO" "$WORKSPACE"
cd "$WORKSPACE"

WITH_LOG="/tmp/eval-with-${SCENARIO_ID}.jsonl"
run_claude "$PROMPT" "$WITH_LOG"
cd "$EVAL_DIR/.."

# Verify plugin loaded
assert_plugin_loaded "$WITH_LOG"

# Grade
printf '\n── WITH SKILL ──\n'
with_output=$(bash "$EVAL_DIR/graders/process-checks.sh" "$WORKSPACE" "$SCENARIO" 2>&1)
echo "$with_output"
with_pass=$(echo "$with_output" | grep -c "PASS:" || true)
with_fail=$(echo "$with_output" | grep -c "FAIL:" || true)
with_total=$((with_pass + with_fail))

# ── WITHOUT SKILL (only if --baseline) ──────────────────────────────────────
if [ "$MODE" = "--baseline" ]; then
  printf '\n▸ Running WITHOUT skill (baseline)...\n'
  setup_workspace "$SCENARIO" "$WORKSPACE"
  cd "$WORKSPACE"

  WITHOUT_LOG="/tmp/eval-without-${SCENARIO_ID}.jsonl"
  run_claude_baseline "$PROMPT" "$WITHOUT_LOG"
  cd "$EVAL_DIR/.."

  # Grade
  printf '\n── WITHOUT SKILL ──\n'
  without_output=$(bash "$EVAL_DIR/graders/process-checks.sh" "$WORKSPACE" "$SCENARIO" 2>&1)
  echo "$without_output"
  without_pass=$(echo "$without_output" | grep -c "PASS:" || true)

  # Delta
  delta=$((with_pass - without_pass))
  printf '\n══════════════════════════════════════════\n'
  printf 'DELTA: %s\n' "$SCENARIO_ID"
  printf '  With skill:    %d/%d PASS\n' "$with_pass" "$with_total"
  printf '  Without skill: %d/%d PASS\n' "$without_pass" "$with_total"
  printf '  Delta:         %+d\n' "$delta"
  printf '══════════════════════════════════════════\n'
fi

# Restore plugins
printf '\n▸ Restoring plugins...\n'
restore_plugins

[ "$with_fail" -eq 0 ] && exit 0 || exit 1
