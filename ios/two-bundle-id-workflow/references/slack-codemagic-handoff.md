# Slack, Indie Ops, and Codemagic handoff

Use this only after the two identities and signed Preview archive work. The
identity skill creates the app boundary; Indie Ops supplies cross-service state,
Slack routing, Codemagic dispatch, artifact validation, private R2 hosting, and
same-thread delivery.

## Source freshness

Before editing or verifying, run `git fetch origin`. Record the intended commit.
If local `main` is dirty or does not equal `origin/main`, do not pull over user
work or treat the stale checkout as evidence. Create a clean worktree at the
remote commit instead:

```bash
git fetch origin
git worktree add --detach /tmp/app-preview-audit origin/main
```

CI must build the same immutable SHA that Indie Ops reserved.

## App repository contract

Commit all of the following to the app repository:

1. a shared Preview scheme whose Archive action uses `Preview`;
2. `codemagic.yaml` with an API/manual-only workflow named `device-preview`;
3. development main and companion bundle IDs in that workflow;
4. an app-owned `.ci/device-preview.sh` that:
   - checks `DEVICE_PREVIEW_SOURCE_SHA` against `git rev-parse HEAD`;
   - rejects the production bundle ID;
   - fetches `IOS_APP_ADHOC` profiles with `--delete-stale-profiles`;
   - archives the Preview scheme;
   - inspects bundle ID, version, build, size, and SHA-256; and
   - uploads to Indie Ops with the encrypted callback bearer;
5. an app runbook with App ID resource IDs, capabilities, profile type,
   Codemagic app ID, Slack commands, and acceptance evidence.

The workflow imports the existing `indie_ops_ci` and `indie_ops_release`
Codemagic groups. Never copy their values into source, Slack, or the runbook.

## Indie Ops contract

In `config/apps.json`, add or update:

```json
{
  "slug": "example",
  "repository": "Owner/Repository",
  "codemagicAppId": "24-character-codemagic-app-id",
  "devicePreviewEnabled": true,
  "devicePreviewBundleId": "com.example.app.dev"
}
```

The production `bundleId` must remain different from
`devicePreviewBundleId`. Add the Slack channel ID as the app's `releases` route
through a D1 migration. The shared Cloudflare setup must already have:

- `CODEMAGIC_API_TOKEN`;
- `CI_CALLBACK_TOKEN` matching Codemagic's encrypted callback token;
- `DEVICE_PREVIEW_SIGNING_SECRET`;
- the private `DEVICE_PREVIEWS` R2 binding; and
- migration `0023_device_previews.sql`.

Deploy Indie Ops after the registry/migration changes and apply the production
D1 migration. These are shared platform secrets and resources, not per-app
values.

## Static cross-repository gate

From the skill directory:

```bash
scripts/verify-slack-preview-handoff.sh \
  /path/to/App \
  --indie-ops /path/to/indie-ops \
  --app-slug example
```

This proves the checked-out app workflow, Preview scheme, callback script,
Indie Ops registry, Cloudflare bindings, and Slack release route agree. It does
not prove dashboard secrets, Apple signing, deployment, or Slack event delivery.

## Live acceptance gate

After pushing the exact commit and deploying Indie Ops, post this as a new
top-level message in the app's releases channel:

```text
Build latest main device preview
```

Do not call the setup complete until all of these are true:

- D1 records the exact current remote `main` SHA;
- Codemagic runs workflow `device-preview` exactly once;
- the record reaches `ready`;
- the stored IPA has the development bundle ID, not the production ID;
- the landing page, manifest, and IPA return HTTP 200;
- the manifest reports the development bundle ID;
- the app installs beside the App Store build; and
- all start/result messages remain in the originating Slack thread.

For an existing green PR task, `Build me a device preview` is the thread-local
variant. It additionally requires the current PR SHA to match the stored green
Codemagic verification result.
