# Slack, Indie Ops, and Xcode Cloud handoff

Use this only after both identities build correctly. Indie Ops owns Slack
routing, immutable source reservations, artifact validation, private R2
hosting, and same-thread delivery. Xcode Cloud owns build, signing, archive, and
distribution.

## Workflow mapping

| Path | Identity | Xcode Cloud workflow |
| --- | --- | --- |
| PR verification | production build-only | PR-triggered build, no archive/distribution |
| private TestFlight | production Release | `release/<VERSION>.<BUILD>` archive, internal testing only |
| registered-device preview | development Preview | dedicated development product/workflow |

Xcode Cloud requires an App Store Connect app record/product for every bundle
identifier it builds. A side-by-side `.dev` app therefore needs a separate
unpublished record. If that record is absent, keep Preview disabled in Indie
Ops. Do not synthesize a fallback path.

## Common contract

Before verification, fetch the remote and record the immutable SHA. Every
workflow must reject or report any checkout that differs. The handoff must:

1. build the configured scheme/configuration;
2. reject the production bundle ID for Preview;
3. inspect the signed app and embedded targets;
4. report bundle ID, version, build, size, and SHA-256;
5. upload Preview artifacts only to authenticated Indie Ops/R2 storage; and
6. reply in the originating Slack thread without exposing signed tokens.

Use authenticated Xcode Cloud lifecycle webhooks for terminal state. For a
registered-device Preview, download the exported artifact through authenticated
App Store Connect access before uploading it to R2; Xcode Cloud does not replace
the private OTA landing page.

## PassMaker live policy

PassMaker uses Xcode Cloud `PR Verification` for PR commits and `Default` for
`release/<VERSION>.<BUILD>` production TestFlight archives. Registered-device
Preview is disabled because no `com.swapnanildhol.PassMaker.dev` App Store
Connect app/product has been approved. Debug/Preview uses its deterministic
entitlement override; purchase testing uses production TestFlight.

## Acceptance gate

Do not call the handoff complete until D1 records the exact source SHA, Xcode
Cloud reaches a terminal state, the IPA and OTA manifest use the development
bundle ID, landing/manifest/IPA return HTTP 200, both identities install
side-by-side, and all start/result messages stay in the source thread.
