import { AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { BRAND, INK, wallImages } from "../brand";

const COLUMNS = 3;
const CARD_WIDTH = 340;
const CARD_HEIGHT = CARD_WIDTH * (960 / 683);
const GAP = 36;

// A wall of the app's content (gallery items, screenshots of results):
// three columns drifting in alternating directions, tilted for depth, under
// a caption card. Images are cards with a 683:960 aspect; change
// CARD_HEIGHT if yours differ.
export const Wall = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const headlineIn = spring({ frame, fps, config: { damping: 200 } });
  const gridIn = spring({ frame: frame - 6, fps, config: { damping: 18 } });
  const exit = interpolate(frame, [durationInFrames - 12, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Cycle through the images so every column stays full however many there are.
  const PER_COLUMN = 8;
  const columns = Array.from({ length: COLUMNS }, (_, c) =>
    Array.from({ length: PER_COLUMN }, (_, i) => wallImages[(c * PER_COLUMN + i) % wallImages.length]),
  );

  return (
    <AbsoluteFill style={{ opacity: exit, overflow: "hidden" }}>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          transform: `rotate(-8deg) scale(${1.15 + (1 - gridIn) * 0.3})`,
          opacity: gridIn,
        }}
      >
        <div style={{ display: "flex", gap: GAP }}>
          {columns.map((files, c) => {
            const direction = c % 2 === 0 ? -1 : 1;
            const drift = direction * frame * 2.2 + (c % 2 === 0 ? 0 : -CARD_HEIGHT);
            return (
              <div
                key={c}
                style={{ display: "flex", flexDirection: "column", gap: GAP, transform: `translateY(${drift}px)` }}
              >
                {files.map((file, i) => (
                  <Img
                    key={`${c}-${i}`}
                    src={staticFile(file)}
                    style={{
                      width: CARD_WIDTH,
                      height: CARD_HEIGHT,
                      borderRadius: 28,
                      boxShadow: "0 24px 60px rgba(40, 10, 60, 0.35)",
                    }}
                  />
                ))}
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{ justifyContent: "flex-end", alignItems: "center", paddingBottom: 170 }}>
        <div
          style={{
            padding: "36px 56px",
            borderRadius: 48,
            background: "rgba(255, 255, 255, 0.86)",
            backdropFilter: "blur(20px)",
            textAlign: "center",
            color: INK,
            opacity: headlineIn,
            transform: `translateY(${(1 - headlineIn) * 80}px)`,
            boxShadow: "0 20px 60px rgba(40, 10, 60, 0.25)",
          }}
        >
          <div style={{ fontSize: 76, fontWeight: 800, letterSpacing: -2 }}>{BRAND.wallTitle}</div>
          <div style={{ fontSize: 40, fontWeight: 600, opacity: 0.7, marginTop: 8 }}>
            {BRAND.wallSubtitle}
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
