import { Img, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { PrimaryButton, StatusBar } from "../../components/ios";

export type ResultRevealProps = {
  /** Image in public/ (a polished gallery item, not live AI output). */
  image: string;
  /** Frame (within the mock) where the reveal starts. */
  startFrame: number;
  chipLabel?: string;
  buttonLabel?: string;
};

// The payoff both "AI" mocks end on: the finished result springs into place
// with a success chip and the app's primary action, like the real editor.
export const ResultReveal = ({ image, startFrame, chipLabel = "Ready", buttonLabel = "Continue" }: ResultRevealProps) => {
  const frame = useCurrentFrame() - startFrame;
  const { fps } = useVideoConfig();
  if (frame < 0) return null;

  const card = spring({ frame, fps, config: { damping: 13, mass: 0.9 } });
  const chrome = spring({ frame: frame - 8, fps, config: { damping: 200 } });

  return (
    <div style={{ position: "absolute", inset: 0, background: "#F2F2F7", opacity: Math.min(1, frame / 4) }}>
      <StatusBar />
      <div style={{ position: "absolute", top: 70, width: "100%", display: "flex", justifyContent: "center", opacity: chrome }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            padding: "6px 14px",
            borderRadius: 16,
            background: "rgba(52, 199, 89, 0.14)",
            color: "#1E8E3E",
            fontSize: 14,
            fontWeight: 600,
          }}
        >
          <div style={{ width: 8, height: 8, borderRadius: 4, background: "#34C759" }} />
          {chipLabel}
        </div>
      </div>
      <Img
        src={staticFile(image)}
        style={{
          position: "absolute",
          left: 36,
          top: 118,
          width: 330,
          borderRadius: 16,
          boxShadow: "0 24px 50px rgba(0, 0, 0, 0.22)",
          transform: `translateY(${(1 - card) * 260}px) scale(${0.7 + card * 0.3}) rotate(${(1 - card) * -6}deg)`,
        }}
      />
      <PrimaryButton label={buttonLabel} style={{ opacity: chrome, transform: `translateY(${(1 - chrome) * 30}px)` }} />
    </div>
  );
};
