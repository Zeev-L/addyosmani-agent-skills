#!/usr/bin/env bash
# setup-code-graph.sh — bootstrap the dual code-knowledge-graph stack:
#   1) graphify  (CLI, multimodal — primary engine)
#   2) codebase-memory-mcp  (MCP server, code-only — fallback engine)
#
# Operator-side: this script is invoked by the operator (or by setup-rules.sh --all,
# or by batuta-project-hygiene mode=project-init|project-retrofit). It is NEVER
# invoked from inside a Claude tool call. Therefore it does not pass through the
# delegation-guard.sh PreToolUse hook and may freely write to the operator's PATH
# and to ~/.claude.json (via `claude mcp add`). It MUST NOT touch
# .claude/settings.json — that path is reserved for the v2.7 kill-switch.
#
# Idempotent: re-running is safe and quick.
#
# Source: https://github.com/safishamsi/graphify (verified 2026-04-29, graphifyy@0.5.4)
# Source: https://github.com/DeusData/codebase-memory-mcp (verified 2026-04-29, codebase-memory-mcp@0.6.0)
# Source: https://code.claude.com/docs/en/mcp (verified 2026-04-29, claude mcp add semantics)

# NOTE on `set -uo pipefail` (no `-e`): this script tracks per-engine status
# (graphify and codebase-memory-mcp) and intentionally continues on partial failure
# so the operator gets the most-functional configuration possible. Replacing with
# `set -euo pipefail` would abort the second engine install whenever the first
# fails — exactly the opposite of what we want for a fallback architecture.
set -uo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "ERROR: this script requires bash >= 4 (current: $BASH_VERSION)." >&2
  echo "  macOS users: brew install bash; then invoke as /opt/homebrew/bin/bash $0" >&2
  exit 5
fi

# ---------- platform detection ----------
OS="$(uname -s 2>/dev/null || echo unknown)"
IS_WINDOWS=false
[[ "$OS" == MINGW* || "$OS" == MSYS* || "$OS" == CYGWIN* ]] && IS_WINDOWS=true

# ---------- flags ----------
UPGRADE=false
SKIP_GRAPHIFY=false
SKIP_CBM=false
for arg in "$@"; do
  case "$arg" in
    --upgrade)        UPGRADE=true ;;
    --skip-graphify)  SKIP_GRAPHIFY=true ;;
    --skip-cbm)       SKIP_CBM=true ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0 ;;
    *)
      echo "Usage: $0 [--upgrade] [--skip-graphify] [--skip-cbm]" >&2
      exit 1 ;;
  esac
done

# ---------- state ----------
STATE_DIR="$HOME/.claude"
STATE_FILE="$STATE_DIR/code-graph-engines.json"
mkdir -p "$STATE_DIR"

GRAPHIFY_STATUS="MISSING"
GRAPHIFY_VERSION=""
CBM_STATUS="MISSING"
CBM_VERSION=""
CBM_BINARY=""

# ---------- helpers ----------
have() { command -v "$1" >/dev/null 2>&1; }

log()  { printf "  %s\n" "$1"; }
warn() { printf "  WARN: %s\n" "$1" >&2; }
err()  { printf "  ERROR: %s\n" "$1" >&2; }

semver_ge() {
  # semver_ge "0.5.4" "0.5.4" → true ; "0.5.3" "0.5.4" → false
  # Crude but enough for x.y.z. Strips leading 'v' and any non-numeric suffix.
  local a b
  a="${1#v}"; b="${2#v}"
  a="${a%%[!0-9.]*}"; b="${b%%[!0-9.]*}"
  printf '%s\n%s\n' "$b" "$a" | sort -V -C
}

# ---------- block 1: graphify ----------
install_graphify() {
  if $SKIP_GRAPHIFY; then
    log "graphify install skipped (--skip-graphify)"
    return
  fi
  echo ""
  echo "[1/2] graphify (multimodal code knowledge graph, primary engine)"

  if have graphify && ! $UPGRADE; then
    GRAPHIFY_VERSION="$(graphify --version 2>/dev/null | head -n1 | awk '{print $NF}')"
    if [[ -n "$GRAPHIFY_VERSION" ]] && semver_ge "$GRAPHIFY_VERSION" "0.5.4"; then
      GRAPHIFY_STATUS="OK"
      log "✓ graphify $GRAPHIFY_VERSION already installed"
      return
    fi
  fi

  local installer=""
  if   have uv;    then installer="uv tool install"
  elif have pipx;  then installer="pipx install"
  elif have pip;   then installer="pip install --user"
  elif have pip3;  then installer="pip3 install --user"
  fi

  if [[ -z "$installer" ]]; then
    if $IS_WINDOWS; then
      err "no Python installer found (uv/pipx/pip). Install uv first:"
      err "  powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\""
    else
      err "no Python installer found (uv/pipx/pip). Install uv first:"
      err "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi
    GRAPHIFY_STATUS="MISSING"
    return
  fi

  local action="install"
  $UPGRADE && have graphify && action="upgrade"
  log "Using: $installer (action: $action)"

  # uv tool uses different verb for upgrade
  if [[ "$installer" == "uv tool install" && "$action" == "upgrade" ]]; then
    if ! uv tool upgrade graphifyy; then
      err "graphify upgrade failed"
      GRAPHIFY_STATUS="BROKEN"
      return
    fi
  else
    # shellcheck disable=SC2086
    if ! $installer graphifyy 2>&1 | sed 's/^/    /'; then
      err "graphify install failed"
      GRAPHIFY_STATUS="BROKEN"
      return
    fi
  fi

  # Smoke test post-install
  if ! have graphify; then
    if $IS_WINDOWS; then
      warn "graphify installed but not in PATH (Windows). Open a new shell or check ~/.local/bin"
    else
      warn "graphify installed but not in PATH. Open a new shell or check ~/.local/bin"
    fi
    GRAPHIFY_STATUS="BROKEN"
    return
  fi

  GRAPHIFY_VERSION="$(graphify --version 2>/dev/null | head -n1 | awk '{print $NF}')"
  if [[ -z "$GRAPHIFY_VERSION" ]]; then
    # Known issue on Windows: install completes but `graphify --version` fails.
    # See https://github.com/safishamsi/graphify/issues/378 (verified 2026-04-29).
    if $IS_WINDOWS; then
      warn "graphify CLI present but '--version' failed (likely safishamsi/graphify#378)"
      warn "Marking graphify=BROKEN; codebase-memory-mcp will be the active engine"
    else
      warn "graphify CLI present but '--version' failed"
    fi
    GRAPHIFY_STATUS="BROKEN"
    return
  fi

  GRAPHIFY_STATUS="OK"
  log "✓ graphify $GRAPHIFY_VERSION ready"
}

# ---------- block 2: codebase-memory-mcp ----------
install_cbm() {
  if $SKIP_CBM; then
    log "codebase-memory-mcp install skipped (--skip-cbm)"
    return
  fi
  echo ""
  echo "[2/2] codebase-memory-mcp (code-only knowledge graph, fallback engine)"

  if have codebase-memory-mcp && ! $UPGRADE; then
    CBM_BINARY="$(command -v codebase-memory-mcp)"
    CBM_VERSION="$(codebase-memory-mcp --version 2>/dev/null | head -n1 | awk '{print $NF}')"
    if [[ -n "$CBM_VERSION" ]] && semver_ge "$CBM_VERSION" "0.6.0"; then
      CBM_STATUS="OK"
      log "✓ codebase-memory-mcp $CBM_VERSION already installed at $CBM_BINARY"
    fi
  fi

  if [[ "$CBM_STATUS" != "OK" ]]; then
    log "Downloading official installer (with --skip-config to avoid touching agent configs)..."
    local rc=0
    if $IS_WINDOWS; then
      # Windows uses install.ps1; download to tmp and execute via powershell.exe.
      local tmp_ps1
      tmp_ps1="$(mktemp -t cbm-install-XXXXXX.ps1)"
      if ! curl -fsSL \
        "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1" \
        -o "$tmp_ps1"; then
        err "failed to download install.ps1"
        rm -f "$tmp_ps1"
        CBM_STATUS="MISSING"
        return
      fi
      if ! powershell.exe -ExecutionPolicy Bypass -File "$tmp_ps1" -SkipConfig; then
        rc=$?
      fi
      rm -f "$tmp_ps1"
    else
      # Download to temp file first, then execute. Avoids piping a streamed remote
      # script directly into bash (which leaves no audit trail and is harder to
      # interrupt mid-stream if the operator's network blips). Mirrors the Windows
      # path above. The file is deleted in all cases via trap.
      local tmp_sh
      tmp_sh="$(mktemp 2>/dev/null || mktemp -t cbm-install)"
      trap 'rm -f "$tmp_sh"' RETURN
      if ! curl -fsSL \
        "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh" \
        -o "$tmp_sh"; then
        err "failed to download install.sh"
        rm -f "$tmp_sh"
        CBM_STATUS="MISSING"
        return
      fi
      if ! bash "$tmp_sh" --skip-config; then
        rc=$?
      fi
      rm -f "$tmp_sh"
    fi

    if (( rc != 0 )); then
      err "codebase-memory-mcp installer exited $rc"
      CBM_STATUS="BROKEN"
      return
    fi

    # Re-detect after install (PATH may need a hint).
    if ! have codebase-memory-mcp; then
      # Common install locations to probe.
      for candidate in \
          "$HOME/.local/bin/codebase-memory-mcp" \
          "$HOME/.local/bin/codebase-memory-mcp.exe" \
          "$HOME/AppData/Local/codebase-memory-mcp/codebase-memory-mcp.exe" \
          "$HOME/bin/codebase-memory-mcp"; do
        if [[ -x "$candidate" ]]; then CBM_BINARY="$candidate"; break; fi
      done
      [[ -z "$CBM_BINARY" ]] && {
        err "installer succeeded but binary not found in PATH or known locations"
        err "Add the install dir to PATH and re-run, or pass --skip-cbm to skip"
        CBM_STATUS="BROKEN"
        return
      }
    else
      CBM_BINARY="$(command -v codebase-memory-mcp)"
    fi
    CBM_VERSION="$("$CBM_BINARY" --version 2>/dev/null | head -n1 | awk '{print $NF}')"
  fi

  # Register as MCP server (idempotent).
  # Source: https://code.claude.com/docs/en/mcp (verified 2026-04-29).
  if ! have claude; then
    warn "claude CLI not found; cannot register MCP server. Install Claude Code first"
    CBM_STATUS="BROKEN"
    return
  fi

  if claude mcp list 2>/dev/null | grep -q '^codebase-memory'; then
    log "✓ codebase-memory MCP server already registered"
  else
    log "Registering MCP server (scope=user, transport=stdio)..."
    if ! claude mcp add --scope user --transport stdio codebase-memory -- "$CBM_BINARY" 2>&1 | sed 's/^/    /'; then
      err "claude mcp add failed"
      CBM_STATUS="BROKEN"
      return
    fi
    log "✓ codebase-memory registered in ~/.claude.json (user scope)"
  fi

  CBM_STATUS="OK"
  log "✓ codebase-memory-mcp ${CBM_VERSION:-unknown} ready at $CBM_BINARY"
}

# ---------- block 3: persist state ----------
write_state() {
  cat > "$STATE_FILE" <<EOF
{
  "schema_version": 1,
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "platform": "$OS",
  "graphify": {
    "status": "$GRAPHIFY_STATUS",
    "version": "$GRAPHIFY_VERSION"
  },
  "codebase_memory_mcp": {
    "status": "$CBM_STATUS",
    "version": "$CBM_VERSION",
    "binary": "$CBM_BINARY"
  }
}
EOF
  log "state persisted at $STATE_FILE"
}

# ---------- run ----------
echo "setup-code-graph.sh — dual engine bootstrap"
echo "platform: $OS  |  upgrade: $UPGRADE"

install_graphify
install_cbm

echo ""
echo "[3/3] state"
write_state

echo ""
echo "Summary:"
log "graphify             = $GRAPHIFY_STATUS  (${GRAPHIFY_VERSION:-n/a})"
log "codebase-memory-mcp  = $CBM_STATUS  (${CBM_VERSION:-n/a})"

if [[ "$GRAPHIFY_STATUS" == "OK" || "$CBM_STATUS" == "OK" ]]; then
  echo ""
  echo "At least one engine is functional. The code-graph skill will pick the best available."
  exit 0
else
  echo ""
  err "BOTH engines failed. The code-graph skill will instruct re-bootstrap on next invocation."
  exit 2
fi
