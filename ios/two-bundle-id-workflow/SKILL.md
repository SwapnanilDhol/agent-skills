---
name: two-bundle-id-workflow
description: >-
  Deterministically audit, bootstrap, migrate, and verify isolated iOS
  development and production identities across app targets, widgets,
  extensions, app groups, plists, URL schemes, development app icons,
  services, Apple signing, hosted CI, and Indie Ops delivery.
  Use when creating or reviewing a two-bundle-ID setup for a new or existing
  iOS app, preparing side-by-side development and App Store installs, or wiring
  the signed Preview build into an Indie Ops/Slack delivery loop.
---

# Two-bundle-ID workflow

Use this skill when a development build must coexist with the production App
Store build. Do not start by editing the project. First generate an evidence
report, then make paired changes, then run the verifier.

For a complete clean-room implementation, read
`references/one-shot-runbook.md` before taking any action. Use
`scripts/bootstrap-app-runbook.sh` to create the evidence record inside the
host app; do not rely on conversational memory as the runbook.

## Non-negotiable model

Use one app target with three configurations:

| Configuration | Bundle identity | Distribution |
|---|---|---|
| `Debug` | development (`com.example.app.dev`) | local Xcode |
| `Preview` | the same development ID | registered-device ad hoc via Codemagic, local macOS, or an Xcode Cloud dev product |
| `Release` | production (`com.example.app`) | Xcode Cloud or Codemagic TestFlight/App Store |

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

1. Read the host `AGENTS.md` and the relevant references below. Fetch the
   remote first. If the existing checkout is dirty or its local `main` differs
   from `origin/main`, preserve it and audit a clean worktree at the intended
   remote commit; never infer production readiness from a stale local branch.
2. Run `scripts/discover-identities.sh /path/to/app --output /tmp/app-identities.json`.
3. Create the host-app evidence record with
   `scripts/bootstrap-app-runbook.sh`; fill it continuously during the work.
4. Treat the report as facts. Do not guess target names, bundle IDs, groups,
   schemes, extensions, or service behavior.
5. For a new app, run `scripts/bootstrap-identity-files.sh` into a new output
   directory and wire the generated files into Xcode.
6. For an old app, preserve the Release identity and data paths; add the
   development identity and Preview configuration additively.
7. Apply the file-by-file checklist in `references/implementation-checklist.md`.
8. Make explicit service decisions using `references/service-isolation.md`.
9. Generate the development app icon using
   `references/development-app-icon.md`. Derive its wireframe from the real
   production icon; do not use a generic `DEV` badge.
10. Run `scripts/verify-identities.sh /path/to/app`. It must pass before any
   signing or CI work proceeds.
11. Configure Apple App IDs, app groups, companion IDs, capabilities, and
   registered-device profiles. Never silently reuse production entitlements.
12. Select providers explicitly. TestFlight/App Store always uses `Release`.
    Registered-device delivery uses `Preview` and must produce a development-ID
    IPA. Xcode Cloud app products require an App Store Connect app record for
    each bundle identifier; if a `.dev` record is intentionally absent, use a
    local macOS or Codemagic ad hoc builder instead.
13. If Slack delivery is required, follow
    `references/slack-ci-handoff.md`, register the app in Indie Ops, and
    run `scripts/verify-slack-preview-handoff.sh`.
14. Build and inspect all three configurations. Run
    `scripts/verify-built-products.sh` against the resulting app bundles.
15. Install the development and production apps together and execute the
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
- [one-shot-runbook.md](references/one-shot-runbook.md)
- [preview-configuration.md](references/preview-configuration.md)
- [service-isolation.md](references/service-isolation.md)
- [apple-signing-and-capabilities.md](references/apple-signing-and-capabilities.md)
- [development-app-icon.md](references/development-app-icon.md)
- [slack-ci-handoff.md](references/slack-ci-handoff.md)
- [implementation-checklist.md](references/implementation-checklist.md)

## Low-cost execution

Use a low-reasoning model for discovery, template application, deterministic
checks, and repeated per-app migrations. Do not spend a reasoning model on
waiting for Xcode Cloud, Codemagic, Apple processing, or artifact uploads. Escalate
only when a verifier reports an unsupported capability, an ambiguous existing
production identity, or project corruption.

## Completion gate

Do not call an app complete unless the verifier passes, all companion targets
are paired, the production settings match the pre-migration snapshot, the
development icon passes the blueprint-style review and asset validation, both
identities install side-by-side, the app runbook contains the evidence, and—if
Slack delivery is in scope—the cross-repository handoff verifier and one real
Slack-triggered artifact both pass.
