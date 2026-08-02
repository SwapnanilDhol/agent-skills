#!/usr/bin/env python3
"""Validate version-level localized App Store metadata."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


REQUIRED_FIELDS = (
    "description",
    "keywords",
    "marketingUrl",
    "supportUrl",
    "whatsNew",
    "promotionalText",
)
PLACEHOLDER_PATTERN = re.compile(r"(?:<[^>]+>|\bTODO\b|\bTBD\b|REPLACE_ME)", re.IGNORECASE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata-dir", required=True, type=Path)
    parser.add_argument("--locales", required=True, help="Comma-separated locale identifiers")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    locales = [locale.strip() for locale in args.locales.split(",") if locale.strip()]
    if not locales:
        raise SystemExit("at least one locale is required")
    if not args.metadata_dir.is_dir():
        raise SystemExit(f"metadata directory does not exist: {args.metadata_dir}")

    errors: list[str] = []
    for locale in locales:
        path = args.metadata_dir / f"{locale}.json"
        if not path.is_file():
            errors.append(f"{locale}: missing {path.name}")
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"{locale}: invalid JSON: {error}")
            continue

        if not isinstance(payload, dict):
            errors.append(f"{locale}: top-level JSON value must be an object")
            continue
        for field in REQUIRED_FIELDS:
            value = payload.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{locale}: {field} must be a nonempty string")
            elif PLACEHOLDER_PATTERN.search(value):
                errors.append(f"{locale}: {field} contains a placeholder")

        keywords = payload.get("keywords")
        if isinstance(keywords, str) and len(keywords) > 100:
            errors.append(f"{locale}: keywords are {len(keywords)} characters; maximum is 100")
        promotional_text = payload.get("promotionalText")
        if isinstance(promotional_text, str) and len(promotional_text) > 170:
            errors.append(
                f"{locale}: promotionalText is {len(promotional_text)} characters; maximum is 170"
            )

    if errors:
        print("Metadata validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Metadata validation passed for {len(locales)} locale(s): {', '.join(locales)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
