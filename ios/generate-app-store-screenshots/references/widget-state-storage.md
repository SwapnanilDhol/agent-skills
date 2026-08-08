# Simulator widget state storage

Use this reference before modifying widget staging. These behaviors were verified
on macOS 26 and iOS 26.5 Simulator runtimes; re-derive them after meaningful
SpringBoard or WidgetKit changes.

## Separate content from system-owned configuration

Widget content normally comes from the host app's shared app group. Resolve the
container without guessing its generated path:

```bash
xcrun simctl get_app_container <udid> <bundle-id> groups
```

Seed content through the host app when possible. Write only documented
screenshot preferences directly, and only while the Simulator is Shutdown.

System-owned widget state lives primarily in:

| Artifact | Owns |
|---|---|
| `Library/SpringBoard/IconState.plist` | Home Screen placement, grid size, widget kind, extension and host IDs |
| `Library/chronod/chrono.sql` | Widget configuration archives and App Intent references |

A booted SpringBoard rewrites `IconState.plist` during shutdown and can discard
external edits. Patch it only after shutdown, then boot to verify.

## Placement is portable; intent selection may not be

Widget placement can be generated or transplanted onto a matching Simulator.
Saved App Intent selection may be tied to the Simulator instance: copying the
chronod database or archive can cause chronod to rewrite the configuration and
drop its intent reference.

Choose one of two supported designs:

1. Add a DEBUG-only provider fallback that resolves an unconfigured widget from
   a stable entity ID in app-group preferences. Then stage only placement and
   content for every disposable clone.
2. Configure the widget through system UI once and clone that shutdown template
   for each run. Preserve the entity identifiers used by the template.

Never weaken Release configuration behavior to support screenshots.

## Home Screen capacity

Small, medium, and large families consume different grid areas. A phone page may
not fit all three and SpringBoard can silently drop overflow. A 13-inch iPad can
normally present all three on one page. Always inspect the resulting Home Screen.

## Widget media limits

WidgetKit archives rendered images and enforces dimension and area limits that
can differ by device family. An image that works on iPhone may redact an iPad
widget. Treat a redacted skeleton as failure and inspect extension logs for
`imageTooLarge`. Prepare widget-specific thumbnails; a 720×720 bounding box is a
conservative initial target for a large 13-inch iPad widget.

## Stability boundary

`simctl clone`, boot, install, launch, container lookup, status-bar override, and
screenshot are supported Simulator operations. `IconState.plist` is readable but
not a public schema contract. When placement breaks after a runtime update:

1. add one widget manually on a disposable Simulator;
2. shut it down;
3. diff the new `IconState.plist` against clean state;
4. update the staging script and visually verify every requested family.
