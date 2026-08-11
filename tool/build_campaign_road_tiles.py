#!/usr/bin/env python3
"""Build seam-safe campaign road modules from the generated texture source."""

from __future__ import annotations

import argparse
import random
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/generated/campaign-road-modules-source-alpha.png"
OUTPUT_DIR = ROOT / "assets/sprites/campaign/tiles"
SIZE = 64
ROAD_MIN = 20
ROAD_MAX = 43
ROAD_WIDTH = ROAD_MAX - ROAD_MIN + 1

MODULE_MASKS = {
    "road_isolated.png": 0,
    "road_cap.png": 1,
    "road_straight.png": 5,
    "road_corner.png": 3,
    "road_tee.png": 11,
    "road_cross.png": 15,
}


def _components(image: Image.Image) -> list[tuple[int, int, int, int]]:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    visited: set[tuple[int, int]] = set()
    boxes: list[tuple[int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            if pixels[x, y] < 96 or (x, y) in visited:
                continue
            queue = deque([(x, y)])
            visited.add((x, y))
            min_x = max_x = x
            min_y = max_y = y
            count = 0
            while queue:
                current_x, current_y = queue.popleft()
                count += 1
                min_x = min(min_x, current_x)
                max_x = max(max_x, current_x)
                min_y = min(min_y, current_y)
                max_y = max(max_y, current_y)
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if (
                        0 <= next_x < width
                        and 0 <= next_y < height
                        and (next_x, next_y) not in visited
                        and pixels[next_x, next_y] >= 96
                    ):
                        visited.add((next_x, next_y))
                        queue.append((next_x, next_y))
            if count >= 10_000:
                boxes.append((min_x, min_y, max_x + 1, max_y + 1))

    boxes.sort(key=lambda box: (box[1] // max(1, height // 3), box[0]))
    if len(boxes) != 6:
        raise ValueError(f"Expected six source modules, found {len(boxes)}")
    return boxes


def _palette_samples(image: Image.Image) -> tuple[list[tuple[int, int, int, int]], list[tuple[int, int, int, int]]]:
    dirt: list[tuple[int, int, int, int]] = []
    grass: list[tuple[int, int, int, int]] = []
    for red, green, blue, alpha in image.getdata():
        if alpha < 220:
            continue
        if red > green + 12 and red > 105 and blue < 135:
            dirt.append((red, green, blue, 255))
        elif green > red + 18 and green > blue + 25:
            grass.append((red, green, blue, 255))
    if len(dirt) < 500 or len(grass) < 500:
        raise ValueError("Generated road source does not contain enough dirt/grass texture samples")
    return dirt, grass


def _texture(samples: list[tuple[int, int, int, int]], seed: int) -> Image.Image:
    rng = random.Random(seed)
    texture = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pixels = texture.load()
    offset = rng.randrange(len(samples))
    step = 97
    for y in range(SIZE):
        for x in range(SIZE):
            index = (offset + (x * step) + (y * 193) + ((x * y) % 71)) % len(samples)
            pixels[x, y] = samples[index]
    return texture


def _road_mask(connection_mask: int) -> Image.Image:
    mask = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(mask)
    center_min = 18
    center_max = 45
    draw.ellipse((center_min, center_min, center_max, center_max), fill=255)

    if connection_mask & 1:  # north
        draw.rectangle((ROAD_MIN, 0, ROAD_MAX, SIZE // 2), fill=255)
    if connection_mask & 2:  # east
        draw.rectangle((SIZE // 2, ROAD_MIN, SIZE - 1, ROAD_MAX), fill=255)
    if connection_mask & 4:  # south
        draw.rectangle((ROAD_MIN, SIZE // 2, ROAD_MAX, SIZE - 1), fill=255)
    if connection_mask & 8:  # west
        draw.rectangle((0, ROAD_MIN, SIZE // 2, ROAD_MAX), fill=255)
    return mask


def _compose(connection_mask: int, dirt_samples, grass_samples, seed: int) -> Image.Image:
    road_mask = _road_mask(connection_mask)
    outline_mask = road_mask.filter(ImageFilter.MaxFilter(5))
    fringe_mask = road_mask.filter(ImageFilter.MaxFilter(11))

    fringe_only = ImageChops.subtract(fringe_mask, outline_mask)
    outline_only = ImageChops.subtract(outline_mask, road_mask)

    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grass_texture = _texture(grass_samples, seed)
    dirt_texture = _texture(dirt_samples, seed + 1000)
    dark_outline = Image.new("RGBA", (SIZE, SIZE), (61, 70, 29, 255))

    result.alpha_composite(Image.composite(grass_texture, result, fringe_only))
    result.alpha_composite(Image.composite(dark_outline, Image.new("RGBA", result.size), outline_only))
    result.alpha_composite(Image.composite(dirt_texture, Image.new("RGBA", result.size), road_mask))

    # A few deterministic high-contrast pixels preserve the approved hand-made
    # texture without weakening the mathematically exact edge corridors.
    draw = ImageDraw.Draw(result)
    rng = random.Random(seed + 2000)
    for _ in range(14):
        x = rng.randrange(5, SIZE - 5)
        y = rng.randrange(5, SIZE - 5)
        if road_mask.getpixel((x, y)) == 255:
            color = (223, 174, 112, 255) if rng.random() > 0.45 else (106, 70, 43, 255)
            draw.point((x, y), fill=color)
    return result


def _edge_opening(mask: Image.Image, side: int) -> list[int]:
    if side == 1:
        return [x for x in range(SIZE) if mask.getpixel((x, 0))]
    if side == 2:
        return [y for y in range(SIZE) if mask.getpixel((SIZE - 1, y))]
    if side == 4:
        return [x for x in range(SIZE) if mask.getpixel((x, SIZE - 1))]
    return [y for y in range(SIZE) if mask.getpixel((0, y))]


def _validate(outputs: dict[str, Image.Image]) -> None:
    expected_positions = list(range(ROAD_MIN, ROAD_MAX + 1))
    for filename, connection_mask in MODULE_MASKS.items():
        image = outputs[filename]
        if image.mode != "RGBA" or image.size != (SIZE, SIZE):
            raise ValueError(f"{filename}: expected 64x64 RGBA")
        mask = _road_mask(connection_mask)
        for side in (1, 2, 4, 8):
            opening = _edge_opening(mask, side)
            expected = expected_positions if connection_mask & side else []
            if opening != expected:
                raise ValueError(
                    f"{filename}: side {side} opening {opening} does not match {expected}"
                )
        if image.getpixel((0, 0))[3] != 0 or image.getpixel((63, 63))[3] != 0:
            raise ValueError(f"{filename}: corners must remain transparent")


def build(*, check_only: bool) -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source = Image.open(SOURCE).convert("RGBA")
    boxes = _components(source)
    texture_source = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    for box in boxes:
        crop = source.crop(box)
        square_size = max(crop.size)
        square = Image.new("RGBA", (square_size, square_size), (0, 0, 0, 0))
        square.alpha_composite(
            crop,
            ((square_size - crop.width) // 2, (square_size - crop.height) // 2),
        )
        normalized = square.resize((SIZE, SIZE), Image.Resampling.NEAREST)
        texture_source = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        texture_source.alpha_composite(normalized)
        # One well-populated module contains enough of both material palettes.
        dirt, grass = _palette_samples(texture_source)
        if len(dirt) >= 500 and len(grass) >= 500:
            break
    else:
        raise ValueError("No source module contained both road and grass palettes")

    outputs = {
        filename: _compose(mask, dirt, grass, 8110 + index)
        for index, (filename, mask) in enumerate(MODULE_MASKS.items())
    }
    _validate(outputs)

    if check_only:
        for filename, expected in outputs.items():
            path = OUTPUT_DIR / filename
            if not path.exists():
                raise FileNotFoundError(path)
            actual = Image.open(path).convert("RGBA")
            if actual.tobytes() != expected.tobytes():
                raise ValueError(f"{path} is not reproducible from the current source")
        print("Validated six deterministic campaign road modules")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for filename, image in outputs.items():
        image.save(OUTPUT_DIR / filename, optimize=True)
    print(f"Wrote {len(outputs)} road modules to {OUTPUT_DIR}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    build(check_only=args.check)


if __name__ == "__main__":
    main()
