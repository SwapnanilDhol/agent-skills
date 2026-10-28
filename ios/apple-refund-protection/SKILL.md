---
name: apple-refund-protection
description: >-
  Set up RevenueCat Refund Control and App Store Server Notifications so Apple
  receives consumption data and a refund preference when a customer asks for a
  refund. Use when the user complains about refund abuse, asks how to dispute
  an App Store refund, or wants refund handling configured for one or all apps.
---

# Apple Refund Protection

Developers cannot appeal or charge back an App Store refund after Apple grants
it. The only lever is answering Apple's `CONSUMPTION_REQUEST` notification
(within about 12 hours) with usage data and a refund preference. RevenueCat
does this automatically once two things are true:

1. A refund policy is set in RevenueCat → project → **Lifecycle → Refund Control**.
2. App Store Connect sends that app's **App Store Server Notifications** to
   RevenueCat's per-app webhook URL.

Both are required. A policy without the notification URL does nothing.

## Standard policy

| Policy | Condition | Refund preference |
|---|---|---|
| Primary: Recent renewal | Most recent renewal date within last 24 hours | Send consumption data only |
| Default | Everyone else | Prefer no refund |

The renewal exception covers the legitimate "forgot to cancel" case. Lifetime
and one-time buyers stay on "Prefer no refund".

Do **not** carve out "first purchase date within last N days" to satisfy
RevenueCat's 20% warning: refund requests come almost entirely from recent
buyers, so that exempts exactly the people the policy is for. The warning
counts every customer including free users who never bought anything, so it
usually cannot be cleared with purchaser-based rules anyway.

If a project already has a custom primary policy, report it and leave it
alone unless the user says to replace it.

## Workflow

### 1. Inventory

```bash
asc apps --paginate --output json
```

For every app record `id`, `bundleId`, `subscriptionStatusUrl`,
`subscriptionStatusUrlForSandbox`. Note any URL that is not
`api.revenuecat.com`; ask the user what it is before replacing it. If they
don't know it, replace it without forwarding (an unknown endpoint should not
keep receiving purchase events).

In the RevenueCat dashboard, list projects at `app.revenuecat.com/projects`,
then each project's apps at `/projects/<id>/apps`. On each App Store app page
read the bundle ID and the **Apple Server Notification URL**
(`https://api.revenuecat.com/v1/incoming-webhooks/apple-server-to-server-notification/<key>`).
Match RevenueCat apps to App Store apps by **bundle ID**, never by name.
Projects can contain a `.dev` or second app; use the one whose bundle ID
matches the App Store record.

### 2. Refund policies (RevenueCat dashboard)

Open `/projects/<id>/lifecycle/refund-control`.

- New policies default to **"Prefer full refund"**. Always change it.
- Click the third **New policy** card ("Recent renewal"); it pre-fills
  "Most recent renewal date within Last 24 hours".
- Set that policy to "Send consumption data only" and the Default policy to
  "Prefer no refund", then **Save changes** and wait for "Refund policies saved".
- The comboboxes respond to a synthetic pointer sequence
  (`pointerdown, mousedown, pointerup, mouseup, click`) on the input, then
  `mousedown` + `click` on the `[role=option]` with the exact label. Verify the
  input's value afterwards before saving.
- Reload and re-read the inputs to confirm the save.

### 3. Notification URLs (asc CLI)

```bash
asc apps update --id "<APP_ID>" \
  --subscription-status-url "<REVENUECAT_WEBHOOK_URL>" \
  --sandbox-subscription-status-url "<REVENUECAT_WEBHOOK_URL>"
```

Both flags set version V2. Check the response echoes the new URLs.

If the app also needs notifications on another server, put that server's URL in
RevenueCat's **Apple Server Notification Forwarding URL** field (app settings)
instead of keeping it in App Store Connect.

### 4. Verify with a test notification

The test endpoint is the App Store Server API, which only accepts an
**In-App Purchase key** (`SubscriptionKey_<KEYID>.p8`), not the App Store
Connect API key asc already uses. Register one once:

```bash
chmod 600 /path/to/SubscriptionKey_<KEYID>.p8   # asc rejects looser permissions
asc storekit auth login --name <Name> --key-id <KEYID> \
  --issuer-id <ISSUER_ID> --private-key /path/to/SubscriptionKey_<KEYID>.p8 \
  --bundle-id <any.app.bundle.id>
```

The issuer ID is the same one in `~/.asc/config.json`. In-App Purchase keys are
team-wide, so one key covers every app via `--bundle-id`:

```bash
asc storekit notifications test --bundle-id <bundle> --environment production --confirm
asc storekit notifications test-status --bundle-id <bundle> --token <token> --environment production
```

Expect `"firstSendAttemptResult":"SUCCESS"`.

- `404 4040007` right after changing the URL is propagation delay. Retry every
  2–3 minutes; it can take up to ~10 minutes.
- `401 Unauthorized` for one app while others succeed usually means that app
  isn't selling yet. The URL is still set; report it as unverified.

RevenueCat's app page should later change from "No notifications received" to
"Last received <date>".

## Report

Keep it short: which projects got the policy, which were skipped and why, which
URLs changed (and what they replaced), and test results per app. Never put
webhook URLs, key IDs, or issuer IDs in commits or public docs.
