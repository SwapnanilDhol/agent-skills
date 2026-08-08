# Product demonstrations, permissions, and offers

## Demonstrate the real product

Reuse a shipping component populated with safe demo data. While work is pending,
redact a stable placeholder instance of that same component in place. Keep its
identity and geometry close to the result so the interface does not jump.

Use varied, natural user examples that demonstrate flexibility rather than one
rigid syntax. Localize language, names, units, number formatting, and currency.
Never emit user-entered demo text to analytics.

## Processing

Use a processing screen only when a short pause improves pacing between
configuration and demonstration. Keep it brief, cancellable, asynchronous, and
single-advance. Do not imply server or intelligence work that is not occurring.

## Account or source setup

Use plausible values and the product's real visual language. Reflect earlier
locale or unit choices. Present existing entry flows through the coordinator.
Allow deferral only when the app remains useful and the later recovery path is
clear.

## Notification permission

Show value before calling the system API. Build compact, vertically stacked
notification previews using the real app icon, user-facing bundle name, relative
time, concise title, one- or two-line body, system-like material, restrained
padding, and subtle shadow. Use notification categories and tone that the app can
actually send.

Drive actions from a finite state:

| Authorization | Primary | Secondary |
|---|---|---|
| Not determined | Enable notifications | Enable later |
| Enabled | Send test notification | Continue |
| Denied | Open Settings | Enable later |

Refresh state whenever the scene becomes active so returning from Settings
updates the screen.

## Paywall

Place the offer after demonstrated value. A paywall may own its footer because
selection, purchase, and loading alter CTA semantics. Keep entitlement and
purchase orchestration outside the view. Track offer viewed, plan selected,
purchase started/completed/failed, restore, and skip with non-sensitive metadata.

Do not disguise a paywall as a mandatory setup step when the user can defer it.
Make cancellation and continuation behavior explicit.

## Completion

Treat completion as the handoff, not another explainer. Confirm the configured
result, personalize concise copy when appropriate, place it immediately above the
CTA, commit persistence once, and dismiss through the coordinator. Do not mark
completion merely because the screen appeared.
