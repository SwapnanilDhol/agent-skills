#!/usr/bin/env bash
# Tiles frames of a recording into one image, labelled by time order, so cut
# points can be read off it. Frame i (0-based, left to right, top to bottom)
# is at FROM + i / FPS seconds.
# Usage: contact-sheet.sh <video.mp4> <out.png> [fps=4] [from=0] [to=end] [columns=20]
set -euo pipefail
IN="$1" OUT="$2" FPS="${3:-4}" FROM="${4:-0}" TO="${5:-}" COLS="${6:-20}"
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
TO="${TO:-$DURATION}"
FRAMES=$(python3 -c "import math; print(max(1, math.ceil(($TO - $FROM) * $FPS)))")
ROWS=$(( (FRAMES + COLS - 1) / COLS ))
ffmpeg -loglevel error -y -i "$IN" \
  -vf "select='between(t,$FROM,$TO)',fps=$FPS,scale=110:-1,tile=${COLS}x${ROWS}" -frames:v 1 "$OUT"
echo "$OUT: $FRAMES frames from ${FROM}s at ${FPS} fps (${COLS} per row)"
