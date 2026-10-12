import {
  AbsoluteFill,
  interpolate,
  OffthreadVideo,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { INK } from "../brand";
import { PointsScreen, SCREEN_POINTS } from "../components/ios";
import { Segment } from "../timeline";
import { MOCKS } from "./mock";

// Screen aspect follows the recordings (iPhone 17/18 Pro: 402 × 874 points).
const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = SCREEN_WIDTH * (SCREEN_POINTS.height / SCREEN_POINTS.width);
const BEZEL = 18;

const Caption = ({ text }: { text: string }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = spring({ frame, fps, config: { damping: 200 } });
  const exit = interpolate(frame, [durationInFrames - 8, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        position: "absolute",
        top: 120,
        width: "100%",
        textAlign: "center",
        fontSize: 92,
        fontWeight: 800,
        letterSpacing: -2.5,
        color: INK,
        opacity: enter * (1 - exit),
        transform: `translateY(${(1 - enter) * 40 - exit * 30}px)`,
      }}
    >
      {text}
    </div>
  );
};

// Simulator recordings and mocked scenes play inside a drawn iPhone while
// captions change above it, so the device stays put across every step.
export const Flow = ({ segments: clips }: { segments: Segment[] }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  const enter = spring({ frame, fps, config: { damping: 16 } });
  const exit = interpolate(frame, [durationInFrames - 12, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const starts = clips.map((_, i) => clips.slice(0, i).reduce((sum, c) => sum + c.durationInFrames, 0));

  // Consecutive clips with the same caption keep one caption on screen.
  const captions: { text: string; from: number; durationInFrames: number }[] = [];
  clips.forEach((clip, i) => {
    const last = captions[captions.length - 1];
    if (last && last.text === clip.caption) last.durationInFrames += clip.durationInFrames;
    else captions.push({ text: clip.caption, from: starts[i], durationInFrames: clip.durationInFrames });
  });

  return (
    <AbsoluteFill>
      {captions.map((caption) => (
        <Sequence key={caption.from} from={caption.from} durationInFrames={caption.durationInFrames}>
          <Caption text={caption.text} />
        </Sequence>
      ))}
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "flex-end", paddingBottom: 90 }}>
        <div
          style={{
            width: SCREEN_WIDTH + BEZEL * 2,
            height: SCREEN_HEIGHT + BEZEL * 2,
            padding: BEZEL,
            borderRadius: 112,
            background: "#0B0B0D",
            boxShadow: "0 0 0 4px #3A3A40, 0 50px 120px rgba(50, 10, 70, 0.45)",
            opacity: 1 - exit,
            transform: `translateY(${(1 - enter) * 900 + exit * 120}px) scale(${1 - exit * 0.08})`,
          }}
        >
          <div
            style={{
              width: SCREEN_WIDTH,
              height: SCREEN_HEIGHT,
              borderRadius: 96,
              overflow: "hidden",
              position: "relative",
              background: "white",
            }}
          >
            {clips.map((clip, i) => (
              <Sequence key={clip.id} from={starts[i]} durationInFrames={clip.durationInFrames}>
                {clip.kind === "video" ? (
                  <OffthreadVideo
                    src={staticFile(`recordings/${clip.src}.mp4`)}
                    trimBefore={clip.trimBeforeFrames}
                    playbackRate={clip.rate}
                    muted
                    style={{ width: "100%", height: "100%" }}
                  />
                ) : (
                  <PointsScreen width={SCREEN_WIDTH}>{MOCKS[clip.mock]?.() ?? null}</PointsScreen>
                )}
              </Sequence>
            ))}
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
