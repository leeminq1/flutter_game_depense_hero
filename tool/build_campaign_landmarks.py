#!/usr/bin/env python3
"""Normalize generated campaign landmarks into deterministic game sprites."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "docs" / "generated" / "campaign-landmarks"
OUTPUT_DIR = (
    ROOT / "assets" / "sprites" / "campaign" / "environment" / "landmarks"
)
LANDMARKS = (
    "watch_post",
    "checkpoint_tower",
    "bandit_stockade",
    "cemetery_statue",
    "mausoleum_gate",
    "ritual_arch",
    "cursed_chapel_front",
    "gate_ruin",
    "bastion_wall_chunk",
    "infernal_gate",
    "throne_road_monument",
)
CANVAS_SIZE = 256
SIDE_MARGIN = 12
TOP_MARGIN = 10
BOTTOM_MARGIN = 12


def _normalized_sprite(source_path: Path) -> Image.Image:
    source = Image.open(source_path).convert("RGBA")
    bounds = source.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels in {source_path}")

    cropped = source.crop(bounds)
    max_width = CANVAS_SIZE - (SIDE_MARGIN * 2)
    max_height = CANVAS_SIZE - TOP_MARGIN - BOTTOM_MARGIN
    scale = min(max_width / cropped.width, max_height / cropped.height)
    width = max(1, round(cropped.width * scale))
    height = max(1, round(cropped.height * scale))
    resized = cropped.resize((width, height), Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    left = (CANVAS_SIZE - width) // 2
    top = CANVAS_SIZE - BOTTOM_MARGIN - height
    canvas.alpha_composite(resized, (left, top))

    alpha = canvas.getchannel("A")
    final_bounds = alpha.getbbox()
    if final_bounds is None:
        raise ValueError(f"Normalized sprite is empty for {source_path}")
    if any(alpha.getpixel(point) != 0 for point in ((0, 0), (255, 0), (0, 255), (255, 255))):
        raise ValueError(f"Transparent corner contract failed for {source_path}")
    if final_bounds[2] - final_bounds[0] < 96 or final_bounds[3] - final_bounds[1] < 64:
        raise ValueError(f"Visible coverage is too small for {source_path}")
    return canvas


def _matches_existing(expected: Image.Image, output_path: Path) -> bool:
    if not output_path.exists():
        return False
    actual = Image.open(output_path).convert("RGBA")
    return actual.size == expected.size and ImageChops.difference(actual, expected).getbbox() is None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify checked-in sprites match the generated alpha sources.",
    )
    args = parser.parse_args()

    if not args.check:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    mismatches: list[str] = []
    for name in LANDMARKS:
        source_path = SOURCE_DIR / f"{name}-alpha.png"
        output_path = OUTPUT_DIR / f"{name}.png"
        expected = _normalized_sprite(source_path)
        if args.check:
            if not _matches_existing(expected, output_path):
                mismatches.append(name)
            continue
        expected.save(output_path, format="PNG", optimize=True)
        print(f"Wrote {output_path.relative_to(ROOT)}")

    if mismatches:
        raise SystemExit("Out-of-date landmark assets: " + ", ".join(mismatches))
    if args.check:
        print(f"Verified {len(LANDMARKS)} campaign landmark assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
