#!/usr/bin/env bash
# kb-resync.sh
# Reconciles the project's session journal with `git log` after a rebase or
# cherry-pick that the post-commit-kb.sh hook deliberately skipped.
#
# Usage: bash tools/kb-resync.sh [--since YYYY-MM-DD] [--dry-run]
#   Default scope: today's journal (date_ymd).
#
# Why: post-commit-kb.sh skips during rebase/cherry-pick because the hook fires
# per replayed commit and would write a flood of stale entries. After rebase
# completes, the operator runs this script to bring today's journal in sync
# with the actual `git log`.

set -uo pipefail

# Parse args.
since_arg=""
dry_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) since_arg="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help)
      cat <<EOF
kb-resync.sh — reconcile session journal with git log after rebase

Options:
  --since YYYY-MM-DD   Reconcile commits since this date (default: today)
  --dry-run            Print what would be added; do not modify files
  -h, --help           Show this help

Run from repo root. Requires .claude/kb-config.json (same contract as post-commit-kb.sh).
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$repo_root" ]]; then
  echo "kb-resync: not inside a git repo" >&2
  exit 1
fi

config_file="$repo_root/.claude/kb-config.json"
if [[ ! -f "$config_file" ]]; then
  echo "kb-resync: $config_file not found — nothing to do" >&2
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "kb-resync: jq required" >&2
  exit 1
fi

enabled=$(jq -r '.enabled // false' "$config_file")
if [[ "$enabled" != "true" ]]; then
  echo "kb-resync: kb-config.json has enabled=false — nothing to do" >&2
  exit 0
fi

client=$(jq -r '.client // ""' "$config_file")
project=$(jq -r '.project // ""' "$config_file")
vault_root=$(jq -r '.vault_root // ""' "$config_file")

date_ymd=$(date -u +%Y-%m-%d)
since="${since_arg:-$date_ymd}"

# Find today's (or the closest) session journal in docs/sessions/.
journal=$(ls -t "$repo_root/docs/sessions/$since"*.md 2>/dev/null | head -1)
if [[ -z "$journal" ]]; then
  echo "kb-resync: no session journal at docs/sessions/$since*.md — nothing to reconcile"
  exit 0
fi

echo "kb-resync: reconciling $journal"
echo "  since: $since"
echo "  dry-run: $dry_run"

added=0
while IFS='|' read -r sha_full sha_abbrev ts_iso subject; do
  # Skip if SHA already in the journal.
  if grep -q "$sha_abbrev" "$journal" 2>/dev/null; then
    continue
  fi

  ts_hhmm=$(date -u -d "$ts_iso" +%H:%M 2>/dev/null || echo "00:00")
  branch=$(git -C "$repo_root" branch --contains "$sha_full" 2>/dev/null | head -1 | sed 's/^[* ] //')
  files_count=$(git -C "$repo_root" diff-tree --no-commit-id --name-only -r "$sha_full" 2>/dev/null | wc -l | tr -d ' ')
  files_changed=$(git -C "$repo_root" diff-tree --no-commit-id --name-only -r "$sha_full" 2>/dev/null | head -3 | tr '\n' ',' | sed 's/,$//')

  bullet="- **${ts_hhmm} · \`${sha_abbrev}\`** · ${subject}
  - branch: \`${branch}\`
  - files: ${files_count} (\`${files_changed}\`)
  - resync: true"

  if [[ "$dry_run" == "1" ]]; then
    echo "+ would add: $sha_abbrev | $subject"
  else
    echo "$bullet" >> "$journal"
    added=$((added + 1))
  fi
done < <(git -C "$repo_root" log --since="$since 00:00" --pretty='%H|%h|%aI|%s' --reverse 2>/dev/null)

if [[ "$dry_run" == "0" ]]; then
  echo "kb-resync: added $added entries to $journal"
fi

# Mirror to vault is intentionally NOT done here — vault sync is the post-commit
# hook's job. Re-running rebase will re-fire the hook for new commits; this
# script's only job is the project-local journal reconciliation.

exit 0
