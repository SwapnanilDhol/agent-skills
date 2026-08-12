#!/usr/bin/env python3
"""Produce a redacted, deterministic analytics inventory for a source repository."""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path
from typing import Iterable


EXCLUDED_DIRS = {
    ".git", ".build", ".next", ".swiftpm", "Pods", "DerivedData", "build", "coverage",
    "dist", "node_modules", "vendor",
}
SOURCE_SUFFIXES = {
    ".c", ".cc", ".cpp", ".cs", ".go", ".h", ".hpp", ".java", ".js", ".jsx", ".kt",
    ".kts", ".m", ".mm", ".php", ".py", ".rb", ".rs", ".swift", ".ts", ".tsx", ".vue",
}
CONFIG_NAMES = {
    "Package.swift", "Package.resolved", "Podfile", "build.gradle", "build.gradle.kts",
    "package.json", "requirements.txt", "pyproject.toml", "Cargo.toml", "Info.plist",
    "wrangler.json", "wrangler.jsonc", "wrangler.toml",
}

PATTERNS: dict[str, list[tuple[str, re.Pattern[str]]]] = {
    "providers": [
        ("Firebase Analytics", re.compile(r"FirebaseAnalytics|Analytics\.logEvent|SFKFirebaseLogger", re.I)),
        ("Mixpanel", re.compile(r"\bMixpanel\b", re.I)),
        ("TelemetryDeck", re.compile(r"TelemetryDeck|SFKTelemetryLogger", re.I)),
        ("PostHog", re.compile(r"\bPostHog\b", re.I)),
        ("Amplitude", re.compile(r"import\s+Amplitude|@amplitude/|amplitude-swift|Amplitude\.instance", re.I)),
        ("Segment", re.compile(r"import\s+Segment|@segment/analytics|segment-analytics", re.I)),
        ("Crash reporting", re.compile(r"Crashlytics|\bSentry\b|recordNonFatal|recordException", re.I)),
        ("RevenueCat", re.compile(r"RevenueCat|Purchases\.shared|appUserID", re.I)),
        ("Ad provider", re.compile(r"GoogleMobileAds|\bAdMob\b|\bGAD[A-Z]|AdsManager", re.I)),
    ],
    "event_calls": [
        ("Event call", re.compile(r"\b(logEvent|trackEvent|capture|trackScreen|screenView)\s*\(", re.I)),
        ("Identity/property call", re.compile(r"\b(setUserID|identifyUser|identify|setUserProperty|setAttributes)\s*\(", re.I)),
    ],
    "candidate_outcomes": [
        ("Monetization", re.compile(r"purchase|paywall|restore|subscription|entitlement|checkout", re.I)),
        ("Activation/onboarding", re.compile(r"onboard|sign.?up|register|activation|permission", re.I)),
        ("Core outcome", re.compile(r"\b(save|saved|create|created|export|share|import|backup|generate|complete|success)", re.I)),
        ("Terminal failure", re.compile(r"\b(catch|failure|failed|error|timeout|rate.?limit)", re.I)),
    ],
    "volume_risks": [
        ("Lifecycle repeat", re.compile(r"onAppear|onChange|componentDidMount|useEffect|viewDidAppear", re.I)),
        ("Interaction noise", re.compile(r"onTap|onClick|buttonTapped|didSelect|scroll|drag|hover|keystroke", re.I)),
        ("High-frequency callback", re.compile(r"impression|heartbeat|timer|poll|progress|frame|retry", re.I)),
        ("Device identity", re.compile(r"identifierForVendor|advertisingIdentifier|\bIDFA\b|\bIDFV\b|device[_ .-]?id\b", re.I)),
    ],
    "backend_observability": [
        ("Structured/error log", re.compile(r"console\.(error|warn)|Logger\.error|log\.error|tracing::error", re.I)),
        ("HTTP route", re.compile(r"app\.(get|post|put|patch|delete)|router\.|@app\.route|fetch\s*\(", re.I)),
    ],
}


def source_files(root: Path) -> Iterable[Path]:
    for current, directories, files in os.walk(root):
        directories[:] = sorted(d for d in directories if d not in EXCLUDED_DIRS and not d.startswith("."))
        for name in sorted(files):
            path = Path(current) / name
            if path.suffix.lower() in SOURCE_SUFFIXES or name in CONFIG_NAMES:
                try:
                    if path.stat().st_size <= 2_000_000:
                        yield path
                except OSError:
                    continue


def scan(root: Path, limit: int) -> dict[str, dict[str, list[str]]]:
    results: dict[str, dict[str, list[str]]] = {
        section: {label: [] for label, _ in entries} for section, entries in PATTERNS.items()
    }
    for path in source_files(root):
        try:
            lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        except OSError:
            continue
        relative = path.relative_to(root)
        for line_number, line in enumerate(lines, 1):
            for section, entries in PATTERNS.items():
                for label, pattern in entries:
                    bucket = results[section][label]
                    if len(bucket) < limit and pattern.search(line):
                        bucket.append(f"{relative}:{line_number}")
    return results


def render(root: Path, results: dict[str, dict[str, list[str]]]) -> str:
    titles = {
        "providers": "Providers and identity",
        "event_calls": "Existing instrumentation calls",
        "candidate_outcomes": "Candidate outcome areas (inspect context)",
        "volume_risks": "Potential volume or identity risks",
        "backend_observability": "Backend observability surfaces",
    }
    output = ["# Analytics scan", "", f"Repository: `{root}`", ""]
    for section, groups in results.items():
        output.extend([f"## {titles[section]}", ""])
        populated = False
        for label, locations in groups.items():
            if not locations:
                continue
            populated = True
            output.append(f"### {label} ({len(locations)} shown)")
            output.append("")
            output.extend(f"- `{location}`" for location in locations)
            output.append("")
        if not populated:
            output.extend(["No matches found.", ""])
    output.extend([
        "## Interpretation",
        "",
        "Matches are redacted file/line pointers. Inspect full control flow before selecting events. ",
        "Provider matches can be transitive or inactive; candidate and risk matches are not findings by themselves.",
        "",
    ])
    return "\n".join(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", nargs="?", default=".", help="Repository root")
    parser.add_argument("--limit", type=int, default=40, help="Maximum locations per label")
    args = parser.parse_args()
    root = Path(args.repository).expanduser().resolve()
    if not root.is_dir():
        parser.error(f"not a directory: {root}")
    if args.limit < 1 or args.limit > 500:
        parser.error("--limit must be between 1 and 500")
    print(render(root, scan(root, args.limit)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
