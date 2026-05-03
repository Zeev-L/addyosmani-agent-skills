#!/bin/bash
# package-skills.sh — Creates or updates zip packages for skill directories.
#
# A zip is created/updated for a skill when:
#   - No zip exists yet, OR
#   - The zip contents (file list + sizes) differ from the skill directory
#     Content-based comparison: reliable on fresh git clones (no timestamp dependency)
#
# Usage:
#   bash scripts/package-skills.sh           # package all skills
#   bash scripts/package-skills.sh --check   # exit 1 if any zip is missing or stale
#   bash scripts/package-skills.sh <name>    # package one skill by directory name
#
# Output:
#   stdout — one line per skill: "created", "updated", "ok", or "MISSING"/"STALE"
#   stderr — errors only
#
# Exit codes: 0 = success (or all up-to-date in --check mode)
#             1 = error, or stale/missing zips found in --check mode

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

CHECK_ONLY=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    *) TARGET="$arg" ;;
  esac
done

# ── helpers ───────────────────────────────────────────────────────────────────

# is_stale NAME DIR ZIP
# Returns 0 (true) when the zip is missing or its contents differ from the directory.
# Extracts the zip to a temp dir and uses diff -rq for content comparison — no timestamp
# dependency and catches same-size content changes. Reliable on fresh git clones.
is_stale() {
  local name="$1" dir="$2" zip="$3"
  [ ! -f "$zip" ] && return 0  # missing → stale

  local tmpdir
  tmpdir=$(mktemp -d) || {
    printf 'package-skills: mktemp -d failed; cannot compare zip contents\n' >&2
    return 0  # conservative: treat as stale so --check fails visibly
  }

  if unzip -q "$zip" -d "$tmpdir" 2>/dev/null; then
    if diff -rq -x '.DS_Store' -x '__pycache__' -x '.git' \
         "$dir" "$tmpdir/$name" > /dev/null 2>&1; then
      # Identical content — not stale (return 1 = false)
      rm -rf "$tmpdir"
      return 1
    fi
  fi

  # Contents differ or unzip failed → stale (return 0 = true)
  rm -rf "$tmpdir"
  return 0
}

# build_zip NAME ZIP
# Always rebuilds the zip from scratch using a temp file, then atomically replaces ZIP.
# Guarantees deleted skill files are never retained in the published archive.
build_zip() {
  local name="$1" zip="$2"
  local tmpzip
  tmpzip=$(mktemp "${zip}.XXXXXX")
  if (cd "$SKILLS_DIR" && zip -r "$tmpzip" "$name/" \
        -x '*.DS_Store' -x '*/__pycache__/*' -x '*/.git/*' > /dev/null); then
    mv "$tmpzip" "$zip"
  else
    rm -f "$tmpzip"
    return 1
  fi
}

package_skill() {
  local name="$1"
  local dir="$SKILLS_DIR/$name"
  local zip="$SKILLS_DIR/$name.zip"

  if [ ! -d "$dir" ]; then
    printf 'ERROR: %s is not a directory\n' "$dir" >&2
    return 1
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ ! -f "$zip" ]; then
      printf 'MISSING  %s.zip\n' "$name"
      return 1
    elif is_stale "$name" "$dir" "$zip"; then
      printf 'STALE    %s.zip\n' "$name"
      return 1
    else
      printf 'ok       %s.zip\n' "$name"
      return 0
    fi
  fi

  if [ ! -f "$zip" ]; then
    build_zip "$name" "$zip"
    printf 'created  %s.zip\n' "$name"
  elif is_stale "$name" "$dir" "$zip"; then
    build_zip "$name" "$zip"
    printf 'updated  %s.zip\n' "$name"
  else
    printf 'ok       %s.zip\n' "$name"
  fi
}

# ── main ──────────────────────────────────────────────────────────────────────

status=0

if [ -n "$TARGET" ]; then
  package_skill "$TARGET" || status=1
else
  while IFS= read -r dir; do
    name="$(basename "$dir")"
    package_skill "$name" || status=1
  done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)

  # In --check mode, also flag orphaned zips (skill directory deleted but zip not removed)
  if [ "$CHECK_ONLY" -eq 1 ]; then
    while IFS= read -r zip; do
      name="$(basename "$zip" .zip)"
      if [ ! -d "$SKILLS_DIR/$name" ]; then
        printf 'ORPHAN   %s.zip\n' "$name"
        status=1
      fi
    done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -name "*.zip" -type f | sort)
  fi
fi

if [ "$CHECK_ONLY" -eq 1 ] && [ "$status" -ne 0 ]; then
  printf '\nRun: bash scripts/package-skills.sh  to regenerate missing/stale zips.\n' >&2
fi

exit "$status"
