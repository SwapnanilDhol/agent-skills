#!/usr/bin/env bash
# Copies the Remotion promo template into <app-repo>/promo and installs it.
# Usage: scaffold.sh <app-repo-root>
set -euo pipefail
APP="${1:?app repo root}"
SKILL="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$APP/promo"
if [[ -e "$DEST" ]]; then
  echo "$DEST already exists; refusing to overwrite." >&2
  exit 1
fi
cp -R "$SKILL/assets/template" "$DEST"
chmod +x "$DEST/scripts/"*.sh
(cd "$DEST" && npm install --silent)
echo "Scaffolded $DEST. Next: edit assets.json, src/brand.ts, src/scenes/mock/index.tsx,"
echo "scripts/capture-flow.sh and scripts/build-timeline.mjs, then npm run dev."
