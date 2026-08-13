---
name: two-bundle-id-workflow
description: >-
  Deterministically audit, bootstrap, migrate, and verify isolated iOS
  development and production identities across app targets, widgets,
  extensions, app groups, plists, URL schemes, services, and Codemagic.
  Use when creating or reviewing a two-bundle-ID setup for a new or existing
  iOS app, or when preparing side-by-side development and App Store installs.
---

# Two-bundle-ID workflow

Use this skill when a development build must coexist with the production App
Store build. Do not start by editing the project. First generate an evidence
report, then make paired changes, then run the verifier.

## Non-negotiable model

Use one app target with three configurations:

| Configuration | Bundle identity | Distribution |
|---|---|---|
| `Debug` | development (`com.example.app.dev`) | local Xcode |
| `Preview` | the same development ID | Codemagic ad hoc, registered devices |
| `Release` | production (`com.example.app`) | TestFlight/App Store |

`Preview` is Release-optimized but has the development identity and a
`DEVELOPMENT`/`PREVIEW` compilation condition. TestFlight must always use
`Release`; a preview must never upload to Apple, create a release branch, or
create a tag.

The same pairing applies to every companion target:

```text
app.dev              ↔ widget.dev / share-extension.dev
app                  ↔ widget / share-extension
group.*.dev          ↔ development companion entitlements
group.*              ↔ production companion entitlements
```

## Required sequence

1. Read the host `AGENTS.md` and the relevant references below.
2. Run `scripts/discover-identities.sh /path/to/app --output /tmp/app-identities.json`.
3. Treat the report as facts. Do not guess target names, bundle IDs, groups,
   schemes, extensions, or service behavior.
4. For a new app, run `scripts/bootstrap-identity-files.sh` into a new output
   directory and wire the generated files into Xcode.
5. For an old app, preserve the Release identity and data paths; add the
   development identity and Preview configuration additively.
6. Apply the file-by-file checklist in `references/implementation-checklist.md`.
7. Make explicit service decisions using `references/service-isolation.md`.
8. Run `scripts/verify-identities.sh /path/to/app`. It must pass before any
   signing or CI work proceeds.
9. Configure Apple App IDs, app groups, companion IDs, capabilities, and
   registered-device profiles. Never silently reuse production entitlements.
10. Configure Codemagic: `device-preview` uses `Preview`; TestFlight uses
    `Release`.
11. Build and inspect all three configurations. Run
    `scripts/verify-built-products.sh` against the resulting app bundles.
12. Install the development and production apps together and execute the
    host-specific smoke tests. Record evidence in the app runbook.

## Deterministic tooling

The scripts are intentionally conservative:

- discovery is read-only and emits stable JSON;
- verification exits non-zero with named failures;
- bootstrap refuses to overwrite an existing output directory;
- no script registers Apple identifiers, rotates secrets, deletes apps, or
  changes production settings automatically;
- build status and signing are decided by command exit codes and artifact
  inspection, not model interpretation.

Read the variant references only when needed:

- [legacy-app-migration.md](references/legacy-app-migration.md)
- [new-app-bootstrap.md](references/new-app-bootstrap.md)
- [preview-configuration.md](references/preview-configuration.md)
- [service-isolation.md](references/service-isolation.md)
- [apple-signing-and-capabilities.md](references/apple-signing-and-capabilities.md)
- [implementation-checklist.md](references/implementation-checklist.md)

## Low-cost execution

Use a low-reasoning model for discovery, template application, deterministic
checks, and repeated per-app migrations. Do not spend a reasoning model on
waiting for Xcode, Codemagic, Apple processing, or artifact uploads. Escalate
only when a verifier reports an unsupported capability, an ambiguous existing
production identity, or project corruption.

## Completion gate

Do not call an app complete unless the verifier passes, all companion targets
are paired, the production settings match the pre-migration snapshot, both
identities install side-by-side, and the app runbook contains the evidence.
