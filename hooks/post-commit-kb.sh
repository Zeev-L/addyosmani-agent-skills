#!/usr/bin/env bash
# post-commit-kb.sh
# Git post-commit hook (NOT a Claude Code hook). Installed at .git/hooks/post-commit
# in projects that opt in via .claude/kb-config.json. Captures every accepted commit
# as a structured bullet in the project's session journal AND mirrors the bullet to
# the operator's Obsidian vault (L1).
#
# ADR-0011 D1 — automatic persistence on commit (not on Stop). The commit is the
# intentional event; Stop is too noisy.
#
# Failure mode: NEVER block the commit. Errors go to .claude/kb-debug.log; exit 0
# always. The commit is already accepted by the time this hook fires.
#
# Source: https://git-scm.com/docs/githooks#_post_commit (verified 2026-04-29, git@2.x)

# Fail-soft setup. Trap any error and exit 0.
set +e
trap 'exit 0' ERR

# Resolve the repo root from the hook's working directory (git invokes hooks with
# cwd = top of working tree).
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$repo_root" ]]; then
  exit 0
fi

config_file="$repo_root/.claude/kb-config.json"
debug_log="$repo_root/.claude/kb-debug.log"

# Opt-in gate: no config file → silent no-op.
if [[ ! -f "$config_file" ]]; then
  exit 0
fi

# jq is required for config parsing. Without it, log and exit silent.
if ! command -v jq >/dev/null 2>&1; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN post-commit-kb: jq missing, skipping" >> "$debug_log" 2>/dev/null
  exit 0
fi

enabled=$(jq -r '.enabled // false' "$config_file" 2>/dev/null)
if [[ "$enabled" != "true" ]]; then
  exit 0
fi

client=$(jq -r '.client // ""' "$config_file" 2>/dev/null)
project=$(jq -r '.project // ""' "$config_file" 2>/dev/null)
vault_root=$(jq -r '.vault_root // ""' "$config_file" 2>/dev/null)
slug_strategy=$(jq -r '.session_slug_strategy // "branch-or-plan-or-daily"' "$config_file" 2>/dev/null)

if [[ -z "$client" || -z "$project" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN post-commit-kb: client or project empty in $config_file" >> "$debug_log" 2>/dev/null
  exit 0
fi

# Rebase / cherry-pick detection: skip while in progress; reconcile via tools/kb-resync.sh.
if [[ -d "$repo_root/.git/rebase-merge" || -d "$repo_root/.git/rebase-apply" || -d "$repo_root/.git/CHERRY_PICK_HEAD" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SKIP post-commit-kb: rebase/cherry-pick in progress" >> "$debug_log" 2>/dev/null
  exit 0
fi

# Capture the last commit's metadata.
sha_full=$(git -C "$repo_root" log -1 --format='%H' 2>/dev/null)
sha_abbrev=$(git -C "$repo_root" log -1 --format='%h' 2>/dev/null)
subject=$(git -C "$repo_root" log -1 --format='%s' 2>/dev/null)
ts_iso=$(git -C "$repo_root" log -1 --format='%aI' 2>/dev/null)
ts_hhmm=$(date -u -d "$ts_iso" +%H:%M 2>/dev/null || date -u +%H:%M)
date_ymd=$(date -u -d "$ts_iso" +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)
branch=$(git -C "$repo_root" rev-parse --abbrev-ref HEAD 2>/dev/null)
files_changed=$(git -C "$repo_root" diff-tree --no-commit-id --name-only -r "$sha_full" 2>/dev/null | head -3 | tr '\n' ',' | sed 's/,$//')
files_count=$(git -C "$repo_root" diff-tree --no-commit-id --name-only -r "$sha_full" 2>/dev/null | wc -l | tr -d ' ')

# Determine session slug per strategy.
slug=""
case "$slug_strategy" in
  branch-or-plan-or-daily|*)
    case "$branch" in
      feature/*|feat/*)
        slug="${branch#feature/}"
        slug="${slug#feat/}"
        ;;
      *)
        ;;
    esac
    if [[ -z "$slug" ]]; then
      first_plan=$(ls -t "$repo_root/docs/plans/active/"*.md 2>/dev/null | head -1)
      if [[ -n "$first_plan" ]]; then
        slug=$(basename "$first_plan" .md)
        slug="${slug#$date_ymd-}"
      fi
    fi
    if [[ -z "$slug" ]]; then
      slug="daily"
    fi
    ;;
esac

# Ensure docs/sessions/ exists.
sessions_dir="$repo_root/docs/sessions"
mkdir -p "$sessions_dir" 2>/dev/null || true

journal="$sessions_dir/$date_ymd-$slug.md"
plan_link=""
first_plan=$(ls -t "$repo_root/docs/plans/active/"*.md 2>/dev/null | head -1)
if [[ -n "$first_plan" ]]; then
  plan_link="docs/plans/active/$(basename "$first_plan")"
fi

# Idempotency: if this SHA is already in today's journal, skip (handles --amend
# returning the same SHA on re-write, and accidental hook double-fires).
if [[ -f "$journal" ]] && grep -q "$sha_abbrev" "$journal" 2>/dev/null; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SKIP post-commit-kb: SHA $sha_abbrev already in $journal" >> "$debug_log" 2>/dev/null
  exit 0
fi

# Create the journal with frontmatter on first write of the day.
if [[ ! -f "$journal" ]]; then
  cat > "$journal" <<EOF
---
type: session
date: $date_ymd
client: $client
project: $project
repo: $(git -C "$repo_root" remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's|.*github.com[:/]||')
tags: [session, client/$client]
last_verified: $date_ymd
---

# Session journal — $date_ymd — $project

EOF
fi

# Append the bullet.
{
  echo "- **${ts_hhmm} · \`${sha_abbrev}\`** · ${subject}"
  echo "  - branch: \`${branch}\`"
  echo "  - files: ${files_count} (\`${files_changed}\`)"
  if [[ -n "$plan_link" ]]; then
    echo "  - plan: ${plan_link}"
  fi
} >> "$journal"

# Mirror to the vault if vault_root is configured and reachable.
if [[ -n "$vault_root" ]]; then
  vault_root_expanded="${vault_root/#\~/$HOME}"
  vault_target_dir="$vault_root_expanded/clients/$client/projects/$project/sessions"
  if [[ -d "$vault_root_expanded" ]]; then
    mkdir -p "$vault_target_dir" 2>/dev/null
    vault_journal="$vault_target_dir/$date_ymd.md"
    if [[ ! -f "$vault_journal" ]]; then
      cat > "$vault_journal" <<EOF
---
type: session
date: $date_ymd
client: $client
project: $project
tags: [session, client/$client]
last_verified: $date_ymd
---

# Session — $date_ymd — $client/$project

EOF
    fi
    if ! grep -q "$sha_abbrev" "$vault_journal" 2>/dev/null; then
      {
        echo "- **${ts_hhmm} · \`${sha_abbrev}\`** · ${subject}"
        echo "  - branch: \`${branch}\`"
        echo "  - files: ${files_count}"
      } >> "$vault_journal"
    fi
  else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARN post-commit-kb: vault_root not reachable: $vault_root_expanded" >> "$debug_log" 2>/dev/null
  fi
fi

exit 0
