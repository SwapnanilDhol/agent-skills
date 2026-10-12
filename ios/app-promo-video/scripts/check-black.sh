#!/usr/bin/env bash
# Reports black stretches on the drawn phone's screen in a rendered promo
# (e.g. an app's cold-launch black leaking into a cut). Silent output = clean.
# Usage: check-black.sh <promo.mp4>
set -euo pipefail
ffmpeg -hide_banner -i "$1" -vf "crop=560:1200:260:500,blackdetect=d=0.03:pix_th=0.12:pic_th=0.85" -an -f null - 2>&1 \
  | grep -o "black_start:[0-9.]* black_end:[0-9.]*" || echo "No black frames on the phone screen."
