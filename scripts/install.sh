#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
FORCE=0
LIST=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--force] [--list] [--dest DIR]

Symlink skills from this repo into ~/.cursor/skills (or --dest).

  --force   Replace existing symlinks/directories for matching skill names
  --list    Print discovered skills and exit
  --dest    Override install destination (default: ~/.cursor/skills)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --list) LIST=1; shift ;;
    --dest) DEST="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

discover_skills() {
  find "$ROOT" -type f -name SKILL.md ! -path '*/.*' | sort
}

skill_name_from_path() {
  basename "$(dirname "$1")"
}

if [[ "$LIST" -eq 1 ]]; then
  echo "Skills in $ROOT:"
  while IFS= read -r skill_md; do
    category="$(basename "$(dirname "$(dirname "$skill_md")")")"
    name="$(skill_name_from_path "$skill_md")"
    echo "  - $category/$name"
  done < <(discover_skills)
  exit 0
fi

mkdir -p "$DEST"
count=0

while IFS= read -r skill_md; do
  src="$(dirname "$skill_md")"
  name="$(skill_name_from_path "$skill_md")"
  target="$DEST/$name"

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
      echo "OK   $name (already linked)"
      count=$((count + 1))
      continue
    fi
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$target"
    else
      echo "SKIP $name (exists at $target — pass --force to replace)"
      continue
    fi
  fi

  ln -s "$src" "$target"
  echo "LINK $name → $src"
  count=$((count + 1))
done < <(discover_skills)

echo
echo "Installed $count skill(s) into $DEST"
echo "Invoke in Cursor Agent chat with /<skill-name> (e.g. /asc-morning-brief)"
