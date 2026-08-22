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

## Resolve configuration

1. Read repository instructions and release docs first.
2. Read `.asc/release.json` when present. See
   [references/project-configuration.md](references/project-configuration.md).
3. Discover missing values from the Xcode project, existing metadata, git, and
   App Store Connect. Ask only for values that cannot be discovered safely.
4. Require a three-component marketing version and a positive build number.
   Discover the build from App Store Connect, not from a reset-to-1 guess.
   Call `asc builds next-build-number` for the app and platform. Use that
   exact next unused `CFBundleVersion`. A new marketing version does not
   reset the Apple build number. Re-check immediately before upload.
5. Derive, do not free-type:
   - branch: `release/<VERSION>.<BUILD>`
   - tag: `v<VERSION>.<BUILD>`
   - metadata: `metadata/version/<VERSION>/`
   - release record: `docs/releases/<VERSION>.md`

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
- Do not local-archive when an enabled Cloud archive workflow would start on
  the release branch. Do not run both.
- Treat upload, App Store version creation, metadata push, and build attachment as
  release preparation. Treat App Review submission as a separate approval gate.
- Stop before `--submit` or the equivalent unless the user explicitly requests it.

## Choose the archive owner

Do this after resolving version/build and before creating or pushing the
release branch.

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
   smoke test, and feature-specific release checks.
5. Refresh App Store screenshots only when visible UI or marketing claims changed.
6. Commit only intentional release files.
7. If Cloud owns the archive, push the release branch now and record
   `<RELEASE_COMMIT>`. If local owns the archive, keep the branch unpushed
   until Apple accepts the IPA, then push and record `<RELEASE_COMMIT>`.

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

Export with an App Store Connect export-options plist into `<TEMP>/Export`.
Require exactly one expected IPA and stop on any identity or signing mismatch.

## 6. Upload and verify with Apple

1. Confirm local App Store Connect authentication.
2. Inspect the installed CLI help rather than assuming stale upload syntax.
3. Upload the exported IPA without a submit flag.
4. Poll App Store Connect until the matching version and build appears.
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
