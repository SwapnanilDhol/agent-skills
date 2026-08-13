# {{APP_NAME}} dual-identity and device-preview runbook

This is the durable source of truth for the development/production identity
split. Never record secrets, private keys, bearer tokens, signed install URLs,
provisioning-profile contents, or dashboard passwords here.

## Scope

- App: `{{APP_NAME}}`
- App slug: `{{APP_SLUG}}`
- Repository: `{{REPOSITORY}}`
- Production bundle ID: `{{PRODUCTION_BUNDLE_ID}}`
- Development bundle ID: `{{DEVELOPMENT_BUNDLE_ID}}`
- Baseline remote commit: `TODO`
- Implementation commit: `TODO`

## Production snapshot

Record the pre-change resolved Release values for the app and every companion:

| Target | Bundle ID | Entitlements | App group | URL scheme | Display name | Icon |
|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO |

## Final identity matrix

| Target/configuration | Bundle ID | Entitlements | App group | URL scheme | Display name | Icon |
|---|---|---|---|---|---|---|
| App / Debug | {{DEVELOPMENT_BUNDLE_ID}} | TODO | TODO | TODO | TODO | `AppIcon-Dev` |
| App / Preview | {{DEVELOPMENT_BUNDLE_ID}} | TODO | TODO | TODO | TODO | `AppIcon-Dev` |
| App / Release | {{PRODUCTION_BUNDLE_ID}} | TODO | TODO | TODO | TODO | `AppIcon` |

Add one row per companion target and configuration.

## Service policy

| Service | Debug | Preview | Release | Verification |
|---|---|---|---|---|
| Analytics | TODO | TODO | production | TODO |
| Firebase/Crashlytics | TODO | TODO | production | TODO |
| RevenueCat/StoreKit | TODO | TODO | production | TODO |
| Backend | TODO | TODO | production | TODO |
| APNs | TODO | TODO | production | TODO |
| Associated domains | TODO | TODO | production | TODO |
| Keychain/CloudKit | TODO | TODO | production | TODO |

## Apple resources

| Resource | Identifier | ASC resource ID | Capabilities | Profile/type |
|---|---|---|---|---|
| Development app | {{DEVELOPMENT_BUNDLE_ID}} | TODO | TODO | `IOS_APP_ADHOC` / TODO |
| Companion | TODO | TODO | TODO | TODO |

Registered test devices: `TODO names/UDID suffixes only`

## Codemagic and Slack

- Codemagic app ID: `TODO`
- Workflow: `device-preview`
- Preview scheme: `TODO`
- Slack releases channel ID: `TODO`
- Indie Ops registry entry: `TODO path/commit`
- Slack route migration: `TODO path/commit`

## Deterministic verification

| Gate | Command/artifact | Result |
|---|---|---|
| Identity discovery | `/tmp/...json` | TODO |
| Identity verifier | `verify-identities.sh` | TODO |
| Debug build | `xcodebuild ... Debug` | TODO |
| Preview unsigned archive | `xcodebuild ... Preview` | TODO |
| Release unsigned archive | `xcodebuild ... Release` | TODO |
| Built-product verifier | `verify-built-products.sh` | TODO |
| Cross-repo handoff | `verify-slack-preview-handoff.sh` | TODO |

## Live acceptance

- Slack root message timestamp/link: `TODO`
- Reserved source SHA: `TODO`
- Codemagic build ID: `TODO`
- Version/build: `TODO`
- IPA bundle ID: `TODO`
- Artifact bytes/SHA-256: `TODO`
- Landing/manifest/IPA HTTP status: `TODO`
- Manifest bundle ID: `TODO`
- Artifact expiry: `TODO`
- Side-by-side device installation: `TODO`
- Same-thread start/result replies: `TODO`

## Completion checklist

Copy the current checklist from the installed
`two-bundle-id-workflow/references/implementation-checklist.md` and attach one
piece of evidence to every checked item. Record unresolved blockers below.

## Blockers and follow-ups

- None, or `TODO`.
