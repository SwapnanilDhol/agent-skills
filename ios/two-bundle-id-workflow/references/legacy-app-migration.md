# Legacy-app migration

Treat a legacy app as production-critical. The first rule is preservation:
capture Release settings and entitlements before changing anything, then add
development identities without changing the production bundle ID, app group,
URL scheme, App Store metadata, or release configuration.

1. Run discovery and commit the JSON report outside the source tree.
2. Identify the production app target and every embedded target.
3. Inventory hard-coded bundle IDs, groups, URL schemes, background identifiers,
   keychain groups, Firebase files, RevenueCat keys, APNs topics and backend URLs.
4. Create additive Apple development IDs/capabilities and register devices.
5. Add Debug/Preview configs and development entitlements.
6. Move identity-sensitive values into xcconfig/plist variables or the one
   runtime configuration type.
7. Split storage, widgets, extensions, deep links, analytics and service policy.
8. Preserve the production icon and generate a distinct blue-grid wireframe
   development icon from it; never replace the development identity with a
   generic `DEV` badge.
9. Migrate hosted CI to Xcode Cloud and verify the production product before
   changing any user data migration. Do not create an App Store Connect record
   for the development bundle ID without an explicit account-owner decision.
10. Run the verifier. Fix every named finding; do not waive a finding silently.
11. Install both apps and exercise a representative data write, widget refresh,
    deep link, notification, purchase gate, and backend call.

If a legacy app has no safe development identity, stop after the read-only audit
and report the missing Apple capabilities or service decisions. Do not invent a
bundle ID and start signing against it.
