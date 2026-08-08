#!/usr/bin/env python3

"""Render a localized App Store screenshot set from a JSON manifest."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()

    manifest_path = Path(args.manifest).resolve()
    with manifest_path.open(encoding="utf-8") as file:
        manifest = json.load(file)

    screenshots = manifest.get("screenshots")
    if not isinstance(screenshots, list) or not screenshots:
        raise SystemExit("error: manifest must contain a non-empty screenshots array")

    orders = [item.get("order") for item in screenshots]
    if orders != list(range(1, len(screenshots) + 1)):
        raise SystemExit("error: screenshot order values must be contiguous and start at 1")

    renderer = Path(__file__).resolve().with_name("render.py")
    size = manifest.get("size", "1320x2868")
    background = manifest.get("background")
    background_opacity = manifest.get("backgroundOpacity", 0.8)
    style = manifest.get("style", "atmospheric")
    locale = manifest.get("locale", "en-US")

    rendered = 0
    skipped = 0
    for item in screenshots:
        status = item.get("status", "ready")
        if status == "needs-capture":
            print(f'Skipped {item["order"]:02d} {item["slug"]}: needs a real app capture')
            skipped += 1
            continue
        if status != "ready":
            raise SystemExit(f'error: unsupported status "{status}" for {item["slug"]}')
        command = [
            sys.executable,
            str(renderer),
            "--device-image",
            item["deviceImage"],
            "--headline",
            item["headline"],
            "--emphasis",
            item.get("emphasis", ""),
            "--subtitle",
            item["subtitle"],
            "--output",
            item["output"],
            "--size",
            size,
            "--background-opacity",
            str(background_opacity),
            "--style",
            item.get("style", style),
            "--eyebrow",
            item.get("eyebrow", item["feature"]),
            "--locale",
            locale,
        ]
        if background:
            command.extend(["--background", background])
        if "phoneWidthRatio" in item:
            command.extend(["--phone-width-ratio", str(item["phoneWidthRatio"])])
        if "phoneTopRatio" in item:
            command.extend(["--phone-top-ratio", str(item["phoneTopRatio"])])
        subprocess.run(command, check=True)
        rendered += 1

    print(f"Rendered {rendered}; skipped {skipped} pending captures from {manifest_path}")


if __name__ == "__main__":
    main()
