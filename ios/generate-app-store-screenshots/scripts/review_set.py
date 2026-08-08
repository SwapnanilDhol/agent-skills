#!/usr/bin/env python3

"""Build a labeled thumbnail contact sheet for visual screenshot review."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def label_font(locale: str, size: int) -> ImageFont.FreeTypeFont:
    if locale == "ja":
        return ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", size, index=0)
    if locale == "ko":
        return ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", size, index=0)
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--columns", type=int, default=3)
    args = parser.parse_args()

    if args.columns < 1:
        raise SystemExit("error: --columns must be at least 1")

    manifest_path = Path(args.manifest).resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    ready = [item for item in manifest["screenshots"] if item.get("status", "ready") == "ready"]
    if not ready:
        raise SystemExit("error: manifest has no ready screenshots")

    try:
        expected_size = tuple(int(value) for value in manifest.get("size", "1320x2868").split("x"))
    except (AttributeError, ValueError) as error:
        raise SystemExit("error: manifest size must use WIDTHxHEIGHT format") from error
    if len(expected_size) != 2:
        raise SystemExit("error: manifest size must use WIDTHxHEIGHT format")

    thumb_width = 330
    thumb_height = round(thumb_width * expected_size[1] / expected_size[0])
    label_height = 42
    gap = 20
    margin = 24
    rows = math.ceil(len(ready) / args.columns)
    sheet_width = margin * 2 + args.columns * thumb_width + (args.columns - 1) * gap
    sheet_height = margin * 2 + rows * (thumb_height + label_height) + (rows - 1) * gap
    sheet = Image.new("RGB", (sheet_width, sheet_height), "white")
    draw = ImageDraw.Draw(sheet)
    locale = manifest.get("locale", "en-US")

    for index, item in enumerate(ready):
        image_path = Path(item["output"]).resolve()
        with Image.open(image_path) as source:
            if source.size != expected_size or source.mode != "RGB":
                raise SystemExit(f"error: invalid App Store output: {image_path}")
            thumb = source.resize((thumb_width, thumb_height), Image.Resampling.LANCZOS)
        column = index % args.columns
        row = index // args.columns
        x = margin + column * (thumb_width + gap)
        y = margin + row * (thumb_height + label_height + gap)
        sheet.paste(thumb, (x, y))
        label = f'{item["order"]:02d} · {item["feature"]}'
        font = label_font(locale, 18)
        for size in range(17, 8, -1):
            if draw.textlength(label, font=font) <= thumb_width:
                break
            font = label_font(locale, size)
        draw.text((x, y + thumb_height + 10), label, font=font, fill=(8, 8, 12))

    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path, format="PNG", optimize=True)
    print(f"Review sheet: {output_path}")


if __name__ == "__main__":
    main()
