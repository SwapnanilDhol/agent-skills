#!/usr/bin/env bash
set -euo pipefail

product=""
bundle=""
output=""
while (($#)); do
  case "$1" in
    --product) product="$2"; shift 2 ;;
    --bundle-id) bundle="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    *) echo "Usage: $0 --product NAME --bundle-id com.example.app --output DIR" >&2; exit 64 ;;
  esac
done
[[ "$product" =~ ^[A-Za-z][A-Za-z0-9-]*$ ]] || { echo "Invalid --product" >&2; exit 1; }
[[ "$bundle" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { echo "Invalid --bundle-id" >&2; exit 1; }
[[ -n "$output" ]] || { echo "Missing --output" >&2; exit 1; }
if [[ -e "$output" ]]; then
  echo "Refusing to overwrite existing output: $output" >&2
  exit 1
fi

dev_bundle="${bundle}.dev"
mkdir -p "$output/Configuration/Entitlements" "$output/Configuration/Info"
cat > "$output/Configuration/DebugConfig.xcconfig" <<EOF
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEVELOPMENT DEBUG \$(inherited)
PRODUCT_BUNDLE_IDENTIFIER = ${dev_bundle}
DISPLAY_NAME = ${product} Dev
PRODUCT_NAME = ${product}Dev
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Dev
CODE_SIGN_ENTITLEMENTS = Configuration/Entitlements/${product}Dev.entitlements
APP_GROUP_IDENTIFIER = group.${dev_bundle}
URL_SCHEME = ${product}-dev
EOF
cat > "$output/Configuration/PreviewConfig.xcconfig" <<EOF
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEVELOPMENT PREVIEW \$(inherited)
PRODUCT_BUNDLE_IDENTIFIER = ${dev_bundle}
DISPLAY_NAME = ${product} Dev
PRODUCT_NAME = ${product}Dev
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Dev
CODE_SIGN_ENTITLEMENTS = Configuration/Entitlements/${product}Dev.entitlements
APP_GROUP_IDENTIFIER = group.${dev_bundle}
URL_SCHEME = ${product}-dev
EOF
cat > "$output/Configuration/ReleaseConfig.xcconfig" <<EOF
SWIFT_ACTIVE_COMPILATION_CONDITIONS = \$(inherited)
PRODUCT_BUNDLE_IDENTIFIER = ${bundle}
DISPLAY_NAME = ${product}
PRODUCT_NAME = ${product}
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
CODE_SIGN_ENTITLEMENTS = Configuration/Entitlements/${product}.entitlements
APP_GROUP_IDENTIFIER = group.${bundle}
URL_SCHEME = ${product}
EOF

for suffix in "${product}Dev" "${product}"; do
  group="group.${bundle}"
  [[ "$suffix" == "${product}Dev" ]] && group="group.${dev_bundle}"
  cat > "$output/Configuration/Entitlements/${suffix}.entitlements" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.application-groups</key><array><string>${group}</string></array></dict></plist>
EOF
done

cat > "$output/Configuration/IdentityConfiguration.swift" <<'EOF'
enum IdentityConfiguration {
    static var isDevelopment: Bool {
        #if DEVELOPMENT
        return true
        #else
        return false
        #endif
    }
}
EOF
echo "Generated identity templates in $output"
