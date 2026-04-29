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

# ---------- pinned versions (v2.9 hardening, M1 from GATE 3 audit) ----------
# graphify: PyPI version pin only — uv/pipx do not expose hash-pinning
# ergonomically; we trust PyPI's TLS + signed-distribution chain. See ADR-0007
# § Asymmetric trust posture for the rationale.
# Source: https://pypi.org/project/graphifyy/0.5.4/ (verified 2026-04-29)
GRAPHIFY_PIN="0.5.4"

# codebase-memory-mcp: full release-asset pin + SHA-256 verification against
# the release's checksums.txt. The release tag below points at an immutable
# GitHub Release; the binary is downloaded directly (skipping install.sh, which
# is not a release asset and lives on a mutable branch).
# Source: https://github.com/DeusData/codebase-memory-mcp/releases/tag/v0.6.0 (verified 2026-04-29)
CBM_PIN_TAG="v0.6.0"

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

# Map (uname -s, uname -m) to the codebase-memory-mcp release-asset platform
# tag. Returns empty string on unsupported platforms.
detect_platform_tag() {
  local os arch
  case "$(uname -s 2>/dev/null)" in
    Linux*)                 os="linux" ;;
    Darwin*)                os="darwin" ;;
    MINGW*|MSYS*|CYGWIN*)   os="windows" ;;
    *) return ;;
  esac
  case "$(uname -m 2>/dev/null)" in
    x86_64|amd64)           arch="amd64" ;;
    aarch64|arm64)          arch="arm64" ;;
    *) return ;;
  esac
  # Windows release ships only amd64.
  if [[ "$os" == "windows" && "$arch" != "amd64" ]]; then
    return
  fi
  echo "${os}-${arch}"
}

# Compute SHA-256 of a file using whichever tool is available. Returns the hex
# digest on stdout. Empty stdout on failure.
sha256_of() {
  local f="$1"
  if   have sha256sum;  then sha256sum "$f" | awk '{print $1}'
  elif have shasum;     then shasum -a 256 "$f" | awk '{print $1}'
  elif have certutil;   then certutil -hashfile "$f" SHA256 | awk 'NR==2 {print $1}' | tr -d '\r '
  fi
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
  log "Using: $installer (action: $action; pinned to graphifyy==$GRAPHIFY_PIN)"

  # Version-pinned install. Hash-pinning at the PyPI layer is intentionally NOT
  # done here (uv tool / pipx do not expose --require-hashes ergonomically and
  # adding a separate requirements.txt is more surface than the value warrants).
  # PyPI's TLS + signed-distribution chain is the implicit trust anchor for this
  # engine. See ADR-0007 § Asymmetric trust posture.
  # uv tool uses different verb for upgrade
  if [[ "$installer" == "uv tool install" && "$action" == "upgrade" ]]; then
    if ! uv tool upgrade "graphifyy==$GRAPHIFY_PIN"; then
      err "graphify upgrade failed"
      GRAPHIFY_STATUS="BROKEN"
      return
    fi
  else
    # shellcheck disable=SC2086
    if ! $installer "graphifyy==$GRAPHIFY_PIN" 2>&1 | sed 's/^/    /'; then
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
    # v2.9 hardening (M1 from GATE 3 audit, v2.8): instead of fetching install.sh
    # from a mutable branch and executing it, we download the platform-specific
    # binary tarball directly from the pinned GitHub Release and verify it against
    # the release's signed checksums.txt. This eliminates install.sh as a trust
    # surface entirely. Source: https://github.com/DeusData/codebase-memory-mcp/releases/tag/v0.6.0
    # (verified 2026-04-29, codebase-memory-mcp@0.6.0).
    local rc=0
    local arch_tag asset_name install_dir extracted_bin
    arch_tag="$(detect_platform_tag)"
    if [[ -z "$arch_tag" ]]; then
      err "could not detect a supported platform (uname -s = $(uname -s), uname -m = $(uname -m))"
      err "supported: darwin-amd64, darwin-arm64, linux-amd64, linux-arm64, windows-amd64"
      CBM_STATUS="MISSING"
      return
    fi
    if [[ "$arch_tag" == "windows-amd64" ]]; then
      asset_name="codebase-memory-mcp-${arch_tag}.zip"
    else
      asset_name="codebase-memory-mcp-${arch_tag}.tar.gz"
    fi
    log "Platform: $arch_tag → asset: $asset_name"

    local download_dir
    download_dir="$(mktemp -d 2>/dev/null || mktemp -d -t cbm-dl)"
    trap 'rm -rf "$download_dir"' RETURN

    log "Downloading release asset (pinned to $CBM_PIN_TAG)..."
    if ! curl -fsSL \
      "https://github.com/DeusData/codebase-memory-mcp/releases/download/${CBM_PIN_TAG}/${asset_name}" \
      -o "$download_dir/$asset_name"; then
      err "failed to download $asset_name"
      CBM_STATUS="MISSING"
      return
    fi
    if ! curl -fsSL \
      "https://github.com/DeusData/codebase-memory-mcp/releases/download/${CBM_PIN_TAG}/checksums.txt" \
      -o "$download_dir/checksums.txt"; then
      err "failed to download checksums.txt"
      CBM_STATUS="MISSING"
      return
    fi

    log "Verifying SHA-256 against release checksums.txt..."
    local actual expected
    actual="$(sha256_of "$download_dir/$asset_name")"
    expected="$(awk -v name="$asset_name" '$2 == name {print $1}' "$download_dir/checksums.txt")"
    if [[ -z "$expected" ]]; then
      err "checksums.txt does not list $asset_name"
      CBM_STATUS="BROKEN"
      return
    fi
    if [[ "$actual" != "$expected" ]]; then
      err "SHA-256 mismatch for $asset_name"
      err "  expected: $expected"
      err "  actual:   $actual"
      err "Refusing to install. The asset may have been tampered with or the download was corrupted."
      CBM_STATUS="BROKEN"
      return
    fi
    log "✓ SHA-256 match: $actual"

    install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    log "Extracting to $install_dir ..."
    if [[ "$arch_tag" == "windows-amd64" ]]; then
      if ! unzip -q -o "$download_dir/$asset_name" -d "$download_dir/extracted"; then
        err "unzip failed"; CBM_STATUS="BROKEN"; return
      fi
      extracted_bin="$(find "$download_dir/extracted" -type f -name 'codebase-memory-mcp*.exe' | head -n1)"
    else
      if ! tar -xzf "$download_dir/$asset_name" -C "$download_dir" 2>&1 | sed 's/^/    /'; then
        err "tar extract failed"; CBM_STATUS="BROKEN"; return
      fi
      extracted_bin="$(find "$download_dir" -type f -name 'codebase-memory-mcp' -not -path "*$asset_name*" | head -n1)"
    fi
    if [[ -z "$extracted_bin" || ! -f "$extracted_bin" ]]; then
      err "extracted archive but did not find the binary"
      CBM_STATUS="BROKEN"
      return
    fi

    if [[ "$arch_tag" == "windows-amd64" ]]; then
      CBM_BINARY="$install_dir/codebase-memory-mcp.exe"
    else
      CBM_BINARY="$install_dir/codebase-memory-mcp"
    fi
    cp "$extracted_bin" "$CBM_BINARY"
    chmod +x "$CBM_BINARY" 2>/dev/null || true

    log "✓ codebase-memory-mcp installed at $CBM_BINARY"
    CBM_VERSION="$("$CBM_BINARY" --version 2>/dev/null | head -n1 | awk '{print $NF}')"

    # Reachable from PATH? Warn but do not abort — operator may need to add
    # ~/.local/bin to PATH manually. The MCP registration uses absolute path.
    if ! have codebase-memory-mcp; then
      warn "$install_dir is not on PATH; binary is at $CBM_BINARY (absolute path used for MCP registration)"
    fi
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
