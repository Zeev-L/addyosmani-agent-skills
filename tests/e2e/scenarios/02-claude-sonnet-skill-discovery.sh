#!/usr/bin/env bash
# 02-claude-sonnet-skill-discovery.sh
# E2E: launches `claude --print --model sonnet` against a sandbox and verifies
# the medium model is aware of (and willing to invoke) at least one Batuta
# plugin skill. Confirms the plugin loads correctly with sonnet as the model.
#
# Skips (exit 77) if `claude` CLI is missing or not authenticated.

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
KEEP_SANDBOX="${KEEP_SANDBOX:-false}"

if ! command -v claude >/dev/null 2>&1; then
  echo "  SKIP claude CLI not installed (PATH check)"
  exit 77
fi

# Cheap auth probe — `claude --version` works regardless of auth, so we use
# a tiny --print invocation. If it fails fast (< 5s) treat as auth issue.
if ! timeout 30 claude --print --model sonnet "say only the literal word: ready" 2>/dev/null | grep -qi 'ready'; then
  echo "  SKIP claude CLI present but a minimal sonnet invocation failed (auth / network / model availability)"
  exit 77
fi
echo "  OK   claude CLI is reachable with --model sonnet"

sandbox="$(mktemp -d 2>/dev/null || mktemp -d -t e2e-sandbox)"
cleanup() {
  if [[ "$KEEP_SANDBOX" == "true" ]]; then
    echo "  sandbox preserved at $sandbox"
  else
    rm -rf "$sandbox"
  fi
}
trap cleanup EXIT

# Initialize a minimal Python project so the project-hygiene skill could fire.
cat > "$sandbox/pyproject.toml" <<'EOF'
[project]
name = "e2e-sandbox"
version = "0.0.1"
requires-python = ">=3.10"
EOF
mkdir -p "$sandbox/src"
echo "# placeholder" > "$sandbox/src/__init__.py"

prompt="List the names (just the names, comma-separated, lowercase) of any Batuta plugin skills you have access to that start with 'batuta-' or are named 'code-graph', 'research-first-dev', or 'notion-kb-workflow'. Output ONLY the comma-separated list, nothing else."

cd "$sandbox" || exit 1
# v3.2: --plugin-dir "$REPO_ROOT" forces the local checkout to load instead of
# the marketplace-cached version (which can be stale; see tests/e2e/README.md
# § Methodology — plugin loading in --print mode).
out="$(timeout 60 claude --print --model sonnet --plugin-dir "$REPO_ROOT" "$prompt" 2>&1 || true)"
cd - >/dev/null || true

# Check that at least 2 of the expected skill names appear in the output.
expected=(batuta-project-hygiene batuta-skill-authoring batuta-agent-authoring batuta-rule-authoring code-graph research-first-dev notion-kb-workflow)
hits=0
for name in "${expected[@]}"; do
  if echo "$out" | grep -qF "$name"; then
    hits=$((hits + 1))
  fi
done

if (( hits >= 2 )); then
  echo "  OK   sonnet identifies $hits Batuta plugin skill(s)"
  echo "  PASS scenario 02"
  exit 0
else
  echo "  FAIL sonnet output mentioned only $hits expected skill(s); plugin may not be loaded"
  echo "  output:"
  echo "$out" | head -20 | sed 's/^/    /'
  exit 1
fi
