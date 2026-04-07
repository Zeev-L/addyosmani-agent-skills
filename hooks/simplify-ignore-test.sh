#!/bin/bash
# simplify-ignore-test.sh — Tests for the simplify-ignore hook
#
# Exercises filter_file by extracting function definitions from the hook.
# Run: bash hooks/simplify-ignore-test.sh

set -euo pipefail

PASS=0 FAIL=0
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

export CACHE="$TMPDIR/cache"
mkdir -p "$CACHE"

# Extract function definitions we need
hash_cmd() {
  if command -v shasum >/dev/null 2>&1; then shasum
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum
  else printf '%s\n' "error: missing shasum or sha1sum" >&2; exit 1; fi
}
file_id() { printf '%s' "$1" | hash_cmd | cut -c1-16; }
block_hash() { printf '%s' "$1" | hash_cmd | cut -c1-8; }
escape_glob() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\*/\\*}"
  s="${s//\?/\\?}"
  s="${s//\[/\\[}"
  printf '%s' "$s"
}

# Extract filter_file from the hook script (line 59 "filter_file()" to line 142 closing brace)
eval "$(sed -n '/^filter_file()/,/^}/p' hooks/simplify-ignore.sh)"

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  PASS: %s\n' "$label"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL: %s\n' "$label" >&2
    printf '    expected: %s\n' "$(printf '%s' "$expected" | cat -v)" >&2
    printf '    actual:   %s\n' "$(printf '%s' "$actual" | cat -v)" >&2
  fi
}

# ── Test 1: Single-line block produces exactly one placeholder ────────────
printf 'Test 1: Single-line block (start+end on same line)\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/single-line.js"
DEST="$TMPDIR/single-line-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
/* simplify-ignore-start */ const secret = 42; /* simplify-ignore-end */
const b = 2;
EOF

FID="test_single"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exactly one placeholder line" "1" "$placeholder_count"
assert_eq "line before block preserved" "1" "$(grep -c 'const a = 1' "$DEST")"
assert_eq "line after block preserved" "1" "$(grep -c 'const b = 2' "$DEST")"

block_files=$(ls "$CACHE/${FID}".block.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "one block file in cache" "1" "$block_files"

block_content=$(cat "$CACHE/${FID}".block.*)
assert_eq "block content matches" \
  "/* simplify-ignore-start */ const secret = 42; /* simplify-ignore-end */" \
  "$block_content"

# ── Test 2: Multi-line block ─────────────────────────────────────────────
printf '\nTest 2: Multi-line block\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/multi-line.js"
DEST="$TMPDIR/multi-line-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
// simplify-ignore-start
const secret1 = 42;
const secret2 = 99;
// simplify-ignore-end
const b = 2;
EOF

FID="test_multi"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exactly one placeholder for multi-line block" "1" "$placeholder_count"

output_lines=$(wc -l < "$DEST" | tr -d ' ')
assert_eq "output has 3 lines (before + placeholder + after)" "3" "$output_lines"

# ── Test 3: Multiple blocks in one file ──────────────────────────────────
printf '\nTest 3: Multiple blocks in one file\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/multi-block.js"
DEST="$TMPDIR/multi-block-filtered.js"
cat > "$SRC" <<'EOF'
line1
// simplify-ignore-start
blockA
// simplify-ignore-end
line2
// simplify-ignore-start
blockB
// simplify-ignore-end
line3
EOF

FID="test_multiblock"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "two placeholders for two blocks" "2" "$placeholder_count"

block_files=$(ls "$CACHE/${FID}".block.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "two block files in cache" "2" "$block_files"

# ── Test 4: Reason string preserved ──────────────────────────────────────
printf '\nTest 4: Reason string in placeholder\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/reason.js"
DEST="$TMPDIR/reason-filtered.js"
cat > "$SRC" <<'EOF'
// simplify-ignore-start: perf-critical
hot_loop();
// simplify-ignore-end
EOF

FID="test_reason"
filter_file "$SRC" "$DEST" "$FID"

assert_eq "placeholder includes reason" "1" "$(grep -c 'perf-critical' "$DEST")"

reason_files=$(ls "$CACHE/${FID}".reason.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "reason file saved" "1" "$reason_files"
assert_eq "reason content" "perf-critical" "$(cat "$CACHE/${FID}".reason.*)"

# ── Test 5: Trailing newline preservation ────────────────────────────────
printf '\nTest 5: Trailing newline preservation\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/no-trailing-nl.js"
DEST="$TMPDIR/no-trailing-nl-filtered.js"
printf 'line1\n// simplify-ignore-start\nsecret\n// simplify-ignore-end' > "$SRC"

FID="test_trail"
filter_file "$SRC" "$DEST" "$FID"

# Source has no trailing newline; dest should also have no trailing newline
src_has_nl=$(tail -c 1 "$SRC" | wc -l | tr -d ' ')
dest_has_nl=$(tail -c 1 "$DEST" | wc -l | tr -d ' ')
assert_eq "dest preserves no-trailing-newline from source" "$src_has_nl" "$dest_has_nl"

# ── Test 6: No blocks → return 1 ────────────────────────────────────────
printf '\nTest 6: No blocks returns 1\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/no-blocks.js"
DEST="$TMPDIR/no-blocks-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
const b = 2;
EOF

FID="test_noblocks"
rc=0
filter_file "$SRC" "$DEST" "$FID" || rc=$?
assert_eq "returns 1 when no blocks found" "1" "$rc"

# ── Test 7: Unclosed block emits warning and flushes ─────────────────────
printf '\nTest 7: Unclosed block\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/unclosed.js"
DEST="$TMPDIR/unclosed-filtered.js"
cat > "$SRC" <<'EOF'
line1
// simplify-ignore-start
orphan code
EOF

FID="test_unclosed"
stderr_out=$(filter_file "$SRC" "$DEST" "$FID" 2>&1) || true
assert_eq "warning emitted for unclosed block" "1" "$(printf '%s' "$stderr_out" | grep -c 'unclosed')"
assert_eq "orphan code flushed to output" "1" "$(grep -c 'orphan code' "$DEST")"

# ── Test 8: Single-line block with reason ────────────────────────────────
printf '\nTest 8: Single-line block with reason\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/single-reason.js"
DEST="$TMPDIR/single-reason-filtered.js"
cat > "$SRC" <<'EOF'
before
/* simplify-ignore-start: hot-path */ x = compute(); /* simplify-ignore-end */
after
EOF

FID="test_single_reason"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exactly one placeholder for single-line+reason" "1" "$placeholder_count"
assert_eq "reason in placeholder" "1" "$(grep -c 'hot-path' "$DEST")"

# ── Test 9: HTML comment syntax ──────────────────────────────────────────
printf '\nTest 9: HTML comment syntax\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/html.html"
DEST="$TMPDIR/html-filtered.html"
cat > "$SRC" <<'EOF'
<div>
<!-- simplify-ignore-start -->
<secret-component />
<!-- simplify-ignore-end -->
</div>
EOF

FID="test_html"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "HTML block replaced" "1" "$placeholder_count"
assert_eq "HTML suffix preserved" "1" "$(grep -c '\-\->' "$DEST")"

# ── Test 10: JSON parsing error warning ──────────────────────────────────
printf '\nTest 10: Malformed JSON input produces warning\n'

warning_out=$(echo 'NOT_JSON{{{' | bash hooks/simplify-ignore.sh 2>&1) || true
assert_eq "warning on bad JSON" "1" "$(printf '%s' "$warning_out" | grep -c 'Warning.*failed to parse')"

# ── Test 11: Empty JSON {} from pipe does NOT trigger restore (Bug 3) ───
printf '\nTest 11: Empty JSON from pipe does not silently restore\n'

BUG3_DIR="$TMPDIR/bug3-test"
mkdir -p "$BUG3_DIR/.claude/.simplify-ignore-cache"
BUG3_CACHE="$BUG3_DIR/.claude/.simplify-ignore-cache"
BUG3_ID="testfile12345678"
printf 'original content\n' > "$BUG3_DIR/target.js"
cp "$BUG3_DIR/target.js" "$BUG3_CACHE/${BUG3_ID}.bak"
printf '%s' "$BUG3_DIR/target.js" > "$BUG3_CACHE/${BUG3_ID}.path"
printf 'model changed this\n' > "$BUG3_DIR/target.js"

bug3_stderr=$(echo '{}' | CLAUDE_PROJECT_DIR="$BUG3_DIR" bash hooks/simplify-ignore.sh 2>&1) || true
bug3_content=$(cat "$BUG3_DIR/target.js")
assert_eq "empty JSON from pipe does not revert file" "model changed this" "$bug3_content"
assert_eq "warning emitted for empty tool_name from pipe" "1" \
  "$(printf '%s' "$bug3_stderr" | grep -c 'Warning.*empty tool_name')"

# ── Test 12: Piped Stop event restores correctly ────────────────────────
printf '\nTest 12: Piped Stop event restores correctly\n'

STOP_DIR="$TMPDIR/stop-test"
mkdir -p "$STOP_DIR/.claude/.simplify-ignore-cache"
STOP_CACHE="$STOP_DIR/.claude/.simplify-ignore-cache"
STOP_ID="testfile78901234"
printf 'original content\n' > "$STOP_DIR/target.js"
cp "$STOP_DIR/target.js" "$STOP_CACHE/${STOP_ID}.bak"
printf '%s' "$STOP_DIR/target.js" > "$STOP_CACHE/${STOP_ID}.path"
printf 'BLOCK_deadbeef placeholder\n' > "$STOP_DIR/target.js"
mkdir -p "$STOP_CACHE/${STOP_ID}.lock"

echo '{"hook_event_name":"Stop","stop_reason":"end_turn"}' \
  | CLAUDE_PROJECT_DIR="$STOP_DIR" bash hooks/simplify-ignore.sh 2>/dev/null
stop_content=$(cat "$STOP_DIR/target.js")
assert_eq "stop_reason input restores file" "original content" "$stop_content"

# ── Test 13: tool_name present but file_path missing exits cleanly ──────
printf '\nTest 13: tool_name present but file_path missing\n'

PART_DIR="$TMPDIR/partial-test"
mkdir -p "$PART_DIR/.claude/.simplify-ignore-cache"
PART_CACHE="$PART_DIR/.claude/.simplify-ignore-cache"
PART_ID="testfiledef01234"
printf 'original\n' > "$PART_DIR/target.js"
cp "$PART_DIR/target.js" "$PART_CACHE/${PART_ID}.bak"
printf '%s' "$PART_DIR/target.js" > "$PART_CACHE/${PART_ID}.path"
printf 'model work\n' > "$PART_DIR/target.js"

rc=0
echo '{"hook_event_name":"PreToolUse","tool_name":"Read"}' \
  | CLAUDE_PROJECT_DIR="$PART_DIR" bash hooks/simplify-ignore.sh 2>/dev/null || rc=$?
part_content=$(cat "$PART_DIR/target.js")
assert_eq "missing file_path exits without restore" "model work" "$part_content"
assert_eq "exit code 0" "0" "$rc"

# ── Test 14: Single-line block hash computed exactly once (Bug 1) ───────
printf '\nTest 14: Single-line block hash unique count\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/hash-once.js"
DEST="$TMPDIR/hash-once-filtered.js"
cat > "$SRC" <<'EOF'
/* simplify-ignore-start */ secret(); /* simplify-ignore-end */
EOF

FID="test_hash_once"
filter_file "$SRC" "$DEST" "$FID"

block_files=$(ls "$CACHE/${FID}".block.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "single-line: exactly one block file (hash computed once)" "1" "$block_files"

placeholder_lines=$(grep -c 'BLOCK_' "$DEST")
assert_eq "single-line: exactly one placeholder line (no double-write)" "1" "$placeholder_lines"

output_lines=$(wc -l < "$DEST" | tr -d ' ')
assert_eq "single-line: output line count matches" "1" "$output_lines"

# ── Summary ──────────────────────────────────────────────────────────────
printf '\n══════════════════════════════════════════\n'
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
