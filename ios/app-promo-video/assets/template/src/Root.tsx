import { Composition, staticFile, Still } from "remotion";
import { APP_PREVIEW_WIDTH, FPS, HEIGHT, WIDTH } from "./brand";
import { Promo, PromoProps } from "./Promo";
import { SourcePhoto } from "./stills/SourcePhoto";
import { Timeline } from "./timeline";

const loadTimeline = async () => {
  const timeline: Timeline = await fetch(staticFile("timeline.json")).then((r) => r.json());
  return { durationInFrames: timeline.totalFrames, props: { timeline } };
};

export const RemotionRoot = () => (
  <>
    <Still id="SourcePhoto" component={SourcePhoto} width={1500} height={2000} />
    <Composition
      id="Promo"
      component={Promo}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
      defaultProps={{ timeline: null } as PromoProps}
      calculateMetadata={loadTimeline}
    />
    {/* App Store app preview for 6.9" iPhones: exactly 886 × 1920, 15–30 s. */}
    <Composition
      id="AppPreview"
      component={Promo}
      fps={FPS}
      width={APP_PREVIEW_WIDTH}
      height={HEIGHT}
      defaultProps={{ timeline: null } as PromoProps}
      calculateMetadata={loadTimeline}
    />
  </>
);
