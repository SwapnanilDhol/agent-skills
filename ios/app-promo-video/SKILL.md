---
name: app-promo-video
description: Produce a polished vertical promo video for an iOS app with Remotion — mocked AI/camera scenes that end on hand-picked results, real Simulator recordings of the deterministic flows inside a drawn iPhone, beat-synced captions, and a synthesized music bed. Use when asked for an app promo, launch video, App Store preview-style video, or social clip of an iOS app, or when re-recording or re-cutting an existing promo/.
---

# iOS app promo video (Remotion)

Builds a ~30–40 s 1080 × 1920 promo in `<app-repo>/promo/`: intro → content
wall → a drawn iPhone that plays mocked scenes and real Simulator recordings
under changing captions → outro, all on a 120 BPM beat grid with a generated
funk bed. First built for PassMaker (camera scan → AI prompt → template →
recolour → Add to Apple Wallet → Wallet app).

Read [references/styling.md](references/styling.md) before designing scenes and
[references/simulator-capture.md](references/simulator-capture.md) before the
first recording. [references/cuts-and-verification.md](references/cuts-and-verification.md)
covers picking cut points and checking the render.

## Workflow

1. **Scaffold.** `scripts/scaffold.sh <app-repo>` copies `assets/template/` to
   `<app-repo>/promo` and runs `npm install`. Never overwrite an existing
   `promo/`.
2. **Storyboard with the user** before building: 4–7 phone beats, one idea
   each, captioned in ≤ 5 words ("Snap any ticket", "Or just describe it",
   "Make it yours", "Add it to Apple Wallet"). Lead with the most magical
   feature; end on the payoff in a system surface (Wallet, Home Screen widget,
   Share sheet) if the app has one.
3. **Decide mock vs record per beat.** Mock anything whose real output you
   don't control: AI results, camera, network, other people's data. Record
   only deterministic UI. Mocks always end on a polished, hand-picked result
   (a gallery item, a designed sample), never live AI output.
4. **Brand and assets.** Fill in `src/brand.ts` (name, taglines, CTA, wall
   copy, background = the app's own canvas) and `assets.json` (icon and wall
   images, as paths in the app repo; `npm run` copies them into the
   gitignored `public/assets/`).
5. **Mocks.** Configure `src/scenes/mock/index.tsx`: `CameraMock` (viewfinder →
   lock-on → shutter → "reading" → reveal) and `PromptMock` (prompt types
   itself → working shimmer → reveal), or write new ones in iPhone points with
   `components/ios.tsx`. For a camera scene, design the photographed object
   in `src/stills/SourcePhoto.tsx` to match the reveal (same name, date,
   colours), then `npm run source-photo` (real QR via Core Image).
   If the app has deterministic screenshot scenes, end mocks on real screens
   instead: `npm run capture-screens -- <udid>` (`scripts/capture-screens.sh`)
   and animate them with `components/ScreenBuild.tsx` (pass it through
   `CameraMock`'s `renderReveal`); fake scrolls from two stills with
   `ScrollMock` rather than recording them. See `references/styling.md`.
6. **Record.** Write the app's scenes at the bottom of
   `scripts/capture-flow.sh` (library on top: relaunch, responsiveness probe,
   per-scene `rec_start`/`rec_stop`, pixel waits for remote sheets), boot a
   simulator on the right OS, check host load, then
   `BUNDLE=… LAUNCH_ENV=… npm run capture -- <udid>`.
7. **Cut.** Make contact sheets (`scripts/contact-sheet.sh`), read the frames,
   and set `from`/`to` seconds per segment in `scripts/build-timeline.mjs`.
   Split idle stretches into two windows; skip transition flashes and
   cold-launch black.
8. **Review and render.** `npm run dev` for Studio; render stills of every
   segment and look at them; `npm run render`; `scripts/check-black.sh
   out/promo.mp4`; `npm run render-preview` for the App Store app preview
   (886 × 1920). Tell the user what you checked by stills vs what needs a
   full-speed watch.

## Hard rules

- **Never show live AI output in marketing.** It was flat, crowded or
  unreadable more than once; mock it and reveal a curated result.
- **Pick reveals for contrast.** White text on a vivid image beats dark text
  on a muddy blur; check every pass/card the viewer sees, including ones that
  leak in from test runs (an old item in Wallet's list).
- **One edit per "make it yours" beat.** Several colour changes read as
  indecision; change one thing once and carry it to the ending.
- **Playback rate 1 for recordings.** 1.25×/1.6× judders. Cut, don't speed up.
- **Stay within 29 s.** App Store app previews must run 15–30 s; the
  template's intro/wall/outro leave 45 beats for the phone scene, and
  `build-timeline.mjs` warns when the total drifts outside the window.
- **Don't trust wall-clock marks for cuts.** Simulator recording timing drifts
  under load; pick cuts from frames, and re-check after every re-capture.
- **Check host load before recording** (`sysctl -n vm.loadavg`). Ask the user
  before shutting down simulators you didn't boot.
- **Use the app's canvas, not a decorative gradient**, and ask before deleting
  old marketing assets — but do remove the ones the user calls out.
- Don't commit recordings, renders, music or `node_modules` (the template's
  `.gitignore` covers them); do commit the scripts so the video is
  reproducible.

## Files

| Path | Purpose |
|---|---|
| `assets/template/` | The Remotion project copied into the app |
| `scripts/scaffold.sh` | Copy template + `npm install` |
| `scripts/contact-sheet.sh` | Tile a recording's frames to pick cuts |
| `scripts/check-black.sh` | Find black frames on the phone screen of a render |
| `references/styling.md` | Visual system, motion, captions, music |
| `references/simulator-capture.md` | Simulator, `axe`, Wallet and recording pitfalls |
| `references/cuts-and-verification.md` | Cut picking, timeline, render checks |
