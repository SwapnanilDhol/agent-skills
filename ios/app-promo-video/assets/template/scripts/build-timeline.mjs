// Builds the beat-aligned timeline (public/timeline.json) from the segment
// list below and synthesizes a music bed of exactly the same length.
import { execFileSync } from "node:child_process";
import { existsSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const promoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const recordingsDir = join(promoRoot, "public", "recordings");

const FPS = 30;
const BEAT_FRAMES = 15; // 120 BPM: every cut lands on a beat
const floorToBeat = (frames) => Math.max(BEAT_FRAMES, Math.floor(frames / BEAT_FRAMES) * BEAT_FRAMES);

// The phone scene, in order.
//
// - Mocks ({ kind: "mock" }) are named in src/scenes/mock/index.tsx and have
//   fixed lengths in beats.
// - Recordings ({ kind: "video" }) are windows into public/recordings/<src>.mp4,
//   in seconds, picked by eye from a contact sheet (see the skill's
//   scripts/contact-sheet.sh). simctl's frame timing drifts under load, so
//   wall-clock marks from the capture script can't place cuts; re-check these
//   after every re-capture.
// - Keep rate at 1: non-integer rates make motion judder.
// - Jump-cut idle stretches (a picker waiting for a tap, a sheet holding still)
//   by splitting one moment into two windows; the seam is invisible.
// - Consecutive segments with the same caption share one caption on screen.
const segmentSpecs = [
  { kind: "mock", mock: "camera", caption: "Snap any ticket", beats: 10 },
  { kind: "mock", mock: "prompt", caption: "Or just describe it", beats: 11 },
  { kind: "video", src: "edit", caption: "Make it yours", from: 0.8, to: 4.4 },
  { kind: "video", src: "edit", caption: "Make it yours", from: 5.2, to: 6.8 },
];

const missing = [...new Set(segmentSpecs.filter((s) => s.kind === "video").map((s) => s.src))].filter(
  (src) => !existsSync(join(recordingsDir, `${src}.mp4`)),
);
if (missing.length) {
  console.warn(`No recording for: ${missing.join(", ")}. Run \`npm run capture\`; skipping those segments.`);
}

for (const spec of segmentSpecs.filter((s) => s.kind === "video")) {
  if (!(spec.from >= 0 && spec.to > spec.from)) {
    console.error(`Bad cut for "${spec.caption}" in ${spec.src}: ${spec.from}-${spec.to}s.`);
    process.exit(1);
  }
}

const segments = segmentSpecs
  .filter((s) => s.kind !== "video" || !missing.includes(s.src))
  .map(({ beats, from, to, rate = 1, ...segment }, i) => ({
    ...segment,
    id: `${segment.src ?? segment.mock}-${i}`,
    ...(segment.kind === "video"
      ? { rate, trimBeforeFrames: Math.round(from * FPS), durationInFrames: floorToBeat(((to - from) / rate) * FPS) }
      : { durationInFrames: beats * BEAT_FRAMES }),
  }));

// App Store app previews must run 15–30 s, so the default promo is 29 s and
// one render serves both the social cut and the preview. Intro, wall and
// outro take 195 frames, leaving 675 (45 beats) for the phone scene; budget
// segmentSpecs against that.
const MAX_SECONDS = 29;
const scenes = {
  intro: 60, // 4 beats; the groove drops when the intro ends
  wall: 60,
  flow: segments.reduce((sum, segment) => sum + segment.durationInFrames, 0),
  outro: 75,
};
const totalFrames = Object.values(scenes).reduce((a, b) => a + b, 0);
if (totalFrames > MAX_SECONDS * FPS || totalFrames < 15 * FPS) {
  console.warn(
    `Timeline is ${(totalFrames / FPS).toFixed(1)}s; App Store previews need 15–30 s (aim for ${MAX_SECONDS}). ` +
      `The phone scene has ${MAX_SECONDS * FPS - scenes.intro - scenes.wall - scenes.outro} frames.`,
  );
}

writeFileSync(
  join(promoRoot, "public", "timeline.json"),
  JSON.stringify({ fps: FPS, scenes, segments, totalFrames }, null, 2),
);
console.log(`Timeline: ${(totalFrames / FPS).toFixed(1)}s`, scenes);

execFileSync(
  "python3",
  [
    join(promoRoot, "scripts", "synth-music.py"),
    String(totalFrames / FPS),
    String(scenes.intro / BEAT_FRAMES),
    join(promoRoot, "public", "music.wav"),
  ],
  { stdio: "inherit" },
);
