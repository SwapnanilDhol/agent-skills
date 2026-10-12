#!/usr/bin/env bash
# Records the real-app scenes of the promo on a simulator, one short recording
# per scene, into public/recordings/<scene>.mp4. Taps are in device points
# (iPhone 17/18 Pro: 402 × 874). Find coordinates by taking a screenshot,
# scaling it to 402 wide, and reading positions off it; prefer --id taps for
# full-screen views.
#
# The library below is app-agnostic. Replace the scenes at the bottom with the
# app's flows. Cut points live in build-timeline.mjs and are picked from the
# frames afterwards; the marks written here are only a rough guide.
#
# Usage: scripts/capture-flow.sh [simulator-udid]
#   BUNDLE=com.example.app LAUNCH_ENV="FORCE_PRO=1" scripts/capture-flow.sh <udid>
set -euo pipefail

UDID="${1:?simulator UDID}"
BUNDLE="${BUNDLE:?set BUNDLE to the app bundle id}"
# Space-separated KEY=VALUE pairs passed to the app (e.g. a debug Pro override).
LAUNCH_ENV="${LAUNCH_ENV:-}"
WALLET=com.apple.Passbook
PROMO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$PROMO_ROOT/public/recordings"
mkdir -p "$OUT_DIR"

now() { python3 -c 'import time; print(f"{time.time():.3f}")'; }
tap() { axe tap -x "$1" -y "$2" --tap-style physical --udid "$UDID" >/dev/null; }
tap_id() { axe tap --id "$1" --tap-style physical --udid "$UDID" >/dev/null; }
has_label() { axe describe-ui --udid "$UDID" | grep -q "\"AXLabel\" : \"$1"; }

# Waits for the pixel at (x, y) in a 3x screenshot to match a predicate on
# r, g, b. Use for remote views and sheets, which axe can't see. Avoid during
# animations you care about: screenshots load the simulator.
wait_pixel() {
  local x=$1 y=$2 predicate=$3
  for _ in $(seq 120); do
    xcrun simctl io "$UDID" screenshot /tmp/promo-probe.png >/dev/null 2>&1
    read -r r g b <<<"$(ffmpeg -loglevel error -i /tmp/promo-probe.png -vf "crop=1:1:$x:$y" -f rawvideo -pix_fmt rgb24 - | od -An -tu1)"
    if eval "$predicate"; then return; fi
    sleep 0.25
  done
  echo "Timed out waiting for pixel ($x, $y): $predicate" >&2; exit 1
}
# The PassKit Add to Wallet sheet's blue Add button, top right.
wait_add_to_wallet() { wait_pixel 1092 261 '(( b > 200 && r < 80 ))'; }

# Launches from the home screen with Wallet closed (no "◂ Wallet" back link),
# then waits until the app actually responds to touches.
relaunch() {
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl terminate "$UDID" "$WALLET" 2>/dev/null || true
  axe button home --udid "$UDID" >/dev/null
  sleep 1
  local env_args=()
  for pair in $LAUNCH_ENV; do env_args+=("SIMCTL_CHILD_$pair"); done
  env ${env_args[@]+"${env_args[@]}"} xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
  wait_responsive
}

# A cold launch can ignore touches for a while on a loaded host. Override this
# with a probe that suits the app: tap something harmless, check it reacted,
# undo it. The default just waits.
wait_responsive() { sleep 5; }

CLIP="" START="" RECORDER="" MARKS=""
mark() { MARKS+="\"$1\": $(python3 -c "print(round($(now) - $START, 3))"),"; }

rec_start() {
  CLIP=$1 MARKS=""
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT_DIR/$CLIP.mov" 2>"$OUT_DIR/$CLIP.log" &
  RECORDER=$!
  until grep -q "Recording started" "$OUT_DIR/$CLIP.log" 2>/dev/null; do sleep 0.05; done
  START=$(now)
}

rec_stop() {
  mark end
  kill -INT "$RECORDER"
  wait "$RECORDER" 2>/dev/null || true
  RECORDER=""
  # Constant 30 fps so Remotion can seek frame-accurately. simctl stops writing
  # frames while the screen is still, so pad with the last frame.
  ffmpeg -loglevel error -y -i "$OUT_DIR/$CLIP.mov" -vf "fps=30,scale=1080:-2,tpad=stop_mode=clone:stop_duration=3" \
    -c:v libx264 -crf 17 -pix_fmt yuv420p -movflags +faststart "$OUT_DIR/$CLIP.mp4"
  rm -f "$OUT_DIR/$CLIP.mov" "$OUT_DIR/$CLIP.log"
  python3 - "$OUT_DIR/marks.json" "$CLIP" <<EOF
import json, os, sys
path, clip = sys.argv[1], sys.argv[2]
all_marks = json.load(open(path)) if os.path.exists(path) else {}
all_marks[clip] = {${MARKS%,}}
json.dump(all_marks, open(path, "w"), indent=2)
EOF
  echo "Recorded $CLIP ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT_DIR/$CLIP.mp4")s)"
}
trap '[[ -n "$RECORDER" ]] && kill -INT "$RECORDER" 2>/dev/null || true' EXIT

xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 >/dev/null

# --- scenes (replace with the app's flows) -----------------------------------
# Rules: set up state off-camera; one short recording per scene; never poll
# screenshots mid-animation; leave ~1 s of stillness at both ends.

relaunch
rec_start edit
sleep 0.6
mark start
tap 201 757                       # e.g. open a create sheet
sleep 1.5
tap 200 200                       # e.g. pick the first row
sleep 2.5
mark editor
sleep 1.5
rec_stop

# Example: a Wallet ending (PassKit apps). Remove any earlier copy of the pass
# first, or the sheet shows "Update" instead of "Add".
# rec_start wallet
# tap 201 800                     # the app's "Preview"/"Add" button
# wait_add_to_wallet
# sleep 1.5
# tap 364 87                      # Add
# sleep 1.8
# xcrun simctl launch "$UDID" "$WALLET" >/dev/null
# sleep 4
# rec_stop

cat "$OUT_DIR/marks.json"
