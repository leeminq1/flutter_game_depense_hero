#!/usr/bin/env python3
"""Clean up Playwright screenshot capture folders under output/playwright/.

By default keeps the most recent N runs and deletes older ones.
Can also delete all runs with --all.

Usage:
  python tools/qa/clean_captures.py           # keep 5 most recent runs
  python tools/qa/clean_captures.py --keep 3  # keep 3 most recent runs
  python tools/qa/clean_captures.py --all     # delete everything
  python tools/qa/clean_captures.py --dry-run # preview without deleting
"""

import argparse
import shutil
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
PLAYWRIGHT_DIR = PROJECT_ROOT / "output" / "playwright"

EXPECTED_SCREENSHOTS = [
    "phone-360x800.png",
    "phone-412x915.png",
    "tablet-768x1024.png",
    "tablet-834x1194.png",
    "landscape-915x412.png",
]


def list_runs() -> list[Path]:
    """Return capture run directories sorted oldest-first by name."""
    if not PLAYWRIGHT_DIR.is_dir():
        return []
    return sorted(p for p in PLAYWRIGHT_DIR.iterdir() if p.is_dir())


def report_run(run_dir: Path) -> None:
    """Print a one-line summary of a capture run directory."""
    found = [f for f in EXPECTED_SCREENSHOTS if (run_dir / f).exists()]
    missing = len(EXPECTED_SCREENSHOTS) - len(found)
    total_bytes = sum(
        f.stat().st_size for f in run_dir.rglob("*.png") if f.is_file()
    )
    size_kb = total_bytes // 1024
    status = "complete" if missing == 0 else f"{missing} missing"
    print(f"  {run_dir.name:<22}  {len(found)}/{len(EXPECTED_SCREENSHOTS)} screenshots  {size_kb} KB  [{status}]")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--keep",
        type=int,
        default=5,
        metavar="N",
        help="Number of most-recent runs to keep (default: 5)",
    )
    group.add_argument(
        "--all",
        action="store_true",
        help="Delete all capture runs",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview what would be deleted without actually deleting",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    runs = list_runs()

    if not runs:
        print(f"No capture runs found in: output/playwright/")
        return 0

    print(f"Capture runs in output/playwright/  ({len(runs)} total):")
    for run in runs:
        report_run(run)
    print()

    if args.all:
        to_delete = runs
    else:
        to_keep = args.keep
        to_delete = runs[:-to_keep] if len(runs) > to_keep else []

    if not to_delete:
        print("Nothing to delete.")
        return 0

    verb = "Would delete" if args.dry_run else "Deleting"
    print(f"{verb} {len(to_delete)} run(s):")
    for run in to_delete:
        print(f"  {run.name}")
        if not args.dry_run:
            shutil.rmtree(run)

    if args.dry_run:
        print()
        print("Dry run: no files were deleted. Remove --dry-run to apply.")
    else:
        remaining = len(runs) - len(to_delete)
        print()
        print(f"Done. {remaining} run(s) retained.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
