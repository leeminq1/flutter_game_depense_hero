"""
Normalize the four outlier environment sprites that were imported at 1024x1024.

The rest of the environment set uses compact game-sized PNGs:
- landmarks: 96x96
- props: 64x64

These targeted fixes keep the existing art, but resize the assets to the same
runtime-friendly footprint and apply circular masking where the original source
included a square backdrop.
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

BASE = Path(__file__).resolve().parent

TARGET_SPECS = {
    "assets/sprites/environment/landmarks/central_citadel.png": {
        "size": 96,
        "circle_mask_ratio": None,
    },
    "assets/sprites/environment/props/breach_front_marker.png": {
        "size": 64,
        "circle_mask_ratio": 0.47,
    },
    "assets/sprites/environment/props/supply_node_idle.png": {
        "size": 64,
        "circle_mask_ratio": 0.42,
    },
    "assets/sprites/environment/props/supply_node_occupied.png": {
        "size": 64,
        "circle_mask_ratio": 0.42,
    },
}


def apply_circle_mask(image: Image.Image, radius_ratio: float) -> Image.Image:
    image = image.copy().convert("RGBA")
    width, height = image.size
    radius = min(width, height) * radius_ratio
    center_x = width / 2
    center_y = height / 2

    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse(
        (
            center_x - radius,
            center_y - radius,
            center_x + radius,
            center_y + radius,
        ),
        fill=255,
    )
    image.putalpha(ImageChops.multiply(image.getchannel("A"), mask))
    return image


def fit_into_square(image: Image.Image, size: int, padding: int = 4) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox is not None:
        image = image.crop(bbox)

    inner = max(1, size - (padding * 2))
    scale = min(inner / image.width, inner / image.height)
    resized = image.resize(
        (
            max(1, round(image.width * scale)),
            max(1, round(image.height * scale)),
        ),
        Image.Resampling.LANCZOS,
    )

    output = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    output.alpha_composite(
        resized,
        ((size - resized.width) // 2, (size - resized.height) // 2),
    )
    return output


def normalize_sprite(path: Path, output_size: int, circle_mask_ratio: float | None) -> None:
    image = Image.open(path).convert("RGBA")
    if circle_mask_ratio is not None:
        image = apply_circle_mask(image, circle_mask_ratio)
    image = fit_into_square(image, output_size)
    image.save(path)


def main() -> None:
    for relative_path, spec in TARGET_SPECS.items():
        path = BASE / relative_path
        if not path.exists():
            print(f"Missing: {relative_path}")
            continue
        normalize_sprite(
            path=path,
            output_size=spec["size"],
            circle_mask_ratio=spec["circle_mask_ratio"],
        )
        print(f"Normalized: {relative_path} -> {spec['size']}x{spec['size']}")


if __name__ == "__main__":
    main()
