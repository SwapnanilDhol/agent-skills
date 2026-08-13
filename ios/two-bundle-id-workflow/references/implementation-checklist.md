# Implementation checklist

Use this after discovery and before signing. Every item needs a file path or
command output in the app's runbook.

## Build configurations

- [ ] `Debug`, `Preview`, and `Release` exist on the app target.
- [ ] Debug and Preview use the same development `PRODUCT_BUNDLE_IDENTIFIER`.
- [ ] Release retains the pre-migration production bundle ID exactly.
- [ ] Preview is Release-optimized and defines `PREVIEW`/`DEVELOPMENT`.
- [ ] Debug/Preview and Release have distinct display names, product names and
      app icons.
- [ ] `CODE_SIGN_ENTITLEMENTS` and `INFOPLIST_FILE` resolve per configuration.
- [ ] `SWIFT_ACTIVE_COMPILATION_CONDITIONS` preserves `$(inherited)` where the
      project requires inherited conditions.

## Companion targets

For every widget, Share Extension, notification service/content extension,
watch target, App Intent extension, or other embedded target:

- [ ] development and production bundle IDs are distinct;
- [ ] Preview uses the development companion ID;
- [ ] entitlements point to the matching app group and capabilities;
- [ ] the target is embedded in the expected app configuration; and
- [ ] no development companion points at a production app group.

## Plists and identity-derived values

- [ ] `CFBundleIdentifier`, display name, name and version use build settings.
- [ ] URL schemes are distinct or intentionally absent in development.
- [ ] background-task identifiers derive from `$(PRODUCT_BUNDLE_IDENTIFIER)`.
- [ ] associated domains, app links, document types and callback URLs are
      reviewed for development routing.
- [ ] extension point metadata remains valid for both identities.

## Storage and runtime

- [ ] app groups, `UserDefaults` suites, Core Data stores, file paths and
      backups are environment-aware;
- [ ] widgets/extensions read the matching container;
- [ ] the user-visible name is bundle/configuration-driven; and
- [ ] a single runtime configuration type owns environment branching.

## Services and signing

- [ ] analytics behavior is explicitly chosen;
- [ ] Firebase/Crashlytics bundle registration is compatible or disabled;
- [ ] RevenueCat identity and purchase behavior are explicitly chosen;
- [ ] backend requests carry an explicit environment/preview marker or use a
      staging endpoint;
- [ ] APNs topics and environments match each App ID;
- [ ] development App IDs and capabilities are registered in Apple Developer;
- [ ] ad hoc profiles include the test devices for app and companions; and
- [ ] Codemagic `device-preview` uses Preview while TestFlight uses Release.

## Verification

- [ ] `verify-identities.sh` passes;
- [ ] Debug simulator build passes;
- [ ] Preview archive/ad hoc export passes;
- [ ] Release archive/validation passes;
- [ ] `verify-built-products.sh` passes for all three artifacts;
- [ ] codesigned entitlements are inspected for app and companions;
- [ ] development and production install side-by-side;
- [ ] development data, widgets, links and notifications do not reach the
      production containers; and
- [ ] the Release identity and settings match the pre-migration snapshot.
