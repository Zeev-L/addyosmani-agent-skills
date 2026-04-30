#!/usr/bin/env bash
# _lib.sh — shared helpers for authoring-gate test cases.
# Sourced by every NN-*.sh test. Provides setup_plugin_root, cleanup, run_hook.

# Create a fake plugin root with `.claude-plugin/` marker and a git remote that
# matches the batuta-agent-skills regex by default. Sets PLUGIN_ROOT.
setup_batuta_plugin_root() {
  PLUGIN_ROOT="$(mktemp -d)"
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"
  echo '{"name":"test"}' > "$PLUGIN_ROOT/.claude-plugin/plugin.json"
  mkdir -p "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/agents"
  ( cd "$PLUGIN_ROOT" && git init -q && git remote add origin "https://github.com/jota-batuta/batuta-agent-skills.git" )
  trap 'rm -rf "$PLUGIN_ROOT"' EXIT
  export PLUGIN_ROOT
}

# Same but with a non-batuta origin (for negative-scope tests).
setup_non_batuta_plugin_root() {
  PLUGIN_ROOT="$(mktemp -d)"
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"
  echo '{"name":"test"}' > "$PLUGIN_ROOT/.claude-plugin/plugin.json"
  mkdir -p "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/agents"
  ( cd "$PLUGIN_ROOT" && git init -q && git remote add origin "https://github.com/someone/unrelated-plugin.git" )
  trap 'rm -rf "$PLUGIN_ROOT"' EXIT
  export PLUGIN_ROOT
}

# Drop a fresh marker (current mtime). $1 = "skill" or "agent".
write_fresh_marker() {
  local kind="$1"
  mkdir -p "$PLUGIN_ROOT/.claude"
  local marker="$PLUGIN_ROOT/.claude/.authoring-marker-${kind}-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
  touch "$marker"
}

# Drop a stale marker (mtime 2 hours ago). Uses `touch -d` for portability.
write_stale_marker() {
  local kind="$1"
  mkdir -p "$PLUGIN_ROOT/.claude"
  local marker="$PLUGIN_ROOT/.claude/.authoring-marker-${kind}-stale"
  touch "$marker"
  # Set mtime back 2 hours. -d works on GNU coreutils (Git Bash on Windows ships GNU).
  touch -d "2 hours ago" "$marker" 2>/dev/null || touch -t "$(date -u -d '2 hours ago' +%Y%m%d%H%M.%S 2>/dev/null || echo 202601010000.00)" "$marker"
}

# Run the hook with a synthetic input. $1 = hook script name, $2 = file_path.
# Prints "EXIT=<code> STDERR=<text>" via stdout for assertion convenience.
run_hook() {
  local hook="$1"
  local fpath="$2"
  local input
  input=$(printf '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"%s"}}' "$fpath")
  local stderr_capture
  stderr_capture=$(mktemp)
  echo "$input" | bash "$REPO_ROOT/hooks/$hook" 2>"$stderr_capture"
  local rc=$?
  local err
  err=$(cat "$stderr_capture")
  rm -f "$stderr_capture"
  printf 'EXIT=%d STDERR=%s' "$rc" "$err"
  return $rc
}

# Assert: $1 = expected exit code (0 or 1), $2 = description.
# Exits the test with 1 on mismatch, prints PASS line on match.
assert_exit() {
  local expected="$1"
  local desc="$2"
  local got="$3"
  if [[ "$got" == "$expected" ]]; then
    echo "PASS: $desc"
    return 0
  fi
  echo "FAIL: $desc — expected exit $expected, got $got"
  return 1
}
