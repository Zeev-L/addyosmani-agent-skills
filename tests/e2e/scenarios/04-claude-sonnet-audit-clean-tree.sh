#!/usr/bin/env bash
# 04-claude-sonnet-audit-clean-tree.sh
# E2E: drives `claude --print --model sonnet` against a sandbox git repo
# with a CLEAN working tree, asks for a code review, and verifies the
# code-reviewer agent returns the literal `AUDIT RESULT: NOT APPLICABLE`
# string (Step 0 short-circuit per ADR-0005 and the v2.5 contract).
#
# Skips (exit 77) if claude CLI or git is missing.

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
KEEP_SANDBOX="${KEEP_SANDBOX:-false}"

if ! command -v claude >/dev/null 2>&1; then
  echo "  SKIP claude CLI not installed"
  exit 77
fi
if ! command -v git >/dev/null 2>&1; then
  echo "  SKIP git not installed"
  exit 77
fi
if ! timeout 30 claude --print --model sonnet "say only: ready" 2>/dev/null | grep -qi 'ready'; then
  echo "  SKIP claude --model sonnet not reachable"
  exit 77
fi

sandbox="$(mktemp -d 2>/dev/null || mktemp -d -t e2e-sandbox)"
cleanup() {
  if [[ "$KEEP_SANDBOX" == "true" ]]; then
    echo "  sandbox preserved at $sandbox"
  else
    rm -rf "$sandbox"
  fi
}
trap cleanup EXIT

cd "$sandbox" || exit 1
git init -q
git config user.email "e2e@test.local"
git config user.name "E2E Harness"
echo "# clean repo" > README.md
git add README.md
git commit -q -m "initial"

# Confirm tree is clean.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "  FAIL test setup left an unclean tree"
  exit 1
fi
if [[ -n "$(git diff --staged)" ]] || [[ -n "$(git diff HEAD)" ]]; then
  echo "  FAIL test setup left a non-empty diff"
  exit 1
fi
echo "  OK   sandbox tree is clean"

prompt="Run the code-reviewer agent against the current repository working tree. Return its verbatim verdict line. Do not invent findings."

out="$(timeout 180 claude --print --model sonnet "$prompt" 2>&1 || true)"
cd - >/dev/null || true

# The v2.5 contract requires the literal 'AUDIT RESULT: NOT APPLICABLE'.
if echo "$out" | grep -qF 'AUDIT RESULT: NOT APPLICABLE'; then
  echo "  OK   sonnet's code-reviewer returns NOT APPLICABLE on clean tree"
  echo "  PASS scenario 04"
  exit 0
else
  echo "  FAIL expected literal 'AUDIT RESULT: NOT APPLICABLE' in output"
  echo "  output (head):"
  echo "$out" | head -20 | sed 's/^/    /'
  exit 1
fi
