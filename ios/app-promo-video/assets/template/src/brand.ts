import assets from "../assets.json";

// Everything app-specific about the promo's look and copy lives here.
export const BRAND = {
  appName: "YourApp",
  introTagline: "One short promise.",
  outroLines: ["What the app does,", "in two short lines"],
  cta: "Download on the App Store",
  wallTitle: "60+ templates",
  wallSubtitle: "Show the breadth of what's inside",
};

// Use the app's own canvas, not a decorative gradient. This is iOS grouped
// background with a faint dot grid; swap in the app's real surface colour.
export const BACKGROUND =
  "radial-gradient(circle, rgba(17, 16, 20, 0.09) 2px, transparent 2.5px) 0 0 / 36px 36px, #F2F2F7";
export const INK = "#111014";
export const FONT = '"SF Pro Display", -apple-system, system-ui, sans-serif';

export const FPS = 30;
export const WIDTH = 1080;
export const HEIGHT = 1920;

export const wallImages = assets.wall.map((name) => `assets/wall/${name}`);
