#!/usr/bin/env bash
# 02-implementer-research-first.sh
# Validates that agents/implementer.md has an explicit Step 2 research-first lookup
# with Context7 instruction and source-citation comment requirement. Contract introduced
# in v2.5 (PR #9).

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="02-implementer-research-first"
echo "[${case_name}] starting"

failed=0
file="agents/implementer.md"

check() {
  local pattern="$1"
  local label="$2"
  if grep -qE "${pattern}" "${REPO_ROOT}/${file}"; then
    echo "  OK   ${file} — ${label}"
  else
    echo "  MISS ${file} — ${label}"
    failed=1
  fi
}

check "Research-first lookup \(mandatory\)" "Step 2 mandatory research-first heading"
check "Context7" "mentions Context7"
check "mcp__context7__resolve-library-id" "names the Context7 resolve tool"
check "mcp__context7__query-docs" "names the Context7 query tool"
check "official documentation domain or GitHub repository" "web-search fallback"
check "// Source: <url> .*verified YYYY-MM-DD" "JS/TS citation comment template"
check "# Source: <url> .*verified YYYY-MM-DD" "Python/YAML citation comment template"
check "build-log\.md.*libraries researched" "build-log content includes researched libraries"
check "NEVER write or modify an import" "Absolute rule against untraced imports"

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
