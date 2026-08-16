# Motion and haptics

Add motion only after static geometry passes phone and iPad review.

## Opening sequence

Model explicit phases such as dormant, charging, bursting, and settled. Keep one
stable hierarchy throughout. Give every decorative item an immutable ID, symbol,
color, normalized final position, size, rotation, drift, speed, phase, and reveal
delay.

Before the burst, render all items at the same center. Animate only offset, scale,
rotation, and opacity. Do not generate random positions during rendering or swap
one hierarchy for another.

A useful starting sequence is:

| Time | Phase | Result |
|---:|---|---|
| 0 ms | Dormant | Center mark visible; decorative items hidden |
| 180 ms | Charging | Mark pulses and emits a ring |
| 1,020 ms | Bursting | Items spring to authored positions |
| 1,520 ms | Settled | Low-amplitude ambient drift blends in |

Use a spring near response `0.58`, damping `0.82`, blend `0.08` for the burst.
Keep stagger subtle. Blend deterministic sine/cosine drift over roughly 0.8
seconds after the main spring settles so the target does not move mid-flight.

## Page transitions

Apply an asymmetric move-plus-opacity transition at both levels:

- marketing to setup at the root boundary;
- step to step inside setup.

Key content by stable step identity. A spring near response `0.5`, damping `0.76`,
blend `0.08` is a starting point. Reduce Motion uses a short crossfade.

When leaving a welcome burst, set an explicit exit phase as soon as Continue is
tapped and hide the outgoing decorative items. A new screen’s opaque semantic
background should be visible immediately; do not rely on delayed view removal
to clean up the previous animation.

## CTA confirmation

For a short personal payoff, a full-width CTA may morph into a centered
confirmation mark, show personalized feedback, then advance after a cancellable
brief delay. Prefer this over adding a whole extra screen with no new value.

## Haptic score

Make haptics tell the same physical story as motion: gather, peak, release,
settle. Use a rich Core Haptics pattern only when it materially improves the
opening. Provide light/heavy/light impact fallbacks and prepare generators before
their moments. Avoid stacking ordinary button haptics over the score.

Validate haptic timing and intensity on a physical device. Reduce transient count
before weakening the main event when a pattern feels buzzy.

For feature chips, prefer the public design-system chip primitive so its press
feedback and light haptic are consistent with the rest of the app. A chip’s
highlight is explanatory micro-interaction, not a purchase or onboarding
selection. Keep that state separate from plan selection and avoid adding a
second competing haptic score.

## Reduce Motion

- skip charging and burst travel;
- present the settled composition immediately or with opacity;
- disable ambient drift;
- replace move transitions with short crossfades;
- make notification arrangements static;
- keep timed steps understandable without motion;
- do not play rich haptic choreography coupled to removed movement.
