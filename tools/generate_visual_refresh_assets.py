from __future__ import annotations

import subprocess
from pathlib import Path
from random import Random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]


def rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


OUTLINE = rgba("#17120F")
SHADOW = rgba("#000000", 72)
STONE = rgba("#8E98A5")
STONE_DARK = rgba("#4F5965")
STONE_LIGHT = rgba("#CCD5DF")
WOOD = rgba("#906036")
WOOD_DARK = rgba("#51341F")
WOOD_LIGHT = rgba("#C58B50")
IRON = rgba("#77818E")
IRON_DARK = rgba("#404852")
GOLD = rgba("#D9A73E")
GOLD_LIGHT = rgba("#FFE17C")
RED = rgba("#B54E3E")
RED_LIGHT = rgba("#FF796C")
BLUE = rgba("#6EA9F3")
ICE = rgba("#DFFAFF")
PURPLE = rgba("#8D72FF")
FIRE = rgba("#FFB545")
EMBER = rgba("#F26A35")


def run_existing_generators() -> None:
    for script in (
        "generate_tower_sprites.py",
        "generate_barracks_defender_sprites.py",
        "generate_environment_props.py",
        "generate_environment_landmarks.py",
    ):
        subprocess.run(["python", str(ROOT / "tools" / script)], check=True)


def polish_image(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    alpha = img.getchannel("A")
    if alpha.getbbox() is None:
        return

    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    body.alpha_composite(img)
    body = ImageEnhance.Color(body).enhance(1.10)
    body = ImageEnhance.Contrast(body).enhance(1.08)
    body = body.filter(ImageFilter.UnsharpMask(radius=0.8, percent=130, threshold=3))

    rng = Random(path.as_posix())
    texture = Image.new("RGBA", img.size, (0, 0, 0, 0))
    texture_pixels = texture.load()
    alpha_pixels = alpha.load()
    for y in range(img.height):
        for x in range(img.width):
            if alpha_pixels[x, y] == 0:
                continue
            jitter = rng.randint(-16, 18)
            if jitter >= 0:
                texture_pixels[x, y] = (255, 238, 190, min(28, jitter + 4))
            else:
                texture_pixels[x, y] = (24, 18, 14, min(24, abs(jitter) + 3))
    texture = texture.filter(ImageFilter.GaussianBlur(0.45))

    outline_mask = alpha.filter(ImageFilter.MaxFilter(5))
    outline_mask = ImageChops.subtract(outline_mask, alpha)
    outline = Image.new("RGBA", img.size, OUTLINE)
    outline.putalpha(outline_mask.point(lambda value: min(185, value)))

    shadow_mask = alpha.filter(ImageFilter.GaussianBlur(1.4))
    shadow = Image.new("RGBA", img.size, SHADOW)
    shadow.putalpha(shadow_mask.point(lambda value: int(value * 0.42)))
    shifted_shadow = ImageChops.offset(shadow, 0, 2)

    highlight = Image.new("RGBA", img.size, (255, 245, 205, 0))
    highlight_alpha = ImageChops.offset(alpha, -1, -2).filter(ImageFilter.GaussianBlur(0.8))
    highlight.putalpha(highlight_alpha.point(lambda value: int(value * 0.16)))
    rim = Image.new("RGBA", img.size, (178, 216, 255, 0))
    rim_alpha = ImageChops.offset(alpha, 1, -1).filter(ImageFilter.GaussianBlur(0.55))
    rim.putalpha(rim_alpha.point(lambda value: int(value * 0.08)))

    result = Image.new("RGBA", img.size, (0, 0, 0, 0))
    result.alpha_composite(shifted_shadow)
    result.alpha_composite(outline)
    result.alpha_composite(body)
    result.alpha_composite(texture)
    result.alpha_composite(highlight)
    result.alpha_composite(rim)
    result.save(path)


def canvas(size: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rect(draw: ImageDraw.ImageDraw, box, fill, outline=OUTLINE) -> None:
    draw.rounded_rectangle(box, radius=3, fill=fill, outline=outline, width=1)


def poly(draw: ImageDraw.ImageDraw, points, fill, outline=OUTLINE) -> None:
    draw.polygon(points, fill=fill, outline=outline)


def line(draw: ImageDraw.ImageDraw, coords, fill, width=1) -> None:
    draw.line(coords, fill=fill, width=width)


def save_barriers() -> None:
    out_dir = ROOT / "assets" / "sprites" / "barriers"
    out_dir.mkdir(parents=True, exist_ok=True)

    specs = {
        "wood_fence.png": ("wood", WOOD_LIGHT),
        "stone_wall.png": ("stone", STONE),
        "reinforced_wall.png": ("reinforced", STONE_LIGHT),
        "fortress_wall.png": ("fortress", STONE_DARK),
    }
    for filename, (kind, base) in specs.items():
        img, d = canvas(64)
        d.ellipse((10, 50, 54, 59), fill=SHADOW)
        if kind == "wood":
            for x in (17, 27, 37):
                poly(d, [(x, 18), (x + 5, 10), (x + 10, 18), (x + 10, 50), (x, 50)], WOOD_LIGHT)
            rect(d, (13, 28, 51, 34), WOOD, WOOD_DARK)
            rect(d, (13, 40, 51, 46), WOOD, WOOD_DARK)
        elif kind == "stone":
            rect(d, (12, 22, 52, 50), base, STONE_DARK)
            for y in (22, 31, 40):
                line(d, (14, y, 50, y), STONE_DARK, 1)
            for x in (23, 36, 47):
                line(d, (x, 23, x, 49), STONE_DARK, 1)
            rect(d, (18, 16, 30, 24), STONE_LIGHT, STONE_DARK)
            rect(d, (34, 16, 46, 24), STONE_LIGHT, STONE_DARK)
        elif kind == "reinforced":
            rect(d, (10, 20, 54, 51), base, STONE_DARK)
            rect(d, (14, 15, 24, 23), STONE_LIGHT, STONE_DARK)
            rect(d, (28, 15, 38, 23), STONE_LIGHT, STONE_DARK)
            rect(d, (42, 15, 52, 23), STONE_LIGHT, STONE_DARK)
            line(d, (14, 32, 50, 32), IRON_DARK, 3)
            line(d, (18, 43, 46, 43), IRON_DARK, 3)
            for x in (18, 32, 46):
                d.ellipse((x - 3, 29, x + 3, 35), fill=GOLD, outline=OUTLINE)
        else:
            rect(d, (8, 18, 56, 52), base, OUTLINE)
            for x in (10, 22, 34, 46):
                rect(d, (x, 10, x + 9, 22), STONE_LIGHT, STONE_DARK)
            rect(d, (15, 31, 49, 52), IRON_DARK, OUTLINE)
            line(d, (20, 35, 44, 35), GOLD_LIGHT, 2)
            line(d, (20, 43, 44, 43), GOLD_LIGHT, 2)
        img.save(out_dir / filename)
        polish_image(out_dir / filename)


def save_effects() -> None:
    out_dir = ROOT / "assets" / "sprites" / "effects"
    out_dir.mkdir(parents=True, exist_ok=True)

    projectiles = {
        "arrow_projectile.png": (rgba("#F8E8A6"), rgba("#7D5C2E")),
        "siege_bolt_projectile.png": (rgba("#D8DDE3"), rgba("#5B4632")),
        "arcane_bolt_projectile.png": (rgba("#D4C3FF"), PURPLE),
    }
    for filename, (tip, body) in projectiles.items():
        img = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.line((7, 8, 51, 8), fill=body, width=4)
        poly(d, [(52, 3), (62, 8), (52, 13)], tip, body)
        d.line((8, 6, 3, 3), fill=tip, width=2)
        d.line((8, 10, 3, 13), fill=tip, width=2)
        img.save(out_dir / filename)
        polish_image(out_dir / filename)

    impacts = {
        "frost_impact.png": (ICE, BLUE),
        "flame_impact.png": (FIRE, EMBER),
    }
    for filename, (core, accent) in impacts.items():
        img, d = canvas(64)
        for radius, alpha in ((24, 80), (18, 120), (10, 180)):
            d.ellipse(
                (32 - radius, 32 - radius, 32 + radius, 32 + radius),
                outline=accent[:3] + (alpha,),
                width=3,
            )
        for angle in range(0, 360, 45):
            import math

            x = 32 + math.cos(math.radians(angle)) * 24
            y = 32 + math.sin(math.radians(angle)) * 24
            line(d, (32, 32, x, y), core, 2)
        d.ellipse((25, 25, 39, 39), fill=core, outline=accent)
        img.save(out_dir / filename)
        polish_image(out_dir / filename)


def polish_runtime_assets() -> None:
    targets = [
        ROOT / "assets" / "sprites" / "towers",
        ROOT / "assets" / "sprites" / "defenders",
        ROOT / "assets" / "sprites" / "environment" / "props",
        ROOT / "assets" / "sprites" / "environment" / "landmarks",
    ]
    for folder in targets:
        for path in folder.glob("*.png"):
            if path.name == "central_citadel.png":
                continue
            polish_image(path)


def main() -> None:
    run_existing_generators()
    polish_runtime_assets()
    save_barriers()
    save_effects()


if __name__ == "__main__":
    main()
