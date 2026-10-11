#!/usr/bin/env python3
"""device_to_mac.py LEFT TOP RIGHT BOTTOM DEV_W DEV_H DX DY

Map a device point (DX, DY) to a Mac point for cliclick, given the device screen rect in
Mac points (from screen_rect.py) and the device's point size in the current pose:
outer 466 x 678, inner landscape 951 x 669, inner portrait 669 x 951. Device points come
from a `simctl io` capture divided by 3.
"""
import sys

left, top, right, bottom, dev_w, dev_h, dx, dy = (float(v) for v in sys.argv[1:9])
mac_x = left + dx * (right - left) / dev_w
mac_y = top + dy * (bottom - top) / dev_h
print(f"{mac_x:.0f} {mac_y:.0f}")
