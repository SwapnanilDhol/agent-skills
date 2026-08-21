---
name: premium-onboarding
description: Design, implement, refactor, or review polished multi-step onboarding for SwiftUI iPhone and iPad apps. Use for first launch, interrupted setup, returning-user marketing, personalization, product demos, permissions, paywalls, completion handoff, onboarding state machines, shared CTA shells, motion and haptics, adaptive iPad layout, split-view presentation, accessibility, analytics, previews, or onboarding QA.
---

# Premium Onboarding

Build a paced product story, not a settings form with decorative styling. Keep
the product narrative app-owned while reusing the host design system's progress,
typography, cards, buttons, materials, settings rows, and haptic primitives.

## Inspect before designing

1. Read repository instructions and the onboarding module map.
2. Inspect current launch routing, persistence flags, coordinator conventions,
   design-system components, notification service, purchase flow, analytics,
   and the real product views that onboarding can demonstrate.
3. Read the design-system capability catalog and feature-discovery guide before
   writing reusable UI. Use public foundation primitives directly when they
   fit; wrap them for product-specific behavior; do not invent an app-footer or
   other component API that the package does not expose.
4. Run the existing flow on the smallest supported iPhone and a landscape iPad.
5. Identify whether the task is a new flow, migration, visual refactor, launch
   bug, iPad adaptation, permission/paywall change, or motion polish.
6. Preserve user data and existing-user launch behavior during migration.

## Author the narrative first

Use this shape:

**Attract → Personalize → Validate → Demonstrate → Ask → Deliver**

Give every screen one communication goal and one obvious primary action. Keep a
screen only when it changes configuration, increases confidence, demonstrates a
core behavior, prepares a permission, advances justified purchase intent, or
provides necessary pacing. Remove everything else.

Read [references/screen-sequence.md](references/screen-sequence.md) to choose and
order screens. Do not mechanically copy every example step.

## Model presentation separately from progress

Persist at least two independent facts when returning users may see new
marketing without repeating setup:

- whether the marketing experience was shown;
- whether setup was completed.

Resolve a typed presentation intent such as first launch, returning-user
marketing, resumed setup, debug, or preview. Unit-test the full launch matrix.
Mark marketing when it is displayed; mark completion only after the final action
succeeds. Debug and preview must not corrupt production state.

Read [references/architecture-and-state.md](references/architecture-and-state.md)
for the launch matrix, coordinator contract, enum-driven chrome, async rules,
and single-layer dismissal pattern.

## Build one adaptive shell

Use an ordered step enum as the single source of truth for:

- progress index and analytics name;
- primary and secondary CTA titles;
- enabled and loading state;
- action routing;
- shared versus specialized footer ownership;
- scrolling policy;
- transition direction.

The shared shell owns progress, step transitions, content geometry, and the
bottom safe-area footer. Individual steps own only their visual, copy, and input.
The welcome screen may intentionally use no footer and place its direct CTA at
the bottom. Permission, inline-paywall, or timed steps may own a specialized
footer; never render both footers. Keep footer geometry in one shared container
that owns the content cap, horizontal padding, safe-area extension, and surface.
Specialized steps should replace the controls, not duplicate that geometry.

Use three regions on a standard screen:

1. bounded visual or interactive stage;
2. eyebrow, headline, and supporting copy near the bottom;
3. pinned CTA and optional secondary action.

Place the hero in the middle of the space above its copy with flexible space
above and below. Do not pin it under progress with a large dead zone beneath.
Every step uses the same eyebrow/title/subtitle hierarchy.

There are two intentional exceptions to the standard hero composition:

- List-first selection screens omit decorative artwork entirely. Give the list,
  title, and supporting copy the full screen; keep deliberate top spacing below
  progress and use full-width, pressable choice rows. Keep unselected rows on a
  neutral semantic surface; reserve stronger tint, stroke, and checkmark color
  for selection instead of filling every option with a saturated gradient.
- Paywalls that already show inline plans omit a hero graphic to preserve real
  estate for benefits and pricing. Use compact, interactive feature chips for
  lightweight product highlights, then place the real inline plan selector
  below them.

Read [references/inline-paywall-and-footers.md](references/inline-paywall-and-footers.md)
for the implementation patterns and ownership matrix.

## Treat iPad as a required design mode

Read and apply [references/ipad-layout.md](references/ipad-layout.md). The core
rules are non-negotiable:

1. Present the wizard full-screen over the split view, never inside a column.
2. Cap and center copy, controls, cards, and footers instead of stretching them.
   Start with a 640-point content cap and tune from visual evidence.
3. Cap decorative scatter stages independently; start near 560 points.
4. Make every step render through the shared capped container. Audit exceptions.
5. Center each hero vertically in the stage above the copy.
6. Protect footer contrast on short landscape viewports. An inline paywall is a
   deliberate exception: its material footer should reveal the plan cards so
   the offer does not appear to contain only one plan.
7. Keep a valid secondary split-view controller behind the modal and use a tiled
   split behavior when overlay would obscure content.
8. Verify orientation declarations and current App Store requirements. Do not
   expose unsupported portrait layouts merely to silence validation.

## Demonstrate real value before asking

Reuse production components populated with stable demo models. Keep loading and
result geometry identical by redacting the real component in place. Avoid fake
marketing cards that drift from the shipping product.

Show believable permission value before presenting the system prompt. Drive
permission CTA behavior from a finite authorization-state enum and refresh it
when the scene becomes active.

Place a paywall only after the user understands the product. When the purchase
package provides an inline plan selector, embed that production component in
the onboarding content instead of building a second plan UI. The primary CTA
should purchase the currently selected plan directly; use a clearly secondary
free-continuation action. Do not retain “see plans and pricing” copy or a trial
footnote when the plans and their trial eligibility are already visible.
Keep entitlement, purchase, restore, and coordinator logic outside the SwiftUI
view. Make defer or skip semantics explicit.

Read [references/product-surfaces.md](references/product-surfaces.md) when the
flow contains a demo, processing step, notification request, paywall, account
setup, or personalized completion.

## Add motion after geometry is stable

Model opening motion with explicit phases. Render decorative items once with
stable IDs and authored final positions; animate transforms rather than swapping
hierarchies or generating random coordinates. Blend ambient drift only after the
main spring settles.

Apply transitions at both the root marketing/setup boundary and the setup-step
boundary. Make every delayed sequence cancellable. When a welcome burst is
leaving, clear or hide its outgoing decorative hierarchy immediately so it
cannot remain visible through the next screen. Give the hosting surface an
opaque semantic background. Provide an intentional Reduce Motion composition
and test rich haptics on a physical device.

Read [references/motion-and-haptics.md](references/motion-and-haptics.md) before
implementing a hero burst, CTA morph, ambient animation, or haptic score.

## Preserve coordinator ownership

Present onboarding from a coordinator using one opaque full-screen hosting
surface. The coordinator owns dismissal and nested account, settings, permission,
and purchase flows. Production children must not bypass it with environment
dismissal.

When continuously rendered SwiftUI or UIKit-backed content leaves orphaned
layers during dismissal, snapshot the complete hosting view immediately before
UIKit dismisses it, hide the live subviews, and animate that one stable surface.
Do not treat drawing or compositing groups as a dismissal fix.

## Instrument and make accessible

Instrument marketing, start, step viewed, step completed, selection changed,
and completion events with stable machine IDs and a presentation source. Log a
step view once per presentation. Never send names, free-form demo input, or
other user-entered content.

Design VoiceOver, Dynamic Type, Reduce Motion, contrast, keyboard behavior, and
44×44-point targets alongside the primary experience. Hide decorative artwork
and redacted placeholders from accessibility.

Read [references/quality-gates.md](references/quality-gates.md) for analytics,
preview dependencies, unit/UI tests, visual matrices, failure diagnosis, and the
definition of done.

## Implement in dependency order

1. Product map and screen success conditions.
2. Presentation intent, persistence, step enum, launch resolver, and tests.
3. Shared adaptive shell, progress, footer, scrolling, and keyboard geometry.
4. Static personalization and completion screens.
5. Real product demos and permission previews.
6. Motion, haptics, and Reduce Motion.
7. Analytics, accessibility identifiers, previews, visual QA, and rollout.
8. Remove the old flow only after all production entry points use the new
   coordinator and the full app builds successfully.
9. Validate list screens, inline plan visibility through the paywall footer,
   direct purchase completion, Wallet preview presentation, and welcome-to-next
   screen artifacting as first-class onboarding states.

## Completion gate

Do not mark onboarding done until it passes phone and iPad layout, launch-state,
keyboard, localization, accessibility, permission, purchase, physical-device
motion/haptic, and frame-by-frame dismissal checks in
[references/quality-gates.md](references/quality-gates.md).
