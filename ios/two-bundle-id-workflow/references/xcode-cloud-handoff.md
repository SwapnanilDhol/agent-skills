# Xcode Cloud and device-preview handoff

Use this only after both identities build correctly. Xcode Cloud owns build,
signing, archive, and distribution. The app-local runbook
(`docs/build/two-bundle-id.md`) is the registry: it records every product,
workflow ID, scheme, and the Preview enablement state. There is no separate
delivery service, chat trigger, or private hosting.

## Workflow mapping

| Path | Identity | Xcode Cloud workflow | Started by |
| --- | --- | --- | --- |
| PR verification | production build-only | Manual-only build, no archive/distribution | `asc xcode-cloud run` |
| private TestFlight | production Release | `release/<VERSION>.<BUILD>` archive, internal testing only | pushing the release branch |
| registered-device preview | development Preview | dedicated development product/workflow, ad hoc export | `asc xcode-cloud run` |

Xcode Cloud requires an App Store Connect app record/product for every bundle
identifier it builds. A side-by-side `.dev` app therefore needs a separate
unpublished record. If that record is absent, record the Preview workflow as
`disabled` in the runbook. Do not synthesize a fallback path.

## Common contract

Before starting a run, fetch the remote and record the immutable SHA. Every
workflow must reject or report a checkout that differs. The handoff must:

1. build the configured scheme/configuration;
2. reject the production bundle ID for Preview;
3. inspect the signed app and embedded targets;
4. report bundle ID, version, build, size, and SHA-256; and
5. keep Preview artifacts inside App Store Connect/Xcode Cloud and the local
   machine. Never upload them to public or third-party storage or post install
   links anywhere.

## Running a device preview

Start the Preview workflow for the branch whose head is the recorded SHA, then
wait for a terminal state:

```bash
asc xcode-cloud run --workflow-id <PREVIEW_WORKFLOW_ID> --branch main
asc xcode-cloud status --run-id <BUILD_RUN_ID> --wait
```

Download the exported ad hoc artifact through authenticated App Store Connect
access and install it on a registered device beside the production app:

```bash
asc xcode-cloud artifacts list --run-id <BUILD_RUN_ID>
asc xcode-cloud artifacts download --id <ARTIFACT_ID> --path /tmp/preview.zip
unzip -q /tmp/preview.zip -d /tmp/preview
xcrun devicectl list devices
xcrun devicectl device install app --device <DEVICE_ID> /tmp/preview/<App>.ipa
```

Run `scripts/verify-built-products.sh` against the downloaded app before
installing it. Never commit the artifact or record signed URLs.

## PassMaker live policy

PassMaker uses Xcode Cloud `PR Verification` for PR commits and `Default` for
`release/<VERSION>.<BUILD>` production TestFlight archives. `PR Verification`
has only a manual start condition: after a PR is attached, reply `Please build
and test this PR`; after a green result, a release is cut by pushing one
`release/<VERSION>.<BUILD>` branch from the verified `main`. Registered-device
Preview is disabled because no `com.swapnanildhol.PassMaker.dev` App Store
Connect app/product has been approved. Debug/Preview uses its deterministic
entitlement override; purchase testing uses production TestFlight.

## Acceptance gate

Do not call the handoff complete until `scripts/verify-preview-handoff.sh`
passes, Xcode Cloud reaches a terminal state for the exact recorded source SHA,
the downloaded artifact uses the development bundle ID and passes
`verify-built-products.sh`, and both identities install side-by-side.
