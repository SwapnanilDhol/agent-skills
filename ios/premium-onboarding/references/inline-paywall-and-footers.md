# List-first screens, inline paywalls, and footers

Use these patterns when an onboarding step is dominated by choices, an inline
purchase selector, or a result preview. They refine the standard hero/copy/CTA
composition; they do not replace the launch-state and coordinator rules.

## List-first selection screens

Use a list-first composition when the user is choosing a goal, pain point,
pass type, or another meaningful option:

- Omit decorative hero artwork. The list is the visual stage.
- Keep the title and supporting copy above the list, with intentional spacing
  below the progress indicator. Do not let the first row touch the progress bar.
- Prefer the shared scroll shell with an empty hero and zero hero-to-headline
  spacing rather than adding a hidden placeholder with an arbitrary height.
- Use full-width selection rows/cards with a clear icon tile, concise title,
  optional two-line subtitle, selected tint, checkmark or selected symbol, and
  a 44-point-or-larger hit target.
- Add a press treatment that respects Reduce Motion. Selection must be
  communicated by more than color.
- Keep the shared footer behind the primary Continue action. Disable it until
  the required selection count is valid, and use stable option IDs for state and
  analytics rather than localized labels.

Representative structure:

```swift
OnboardingScrollableStep(
    eyebrow: "CHOOSE YOUR STARTING POINT",
    title: "What are you making today?",
    subtitle: "Pick one so we can tailor the examples.",
    heroToHeadlineSpacing: 0
) {
    EmptyView()
} content: {
    LazyVStack(spacing: 12) {
        ForEach(options) { option in
            OnboardingSelectionCard(
                icon: option.icon,
                title: option.title,
                color: option.tint,
                isSelected: selectedIDs.contains(option.id),
                accessibilityIdentifier: "onboarding.option.\(option.id)"
            ) { toggle(option.id) }
        }
    }
}
```

Use `SFKSelectableChip` or `SFKChipFlowLayout` for compact optional tags and
filters, not for choices that need explanatory copy or a large hit surface.

## Inline purchase screens

When SwapProKit (or the host purchase package) supplies an inline selector:

1. Embed the production inline view in the onboarding content, for example
   `SwapProInlineView(viewModel: proManager)`.
2. Keep the selected plan in the purchase manager. Gate the direct purchase CTA
   on `selectedPlan != nil` and a separate loading state.
3. Use a direct primary title such as “Unlock Pro” or “Start Pro”. The action
   calls the manager’s purchase method for the selected package.
4. Use “Continue with Free” as a visually secondary action. It must remain
   explicit and accessible, but must not compete with purchase visually.
5. Remove “See plans and pricing” when plans are already on screen. Remove
   generic trial footnotes when eligibility is represented by the inline plans.
6. Keep entitlement, restore, purchase error handling, analytics, and successful
   purchase handoff in the manager/coordinator layer. The view observes state
   and emits only user intent.
7. Set the manager’s presentation reason before loading the inline offer and
   record offer view once per presentation. Record plan selection, purchase
   start/result, restore, and free continuation with stable IDs.

Do not duplicate plan cards, pricing logic, or trial rules in onboarding. The
inline purchase component is the source of truth for available plans.

## Feature chips and micro-interactions

Remove a large paywall hero graphic when it consumes space needed by pricing.
Use a small set of concise benefit chips above the inline selector:

- Use the design system’s public chip primitive directly when available.
- Give chips distinct but restrained tints and meaningful SF Symbols.
- Keep the interaction lightweight: a tap may highlight one chip, add a small
  accessory checkmark, and provide the primitive’s built-in haptic/press
  feedback. Highlighting is explanatory UI, not a required purchase selection.
- Keep chip state separate from the selected plan state.
- Do not turn every benefit sentence into a long pill; shorten copy so the
  group wraps naturally on small phones and iPad.

## Footer ownership and transparency

Use `safeAreaInset(edge: .bottom)` so the action stays above the home indicator.
The screen owns the footer only when its CTA semantics differ from the shared
shell. Never stack a shared footer and a specialized footer.

| Screen | Footer | Background treatment |
|---|---|---|
| Welcome | No footer; direct bottom CTA | Seamless screen background |
| Standard/list step | Shared app footer | Light semantic fill with a subtle separator |
| Inline paywall | Specialized purchase footer | `.ultraThinMaterial` so plan cards remain visible |
| Permission/timed step | Specialized only if action state differs | Match the product surface and protect contrast |

The inline-paywall material is intentional: an opaque system background can
hide the lower plans and make the offer look like it has only one plan. Keep
the material in the footer, not on top of the entire scroll content. Preserve
button contrast, use a one-point separator if needed, and verify the plan cards
remain legible while scrolling in light and dark appearance.

For ordinary footers, use the host app’s existing footer/design-system surface
when it is public. If no public footer exists, compose the local footer from
public primitives; do not reference an imagined package type. Use a low-opacity
semantic fill for stable contrast and extend it through the safe area.

On short landscape layouts, explicitly verify what should show through. A
default footer may need a semantic-background scrim to protect readability;
the inline paywall is the deliberate exception because plan visibility is part
of the offer’s comprehension.

## Wallet-style result previews

When onboarding directly shows a generated Wallet-style pass preview:

- Use a polished, bundled preview asset or the production preview renderer,
  with a stable fallback if loading fails.
- Fill the upper visual region instead of shrinking the pass into a small icon.
- Pin the explanatory title and copy toward the bottom like the other
  bottom-weighted onboarding screens.
- Remove decorative success checkmarks that do not communicate new state.
- Do not show a “Show in Wallet” action if the preview is only a sample or the
  Wallet handoff is not reliable. Use Continue as the primary CTA.
- Keep actual Wallet installation or PassKit handoff in a separate, verified
  product flow.

## Transition and icon artifact prevention

For a welcome screen with a blast/burst animation:

- Resolve the app icon from the correct bundled asset at an appropriate
  resolution, and fail to a branded vector/SF Symbol rather than a generic
  fallback.
- Keep burst items in one stable hierarchy with stable IDs.
- Set an exit phase as soon as Continue is tapped and hide the outgoing burst;
  do not allow it to render under the next step for a delayed cleanup period.
- Give the new step and the root hosting surface a semantic opaque background.
- Use an opacity removal or a frozen host snapshot for UIKit dismissal when live
  SwiftUI/UIKit layers otherwise remain visible.

## Verification checklist

Verify the following states on a small phone and landscape iPad:

- list content is not touching the progress indicator;
- list rows fill the available width and selection is visible without color;
- welcome has no accidental footer background;
- inline plans remain visible behind the material footer;
- primary purchase and secondary free actions have distinct hierarchy;
- chip taps animate without changing the selected plan;
- the direct purchase success notification advances/dismisses once;
- the Wallet preview is large, polished, and has no misleading checkmark or
  broken Wallet action;
- the welcome burst and app icon disappear cleanly at the first transition;
- light/dark appearance, Dynamic Type, Reduce Motion, and VoiceOver remain
  usable.
