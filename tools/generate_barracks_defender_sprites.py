from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "defenders"
SIZE = 48


def rgba(hex_value: str, alpha: int = 255):
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


OUTLINE = rgba("#221812")
SHADOW = rgba("#000000", 70)
SKIN = rgba("#E2C19B")
STEEL = rgba("#8F96A2")
STEEL_DARK = rgba("#59606A")
STEEL_LIGHT = rgba("#C5CCD5")
LEATHER = rgba("#8C6037")
LEATHER_DARK = rgba("#5C3C24")
TAN = rgba("#C49B69")
RED = rgba("#B24F32")
RED_LIGHT = rgba("#ED9A63")
CREAM = rgba("#F2E6C7")
WOOD = rgba("#8E6034")
WOOD_DARK = rgba("#5D3D21")
GOLD = rgba("#D9A73E")


def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def shadow(draw, box):
    draw.ellipse(box, fill=SHADOW)


def rect(draw, box, fill, outline=OUTLINE):
    draw.rectangle(box, fill=fill, outline=outline)


def poly(draw, points, fill, outline=OUTLINE):
    draw.polygon(points, fill=fill, outline=outline)


def line(draw, coords, fill, width=1):
    draw.line(coords, fill=fill, width=width)


def defender_body(draw, *, armored=False, bulky=False):
    shadow(draw, (11, 40, 37, 46))
    rect(draw, (19, 8, 29, 16), SKIN, OUTLINE)
    rect(draw, (16, 16, 32, 28), STEEL if armored else TAN, STEEL_DARK if armored else LEATHER_DARK)
    rect(draw, (18, 28, 24, 39), TAN, LEATHER_DARK)
    rect(draw, (24, 28, 30, 39), TAN, LEATHER_DARK)
    rect(draw, (12, 18, 16, 31), STEEL if armored else TAN, STEEL_DARK if armored else LEATHER_DARK)
    rect(draw, (32, 18, 36, 31), STEEL if armored else TAN, STEEL_DARK if armored else LEATHER_DARK)
    if bulky:
      rect(draw, (15, 15, 33, 18), STEEL_DARK, OUTLINE)
      rect(draw, (14, 18, 18, 26), STEEL, STEEL_DARK)
      rect(draw, (30, 18, 34, 26), STEEL, STEEL_DARK)


def helmet(draw, *, plume=False):
    rect(draw, (17, 6, 31, 11), STEEL, STEEL_DARK)
    rect(draw, (18, 11, 30, 15), STEEL_LIGHT, STEEL_DARK)
    if plume:
        poly(draw, [(22, 5), (24, 1), (26, 5)], RED_LIGHT)


def shield(draw, *, heavy=False, elite=False):
    points = [(7, 18), (15, 16), (19, 21), (17, 33), (11, 38), (6, 33)]
    fill = RED if heavy else LEATHER
    poly(draw, points, fill, WOOD_DARK)
    if elite:
        line(draw, (11, 18, 11, 34), fill=GOLD, width=1)
        line(draw, (8, 24, 14, 24), fill=GOLD, width=1)


def spear(draw, *, long=False):
    top_y = 2 if long else 8
    line(draw, (35, 14, 35, 39), fill=WOOD_DARK, width=2)
    poly(draw, [(35, top_y), (39, top_y + 6), (35, top_y + 11), (31, top_y + 6)], STEEL_LIGHT)


def halberd(draw):
    line(draw, (35, 4, 35, 39), fill=WOOD_DARK, width=2)
    poly(draw, [(35, 4), (41, 10), (35, 13), (35, 9), (28, 11), (28, 8), (35, 7)], STEEL_LIGHT)


def base_defender(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    defender_body(d, armored=tier >= 2)
    helmet(d, plume=tier >= 3)
    shield(d, heavy=tier >= 2, elite=tier >= 3)
    spear(d, long=tier >= 2)
    if tier >= 3:
        rect(d, (14, 16, 18, 27), STEEL, STEEL_DARK)
        rect(d, (30, 16, 34, 27), STEEL, STEEL_DARK)
    return img


def vanguard_defender(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    defender_body(d, armored=True, bulky=True)
    helmet(d, plume=tier >= 3)
    poly(d, [(6, 17), (17, 15), (22, 21), (20, 35), (12, 40), (5, 35)], RED, WOOD_DARK)
    line(d, (12, 18, 12, 35), fill=CREAM, width=1)
    line(d, (9, 24, 15, 24), fill=CREAM, width=1)
    spear(d, long=tier >= 3)
    rect(d, (14, 15, 18, 30), STEEL_DARK, OUTLINE)
    rect(d, (30, 15, 34, 30), STEEL_DARK, OUTLINE)
    if tier >= 3:
        rect(d, (15, 12, 33, 15), STEEL_LIGHT, STEEL_DARK)
    return img


def sentinel_defender(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    defender_body(d, armored=True)
    helmet(d, plume=tier >= 3)
    rect(d, (9, 20, 13, 31), STEEL, STEEL_DARK)
    rect(d, (32, 20, 36, 31), STEEL, STEEL_DARK)
    halberd(d)
    poly(d, [(7, 19), (13, 16), (16, 22), (12, 30), (6, 27)], LEATHER, WOOD_DARK)
    if tier >= 2:
        line(d, (35, 14, 42, 18), fill=RED, width=2)
    if tier >= 3:
        rect(d, (16, 14, 32, 17), STEEL_LIGHT, STEEL_DARK)
    return img


def save_image(name, image):
    image.save(OUT_DIR / name)
    print(f"saved {name}")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for tier in (1, 2, 3):
        save_image(f"barracks_defender_t{tier}.png", base_defender(tier))
    for tier in (2, 3):
        save_image(f"barracks_defender_vanguard_t{tier}.png", vanguard_defender(tier))
        save_image(f"barracks_defender_sentinel_t{tier}.png", sentinel_defender(tier))


if __name__ == "__main__":
    main()
