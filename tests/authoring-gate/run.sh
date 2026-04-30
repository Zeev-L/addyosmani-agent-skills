#!/usr/bin/env bash
# run.sh — authoring-gate test suite (v3.8).
# Runs the skill-gate and agent-gate hook validators end-to-end against a
# simulated plugin-repo environment. Exit 0 on all-pass.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export REPO_ROOT

cd "${REPO_ROOT}"

cases=(
  "01-skill-no-marker-blocks.sh"
  "02-skill-fresh-marker-allows.sh"
  "03-skill-stale-marker-blocks.sh"
  "04-skill-non-batuta-allows.sh"
  "05-skill-bypass-env-allows.sh"
  "06-agent-no-marker-blocks.sh"
  "07-agent-fresh-marker-allows.sh"
  "08-agent-stale-marker-blocks.sh"
  "09-agent-project-local-no-origin-check.sh"
  "10-agent-bypass-env-allows.sh"
  "11-skill-edit-existing-allows.sh"
)

pass=0
fail=0
fail_names=()

echo "=== authoring-gate test suite (v3.8) ==="
echo "Repo root: ${REPO_ROOT}"
echo

for case_file in "${cases[@]}"; do
  case_path="${SCRIPT_DIR}/${case_file}"
  if [[ ! -f "${case_path}" ]]; then
    echo "SKIP: ${case_file} (file not found)"
    fail=$((fail + 1))
    fail_names+=("${case_file} (missing)")
    continue
  fi
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
