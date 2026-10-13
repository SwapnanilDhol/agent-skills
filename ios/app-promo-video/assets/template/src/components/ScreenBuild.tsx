import { CSSProperties } from "react";
import { Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { SCREEN_POINTS } from "./ios";

/** A full-width horizontal slice of the screenshot, in points. */
export type Band = { top: number; bottom: number; at: number; from?: "below" | "fade" };

export type ScreenBuildProps = {
  /** A 3x screenshot in public/ (402 × 874 points). */
  image: string;
  /** Slices that animate in, each at its own frame. Everything else is static. */
  bands?: Band[];
  /** Frame (within the parent) where the static base appears. */
  baseAt?: number;
  /** Colour shown under a band before it lands (the screen's background). */
  canvas?: string;
  style?: CSSProperties;
};

const fullScreen: CSSProperties = {
  position: "absolute",
  left: 0,
  top: 0,
  width: SCREEN_POINTS.width,
  height: SCREEN_POINTS.height,
};

// A real app screenshot that assembles itself: the static base fades in, then
// each band (a card, a list, a message bubble) springs up into place. The base
// is masked where the bands sit so nothing shows twice.
export const ScreenBuild = ({ image, bands = [], baseAt = 0, canvas = "#F2F2F7", style }: ScreenBuildProps) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (frame < baseAt) return null;

  const pct = (points: number) => `${(points / SCREEN_POINTS.height) * 100}%`;
  const sorted = [...bands].sort((a, b) => a.top - b.top);
  const stops: string[] = [];
  let cursor = 0;
  for (const band of sorted) {
    stops.push(`black ${pct(cursor)}`, `black ${pct(band.top)}`, `transparent ${pct(band.top)}`, `transparent ${pct(band.bottom)}`);
    cursor = band.bottom;
  }
  stops.push(`black ${pct(cursor)}`, "black 100%");
  const mask = `linear-gradient(to bottom, ${stops.join(", ")})`;

  return (
    <div
      style={{
        ...fullScreen,
        background: canvas,
        opacity: interpolate(frame, [baseAt, baseAt + 5], [0, 1], { extrapolateRight: "clamp" }),
        ...style,
      }}
    >
      <Img src={staticFile(image)} style={{ ...fullScreen, maskImage: mask, WebkitMaskImage: mask }} />
      {sorted.map((band) => {
        const local = frame - band.at;
        if (local < 0) return null;
        const landed = spring({ frame: local, fps, config: { damping: 15, mass: 0.8 } });
        const fade = interpolate(local, [0, 6], [0, 1], { extrapolateRight: "clamp" });
        const rise = band.from === "fade" ? 0 : (1 - landed) * 70;
        return (
          <Img
            key={band.top}
            src={staticFile(image)}
            style={{
              ...fullScreen,
              clipPath: `inset(${band.top}px 0 ${SCREEN_POINTS.height - band.bottom}px 0)`,
              opacity: fade,
              transform: `translateY(${rise}px) scale(${band.from === "fade" ? 1 : 0.96 + landed * 0.04})`,
              transformOrigin: `50% ${(band.top + band.bottom) / 2}px`,
            }}
          />
        );
      })}
    </div>
  );
};
