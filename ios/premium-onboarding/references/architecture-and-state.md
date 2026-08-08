# Architecture and state

## Module boundaries

Use a small MVVM-C feature:

```text
Onboarding/
├── Model/          presentation intent, root screen, ordered step, selections
├── Service/        permissions and rich haptics
├── View/           root, shared shell, footer, welcome, specialized steps
├── ViewModel/      state, navigation, persistence, analytics
├── Coordinator/    presentation, nested flows, dismissal
└── PreviewSupport  explicit preview dependency factory
```

Keep permission requests, persistence writes, analytics, purchases, and
coordinator presentation outside SwiftUI `body`.

## Launch-state matrix

Persist marketing-shown and setup-completed independently:

| Forced | Marketing shown | Setup complete | Result |
|---|---:|---:|---|
| Yes | Any | Any | Full flow for automation |
| No | No | No | Marketing, then setup |
| No | No | Yes | Marketing only, then dismiss |
| No | Yes | No | Resume setup |
| No | Yes | Yes | Present nothing |

Represent the result with a typed presentation intent. Preview mode must not
write persistence or analytics. Debug mode should intentionally exercise the
production flow through the same coordinator entry point.

## Enum-driven chrome

Make the step enum own computed properties for progress visibility, analytics
name, CTA title, CTA validity, secondary action, footer ownership, and scroll
policy. Keep action routing in one exhaustive switch.

Trim all user-entered text. Derive CTA validity rather than duplicating conditions
in views. Disabled controls use no haptic feedback.

## Coordinator contract

The coordinator owns the opaque full-screen hosting controller, dismissal, and
nested account, settings, permission, or purchase flows. Use a typed delegate or
bridge. Do not let production children dismiss themselves directly.

Continuously rendered layers can update after UIKit starts dismissing the host,
leaving cards or tiles visually orphaned. Freeze the complete host immediately
before dismissal:

```swift
@MainActor
final class OnboardingHostingController<Content: View>: UIHostingController<Content> {
    private var isDismissingAsSingleLayer = false

    func dismissAsSingleLayer() {
        guard !isDismissingAsSingleLayer else { return }
        isDismissingAsSingleLayer = true
        view.layoutIfNeeded()
        let liveSubviews = view.subviews

        if let snapshot = view.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = view.bounds
            snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            snapshot.isUserInteractionEnabled = false
            snapshot.accessibilityElementsHidden = true
            UIView.performWithoutAnimation {
                view.addSubview(snapshot)
                liveSubviews.forEach { $0.isHidden = true }
            }
        }
        dismiss(animated: true)
    }
}
```

Set the hosting view's semantic background and `isOpaque = true`. Drawing groups
and extra SwiftUI exit animations do not guarantee single-surface dismissal.

## Footer and scrolling policy

Use `safeAreaInset(edge: .bottom)` for the shared footer. Extend its background
through the safe area while keeping controls above the home indicator. Let
permission, paywall, or timed steps own a specialized footer only when their
action state is independent.

Do not wrap every step in a scroll view. Choose per step. Inputs, selection grids,
and demos usually need scrolling; concise proof, solution, and completion screens
often do not. The name/input step must survive the keyboard with focus-driven
scrolling and a footer that moves safely.

## Async work

Run delays, parsing, permission refreshes, and processing outside `body` using
cancellable tasks. Check cancellation before advancing and mutate UI state on the
main actor. Cancel pending work and haptic players when the view disappears.
