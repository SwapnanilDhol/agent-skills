# Styling

The look that landed for PassMaker, and why. All values live in the template;
change them in one place (`src/brand.ts`, scene files) rather than per scene.

## Canvas

- 1080 × 1920, 30 fps, 29 s by default. App Store app previews must run
  15–30 s, so one cut serves both; the `AppPreview` composition renders the
  same timeline at 886 × 1920 (the exact 6.9" iPhone preview size) and
  `npm run render-preview` re-encodes it to spec (H.264 High, 30 fps, AAC
  stereo 44.1 kHz). The drawn iPhone fits both widths.
- Background = the app's own surface: iOS grouped background `#F2F2F7`
  with a faint 36 px dot grid (the app's Home screen texture). A purple marketing gradient was rejected as "old screenshot"
  styling.
- Ink `#111014`; SF Pro Display via the system font stack (renders because
  Remotion's headless browser runs on macOS).

## Structure

| Scene | Length | Notes |
|---|---|---|
| Intro | 60 frames (4 beats) | Icon springs in with a slight rotation, then name (112 px, 800, −3 tracking), then tagline. The groove drops when it ends. |
| Wall | 60 frames | Three tilted (−8°) columns of content cards drifting in alternating directions, scale-in on entry, under a frosted white caption card ("60+ templates"). |
| Phone | sum of segments (675 frames / 45 beats fills 29 s) | One drawn iPhone stays on screen; mocks and recordings swap inside it; captions change above it. |
| Outro | 75 frames | Icon, name, two-line description, black CTA pill. |

## Drawn iPhone

- Screen 640 px wide, aspect from the recordings (402 × 874 points), bezel
  18 px `#0B0B0D`, outer radius 112, screen radius 96, a 4 px `#3A3A40` rim
  and a soft purple-black drop shadow.
- Enters with a spring from below (damping 16), exits by fading, dropping and
  scaling to 0.92 over 12 frames.
- Mocks are laid out in device points (`PointsScreen`) so they line up 1:1
  with real recordings; include the status bar (9:41, full battery). The
  Dynamic Island is drawn once by `Flow.tsx` over every clip.

## Captions

- 92 px, weight 800, −2.5 tracking, centred 120 px from the top.
- Spring in (damping 200) with a 40 px rise; fade and lift 30 px over the last
  8 frames. Consecutive segments with the same caption share one caption.
- ≤ 5 words, verbs first, story-shaped: "Snap any ticket" → "Or just describe
  it" → "Or start from a template" → "Make it yours" → "Add it to Apple
  Wallet" → "Right in your Wallet".

## Mock vocabulary

- **Camera**: black chrome bars, handheld wobble (sin/cos, 3–4 pt), yellow
  `#FFD60A` lock-on outline that springs from 40 pt larger, shutter press
  (scale 0.82) + white flash, then blur/dim the photo with a sweeping blue
  scan line and two status lines.
- **Prompt**: white sheet over grey, title + subtitle, prompt card types the
  text over ~2 s with a blue caret, chips (first one selected), primary button
  pressed then a purple→pink shimmer "Creating…" with a sparkle.
- **Reveal**: success chip (green dot), result card springs up with a slight
  rotation (damping 13), primary button slides in; the prompt reveal adds a
  six-sparkle burst.
- The **source photo** for a camera scene: the object on a warm oak desk
  (layered gradients for grain), rotated −5°, real drop shadow, vignette;
  everything on it matches the reveal.
- Every mock in the drawn iPhone gets the **Dynamic Island** from `Flow.tsx`
  (an overlay above all clips): simctl screenshots and recordings omit it.

## Mock on the app's own screens

When a scene can't be recorded (AI, camera, sample data) but the app can
render the result screen deterministically, mock the *path* and end on the
*real* screen instead of a drawn card:

- Capture the screen as a 3× still with `scripts/capture-screens.sh` (the
  app's debug screenshot-scene launch mode, fixed data, pinned status bar).
- Animate it with `components/ScreenBuild.tsx`: the static base fades in,
  then horizontal bands (a card, a list, a message bubble; `top`/`bottom` in
  points) spring up into place at their own frames. Bands are masked out of
  the base so nothing shows twice; `from: "fade"` for bands that shouldn't
  move. Two to four bands, 6–10 frames apart, reads as "building".
- Chain it after a mocked input: `CameraMock`'s `renderReveal={(start) =>
  <Sequence from={start}><ScreenBuild … /></Sequence>}` ends the camera on
  the real result instead of a `ResultReveal` card.
- **Scrolls: stitch stills instead of recording.** simctl drops frames during
  a fast scroll and it visibly stutters. Capture the screen at rest and
  scrolled, measure the offset off one row (its y in both captures), and use
  `scenes/mock/ScrollMock.tsx`: the page moves as one stitched strip while
  only the header and floating chrome (tab bar pills, as clip-path insets)
  stay pinned and cross-fade to their scrolled look.
- Real copy and layout beat drawn approximations; only draw what the app
  can't render in a screenshot scene.

## Music

- 120 BPM so 1 beat = 15 frames; every scene and segment is floored to whole
  beats so cuts land on the beat.
- `synth-music.py` (numpy): swung 16ths (58 %), kick on 1/"a of 1"/3+, snare
  on 2 and 4 with ghost notes, slap-style bass with octave pops (tanh
  saturation), clav stabs on off-beats over an Em7 – A7 vamp. A filtered clav
  plays under the intro, a snare fill leads into the drop, the last bar is a
  single ringing stab. Placeholder quality; swap in a licensed track for
  launch.
- Music volume fades in over 10 frames and out over the last 20.
