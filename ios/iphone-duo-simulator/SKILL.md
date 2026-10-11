---
name: iphone-duo-simulator
description: Drive the iPhone Duo simulator unattended from an agent session on macOS with Xcode 27.1+ — fold/unfold through the Device Hub pose bar, rotate, tap and drag via cliclick, and capture the outer and inner displays as trustworthy evidence. Use when verifying an app's iPhone Duo layout, taking closed/open/portrait screenshots, proving taps landed, or when Duo simulator automation (axe, simctl, devicectl) fails or hangs.
---

# Drive the iPhone Duo simulator

Xcode 27 has no Simulator.app. Simulators live in **Device Hub**
(`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`), and the iPhone Duo's
pose (closed / book / open) is a hinge event that only Device Hub's pose bar can inject.
There is no CLI for it. This skill is the protocol that worked, unattended, on a host
shared with other agent sessions and a load average that swung between 5 and 600.

Read [references/device-hub-protocol.md](references/device-hub-protocol.md) before the
first pose change; it records every failure mode below with the numbers that were
measured. The scripts are in `scripts/`; run `scripts/duo.sh` with no arguments for usage.

## Never do these

- **Never** use `xcrun simctl io <udid> screenConfig … power` to fake a pose. It cuts the
  framebuffer, `devicectl` keeps reporting the old screen, and SpringBoard crash-loops.
- **Never** trust a capture without confirming which display is active
  (`duo.sh displays`): `LCD (primary) (active)` = closed, `LCD-1 (active)` = open.
- **Never** capture the inactive display without a timeout — it hangs. Wrap every
  `simctl io` / `devicectl` call: `perl -e 'alarm 150; exec @ARGV' xcrun …`.
- **Never** click device content without first checking Device Hub still shows your
  device (`duo.sh dclick` does this). Other sessions switch the selected device.
- **Never** touch another session's simulators, and keep at most two of your own booted.

## Tooling that does not work on the Duo

- `axe` cannot open an automation session ("Timed out creating the simulator remote
  automation session").
- The simulator MCP tool needs a one-time per-device access prompt that only a person can
  answer. Try `attach` once; if it reports no response to the access request, stop.
- `xcrun devicectl device orientation set` reports success but did not rotate the inner
  display. Use the pose bar's rotate button (`duo.sh rotate`).
- macOS System Events automation is usually denied; window moves and menu scripting via
  AppleScript fail. `osascript -e 'tell application "DeviceHub" to activate'` works.

What does work: synthetic mouse and keyboard input with `/opt/homebrew/bin/cliclick`
on the Device Hub window, which forwards it to the simulator as touches and hardware keys.

## Setup (once per session)

```bash
export DUO_UDID=<your iPhone Duo simulator UDID>
S=<path to this skill>/scripts
$S/duo.sh lock          # shared with other sessions; release as soon as you are done
$S/duo.sh shot          # then read /tmp/duo-sim/dh-small.png
```

1. Dismiss any macOS "… quit unexpectedly" dialog (ReportCrash for a simulator daemon)
   with its **Ignore** button before anything else.
2. Select your device in Device Hub's sidebar (`duo.sh click X Y` on its row — the
   sidebar re-sorts when devices boot, so locate the row from the fresh capture).
3. With your device showing, run `duo.sh ref-title`. Every `dclick`, `drag`, `pose`, and
   `rotate` afterwards refuses to act if the window title no longer matches.
4. Install and launch with `xcrun simctl install` / `launch`. The first launch after an
   install can take minutes on a loaded host; wait for a stable capture.

## Change the pose

```bash
$S/duo.sh setpose open      # or closed; polls devicectl for up to 3 minutes
```

- Pose-bar coordinates default to a 1470 × 956 pt display with Device Hub at its usual
  size (closed 810,871 · book 844,871 · open 878,871 · rotate 773,871). Read them from a
  capture and override with `DUO_POSE_*` if the window differs.
- On a quiet host the display switches in about 10 s; under load it took 1–3 minutes,
  and sometimes only after the next input event.
- If the pose bar's highlighted button disagrees with the device (bar says *closed*,
  device is open), press the pose the bar shows, then the one you want.
- Rotate with `duo.sh rotate`; each press is a quarter turn
  (landscapeRight → portraitUpsideDown → landscapeLeft → portrait). The open pose's
  natural posture is landscapeRight; inner portrait is the only pose with horizontal bars.
- A pose does not survive a simulator reboot (it comes back closed).

## Tap, drag, type

1. `duo.sh shot`, then find the device screen rectangle:
   `python3 $S/screen_rect.py /tmp/duo-sim/dh.png <row-pt> <col-pt>` — the screen edges
   are the inner edges of the outermost dark (bezel) runs. Re-measure after every pose
   change, rotation, or window move.
2. Get the target in device points from a capture (pixels ÷ 3), then
   `python3 $S/device_to_mac.py LEFT TOP RIGHT BOTTOM DEV_W DEV_H DX DY`
   (outer 466 × 678, inner landscape 951 × 669, inner portrait 669 × 951).
3. `duo.sh dclick X Y` — a native click. Press/release pairs (`dd`/`du`) arrived seconds
   apart under load and registered as long presses (rows highlight, nothing happens).
4. Scroll with `duo.sh drag X1 Y1 X2 Y2`. Drags scrolled content but did not dismiss sheets.
5. Type into a focused field with `cliclick t:"text"` and submit with `cliclick kp:return`
   (Device Hub forwards the Mac keyboard as a hardware keyboard). An alert button that
   ignored clicks accepted Return.

## Capture and prove

```bash
$S/duo.sh displays                       # which screen is live, and its orientation
$S/duo.sh capture 3 /tmp/out/open.png    # 1 = outer, 3 = inner; waits for two equal frames
```

- Every tap must be proven by the next capture. If a capture looks stale (unchanged
  clock, half-finished transition), compare with the Device Hub window (`duo.sh shot`) or
  confirm the touch reached the app:
  `xcrun simctl spawn $DUO_UDID log show --last 2m --predicate 'process == "<App>" AND eventMessage CONTAINS "Sending UIEvent type: 0"'`
  (a down/up pair seconds apart means the click arrived as a long press).
- Debug launch arguments that open a screen directly save taps, but walk the real path
  (Home → feature) at least once per pose.
- Downscale evidence for repos with `sips -Z 1200`, name it `<screen>-<pose>.png`.

## Recover

- Frozen frame that survives `simctl terminate`, or captures that never change:
  `xcrun simctl shutdown $DUO_UDID && xcrun simctl boot $DUO_UDID`, re-select it in
  Device Hub, run `ref-title` again, and re-apply the pose.
- Device Hub stuck showing the device's side view: press the pose the bar shows, wait,
  then the pose you want; re-selecting the device alone did not help.
- Release the lock (`duo.sh unlock`) whenever you stop clicking, including before long
  installs or builds.

## Report honestly

State which poses and orientations were captured, which taps were proven, and what
could not be driven (book/tabletop poses, swipe-to-dismiss, anything that timed out
under load). Partially folded behaviour is not observable through this protocol unless
you actually exercised the book pose.
