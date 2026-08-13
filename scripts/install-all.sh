#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

"${script_dir}/install.sh" --force --dest "${CODEX_HOME:-$HOME/.codex}/skills"
"${script_dir}/install.sh" --force --dest "$HOME/.cursor/skills"

echo
echo "Installed every repository skill for Codex and Cursor."
