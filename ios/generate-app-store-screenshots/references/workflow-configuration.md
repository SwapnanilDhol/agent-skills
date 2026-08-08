# Screenshot workflow configuration

Use [workflow.example.json](workflow.example.json) as the portable contract
between an app repository and `capture_simulator_set.py`.

## Host-app responsibilities

The host app must implement the configured screenshot-mode launch arguments and
routes. Screenshot mode should seed deterministic UI data, suppress side effects,
and optionally write widget-readable data to its app group.

For portable widget placement, add a DEBUG-only widget-provider fallback that
resolves an unconfigured widget from a preference in the shared app group. Keep
the normal App Intent configuration path unchanged in Release.

## Fields

| Field | Purpose |
|---|---|
| `appName` | Human-readable name used for disposable Simulator clones |
| `bundleIdentifier` | Installed host-app bundle identifier |
| `screenshot.launchArguments` | Arguments that enable deterministic screenshot mode |
| `screenshot.routeArgument` | Argument followed by each shot's `route` value |
| `fixtureSourceDir` | Repository-relative licensed fixture directory |
| `fixtureDestination` | App-data-relative directory read by the DEBUG loader |
| `rawDir` | Repository-relative raw capture directory |
| `presentation.landscape` | Rotate Simulator and saved PNGs to landscape |
| `widget.extensionBundleIdentifier` | Widget extension bundle identifier |
| `widget.kind` | WidgetKit `kind` written into SpringBoard placement |
| `widget.appGroupIdentifier` | Shared app-group identifier |
| `widget.preferenceDomain` | Preference plist domain; defaults to app group ID |
| `widget.preferenceOverrides` | JSON-compatible values staged while Shutdown |
| `widget.sizes` | Any of `small`, `medium`, and `large` |
| `shots[].slug` | Filename without extension; lexical order is upload order |
| `shots[].route` | Host-app route value |
| `shots[].surface` | `app` by default or `home-screen` for a widget page |

Omit fixture fields when the app does not use media fixtures. Omit `widget`
when no Home Screen shot is configured.

## Design constraints

- Keep all selected entity IDs stable across runs.
- Copy fixtures after install and before first launch.
- Place widgets only while the clone is Shutdown.
- Avoid staging Core Data directly; let the app own its persistence schema.
- Keep generated screenshot state out of Release builds.
- On iPhone, verify that requested widget families fit the Home Screen grid.
- Use one uncluttered Home Screen page and a small number of stock app icons.
