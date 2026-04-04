from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "environment" / "props"
SIZE = 64


def rgba(hex_value: str, alpha: int = 255):
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


OUTLINE = rgba("#221812")
SHADOW = rgba("#000000", 70)
STONE = rgba("#8E8F93")
STONE_DARK = rgba("#626367")
STONE_LIGHT = rgba("#B6B7BC")
WOOD = rgba("#8E6034")
WOOD_DARK = rgba("#5D3D21")
WOOD_LIGHT = rgba("#B88449")
DIRT = rgba("#6E5742")
MOSS = rgba("#60784B")
BONE = rgba("#D9D2BE")
BONE_DARK = rgba("#A59A82")
RED = rgba("#A84A31")
RED_LIGHT = rgba("#E0915A")
GREEN = rgba("#587441")
ORANGE = rgba("#D17022")
FIRE = rgba("#FFD06A")
PURPLE = rgba("#6A4AAC")
PURPLE_LIGHT = rgba("#C9B7FF")
IRON = rgba("#757C86")
IRON_DARK = rgba("#4D535B")


def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def shadow(draw: ImageDraw.ImageDraw, box):
    draw.ellipse(box, fill=SHADOW)


def rect(draw: ImageDraw.ImageDraw, box, fill, outline=OUTLINE):
    draw.rectangle(box, fill=fill, outline=outline)


def poly(draw: ImageDraw.ImageDraw, points, fill, outline=OUTLINE):
    draw.polygon(points, fill=fill, outline=outline)


def line(draw: ImageDraw.ImageDraw, coords, fill, width=1):
    draw.line(coords, fill=fill, width=width)


def road_signpost():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (18, 54, 48, 61))
    rect(d, (29, 18, 34, 55), WOOD, WOOD_DARK)
    poly(d, [(16, 18), (33, 13), (33, 24), (16, 29)], WOOD_LIGHT)
    poly(d, [(31, 30), (48, 25), (48, 36), (31, 41)], WOOD_LIGHT)
    line(d, (20, 20, 28, 18), fill=WOOD_DARK, width=1)
    line(d, (35, 32, 44, 29), fill=WOOD_DARK, width=1)
    return img


def wooden_fence_segment():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 54, 54, 60))
    for x in (15, 25, 35, 45):
        poly(d, [(x, 24), (x + 4, 17), (x + 8, 24), (x + 8, 52), (x, 52)], WOOD_LIGHT)
    rect(d, (12, 29, 52, 34), WOOD, WOOD_DARK)
    rect(d, (12, 40, 52, 45), WOOD, WOOD_DARK)
    return img


def supply_crate():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (14, 51, 50, 60))
    rect(d, (16, 22, 48, 50), WOOD, WOOD_DARK)
    line(d, (16, 22, 48, 50), fill=WOOD_LIGHT, width=2)
    line(d, (48, 22, 16, 50), fill=WOOD_LIGHT, width=2)
    rect(d, (20, 26, 44, 46), WOOD_LIGHT, WOOD_DARK)
    return img


def wagon_wreck():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 52, 56, 60))
    rect(d, (18, 28, 46, 42), WOOD, WOOD_DARK)
    poly(d, [(15, 24), (30, 16), (49, 24), (44, 28), (20, 28)], WOOD_LIGHT)
    line(d, (20, 42, 14, 50), fill=WOOD_DARK, width=2)
    line(d, (44, 42, 50, 50), fill=WOOD_DARK, width=2)
    d.ellipse((8, 38, 22, 52), outline=WOOD_DARK, width=2)
    d.ellipse((42, 38, 56, 52), outline=WOOD_DARK, width=2)
    line(d, (12, 45, 18, 45), fill=WOOD_DARK, width=2)
    line(d, (46, 45, 52, 45), fill=WOOD_DARK, width=2)
    return img


def grave_marker_tall():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (18, 54, 46, 60))
    rect(d, (24, 18, 40, 53), STONE, STONE_DARK)
    poly(d, [(24, 18), (32, 10), (40, 18)], STONE_LIGHT)
    rect(d, (20, 47, 44, 53), STONE_DARK, OUTLINE)
    line(d, (32, 24, 32, 41), fill=STONE_LIGHT, width=1)
    line(d, (27, 29, 37, 29), fill=STONE_LIGHT, width=1)
    return img


def dead_tree_twisted():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 54, 52, 60))
    line(d, (32, 50, 31, 24), fill=WOOD_DARK, width=5)
    line(d, (31, 30, 20, 18), fill=WOOD_DARK, width=4)
    line(d, (31, 25, 42, 15), fill=WOOD_DARK, width=4)
    line(d, (21, 18, 15, 10), fill=WOOD_DARK, width=3)
    line(d, (42, 15, 50, 8), fill=WOOD_DARK, width=3)
    line(d, (30, 40, 20, 48), fill=WOOD_DARK, width=3)
    line(d, (33, 43, 44, 48), fill=WOOD_DARK, width=3)
    return img


def bone_pile():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 50, 52, 58))
    line(d, (18, 44, 32, 32), fill=BONE, width=5)
    line(d, (20, 33, 42, 46), fill=BONE, width=5)
    line(d, (24, 47, 42, 34), fill=BONE, width=5)
    for cx, cy in ((18, 44), (32, 32), (20, 33), (42, 46), (24, 47), (42, 34)):
        d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=BONE, outline=BONE_DARK)
    return img


def chapel_rubble():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 53, 54, 60))
    rect(d, (14, 38, 46, 50), STONE, STONE_DARK)
    poly(d, [(18, 28), (27, 18), (34, 29), (25, 39)], STONE_LIGHT)
    poly(d, [(34, 29), (42, 21), (50, 36), (39, 42)], STONE)
    poly(d, [(10, 42), (18, 33), (24, 46), (14, 50)], STONE_DARK)
    line(d, (29, 23, 29, 34), fill=STONE_DARK, width=1)
    line(d, (24, 28, 34, 28), fill=STONE_DARK, width=1)
    return img


def ritual_altar():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 52, 52, 60))
    rect(d, (18, 40, 46, 50), STONE_DARK, OUTLINE)
    rect(d, (22, 28, 42, 40), STONE, STONE_DARK)
    poly(d, [(32, 11), (38, 20), (32, 30), (26, 20)], PURPLE, OUTLINE)
    poly(d, [(32, 15), (35, 20), (32, 25), (29, 20)], PURPLE_LIGHT, None)
    line(d, (25, 45, 39, 45), fill=PURPLE_LIGHT, width=1)
    return img


def fort_wall_breach():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 54, 56, 60))
    rect(d, (10, 24, 54, 52), STONE, STONE_DARK)
    for x in range(12, 54, 8):
        rect(d, (x, 18, x + 5, 24), STONE_LIGHT, STONE_DARK)
    poly(d, [(24, 52), (30, 31), (39, 31), (44, 52)], (0, 0, 0, 0), None)
    rect(d, (13, 34, 20, 40), STONE_LIGHT, STONE_DARK)
    rect(d, (44, 31, 51, 38), STONE_LIGHT, STONE_DARK)
    return img


def brazier_large():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 54, 52, 60))
    rect(d, (27, 40, 37, 54), IRON, IRON_DARK)
    poly(d, [(20, 30), (44, 30), (40, 42), (24, 42)], IRON_DARK)
    poly(d, [(32, 10), (40, 24), (35, 25), (40, 36), (32, 29), (24, 36), (29, 25), (24, 24)], ORANGE, OUTLINE)
    poly(d, [(32, 15), (37, 25), (34, 26), (37, 32), (32, 27), (27, 32), (30, 26), (27, 25)], FIRE)
    return img


def chain_post():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 54, 54, 60))
    rect(d, (16, 42, 24, 54), STONE_DARK, OUTLINE)
    rect(d, (40, 42, 48, 54), STONE_DARK, OUTLINE)
    rect(d, (18, 22, 22, 42), IRON, IRON_DARK)
    rect(d, (42, 22, 46, 42), IRON, IRON_DARK)
    for x1, x2, y in ((22, 30, 27), (29, 37, 30), (36, 42, 33)):
        d.ellipse((x1, y, x1 + 6, y + 5), outline=IRON_DARK, width=2)
        d.ellipse((x2, y + 2, x2 + 6, y + 7), outline=IRON_DARK, width=2)
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    props = {
        "road_signpost.png": road_signpost(),
        "wooden_fence_segment.png": wooden_fence_segment(),
        "supply_crate.png": supply_crate(),
        "wagon_wreck.png": wagon_wreck(),
        "grave_marker_tall.png": grave_marker_tall(),
        "dead_tree_twisted.png": dead_tree_twisted(),
        "bone_pile.png": bone_pile(),
        "chapel_rubble.png": chapel_rubble(),
        "ritual_altar.png": ritual_altar(),
        "fort_wall_breach.png": fort_wall_breach(),
        "brazier_large.png": brazier_large(),
        "chain_post.png": chain_post(),
    }
    for filename, image in props.items():
        image.save(OUT_DIR / filename)
        print(f"saved {filename}")


if __name__ == "__main__":
    main()
