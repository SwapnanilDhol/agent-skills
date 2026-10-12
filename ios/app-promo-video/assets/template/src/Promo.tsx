import { AbsoluteFill, Audio, interpolate, Series, staticFile } from "remotion";
import { BACKGROUND, FONT } from "./brand";
import { Flow } from "./scenes/Flow";
import { Intro } from "./scenes/Intro";
import { Outro } from "./scenes/Outro";
import { Wall } from "./scenes/Wall";
import { Timeline } from "./timeline";

export type PromoProps = { timeline: Timeline | null };

export const Promo = ({ timeline }: PromoProps) => {
  if (!timeline) return null;
  const { scenes, segments, totalFrames } = timeline;

  return (
    <AbsoluteFill style={{ background: BACKGROUND, fontFamily: FONT }}>
      <Audio
        src={staticFile("music.wav")}
        volume={(f) => interpolate(f, [0, 10, totalFrames - 20, totalFrames], [0, 1, 1, 0])}
      />
      <Series>
        <Series.Sequence durationInFrames={scenes.intro}>
          <Intro />
        </Series.Sequence>
        <Series.Sequence durationInFrames={scenes.wall}>
          <Wall />
        </Series.Sequence>
        <Series.Sequence durationInFrames={scenes.flow}>
          <Flow segments={segments} />
        </Series.Sequence>
        <Series.Sequence durationInFrames={scenes.outro}>
          <Outro />
        </Series.Sequence>
      </Series>
    </AbsoluteFill>
  );
};
