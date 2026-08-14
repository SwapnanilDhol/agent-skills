# Preview configuration

Preview is the bridge between local development and TestFlight. It must be
optimized like Release but carry the development identity.

Required settings:

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEVELOPMENT PREVIEW
PRODUCT_BUNDLE_IDENTIFIER = $(DEV_BUNDLE_ID)
DISPLAY_NAME = $(DEV_DISPLAY_NAME)
CODE_SIGN_ENTITLEMENTS = $(DEV_ENTITLEMENTS)
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-Dev
```

The selected ad hoc provider must archive Preview with registered-device
profiles for the main app and every embedded target. It must check the source
SHA, inspect the bundle ID/version/build, upload only to the private preview
storage service, and report the result to the originating workflow. It must not
run the TestFlight upload/tagging path.

Provider choices:

- **Local macOS or Codemagic:** requires only Developer Portal App IDs, devices,
  capabilities, and ad hoc profiles.
- **Xcode Cloud:** additionally requires an unpublished App Store Connect app
  record/product for the development bundle ID. Archive artifacts must be
  downloaded and handed to Indie Ops/R2 because Xcode Cloud does not provide
  the app's private OTA landing page.

Never silently create a development App Store Connect record. Record that
account-level choice in the app runbook first.

Use a Preview-only environment marker for backend requests. Keep the default
policy explicit: staging endpoint, production endpoint with a preview header,
or no network access.
