#!/usr/bin/env python3
"""Portrait smoke-test runner for Citadel Siege (Flutter Web).

Starts a Playwright-CLI session against the running Flutter Web dev server,
captures screenshots at every required viewport, and runs the landscape
orientation guard check.

Prerequisites:
  1. Flutter Web server must already be running:
       flutter run -d web-server --web-port 7357
  2. npx must be available in PATH.

Usage:
  python tools/qa/smoke_test.py [--label LABEL] [--port PORT]

Output:
  output/playwright/<label>/
    phone-360x800.png
    phone-412x915.png
    tablet-768x1024.png
    tablet-834x1194.png
    landscape-915x412.png
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Viewport definitions
# ---------------------------------------------------------------------------

PORTRAIT_VIEWPORTS = [
    {"label": "phone-360x800",   "width": 360,  "height": 800},
    {"label": "phone-412x915",   "width": 412,  "height": 915},
    {"label": "tablet-768x1024", "width": 768,  "height": 1024},
    {"label": "tablet-834x1194", "width": 834,  "height": 1194},
]

LANDSCAPE_VIEWPORT = {"label": "landscape-915x412", "width": 915, "height": 412}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent


def output_dir(label: str) -> Path:
    directory = PROJECT_ROOT / "output" / "playwright" / label
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def run_playwright(*args: str) -> subprocess.CompletedProcess:
    """Run a playwright-cli command via npx and return the result."""
    cmd = [
        "npx", "--yes",
        "--package", "@playwright/cli",
        "playwright-cli",
        *args,
    ]
    return subprocess.run(cmd, capture_output=True, text=True)


def screenshot(out_path: Path, viewport_label: str) -> bool:
    """Capture a screenshot to out_path. Returns True on success."""
    result = run_playwright("screenshot", "--filename", str(out_path))
    if result.returncode != 0:
        print(f"  [ERROR] screenshot failed for {viewport_label}")
        print(result.stderr.strip())
        return False
    print(f"  [OK]    {out_path.relative_to(PROJECT_ROOT)}")
    return True


def resize(width: int, height: int) -> bool:
    """Resize the open browser window. Returns True on success."""
    result = run_playwright("resize", str(width), str(height))
    if result.returncode != 0:
        print(f"  [ERROR] resize to {width}x{height} failed")
        print(result.stderr.strip())
        return False
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--label",
        default=None,
        help="Output sub-folder label (default: YYYY-MM-DDTHHMM)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=7357,
        help="Flutter Web server port (default: 7357)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    from datetime import datetime
    label = args.label or datetime.now().strftime("%Y-%m-%dT%H%M")
    base_url = f"http://127.0.0.1:{args.port}"
    out = output_dir(label)

    print(f"Citadel Siege – portrait smoke test")
    print(f"  URL    : {base_url}")
    print(f"  Output : {out.relative_to(PROJECT_ROOT)}")
    print()

    # Open the app
    print("Opening app in headed browser…")
    open_result = run_playwright("open", base_url, "--headed")
    if open_result.returncode != 0:
        print("[ERROR] Could not open browser. Is the Flutter Web server running?")
        print(open_result.stderr.strip())
        return 1

    # Brief pause to let the app finish loading
    time.sleep(2)

    failures = 0

    # Portrait captures
    print("Capturing portrait viewports…")
    for vp in PORTRAIT_VIEWPORTS:
        if not resize(vp["width"], vp["height"]):
            failures += 1
            continue
        png = out / f"{vp['label']}.png"
        if not screenshot(png, vp["label"]):
            failures += 1

    # Landscape guard check
    print()
    print("Capturing landscape orientation guard…")
    lv = LANDSCAPE_VIEWPORT
    if resize(lv["width"], lv["height"]):
        png = out / f"{lv['label']}.png"
        if not screenshot(png, lv["label"]):
            failures += 1
    else:
        failures += 1

    print()
    if failures == 0:
        print(f"All captures succeeded.  Review screenshots in: output/playwright/{label}/")
        return 0

    print(f"{failures} capture(s) failed. Check the errors above.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
