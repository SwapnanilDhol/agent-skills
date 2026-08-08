# Widget system UI bootstrap

Use this path only when a screenshot widget must retain a real saved App Intent
selection. Prefer portable `IconState.plist` placement plus a DEBUG-only provider
fallback when the app can support it.

## Process ownership

| Surface | Bundle ID |
|---|---|
| Home Screen, jiggle mode, and widget gallery | `com.apple.springboard` |
| Home Screen widget configuration | `com.apple.WorkflowUI.WidgetConfigurationExtension` |
| Lock Screen customization | `com.apple.PosterBoard` |
| Seeded data and WidgetKit timelines | Host app and its app group |

An automation driver must interact with the process that owns the frontmost
surface. After choosing Edit Widget, parameter labels belong to the configuration
extension rather than SpringBoard.

## Phase A: bootstrap once

1. Boot a clean Simulator matching the production capture device.
2. Install the current Debug or screenshot build with its widget extension.
3. Launch screenshot mode and verify stable seeded entities and premium state.
4. Normalize presentation and return Home.
5. Add the approved widget families to one uncluttered page.
6. Open Edit Widget and select the stable marketing entity.
7. Exit edit mode and verify live content without placeholders or redaction.
8. Shut down the Simulator and record its UDID in the app's workflow config.

Prepare the device with:

```bash
APP_BUNDLE_ID="<bundle-id>" \
APP_LAUNCH_ARGUMENTS="<screenshot arguments>" \
<skill-dir>/scripts/prepare_widget_template.sh <udid> <current.app>
```

Use `probe_widget_ui.sh` after every meaningful gesture. Configure hints with:

```bash
WIDGET_PARAMETER_LABEL="Item" \
WIDGET_ENTITY_LABEL="Marketing Sample" \
WIDGET_PLACEHOLDER_PATTERNS="select an item|requires premium" \
<skill-dir>/scripts/probe_widget_ui.sh <udid>
```

## Phase B: clone and capture

Leave the template Shutdown. For each current build, clone it, install over the
clone, launch once to refresh app-group data, return to the widget page, capture,
and delete the clone. Use `capture_widget_showcase.sh`; do not re-enter jiggle
mode during Phase B.

Rebuild Phase A when widget kinds, App Intent schema, selected entity IDs, device
layout, or runtime behavior changes. Never force reseeding if it changes an ID
stored in the template's widget configuration.

## Optional XCUITest mapping

When a host app owns a UI test target, use separate applications:

```swift
let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
let widgetConfig = XCUIApplication(
    bundleIdentifier: "com.apple.WorkflowUI.WidgetConfigurationExtension"
)
let posterboard = XCUIApplication(bundleIdentifier: "com.apple.PosterBoard")
```

Use SpringBoard for add/remove/jiggle, the configuration extension for widget
parameters, and PosterBoard for Lock Screen widget slots.

## Reject these states

- unconfigured or premium-locked placeholder;
- redacted WidgetKit content;
- stale entity after reinstall;
- dirty page with unrelated widgets;
- edit controls, context menus, or jiggle affordances;
- wrong device orientation or system appearance.
