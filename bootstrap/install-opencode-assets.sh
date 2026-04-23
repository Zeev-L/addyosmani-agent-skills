#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: install-opencode-assets.sh <github-repo-url> [ref] [--force] [--dry-run] [--target-dir DIR]

Examples:
  sh install-opencode-assets.sh https://github.com/example/agent-skills-opencode
  sh install-opencode-assets.sh https://github.com/example/agent-skills-opencode v1.2.0 --force
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'error: missing required command: %s\n' "$1" >&2
    exit 1
  }
}

extract_repo_path() {
  printf '%s' "$1" | sed -E 's#^https?://github.com/##; s#\.git$##; s#/$##'
}

copy_tree() {
  src="$1"
  dest="$2"
  if [ "$DRY_RUN" = "1" ]; then
    printf 'Would copy %s -> %s\n' "$src" "$dest"
    return
  fi
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
}

REPO_URL=""
REF="main"
FORCE="0"
DRY_RUN="0"
TARGET_DIR="$(pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      FORCE="1"
      shift
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -z "$REPO_URL" ]; then
        REPO_URL="$1"
      elif [ "$REF" = "main" ]; then
        REF="$1"
      else
        printf 'error: unexpected argument: %s\n' "$1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$REPO_URL" ]; then
  usage >&2
  exit 1
fi

require_cmd curl
require_cmd tar
require_cmd mktemp
require_cmd cp
require_cmd rm

REPO_PATH="$(extract_repo_path "$REPO_URL")"
ARCHIVE_URL="https://codeload.github.com/${REPO_PATH}/tar.gz/${REF}"

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t opencode-assets)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

ARCHIVE_PATH="$TMP_DIR/archive.tar.gz"
printf 'Downloading %s at ref %s\n' "$REPO_PATH" "$REF"
curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

EXTRACTED_ROOT="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [ ! -d "$EXTRACTED_ROOT/.opencode" ]; then
  printf 'error: extracted repository does not contain .opencode/\n' >&2
  exit 1
fi

cd "$TARGET_DIR"

for dest in .opencode/commands .opencode/skills .opencode/agents .opencode/references; do
  if [ -e "$dest" ] && [ "$FORCE" != "1" ]; then
    printf 'error: target path exists: %s (use --force to overwrite)\n' "$dest" >&2
    exit 1
  fi
  if [ -e "$dest" ] && [ "$FORCE" = "1" ] && [ "$DRY_RUN" != "1" ]; then
    rm -rf "$dest"
  fi
done

copy_tree "$EXTRACTED_ROOT/.opencode/commands" ".opencode/commands"
copy_tree "$EXTRACTED_ROOT/.opencode/skills" ".opencode/skills"
copy_tree "$EXTRACTED_ROOT/.opencode/agents" ".opencode/agents"
copy_tree "$EXTRACTED_ROOT/.opencode/references" ".opencode/references"

MANIFEST_PATH=".opencode-vendor.json"
MANIFEST_CONTENT=$(cat <<EOF
{
  "source": "$REPO_URL",
  "ref": "$REF",
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "paths": [
    ".opencode/commands",
    ".opencode/skills",
    ".opencode/agents",
    ".opencode/references"
  ]
}
EOF
)

if [ "$DRY_RUN" = "1" ]; then
  printf 'Would write %s\n' "$MANIFEST_PATH"
else
  printf '%s\n' "$MANIFEST_CONTENT" > "$MANIFEST_PATH"
fi

printf '\nInstalled shared OpenCode assets into %s\n' "$TARGET_DIR"
printf 'Review your local AGENTS.md and merge any project-specific instructions manually.\n'
printf 'Re-run this script with --force to refresh the vendored assets.\n'
