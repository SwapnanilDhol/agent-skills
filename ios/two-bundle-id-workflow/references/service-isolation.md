# Service isolation decisions

Record one decision per service; “same as production” is allowed only when it
is deliberate and tested.

| Service | Minimum decision |
|---|---|
| Mixpanel/analytics | disabled, or a separate development project |
| Firebase/Crashlytics | separate Firebase app/plist, or disabled |
| RevenueCat | controlled preview identity/entitlements; never accidental real purchase testing |
| Backend | staging, or production with an explicit preview marker and safe data policy |
| APNs | development topic/environment matching the development App ID |
| URL schemes | distinct development scheme |
| Associated domains | separate development route, or disabled |
| Keychain groups | split or explicitly proven safe to share |
| CloudKit | separate container/environment decision |
| App groups | always split between development and production |

Never put service secrets in the identity manifest, xcconfig, generated
templates, Slack, or source control.
