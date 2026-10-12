import { AbsoluteFill, Img, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { BRAND, INK } from "../brand";

export const Outro = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const iconIn = spring({ frame, fps, config: { damping: 14 } });
  const textIn = spring({ frame: frame - 10, fps, config: { damping: 200 } });
  const badgeIn = spring({ frame: frame - 22, fps, config: { damping: 12 } });

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", color: INK }}>
      <Img
        src={staticFile("assets/icon.png")}
        style={{
          width: 240,
          height: 240,
          borderRadius: 54,
          boxShadow: "0 30px 80px rgba(80, 20, 90, 0.35)",
          transform: `scale(${iconIn})`,
        }}
      />
      <div
        style={{
          marginTop: 60,
          fontSize: 96,
          fontWeight: 800,
          letterSpacing: -3,
          opacity: textIn,
          transform: `translateY(${(1 - textIn) * 30}px)`,
        }}
      >
        {BRAND.appName}
      </div>
      <div
        style={{
          marginTop: 16,
          fontSize: 44,
          fontWeight: 600,
          opacity: textIn * 0.75,
          textAlign: "center",
          lineHeight: 1.25,
        }}
      >
        {BRAND.outroLines[0]}
        <br />
        {BRAND.outroLines[1]}
      </div>
      <div
        style={{
          marginTop: 80,
          padding: "28px 56px",
          borderRadius: 999,
          background: INK,
          color: "white",
          fontSize: 42,
          fontWeight: 700,
          transform: `scale(${badgeIn})`,
        }}
      >
        {BRAND.cta}
      </div>
    </AbsoluteFill>
  );
};
