import { ReactNode } from "react";
import { CameraMock } from "./CameraMock";
import { PromptMock } from "./PromptMock";

// Mocked scenes, by name. build-timeline.mjs refers to these with
// { kind: "mock", mock: "<name>", beats: n }. Mock anything whose real
// output you can't control (AI results, camera, network) and always end on a
// polished, hand-picked result. Replace the examples with the app's own.
export const MOCKS: Record<string, () => ReactNode> = {
  camera: () => (
    <CameraMock
      photo="source-photo.jpg"
      subject={{ left: 14, top: 318, width: 374, height: 176, rotate: -5 }}
      readingLabels={["Reading your ticket…", "Building your pass…"]}
      reveal={{ image: "assets/wall/item-01.png", chipLabel: "Pass ready", buttonLabel: "Preview Your Pass" }}
    />
  ),
  prompt: () => (
    <PromptMock
      title="Describe Your Pass"
      subtitle="Describe what you need in one sentence, then we will turn it into a draft."
      prompt="Coffee coupon: a free pastry with any large coffee, valid through June 30"
      chips={["Best Match", "Coupon", "Event"]}
      buttonLabel="Create Draft"
      workingLabel="Creating your pass…"
      reveal={{ image: "assets/wall/item-02.png", chipLabel: "Pass ready", buttonLabel: "Preview Your Pass" }}
    />
  ),
};
