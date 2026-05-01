#!/bin/bash
# agent-skills session start hook
# Injects the using-agent-skills meta-skill into every new session, then
# loads KB context from the operator's Obsidian vault when .claude/kb-config.json
# is present in the current working directory.
#
# Output: a single JSON object { "priority": "...", "message": "..." } consumed
# by Claude Code's SessionStart hook protocol.
#
# Fail-soft contract: any error is logged to .claude/kb-debug.log and the hook
# exits 0. A broken hook must never block a session start.

set +e
trap 'exit 0' ERR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
META_SKILL="$SKILLS_DIR/using-agent-skills/SKILL.md"

# ---------------------------------------------------------------------------
# Part 1 — meta-skill content (always injected)
# ---------------------------------------------------------------------------
meta_content=""
if [ -f "$META_SKILL" ]; then
  meta_content=$(cat "$META_SKILL" 2>/dev/null)
fi

# ---------------------------------------------------------------------------
# Part 2 — KB context block (injected only when kb-config.json is present)
# ---------------------------------------------------------------------------
kb_block=""

# Resolve repo root so the hook works regardless of cwd within the repo.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
config_file="${repo_root}/.claude/kb-config.json"
debug_log="${repo_root}/.claude/kb-debug.log"

_log() {
  # Append a timestamped line to the debug log. Swallows errors so the
  # log write itself never aborts the hook.
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $1" >> "$debug_log" 2>/dev/null || true
}

if [[ -z "$repo_root" ]]; then
  # Not inside a git repo — skip KB context silently.
  kb_block=""
elif [[ ! -f "$config_file" ]]; then
  # No kb-config.json: leave a soft hint but don't auto-trigger hygiene.
  # The CLAUDE.md auto-trigger rule covers that case when the operator starts work.
  kb_block="KB context: .claude/kb-config.json not found in this repo. If this is a Batuta project, consider running batuta-project-hygiene to set up vault integration."
else
  # ------------------------------------------------------------------
  # Parse kb-config.json (jq required; fall back to python3 if absent)
  # ------------------------------------------------------------------
  if command -v jq >/dev/null 2>&1; then
    enabled=$(jq -r '.enabled // false' "$config_file" 2>/dev/null)
    client=$(jq -r '.client // ""' "$config_file" 2>/dev/null)
    project=$(jq -r '.project // ""' "$config_file" 2>/dev/null)
    vault_root=$(jq -r '.vault_root // ""' "$config_file" 2>/dev/null)
  elif command -v python3 >/dev/null 2>&1; then
    # Pass config path via env var (NEVER interpolate into -c) — repo paths
    # may contain quotes/spaces and would otherwise inject into the script.
    parsed=$(KB_CFG="$config_file" python3 -c '
import json, os, sys
try:
    d = json.load(open(os.environ["KB_CFG"]))
except Exception:
    print("false||||")
    sys.exit(0)
print("{}|{}|{}|{}".format(
    str(d.get("enabled", False)).lower(),
    d.get("client", ""),
    d.get("project", ""),
    d.get("vault_root", ""),
))
' 2>/dev/null)
    enabled="${parsed%%|*}"
    rest="${parsed#*|}"
    client="${rest%%|*}"
    rest="${rest#*|}"
    project="${rest%%|*}"
    vault_root="${rest#*|}"
  else
    _log "WARN session-start-kb: neither jq nor python3 found; skipping KB context"
    enabled="false"
  fi

  if [[ "$enabled" != "true" ]]; then
    _log "INFO session-start-kb: kb-config.json has enabled=false; skipping KB context"
    kb_block="KB context: disabled (kb-config.json enabled=false)."
  elif [[ -z "$client" || -z "$project" ]]; then
    _log "WARN session-start-kb: client or project empty in $config_file"
    kb_block="KB context: kb-config.json is missing client or project fields."
  else
    # ----------------------------------------------------------------
    # Resolve vault_root: project config → ~/.claude/kb-vault.json → $KB_VAULT_ROOT
    # ----------------------------------------------------------------
    global_vault_file="${HOME}/.claude/kb-vault.json"

    # Detect template/empty values that should not be used as-is.
    vault_root_is_template=false
    [[ "$vault_root" == *'${'* || "$vault_root" == "~/batuta-kb" || -z "$vault_root" ]] \
      && vault_root_is_template=true

    if $vault_root_is_template; then
      # Try global config first.
      if [[ -f "$global_vault_file" ]] && command -v jq >/dev/null 2>&1; then
        global_vault=$(jq -r '.vault_root // ""' "$global_vault_file" 2>/dev/null)
        [[ -n "$global_vault" ]] && vault_root="$global_vault"
      fi
      # Then env var.
      [[ -z "$vault_root" && -n "$KB_VAULT_ROOT" ]] && vault_root="$KB_VAULT_ROOT"
    fi

    # Expand leading tilde.
    vault_root_expanded="${vault_root/#\~/$HOME}"

    # ----------------------------------------------------------------
    # Build context block from vault files (all reads are best-effort)
    # ----------------------------------------------------------------
    context_lines=()

    if [[ ! -d "$vault_root_expanded" ]]; then
      _log "WARN session-start-kb: vault_root not reachable: $vault_root_expanded"
      kb_block="KB context: vault not reachable (${vault_root_expanded}). Proceeding without vault data."
    else
      client_dir="$vault_root_expanded/clients/$client"
      project_dir="$client_dir/projects/$project"

      context_lines+=("KB context loaded for client=$client project=$project")
      context_lines+=("Vault: $vault_root_expanded")
      context_lines+=("")

      # --- Client metadata ---
      client_meta="$client_dir/_metadata.md"
      if [[ -f "$client_meta" ]]; then
        context_lines+=("## Client metadata (${client}/_metadata.md)")
        # Read first 30 lines to keep the hook fast (< 500ms budget).
        while IFS= read -r line; do
          context_lines+=("$line")
        done < <(head -30 "$client_meta" 2>/dev/null)
        context_lines+=("")
      fi

      # --- Project status ---
      project_status="$project_dir/_status.md"
      if [[ -f "$project_status" ]]; then
        context_lines+=("## Project status (${client}/projects/${project}/_status.md)")
        while IFS= read -r line; do
          context_lines+=("$line")
        done < <(head -40 "$project_status" 2>/dev/null)
        context_lines+=("")
      fi

      # --- Last 3 vault session journals (date-sorted desc) ---
      # Initialize before the conditional so the array is defined regardless
      # of whether the sessions directory exists (used in _log at end of block).
      recent_sessions=()
      sessions_dir="$project_dir/sessions"
      if [[ -d "$sessions_dir" ]]; then
        mapfile -t recent_sessions < <(ls -t "$sessions_dir"/*.md 2>/dev/null | head -3)
        if [[ ${#recent_sessions[@]} -gt 0 ]]; then
          context_lines+=("## Recent vault sessions (last ${#recent_sessions[@]})")
          for sfile in "${recent_sessions[@]}"; do
            context_lines+=("### $(basename "$sfile")")
            while IFS= read -r line; do
              context_lines+=("$line")
            done < <(head -30 "$sfile" 2>/dev/null)
            context_lines+=("")
          done
        fi
      fi

      # --- Active plan from repo ---
      active_plan_dir="$repo_root/docs/plans/active"
      if [[ -d "$active_plan_dir" ]]; then
        active_plan=$(ls -t "$active_plan_dir"/*.md 2>/dev/null | head -1)
        if [[ -n "$active_plan" ]]; then
          context_lines+=("## Active plan: docs/plans/active/$(basename "$active_plan")")
          while IFS= read -r line; do
            context_lines+=("$line")
          done < <(head -60 "$active_plan" 2>/dev/null)
          context_lines+=("")
        else
          context_lines+=("## Active plan: none (docs/plans/active/ is empty)")
        fi
      fi

      # --- Most recent repo session journal ---
      repo_sessions_dir="$repo_root/docs/sessions"
      if [[ -d "$repo_sessions_dir" ]]; then
        last_repo_session=$(ls -t "$repo_sessions_dir"/*.md 2>/dev/null | head -1)
        if [[ -n "$last_repo_session" ]]; then
          context_lines+=("## Last repo session journal: docs/sessions/$(basename "$last_repo_session")")
          while IFS= read -r line; do
            context_lines+=("$line")
          done < <(head -40 "$last_repo_session" 2>/dev/null)
          context_lines+=("")
        fi
      fi

      # Join lines into a single string and cap total length.
      # Vault files are an untrusted-ish source (anyone with write access to the
      # vault — including a malicious sync, a poisoned plugin, or a compromised
      # post-commit hook — can inject text into the operator's session context).
      # The cap (4000 chars / ~150 lines) limits how much vault-sourced content
      # lands in the session prompt. The threat is documented but not eliminated:
      # the operator should treat vault content as informational, never instructional.
      kb_block=$(printf '%s\n' "${context_lines[@]}")
      max_len=4000
      if [[ ${#kb_block} -gt $max_len ]]; then
        kb_block="${kb_block:0:$max_len}

[...truncated by session-start-kb at $max_len chars to limit vault-sourced context size]"
        _log "INFO session-start-kb: kb_block truncated at $max_len chars (full size: ${#kb_block})"
      fi

      _log "OK session-start-kb: context loaded for $client/$project (vault sessions: ${#recent_sessions[@]}, kb_block: ${#kb_block} chars)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Part 3 — Assemble the final message and emit JSON
# ---------------------------------------------------------------------------
# The message combines the meta-skill content and the KB context block.
# We use jq to build the JSON so that special characters (quotes, backslashes,
# newlines) in both components are safely escaped.

if command -v jq >/dev/null 2>&1; then
  final_message=$(jq -n \
    --arg meta "$meta_content" \
    --arg kb "$kb_block" \
    '($meta) + (if $kb != "" then "\n\n---\n\n" + $kb else "" end)' \
    2>/dev/null)
  # jq -n outputs a quoted JSON string; we embed it directly in the output object.
  if [[ -n "$final_message" ]]; then
    echo "{\"priority\": \"IMPORTANT\", \"message\": $final_message}"
  else
    # jq failed for some reason — fall back to meta-skill only, plain output.
    echo '{"priority": "IMPORTANT", "message": "agent-skills loaded (KB context unavailable — jq assembly failed)."}'
  fi
else
  # No jq: emit a minimal valid response so the session is not broken.
  if [[ -n "$meta_content" ]]; then
    # python3 can safely encode the JSON string. We pass values via environment
    # variables (NEVER via string interpolation in -c) to avoid code-injection
    # vectors when vault content contains quotes/backticks/triple-quotes.
    if command -v python3 >/dev/null 2>&1; then
      final_message=$(KB_META_PATH="$META_SKILL" KB_BLOCK="$kb_block" python3 -c '
import json, os, sys
meta_path = os.environ.get("KB_META_PATH", "")
kb        = os.environ.get("KB_BLOCK", "")
try:
    meta = open(meta_path).read() if meta_path and os.path.isfile(meta_path) else ""
except Exception:
    meta = ""
msg  = meta + ("\n\n---\n\n" + kb if kb else "")
print(json.dumps(msg))
' 2>/dev/null)
      if [[ -n "$final_message" ]]; then
        echo "{\"priority\": \"IMPORTANT\", \"message\": $final_message}"
      else
        echo '{"priority": "IMPORTANT", "message": "agent-skills loaded (KB context unavailable)."}'
      fi
    else
      echo '{"priority": "IMPORTANT", "message": "agent-skills loaded (jq and python3 unavailable; KB context skipped)."}'
    fi
  else
    echo '{"priority": "INFO", "message": "agent-skills: using-agent-skills meta-skill not found. Skills may still be available individually."}'
  fi
fi
