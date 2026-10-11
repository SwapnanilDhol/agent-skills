#!/usr/bin/env python3
"""screen_rect.py CAPTURE ROW_PT COL_PT [--from X0 --to X1]

Locate the device screen inside a Device Hub capture by scanning for the bezel (runs of
near-black pixels) along one row and one column that cross the screen. Prints the dark
runs in Mac points; the screen edges are the inner edges of the outermost bezel runs.
Pick a row and column through plain background (not dark text or buttons).

Example: screen_rect.py /tmp/duo-sim/dh.png 400 700
"""
import argparse

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("capture")
parser.add_argument("row", type=float, help="Mac-point y of the row to scan")
parser.add_argument("col", type=float, help="Mac-point x of the column to scan")
parser.add_argument("--screen-width-pt", type=float, default=1470)
parser.add_argument("--min-run", type=int, default=6, help="minimum dark run in pixels")
args = parser.parse_args()

image = Image.open(args.capture).convert("RGB")
scale = image.width / args.screen_width_pt


def dark(px):
    return max(px) < 70


def runs(values):
    out, start, prev = [], None, None
    for v in values:
        if prev is None or v != prev + 1:
            if start is not None:
                out.append((start, prev))
            start = v
        prev = v
    if start is not None:
        out.append((start, prev))
    return [(round(a / scale, 1), round(b / scale, 1)) for a, b in out if b - a >= args.min_run]


y = int(args.row * scale)
x = int(args.col * scale)
print("row", args.row, runs([i for i in range(image.width) if dark(image.getpixel((i, y)))]))
print("col", args.col, runs([j for j in range(image.height) if dark(image.getpixel((x, j)))]))
