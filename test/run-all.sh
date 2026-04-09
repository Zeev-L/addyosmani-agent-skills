#!/bin/bash
# run-all.sh — Run all evaluation scenarios
#
# Usage:
#   bash test/run-all.sh                  # Run all with skill
#   bash test/run-all.sh --baseline        # Run all with delta
#   bash test/run-all.sh --triggering      # Fast: just check skill activation
#   bash test/run-all.sh --validate        # Validate all scenario JSON + prompts
#   bash test/run-all.sh --list            # List all scenarios

set -uo pipefail

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-}"

# ── List ────────────────────────────────────────────────────────────────────
if [ "$MODE" = "--list" ]; then
  printf '%-35s %-25s %s\n' "SCENARIO" "SKILL" "DESCRIPTION"
  printf '%-35s %-25s %s\n' "--------" "-----" "-----------"
  for f in "$EVAL_DIR"/scenarios/*.json; do
    [ -f "$f" ] || continue
    printf '%-35s %-25s %s\n' \
      "$(jq -r '.id' "$f")" \
      "$(jq -r '.skill' "$f")" \
      "$(jq -r '.description' "$f")"
  done
  exit 0
fi

# ── Validate ────────────────────────────────────────────────────────────────
if [ "$MODE" = "--validate" ]; then
  pass=0 fail=0
  for f in "$EVAL_DIR"/scenarios/*.json; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .json)

    # JSON valid?
    if ! jq empty "$f" 2>/dev/null; then
      printf '  FAIL: %s.json — invalid JSON\n' "$name" >&2
      fail=$((fail + 1))
      continue
    fi

    # Required fields?
    missing=""
    for field in id skill description prompt expected_behaviors process_checks; do
      val=$(jq -r ".$field // empty" "$f")
      [ -z "$val" ] && missing="$missing $field"
    done
    if [ -n "$missing" ]; then
      printf '  FAIL: %s.json — missing:%s\n' "$name" "$missing" >&2
      fail=$((fail + 1))
      continue
    fi

    # Matching prompt file?
    if [ -f "$EVAL_DIR/prompts/${name}.txt" ]; then
      printf '  PASS: %s.json (prompt: %s.txt)\n' "$name" "$name"
    else
      printf '  PASS: %s.json (no prompt .txt — will use JSON prompt)\n' "$name"
    fi
    pass=$((pass + 1))
  done
  printf '\nResults: %d passed, %d failed\n' "$pass" "$fail"
  [ "$fail" -eq 0 ] && exit 0 || exit 1
fi

# ── Run all scenarios ───────────────────────────────────────────────────────
total=0 passed=0 failed=0

for f in "$EVAL_DIR"/scenarios/*.json; do
  [ -f "$f" ] || continue
  total=$((total + 1))
  name=$(basename "$f")

  printf '\n────────────────────────────────────────\n'
  printf 'Scenario %d: %s\n' "$total" "$name"
  printf '────────────────────────────────────────\n'

  if bash "$EVAL_DIR/run-test.sh" "$f" "$MODE"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

printf '\n══════════════════════════════════════════\n'
printf 'All Scenarios: %d/%d passed\n' "$passed" "$total"
printf '══════════════════════════════════════════\n'

[ "$failed" -eq 0 ] && exit 0 || exit 1
