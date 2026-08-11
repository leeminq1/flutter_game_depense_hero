#!/usr/bin/env python3
"""Export registered bombardment animation strips from the generated atlas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/generated/campaign-bombardment-source-alpha.png"
SHELL_OUTPUT = ROOT / "assets/sprites/effects/bombardment_shell_strip.png"
IMPACT_OUTPUT = ROOT / "assets/sprites/effects/bombardment_impact_strip.png"
FRAME_SIZE = 96
CONTENT_SIZE = 88


def _cell(source: Image.Image, column: int, row: int) -> Image.Image:
    left = round(column * source.width / 6) + 4
    right = round((column + 1) * source.width / 6) - 4
    top = round(row * source.height / 2) + 4
    bottom = round((row + 1) * source.height / 2) - 4
    return source.crop((left, top, right, bottom))


def _registered_frames(cells: list[Image.Image]) -> list[Image.Image]:
    boxes = []
    for index, cell in enumerate(cells):
        box = cell.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"Frame {index} contains no visible pixels")
        boxes.append(box)

    union = (
        min(box[0] for box in boxes),
        min(box[1] for box in boxes),
        max(box[2] for box in boxes),
        max(box[3] for box in boxes),
    )
    width = union[2] - union[0]
    height = union[3] - union[1]
    scale = CONTENT_SIZE / max(width, height)
    target_width = max(1, round(width * scale))
    target_height = max(1, round(height * scale))

    frames = []
    for cell in cells:
        registered = cell.crop(union).resize(
            (target_width, target_height),
            Image.Resampling.NEAREST,
        )
        frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        frame.alpha_composite(
            registered,
            ((FRAME_SIZE - target_width) // 2, (FRAME_SIZE - target_height) // 2),
        )
        frames.append(frame)
    return frames


def _strip(frames: list[Image.Image]) -> Image.Image:
    atlas = Image.new(
        "RGBA",
        (FRAME_SIZE * len(frames), FRAME_SIZE),
        (0, 0, 0, 0),
    )
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * FRAME_SIZE, 0))
    return atlas


def _validate(atlas: Image.Image, frame_count: int, name: str) -> None:
    expected_size = (FRAME_SIZE * frame_count, FRAME_SIZE)
    if atlas.mode != "RGBA" or atlas.size != expected_size:
        raise ValueError(f"{name}: expected RGBA {expected_size}, got {atlas.mode} {atlas.size}")
    for index in range(frame_count):
        frame = atlas.crop(
            (index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE)
        )
        if frame.getchannel("A").getbbox() is None:
            raise ValueError(f"{name}: frame {index} is empty")
        for point in ((0, 0), (FRAME_SIZE - 1, 0), (0, FRAME_SIZE - 1), (FRAME_SIZE - 1, FRAME_SIZE - 1)):
            if frame.getpixel(point)[3] != 0:
                raise ValueError(f"{name}: frame {index} corner {point} is opaque")


def build(*, check_only: bool) -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source = Image.open(SOURCE).convert("RGBA")
    shell = _strip(_registered_frames([_cell(source, column, 0) for column in range(4)]))
    impact = _strip(_registered_frames([_cell(source, column, 1) for column in range(6)]))
    _validate(shell, 4, "shell")
    _validate(impact, 6, "impact")

    outputs = {SHELL_OUTPUT: shell, IMPACT_OUTPUT: impact}
    if check_only:
        for path, expected in outputs.items():
            if not path.exists():
                raise FileNotFoundError(path)
            actual = Image.open(path).convert("RGBA")
            if actual.tobytes() != expected.tobytes():
                raise ValueError(f"{path} is not reproducible from the current source")
        print("Validated deterministic bombardment animation strips")
        return

    for path, image in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, optimize=True)
    print(f"Wrote {SHELL_OUTPUT}")
    print(f"Wrote {IMPACT_OUTPUT}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    build(check_only=args.check)


if __name__ == "__main__":
    main()
