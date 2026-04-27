#!/usr/bin/env python3
"""Repair LPC hero sprites by merging visible bodies with legacy equipment.

The current hero assets may contain a readable human body but miss armor/robe
layers. The committed legacy assets contain the intended role equipment but can
miss the body/head layers. This tool composites the current body under the
legacy equipment, then restores a small face/skin window so heroes read as
people instead of empty armor.
"""

from __future__ import annotations

import io
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
HERO_DIR = ROOT / "assets" / "sprites" / "heroes"
HERO_IDS = ["knight", "archer", "mage", "ninja", "paladin"]
DIRECTIONS = ["north", "west", "south"]
FRAMES = ["base", "walk_02", "walk_03"]


@dataclass(frozen=True)
class FrameStats:
    bbox: tuple[int, int, int, int]
    opaque_pixels: int
    skin_pixels: int
    equipment_pixels: int


def load_legacy_png(path: Path, ref: str) -> Image.Image:
    rel = path.relative_to(ROOT).as_posix()
    data = subprocess.check_output(["git", "show", f"{ref}:{rel}"], cwd=ROOT)
    return Image.open(io.BytesIO(data)).convert("RGBA")


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


def stats_for(image: Image.Image) -> FrameStats:
    pixels = image.load()
    xs: list[int] = []
    ys: list[int] = []
    opaque = skin = equipment = 0
    for y in range(image.height):
        for x in range(image.width):
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
    bbox = (min(xs), min(ys), max(xs) + 1, max(ys) + 1) if xs else (0, 0, 0, 0)
    return FrameStats(bbox, opaque, skin, equipment)


def restore_face(composite: Image.Image, current: Image.Image, hero_id: str) -> None:
    """Put readable skin/face pixels over helmets and hoods without exposing torsos."""
    pixels_out = composite.load()
    pixels_body = current.load()
    if hero_id in {"knight", "paladin"}:
        window = (22, 14, 43, 34)
    elif hero_id in {"mage", "ninja"}:
        window = (24, 15, 42, 37)
    else:
        window = (20, 13, 45, 38)

    left, top, right, bottom = window
    for y in range(top, bottom):
        for x in range(left, right):
            r, g, b, a = pixels_body[x, y]
            if is_skin_pixel(r, g, b, a):
                pixels_out[x, y] = (r, g, b, a)


def repair_frame(path: Path, ref: str, hero_id: str) -> FrameStats:
    current = Image.open(path).convert("RGBA")
    legacy = load_legacy_png(path, ref)
    composite = Image.alpha_composite(current, legacy)
    restore_face(composite, current, hero_id)
    composite.save(path, "PNG")
    return stats_for(composite)


def write_metadata(hero_id: str, ref: str, frame_stats: dict[str, FrameStats]) -> None:
    meta_path = HERO_DIR / hero_id / "metadata.json"
    try:
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        meta = {"id": hero_id}
    except json.JSONDecodeError:
        meta = {"id": hero_id}

    meta["repair"] = {
        "source": "current body/head composited under legacy LPC equipment",
        "legacyRef": ref,
        "rules": [
            "preserve role equipment from legacy frames",
            "preserve visible human body and face readability",
            "reject fully nude or empty-armor reads",
        ],
        "frameStats": {
            key: {
                "bbox": list(value.bbox),
                "opaquePixels": value.opaque_pixels,
                "skinPixels": value.skin_pixels,
                "equipmentPixels": value.equipment_pixels,
            }
            for key, value in frame_stats.items()
        },
    }
    meta_path.write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")


def main() -> int:
    ref = sys.argv[1] if len(sys.argv) > 1 else "HEAD"
    for hero_id in HERO_IDS:
        frame_stats: dict[str, FrameStats] = {}
        for direction in DIRECTIONS:
            for frame in FRAMES:
                path = HERO_DIR / hero_id / direction / f"{frame}.png"
                if not path.exists():
                    print(f"[FAIL] missing {path.relative_to(ROOT)}", file=sys.stderr)
                    return 1
                key = f"{direction}/{frame}"
                frame_stats[key] = repair_frame(path, ref, hero_id)
        write_metadata(hero_id, ref, frame_stats)
        south = frame_stats["south/base"]
        print(
            f"[OK] {hero_id}: bbox={south.bbox} skin={south.skin_pixels} "
            f"equipment={south.equipment_pixels}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
