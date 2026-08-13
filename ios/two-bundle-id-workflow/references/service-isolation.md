# Service isolation decisions

Record one decision per service; “same as production” is allowed only when it
is deliberate and tested.

| Service | Minimum decision |
|---|---|
| Mixpanel/analytics | disabled, or a separate development project |
| Firebase/Crashlytics | separate Firebase app/plist, or disabled |
| RevenueCat | RevenueCat Test Store for Preview, or a documented no-purchase/forced-access mode; never spoof `Bundle.main` or accidentally test real purchases |
| Backend | staging, or production with an explicit preview marker and safe data policy |
| APNs | development topic/environment matching the development App ID |
| URL schemes | distinct development scheme |
| Associated domains | separate development route, or disabled |
| Keychain groups | split or explicitly proven safe to share |
| CloudKit | separate container/environment decision |
| App groups | always split between development and production |

Never put service secrets in the identity manifest, xcconfig, generated
templates, Slack, or source control.

## RevenueCat and StoreKit

An iOS in-app purchase belongs to the App Store app identified by the binary's
code-signed bundle ID. A development bundle ID is therefore a different
StoreKit app even when it is built from the same target and uses the same
RevenueCat project.

Never swizzle `Bundle.main`, override `bundleIdentifier`, or patch RevenueCat's
request metadata to report the production ID. RevenueCat might receive the
spoofed string, but StoreKit still evaluates the signed development identity;
offerings can remain empty and purchases/restores are not valid tests. The
swizzle can also corrupt analytics, backend routing, app groups, URL schemes,
and diagnostics that correctly rely on the real bundle ID.

Choose one explicit Preview policy:

1. **RevenueCat Test Store (preferred when testing paywalls):** configure Debug
   and Preview with the project's Test Store public key and Test Store products;
   keep Release on the Apple public key. A compile-time/build-setting boundary
   must make it impossible to ship the Test Store key in Release.
2. **Forced-access preview:** do not initialize purchase UI in Preview, grant
   Pro locally, and label purchasing/restoring as unavailable. Use this when the
   preview is for product QA rather than purchase QA.
3. **Separate Apple/RevenueCat app:** use only when true end-to-end Apple sandbox
   purchasing for the development bundle is worth the duplicated configuration.

Record the chosen policy and verify both Preview and Release. "Reuse the Apple
key and hope" is not a policy.
