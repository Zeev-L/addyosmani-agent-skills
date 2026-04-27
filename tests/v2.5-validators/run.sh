#!/usr/bin/env bash
# run.sh — runs all v2.5+ static contract validators and aggregates the result.
# Exit 0 on all-pass, non-zero on any fail. Prints a summary at the end.

set -uo pipefail

# Resolve repo root from this script's location (tests/v2.5-validators/run.sh -> repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export REPO_ROOT

cd "${REPO_ROOT}"

cases=(
  "01-auditor-not-applicable.sh"
  "02-implementer-research-first.sh"
  "03-implementer-haiku-conditional.sh"
  "04-architect-bakes-research-first.sh"
  "05-batuta-agent-authoring-rules.sh"
)

pass=0
fail=0
fail_names=()

echo "=== v2.5+ static contract validators ==="
echo "Repo root: ${REPO_ROOT}"
echo

for case_file in "${cases[@]}"; do
  case_path="${SCRIPT_DIR}/${case_file}"
  if [[ ! -x "${case_path}" ]]; then
    chmod +x "${case_path}" 2>/dev/null || true
  fi
  if bash "${case_path}"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    fail_names+=("${case_file}")
  fi
  echo
done

echo "=== Summary ==="
echo "Total: ${#cases[@]}"
echo "PASS:  ${pass}"
echo "FAIL:  ${fail}"

if [[ ${fail} -gt 0 ]]; then
  echo
  echo "Failed cases:"
  for name in "${fail_names[@]}"; do
    echo "  - ${name}"
  done
  exit 1
fi

exit 0
