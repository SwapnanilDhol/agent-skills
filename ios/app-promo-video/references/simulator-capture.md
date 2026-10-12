# Simulator capture

What it took to get clean recordings for PassMaker. Assume a shared, busy Mac.

## Before recording

- **Load.** `sysctl -n vm.loadavg`. At ~390 (several iOS 27 simulators booted
  by other sessions, Spotlight indexing a new simulator) the app ignored taps
  for 20–30 s after launch and recordings dropped frames. Below ~10 it was
  clean. Shut down only simulators you booted; ask about the rest.
- **OS.** Use the OS the features need. PassMaker's poster passes (and the
  gallery section that lists them) exist only on iOS 27; on iOS 26.5 they
  silently disappear. Check `xcrun simctl list runtimes -j` for supported
  device types: iOS 27.1 only offered iPhone Duo; iOS 27.0 offered iPhone 18
  Pro. Create a dedicated simulator for the promo
  (`xcrun simctl create "<App> Promo iPhone 18 Pro" …`) rather than borrowing
  another project's.
- **State.** Pin the status bar (`simctl status_bar … --time 9:41 …`), force
  premium/debug states via launch environment (`SIMCTL_CHILD_<KEY>=…`), and
  dismiss one-time system UI off-camera: Photos "Private Access" banner,
  Wallet location prompt (iOS 26), "What's New in Wallet" (iOS 27).
- **Test data.** Remove leftovers from exploration (an ugly AI-generated card
  sitting in Wallet showed up in the final list shot).

## Driving the app

- Use `axe` with `--tap-style physical` (the default can report success and do
  nothing). First use on a new simulator may time out creating its automation
  session; retry.
- `axe describe-ui` sees full-screen views but **not sheets**; waiting for a
  label inside a sheet never succeeds. For remote views (PassKit's Add to
  Wallet sheet) sample a pixel in a 3× screenshot instead (`wait_pixel`).
- Debug "screenshot scene" launch flags often render a screen with no-op
  handlers; go through the real navigation for anything you need to tap.
- After a cold launch, probe responsiveness (tap something harmless, confirm,
  undo) before starting the recorder.
- Launching an app straight from another app adds a "◂ App" back link to the
  status bar; press Home first.
- Wallet restores its last screen, including an open pass. Close it before
  recording, and remove an existing copy of the pass you're adding (otherwise
  the sheet says "Update"). On iOS 26/27: pass → More (363, 84) → Remove Pass
  (250, 156) → Remove (273, 179).
- AI flows that call a production API cost real requests; once you've decided
  to mock them, stop exercising them.

## Recording

- One short recording per scene (`rec_start` / `rec_stop`); set up state
  between recordings, not on camera.
- `simctl io recordVideo` is variable-frame-rate and stops writing frames while
  the screen is still, so files can end early. Convert with `fps=30` and pad
  with `tpad=stop_mode=clone`.
- Don't poll screenshots during animations you want smooth; poll
  `axe describe-ui` (cheap) and keep screenshot probes to static waits.
- Leave ~1 s of stillness at both ends of each recording for clean cuts.
