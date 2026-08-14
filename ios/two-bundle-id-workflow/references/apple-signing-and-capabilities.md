# Apple signing and capability recovery

Use this when a Preview archive compiles without signing but Xcode Cloud fails
after creating a development App ID or ad hoc profile.

## Required order

Apple capabilities belong to the App ID. Provisioning profiles snapshot those
capabilities. The deterministic order is:

1. register the development main and companion App IDs;
2. enable every capability required by each development entitlements file;
3. create or regenerate the ad hoc profiles;
4. archive and export;
5. inspect the signed artifact and OTA manifest.

Creating the profile before enabling a capability produces a profile that
cannot satisfy the app's entitlements. Re-running the same archive without
regenerating that profile cannot repair it.

## ASC inspection and repair

Resolve the App Store Connect resource ID from the literal bundle identifier:

```bash
bundle_resource_id="$(asc bundle-ids list --paginate --output json | \
  jq -r '.data[] | select(.attributes.identifier == "com.example.app.dev") | .id')"
test -n "$bundle_resource_id"
```

Inspect enabled capabilities:

```bash
asc bundle-ids capabilities list \
  --bundle "$bundle_resource_id" \
  --output json \
  --pretty
```

Compare that output with the development entitlements file. For example, an
app containing `com.apple.developer.pass-type-identifiers` requires `WALLET`:

```bash
asc bundle-ids capabilities add \
  --bundle "$bundle_resource_id" \
  --capability WALLET \
  --output json \
  --pretty
```

After changing capabilities, start a clean Xcode Cloud build so managed signing
regenerates the affected profiles. Repeat the capability audit for every
embedded target. Do not enable a capability on a companion App ID unless its
own entitlements require it.

## Isolation test

Prove source code is not the failure before mutating Apple configuration:

```bash
xcodebuild \
  -project App.xcodeproj \
  -scheme App-Preview \
  -configuration Preview \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  archive
```

- Unsigned archive fails: fix the project/code first.
- Unsigned archive succeeds but signed Xcode Cloud archive fails: inspect App ID
  capabilities, profiles, certificates, and signed entitlements.

## End-to-end proof

Do not stop at a green Xcode Cloud status. Verify:

- Xcode Cloud used the exact reserved source SHA;
- the uploaded IPA bundle ID equals the development bundle ID;
- the OTA manifest returns HTTP 200 and reports that same bundle ID;
- the IPA endpoint returns HTTP 200 with a non-zero content length;
- the development app installs beside the production app; and
- the result and install link remain in the originating Slack thread.

Record the App ID resource IDs, capability output, build ID, version/build,
source SHA, manifest bundle ID, link expiry, development App Store Connect
app/product ID, workflow ID, and archive artifact ID in the app runbook. Never record
private keys, bearer tokens, signed install tokens, or provisioning profile
contents.
