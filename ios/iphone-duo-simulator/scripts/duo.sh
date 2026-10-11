#!/usr/bin/env bash
# Drive an iPhone Duo simulator through Device Hub with synthetic mouse input.
#
# Usage: duo.sh <command> [args]
#   lock | unlock          take / release the shared mouse lock
#   shot                   activate Device Hub, capture the Mac screen (+1600-px copy)
#   ref-title              save the window-title crop of the currently selected device
#   check-title            exit 0 only if Device Hub still shows the reference device
#   click X Y              native click at Mac point X,Y (no device check)
#   dclick X Y             native click, but only after check-title passes
#   drag X1 Y1 X2 Y2       press, move in steps, release (scrolling)
#   pose closed|book|open  press the pose-bar button (after check-title)
#   setpose closed|open    press the pose button, then poll devicectl until it lands
#   rotate                 press the pose-bar rotate button (quarter turn)
#   displays               print the active display and orientation
#   capture DISPLAY OUT    capture until two frames match (DISPLAY: 1 outer, 3 inner)
#
# Environment:
#   DUO_UDID      simulator UDID (required for setpose/displays/capture)
#   DUO_WORK      scratch directory (default /tmp/duo-sim)
#   DUO_LOCK      lock directory shared with other sessions (default /tmp/duo-pose-bar.lock)
#   DUO_POSE_Y, DUO_POSE_CLOSED_X, DUO_POSE_BOOK_X, DUO_POSE_OPEN_X, DUO_ROTATE_X
#                 pose-bar coordinates in Mac points (defaults from a 1470 x 956 pt
#                 display with Device Hub at its usual size; re-check from `shot`)
#   DUO_TITLE_RECT  "x0 y0 x1 y1" Mac-point crop of the device title (default 366 108 560 127)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${DUO_WORK:-/tmp/duo-sim}"
LOCK="${DUO_LOCK:-/tmp/duo-pose-bar.lock}"
POSE_Y="${DUO_POSE_Y:-871}"
ROTATE_X="${DUO_ROTATE_X:-773}"
CLICLICK="${CLICLICK:-/opt/homebrew/bin/cliclick}"
mkdir -p "$WORK"

timeout_run() { local secs="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$secs" "$@"; }
activate() { osascript -e 'tell application "DeviceHub" to activate' >/dev/null 2>&1 || true; sleep 0.5; }
need_udid() { [[ -n "${DUO_UDID:-}" ]] || { echo "DUO_UDID is not set" >&2; exit 64; }; }
pose_x() {
  case "$1" in
    closed) echo "${DUO_POSE_CLOSED_X:-810}" ;;
    book) echo "${DUO_POSE_BOOK_X:-844}" ;;
    open) echo "${DUO_POSE_OPEN_X:-878}" ;;
    *) echo "unknown pose: $1" >&2; exit 64 ;;
  esac
}
check_title() { python3 "$HERE/check_title.py" check "$WORK"; }
press() { "$CLICLICK" "m:$1,$2" w:300 "dd:$1,$2" w:120 "du:$1,$2"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  lock)
    for _ in $(seq 1 30); do mkdir "$LOCK" 2>/dev/null && { echo "locked $LOCK"; exit 0; }; sleep 2; done
    echo "lock busy: $LOCK" >&2; exit 1 ;;
  unlock)
    rmdir "$LOCK" && echo "unlocked" ;;
  shot)
    activate
    screencapture -x "$WORK/dh.png"
    sips -Z 1600 "$WORK/dh.png" --out "$WORK/dh-small.png" >/dev/null
    echo "$WORK/dh-small.png (multiply its coordinates by 0.91875 for Mac points on a 1470-pt display)" ;;
  ref-title)
    activate; python3 "$HERE/check_title.py" ref "$WORK" ;;
  check-title)
    activate; check_title ;;
  click)
    activate; "$CLICLICK" "m:$1,$2" w:300 "c:$1,$2"; echo "clicked $1,$2" ;;
  dclick)
    activate
    check_title || { echo "Device Hub is not showing the reference device; not clicking" >&2; exit 2; }
    "$CLICLICK" "m:$1,$2" w:300 "c:$1,$2"; echo "clicked $1,$2" ;;
  drag)
    activate
    check_title || { echo "Device Hub is not showing the reference device; not dragging" >&2; exit 2; }
    x1="$1"; y1="$2"; x2="$3"; y2="$4"; steps=12; args=("m:$x1,$y1" w:200 "dd:$x1,$y1" w:150)
    for i in $(seq 1 "$steps"); do
      args+=("m:$(( x1 + (x2 - x1) * i / steps )),$(( y1 + (y2 - y1) * i / steps ))" w:80)
    done
    args+=(w:300 "du:$x2,$y2")
    "$CLICLICK" "${args[@]}"; echo "dragged $x1,$y1 -> $x2,$y2" ;;
  pose)
    activate
    check_title || { echo "Device Hub is not showing the reference device" >&2; exit 2; }
    press "$(pose_x "$1")" "$POSE_Y"; echo "pose $1 pressed" ;;
  rotate)
    activate
    check_title || { echo "Device Hub is not showing the reference device" >&2; exit 2; }
    press "$ROTATE_X" "$POSE_Y"; echo "rotate pressed" ;;
  displays)
    need_udid
    timeout_run 90 xcrun devicectl device info displays --device "$DUO_UDID" 2>&1 | grep -E '^\? [0-9]|orientation' ;;
  setpose)
    need_udid
    want="$1"
    [[ "$want" == open ]] && pattern='LCD-1 \(active\)' || pattern='LCD \(primary\) \(active\)'
    "$0" pose "$want"
    for i in $(seq 1 18); do
      sleep 10
      out="$("$0" displays || true)"
      if grep -qE "$pattern" <<<"$out"; then echo "$out"; echo "pose $want reached after $((i * 10))s"; exit 0; fi
    done
    echo "$out"; echo "pose $want NOT reached in 180s; compare the pose bar with the device (see SKILL.md)" >&2; exit 1 ;;
  capture)
    need_udid
    python3 "$HERE/stable_capture.py" "$DUO_UDID" "$1" "$2" ;;
  *)
    sed -n '2,24p' "$0"; exit 64 ;;
esac
