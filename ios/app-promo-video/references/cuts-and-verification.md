# Cuts and verification

## Picking cuts

Wall-clock marks written during capture drifted by different amounts within
one recording (+1.4 s at one step, −2.5 s at another), and once pushed a cut
below 0 s. Cuts are therefore explicit seconds in `scripts/build-timeline.mjs`,
read off contact sheets:

```bash
scripts/contact-sheet.sh public/recordings/edit.mp4 /tmp/edit.png 2       # overview
scripts/contact-sheet.sh public/recordings/edit.mp4 /tmp/edit-fine.png 4 7 11   # around a tap
```

Frame *i* is at `from + i / fps`. Look for, and cut around:

- **Transition flashes** — e.g. the app briefly showing Home while one sheet
  replaces another (~1.5 s in PassMaker).
- **Cold-launch black** — Wallet showed ~1.5 s of black, then grey/white,
  before its list; start after the first real frame.
- **Idle holds** — a picker waiting for a tap, a sheet sitting still. Split the
  moment into two windows; the seam is invisible because nothing moves.

For single frames use output-side seeking (`ffmpeg -i in.mp4 -ss 12.5 …`);
input-side `-ss` landed on the wrong frame.

`build-timeline.mjs` floors each segment to whole beats (15 frames), skips
segments whose recording is missing (so mocks can be previewed alone), and
rejects cuts with `from < 0` or `to <= from`.

## Reviewing

- Render a still from inside every segment (`npx remotion still src/index.ts
  Promo out/f.png --frame=<n>`) and look at all of them side by side
  (`ffmpeg … hstack`). Compute segment start frames from
  `public/timeline.json` (phone scene starts at intro + wall).
- Check the payoff surfaces specifically: the result card, the system sheet,
  the final shot.
- `scripts/check-black.sh out/promo.mp4` must report no black on the phone
  screen.
- Stills don't show judder; say so and ask the user to watch at full speed.

## Remotion gotchas

- Studio caches `calculateMetadata`'s `timeline.json`; after changing its shape,
  restart `npm run dev` (symptom: `Cannot read properties of undefined`).
- The first `remotion still`/`render` on a machine can time out loading the
  root component while the headless browser downloads; retry.
- `trimBefore` (formerly `startFrom`) must be ≥ 0.
