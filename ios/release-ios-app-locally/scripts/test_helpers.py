#!/usr/bin/env python3
"""Focused tests for the deterministic local-release helpers."""

from __future__ import annotations

import json
import plistlib
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parent


def run_script(name: str, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(SCRIPTS / name), *arguments],
        check=False,
        capture_output=True,
        text=True,
    )


class ReleaseHelperTests(unittest.TestCase):
    def test_release_context_is_version_scoped_and_build_specific(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = run_script(
                "derive_release_context.py",
                "--version",
                "8.2.0",
                "--build",
                "3",
                "--repo-root",
                directory,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            payload = json.loads(result.stdout)
            self.assertEqual(payload["branch"], "release/8.2.0.3")
            self.assertEqual(payload["tag"], "v8.2.0.3")
            self.assertTrue(payload["metadataDirectory"].endswith("metadata/version/8.2.0"))
            self.assertTrue(payload["releaseNotesFile"].endswith("docs/releases/8.2.0.md"))

    def test_release_context_rejects_invalid_version(self) -> None:
        result = run_script(
            "derive_release_context.py", "--version", "8.2", "--build", "1"
        )
        self.assertNotEqual(result.returncode, 0)

    def test_metadata_validation_accepts_complete_locale(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            metadata = Path(directory)
            payload = {
                "description": "Create useful things.",
                "keywords": "create,utility",
                "marketingUrl": "https://example.com",
                "supportUrl": "https://example.com/support",
                "whatsNew": "Improved reliability.",
                "promotionalText": "Create faster with a polished workflow.",
            }
            (metadata / "en-US.json").write_text(json.dumps(payload), encoding="utf-8")
            result = run_script(
                "validate_metadata.py",
                "--metadata-dir",
                directory,
                "--locales",
                "en-US",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_metadata_validation_rejects_placeholders(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            metadata = Path(directory)
            payload = {
                "description": "<LOCALIZED_DESCRIPTION>",
                "keywords": "create,utility",
                "marketingUrl": "https://example.com",
                "supportUrl": "https://example.com/support",
                "whatsNew": "Improved reliability.",
                "promotionalText": "Create faster.",
            }
            (metadata / "en-US.json").write_text(json.dumps(payload), encoding="utf-8")
            result = run_script(
                "validate_metadata.py",
                "--metadata-dir",
                directory,
                "--locales",
                "en-US",
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("placeholder", result.stdout)

    def test_archive_inspection_matches_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "App.xcarchive"
            app = archive / "Products" / "Applications" / "Example.app"
            app.mkdir(parents=True)
            with (app / "Info.plist").open("wb") as stream:
                plistlib.dump(
                    {
                        "CFBundleIdentifier": "com.example.app",
                        "CFBundleShortVersionString": "8.2.0",
                        "CFBundleVersion": "1",
                    },
                    stream,
                )
            result = run_script(
                "inspect_archive.py",
                "--archive",
                str(archive),
                "--bundle-id",
                "com.example.app",
                "--version",
                "8.2.0",
                "--build",
                "1",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
