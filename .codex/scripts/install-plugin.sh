#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLUGIN_TEMPLATE_ROOT="${REPO_ROOT}/.codex/plugin"
PLUGIN_MANIFEST_TEMPLATE="${PLUGIN_TEMPLATE_ROOT}/.codex-plugin/plugin.json"
WRAPPER_SYNC_SCRIPT="${REPO_ROOT}/.codex/scripts/sync-wrapper-skills.py"
PLUGIN_INSTALL_ROOT="${HOME}/.codex/plugins/agent-skills"
HOME_DIR="${HOME}"
MARKETPLACE_PATH="${HOME_DIR}/.agents/plugins/marketplace.json"
CODEX_CONFIG_PATH="${HOME_DIR}/.codex/config.toml"
TMP_FILE="$(mktemp)"
TMP_PLUGIN_DIR="$(mktemp -d)"

cleanup() {
  rm -f "${TMP_FILE}"
  if [[ -n "${TMP_PLUGIN_DIR}" ]]; then
    rm -rf "${TMP_PLUGIN_DIR}"
  fi
}

trap cleanup EXIT

echo "Checking agent-skills Codex plugin setup..." >&2

if [[ ! -f "${PLUGIN_MANIFEST_TEMPLATE}" ]]; then
  echo "Missing ${PLUGIN_MANIFEST_TEMPLATE}. Run this script from an agent-skills clone that includes Codex plugin metadata." >&2
  exit 1
fi

if [[ ! -f "${WRAPPER_SYNC_SCRIPT}" ]]; then
  echo "Missing ${WRAPPER_SYNC_SCRIPT}. Run this script from an agent-skills clone that includes the Codex helper scripts." >&2
  exit 1
fi

mkdir -p "$(dirname "${MARKETPLACE_PATH}")"
mkdir -p "$(dirname "${PLUGIN_INSTALL_ROOT}")"
mkdir -p "$(dirname "${CODEX_CONFIG_PATH}")"

echo "Building personal plugin bundle at ${PLUGIN_INSTALL_ROOT}..." >&2

mkdir -p "${TMP_PLUGIN_DIR}/.codex-plugin" "${TMP_PLUGIN_DIR}/skills"
cp "${PLUGIN_MANIFEST_TEMPLATE}" "${TMP_PLUGIN_DIR}/.codex-plugin/plugin.json"

for skill_dir in "${REPO_ROOT}"/skills/*; do
  if [[ -d "${skill_dir}" ]]; then
    cp -R "${skill_dir}" "${TMP_PLUGIN_DIR}/skills/"
  fi
done

if [[ -d "${REPO_ROOT}/references" ]]; then
  cp -R "${REPO_ROOT}/references" "${TMP_PLUGIN_DIR}/references"
fi

if [[ -d "${REPO_ROOT}/agents" ]]; then
  cp -R "${REPO_ROOT}/agents" "${TMP_PLUGIN_DIR}/agents"
fi

echo "Generating Codex wrapper skills inside the personal plugin bundle..." >&2
python3 "${WRAPPER_SYNC_SCRIPT}" --output-dir "${TMP_PLUGIN_DIR}/skills" >/dev/null

rm -f \
  "${TMP_PLUGIN_DIR}/skills/.DS_Store" \
  "${TMP_PLUGIN_DIR}/references/.DS_Store" \
  "${TMP_PLUGIN_DIR}/agents/.DS_Store" \
  "${TMP_PLUGIN_DIR}/.DS_Store"
find "${TMP_PLUGIN_DIR}/skills" -name '.DS_Store' -delete
if [[ -d "${TMP_PLUGIN_DIR}/references" ]]; then
  find "${TMP_PLUGIN_DIR}/references" -name '.DS_Store' -delete
fi
if [[ -d "${TMP_PLUGIN_DIR}/agents" ]]; then
  find "${TMP_PLUGIN_DIR}/agents" -name '.DS_Store' -delete
fi

rm -rf "${PLUGIN_INSTALL_ROOT}"
mv "${TMP_PLUGIN_DIR}" "${PLUGIN_INSTALL_ROOT}"
TMP_PLUGIN_DIR=""

echo "Updating ${MARKETPLACE_PATH}..." >&2

HOME_DIR="${HOME_DIR}" \
MARKETPLACE_PATH="${MARKETPLACE_PATH}" \
CODEX_CONFIG_PATH="${CODEX_CONFIG_PATH}" \
TMP_FILE="${TMP_FILE}" \
python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

home_dir = Path(os.environ["HOME_DIR"]).resolve()
marketplace_path = Path(os.environ["MARKETPLACE_PATH"]).resolve()
codex_config_path = Path(os.environ["CODEX_CONFIG_PATH"]).resolve()
tmp_file = Path(os.environ["TMP_FILE"]).resolve()

source_path = "./.codex/plugins/agent-skills"

default_root = {
    "name": "local-plugins",
    "interface": {"displayName": "Local Plugins"},
    "plugins": [],
}

if marketplace_path.exists():
    data = json.loads(marketplace_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("Marketplace JSON must contain a top-level object.")
else:
    data = default_root

data.setdefault("name", default_root["name"])

interface = data.get("interface")
if interface is None:
    interface = {}
    data["interface"] = interface
if not isinstance(interface, dict):
    raise SystemExit("Marketplace interface must be an object.")
interface.setdefault("displayName", default_root["interface"]["displayName"])

plugins = data.get("plugins")
if plugins is None:
    plugins = []
    data["plugins"] = plugins
if not isinstance(plugins, list):
    raise SystemExit("Marketplace plugins must be an array.")

entry = {
    "name": "agent-skills",
    "source": {
        "source": "local",
        "path": source_path,
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Coding",
}

replaced = False
updated_plugins = []
for plugin in plugins:
    if isinstance(plugin, dict) and plugin.get("name") == "agent-skills":
        updated_plugins.append(entry)
        replaced = True
    else:
        updated_plugins.append(plugin)

if not replaced:
    updated_plugins.append(entry)

data["plugins"] = updated_plugins
marketplace_name = data["name"]

content = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
tmp_file.write_text(content, encoding="utf-8")

config_content = codex_config_path.read_text(encoding="utf-8") if codex_config_path.exists() else ""
marketplace_section_header = f"[marketplaces.{marketplace_name}]"
marketplace_section_body = (
    f"{marketplace_section_header}\n"
    f'last_updated = "{datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"\n'
    'source_type = "local"\n'
    f'source = "{home_dir.as_posix()}"\n'
)
plugin_section_header = f'[plugins."agent-skills@{marketplace_name}"]'
plugin_section_body = (
    f"{plugin_section_header}\n"
    "enabled = true\n"
)

def replace_or_append_section(content: str, section_header: str, section_body: str) -> str:
    lines = content.splitlines()
    updated_lines = []
    inside_target = False
    section_written = False

    for line in lines:
        stripped = line.strip()
        is_table = stripped.startswith("[") and stripped.endswith("]")
        if is_table and stripped == section_header:
            if not section_written:
                updated_lines.extend(section_body.rstrip("\n").splitlines())
                section_written = True
            inside_target = True
            continue
        if inside_target and is_table:
            inside_target = False
        if not inside_target:
            updated_lines.append(line)

    if not section_written:
        if updated_lines and updated_lines[-1] != "":
            updated_lines.append("")
        updated_lines.extend(section_body.rstrip("\n").splitlines())

    return "\n".join(updated_lines).rstrip() + "\n"

config_content = replace_or_append_section(
    config_content,
    marketplace_section_header,
    marketplace_section_body,
)
config_content = replace_or_append_section(
    config_content,
    plugin_section_header,
    plugin_section_body,
)

codex_config_path.write_text(config_content, encoding="utf-8")

print(source_path)
PY

mv "${TMP_FILE}" "${MARKETPLACE_PATH}"

echo >&2
echo "Registered agent-skills in your personal Codex marketplace." >&2
echo "Next steps:" >&2
echo "1. Restart Codex." >&2
echo "2. Open /plugins." >&2
echo "3. Choose your personal marketplace." >&2
echo "4. Install or reinstall agent-skills." >&2
echo "5. Start a new thread and invoke aliases like @agent-skills:plan, @agent-skills:build, or @agent-skills:review." >&2
