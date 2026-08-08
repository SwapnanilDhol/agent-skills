#!/usr/bin/env python3
"""Capture a configured iOS Simulator screenshot set without hand navigation.

The host app owns deterministic fixture seeding and route arguments. This helper
owns the disposable Simulator clone, fixture copying, optional widget placement,
presentation preflight, settled-frame capture, orientation, and cleanup.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import shutil
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional


SCRIPTS = Path(__file__).resolve().parent


def run(*args: str, check: bool = True) -> str:
    result = subprocess.run(
        args,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    output = (result.stdout or "").strip()
    if check and result.returncode != 0:
        raise SystemExit(
            f"Command failed ({result.returncode}): {' '.join(args)}\n{output}"
        )
    return output


def simctl(*args: str, check: bool = True) -> str:
    return run("xcrun", "simctl", *args, check=check)


def device_state(udid: str) -> str:
    devices = json.loads(simctl("list", "devices", "-j"))
    for runtime in devices["devices"].values():
        for device in runtime:
            if device["udid"] == udid:
                return device["state"]
    return "unknown"


def wait_for_state(udid: str, state: str, timeout: float = 60) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if device_state(udid) == state:
            return
        time.sleep(0.5)
    raise SystemExit(f"Simulator {udid} did not reach {state}")


def device_data_dir(udid: str) -> Path:
    return Path.home() / "Library/Developer/CoreSimulator/Devices" / udid / "data"


def app_group_dir(udid: str, bundle_id: str, app_group: str) -> Path:
    output = simctl("get_app_container", udid, bundle_id, "groups")
    for line in output.splitlines():
        identifier, _, path = line.partition("\t")
        if identifier.strip() == app_group:
            return Path(path.strip())
    raise SystemExit(f"App group container not found: {app_group}")


def resolve_path(repo_root: Path, value: str) -> Path:
    path = Path(value).expanduser()
    return path if path.is_absolute() else repo_root / path


def stage_fixtures(
    udid: str,
    bundle_id: str,
    source: Optional[Path],
    destination: Optional[str],
) -> None:
    if source is None or destination is None:
        return
    if not source.is_dir():
        raise SystemExit(f"Fixture directory not found: {source}")
    app_data = Path(simctl("get_app_container", udid, bundle_id, "data"))
    target = app_data / destination
    target.mkdir(parents=True, exist_ok=True)
    fixtures = sorted(path for path in source.rglob("*") if path.is_file())
    if not fixtures:
        raise SystemExit(f"No fixture files found in {source}")
    for fixture in fixtures:
        relative = fixture.relative_to(source)
        output = target / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(fixture, output)


def stage_app_group_preferences(
    group_dir: Path,
    preference_domain: str,
    overrides: Dict[str, Any],
) -> None:
    if not overrides:
        return
    path = group_dir / "Library/Preferences" / f"{preference_domain}.plist"
    values = plistlib.loads(path.read_bytes()) if path.exists() else {}
    values.update(overrides)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(plistlib.dumps(values, fmt=plistlib.FMT_BINARY))


def keep_app_icon(entry: object) -> bool:
    if not isinstance(entry, str):
        return False
    lowered = entry.lower()
    return "xctrunner" not in lowered and "uitests" not in lowered


def widget_entry(
    bundle_id: str,
    extension_id: str,
    widget_kind: str,
    grid_size: str,
) -> Dict[str, Any]:
    identity = f"{bundle_id}/{widget_kind}/{grid_size}"
    container = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{identity}/container"))
    unique = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{identity}/widget"))
    return {
        "allowsExternalSuggestions": True,
        "allowsSuggestions": True,
        "bundleIdentifier": extension_id,
        "containerBundleIdentifier": bundle_id,
        "displayIdentifier": container.upper(),
        "elementType": "widget",
        "gridSize": grid_size,
        "iconType": "custom",
        "uniqueIdentifier": unique.upper(),
        "userSelectedElementIdentifier": unique.upper(),
        "widgetIdentifier": widget_kind,
    }


def place_widgets(udid: str, bundle_id: str, widget: Dict[str, Any]) -> None:
    sizes = widget.get("sizes", ["medium"])
    unsupported = set(sizes) - {"small", "medium", "large"}
    if unsupported:
        raise SystemExit(f"Unsupported widget sizes: {sorted(unsupported)}")

    path = device_data_dir(udid) / "Library/SpringBoard/IconState.plist"
    if not path.exists():
        raise SystemExit(f"SpringBoard icon state not found: {path}")
    state = plistlib.loads(path.read_bytes())
    apps: List[str] = []
    for page in state.get("iconLists", []):
        for entry in page:
            if keep_app_icon(entry) and entry not in apps:
                apps.append(entry)

    entries = [
        widget_entry(
            bundle_id,
            widget["extensionBundleIdentifier"],
            widget["kind"],
            size,
        )
        for size in sizes
    ]
    app_slots = int(widget.get("appSlots", 8))
    state["iconLists"] = [[*entries, *apps[:app_slots]]]
    path.write_bytes(plistlib.dumps(state, fmt=plistlib.FMT_BINARY))


def remove_test_runners(udid: str) -> None:
    for line in simctl("listapps", udid).splitlines():
        if "xctrunner" not in line.lower():
            continue
        identifier = line.strip().split("=")[0].strip().strip('"')
        if "xctrunner" in identifier.lower():
            simctl("uninstall", udid, identifier, check=False)


def rotate_to_landscape(udid: str, clone_name: str) -> None:
    run("osascript", "-e", 'tell application "Simulator" to quit', check=False)
    time.sleep(3)
    run("open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", udid)
    deadline = time.time() + 45
    while time.time() < deadline:
        windows = run(
            "osascript",
            "-e",
            'tell application "System Events" to tell process "Simulator" '
            'to get name of every window',
            check=False,
        )
        if clone_name in windows:
            break
        time.sleep(2)
    else:
        raise SystemExit(f"Simulator window for {clone_name} never appeared")

    script = f'''
    tell application "Simulator" to activate
    delay 1.5
    tell application "System Events"
      tell process "Simulator"
        set frontmost to true
        perform action "AXRaise" of (first window whose name contains "{clone_name}")
        delay 1
        key code 124 using command down
      end tell
    end tell
    '''
    run("osascript", "-e", script)
    time.sleep(3)


def upright_landscape(path: Path) -> None:
    from PIL import Image

    with Image.open(path) as image:
        image.transpose(Image.ROTATE_270).save(path)


def screenshot_attempt(udid: str, destination: Path) -> bytes:
    last_error = ""
    for _ in range(5):
        destination.unlink(missing_ok=True)
        try:
            simctl("io", udid, "screenshot", str(destination))
        except SystemExit as error:
            last_error = str(error)
            time.sleep(1.5)
            continue
        if destination.exists() and destination.stat().st_size:
            return destination.read_bytes()
        time.sleep(1.5)
    raise SystemExit(f"Capture failed: {destination}\n{last_error}")


def capture_settled(udid: str, destination: Path, timeout: float = 25) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.time() + timeout
    previous = screenshot_attempt(udid, destination)
    while time.time() < deadline:
        time.sleep(1)
        current = screenshot_attempt(udid, destination)
        if current == previous:
            return
        previous = current
    print(f"warning: {destination.name} never settled; using the last frame")


def require_config(config: Dict[str, Any]) -> None:
    required = ("appName", "bundleIdentifier", "shots")
    missing = [key for key in required if not config.get(key)]
    if missing:
        raise SystemExit(f"Missing workflow keys: {', '.join(missing)}")
    if not isinstance(config["shots"], list):
        raise SystemExit("workflow shots must be an array")
    for shot in config["shots"]:
        if not shot.get("slug"):
            raise SystemExit("Every shot requires a slug")
        if shot.get("surface", "app") not in {"app", "home-screen"}:
            raise SystemExit(f"Unsupported surface for {shot['slug']}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, help="Screenshot workflow JSON")
    parser.add_argument("--app", required=True, help="Path to the built .app")
    parser.add_argument("--source-udid", required=True, help="Shutdown Simulator to clone")
    parser.add_argument("--repo-root", default=".", help="Base for relative workflow paths")
    parser.add_argument("--raw-dir", help="Override configured raw output directory")
    parser.add_argument("--landscape", action="store_true", help="Force landscape capture")
    parser.add_argument("--settle", type=float, help="Override post-launch wait")
    parser.add_argument("--keep", action="store_true", help="Keep clone for debugging")
    args = parser.parse_args()

    config_path = Path(args.config).expanduser().resolve()
    config = json.loads(config_path.read_text(encoding="utf-8"))
    require_config(config)
    repo_root = Path(args.repo_root).expanduser().resolve()
    app_path = Path(args.app).expanduser().resolve()
    if not app_path.is_dir() or app_path.suffix != ".app":
        raise SystemExit(f"App bundle not found: {app_path}")
    if device_state(args.source_udid) != "Shutdown":
        raise SystemExit("Source Simulator must be Shutdown before cloning")

    screenshot = config.get("screenshot", {})
    raw_value = args.raw_dir or screenshot.get("rawDir", "app_store/screenshots/raw/en-US")
    raw_dir = resolve_path(repo_root, raw_value)
    launch_arguments = [str(value) for value in screenshot.get("launchArguments", [])]
    route_argument = screenshot.get("routeArgument")
    settle = args.settle if args.settle is not None else float(screenshot.get("settleSeconds", 4))
    fixture_source = screenshot.get("fixtureSourceDir")
    fixture_path = resolve_path(repo_root, fixture_source) if fixture_source else None
    fixture_destination = screenshot.get("fixtureDestination")
    landscape = args.landscape or bool(config.get("presentation", {}).get("landscape"))
    bundle_id = config["bundleIdentifier"]
    widget = config.get("widget")
    has_home_shot = any(shot.get("surface") == "home-screen" for shot in config["shots"])
    if has_home_shot and not widget:
        raise SystemExit("A home-screen shot requires widget configuration")

    started = time.time()
    safe_name = re.sub(r"[^A-Za-z0-9]+", "", config["appName"]) or "App"
    clone_name = f"{safe_name}Shots-{int(started)}"
    udid = simctl("clone", args.source_udid, clone_name)
    print(f"clone      {udid} ({time.time() - started:.1f}s)")

    try:
        simctl("boot", udid)
        simctl("bootstatus", udid, "-b")
        simctl("uninstall", udid, bundle_id, check=False)
        simctl("install", udid, str(app_path))
        stage_fixtures(udid, bundle_id, fixture_path, fixture_destination)
        if screenshot.get("removeTestRunners", True):
            remove_test_runners(udid)
        simctl("launch", udid, bundle_id, *launch_arguments)
        time.sleep(settle)

        group_path = None
        if widget and widget.get("appGroupIdentifier"):
            group_path = app_group_dir(
                udid, bundle_id, widget["appGroupIdentifier"]
            )
        print(f"seeded     ({time.time() - started:.1f}s)")

        if widget:
            simctl("shutdown", udid)
            wait_for_state(udid, "Shutdown")
            if group_path is not None:
                domain = widget.get("preferenceDomain", widget["appGroupIdentifier"])
                stage_app_group_preferences(
                    group_path, domain, widget.get("preferenceOverrides", {})
                )
            place_widgets(udid, bundle_id, widget)
            print(f"staged     ({time.time() - started:.1f}s)")
            simctl("boot", udid)
            simctl("bootstatus", udid, "-b")

        run("bash", str(SCRIPTS / "prepare_simulator.sh"), udid)
        if landscape:
            rotate_to_landscape(udid, clone_name)
        time.sleep(float(config.get("presentation", {}).get("postBootSettleSeconds", 6)))

        for shot in config["shots"]:
            slug = shot["slug"]
            destination = raw_dir / f"{slug}.png"
            simctl("terminate", udid, bundle_id, check=False)
            if shot.get("surface", "app") == "home-screen":
                time.sleep(float(shot.get("settleSeconds", 8)))
            else:
                shot_arguments = list(launch_arguments)
                route = shot.get("route")
                if route is not None:
                    if not route_argument:
                        raise SystemExit(f"{slug} has a route but routeArgument is unset")
                    shot_arguments.extend([route_argument, str(route)])
                simctl("launch", udid, bundle_id, *shot_arguments)
                time.sleep(float(shot.get("settleSeconds", settle)))
            capture_settled(udid, destination)
            if landscape:
                upright_landscape(destination)
            print(f"captured   {slug} ({time.time() - started:.1f}s)")
    finally:
        if not args.keep:
            simctl("shutdown", udid, check=False)
            simctl("delete", udid, check=False)

    print(f"done in {time.time() - started:.1f}s -> {raw_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
