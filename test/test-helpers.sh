#!/bin/bash
# test-helpers.sh — Shared assertion library for evaluation scripts
#
# Source this file in test scripts:
#   source "$(dirname "$0")/test-helpers.sh"
#
# Pattern follows superpowers tests/claude-code/test-helpers.sh

EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$EVAL_DIR")"

PASS=0 FAIL=0 WARN=0

# ── Assertions ──────────────────────────────────────────────────────────────

pass() {
  PASS=$((PASS + 1))
  printf '  PASS: %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  FAIL: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2
}

warn() {
  WARN=$((WARN + 1))
  printf '  WARN: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2
}

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "Pattern /$pattern/ not found in $(basename "$file")"
  fi
}

assert_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    fail "$label" "Pattern /$pattern/ found in $(basename "$file") but should not be"
  else
    pass "$label"
  fi
}

print_results() {
  printf '\n══════════════════════════════════════════\n'
  printf 'Results: %d passed, %d failed' "$PASS" "$FAIL"
  [ "$WARN" -gt 0 ] && printf ', %d warnings' "$WARN"
  printf '\n══════════════════════════════════════════\n'
}

# ── Claude Execution ────────────────────────────────────────────────────────

# Model to use for evaluation runs. Override with EVAL_MODEL env var.
# Anthropic recommends testing with all models:
#   "Test your Skill with all the models you plan to use it with."
#   - Haiku: Does the Skill provide enough guidance?
#   - Sonnet: Is the Skill clear and efficient?
#   - Opus: Does the Skill avoid over-explaining?
# Source: platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
EVAL_MODEL="${EVAL_MODEL:-}"

# Run Claude with agent-skills plugin loaded (with skill)
run_claude() {
  local prompt="$1" log="$2"
  local model_flag=""
  [ -n "$EVAL_MODEL" ] && model_flag="--model $EVAL_MODEL"
  claude --plugin-dir "$REPO_ROOT" --dangerously-skip-permissions \
    -p --output-format stream-json --verbose $model_flag "$prompt" > "$log" 2>/dev/null || true
}

# Run Claude without any skills (baseline)
run_claude_baseline() {
  local prompt="$1" log="$2"
  local model_flag=""
  [ -n "$EVAL_MODEL" ] && model_flag="--model $EVAL_MODEL"
  claude --disable-slash-commands --disallowedTools "Skill" \
    --dangerously-skip-permissions -p --output-format stream-json \
    --verbose $model_flag "$prompt" > "$log" 2>/dev/null || true
}

# ── Skill Verification ─────────────────────────────────────────────────────

# Check if a specific skill was triggered in the session log
assert_skill_triggered() {
  local log="$1" skill="$2"
  if grep -q '"name":"Skill"' "$log" 2>/dev/null && \
     grep -qE "\"skill\":\"([^\"]*:)?${skill}\"" "$log" 2>/dev/null; then
    pass "skill triggered: $skill"
  else
    fail "skill NOT triggered: $skill"
  fi
}

# Check that no tools were used before the Skill tool (premature action detection)
# Inspired by superpowers tests/explicit-skill-requests/run-test.sh
assert_no_premature_action() {
  local log="$1"
  local first_skill_line
  first_skill_line=$(grep -n '"name":"Skill"' "$log" 2>/dev/null | head -1 | cut -d: -f1)

  if [ -z "$first_skill_line" ]; then
    fail "no premature action: Skill tool never invoked"
    return
  fi

  # Check if Edit, Write, or Bash were used before the first Skill invocation
  local premature
  premature=$(head -n "$first_skill_line" "$log" | \
    grep '"type":"tool_use"' | \
    grep -E '"name":"(Edit|Write|Bash)"' | \
    grep -v '"name":"Skill"' | \
    grep -v '"name":"TodoWrite"' | \
    grep -v '"name":"Read"' | \
    grep -v '"name":"Glob"' | \
    grep -v '"name":"Grep"' || true)

  if [ -z "$premature" ]; then
    pass "no premature action: skill loaded before editing/writing"
  else
    fail "premature action: agent used Edit/Write/Bash before loading skill"
  fi
}

# Check that agent-skills plugin was loaded in the session
assert_plugin_loaded() {
  local log="$1"
  local count
  count=$(grep -o '"agent-skills:[^"]*"' "$log" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    pass "agent-skills plugin loaded ($count skills)"
  else
    fail "agent-skills plugin NOT loaded"
  fi
}

# ── Plugin Management ───────────────────────────────────────────────────────

save_plugins() {
  claude plugin list 2>&1 | grep -B3 "enabled" | grep "❯" | sed 's/.*❯ //' > /tmp/eval-plugins-backup.txt
  printf '  Saved %d enabled plugins\n' "$(wc -l < /tmp/eval-plugins-backup.txt | tr -d ' ')"
}

restore_plugins() {
  if [ -f /tmp/eval-plugins-backup.txt ]; then
    while IFS= read -r plugin; do
      [ -z "$plugin" ] && continue
      claude plugin enable "$plugin" >/dev/null 2>&1 || true
    done < /tmp/eval-plugins-backup.txt
    rm -f /tmp/eval-plugins-backup.txt
    printf '  Restored all plugins\n'
  fi
}

# ── Workspace Management ────────────────────────────────────────────────────

setup_workspace() {
  local scenario="$1" workspace="$2"
  rm -rf "$workspace"
  mkdir -p "$workspace"

  local fixtures
  fixtures=$(jq -r '.fixtures[]? // empty' "$scenario")
  if [ -n "$fixtures" ]; then
    for fixture in $fixtures; do
      local fixture_path="$EVAL_DIR/$fixture"
      if [ -d "$fixture_path" ]; then
        cp -r "$fixture_path"/* "$workspace/"
      fi
    done
  fi

  (cd "$workspace" && git init -q && git add -A && git commit -q -m "initial: evaluation fixture")
}
