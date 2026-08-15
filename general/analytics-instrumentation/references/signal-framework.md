# Signal framework

## Decision table

For every candidate, record:

| Field | Requirement |
|---|---|
| Question | A concrete product, monetization, or reliability question |
| Action | What changes if the metric moves |
| Event owner | Product analytics, crash tool, subscription/ad provider, or backend observability |
| Fire point | Exact confirmed state transition or terminal callback |
| Frequency bound | Worst-case events per user/task/day |
| Properties | Small enum-like dimensions with owners and allowed values |
| Privacy | Why no raw content or unnecessary personal identifier is needed |
| Duplicate check | Automatic/provider/client/server equivalents considered |

Reject a candidate when the question or action is blank.

## Provider ownership

| Fact | Default owner |
|---|---|
| App open, first open, session, device/OS/app version, locale | Product analytics automatic collection |
| Crash, stack trace, nonfatal exception | Crash reporting |
| Subscription entitlement, renewal, revenue, product | RevenueCat/store provider |
| Ad impression, click, fill, revenue | Ad provider |
| User-completed funnel and feature outcome | Product analytics |
| API latency, upstream status, auth/provider failure | Backend logs/metrics/traces |

Copy a provider fact only when a documented join or funnel cannot use the provider integration, and
record why.

## Naming

All event names must be `snake_case`. Reject camelCase (`paywallViewed`), PascalCase
(`PaywallViewed`), kebab-case (`paywall-viewed`), spaces, and names that embed IDs, routes,
content, or errors.

Names should describe facts in past tense. Properties explain stable variants; they do not carry
content.

## High-signal event shapes

- `onboarding_started`, `onboarding_step_completed`, `onboarding_completed`
- `paywall_viewed`, `purchase_completed`, `purchase_cancelled`, `purchase_failed`,
  `restore_completed`, `restore_cancelled`, `restore_failed`
- `feature_completed` with bounded `feature_name` and optional `source`
- `share_completed` after the activity/result callback
- `permission_decided` with permission type and boolean outcome
- `<operation>_completed` and `<operation>_failed` with bounded operation and error categories

`purchase_failed` and `restore_failed` fire only for genuine store, payment, network, or provider
errors. User cancellation is not a failure: do not map StoreKit `paymentCancelled`, RevenueCat
`purchaseCancelledError`, or equivalent dismiss/cancel results onto `*_failed`. Use
`purchase_cancelled` / `restore_cancelled` only when cancellation itself is a named funnel
question; otherwise omit it.

## Volume anti-patterns

- every button tap, tab selection, row appearance, hover, scroll, drag, keystroke, or animation;
- `onAppear`/mount callbacks without deduplication;
- timers, heartbeats, retries, polling, frame updates, and progress callbacks;
- banner ad refresh callbacks copied to product analytics;
- both request-start and request-success when only completion affects a decision;
- both client success and backend success for the same user outcome;
- dynamic event names containing IDs, routes, content, or errors;
- event names that are not `snake_case`;
- raw timestamps, UUIDs, URLs, filenames, prompts, query text, colors, or descriptions as properties.

## Cardinality budget

Prefer booleans and enums. Product/package IDs and stable feature names are acceptable bounded
dimensions. Treat source/reason strings as enums even if represented as strings in code. Categorize
errors before logging.

Avoid user ID as a custom event property when the provider's identity column is sufficient. Include
a subscription customer ID only when the requested backend/export workflow genuinely needs it and
the privacy contract allows it. Never use advertising or device identifiers as the primary account
identity.

## Mobile specifics

- Disable automatic screen reporting when manual semantic screen names are authoritative; do not run
  both.
- SwiftUI/Compose/React Native lifecycle callbacks can repeat during navigation and state updates;
  deduplicate screens and fire outcomes from models/services when possible.
- Record permissions only after the system result resolves.
- Record sharing only after completion, not when the share sheet opens.
- Refresh subscription user properties after purchase, restore, login/logout, and entitlement
  delegate updates.

## Backend specifics

- Use structured JSON logs with stable event/category/status fields.
- Never log auth tokens, subscription customer IDs, raw request bodies, prompts, or provider response
  bodies.
- Disable or sample routine invocation/access logs when pricing or volume matters; retain explicit
  low-volume failures and sample traces.
- Bound upstream response bodies and request durations before parsing or logging.
- Cache only successful upstream decisions; do not cache outages as authorization failures.
- Avoid logging successful requests when the client already records the accepted product outcome.

## Minimum useful documentation

Document destinations, automatic collection, identity, user/global properties, event names, exact
fire points, allowed property values, omitted signals, environment behavior, backend logging/sampling,
and a deletion rule for unused events.
