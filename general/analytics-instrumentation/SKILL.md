---
name: analytics-instrumentation
description: Audit, design, implement, and validate cost-conscious product analytics across mobile apps, web apps, APIs, and Workers. Use when asked to add or clean up analytics, telemetry, event tracking, instrumentation, funnels, identities, user properties, error logging, Mixpanel/Firebase/PostHog/Amplitude/TelemetryDeck integration, RevenueCat-aligned subscription signals, or to reduce noisy event volume and cardinality.
---

# Analytics Instrumentation

Build the smallest event system that can answer the app's real product and reliability questions.
Treat volume, cardinality, privacy, and provider pricing as design constraints.

## Start with scope

Determine whether the user requested an audit, a plan, or implementation. Keep audit/plan work
read-only. For implementation, follow repository instructions and normal branch/validation policy.

Read [`references/signal-framework.md`](references/signal-framework.md) before making event decisions.
Run the deterministic inventory from the repository root:

```bash
python3 ~/.codex/skills/analytics-instrumentation/scripts/scan_analytics.py .
```

The scan is a lead generator, not an event specification. Inspect every selected fire point in its
full control-flow context before changing code.

## Audit workflow

1. Discover repository instructions, platforms, targets, entry points, manifests, and backends.
2. Inventory analytics providers, automatic collection, crash/error tools, ad SDKs, subscription
   providers, identity calls, existing event wrappers, events, user properties, and backend logs.
3. Identify the source of truth for identity. Prefer authenticated account ID or subscription
   customer ID. Reject IDFA, IDFV, device name, random install UUID, email, and mutable display data.
4. Map the product into a few journeys: activation/onboarding, core creation or consumption,
   retention, monetization, sharing/export, permissions, and recovery/error paths.
5. For each candidate event, write down the question it answers, action it could change, exact
   terminal fire point, owner/provider, expected maximum frequency, and bounded properties.
6. Find duplicates: SDK automatic events, provider-native metrics, multiple callbacks for one
   outcome, view lifecycle repeats, client/server double sends, and multiple analytics destinations.
7. Estimate worst-case daily volume and property cardinality. Treat loops, rows, scrolling, timers,
   banner refreshes, retries, and raw content as unbounded until proven otherwise.
8. Produce a keep/add/remove table before implementation.

## Selection gate

Keep or add an event only when all are true:

- It answers a named product, monetization, or reliability question.
- Someone could change a feature, funnel, alert, or investigation based on it.
- It fires at one stable boundary or terminal outcome.
- Another provider does not already own the fact.
- Its frequency and every property value have a defensible upper bound.
- It contains no raw user content or unnecessary personal/device identifier.

Prefer one event plus a bounded property over many semantically identical event names. Prefer
success/failure outcomes over taps. Prefer provider-native facts over copied callbacks.

## Architecture

Use one app-owned wrapper around one product analytics destination. Keep vendor calls out of feature
code. The wrapper should own:

- environment gating so tests and ordinary debug builds do not pollute production;
- identity and dynamic account/subscription context;
- event schema versioning;
- screen deduplication where lifecycle callbacks can repeat;
- provider adapters and test seams;
- normalization to short, stable snake_case event names and enum-like properties.

All event names must be `snake_case` (`paywall_viewed`). Reject camelCase, PascalCase,
kebab-case, spaces, and names that embed IDs, routes, or content.

Do not put static app/device/locale fields on every event when the provider already supplies them.
Do not put session UUIDs on events when the provider already has sessions. Keep subscription state
dynamic; refresh user properties after entitlement changes.

## Coarse IP geolocation and RevenueCat attribution

Mixpanel's iOS SDK can derive coarse location from the device's public IP. Its default automatic
properties may include `$city`, `$region`, and `mp_country_code`; setting
`trackAutomaticEvents: false` disables automatic event collection, not this geolocation behavior.
Verify the current SDK configuration and provider dashboard before relying on these fields.

RevenueCat supports the reserved `$ip` subscriber attribute, using the SDK's supported `"true"`
sentinel, to associate request/device IP information for downstream integrations. This is distinct
from `Purchases.shared.collectDeviceIdentifiers()`, which additionally collects device identifiers
such as IDFA and IDFV. When the analytics privacy contract excludes advertising and device
identifiers, set only `$ip` after RevenueCat configuration and before the first purchase; do not add
GPS/location permission or an external IP lookup.
RevenueCat treats device identifiers as installation-associated, so this is attribution context for
downstream subscription events, not a live location stream; it does not backfill historical profiles.

RevenueCat's Mixpanel integration forwards RevenueCat subscriber attributes to Mixpanel, but it
does not copy Mixpanel-derived `$city`, `$region`, or `mp_country_code` back into RevenueCat.
Treat IP-derived location as provider-owned, coarse, and approximate: VPNs, proxies, carrier
routing, and Apple Private Relay can make it unavailable or inaccurate. Document the provider
ownership, privacy rationale, and verification method, and do not duplicate these fields as custom
event properties unless a documented join requires it.

## Instrument fire points

Instrument only confirmed boundaries:

- onboarding start, meaningful step completion, and completion;
- paywall actually shown; purchase/restore terminal success; user cancellation as its own
  non-failure outcome; categorized purchase/restore failure only for genuine errors;
- core output successfully created, saved, imported, exported, shared, or accepted;
- permission decision after the system callback resolves;
- AI/network operation accepted by the product or reaching a terminal categorized failure;
- backend authentication/provider failures as structured operational logs;
- marketing-site high-intent surfaces when the product has a website, especially App Store
  outbound clicks.

Do not log intent taps when the outcome callback exists. Do not log successful backend traffic when
the accepted client outcome is the product signal. Keep backend observability separate from product
analytics.

## Errors

Use crash reporting for crashes and stack traces. Use product analytics only for bounded failure
categories tied to a funnel. Use backend logs/traces for server diagnosis.

Never use localized descriptions, exception messages, URLs, file paths, prompts, payloads, or stack
traces as analytics dimensions. Map them to a finite taxonomy such as `timeout`, `rate_limited`,
`unauthorized`, `invalid_response`, `provider_unavailable`, and `unknown`.

Never emit `purchase_failed` or `restore_failed` for user cancellation. StoreKit
`paymentCancelled`, RevenueCat `purchaseCancelledError`, and equivalent dismiss/cancel outcomes
are not errors. If cancellation answers a funnel question, emit `purchase_cancelled` or
`restore_cancelled`; otherwise omit it. Reserve `*_failed` for genuine payment, network, provider,
or unknown store errors.

## Website

If the product also has a marketing website, instrument only the highest-intent surfaces on that
site. Always instrument App Store (and Play Store, if present) outbound links at the actual click
or navigation boundary so store-page arrivals from the site are countable. Prefer one snake_case
event such as `app_store_clicked` with bounded properties like `store` and `surface`. Do not copy
every page view, scroll, or CTA if automatic collection already covers traffic; keep the catalog
tiny and focused on conversion into the store.

## Validate and document

1. Search again for direct SDK calls, removed providers, stale keys, duplicate events, raw error
   text, non-snake_case event names, purchase/restore failures fired on user cancellation, and
   missing App Store click tracking on a product marketing site.
2. Run focused unit tests, typecheck/compile, and the platform build in proportion to risk.
3. Exercise one success and terminal failure per changed funnel when runtime access is available.
4. Verify identity and dynamic subscription properties in the provider debug view without sending
   production data from ordinary development sessions.
5. Document provider ownership, identity, shared context, exact event catalog/fire points, signals
   intentionally omitted, volume/cardinality rules, and validation steps.
6. Report estimated volume reductions and any provider/configuration gaps that require external
   credentials or dashboard access.

Finish with a concise inventory of kept, added, removed, and provider-native signals. State which
questions the resulting dataset can answer; do not claim that more events automatically mean better
coverage.
