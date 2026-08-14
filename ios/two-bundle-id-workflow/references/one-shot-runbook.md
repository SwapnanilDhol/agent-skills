# One-shot execution runbook

Use this page when the only context available is this skill and an iOS app
repository. Execute the phases in order. Keep the generated app-local runbook
current so another agent can resume without conversation history.

## 0. Establish access and inputs

Discover rather than ask for values available from source or authenticated
CLIs. Record:

- app name and repository `owner/name`;
- Xcode project/workspace, app scheme, app target, and companion targets;
- production bundle ID, display name, app group, URL schemes, entitlements,
  icons, and service configuration;
- desired app slug and Slack releases channel;
- sibling Indie Ops repository path, when Slack delivery is in scope; and
- availability of `xcodebuild`, `asc`, Xcode Cloud, GitHub access,
  Cloudflare deployment access, and authenticated Slack.

Do not ask for secret values. Check whether required secret names exist in
Xcode Cloud and Indie Ops. If an interactive authentication or account decision is genuinely
required, finish every non-blocked phase first, then request exactly one action.

## 1. Freeze production evidence

Run:

```bash
git fetch origin
git status --short
git rev-parse HEAD
git rev-parse origin/main
scripts/discover-identities.sh /path/to/app --output /tmp/app-identities.json
```

If the working tree is dirty or local `main` differs from `origin/main`, preserve
it and create a detached clean worktree at the intended remote commit. Copy the
production settings, entitlements, service files, and icon names into the
app-local runbook before editing anything.

Create that record from the skill directory:

```bash
scripts/bootstrap-app-runbook.sh \
  --app-root /path/to/app \
  --app-name "Example" \
  --app-slug example \
  --repository Owner/Example \
  --production-bundle-id com.example.app
```

## 2. Implement the identity split

Use one app target with `Debug`, `Preview`, and `Release`. Debug and Preview use
`com.example.app.dev`; Release retains the production ID byte-for-byte. Apply
the pairing to every widget, extension, App Intent, watch target, app group,
URL scheme, plist value, entitlement, container, and runtime identity helper.

Preview must be Release-optimized and define `DEVELOPMENT PREVIEW`. Never gate
Preview behavior on `DEBUG`. Never hard-code identity-sensitive values in app
logic when they can resolve from build settings or the runtime identity type.

Generate the blueprint development icon using `development-app-icon.md`.
Record every service decision using `service-isolation.md`.

## 3. Prove the project before Xcode Cloud mutation

Run the deterministic identity verifier, then build unsigned products:

```bash
scripts/verify-identities.sh /path/to/app
xcodebuild -project App.xcodeproj -scheme App \
  -configuration Debug -destination 'generic/platform=iOS Simulator' build
xcodebuild -project App.xcodeproj -scheme App-Preview \
  -configuration Preview -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO archive
xcodebuild -project App.xcodeproj -scheme App \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO archive
```

Adapt `-workspace` only when discovery proves the app uses one. Do not create
Apple resources while source builds are failing.

## 4. Configure Apple signing

Register development App IDs for the main app and every companion. Enable
capabilities before creating profiles. Create or regenerate `IOS_APP_ADHOC`
profiles with all test devices. Follow `apple-signing-and-capabilities.md` and
record resource IDs and capability names—not profile contents or keys.

## 5. Configure Xcode Cloud and Slack delivery

Release uses the production identity. Preview uses the development identity.

When device preview delivery is requested:

1. Confirm an account owner explicitly approved a separate unpublished App
   Store Connect app record/product for the `.dev` bundle ID. If not, keep
   hosted Preview disabled and continue with production Xcode Cloud migration.
2. Commit a shared Preview scheme and deterministic archive/export script
   satisfying `xcode-cloud-handoff.md`.
3. Configure Xcode Cloud workflow IDs and webhook secrets; never duplicate
   secret values in source or documentation.
4. Update Indie Ops `config/apps.json`, add the app's releases-channel D1
   migration, apply migrations, test, and deploy.
5. Run `verify-slack-preview-handoff.sh` across both repositories.

Do not declare success from static configuration alone.

## 6. Commit and live acceptance

Commit the app and Indie Ops changes, push the intended branch, and ensure the
remote SHA equals the one to be built. In the app's Slack releases channel,
post a new top-level message:

```text
Build latest main device preview
```

Verify one Xcode Cloud run, the exact reserved source SHA, the development bundle
ID in the IPA and OTA manifest, HTTP 200 for landing/manifest/IPA, side-by-side
installation, and start/result replies in the originating thread. Never record
signed install tokens.

## Stop conditions

Stop and report a named blocker rather than weakening isolation when:

- a production identity or capability is ambiguous;
- a required entitlement has no safe development equivalent;
- production Release settings change unintentionally;
- a companion target cannot be paired;
- RevenueCat/StoreKit policy is unspecified;
- profiles omit the device or required capability;
- Xcode Cloud would build an unreserved SHA; or
- the artifact resolves to the production bundle ID.

Completion means every checkbox in `implementation-checklist.md` is backed by
a path, command result, Xcode Cloud resource ID, or live artifact fact in the
app-local runbook.
