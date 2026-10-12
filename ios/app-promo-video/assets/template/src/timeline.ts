// Shape of public/timeline.json, written by scripts/build-timeline.mjs.
// A segment is either a cut from a simulator recording or a mocked scene
// from the registry in src/scenes/mock/index.tsx.
export type Segment = {
  id: string;
  caption: string;
  durationInFrames: number;
} & (
  | { kind: "video"; src: string; rate: number; trimBeforeFrames: number }
  | { kind: "mock"; mock: string }
);

export type Timeline = {
  fps: number;
  scenes: { intro: number; wall: number; flow: number; outro: number };
  segments: Segment[];
  totalFrames: number;
};
