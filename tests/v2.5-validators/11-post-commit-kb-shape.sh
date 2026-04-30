#!/usr/bin/env bash
# 11-post-commit-kb-shape.sh
# Static contract validator for the v3.8 post-commit-kb.sh git hook and the
# kb-resync.sh reconciliation tool. Verifies the contracts the hook must honor
# without booting a real git repo (that's the operator pilot's job).
#
# Exit 0 on all-pass, non-zero with explanatory output on first fail.

set -uo pipefail

cd "${REPO_ROOT:-$(pwd)}"

fail=0
pass=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  OK   $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL $desc"
    fail=$((fail + 1))
  fi
}

echo "[11-post-commit-kb-shape] starting"

hook="hooks/post-commit-kb.sh"
resync="tools/kb-resync.sh"

check "hooks/post-commit-kb.sh exists" "test -f $hook"
check "tools/kb-resync.sh exists" "test -f $resync"
check "post-commit-kb.sh has env-bash shebang" "head -1 $hook | grep -qE '^#!/usr/bin/env bash'"
check "kb-resync.sh has env-bash shebang" "head -1 $resync | grep -qE '^#!/usr/bin/env bash'"

# Failure mode contract: the git post-commit hook MUST never fail the commit.
# We verify the script declares set +e and a trap.
check "post-commit-kb sets set +e (never blocks commit)" "grep -qE '^set \+e' $hook"
check "post-commit-kb has ERR trap that exits 0" "grep -qE \"trap 'exit 0' ERR\" $hook"
check "post-commit-kb final line exits 0" "tail -3 $hook | grep -q '^exit 0'"

# Opt-in contract: the hook only runs when .claude/kb-config.json declares enabled:true.
check "post-commit-kb checks .claude/kb-config.json existence" "grep -q 'kb-config.json' $hook"
check "post-commit-kb reads .enabled key" "grep -qE 'jq.*\.enabled' $hook"
check "post-commit-kb requires enabled = true" "grep -qE 'enabled.*!=.*true' $hook || grep -qE '\"\$enabled\".*\"true\"' $hook"

# Idempotency: hook must skip if SHA is already in journal.
check "post-commit-kb has SHA-already-present idempotency check" "grep -qE 'grep -q .\\\$sha_abbrev. .\\\$journal' $hook"

# Rebase / cherry-pick detection (deferred to kb-resync.sh).
check "post-commit-kb skips during rebase-merge" "grep -q 'rebase-merge' $hook"
check "post-commit-kb skips during rebase-apply" "grep -q 'rebase-apply' $hook"
check "post-commit-kb skips during cherry-pick" "grep -q 'CHERRY_PICK_HEAD' $hook"

# Vault mirror contract.
check "post-commit-kb reads vault_root from config" "grep -qE 'jq.*vault_root' $hook"
check "post-commit-kb mirrors to clients/<c>/projects/<p>/sessions/" "grep -qE 'clients/.*projects/.*sessions' $hook"

# Resync tool contract.
check "kb-resync supports --since flag" "grep -qE -- '--since' $resync"
check "kb-resync supports --dry-run flag" "grep -qE -- '--dry-run' $resync"
check "kb-resync requires .claude/kb-config.json" "grep -q 'kb-config.json' $resync"
check "kb-resync uses git log --reverse" "grep -qE 'git.*log.*--reverse' $resync"
check "kb-resync skips SHAs already present" "grep -qE 'grep -q .\\\$sha_abbrev' $resync"

# Hook ordering in plugin hooks.json (post-commit-kb is NOT a Claude Code hook;
# it is a git hook installed at .git/hooks/post-commit by batuta-project-hygiene).
# So it should NOT appear in hooks/hooks.json.
check "post-commit-kb is NOT registered in hooks.json (it's a git hook, not a Claude Code hook)" "! grep -q 'post-commit-kb' hooks/hooks.json"

# batuta-project-hygiene installs the hook (step 4c).
check "batuta-project-hygiene SKILL.md mentions post-commit-kb installation" "grep -q 'post-commit-kb' skills/batuta-project-hygiene/SKILL.md"
check "batuta-project-hygiene has step 4c" "grep -qE '^4c\.|^### 4c\.' skills/batuta-project-hygiene/SKILL.md"

if [[ $fail -gt 0 ]]; then
  echo "[11-post-commit-kb-shape] FAIL — $fail check(s) failed, $pass passed"
  exit 1
fi

echo "[11-post-commit-kb-shape] PASS — $pass checks"
exit 0
