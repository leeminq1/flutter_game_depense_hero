#!/usr/bin/env python3
"""Extracts the generated Stage 1 sprite sheets into deterministic RGBA assets."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


MAGENTA = (255, 0, 255)


@dataclass(frozen=True)
class Export:
    path: str
    column: int
    row: int
    width: int
    height: int
    fill: float = 0.9


STRUCTURE_EXPORTS = (
    Export("towers/archer.png", 0, 0, 128, 160),
    Export("towers/guard_barracks.png", 1, 0, 128, 160),
    Export("towers/mage_obelisk.png", 2, 0, 128, 160),
    Export("towers/frost_shrine.png", 0, 1, 128, 160),
    Export("towers/coin_mill.png", 1, 1, 128, 160),
    Export("towers/ballista.png", 2, 1, 128, 160),
    Export("towers/ember_keep.png", 0, 2, 128, 160),
    Export("environment/tutorial_citadel.png", 1, 2, 224, 224, 0.94),
    Export("environment/supply_cart.png", 2, 2, 128, 128, 0.9),
)


MODULE_EXPORTS = (
    Export("tiles/grass_base.png", 0, 0, 64, 64, 1.0),
    Export("tiles/grass_alt.png", 1, 0, 64, 64, 1.0),
    Export("tiles/road_straight.png", 2, 0, 64, 64, 1.0),
    Export("tiles/road_corner.png", 3, 0, 64, 64, 1.0),
    Export("tiles/road_cap.png", 0, 1, 64, 64, 1.0),
    Export("tiles/road_fill.png", 1, 1, 64, 64, 1.0),
    Export("walls/wood/isolated.png", 2, 1, 64, 64),
    Export("walls/wood/straight.png", 3, 1, 64, 64),
    Export("walls/wood/corner.png", 0, 2, 64, 64),
    Export("walls/stone/isolated.png", 1, 2, 64, 64),
    Export("walls/stone/straight.png", 2, 2, 64, 64),
    Export("walls/stone/corner.png", 3, 2, 64, 64),
    Export("walls/fortress/isolated.png", 0, 3, 64, 64),
    Export("walls/fortress/straight.png", 1, 3, 64, 64),
    Export("walls/fortress/corner.png", 2, 3, 64, 64),
    Export("walls/keep/straight.png", 3, 3, 64, 64),
)


PROP_EXPORTS = (
    Export("environment/village_gatehouse.png", 0, 0, 256, 256, 0.94),
    Export("environment/road_signpost.png", 1, 0, 112, 144, 0.90),
    Export("environment/well.png", 0, 1, 160, 160, 0.92),
    Export("environment/broken_supply_wagon.png", 1, 1, 192, 160, 0.92),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet-a", required=True, type=Path)
    parser.add_argument("--sheet-b", required=True, type=Path)
    parser.add_argument("--sheet-c", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    return parser.parse_args()


def remove_magenta(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, _ = pixels[x, y]
            distance = abs(red - MAGENTA[0]) + green + abs(blue - MAGENTA[2])
            if distance <= 18:
                alpha = 0
            elif distance <= 80:
                alpha = round(255 * (distance - 18) / 62)
            else:
                alpha = 255
            if alpha < 255:
                pixels[x, y] = (red, green, blue, alpha)
    return rgba


def extract_cell(sheet: Image.Image, export: Export, columns: int, rows: int) -> Image.Image:
    cell_width = sheet.width / columns
    cell_height = sheet.height / rows
    left = round(export.column * cell_width)
    top = round(export.row * cell_height)
    right = round((export.column + 1) * cell_width)
    bottom = round((export.row + 1) * cell_height)
    crop = sheet.crop((left, top, right, bottom))
    keyed = crop.convert("RGBA") if sheet.mode == "RGBA" else remove_magenta(crop)
    alpha_box = keyed.getchannel("A").getbbox()
    if alpha_box is None:
        raise RuntimeError(f"empty generated cell at ({export.column}, {export.row})")
    return keyed.crop(alpha_box)


def fit_to_canvas(sprite: Image.Image, export: Export) -> Image.Image:
    max_width = max(1, round(export.width * export.fill))
    max_height = max(1, round(export.height * export.fill))
    scale = min(max_width / sprite.width, max_height / sprite.height)
    target = (
        max(1, round(sprite.width * scale)),
        max(1, round(sprite.height * scale)),
    )
    resized = sprite.resize(target, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (export.width, export.height), (0, 0, 0, 0))
    x = (export.width - resized.width) // 2
    y = min(export.height - resized.height, round(export.height * 0.94) - resized.height)
    canvas.alpha_composite(resized, (x, max(0, y)))
    return canvas


def export_sheet(
    sheet_path: Path,
    exports: tuple[Export, ...],
    columns: int,
    rows: int,
    output_root: Path,
) -> None:
    sheet = Image.open(sheet_path)
    for export in exports:
        sprite = extract_cell(sheet, export, columns, rows)
        output = fit_to_canvas(sprite, export)
        target = output_root / export.path
        target.parent.mkdir(parents=True, exist_ok=True)
        output.save(target, "PNG", optimize=True)
        if output.getpixel((0, 0))[3] != 0:
            raise RuntimeError(f"top-left corner is not transparent: {target}")


def main() -> None:
    args = parse_args()
    export_sheet(args.sheet_a, STRUCTURE_EXPORTS, 3, 3, args.output_root)
    export_sheet(args.sheet_b, MODULE_EXPORTS, 4, 4, args.output_root)
    export_sheet(args.sheet_c, PROP_EXPORTS, 2, 2, args.output_root)
    expected = {
        item.path
        for item in (*STRUCTURE_EXPORTS, *MODULE_EXPORTS, *PROP_EXPORTS)
    }
    missing = [path for path in expected if not (args.output_root / path).is_file()]
    if missing:
        raise RuntimeError(f"missing required exports: {missing}")
    print(f"exported {len(expected)} Stage 1 sprites to {args.output_root}")


if __name__ == "__main__":
    main()
