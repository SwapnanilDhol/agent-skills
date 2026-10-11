#!/usr/bin/env python3
"""stable_capture.py UDID DISPLAY OUT [TRIES]

Capture a simulator display until two consecutive frames (4 s apart) match. On a loaded
host the framebuffer `simctl io` returns can trail the real screen by seconds, and a
single capture often shows a half-finished transition. DISPLAY: 1 = outer, 3 = inner on
iPhone Duo; pass "-" for single-display simulators. Capturing an inactive display hangs,
so every call is wrapped in a 150 s alarm.
"""
import subprocess
import sys
import time

from PIL import Image, ImageChops

udid, display, out = sys.argv[1:4]
tries = int(sys.argv[4]) if len(sys.argv) > 4 else 6


def capture(path):
    cmd = ["perl", "-e", "alarm 150; exec @ARGV", "xcrun", "simctl", "io", udid,
           "screenshot", "--type=png"]
    if display != "-":
        cmd.append(f"--display={display}")
    cmd.append(path)
    return subprocess.run(cmd, capture_output=True).returncode == 0


previous = None
for attempt in range(tries):
    path = f"{out}.try{attempt}.png"
    if not capture(path):
        print("capture failed (inactive display or timeout)", attempt)
        continue
    frame = Image.open(path).convert("RGB")
    if previous is not None and previous.size == frame.size:
        diff = ImageChops.difference(previous, frame)
        changed = sum(1 for px in diff.getdata() if max(px) > 24)
        if changed < 1500:  # the status-bar clock alone changes a few hundred pixels
            frame.save(out)
            print(f"stable after {attempt + 1} captures ({changed} px changed) -> {out}")
            sys.exit(0)
        print("still changing", changed)
    previous = frame
    time.sleep(4)

if previous is not None:
    previous.save(out)
    print("NOT STABLE; saved the last frame", out)
sys.exit(1)
