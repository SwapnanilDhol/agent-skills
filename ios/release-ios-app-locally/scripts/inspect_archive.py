#!/usr/bin/env python3
"""Verify the identity of an exported Xcode application archive."""

from __future__ import annotations

import argparse
import json
import plistlib
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", required=True, type=Path)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    applications = args.archive / "Products" / "Applications"
    app_bundles = sorted(applications.glob("*.app")) if applications.is_dir() else []
    if len(app_bundles) != 1:
        raise SystemExit(f"expected exactly one archived app, found {len(app_bundles)}")

    info_path = app_bundles[0] / "Info.plist"
    if not info_path.is_file():
        raise SystemExit(f"missing archived Info.plist: {info_path}")
    with info_path.open("rb") as stream:
        info = plistlib.load(stream)

    actual = {
        "bundleId": str(info.get("CFBundleIdentifier", "")),
        "version": str(info.get("CFBundleShortVersionString", "")),
        "build": str(info.get("CFBundleVersion", "")),
    }
    expected = {
        "bundleId": args.bundle_id,
        "version": args.version,
        "build": str(args.build),
    }
    mismatches = [key for key in expected if actual[key] != expected[key]]
    if mismatches:
        for key in mismatches:
            print(f"{key}: expected {expected[key]!r}, found {actual[key]!r}")
        return 1

    print(json.dumps({"app": app_bundles[0].name, **actual}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
