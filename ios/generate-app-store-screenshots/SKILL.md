---
name: generate-app-store-screenshots
description: Generate, frame, review, validate, and upload deterministic iPhone and iPad App Store screenshots from authentic iOS Simulator UI, including Home Screen and Lock Screen widget showcases. Use for fresh screenshot capture, screenshot-mode fixtures and routes, widget automation, exact App Store dimensions, localization manifests, device framing, visual review sheets, or App Store Connect screenshot replacement.
---

# Generate App Store Screenshots

Preserve live app UI pixel-for-pixel. Do not redraw product UI with an image
model. Use the bundled scripts for deterministic capture and composition.

## Resolve the project contract

1. Read repository instructions and existing screenshot/release documentation.
2. Find the app's screenshot workflow JSON. If none exists, copy
   [references/workflow.example.json](references/workflow.example.json) into the
   app repository and adapt it. Read
   [references/workflow-configuration.md](references/workflow-configuration.md)
   before changing its schema.
3. Read [references/app-store-sizes.md](references/app-store-sizes.md) and verify
   current Apple dimensions before changing a size preset.
4. Discover the app bundle ID, widget extension ID and kind, app group, launch
   arguments, routes, source Simulator, locales, and output directories. Do not
   guess identifiers that can be read from the built app or Xcode project.

## Require a DEBUG-only screenshot mode

Make fresh capture deterministic without changing Release behavior:

- seed stable sample data and identifiers;
- bypass onboarding, ads, analytics, permissions, and network-dependent startup;
- expose a launch argument for each screenshot route;
- use fixed dates or relative dates that produce stable visible copy;
- copy licensed fixture media into the installed app's Documents directory;
- compile fixture loaders and widget fallbacks out of Release builds.

Copy fixture files after installation and before the first screenshot-mode
launch. A seeder should report missing fixtures cleanly instead of trapping.
Record fixture provenance beside source assets.

Use an invisible, non-interactive scroll anchor for deterministic content
positions. Avoid timed swipes when the app can route and position itself.

## Choose the widget strategy

Read [references/widget-state-storage.md](references/widget-state-storage.md)
before automating widgets.

Prefer **portable placement** when the app can provide a DEBUG-only fallback for
an unconfigured widget. The capture script writes widget entries to
`IconState.plist` while a disposable clone is Shutdown, and the widget resolves
its marketing entity from app-group preferences. This removes jiggle mode,
gallery search, and Edit Widget from normal runs.

Use a **template Simulator** when the widget must retain a real saved App Intent
selection. Bootstrap the widget once through system UI, shut down that Simulator,
then clone it for every capture. Read
[references/widget-system-ui.md](references/widget-system-ui.md). Never repeat
the jiggle/configuration loop per screenshot run.

## Build and prepare

Build the current Debug or dedicated screenshot configuration. Reuse a warm
`.app` only when its source and project inputs are current.

Before each fresh capture, normalize presentation:

```bash
<skill-dir>/scripts/prepare_simulator.sh <SIMULATOR_UDID>
```

This forces Light appearance, 9:41, full battery, and clean network indicators.
Reject permission dialogs, debug chrome, stale loading, wrong orientation, and
dirty status bars.

## Capture a complete set

Use a Shutdown source Simulator and a disposable clone:

```bash
python3 <skill-dir>/scripts/capture_simulator_set.py \
  --config app_store/automation/screenshot-workflow.json \
  --app <build-path>/Example.app \
  --source-udid <shutdown-simulator-udid> \
  --repo-root "$PWD"
```

The script installs the app, copies fixtures, launches screenshot mode, resolves
the app group, optionally stages widget preferences and placement while
Shutdown, applies presentation preflight, captures every configured route after
two byte-identical frames, rotates landscape output upright, and deletes the
clone. Use `--keep` only for debugging.

For an intent-configured widget template, capture Phase B with:

```bash
APP_BUNDLE_ID="<bundle-id>" \
APP_LAUNCH_ARGUMENTS="<screenshot arguments>" \
<skill-dir>/scripts/capture_widget_showcase.sh \
  <shutdown-template-udid> \
  <current.app> \
  app_store/screenshots/raw/en-US/widgets.png
```

## Frame authentic captures

Use the repository's approved frame tool. Frames CLI can auto-detect standard
Simulator captures:

```bash
frames frame \
  --output app_store/screenshots/framed/en-US \
  app_store/screenshots/raw/en-US/*.png
```

Require transparent framed-device PNGs. Stop if the frame output lacks alpha;
an opaque frame image will cover the compositor background. Preserve the
captured screen and frame exactly.

## Compose from a manifest

Keep copy, ordering, paths, provenance, and status in one manifest per language.
Orders must be contiguous from one. Mark a shot `needs-capture` until an
authentic frame has been visually verified; rendering skips pending shots.
Start from [references/manifest.example.json](references/manifest.example.json).

```bash
python3 <skill-dir>/scripts/render_set.py \
  --manifest app_store/aso/screenshots/en-US.json

python3 <skill-dir>/scripts/review_set.py \
  --manifest app_store/aso/screenshots/en-US.json \
  --output /tmp/app-store-screenshot-review.png
```

The compositor emits opaque RGB PNGs, validates exact dimensions and 4.5:1 text
contrast, and supports accepted iPhone portrait and 13-inch iPad portrait or
landscape canvases. Keep the review sheet outside the upload directory.

## Establish the campaign direction

Start with a deterministic style that matches the product's approved visual
system. If the product has no approved system, use the clean `poster` style:
white canvas, faint rounded border, centered SF Rounded copy, and a fully
contained device. Scale every position and font size proportionally from the
1320x2868 reference canvas when rendering iPad; never tune tablet screenshots by
eye or by platform-specific magic numbers.

### Poster style lock

The following values reproduce the MoneyTracker campaign look and are part of
the template contract, not suggestions:

- canvas: opaque white; border inset 6 px, radius 96 px, border width
  `max(2, round(canvasWidth / 440))`, all scaled proportionally for other
  accepted sizes;
- eyebrow: SF Rounded Semibold, 76 px, centered at y=236 px, gray `#68686E`,
  with a 6.5% horizontal margin and no terminal punctuation;
- headline: SF Rounded Semibold, 150 px, centered from y=350 px, maximum three
  lines, 138 px Latin leading and 170 px CJK leading, near-black `#08080C`;
- use Semibold rather than Bold for the headline; do not add a subtitle,
  underline, gradient, generated background, or decorative stock art in poster
  mode;
- keep the complete device visible and use one fixed device width/top anchor
  per display type. Record any feature-specific exception in the manifest.

The renderer must expose this as `--style poster`, validate exact dimensions,
opaque RGB output, text contrast, line limits, and font availability. A
localized poster keeps the same geometry and only swaps the locale-appropriate
font and copy; CJK uses the wider 170 px leading.

Prefer typographic restraint over decoration:

- use one accent phrase, not several colored words;
- create hierarchy with scale, line spacing, and deliberate title-to-subtitle
  spacing;
- keep the subtitle comfortably readable at contact-sheet scale;
- keep the complete phone or tablet visible, including its bottom frame;
- keep device scale and placement consistent unless a recorded feature-specific
  exception improves the visible proof;
- reject gradients, generated backgrounds, textures, and decorative stock art
  when a clean composition communicates the feature more clearly.

Do not use image generation for campaign text, device frames, captured UI, or
background experiments after the direction resolves to deterministic type. A
compositor proof is faster, preserves exact copy and spacing, and cannot mutate
the product UI.

Write for the product's real audience and visible capabilities. Avoid implying
licenses, certifications, professional authority, safety guarantees, or other
high-stakes uses unless the product has them and the claim is approved. For AI
features, show the original source or input, make provenance visible when the UI
supports it, and describe organization or assistance rather than guaranteed
correctness. Screenshot fixtures must not spend model tokens or depend on a live
AI response.

Plan a set with distinct jobs. Lead with the strongest hero, then cover unique
high-value features such as primary workflows, sharing, widgets, notifications,
AI assistance, maps, or Dark appearance when the app actually ships them. Remove
screens that repeat the hero without adding evidence.

## Enforce approval boundaries

Render one representative proof before producing a full set. Review it at full
resolution and contact-sheet scale. Full resolution exposes clipping, stale
state, and truncation; thumbnail scale exposes weak hierarchy.

Treat each of these as a new approval boundary:

1. campaign direction and one proof;
2. complete phone set;
3. complete tablet set;
4. App Store Connect upload.

Approval of a direction does not approve every screenshot. Approval of one
platform does not approve another. Any material copy, camera, detent, fixture,
appearance, device-scale, or order change resets approval for the affected
asset. Keep experiments outside the approved manifest and do not commit rejected
PNGs; preserve reusable reasoning in repository guidance instead.

## Freeze authentic capture state

Use production views with DEBUG-only deterministic routing. Record the exact
sheet detent, inspector state, tab, scroll position, map camera, fixture, device,
appearance, and build in `captureBrief`.

- Choose a sheet detent that preserves meaningful background context while
  keeping the featured detail readable. Freeze it after approval.
- Apply map cameras after the final sheet, sidebar, or inspector geometry has
  settled. Judge centering against the unobscured visible map, not the full
  framebuffer behind an overlay.
- Seed long and narrow values deliberately. Treat truncation in tiles, sidebars,
  split views, and accessibility-size text as a product bug, not a compositor
  problem.
- Capture Dark appearance from the real app. Run the standard Light preflight,
  switch explicitly to Dark for that shot, then restore Light.
- Capture notifications as authentic system UI. Cropping and arranging captured
  cards is acceptable; recreating their text or chrome is not.
- Render real WidgetKit output with deterministic preview data. Do not imitate
  widgets in the compositor.

On iPad, verify onboarding, sidebars, inspectors, sheets, and maps independently
instead of assuming the iPhone layout merely scales. Reject accidental
width-triggered split layouts. If Simulator writes a landscape framebuffer with
rotated pixels, normalize it with a lossless 90-degree rotation and verify the
exact accepted landscape dimensions; never crop or stretch it into compliance.

## Verify every output

Perform both programmatic and visual review:

- current app UI and correct device frame;
- exact accepted dimensions across the set;
- opaque RGB output without alpha;
- readable, unclipped, naturally wrapped truthful copy;
- correct locale, ordering, seeded data, and orientation;
- no placeholders, redaction, premium lock, stale widget, or debug controls;
- every widget family displays live content;
- no duplicate decoded pixels or hidden files.

Treat WidgetKit redaction or `imageTooLarge` logs as capture failures. Prepare
widget media below the runtime's dimension and area limits; a 720×720 bounding
box is a conservative starting point for 13-inch iPad widgets.

Run App Store Connect's local preflight using the device type reported by the
installed CLI:

```bash
asc screenshots sizes --all
asc screenshots validate \
  --path app_store/screenshots/generated/en-US \
  --device-type <DISPLAY_TYPE> \
  --output table
```

## Upload safely

Inspect installed `asc` help and remote state before mutation:

```bash
asc versions list --app <app-id> --platform IOS
asc localizations list --version <version-id> --locale en-US
asc screenshots list --version-localization <localization-id>
```

Run an upload dry run. Upload appends by default, so use `--replace` only after
confirming the exact editable version, locale, and display type:

```bash
asc screenshots upload \
  --version-localization <localization-id> \
  --path app_store/screenshots/generated/en-US \
  --device-type <DISPLAY_TYPE> \
  --replace \
  --dry-run
```

Repeat without `--dry-run`, then list the remote set and compare filename order,
dimensions, delivery state, and MD5 checksum. Screenshot upload does not grant
permission to submit the app version for review.

Upload one approved display type from an exact staging directory containing only
its ordered files. Wait until every replacement asset reports `COMPLETE` before
deleting a legacy display-type set, then query App Store Connect again to verify
the final count. Record version, locale, display type, filenames, dimensions,
processing state, and upload date in the repository. Never infer permission to
submit for App Review from permission to replace screenshots.

## Freshness rules

When asked for fresh or current-build screenshots, do not reuse raw or framed
captures. Rebuild, reseed, capture live UI, reframe, update provenance, render,
and re-review. Layout-only or localization changes may reuse the latest approved
authentic capture, but never describe reused UI as fresh.
