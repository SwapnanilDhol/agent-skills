#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <simulator-udid>"
  echo
  echo "Classifies the frontmost Simulator UI for widget screenshot bootstrap."
  echo "Prints one state token plus matching accessibility labels to stderr hints."
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 64
fi

udid="$1"

if ! command -v axe >/dev/null 2>&1; then
  echo "axe is required (https://github.com/cameroncooke/AXe)" >&2
  exit 69
fi

raw="$(axe describe-ui --udid "$udid" 2>/dev/null || true)"
if [[ -z "$raw" ]]; then
  echo "state=unknown"
  echo "Could not read accessibility tree. Is the Simulator booted?" >&2
  exit 74
fi

lower="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
placeholder_patterns="${WIDGET_PLACEHOLDER_PATTERNS:-please select|requires pro|purchase pro|configure widget}"
parameter_label="${WIDGET_PARAMETER_LABEL:-the widget parameter}"
entity_label="${WIDGET_ENTITY_LABEL:-the seeded marketing entity}"
parameter_lower="$(printf '%s' "$parameter_label" | tr '[:upper:]' '[:lower:]')"
entity_lower="$(printf '%s' "$entity_label" | tr '[:upper:]' '[:lower:]')"

has() {
  printf '%s' "$lower" | grep -Fq "$1"
}

state="unknown"
hints=()

placeholder_found=0
while IFS= read -r pattern; do
  if [[ -n "$pattern" ]] && has "$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')"; then
    placeholder_found=1
    break
  fi
done < <(printf '%s' "$placeholder_patterns" | tr '|' '\n')

if [[ "$placeholder_found" -eq 1 ]]; then
  state="widget_placeholder"
  hints+=("Widget is on-screen but unconfigured or Pro-locked. Open Edit Widget or fix screenshot Pro seed.")
elif has "posterboard" || { has "add widgets" && has "lock screen"; }; then
  state="lock_screen_customize"
  hints+=("PosterBoard customize is frontmost. Use Lock Screen widget slots, not Home Screen jiggle.")
elif has "$parameter_lower" || has "$entity_lower" || has "choose the"; then
  state="widget_config"
  hints+=("WorkflowUI WidgetConfigurationExtension may be frontmost. Tap $parameter_label, then $entity_label.")
elif has "edit widget" && ! has "add widget"; then
  state="widget_context_menu"
  hints+=("Long-press menu is open. Tap Edit Widget to enter configuration.")
elif has "add widget" || has "search widgets" || has "widget gallery"; then
  state="widget_gallery"
  hints+=("SpringBoard widget gallery is up. Search the host app name, pick size, Add Widget.")
elif has "customize" && has "done"; then
  state="jiggle_mode"
  hints+=("Home Screen edit/jiggle mode. Tap Add Widget / + or Done.")
elif has "deletebutton" || has "remove wallpaper"; then
  state="jiggle_mode"
  hints+=("Jiggle/delete affordances visible. Finish layout or tap Done.")
elif has "notificationcenter" || has "today view"; then
  state="today_or_notifications"
  hints+=("Today/Notification Center. Prefer a dedicated Home Screen page for App Store widget shots.")
else
  state="home_or_app"
  hints+=("No widget chrome detected. Go Home before long-pressing, or launch the app to seed fixtures.")
fi

echo "state=$state"

# Emit a compact label sample to help the next axe tap.
printf '%s' "$raw" |
  grep -Eo '"label"[[:space:]]*:[[:space:]]*"[^"]+"' |
  sed 's/.*"\([^"]*\)"$/\1/' |
  awk 'NF && !seen[$0]++' |
  head -n 40 |
  sed 's/^/label: /' || true

for hint in "${hints[@]}"; do
  echo "hint: $hint" >&2
done
