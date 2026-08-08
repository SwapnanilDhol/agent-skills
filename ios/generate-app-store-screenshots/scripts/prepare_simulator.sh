#!/usr/bin/env bash

# Normalize Simulator chrome before every fresh App Store screenshot capture.
set -euo pipefail

device="${1:-booted}"

# Clear inherited overrides first so the resulting status bar is deterministic.
xcrun simctl status_bar "$device" clear
xcrun simctl status_bar "$device" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --operatorName "" \
  --batteryState discharging \
  --batteryLevel 100

# Appearance is intentionally applied after the status-bar override.
xcrun simctl ui "$device" appearance light

echo "Simulator presentation prepared:"
xcrun simctl status_bar "$device" list
printf 'appearance: '
xcrun simctl ui "$device" appearance
