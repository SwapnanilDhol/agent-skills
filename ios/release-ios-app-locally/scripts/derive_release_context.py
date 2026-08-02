#!/usr/bin/env python3
"""Derive deterministic paths and refs for one iOS release build."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True, type=int)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--metadata-root", default="metadata/version")
    parser.add_argument("--release-notes-root", default="docs/releases")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not VERSION_PATTERN.fullmatch(args.version):
        raise SystemExit("version must use MAJOR.MINOR.PATCH, for example 8.2.0")
    if args.build < 1:
        raise SystemExit("build must be a positive integer")

    repository = args.repo_root.resolve()
    release_id = f"{args.version}.{args.build}"
    metadata_dir = repository / args.metadata_root / args.version
    release_notes = repository / args.release_notes_root / f"{args.version}.md"

    result = {
        "version": args.version,
        "build": args.build,
        "releaseId": release_id,
        "branch": f"release/{release_id}",
        "tag": f"v{release_id}",
        "metadataDirectory": str(metadata_dir),
        "metadataExists": metadata_dir.is_dir(),
        "releaseNotesFile": str(release_notes),
        "releaseNotesExist": release_notes.is_file(),
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
