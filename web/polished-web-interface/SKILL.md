---
name: polished-web-interface
description: Design, implement, or review polished web product interfaces for dashboards, trackers, editors, and other working surfaces where visual quality, responsive behavior, accessibility, and interaction detail matter.
---

# Polished Web Interface

Build the product surface itself, not a marketing page for it. Make the primary user action
obvious in the first viewport and spend polish on hierarchy, feedback, and the states people
actually encounter.

## Establish the interface direction

Before styling, write down a one-sentence visual thesis that names the product's tone and the
visual decision that will make it recognizable. Use that thesis to choose typography, surface
contrast, borders, radii, spacing rhythm, color, and motion. Do not default to an unmodified
component-library theme or add decorative sections that are not part of the requested workflow.

## Shape the working surface

1. Identify the primary job-to-be-done and put its control or result in the first viewport.
2. Design explicit empty, loading, success, error, disabled, and permission-denied states.
3. Keep navigation and explanatory copy secondary to the work surface.
4. Use semantic HTML and native controls when they provide the right behavior; compose custom
   visuals around them rather than replacing keyboard and accessibility semantics.
5. Preserve user data and existing behavior when revising an interface.

## Use a small, intentional visual system

- Define tokens for page background, surfaces, text tiers, borders, accent, focus, spacing, and
  radii before styling individual components.
- Keep body text readable at normal zoom and through 200% text enlargement. Do not make essential
  labels smaller than 14px.
- Use color to reinforce meaning, never as the only signal. Pair state colors with text,
  borders, icons, patterns, or accessible labels.
- Keep cards and controls visually related but not identical; hierarchy should remain clear when
  several records are present.
- Use one memorable product-specific detail, such as a distinctive grid, accent edge, or compact
  status treatment, instead of accumulating decorative effects.

## Interaction and responsive quality

- Every interactive element needs a visible focus state and a useful accessible name.
- Provide hover, pressed, selected, disabled, and validation feedback where those states exist.
- Keep touch targets comfortable and primary actions full-width when a narrow layout needs it.
- Test at a narrow phone width, a normal desktop width, and with keyboard-only navigation.
- Respect `prefers-reduced-motion`; transitions should clarify state, not delay the task.
- Avoid layout shifts when dialogs, errors, or validation messages appear.

## Review gate

Before handing off, verify the first viewport, empty and populated states, form validation,
keyboard flow, contrast, responsive layout, and browser console. Use a screenshot or live browser
inspection for visual claims. Do not claim polish from a successful build alone.
