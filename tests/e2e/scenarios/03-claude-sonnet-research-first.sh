#!/usr/bin/env bash
# 03-claude-sonnet-research-first.sh
# E2E: drives `claude --print --model sonnet` against a sandbox with a
# Python project that has fastapi pinned, asks it to add a hello endpoint,
# and verifies that the resulting code contains a `# Source:` citation
# comment (the artifact of the research-first-dev skill).
#
# Skips (exit 77) if claude CLI is missing/unauth.

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
KEEP_SANDBOX="${KEEP_SANDBOX:-false}"

if ! command -v claude >/dev/null 2>&1; then
  echo "  SKIP claude CLI not installed"
  exit 77
fi
if ! timeout 30 claude --print --model sonnet "say only: ready" 2>/dev/null | grep -qi 'ready'; then
  echo "  SKIP claude --model sonnet not reachable"
  exit 77
fi

sandbox="$(mktemp -d 2>/dev/null || mktemp -d -t e2e-sandbox)"
cleanup() {
  if [[ "$KEEP_SANDBOX" == "true" ]]; then
    echo "  sandbox preserved at $sandbox"
  else
    rm -rf "$sandbox"
  fi
}
trap cleanup EXIT

cat > "$sandbox/pyproject.toml" <<'EOF'
[project]
name = "research-first-test"
version = "0.0.1"
requires-python = ">=3.10"
dependencies = ["fastapi==0.115.0"]
EOF
mkdir -p "$sandbox/src"
cat > "$sandbox/src/api.py" <<'EOF'
"""Placeholder API module."""
EOF

prompt="In src/api.py, add a FastAPI 'hello world' GET endpoint at /. Use the research-first-dev skill: include a # Source: citation comment above the FastAPI import line, with the URL of FastAPI's official docs and 'verified $(date +%Y-%m-%d), fastapi==0.115.0'. Write the file and tell me when done. Be brief in your final reply."

cd "$sandbox" || exit 1
# v3.2: --plugin-dir loads the local checkout (see tests/e2e/README.md).
out="$(timeout 180 claude --print --model sonnet --plugin-dir "$REPO_ROOT" "$prompt" 2>&1 || true)"
cd - >/dev/null || true

if [[ ! -f "$sandbox/src/api.py" ]]; then
  echo "  FAIL src/api.py is missing after the prompt"
  exit 1
fi

content="$(cat "$sandbox/src/api.py")"

# Check 1: a # Source: citation is present.
if ! echo "$content" | grep -qE '^[[:space:]]*#[[:space:]]*Source:[[:space:]]*https?://'; then
  echo "  FAIL src/api.py lacks a '# Source: <url>' citation comment"
  echo "  content:"
  echo "$content" | sed 's/^/    /'
  exit 1
fi
echo "  OK   src/api.py contains a # Source: citation comment"

# Check 2: the citation references fastapi's official docs (.tiangolo.com or fastapi.tiangolo).
if ! echo "$content" | grep -qiE 'tiangolo\.com|fastapi\.tiangolo'; then
  echo "  WARN citation does not reference the official fastapi.tiangolo.com domain"
  echo "  This is non-blocking but suggests the model used a non-official source."
fi

# Check 3: a FastAPI import is present.
if ! echo "$content" | grep -qE 'from[[:space:]]+fastapi[[:space:]]+import|import[[:space:]]+fastapi'; then
  echo "  FAIL no fastapi import found in src/api.py"
  exit 1
fi
echo "  OK   src/api.py imports from fastapi"

# Check 4: a route decorator and a function exist.
if ! echo "$content" | grep -qE '@(app|router)\.(get|post|put|delete)'; then
  echo "  FAIL no FastAPI route decorator found"
  exit 1
fi
echo "  OK   src/api.py declares a FastAPI route"

echo "  PASS scenario 03"
exit 0
