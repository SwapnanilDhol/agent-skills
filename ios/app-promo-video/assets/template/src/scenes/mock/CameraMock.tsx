import { ReactNode } from "react";
import { AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { SCREEN_POINTS, StatusBar } from "../../components/ios";
import { ResultReveal, ResultRevealProps } from "./ResultReveal";

export type CameraMockProps = {
  /** The "photo" in the viewfinder (render one with the SourcePhoto still). */
  photo: string;
  /** Where the subject sits in the viewfinder, in points, and its tilt. */
  subject: { left: number; top: number; width: number; height: number; rotate: number };
  readingLabels?: [string, string];
  /** A curated result card, or renderReveal for a custom payoff. */
  reveal?: Omit<ResultRevealProps, "startFrame">;
  /** Custom payoff, given the frame it starts on (e.g. a real app screen). */
  renderReveal?: (startFrame: number) => ReactNode;
  /** Frames for the shutter press and the reveal (defaults fit 10 beats). */
  shutterAt?: number;
  revealAt?: number;
};

// Bottom camera chrome (mode label + shutter), in points.
const CHROME_HEIGHT = 190;
// The "reading" label sits under the subject, but never inside the chrome.
const LABEL_MAX_TOP = SCREEN_POINTS.height - CHROME_HEIGHT - 44;

// Mocked camera capture: a handheld viewfinder, the outline locking onto the
// subject, shutter + flash, a short "reading" beat with a scan line, then the
// finished result. 150 frames (10 beats) fits it.
export const CameraMock = ({
  photo,
  subject,
  readingLabels = ["Reading your photo…", "Building your result…"],
  reveal,
  renderReveal,
  shutterAt: SHUTTER = 48,
  revealAt: REVEAL = 96,
}: CameraMockProps) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const frozen = frame >= SHUTTER;
  const t = frozen ? SHUTTER : frame;
  const wobbleX = Math.sin(t / 11) * 4;
  const wobbleY = Math.cos(t / 14) * 3;

  const lock = spring({ frame: frame - 8, fps, config: { damping: 15 } });
  const inset = (1 - lock) * 40;
  const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
  const shutterPress = interpolate(frame, [SHUTTER - 3, SHUTTER, SHUTTER + 4], [1, 0.82, 1], clamp);
  const flash = interpolate(frame, [SHUTTER, SHUTTER + 2, SHUTTER + 10], [0, 0.9, 0], clamp);
  const reading = interpolate(frame, [SHUTTER + 4, SHUTTER + 14], [0, 1], clamp);
  const scanLine = ((frame - SHUTTER) % 28) / 28;

  return (
    <AbsoluteFill style={{ background: "black" }}>
      <Img
        src={staticFile(photo)}
        style={{
          position: "absolute",
          width: 420,
          left: -9 + wobbleX,
          top: 126 + wobbleY,
          filter: `blur(${reading * 6}px) brightness(${1 - reading * 0.35})`,
        }}
      />

      {/* Outline locking onto the subject. */}
      <div
        style={{
          position: "absolute",
          left: subject.left - inset + wobbleX,
          top: subject.top - inset + wobbleY,
          width: subject.width + inset * 2,
          height: subject.height + inset * 2,
          border: "3px solid #FFD60A",
          borderRadius: 14,
          background: `rgba(255, 214, 10, ${0.12 * lock})`,
          opacity: lock * (1 - reading),
          transform: `rotate(${subject.rotate}deg)`,
        }}
      />

      {frozen && (
        <div style={{ position: "absolute", inset: 0, opacity: reading }}>
          <div
            style={{
              position: "absolute",
              left: 40,
              right: 40,
              top: subject.top + scanLine * subject.height,
              height: 3,
              borderRadius: 2,
              background: "#0A84FF",
              boxShadow: "0 0 18px 6px rgba(10, 132, 255, 0.6)",
            }}
          />
          <div
            style={{
              position: "absolute",
              top: Math.min(subject.top + subject.height + 54, LABEL_MAX_TOP),
              width: "100%",
              textAlign: "center",
              color: "white",
              fontSize: 19,
              fontWeight: 600,
            }}
          >
            {frame - SHUTTER < (REVEAL - SHUTTER) / 2 ? readingLabels[0] : readingLabels[1]}
          </div>
        </div>
      )}

      {/* Camera chrome. */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 110, background: "rgba(0,0,0,0.55)" }} />
      <StatusBar dark />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 0,
          height: CHROME_HEIGHT,
          background: "rgba(0,0,0,0.78)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        <div style={{ marginTop: 16, color: "#FFD60A", fontSize: 13, fontWeight: 600, letterSpacing: 1.5 }}>PHOTO</div>
        <div
          style={{
            marginTop: 16,
            width: 78,
            height: 78,
            borderRadius: 39,
            border: "4px solid white",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div style={{ width: 64, height: 64, borderRadius: 32, background: "white", transform: `scale(${shutterPress})` }} />
        </div>
      </div>

      <AbsoluteFill style={{ background: "white", opacity: flash }} />
      {renderReveal ? renderReveal(REVEAL) : reveal && <ResultReveal {...reveal} startFrame={REVEAL} />}
    </AbsoluteFill>
  );
};
