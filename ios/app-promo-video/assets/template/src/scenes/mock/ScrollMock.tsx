import { AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { Band, ScreenBuild } from "../../components/ScreenBuild";
import { SCREEN_POINTS } from "../../components/ios";

export type ScrollMockProps = {
  /** 3x capture of the screen at rest, in public/. */
  top: string;
  /** 3x capture of the same screen scrolled by `offset` points. */
  scrolled: string;
  /** How far the content moved between the captures, measured off one row. */
  offset: number;
  /** Bottom of the fixed header (status bar + title), in points. */
  header: number;
  /** Top of any fixed bottom chrome (a floating tab bar), in points. */
  contentEnd?: number;
  /**
   * Floating chrome that stays put while the page scrolls under it, as CSS
   * clip-path insets on each capture, e.g. "inset(788px 90px 19px 20px round 32px)".
   */
  pinnedTop?: string[];
  pinnedScrolled?: string[];
  /** Frames where the scroll starts and lands. */
  scrollAt?: number;
  scrollEnd?: number;
  /** Optional ScreenBuild bands for the top capture before the scroll. */
  bands?: Band[];
  /** The screen's background colour. */
  canvas?: string;
};

const full = { position: "absolute", left: 0, top: 0, width: SCREEN_POINTS.width, height: SCREEN_POINTS.height } as const;
const clip = (top: number, bottom: number) => `inset(${top}px 0 ${SCREEN_POINTS.height - bottom}px 0)`;

// A scroll faked from two real stills. simctl recordVideo drops frames during
// fast motion, so a recorded scroll stutters; this one can't. The page is the
// top capture continued below by the scrolled one, stitched at `offset`; only
// the header and the pinned chrome stay fixed, cross-fading to their scrolled
// look as the scroll lands. Without `bands` the top capture just sits still
// until `scrollAt`.
export const ScrollMock = ({
  top,
  scrolled,
  offset,
  header,
  contentEnd = SCREEN_POINTS.height,
  pinnedTop = [],
  pinnedScrolled = [],
  scrollAt = 42,
  scrollEnd = 74,
  bands,
  canvas = "#F2F2F7",
}: ScrollMockProps) => {
  const frame = useCurrentFrame();

  if (frame < scrollAt) {
    return (
      <AbsoluteFill style={{ background: canvas }}>
        {bands ? <ScreenBuild image={top} canvas={canvas} bands={bands} /> : <Img src={staticFile(top)} style={full} />}
      </AbsoluteFill>
    );
  }

  const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
  const s = interpolate(frame, [scrollAt, scrollEnd], [0, offset], { ...clamp, easing: Easing.bezier(0.45, 0, 0.15, 1) });
  const chromeSwap = interpolate(s, [offset * 0.55, offset], [0, 1], clamp);

  return (
    <AbsoluteFill style={{ background: canvas }}>
      {/* The page: the top capture, continued below by the scrolled one. */}
      <Img src={staticFile(top)} style={{ ...full, clipPath: clip(header, contentEnd), transform: `translateY(${-s}px)` }} />
      <Img
        src={staticFile(scrolled)}
        style={{ ...full, clipPath: clip(contentEnd - offset, contentEnd), transform: `translateY(${offset - s}px)` }}
      />
      {/* Fixed chrome, handing over to the scrolled look. */}
      <Img src={staticFile(top)} style={{ ...full, clipPath: clip(0, header), opacity: 1 - chromeSwap }} />
      <Img src={staticFile(scrolled)} style={{ ...full, clipPath: clip(0, header), opacity: chromeSwap }} />
      {pinnedTop.map((pin) => (
        <Img key={pin} src={staticFile(top)} style={{ ...full, clipPath: pin, opacity: 1 - chromeSwap }} />
      ))}
      {pinnedScrolled.map((pin) => (
        <Img key={pin} src={staticFile(scrolled)} style={{ ...full, clipPath: pin, opacity: chromeSwap }} />
      ))}
    </AbsoluteFill>
  );
};
