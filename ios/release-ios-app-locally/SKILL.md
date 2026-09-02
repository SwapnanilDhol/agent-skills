---
name: release-ios-app-locally
description: Prepare, archive, upload, validate, tag, and finish reproducible iOS App Store releases. Prefer an existing Xcode Cloud release-branch archive when one would auto-start; otherwise archive locally. Use for new App Store marketing versions, replacement builds, build-specific release branches, per-version metadata and release notes, App Store Connect uploads, build attachment, validation, or release tagging.
---

# Release iOS App Locally

Run an App Store release with one metadata set and release record per marketing
version, but a unique branch and tag per uploaded build. Never submit for App
Review without explicit user approval.

Before any archive, decide the upload owner: if an enabled Xcode Cloud workflow
would archive on the derived `release/` branch, defer to Cloud and resume after
that build is valid. Archive locally only when no such workflow would start.

## Local-only mode

Treat an explicit request such as “do it locally,” “do not trigger Xcode Cloud,”
or “do not push to remote” as a hard workflow override. In local-only mode:

- Never push the release branch, release commits, or release tag before, during,
  or after the local archive and upload. A push after a valid local upload can
  still match a branch- or tag-triggered Xcode Cloud workflow and create a
  duplicate archive.
- Ignore the default Cloud-owner preference and archive locally, even when an
  enabled Cloud workflow would match the release branch.
- Keep archive, export, upload, validation, metadata, and release-record work
  local. Read-only fetches and App Store Connect API calls are allowed; do not
  start an Xcode Cloud workflow.
- Create the annotated tag locally only after the archive source is confirmed.
  Do not push it until the user separately authorizes remote synchronization.
- If the user asks to finish the repository locally, merge the release branch
  into the local configured main branch without pushing. Otherwise leave the
  release branch and tag local for the later synchronization step.
- Report explicitly that no release-branch/tag push occurred and that Xcode
  Cloud was not triggered. A later request to “push” must be treated as a new
  remote-synchronization approval and checked against current Cloud triggers.

## Resolve configuration

1. Read repository instructions and release docs first.
2. Read `.asc/release.json` when present. See
   [references/project-configuration.md](references/project-configuration.md).
3. Discover missing values from the Xcode project, existing metadata, git, and
   App Store Connect. Ask only for values that cannot be discovered safely.
4. Require a three-component marketing version and a positive build number.
   Build numbers are scoped to the marketing version: a new marketing version
   starts at build `1`; replacement builds for the same marketing version
   increment from that version's latest existing build. Call
   `asc builds next-build-number --app "<APP_ID>" --version "<VERSION>" --platform IOS`
   and use the version-scoped result. If the version has no existing builds,
   use build `1`. Treat the observed App Store Connect result as authoritative:
   Cloud or another upload may have advanced the number even when the local
   repository is unchanged. Re-check immediately before creating the
   build-specific branch and immediately before upload. If the result changes,
   stop and derive a new branch/tag rather than uploading with stale names.
5. Derive, do not free-type:
   - branch: `release/<VERSION>.<BUILD>`
   - tag: `v<VERSION>.<BUILD>`
   - metadata: `metadata/version/<VERSION>/`
   - release record: `docs/releases/<VERSION>.md`

Use configured paths with their exact case; macOS can hide a `docs`/`Docs`
mistake that breaks another checkout. Verify configured files exist before
using them, and record any safe, discovered fallback path instead of silently
inventing a new repository path. In App Store Connect’s API, the UI’s
automatic release choice is `AFTER_APPROVAL`; verify the resulting enum after
updating it.

Run the naming helper when useful:

```bash
python3 <skill-dir>/scripts/derive_release_context.py \
  --version "<VERSION>" --build "<BUILD>" --repo-root "$PWD"
```

## Enforce safety boundaries

- Require a clean, understood working tree before creating the release branch.
- Never release directly from `main` or another integration branch.
- Never commit local Swift package paths or unpushed package revisions.
- Never delete global Derived Data, global package caches, or unrelated archives.
- In local-only mode, never push a release branch, release tag, or release
  commit; this rule takes precedence over the normal Cloud-owner and finish
  steps below.
- Do not local-archive when an enabled Cloud archive workflow would start on
  the release branch unless local-only mode is active. Do not run both.
- Treat upload, App Store version creation, metadata push, and build attachment as
  release preparation. Treat App Review submission as a separate approval gate.
- Stop before `--submit` or the equivalent unless the user explicitly requests it.

## Choose the archive owner

Do this after resolving version/build and before creating or pushing the
release branch.

If local-only mode is active, skip the Cloud-owner preference below and use a
local archive. Do not push the release branch to test or start Cloud.

1. List enabled Xcode Cloud workflows for the app:

   ```bash
   asc xcode-cloud workflows list --app "<APP_ID>" --pretty
   ```

2. A workflow is a release-branch auto-archive when all of these are true:
   - `isEnabled` is true
   - it has an `ARCHIVE` action
   - `branchStartCondition` would match `release/<VERSION>.<BUILD>`
     (prefix `release/` or an exact branch match)

3. If one or more match:
   - Prepare metadata, bump versions, pin packages, test, and commit as usual.
   - Push the release branch once. That push is the Cloud start.
   - Do not run a local `xcodebuild archive` or IPA upload.
   - Wait for the matching Apple build to become `VALID`.
   - If more than one archive workflow matches the same prefix, still do not
     archive locally. Prefer the `APP_STORE_ELIGIBLE` build when attaching.
     Record the extra Cloud builds; do not start a third upload.
   - Continue from metadata, attach, validate, and the submit gate.

4. If none match:
   - Archive and upload locally as described below.
   - Do not push `release/<VERSION>.<BUILD>` until Apple accepts that IPA,
     unless repository docs prove no Cloud start condition can fire.

## 1. Create the build-specific release branch

Fetch the remote, update the configured main branch with a fast-forward-only
pull, and create `release/<VERSION>.<BUILD>`. Verify the branch and tag do not
already exist locally or remotely. Record the release commit after committing;
the archive and tag must both identify that exact commit.

## 2. Reuse or create version-level metadata

Keep one metadata directory and one release record for the whole marketing
version, regardless of how many builds are uploaded.

- If `metadata/version/<VERSION>/` exists, reuse it.
- If it is missing, copy the previous live version as a baseline when available,
  then create one JSON file per configured locale.
- If `docs/releases/<VERSION>.md` exists, update it in place.
- If it is missing, create it from
  [assets/release-notes-template.md](assets/release-notes-template.md).
- Never create metadata or release-note paths suffixed with the build number.
- When copy changes, update the same version-level metadata and release record.
- Add or update the current build under the release record's build history.

Each locale metadata JSON must contain `description`, `keywords`,
`marketingUrl`, `supportUrl`, `whatsNew`, and `promotionalText`. Keep keywords
at or below 100 characters and promotional text at or below 170 characters.
Describe only functionality available in the archived build.

Validate before committing:

```bash
python3 <skill-dir>/scripts/validate_metadata.py \
  --metadata-dir "metadata/version/<VERSION>" \
  --locales "<comma-separated-locales>"
```

## 3. Prepare the release candidate

1. Set `MARKETING_VERSION` to `<VERSION>` and
   `CURRENT_PROJECT_VERSION` to `<BUILD>`.
2. Push every referenced change in remote Swift package repositories.
3. Resolve the committed remote package graph and commit `Package.resolved` if
   it changes. Preserve both branch and revision for branch-pinned packages.
4. Run the repository's required tests, Simulator build/launch, core workflow
   smoke test, and feature-specific release checks. Capture exit codes even
   when using quiet output. If a parallel test run fails, isolate the failing
   suite and rerun it using the repository's documented serialization rules;
   record both outcomes. A serial pass diagnoses a concurrency-sensitive
   failure but does not erase the failed parallel result.
5. Refresh App Store screenshots only when visible UI or marketing claims changed.
6. Commit only intentional release files.
7. If Cloud owns the archive, push the release branch now and record
   `<RELEASE_COMMIT>`. If local owns the archive, keep the branch unpushed
   until Apple accepts the IPA, then push and record `<RELEASE_COMMIT>`—unless
   local-only mode is active. In local-only mode, keep the branch and all
   release-record commits unpushed throughout the workflow.

## 4. Archive in an isolated local environment

Skip this section when Cloud owns the archive.

Create a unique temporary root with `mktemp -d`. Put Derived Data, cloned Swift
packages, archive, export, and temporary files inside that root. Pass explicit
`-derivedDataPath` and `-clonedSourcePackagesDirPath` arguments to every relevant
Xcode command. This makes every build independent of earlier release caches.

Use either `-project` or `-workspace`, never both. Resolve packages first, then
archive the Release configuration for `generic/platform=iOS` with a clean build:

```bash
xcodebuild -resolvePackageDependencies \
  <PROJECT_OR_WORKSPACE_ARGUMENT> \
  -scheme "<SCHEME>" \
  -clonedSourcePackagesDirPath "<TEMP>/SourcePackages"

xcodebuild clean archive \
  <PROJECT_OR_WORKSPACE_ARGUMENT> \
  -scheme "<SCHEME>" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "<TEMP>/Archive/App.xcarchive" \
  -derivedDataPath "<TEMP>/DerivedData" \
  -clonedSourcePackagesDirPath "<TEMP>/SourcePackages"
```

Do not reuse a previous archive, Derived Data directory, or cloned-package
directory.

## 5. Verify and export the archive

Verify bundle ID, marketing version, and build number before export:

```bash
python3 <skill-dir>/scripts/inspect_archive.py \
  --archive "<TEMP>/Archive/App.xcarchive" \
  --bundle-id "<BUNDLE_ID>" \
  --version "<VERSION>" \
  --build "<BUILD>"
```

Inspect the configured export-options plist before exporting. Confirm its exact
path, team, signing method, and `destination`:

- With `destination=export`, export into `<TEMP>/Export`, require exactly one
  expected IPA, and upload that IPA with the installed App Store Connect CLI.
- With `destination=upload`, `xcodebuild -exportArchive` uploads directly and
  normally leaves no IPA in `<TEMP>/Export`. Do not run a second CLI upload;
  query `asc builds uploads list` for the exact marketing version and build to
  capture the upload ID and follow processing.

If the configured plist is missing, inspect only known local release artifact
locations for a matching plist before stopping. Record the actual plist path
used and its destination. Stop on any identity or signing mismatch.

## 6. Upload and verify with Apple

1. Confirm local App Store Connect authentication.
2. Inspect the installed CLI help rather than assuming stale upload syntax.
3. Upload the exported IPA without a submit flag when the export destination is
   `export`; skip this step when `xcodebuild` already uploaded it.
4. Poll the build-upload record until it is terminal, then resolve the matching
   App Store build by both `CFBundleShortVersionString` and `CFBundleVersion`.
5. Treat command exit success without a matching Apple build as incomplete.
6. On rejection, record the diagnostics, clean temporary artifacts, and stop.

## 7. Create or update App Store metadata

- Create the App Store version only when `<VERSION>` does not already exist.
- Reuse the existing App Store version for replacement builds.
- Push version metadata only when it is new or changed.
- Attach the newly uploaded build.
- Complete the encryption declaration.
- Run App Store validation and record warnings separately from blockers.
- Stop before App Review submission unless explicitly authorized.

For a replacement build, first cancel any active App Review submission for the
version and wait for cancellation to complete. Confirm the version is eligible
for replacement, attach only the new valid build, and verify the old submission
is no longer the latest active submission.

Before submission, run the review dry run and verify that its version ID and
build ID are the intended pair. If the convenience wrapper creates a submission
but reports a target-version mismatch, do not retry it blindly: inspect the
submission, then use the explicit sequence `submissions-create`, `items-add`,
and `submissions-submit`, and verify the final submission state.

## 8. Finish the uploaded build

After Apple shows the correct build and required validation passes:

1. Update `docs/releases/<VERSION>.md` build history with branch, commit,
   Apple build ID, upload result, validation result, and pending submission state.
2. Commit and push that release-record update on the release branch when needed.
3. Ensure the tag points to the exact commit whose source produced the uploaded
   archive. If the record-only commit occurs afterward, do not tag that later commit.
4. Create and push annotated tag `v<VERSION>.<BUILD>`.
5. Check out the configured main branch, fast-forward it from the remote, merge
   the release branch, and push main.
6. Delete the release branch locally and remotely when retention is unnecessary.

In local-only mode, perform the record update, exact-source tag, and any
requested local merge without pushing the release branch, tag, or main. Leave
remote synchronization pending until the user explicitly authorizes it.

## 9. Clean local release artifacts

Before returning, validate that the cleanup target is the exact nonempty
temporary directory created for this release. Remove only that directory. Confirm
that its Derived Data, cloned packages, archive, IPA, and export files are gone.
Perform cleanup after success and after failure; retain only concise diagnostics
outside the temporary root when needed.

## 10. Report the handoff

Report version/build, branch, release commit, tag, Apple build ID and processing
state, metadata action, validation result, submission state, merge result, and
artifact-cleanup result. Clearly state whether App Review submission remains
pending.

## Operational learnings from Windfall

For projects whose release workflow archives `release/` branches in Xcode Cloud:

- Convert every sibling development package used by the app from
  `XCLocalSwiftPackageReference` to its remote `XCRemoteSwiftPackageReference`
  before pushing the release branch. Resolve and commit `Package.resolved` so
  it contains the remote branch and revision pins. A stale `PBXFileReference`
  such as `../SwapProKit` can shadow the remote package and prevent the lockfile
  from recording the package; remove that stale file reference on the release
  branch.
- After the archive, upload, and submission are complete, restore the local
  package references on the development branch with project-relative paths
  such as `../SwapFoundationKit` and `../SwapProKit`. Verify the paths by
  resolving the package graph; historical absolute-looking relative paths may
  resolve incorrectly from the current project layout.
- Xcode Cloud can sequence or reserve build numbers independently of the
  version-scoped ASC query. If a corrected source run fails its bundle-version
  guard, inspect the run and ASC upload records rather than bumping the
  marketing version or retrying blindly. A clean rerun of the failed source
  (`asc xcode-cloud run --source-run-id <RUN_ID> --clean`) can advance the Cloud
  run sequence and produce the intended Apple build. Verify the resulting build
  by both marketing version and build number.
- Keep replacement metadata at `metadata/version/<VERSION>/` with no build
  suffix. Keep version screenshots at the existing
  `app_store/screenshots/upload/<VERSION>/<LOCALE>/` paths; reuse them when the
  visible UI and marketing claims have not changed.
- For a valid build missing export compliance, update the build explicitly with
  `asc builds update --build-id <BUILD_ID> --uses-non-exempt-encryption=false`
  only when the app's established encryption declaration supports that value.
  Verify the build reaches `READY_FOR_BETA_TESTING` before distribution.
- Find the requesting tester's internal groups with
  `asc testflight testers list --app <APP_ID> --email <EMAIL> --include betaGroups`.
  Add the valid build with `asc builds add-groups --build-id <BUILD_ID> --group
  <GROUP_ID>` and verify the build's group relationships afterward.
- Before App Review submission, run `asc review submit ... --dry-run` and
  verify the exact version ID/build ID pair. Submit only after that check with
  the explicit confirmation flag; verify the resulting submission is
  `WAITING_FOR_REVIEW`.
- Future localization policy: support one App Store locale per language. The
  next release should use exactly six locales: `en-US` (English), `de-DE`
  (German), `es-ES` (Spanish), `ja` (Japanese), `zh-Hans` (Simplified
  Chinese), and `zh-Hant` (Traditional Chinese). Do not add regional English
  or Spanish variants unless the release scope explicitly changes.
