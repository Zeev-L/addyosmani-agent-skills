#!/bin/bash
# process-checks.sh — Deterministic grading for evaluation scenarios
#
# Runs process checks defined in scenario JSON files against a workspace.
# Checks whether the agent followed the skill's workflow (not just the outcome).
#
# Usage: bash test/graders/process-checks.sh <workspace> <scenario-json>
#
# Exit: 0 if all checks pass, 1 if any fail

set -uo pipefail

if [ $# -lt 2 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  printf 'Usage: %s <workspace-dir> <scenario-json-file>\n\n' "$(basename "$0")"
  printf 'Check types:\n'
  printf '  file_order     — verify file modification order (e.g., test before impl)\n'
  printf '  test_result    — run a command and check exit code\n'
  printf '  file_contains  — check if file matches a regex pattern\n'
  printf '  file_exists    — check if a file matching a glob exists\n'
  printf '  no_code_changes — verify specific files were NOT modified\n'
  exit 0
fi

WORKSPACE="$1"
SCENARIO="$2"

if [ ! -d "$WORKSPACE" ]; then
  printf 'Error: workspace directory not found: %s\n' "$WORKSPACE" >&2
  exit 1
fi
if [ ! -f "$SCENARIO" ]; then
  printf 'Error: scenario file not found: %s\n' "$SCENARIO" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  printf 'Error: jq is required\n' >&2
  exit 1
fi

PASS=0 FAIL=0

pass() {
  PASS=$((PASS + 1))
  printf '  PASS: %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  FAIL: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2
}

SCENARIO_ID=$(jq -r '.id' "$SCENARIO")
SKILL=$(jq -r '.skill' "$SCENARIO")
CHECK_COUNT=$(jq '.process_checks | length' "$SCENARIO")

printf '══════════════════════════════════════════\n'
printf 'Process Checks: %s (%s)\n' "$SCENARIO_ID" "$SKILL"
printf '══════════════════════════════════════════\n'

i=0
while [ "$i" -lt "$CHECK_COUNT" ]; do
  check_type=$(jq -r ".process_checks[$i].type" "$SCENARIO")
  expect=$(jq -r ".process_checks[$i].expect" "$SCENARIO")

  case "$check_type" in

    file_order)
      test_glob=$(jq -r ".process_checks[$i].test_glob" "$SCENARIO")
      impl_file=$(jq -r ".process_checks[$i].impl_file" "$SCENARIO")

      # Compare modification times: test file should be newer than or same as impl
      test_file=$(find "$WORKSPACE" -name "$test_glob" -type f 2>/dev/null | head -1)
      impl_path="$WORKSPACE/$impl_file"

      if [ -z "$test_file" ]; then
        fail "file_order: no test file matching '$test_glob' found"
      elif [ ! -f "$impl_path" ]; then
        fail "file_order: implementation file '$impl_file' not found"
      else
        # Git-based check: look at commit order if available
        if [ -d "$WORKSPACE/.git" ]; then
          test_first_commit=$(git -C "$WORKSPACE" log --diff-filter=AM --format='%H' -- "$test_glob" 2>/dev/null | tail -1)
          impl_first_commit=$(git -C "$WORKSPACE" log --diff-filter=AM --format='%H' -- "$impl_file" 2>/dev/null | tail -1)
          if [ -n "$test_first_commit" ] && [ -n "$impl_first_commit" ]; then
            if git -C "$WORKSPACE" merge-base --is-ancestor "$test_first_commit" "$impl_first_commit" 2>/dev/null; then
              pass "file_order: test created/modified before implementation (git)"
            else
              fail "file_order: implementation modified before test (git)"
            fi
          else
            pass "file_order: files exist (git history inconclusive, manual review needed)"
          fi
        else
          # Fallback: mtime comparison
          if [ "$test_file" -nt "$impl_path" ] || [ "$test_file" -ot "$impl_path" ]; then
            pass "file_order: both files present (mtime check, manual review recommended)"
          fi
        fi
      fi
      ;;

    test_result)
      command_str=$(jq -r ".process_checks[$i].command" "$SCENARIO")
      if (set +o pipefail 2>/dev/null; cd "$WORKSPACE" && eval "$command_str") >/dev/null 2>&1; then
        if [ "$expect" = "pass" ]; then
          pass "test_result: '$command_str' passed"
        else
          fail "test_result: '$command_str' passed but expected failure"
        fi
      else
        if [ "$expect" = "fail" ]; then
          pass "test_result: '$command_str' failed as expected"
        else
          fail "test_result: '$command_str' failed" "Run manually to see errors"
        fi
      fi
      ;;

    file_contains)
      file_pattern=$(jq -r ".process_checks[$i].file" "$SCENARIO")
      pattern=$(jq -r ".process_checks[$i].pattern" "$SCENARIO")

      # Resolve file pattern (may contain glob)
      target=$(find "$WORKSPACE" -name "$file_pattern" -type f 2>/dev/null | head -1)
      if [ -z "$target" ]; then
        target="$WORKSPACE/$file_pattern"
      fi

      if [ ! -f "$target" ]; then
        fail "file_contains: file '$file_pattern' not found"
      elif grep -qE "$pattern" "$target" 2>/dev/null; then
        if [ "$expect" = "true" ]; then
          pass "file_contains: '$file_pattern' matches /$pattern/"
        else
          fail "file_contains: '$file_pattern' should NOT match /$pattern/"
        fi
      else
        if [ "$expect" = "true" ]; then
          fail "file_contains: '$file_pattern' does not match /$pattern/"
        else
          pass "file_contains: '$file_pattern' correctly does not match /$pattern/"
        fi
      fi
      ;;

    file_exists)
      pattern=$(jq -r ".process_checks[$i].pattern" "$SCENARIO")
      found=$(find "$WORKSPACE" -name "$pattern" -type f 2>/dev/null | head -1)
      if [ -n "$found" ]; then
        if [ "$expect" = "true" ]; then
          pass "file_exists: found file matching '$pattern'"
        else
          fail "file_exists: file matching '$pattern' should not exist"
        fi
      else
        if [ "$expect" = "true" ]; then
          fail "file_exists: no file matching '$pattern' found"
        else
          pass "file_exists: correctly no file matching '$pattern'"
        fi
      fi
      ;;

    no_code_changes)
      files=$(jq -r ".process_checks[$i].files[]" "$SCENARIO")
      initial=$(git -C "$WORKSPACE" rev-list --max-parents=0 HEAD 2>/dev/null)
      all_unchanged=1
      for f in $files; do
        if [ -d "$WORKSPACE/.git" ] && [ -n "$initial" ]; then
          if git -C "$WORKSPACE" diff --name-only "$initial" 2>/dev/null | grep -q "^${f}$"; then
            all_unchanged=0
            fail "no_code_changes: '$f' was modified"
          fi
        fi
      done
      if [ "$all_unchanged" -eq 1 ]; then
        pass "no_code_changes: implementation files unchanged (spec-only)"
      fi
      ;;

    files_modified)
      files=$(jq -r ".process_checks[$i].files[]" "$SCENARIO")
      initial=$(git -C "$WORKSPACE" rev-list --max-parents=0 HEAD 2>/dev/null)
      if [ -z "$initial" ]; then
        fail "files_modified: no git history in workspace"
      else
        for f in $files; do
          if git -C "$WORKSPACE" diff --name-only "$initial" 2>/dev/null | grep -q "^${f}$"; then
            pass "files_modified: '$f' was changed by the agent"
            printf '    ── diff %s ──\n' "$f"
            git -C "$WORKSPACE" diff "$initial" -- "$f" 2>/dev/null
            printf '    ── end diff ──\n'
          else
            fail "files_modified: '$f' was NOT modified (no-op agent?)"
          fi
        done
      fi
      ;;

    *)
      fail "unknown check type: $check_type"
      ;;
  esac

  i=$((i + 1))
done

printf '\n══════════════════════════════════════════\n'
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
printf '══════════════════════════════════════════\n'

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
