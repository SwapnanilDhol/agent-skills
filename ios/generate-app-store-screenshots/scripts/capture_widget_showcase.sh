#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <template-udid> <app-path> <output-png>"
  echo
  echo "Phase B widget capture: clones a shutdown, preconfigured widget-showcase"
  echo "Simulator, installs the current app build, opens the widget page, normalizes"
  echo "presentation, and captures. Do not use this to add or configure widgets."
  echo "Bootstrap templates with prepare_widget_template.sh + references/widget-system-ui.md."
  echo "Set KEEP_WIDGET_CAPTURE_SIMULATOR=1 to preserve the disposable clone."
}

if [[ $# -ne 3 ]]; then
  usage >&2
  exit 64
fi

template_udid="$1"
app_path="$2"
output_png="$3"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
started_at="$SECONDS"

if [[ ! -d "$app_path" || "${app_path##*.}" != "app" ]]; then
  echo "App bundle not found: $app_path" >&2
  exit 66
fi

template_state="$(
  xcrun simctl list devices -j |
    jq -r --arg udid "$template_udid" \
      '.. | objects | select(.udid? == $udid) | .state' |
    head -n 1
)"

if [[ "$template_state" != "Shutdown" ]]; then
  echo "Template Simulator must be Shutdown; current state: ${template_state:-not found}" >&2
  exit 69
fi

app_bundle_id="${APP_BUNDLE_ID:?Set APP_BUNDLE_ID to the installed app bundle identifier}"
app_launch_arguments=()
if [[ -n "${APP_LAUNCH_ARGUMENTS:-}" ]]; then
  read -r -a app_launch_arguments <<< "$APP_LAUNCH_ARGUMENTS"
fi
swipe_direction="${WIDGET_PAGE_SWIPE_DIRECTION:-left}"
clone_name="AppStoreWidgetCapture-$(date +%Y%m%d-%H%M%S)-$$"
capture_udid=""

cleanup() {
  if [[ -z "$capture_udid" || "${KEEP_WIDGET_CAPTURE_SIMULATOR:-0}" == "1" ]]; then
    return
  fi
  xcrun simctl shutdown "$capture_udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$capture_udid" >/dev/null 2>&1 || true
}
trap cleanup EXIT

capture_udid="$(xcrun simctl clone "$template_udid" "$clone_name")"
xcrun simctl boot "$capture_udid"
xcrun simctl bootstatus "$capture_udid" -b
xcrun simctl install "$capture_udid" "$app_path"
xcrun simctl launch "$capture_udid" "$app_bundle_id" \
  "${app_launch_arguments[@]}" >/dev/null

"$script_dir/prepare_simulator.sh" "$capture_udid"

steps=(--step "sleep 2" --step "button home" --step "sleep 0.5")
case "$swipe_direction" in
  left)
    steps+=(--step "swipe --start-x 340 --start-y 420 --end-x 25 --end-y 420 --duration 0.35")
    ;;
  right)
    steps+=(--step "swipe --start-x 25 --start-y 420 --end-x 340 --end-y 420 --duration 0.35")
    ;;
  none)
    ;;
  *)
    echo "WIDGET_PAGE_SWIPE_DIRECTION must be left, right, or none" >&2
    exit 64
    ;;
esac
steps+=(--step "sleep 2")
axe batch --udid "$capture_udid" "${steps[@]}"

mkdir -p "$(dirname "$output_png")"
axe screenshot --udid "$capture_udid" --output "$output_png" >/dev/null

if [[ ! -s "$output_png" ]]; then
  echo "Widget capture was not created: $output_png" >&2
  exit 74
fi

echo "Widget showcase captured in $((SECONDS - started_at))s"
echo "Template: $template_udid"
echo "Disposable clone: $capture_udid"
echo "Output: $output_png"
