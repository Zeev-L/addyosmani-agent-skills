#!/usr/bin/env bash
# 12-kb-curate-shape.sh
# Static contract validator for the v3.8 Sprint 2 curation pipeline:
# kb-curate skill + kb-curator agent + slash commands. Verifies the contracts
# that downstream code (post-commit-kb hook output, research-first Step 1.5
# lookups) depends on.

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

echo "[12-kb-curate-shape] starting"

# Skill exists with required shape.
check "skills/kb-curate/SKILL.md exists" "test -f skills/kb-curate/SKILL.md"
check "kb-curate has frontmatter name field" "grep -qE '^name: kb-curate' skills/kb-curate/SKILL.md"
check "kb-curate description starts with Use" "grep -qE '^description: Use' skills/kb-curate/SKILL.md"
check "kb-curate body ≤ 200 lines" "test \$(wc -l < skills/kb-curate/SKILL.md) -le 200"
check "kb-curate documents 4 invocation modes" "grep -qE '/kb-curate.*--feature|--scope session|--scope week|/kb-end-session' skills/kb-curate/SKILL.md"
check "kb-curate documents 7 categories" "grep -qE 'decision-new.*decision-supersede.*gotcha-new.*gotcha-update.*playbook|7 categories' skills/kb-curate/SKILL.md"
check "kb-curate documents hybrid control matrix" "grep -qE 'matrix|Auto-apply' skills/kb-curate/SKILL.md"
check "kb-curate documents curated_into frontmatter" "grep -qE 'curated_into' skills/kb-curate/SKILL.md"
check "kb-curate has Anti-Rationalizations section" "grep -qE '^## Anti-Rationalizations' skills/kb-curate/SKILL.md"
check "kb-curate has Verification section" "grep -qE '^## Verification' skills/kb-curate/SKILL.md"

# Agent exists with required shape (per batuta-agent-authoring contract).
check "agents/kb-curator.md exists" "test -f agents/kb-curator.md"
check "kb-curator frontmatter has name" "grep -qE '^name: kb-curator' agents/kb-curator.md"
check "kb-curator frontmatter has model: sonnet" "grep -qE '^model: sonnet' agents/kb-curator.md"
check "kb-curator description ≤ 150 chars" "head -4 agents/kb-curator.md | grep description | awk -F': ' '{print length(\$2)}' | awk '\$1 <= 150 {exit 0} {exit 1}'"
check "kb-curator body ≤ 150 lines" "test \$(wc -l < agents/kb-curator.md) -le 150"
check "kb-curator has When NOT to invoke section" "grep -qE '^## When NOT to invoke' agents/kb-curator.md"
check "kb-curator declares minimal tool list" "grep -qE '^tools:' agents/kb-curator.md"
check "kb-curator returns BULLETS_CURATED literal" "grep -qE 'BULLETS_CURATED:' agents/kb-curator.md"
check "kb-curator has 7-category enum" "grep -cE '(decision-new|decision-supersede|gotcha-new|gotcha-update|playbook-candidate|glossary-entry|noise)' agents/kb-curator.md | awk '\$1 >= 7 {exit 0} {exit 1}'"
check "kb-curator has Step 0 NOT-APPLICABLE pre-flight" "grep -qE 'Pre-flight|empty.*BULLETS_CURATED: 0' agents/kb-curator.md"

# Slash commands exist.
check ".claude/commands/kb-curate.md exists" "test -f .claude/commands/kb-curate.md"
check ".claude/commands/kb-end-session.md exists" "test -f .claude/commands/kb-end-session.md"
check ".claude/commands/batuta-status.md exists" "test -f .claude/commands/batuta-status.md"
check "kb-curate.md references the skill" "grep -q 'skills/kb-curate' .claude/commands/kb-curate.md"
check "kb-end-session.md references kb-curate" "grep -q '/kb-curate' .claude/commands/kb-end-session.md"
check "batuta-status.md is read-only" "grep -qE 'Read-only|Do NOT modify' .claude/commands/batuta-status.md"

# GitHub Action template (notifier, not executor).
check ".github/workflows-templates/kb-curate-on-merge.yml exists" "test -f .github/workflows-templates/kb-curate-on-merge.yml"
check "Action labels PR with kb-curate-pending" "grep -q 'kb-curate-pending' .github/workflows-templates/kb-curate-on-merge.yml"
check "Action does NOT invoke claude (notifier only — ignore comments)" "! grep -vE '^[[:space:]]*#' .github/workflows-templates/kb-curate-on-merge.yml | grep -qE 'claude --print|claude -p'"

# Cross-references.
check "kb-curate skill references kb-curator agent" "grep -q 'kb-curator' skills/kb-curate/SKILL.md"
check "kb-curator agent references kb-curate skill" "grep -q 'kb-curate' agents/kb-curator.md"

if [[ $fail -gt 0 ]]; then
  echo "[12-kb-curate-shape] FAIL — $fail check(s) failed, $pass passed"
  exit 1
fi

echo "[12-kb-curate-shape] PASS — $pass checks"
exit 0
