# Adaptive iPad onboarding layout

Treat iPad as a distinct composition, not an enlarged phone.

## Contents

- [Full-screen presentation](#full-screen-presentation)
- [Width caps](#width-caps)
- [Standard vertical composition](#standard-vertical-composition)
- [Shared scroll container](#shared-scroll-container)
- [Footer scrim](#footer-scrim)
- [Full-bleed welcome stage](#full-bleed-welcome-stage)
- [iPad verification](#ipad-verification)

## Full-screen presentation

Present onboarding modally over the split-view controller. Installing a wizard
inside the primary or secondary column clips full-bleed artwork and can leave the
other column visible over it.

Keep the split view valid behind the modal:

- install a real placeholder in the secondary column before presentation;
- prefer tiled split behavior when overlay would cover the secondary content;
- verify portrait behavior even when onboarding is authored primarily for
  landscape;
- if the app intentionally supports only legacy full-screen landscape on iPad,
  verify its orientation plist and current App Store validation requirements.

## Width caps

Start with separate caps for content and decorative artwork:

```swift
enum AdaptiveOnboardingLayout {
    static let contentWidth: CGFloat = 640
    static let decorativeStageWidth: CGFloat = 560
}
```

Cap first, then center:

```swift
content
    .frame(maxWidth: AdaptiveOnboardingLayout.contentWidth)
    .frame(maxWidth: .infinity)
```

Apply the same pattern to footer controls. Do not let copy, cards, or a primary
button span the full width of a landscape iPad.

Decorative positions often use normalized coordinates such as
`size.width * item.x`. Cap the stage itself before calculating those positions;
limiting each tile independently does not prevent the field from scattering off
both edges.

## Standard vertical composition

Use this relationship:

```text
progress
┌──────────────────────────────────┐
│            flexible             │
│       visual/interactive hero    │
│            flexible             │
├──────────────────────────────────┤
│ eyebrow · headline · subtitle   │
│ optional controls/cards          │
├──────────────────────────────────┤
│ footer scrim + CTA + safe area  │
└──────────────────────────────────┘
```

The hero belongs in the middle of the stage above the copy. Equal flexible space
above and below the hero prevents the common “card pinned to the top” failure.

## Shared scroll container

Every ordinary step should pass through one capped container. A representative
shape is:

```swift
GeometryReader { proxy in
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 0) {
            Spacer(minLength: 16)
            hero
            Spacer(minLength: 22)
            headlineAndControls
        }
        .frame(
            maxWidth: AdaptiveOnboardingLayout.contentWidth,
            minHeight: max(proxy.size.height - 32, 0),
            alignment: .top
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    .scrollBounceBehavior(.basedOnSize)
    .scrollDismissesKeyboard(.interactively)
}
```

Audit every step for direct `ScrollView`, `GeometryReader`, or custom footer use.
Fixing the shared container cannot affect a step that bypasses it.

## Footer scrim

Translucent buttons reveal scrolling cards beneath them on short landscape
viewports. Fade from clear into the semantic system background and extend the
fade above the controls:

```swift
LinearGradient(
    stops: [
        .init(color: Color(.systemBackground).opacity(0), location: 0),
        .init(color: Color(.systemBackground), location: 0.3),
        .init(color: Color(.systemBackground), location: 1)
    ],
    startPoint: .top,
    endPoint: .bottom
)
.padding(.top, -30)
.allowsHitTesting(false)
.ignoresSafeArea(edges: .bottom)
```

Keep two responsibilities separate: the scrim reaches the physical edge, while
button content respects the bottom safe-area inset.

## Full-bleed welcome stage

Measure full-bleed height as geometry height plus top and bottom safe-area
insets. Let decorative art extend behind the status bar, but keep copy and footer
inside their capped columns. A hero stage around 55–65% of full height is a useful
starting range, not a universal constant.

## iPad verification

Review every step in landscape and portrait-capable states for:

- capped, centered content and controls;
- hero centered in its upper stage;
- decorative elements inside the authored field;
- no sidebar or secondary-column overlay;
- footer scrim fully masking scrolling content;
- keyboard and Dynamic Type without clipped CTA or copy;
- no step bypassing the shared container;
- semantic backgrounds in light and dark appearance.
