# Project configuration

Prefer a repository-owned `.asc/release.json` so the same workflow can run
without hard-coded app values in the skill.

```json
{
  "appName": "My App",
  "appId": "1234567890",
  "bundleId": "com.example.myapp",
  "teamId": "ABCDE12345",
  "project": "MyApp.xcodeproj",
  "workspace": null,
  "scheme": "MyApp",
  "configuration": "Release",
  "mainBranch": "main",
  "locales": ["en-US"],
  "metadataRoot": "metadata/version",
  "releaseNotesRoot": "docs/releases",
  "exportOptionsPlist": ".asc/export-options.plist",
  "simulatorDestination": "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest"
}
```

## Rules

- Set exactly one of `project` or `workspace`.
- Keep secrets and Apple credentials out of this file.
- Keep the export-options plist free of credentials.
- Treat `locales` as the required metadata set for that app.
- Allow repository instructions to override test commands and Simulator choice.
- Discover version from the release request or live App Store train.
- Discover the build with the marketing-version filter in
  `asc builds next-build-number`; do not store it here. A new marketing
  version starts at build `1`; replacement builds for that same version
  increment from its latest existing build.
- Derive branch, tag, metadata path, and release-note path from version/build.

## Export options

Use an App Store Connect export options plist compatible with the installed
Xcode. A minimal modern configuration generally selects App Store Connect
distribution, automatic signing, and symbol upload. Inspect Xcode help when the
installed toolchain changes rather than copying an obsolete plist blindly.

## Missing configuration

When `.asc/release.json` is absent:

1. Read repository release documentation.
2. Discover project/workspace and shared scheme.
3. Read bundle ID, team, version, and build settings from Xcode.
4. Discover the App Store app by bundle ID.
5. Infer locales from existing version metadata.
6. Ask the user only for unresolved or ambiguous values.
