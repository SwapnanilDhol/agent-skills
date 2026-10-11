# Device Hub protocol for the iPhone Duo simulator — measured details

Recorded on 2026-10-11 while verifying an iPhone Duo port of a UIKit-hosted SwiftUI app
(Xcode 27.1, iOS 27.1 iPhone Duo simulator, macOS 27, main display 1470 × 956 pt). Two
other agent sessions were driving their own Duo simulators on the same Mac at the time,
and the load average swung between 5 and 600.

## Displays

| | Display flag | Capture size | Points | Active when |
|---|---|---|---|---|
| Outer LCD | `--display=1` | 1398 × 2034 px | 466 × 678 | closed |
| Inner LCD-1 | `--display=3` | 2853 × 2007 px (landscape) | 951 × 669 | open |

`xcrun devicectl device info displays --device <udid>` prints `LCD (primary) (active)` or
`LCD-1 (active)` plus a `Main display orientation:` line. Capturing the inactive display
hangs indefinitely; a capture of the active one took 1–60 s depending on load.

The fold's division region (queried in-app with
`reservedRegions(kind: .division, options: .includeInactive)`) reported a frame of
≈ 455.5–495.5 pt on the flat inner display in landscape: the fold centre (475.5 pt) plus
the system's 20 pt clearance each side. In inner portrait the region runs across the
screen (it divides top from bottom), so side-by-side layouts must ignore it.

## Device Hub window geometry (at its usual size)

| Element | Mac points |
|---|---|
| Pose bar buttons (y 871) | rotate 773 · closed 810 · book 844 · open 878 |
| Window title crop (device name) | x 366–560, y 108–127 |
| Sidebar device rows | x ≈ 175, rows 50 pt apart starting ≈ y 224; order changes as devices boot |
| Outer screen, closed | x 647.5 → 895.5, y 321.5 → 681.5 |
| Inner screen, open landscape | x 515 → 1021.5, y 323.5 → 679 |
| Inner screen, open portrait | x 590.5 → 946, y 248 → 754.5 |
| iPhone 17 Pro screen (for comparison runs) | x 619 → 917.5, y 177 → 826 |

The Dock sat just below the pose bar; Dock tooltips appearing over the pose bar meant the
pointer was in the Dock's hover zone. Dragging Device Hub's toolbar did not move the
window.

## What failed, and what replaced it

| Attempt | Result | Replacement |
|---|---|---|
| `simctl io … screenConfig power off/on` | SpringBoard crash loop, `devicectl` still reports the old screen | Device Hub pose bar |
| `axe tap` on the Duo | automation session times out | `cliclick` on Device Hub |
| `axe tap` on an iOS 26.5 iPhone while the host was loaded | "completed successfully", nothing happened (no touch reached the app) | `cliclick` on Device Hub with that device selected |
| `devicectl device orientation set portrait` | reports success, display stays landscape | pose-bar rotate button |
| `cliclick dd … du` on device content | down/up logged seconds apart → long press | `cliclick m:X,Y w:300 c:X,Y` |
| `cliclick c:` on the pose bar | sometimes ignored | `dd`/`du` press on the pose bar |
| Device Hub drag on a sheet grabber | sheet did not move | dismiss via the app's own controls |
| Tapping an alert's default button | ignored once | `cliclick kp:return` |
| Trusting a single `simctl io` capture | stale or mid-transition frames | capture until two frames 4 s apart match |
| Holding the shared lock | another session still re-selected Device Hub's device; two clicks landed on its iPad | compare the window title crop before every click |

## Timing under load

- Pose change: ≈ 10 s on a quiet host; 1–3 min at load 150–500, sometimes completing only
  after the next input event. The pose bar's highlighted state drifted from the device's
  real pose twice; pressing the highlighted pose, then the wanted one, resynced it.
- First launch after `simctl install`: up to ~10 min before the app's scene connected
  (white screen until then); later launches 20–60 s.
- A pushed navigation transition stayed visually half-finished until the next input
  event; a harmless tap on empty content flushed it.

## Evidence conventions that held up

- Name captures `<screen>-<pose>.png` (`closed`, `open-landscape`, `open-portrait`),
  downscale with `sips -Z 1200`, keep `baseline/` captures from the pre-change build for
  before/after comparison.
- For "no change on ordinary iPhones" claims, capture the same screens on a regular
  iPhone simulator with the pre-change and post-change builds (identical launch order, so
  persisted state matches) and pixel-diff them, masking server-driven content and the
  home indicator.
- Prove state-survival claims with paired captures: act in one pose (e.g. open a
  section), change pose, capture the other display.
