# Slack, Indie Ops, and CI handoff

Use this only after the two identities build correctly. Indie Ops owns Slack
routing, immutable source reservations, artifact validation, private R2
hosting, and same-thread delivery. The CI provider owns only build/sign/export.

## Provider decision

Record one provider for each path:

| Path | Identity | Supported providers |
|---|---|---|
| PR verification | production build-only | Xcode Cloud or Codemagic |
| private TestFlight | production Release | Xcode Cloud or Codemagic |
| registered-device preview | development Preview | local macOS, Codemagic, or Xcode Cloud dev product |

Xcode Cloud requires an App Store Connect app record/product for every app
bundle identifier it builds. Therefore a side-by-side `.dev` app needs a
separate unpublished record. If that record is absent, keep Preview disabled in
Indie Ops or select local macOS/Codemagic. Never fall back silently.

## Common contract

Before verification, fetch the remote and record the immutable SHA. The build
must reject any checkout that differs. Every provider path must:

1. build the configured scheme/configuration;
2. reject the production bundle ID for Preview;
3. inspect the signed app and embedded targets;
4. report bundle ID, version, build, size, and SHA-256;
5. upload only to authenticated Indie Ops/R2 storage; and
6. reply in the originating Slack thread without exposing signed tokens.

For Xcode Cloud, use lifecycle webhooks for terminal state. Download the
exported ad hoc artifact through authenticated App Store Connect access before
uploading it to R2; Xcode Cloud does not replace the private OTA landing page.

## PassMaker live policy

PassMaker uses Xcode Cloud `PR Verification` for PR commits and `Default` for
`release/<VERSION>.<BUILD>` production TestFlight archives. The registered-device
Preview path is disabled because no `com.swapnanildhol.PassMaker.dev` App Store
Connect app/product has been approved. Debug/Preview uses its deterministic
local entitlement override; purchase testing uses production TestFlight.

## Acceptance gate

Do not call the handoff complete until D1 records the exact source SHA, the
provider run reaches a terminal state, the IPA and OTA manifest use the
development bundle ID, landing/manifest/IPA return HTTP 200, both identities
install side-by-side, and all start/result messages stay in the source thread.
