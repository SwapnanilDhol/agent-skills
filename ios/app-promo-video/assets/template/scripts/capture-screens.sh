#!/usr/bin/env bash
# Captures 3x stills of the app's deterministic screenshot scenes (a debug
# launch argument that renders a production view over fixed in-memory data)
# into public/screens/<scene>.png. Mocks built with ScreenBuild animate these,
# so the promo shows the app's real UI and copy.
#
# Usage: scripts/capture-screens.sh <simulator-udid>
#   BUNDLE=com.example.app SCENE_FLAG=-screenshot-scene \
#     SCENES="home detail settings" scripts/capture-screens.sh <udid>
set -euo pipefail

UDID="${1:?simulator UDID}"
BUNDLE="${BUNDLE:?set BUNDLE to the app bundle id}"
# The launch argument that selects a scene; the scene name follows it.
SCENE_FLAG="${SCENE_FLAG:?set SCENE_FLAG to the app's screenshot-scene launch argument}"
SCENES="${SCENES:?set SCENES to space-separated scene names}"
# Extra launch arguments (skip paywalls, pin the locale, ...).
LAUNCH_ARGS="${LAUNCH_ARGS:--AppleLocale en_US -AppleLanguages (en-US)}"
# Seconds to let each scene settle; raise it for screens that load async.
SETTLE="${SETTLE:-5}"

OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/public/screens"
mkdir -p "$OUT_DIR"
# simctl runs in CoreSimulator, which can't write into privacy-protected
# folders like ~/Desktop; shoot into a temp dir and copy.
SHOTS="$(mktemp -d)"

xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState discharging --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 >/dev/null

# shellcheck disable=SC2086 # LAUNCH_ARGS and SCENES are word lists.
for scene in $SCENES; do
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" $LAUNCH_ARGS "$SCENE_FLAG" "$scene" >/dev/null
  sleep "$SETTLE"
  xcrun simctl io "$UDID" screenshot "$SHOTS/$scene.png"
  cp "$SHOTS/$scene.png" "$OUT_DIR/"
  echo "Captured $scene"
done
