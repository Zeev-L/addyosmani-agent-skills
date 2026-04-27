#!/usr/bin/env bash
# 03-implementer-haiku-conditional.sh
# Validates that agents/implementer-haiku.md has a CONDITIONAL Step 2 research-first lookup
# (skip on trivial tasks, run on version bumps or import changes). Contract introduced
# in v2.5 (PR #9).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="03-implementer-haiku-conditional"
echo "[${case_name}] starting"

failed=0
file="agents/implementer-haiku.md"

check() {
  local pattern="$1"
  local label="$2"
  if grep -qiE "${pattern}" "${REPO_ROOT}/${file}"; then
    echo "  OK   ${file} — ${label}"
  else
    echo "  MISS ${file} — ${label}"
    failed=1
  fi
}

check "Research-first lookup \(conditional\)" "Step 2 conditional research-first heading"
check "Most haiku tasks .* do not touch external libraries" "explicitly mentions skip path"
check "bumps a version in the dependency manifest" "trigger 1: version bump"
check "import.*require.*use.*from" "trigger 2: import/require change"
check "skip this step and continue" "explicit skip instruction"
check "version bumps ship breaking changes" "anti-rationalization for trivial-version-bump excuse"
check "NEVER bump a version" "Absolute rule against untraced version bumps"

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
