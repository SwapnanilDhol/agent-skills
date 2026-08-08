# Analytics, accessibility, testing, and definition of done

## Contents

- [Analytics contract](#analytics-contract)
- [Accessibility](#accessibility)
- [Preview graph](#preview-graph)
- [Automated tests](#automated-tests)
- [Visual matrix](#visual-matrix)
- [Failure diagnosis](#failure-diagnosis)
- [Definition of done](#definition-of-done)

## Analytics contract

Use stable machine IDs and a presentation source:

| Event | Required properties |
|---|---|
| `onboarding_marketing_viewed` | `source`, `continues_into_setup` |
| `onboarding_marketing_completed` | `source`, `action` |
| `onboarding_started` | `source` |
| `onboarding_step_viewed` | `step`, `source` |
| `onboarding_step_completed` | `step`, `action`, `source` |
| `onboarding_selection_changed` | `step`, `selection`, `source` |
| `onboarding_completed` | `source` |

Log a step view once per presentation. Distinguish continue, defer, skip, close,
and purchase actions. Never send names, free-form input, or localized display
strings as identifiers. Preview mode emits no production events.

## Accessibility

- Hide decorative scatter fields and ambient animation.
- Give each selection card one coherent label and selected trait.
- Expose progress as current step and total steps.
- Label close, confirmation, and icon-only controls.
- Hide redacted placeholders from assistive technologies.
- Announce meaningful parsed or confirmation state changes.
- Test the largest accessibility text size with vertical growth and scrolling.
- Use semantic foreground/background colors in both appearances.
- Never communicate selection only through color.
- Keep touch targets at least 44×44 points.
- Provide an intentional Reduce Motion state.

## Preview graph

Create an explicit preview-support factory. Do not add fake parameterless
production initializers. Include light/dark marketing, representative selections,
permission states, loading/result demos, smallest phone, landscape iPad, large
Dynamic Type, and Reduce Motion.

## Automated tests

Unit-test:

- every launch-matrix row;
- ordered and branched navigation;
- required-selection validation;
- completion persistence;
- earlier choices propagating into later examples;
- analytics view deduplication;
- preview/debug persistence behavior;
- cancellation of delayed transitions.

UI-test:

- forced first launch;
- marketing-to-setup transition;
- keyboard-visible input;
- selection-gated CTA;
- product demo loading to real component;
- permission defer and Settings return;
- paywall skip or purchase handoff;
- completion dismissal;
- returning-user marketing-only dismissal;
- debug entry through the production coordinator.

## Visual matrix

| Dimension | Required cases |
|---|---|
| Device | smallest phone, standard phone, largest phone, landscape iPad |
| Appearance | light and dark |
| Text | default and largest accessibility size |
| Motion | normal and Reduce Motion |
| Keyboard | hidden and visible |
| Safe area | home-indicator and alternate supported geometry |
| Locale | short Latin, long Latin, CJK, RTL when supported |
| State | empty, selected, loading, success, denied permission |

Reference catalogs:

- [Goaley iPhone onboarding catalog](visual-catalogs/goaley-iphone-onboarding.jpg)
- [Goaley iPad onboarding catalog](visual-catalogs/goaley-ipad-onboarding.jpg)

Use these catalogs to compare visual pacing, hero scale, capped content width,
selection states, and footer rhythm across phone and iPad. They document a
real, verified flow; do not copy the product name, artwork, or copy into another
app.

Physical-device checks are required for haptics, keyboard animation races,
high-refresh-rate smoothness, notification authorization, Settings round-trip,
and purchase-sheet behavior.

## Failure diagnosis

| Symptom | Likely cause | Fix |
|---|---|---|
| Hero overlaps copy | Unbounded overlay | Separate bounded stage from bottom copy |
| Hero is pinned high | Flexible space exists only below it | Center hero with flexible space on both sides |
| Artwork flies off iPad edges | Stage uses full iPad width | Cap the decorative stage before normalized positioning |
| CTA spans landscape iPad | Footer lacks content cap | Cap first, then center |
| Cards show through buttons | Transparent footer has no scrim | Add an extended semantic-background gradient |
| One step still stretches | It bypasses the shared container | Audit direct scroll/geometry containers |
| Sidebar overlays onboarding | Wizard is installed in a split column | Present full-screen over the split controller |
| Portrait split opens blank | Secondary controller is missing | Seed a placeholder and verify split behavior |
| Keyboard breaks input step | Fixed hero and no scroll path | Use keyboard-aware geometry and safe-area footer |
| First transition is static | Transition exists only in setup pager | Animate the root marketing/setup boundary |
| Burst flickers | Random geometry or unstable IDs | Render one stable hierarchy and animate transforms |
| Demo feels fake | Onboarding duplicated product UI | Reuse the production component with demo data |
| Existing users repeat setup | One boolean models two facts | Separate marketing shown from setup complete |
| Layers remain during dismissal | Live renderers update during UIKit dismissal | Freeze and dismiss one opaque host snapshot |

## Definition of done

- Narrative screens each have a clear purpose and action.
- Launch, resume, returning marketing, debug, and preview states resolve correctly.
- Every standard step uses the shared adaptive container.
- Phone and iPad geometry are capped, centered, and visually balanced.
- Heroes sit in the middle of their stage and never overlap copy.
- Footer reaches the edge, respects the safe area, and masks scrolled content.
- Keyboard, Dynamic Type, localization, dark mode, and Reduce Motion pass.
- Product demonstrations reuse shipping components and stable placeholders.
- Permission previews and offers are truthful and timed after value.
- Analytics reconstructs the funnel without collecting PII.
- Production coordinator owns every presentation and exit.
- Frame-by-frame dismissal leaves no orphaned cards, text, or animated layers.
- The old flow and duplicate debug path are removed.
- Unit/UI tests pass and the full app builds successfully.
