import { AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { BRAND, INK } from "../brand";

export const Intro = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const iconIn = spring({ frame, fps, config: { damping: 12 } });
  const titleIn = spring({ frame: frame - 12, fps, config: { damping: 200 } });
  const subtitleIn = spring({ frame: frame - 22, fps, config: { damping: 200 } });
  const exit = interpolate(frame, [durationInFrames - 10, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: exit }}>
      <Img
        src={staticFile("assets/icon.png")}
        style={{
          width: 280,
          height: 280,
          borderRadius: 64,
          boxShadow: "0 30px 80px rgba(80, 20, 90, 0.35)",
          transform: `scale(${iconIn}) rotate(${(1 - iconIn) * -20}deg)`,
        }}
      />
      <div
        style={{
          marginTop: 72,
          fontSize: 112,
          fontWeight: 800,
          letterSpacing: -3,
          color: INK,
          opacity: titleIn,
          transform: `translateY(${(1 - titleIn) * 40}px)`,
        }}
      >
        {BRAND.appName}
      </div>
      <div
        style={{
          marginTop: 20,
          fontSize: 48,
          fontWeight: 600,
          color: INK,
          opacity: subtitleIn * 0.8,
          transform: `translateY(${(1 - subtitleIn) * 30}px)`,
        }}
      >
        {BRAND.introTagline}
      </div>
    </AbsoluteFill>
  );
};
