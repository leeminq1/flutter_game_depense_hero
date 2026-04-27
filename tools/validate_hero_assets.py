#!/usr/bin/env python3
"""Validate directional hero sprite assets for runtime readability."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
HERO_DIR = ROOT / "assets" / "sprites" / "heroes"
HERO_IDS = ["knight", "archer", "mage", "ninja", "paladin"]
DIRECTIONS = ["north", "west", "south"]
FRAMES = ["base", "walk_02", "walk_03"]


def is_skin_pixel(r: int, g: int, b: int, a: int) -> bool:
    return (
        a > 32
        and r >= 150
        and 75 <= g <= 205
        and 55 <= b <= 175
        and r > g + 18
        and g > b + 8
    )


def is_equipment_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a <= 32:
        return False
    gold = r >= 150 and g >= 95 and b <= 95
    steel = abs(r - g) <= 26 and abs(g - b) <= 34 and 70 <= r <= 210
    robe = r >= 95 and b <= 100 and g <= 95
    leather = 70 <= r <= 165 and 35 <= g <= 115 and b <= 90
    cloth = b >= 120 and r <= 150
    return gold or steel or robe or leather or cloth


def frame_stats(path: Path) -> tuple[tuple[int, int, int, int], int, int, int]:
    image = Image.open(path).convert("RGBA")
    if image.size != (64, 64):
        raise ValueError(f"{path} is {image.size}, expected 64x64")
    pixels = image.load()
    xs: list[int] = []
    ys: list[int] = []
    opaque = skin = equipment = 0
    for y in range(64):
        for x in range(64):
            r, g, b, a = pixels[x, y]
            if a <= 0:
                continue
            xs.append(x)
            ys.append(y)
            if a > 32:
                opaque += 1
            if is_skin_pixel(r, g, b, a):
                skin += 1
            if is_equipment_pixel(r, g, b, a):
                equipment += 1
    if not xs:
        raise ValueError(f"{path} is blank")
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1), opaque, skin, equipment


def validate_hero(hero_id: str) -> list[str]:
    issues: list[str] = []
    hero_path = HERO_DIR / hero_id
    for direction in DIRECTIONS:
        for frame in FRAMES:
            path = hero_path / direction / f"{frame}.png"
            if not path.exists():
                issues.append(f"missing {path.relative_to(ROOT)}")
                continue
            try:
                bbox, opaque, _skin, _equipment = frame_stats(path)
            except ValueError as exc:
                issues.append(str(exc))
                continue
            width = bbox[2] - bbox[0]
            height = bbox[3] - bbox[1]
            if opaque < 120 or width < 12 or height < 18:
                issues.append(
                    f"{path.relative_to(ROOT)} has weak silhouette "
                    f"bbox={bbox} opaque={opaque}"
                )

    south = hero_path / "south" / "base.png"
    if south.exists():
        _bbox, _opaque, skin, equipment = frame_stats(south)
        if skin < 18:
            issues.append(f"{south.relative_to(ROOT)} has too little visible skin/face: {skin}")
        if equipment < 45:
            issues.append(
                f"{south.relative_to(ROOT)} has too little equipment/robe read: {equipment}"
            )

    meta_path = hero_path / "metadata.json"
    if not meta_path.exists():
        issues.append(f"missing {meta_path.relative_to(ROOT)}")
    else:
        try:
            metadata = json.loads(meta_path.read_text(encoding="utf-8"))
            if "repair" not in metadata:
                issues.append(f"{meta_path.relative_to(ROOT)} missing repair record")
        except json.JSONDecodeError as exc:
            issues.append(f"{meta_path.relative_to(ROOT)} invalid JSON: {exc}")

    if not (hero_path / "credits.txt").exists():
        issues.append(f"missing {(hero_path / 'credits.txt').relative_to(ROOT)}")
    return issues


def main() -> int:
    total = 0
    for hero_id in HERO_IDS:
        issues = validate_hero(hero_id)
        if issues:
            total += len(issues)
            print(f"[FAIL] {hero_id}")
            for issue in issues:
                print(f"  {issue}")
        else:
            print(f"[ OK ] {hero_id}")
    if total:
        print(f"\nFound {total} hero asset issue(s).")
        return 1
    print("\nAll hero assets passed validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
