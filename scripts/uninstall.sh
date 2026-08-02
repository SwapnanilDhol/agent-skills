#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"

if [[ ! -d "$DEST" ]]; then
  echo "No skills directory at $DEST"
  exit 0
fi

removed=0
for entry in "$DEST"/*; do
  [[ -e "$entry" || -L "$entry" ]] || continue
  if [[ -L "$entry" ]]; then
    link="$(readlink "$entry")"
    case "$link" in
      "$ROOT"/*)
        rm "$entry"
        echo "REMOVED $(basename "$entry")"
        removed=$((removed + 1))
        ;;
    esac
  fi
done

echo "Removed $removed symlink(s) that pointed at $ROOT"
