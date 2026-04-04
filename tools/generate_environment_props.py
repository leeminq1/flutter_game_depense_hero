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
OBSIDIAN = rgba("#35303C")
EMBER = rgba("#E4682F")


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


def well():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 53, 54, 60))
    rect(d, (16, 34, 48, 50), STONE, STONE_DARK)
    rect(d, (20, 38, 44, 50), DIRT, STONE_DARK)
    rect(d, (22, 18, 26, 34), WOOD, WOOD_DARK)
    rect(d, (38, 18, 42, 34), WOOD, WOOD_DARK)
    line(d, (24, 18, 40, 18), fill=WOOD_DARK, width=2)
    line(d, (32, 18, 32, 29), fill=WOOD_DARK, width=1)
    d.ellipse((28, 26, 36, 33), outline=WOOD_DARK, width=2)
    return img


def spike_barricade():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 53, 56, 60))
    rect(d, (12, 42, 52, 49), WOOD, WOOD_DARK)
    for x in (14, 22, 30, 38, 46):
        poly(d, [(x, 42), (x + 3, 24), (x + 6, 42)], WOOD_LIGHT, WOOD_DARK)
    line(d, (14, 49, 50, 35), fill=WOOD_DARK, width=2)
    return img


def campfire():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (14, 52, 50, 59))
    line(d, (22, 46, 32, 38), fill=WOOD_DARK, width=3)
    line(d, (42, 46, 32, 38), fill=WOOD_DARK, width=3)
    poly(d, [(32, 20), (38, 31), (35, 32), (39, 40), (32, 35), (25, 40), (29, 32), (26, 31)], ORANGE, OUTLINE)
    poly(d, [(32, 25), (36, 32), (34, 33), (36, 38), (32, 34), (28, 38), (30, 33), (28, 32)], FIRE)
    for cx, cy in ((20, 47), (27, 50), (37, 50), (44, 47)):
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=STONE, outline=STONE_DARK)
    return img


def broken_coffin():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 53, 54, 60))
    poly(d, [(16, 25), (32, 17), (48, 25), (44, 46), (20, 46)], WOOD, WOOD_DARK)
    poly(d, [(22, 28), (32, 23), (42, 28), (39, 42), (25, 42)], WOOD_LIGHT, WOOD_DARK)
    line(d, (17, 34, 47, 29), fill=WOOD_DARK, width=2)
    line(d, (18, 46, 25, 52), fill=WOOD_DARK, width=2)
    return img


def ward_stone():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (16, 53, 48, 60))
    poly(d, [(24, 48), (20, 28), (32, 14), (44, 28), (40, 48)], STONE, STONE_DARK)
    line(d, (26, 38, 38, 38), fill=PURPLE_LIGHT, width=1)
    line(d, (32, 24, 32, 44), fill=PURPLE_LIGHT, width=1)
    d.ellipse((28, 18, 36, 26), fill=PURPLE, outline=OUTLINE)
    return img


def candle_cluster():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (16, 54, 48, 60))
    for box in ((22, 34, 27, 50), (29, 29, 35, 50), (37, 36, 42, 50)):
        rect(d, box, BONE, BONE_DARK)
    poly(d, [(24, 32), (26, 28), (27, 34)], FIRE, OUTLINE)
    poly(d, [(32, 27), (34, 22), (35, 29)], FIRE, OUTLINE)
    poly(d, [(39, 34), (41, 30), (42, 36)], FIRE, OUTLINE)
    return img


def siege_crate():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 52, 54, 60))
    rect(d, (14, 26, 50, 50), WOOD, WOOD_DARK)
    rect(d, (18, 30, 46, 46), WOOD_LIGHT, WOOD_DARK)
    rect(d, (22, 20, 42, 26), IRON, IRON_DARK)
    line(d, (20, 30, 44, 46), fill=WOOD_DARK, width=2)
    line(d, (44, 30, 20, 46), fill=WOOD_DARK, width=2)
    return img


def spear_rack():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 53, 56, 60))
    rect(d, (14, 42, 50, 48), WOOD, WOOD_DARK)
    rect(d, (18, 24, 22, 42), WOOD_DARK, OUTLINE)
    rect(d, (42, 24, 46, 42), WOOD_DARK, OUTLINE)
    for x in (21, 27, 33, 39, 45):
        line(d, (x, 20, x, 44), fill=IRON_DARK, width=2)
        poly(d, [(x - 2, 20), (x, 14), (x + 2, 20)], IRON, OUTLINE)
    return img


def brazier_stand():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (14, 53, 50, 60))
    line(d, (24, 52, 28, 36), fill=IRON_DARK, width=2)
    line(d, (40, 52, 36, 36), fill=IRON_DARK, width=2)
    rect(d, (22, 30, 42, 36), IRON, IRON_DARK)
    poly(d, [(32, 14), (38, 25), (35, 26), (39, 34), (32, 29), (25, 34), (29, 26), (26, 25)], ORANGE, OUTLINE)
    poly(d, [(32, 19), (36, 26), (34, 27), (36, 31), (32, 28), (28, 31), (30, 27), (28, 26)], FIRE)
    return img


def obsidian_stake():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (18, 53, 46, 60))
    poly(d, [(32, 12), (40, 48), (24, 48)], IRON_DARK, OUTLINE)
    line(d, (28, 44, 36, 44), fill=RED_LIGHT, width=1)
    return img


def chain_post_heavy():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 53, 56, 60))
    rect(d, (12, 40, 22, 54), OBSIDIAN, OUTLINE)
    rect(d, (42, 40, 52, 54), OBSIDIAN, OUTLINE)
    rect(d, (15, 18, 20, 40), IRON, IRON_DARK)
    rect(d, (44, 18, 49, 40), IRON, IRON_DARK)
    for x1, x2, y in ((20, 28, 24), (27, 35, 28), (34, 42, 32)):
        d.ellipse((x1, y, x1 + 7, y + 6), outline=IRON_DARK, width=2)
        d.ellipse((x2, y + 2, x2 + 7, y + 8), outline=IRON_DARK, width=2)
    return img


def ember_pile():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 53, 52, 60))
    poly(d, [(18, 48), (26, 35), (38, 34), (46, 48), (32, 52)], DIRT, OUTLINE)
    for cx, cy in ((24, 43), (31, 39), (38, 43), (33, 47)):
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=EMBER, outline=OUTLINE)
    return img


def broken_barrel():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (14, 53, 50, 60))
    poly(d, [(22, 27), (34, 23), (42, 29), (38, 48), (24, 48)], WOOD, WOOD_DARK)
    line(d, (22, 34, 40, 31), fill=IRON_DARK, width=2)
    line(d, (24, 42, 38, 39), fill=IRON_DARK, width=2)
    line(d, (22, 27, 18, 37), fill=WOOD_DARK, width=2)
    line(d, (38, 48, 44, 53), fill=WOOD_DARK, width=2)
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
        "well.png": well(),
        "spike_barricade.png": spike_barricade(),
        "campfire.png": campfire(),
        "broken_coffin.png": broken_coffin(),
        "ward_stone.png": ward_stone(),
        "candle_cluster.png": candle_cluster(),
        "siege_crate.png": siege_crate(),
        "spear_rack.png": spear_rack(),
        "brazier_stand.png": brazier_stand(),
        "obsidian_stake.png": obsidian_stake(),
        "chain_post_heavy.png": chain_post_heavy(),
        "ember_pile.png": ember_pile(),
        "broken_barrel.png": broken_barrel(),
    }
    for filename, image in props.items():
        image.save(OUT_DIR / filename)
        print(f"saved {filename}")


if __name__ == "__main__":
    main()
