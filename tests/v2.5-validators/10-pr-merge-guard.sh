#!/usr/bin/env bash
# 10-pr-merge-guard.sh
# Validates the v3.6 pr-merge-guard hook:
#   (a) hooks/pr-merge-guard.sh exists, is executable, has the kill-switch shebang
#   (b) the hook detects 'gh pr merge' with regex (whitespace-tolerant)
#   (c) the hook respects BATUTA_ALLOW_PR_MERGE=1 env var (operator-side opt-in)
#   (d) the hook fails open on missing jq (does not lock the session)
#   (e) the hook is registered in hooks/hooks.json with matcher 'Bash'
#   (f) the block message references the env var for the operator to discover
# Contract introduced in v3.6.

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

case_name="10-pr-merge-guard"
echo "[${case_name}] starting"

HOOK="${REPO_ROOT}/hooks/pr-merge-guard.sh"
HOOKS_JSON="${REPO_ROOT}/hooks/hooks.json"

failed=0

ok()    { echo "  OK   $1"; }
miss()  { echo "  MISS $1"; failed=1; }
drift() { echo "  DRIFT $1"; failed=1; }

# --- (a) hook exists + executable + shebang ---
if [[ ! -f "$HOOK" ]]; then
  miss "hooks/pr-merge-guard.sh missing"
else
  [[ -x "$HOOK" ]] && ok "pr-merge-guard.sh is executable" || miss "pr-merge-guard.sh not executable (chmod +x)"
  head -n1 "$HOOK" | grep -qE '^#!/usr/bin/env bash' \
    && ok "pr-merge-guard.sh has env-bash shebang" \
    || miss "pr-merge-guard.sh missing '#!/usr/bin/env bash' shebang"

  # --- (b) detection regex matches 'gh pr merge' with whitespace tolerance ---
  grep -qE 'gh\[\[:space:\]\]\+pr\[\[:space:\]\]\+merge' "$HOOK" \
    && ok "pr-merge-guard.sh has whitespace-tolerant 'gh pr merge' regex" \
    || miss "pr-merge-guard.sh must match 'gh\\s+pr\\s+merge' (whitespace-tolerant)"

  # --- (c) operator-side opt-in via BATUTA_ALLOW_PR_MERGE env var ---
  grep -qE 'BATUTA_ALLOW_PR_MERGE' "$HOOK" \
    && ok "pr-merge-guard.sh references BATUTA_ALLOW_PR_MERGE env var" \
    || miss "pr-merge-guard.sh must support BATUTA_ALLOW_PR_MERGE=1 override"
  # The override path must allow (exit 0), not block.
  if grep -B1 -A4 'BATUTA_ALLOW_PR_MERGE' "$HOOK" | grep -qE 'exit 0'; then
    ok "BATUTA_ALLOW_PR_MERGE=1 path correctly allows (exit 0)"
  else
    miss "BATUTA_ALLOW_PR_MERGE=1 path must exit 0 (allow)"
  fi

  # --- (d) fail-soft on missing jq ---
  if grep -B1 -A4 'jq.*not installed\|command -v jq' "$HOOK" | grep -qE 'exit 0'; then
    ok "pr-merge-guard.sh fails soft when jq is missing (exit 0)"
  else
    miss "pr-merge-guard.sh must fail soft on missing jq (exit 0, not exit 1)"
  fi

  # --- (f) block message must teach the operator the override mechanism ---
  grep -qE 'BATUTA_ALLOW_PR_MERGE=1 claude|export BATUTA_ALLOW_PR_MERGE' "$HOOK" \
    && ok "block message instructs the operator on the env-var override" \
    || miss "block message must show the operator how to override (e.g. 'BATUTA_ALLOW_PR_MERGE=1 claude')"

  # The block path must exit 1. The heredoc starting with 'RULE violated:' runs
  # ~21 lines through the closing 'EOF', then the next line is 'exit 1'. We use
  # -A28 as a safety budget so future edits to the block message (e.g. adding
  # one or two lines) do not silently break this check. If the block message
  # grows past ~26 lines, bump this number — but more importantly, ask whether
  # the message is still actionable for the operator at that length.
  if grep -A28 'RULE violated' "$HOOK" | grep -qE '^exit 1$'; then
    ok "block path exits 1 (denies the tool call)"
  else
    miss "block path must exit 1 to deny the tool call"
  fi
fi

# --- (e) hook is registered in hooks.json with matcher 'Bash' ---
if [[ ! -f "$HOOKS_JSON" ]]; then
  miss "hooks/hooks.json missing"
else
  # Find a PreToolUse entry whose matcher is exactly "Bash" and whose command path
  # references pr-merge-guard.sh. Use jq to be robust against formatting.
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | contains("pr-merge-guard.sh"))' "$HOOKS_JSON" >/dev/null 2>&1; then
      ok "hooks.json registers pr-merge-guard.sh with matcher Bash"
    else
      miss "hooks.json must register pr-merge-guard.sh under matcher 'Bash'"
    fi
  else
    # Fallback grep: look for the matcher and the script name in proximity.
    if grep -A4 '"matcher": "Bash"' "$HOOKS_JSON" | grep -q 'pr-merge-guard.sh'; then
      ok "hooks.json registers pr-merge-guard.sh with matcher Bash (grep fallback)"
    else
      miss "hooks.json must register pr-merge-guard.sh under matcher 'Bash'"
    fi
  fi

  # Existing delegation-guard.sh registration MUST still be present (regression check).
  if grep -q 'delegation-guard.sh' "$HOOKS_JSON"; then
    ok "hooks.json still registers delegation-guard.sh (no regression)"
  else
    miss "hooks.json must continue to register delegation-guard.sh"
  fi
fi

if [[ ${failed} -eq 0 ]]; then
  echo "[${case_name}] PASS"
  exit 0
else
  echo "[${case_name}] FAIL"
  exit 1
fi
