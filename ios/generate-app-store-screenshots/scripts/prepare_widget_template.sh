#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <simulator-udid> <app-path>"
  echo
  echo "Prepares a Simulator for Phase A widget-template bootstrap:"
  echo "  install app → launch screenshot mode → preflight → Home → probe UI."
  echo "Does not complete the jiggle/gallery/config loop; follow"
  echo "references/widget-system-ui.md and re-run probe_widget_ui.sh between axe steps."
  echo
  echo "Required env:"
  echo "  APP_BUNDLE_ID   Host app bundle identifier"
  echo "Optional env:"
  echo "  APP_LAUNCH_ARGUMENTS   Space-separated screenshot-mode launch arguments"
  echo "  WIDGET_SEED_SETTLE_SECONDS   Wait after launch before Home (default 4)"
}

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 64
fi

udid="$1"
app_path="$2"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$app_path" || "${app_path##*.}" != "app" ]]; then
  echo "App bundle not found: $app_path" >&2
  exit 66
fi

app_bundle_id="${APP_BUNDLE_ID:?Set APP_BUNDLE_ID to the installed app bundle identifier}"
app_launch_arguments=()
if [[ -n "${APP_LAUNCH_ARGUMENTS:-}" ]]; then
  read -r -a app_launch_arguments <<< "$APP_LAUNCH_ARGUMENTS"
fi
settle_seconds="${WIDGET_SEED_SETTLE_SECONDS:-4}"

state="$(
  xcrun simctl list devices -j |
    jq -r --arg udid "$udid" \
      '.. | objects | select(.udid? == $udid) | .state' |
    head -n 1
)"

if [[ -z "$state" || "$state" == "null" ]]; then
  echo "Simulator not found: $udid" >&2
  exit 69
fi

if [[ "$state" != "Booted" ]]; then
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b
fi

xcrun simctl install "$udid" "$app_path"
xcrun simctl launch "$udid" "$app_bundle_id" \
  "${app_launch_arguments[@]}" >/dev/null

"$script_dir/prepare_simulator.sh" "$udid"
sleep "$settle_seconds"
axe batch --udid "$udid" \
  --step "button home" \
  --step "sleep 1"

echo
echo "Phase A prep complete on $udid"
echo "Next: bootstrap widgets with axe, probing between steps:"
echo "  $script_dir/probe_widget_ui.sh $udid"
echo "See: $script_dir/../references/widget-system-ui.md"
echo
echo "When the page looks right:"
echo "  1. Verify live WidgetKit content (no placeholder / Pro lock)."
echo "  2. xcrun simctl shutdown $udid"
echo "  3. Record widgetTemplate.udid in app_store/automation/app_store_workflow.json"
echo "  4. Capture only via capture_widget_showcase.sh (Phase B)."
echo
"$script_dir/probe_widget_ui.sh" "$udid" || true
