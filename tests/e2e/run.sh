#!/usr/bin/env bash
# run.sh — orchestrator for the v3.0 end-to-end test harness.
#
# Each scenario is a bash script under tests/e2e/scenarios/<NN>-<name>.sh.
# Each scenario exits 0 on PASS, 77 on SKIP (skipped due to missing prereq),
# any other non-zero on FAIL. Scenarios are independent and run sequentially.
#
# Some scenarios drive `claude --print --model sonnet` and need the Claude
# Code CLI installed and authenticated. The harness detects missing CLI and
# reports SKIP rather than FAIL.
#
# Usage:
#   bash tests/e2e/run.sh              # run all scenarios
#   bash tests/e2e/run.sh -- 02 03     # run only scenarios 02 and 03
#   bash tests/e2e/run.sh --keep       # keep sandboxes for inspection
#
# Exit codes:
#   0  all scenarios PASS or SKIP
#   1  at least one scenario FAILed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export REPO_ROOT
SCENARIOS_DIR="${SCRIPT_DIR}/scenarios"

KEEP_SANDBOX=false
FILTERS=()
seen_separator=false
for arg in "$@"; do
  case "$arg" in
    --keep)        KEEP_SANDBOX=true ;;
    --)            seen_separator=true ;;
    *)             $seen_separator && FILTERS+=("$arg") ;;
  esac
done
export KEEP_SANDBOX

mapfile -t SCENARIOS < <(find "$SCENARIOS_DIR" -maxdepth 1 -type f -name '*.sh' | sort)
if [[ ${#SCENARIOS[@]} -eq 0 ]]; then
  echo "ERROR: no scenarios found in $SCENARIOS_DIR" >&2
  exit 1
fi

# Apply filters if any.
if [[ ${#FILTERS[@]} -gt 0 ]]; then
  filtered=()
  for s in "${SCENARIOS[@]}"; do
    base="$(basename "$s")"
    for f in "${FILTERS[@]}"; do
      if [[ "$base" == "$f"* ]]; then filtered+=("$s"); break; fi
    done
  done
  SCENARIOS=("${filtered[@]}")
fi

pass=0; fail=0; skip=0
fail_names=()
skip_names=()

echo "=== v3.0 end-to-end test harness ==="
echo "Repo root: ${REPO_ROOT}"
echo "Scenarios: ${#SCENARIOS[@]}"
echo

for scenario in "${SCENARIOS[@]}"; do
  name="$(basename "$scenario")"
  echo "--- $name ---"
  if [[ ! -x "$scenario" ]]; then chmod +x "$scenario" 2>/dev/null || true; fi
  bash "$scenario"
  rc=$?
  case "$rc" in
    0)  pass=$((pass + 1));  echo "  result: PASS" ;;
    77) skip=$((skip + 1));  skip_names+=("$name"); echo "  result: SKIP" ;;
    *)  fail=$((fail + 1));  fail_names+=("$name"); echo "  result: FAIL (exit $rc)" ;;
  esac
  echo
done

echo "=== Summary ==="
echo "Total: ${#SCENARIOS[@]}"
echo "PASS:  $pass"
echo "SKIP:  $skip"
echo "FAIL:  $fail"

if (( ${#skip_names[@]} > 0 )); then
  echo
  echo "Skipped scenarios (typically missing prerequisites):"
  for n in "${skip_names[@]}"; do echo "  - $n"; done
fi

if (( ${#fail_names[@]} > 0 )); then
  echo
  echo "Failed scenarios:"
  for n in "${fail_names[@]}"; do echo "  - $n"; done
  exit 1
fi

exit 0
