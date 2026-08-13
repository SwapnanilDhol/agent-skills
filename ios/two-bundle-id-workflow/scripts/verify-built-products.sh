#!/usr/bin/env bash
set -euo pipefail

development=""
preview=""
production=""
while (($#)); do
  case "$1" in
    --development) development="$2"; shift 2 ;;
    --preview) preview="$2"; shift 2 ;;
    --production) production="$2"; shift 2 ;;
    *) echo "Usage: $0 --development APP --preview APP --production APP" >&2; exit 64 ;;
  esac
done

for path in "$development" "$preview" "$production"; do
  [[ -d "$path" ]] || { echo "Missing app bundle: $path" >&2; exit 1; }
done

read_plist() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Info.plist"; }
dev_id="$(read_plist "$development" CFBundleIdentifier)"
preview_id="$(read_plist "$preview" CFBundleIdentifier)"
prod_id="$(read_plist "$production" CFBundleIdentifier)"
[[ "$dev_id" == "$preview_id" ]] || { echo "FAIL: Preview ID differs from development ID" >&2; exit 1; }
[[ "$dev_id" != "$prod_id" ]] || { echo "FAIL: development and production IDs match" >&2; exit 1; }

for path in "$development" "$preview" "$production"; do
  echo "$(basename "$path"): $(read_plist "$path" CFBundleIdentifier) $(read_plist "$path" CFBundleShortVersionString) ($(read_plist "$path" CFBundleVersion))"
  codesign --verify --deep --strict "$path"
done
echo "PASS: built identities are distinct and signed."
