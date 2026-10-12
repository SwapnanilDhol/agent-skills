import { Composition, staticFile, Still } from "remotion";
import { FPS, HEIGHT, WIDTH } from "./brand";
import { Promo, PromoProps } from "./Promo";
import { SourcePhoto } from "./stills/SourcePhoto";
import { Timeline } from "./timeline";

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
      calculateMetadata={async () => {
        const timeline: Timeline = await fetch(staticFile("timeline.json")).then((r) => r.json());
        return { durationInFrames: timeline.totalFrames, props: { timeline } };
      }}
    />
  </>
);
