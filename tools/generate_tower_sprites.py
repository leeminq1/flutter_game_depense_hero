from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "towers"
SIZE = 64
TIERS = (1, 2, 3)


def rgba(hex_value: str, alpha: int = 255):
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


OUTLINE = rgba("#231A14")
SHADOW = rgba("#000000", 70)
STONE = rgba("#8A8F99")
STONE_DARK = rgba("#59606A")
STONE_LIGHT = rgba("#B7BCC6")
WOOD = rgba("#8C6037")
WOOD_DARK = rgba("#5C3C24")
WOOD_LIGHT = rgba("#B8824A")
GOLD = rgba("#D9A73E")
GOLD_LIGHT = rgba("#F5DB7A")
GREEN = rgba("#51793A")
GREEN_LIGHT = rgba("#7DA455")
PURPLE = rgba("#6A54BE")
PURPLE_LIGHT = rgba("#C9B6FF")
BLUE = rgba("#4F99C4")
BLUE_LIGHT = rgba("#BEEBFF")
RED = rgba("#AF4D2E")
RED_LIGHT = rgba("#F5A36D")
ORANGE = rgba("#D86E24")
FIRE = rgba("#FFD36A")
ICE = rgba("#E8F9FF")
IRON = rgba("#757C86")
IRON_DARK = rgba("#4D535B")


def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def draw_rect(draw, box, fill, outline=OUTLINE):
    draw.rectangle(box, fill=fill, outline=outline)


def draw_ellipse(draw, box, fill, outline=OUTLINE):
    draw.ellipse(box, fill=fill, outline=outline)


def draw_polygon(draw, points, fill, outline=OUTLINE):
    draw.polygon(points, fill=fill, outline=outline)


def shadow(draw, box):
    draw.ellipse(box, fill=SHADOW)


def draw_banner(draw, x, y, color, accent):
    draw.polygon(
        [(x, y), (x + 10, y + 2), (x + 10, y + 11), (x + 4, y + 8), (x, y + 11)],
        fill=color,
        outline=OUTLINE,
    )
    draw.line((x + 2, y + 2, x + 8, y + 2), fill=accent)


def archer_tower(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 52, 54, 61))
    draw_rect(d, (16, 44, 48, 52), STONE, STONE_DARK)
    draw_rect(d, (20, 27, 44, 44), WOOD_LIGHT, WOOD_DARK)
    draw_rect(d, (22, 16, 42, 27), WOOD, WOOD_DARK)
    draw_polygon(d, [(19, 16), (32, 7), (45, 16), (41, 18), (23, 18)], GREEN, OUTLINE)
    d.line((22, 27, 16, 43), fill=WOOD_DARK, width=2)
    d.line((42, 27, 48, 43), fill=WOOD_DARK, width=2)
    d.line((24, 22, 24, 39), fill=WOOD_DARK, width=2)
    d.line((40, 22, 40, 39), fill=WOOD_DARK, width=2)
    d.line((24, 31, 40, 31), fill=WOOD_DARK, width=2)
    d.arc((24, 20, 41, 37), 210, 330, fill=GOLD_LIGHT, width=2)
    d.line((38, 24, 32, 32), fill=GOLD_LIGHT, width=2)
    draw_banner(d, 41, 13, GREEN, GREEN_LIGHT)
    draw_rect(d, (28, 33, 36, 44), WOOD_DARK, OUTLINE)
    if tier >= 2:
        draw_rect(d, (14, 40, 50, 44), STONE_LIGHT, STONE_DARK)
        draw_rect(d, (18, 20, 22, 33), WOOD_DARK, OUTLINE)
        draw_rect(d, (42, 20, 46, 33), WOOD_DARK, OUTLINE)
        draw_banner(d, 13, 16, GREEN, GREEN_LIGHT)
    if tier >= 3:
        draw_rect(d, (18, 11, 46, 16), WOOD_LIGHT, WOOD_DARK)
        draw_polygon(d, [(21, 11), (32, 3), (43, 11), (40, 13), (24, 13)], GREEN_LIGHT, OUTLINE)
        draw_rect(d, (18, 21, 22, 24), WOOD_LIGHT, WOOD_DARK)
        draw_rect(d, (42, 21, 46, 24), WOOD_LIGHT, WOOD_DARK)
        draw_rect(d, (26, 36, 38, 44), STONE, STONE_DARK)
        d.line((20, 24, 44, 24), fill=GOLD_LIGHT, width=1)
    return img


def guard_barracks(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 51, 56, 61))
    draw_rect(d, (13, 30, 51, 50), WOOD_LIGHT, WOOD_DARK)
    draw_polygon(d, [(11, 30), (32, 15), (53, 30), (48, 32), (16, 32)], RED, OUTLINE)
    draw_rect(d, (27, 37, 37, 50), WOOD_DARK, OUTLINE)
    draw_rect(d, (18, 36, 24, 44), STONE, STONE_DARK)
    draw_rect(d, (40, 36, 46, 44), STONE, STONE_DARK)
    draw_rect(d, (15, 44, 49, 50), STONE, STONE_DARK)
    draw_polygon(d, [(32, 22), (40, 26), (38, 38), (32, 42), (26, 38), (24, 26)], STONE, OUTLINE)
    d.line((32, 27, 32, 37), fill=GOLD_LIGHT, width=1)
    d.line((28, 31, 36, 31), fill=GOLD_LIGHT, width=1)
    draw_banner(d, 43, 19, RED, RED_LIGHT)
    if tier >= 2:
        draw_rect(d, (11, 46, 53, 52), STONE_DARK, OUTLINE)
        draw_rect(d, (16, 22, 20, 34), WOOD_DARK, OUTLINE)
        draw_rect(d, (44, 22, 48, 34), WOOD_DARK, OUTLINE)
        draw_banner(d, 11, 19, RED, RED_LIGHT)
    if tier >= 3:
        draw_rect(d, (10, 30, 54, 33), WOOD_DARK, OUTLINE)
        draw_rect(d, (18, 12, 46, 17), STONE_LIGHT, STONE_DARK)
        draw_rect(d, (11, 33, 15, 48), STONE, STONE_DARK)
        draw_rect(d, (49, 33, 53, 48), STONE, STONE_DARK)
        draw_rect(d, (22, 17, 42, 21), WOOD_DARK, OUTLINE)
        draw_rect(d, (29, 33, 35, 39), GOLD, OUTLINE)
        d.line((24, 17, 24, 27), fill=STONE_DARK, width=1)
        d.line((40, 17, 40, 27), fill=STONE_DARK, width=1)
    return img


def mage_obelisk(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 51, 52, 59))
    draw_rect(d, (17, 43, 47, 51), STONE, STONE_DARK)
    draw_rect(d, (22, 34, 42, 43), STONE_DARK, OUTLINE)
    draw_rect(d, (27, 24, 37, 35), STONE, STONE_DARK)
    draw_polygon(d, [(32, 8), (40, 18), (36, 32), (28, 32), (24, 18)], PURPLE, OUTLINE)
    draw_polygon(d, [(32, 12), (37, 19), (34, 27), (30, 27), (27, 19)], PURPLE_LIGHT, None)
    d.line((24, 34, 20, 43), fill=PURPLE_LIGHT, width=1)
    d.line((40, 34, 44, 43), fill=PURPLE_LIGHT, width=1)
    d.line((24, 46, 40, 46), fill=PURPLE_LIGHT)
    d.line((29, 39, 35, 39), fill=PURPLE_LIGHT)
    if tier >= 2:
        draw_rect(d, (20, 39, 44, 43), STONE_LIGHT, STONE_DARK)
        d.line((22, 40, 42, 40), fill=PURPLE_LIGHT, width=1)
        d.line((24, 42, 40, 42), fill=PURPLE, width=1)
        draw_polygon(d, [(20, 30), (23, 34), (20, 38), (17, 34)], PURPLE_LIGHT, OUTLINE)
        draw_polygon(d, [(44, 30), (47, 34), (44, 38), (41, 34)], PURPLE_LIGHT, OUTLINE)
    if tier >= 3:
        draw_polygon(d, [(32, 4), (42, 16), (37, 34), (27, 34), (22, 16)], PURPLE_LIGHT, OUTLINE)
        draw_rect(d, (18, 47, 46, 51), STONE_LIGHT, STONE_DARK)
        d.line((22, 36, 42, 36), fill=PURPLE_LIGHT, width=1)
    return img


def frost_shrine(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 52, 56, 60))
    draw_rect(d, (12, 44, 52, 52), STONE, STONE_DARK)
    draw_rect(d, (18, 28, 24, 44), STONE_DARK, OUTLINE)
    draw_rect(d, (40, 28, 46, 44), STONE_DARK, OUTLINE)
    draw_rect(d, (27, 30, 37, 44), STONE, STONE_DARK)
    draw_polygon(d, [(32, 14), (39, 24), (35, 38), (29, 38), (25, 24)], BLUE, OUTLINE)
    draw_polygon(d, [(32, 18), (36, 24), (34, 32), (30, 32), (28, 24)], BLUE_LIGHT, None)
    draw_polygon(d, [(21, 17), (25, 24), (21, 31), (17, 24)], ICE, OUTLINE)
    draw_polygon(d, [(43, 17), (47, 24), (43, 31), (39, 24)], ICE, OUTLINE)
    d.line((18, 47, 46, 47), fill=BLUE_LIGHT)
    d.line((29, 34, 35, 34), fill=ICE)
    if tier >= 2:
        draw_polygon(d, [(14, 26), (18, 32), (14, 38), (10, 32)], ICE, OUTLINE)
        draw_polygon(d, [(50, 26), (54, 32), (50, 38), (46, 32)], ICE, OUTLINE)
        draw_rect(d, (16, 40, 48, 44), STONE_LIGHT, STONE_DARK)
    if tier >= 3:
        draw_polygon(d, [(24, 14), (32, 9), (40, 14), (36, 16), (28, 16)], ICE, OUTLINE)
        draw_polygon(d, [(32, 8), (40, 20), (36, 39), (28, 39), (24, 20)], ICE, OUTLINE)
        d.line((22, 20, 42, 20), fill=BLUE_LIGHT, width=1)
        draw_rect(d, (14, 48, 50, 52), STONE_LIGHT, STONE_DARK)
    return img


def coin_mill(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (7, 52, 57, 61))
    body_top = 31 if tier == 1 else 29
    draw_rect(d, (15, body_top, 49, 50), WOOD_LIGHT, WOOD_DARK)
    draw_polygon(d, [(13, 31), (32, 18), (51, 31), (46, 33), (18, 33)], GREEN, OUTLINE)
    draw_rect(d, (28, 37, 37, 50), WOOD_DARK, OUTLINE)
    d.line((20, 26, 44, 26), fill=WOOD_DARK, width=2)
    d.line((32, 26, 32, 6), fill=WOOD_DARK, width=2)
    d.line((32, 26, 18, 15), fill=WOOD_DARK, width=2)
    d.line((32, 26, 46, 15), fill=WOOD_DARK, width=2)
    d.line((32, 26, 20, 37), fill=WOOD_DARK, width=2)
    d.line((32, 26, 44, 37), fill=WOOD_DARK, width=2)
    d.line((32, 26, 32, 46), fill=WOOD_DARK, width=2)
    draw_ellipse(d, (18, 35, 26, 43), GOLD, OUTLINE)
    d.line((21, 39, 23, 39), fill=GOLD_LIGHT)
    d.line((30, 36, 35, 36), fill=WOOD, width=1)
    if tier >= 2:
        draw_rect(d, (20, 29, 44, 33), WOOD, WOOD_DARK)
        draw_rect(d, (13, 46, 51, 50), STONE, STONE_DARK)
        draw_rect(d, (39, 35, 45, 41), GOLD, OUTLINE)
        d.line((24, 12, 40, 12), fill=WOOD_DARK, width=1)
    if tier >= 3:
        draw_polygon(d, [(19, 18), (32, 10), (45, 18), (42, 20), (22, 20)], GREEN_LIGHT, OUTLINE)
        draw_rect(d, (16, 34, 22, 42), GOLD, OUTLINE)
        d.line((17, 26, 47, 26), fill=WOOD_LIGHT, width=1)
        d.line((32, 4, 32, 2), fill=WOOD_DARK, width=2)
    return img


def ballista(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 52, 56, 61))
    draw_rect(d, (14, 43, 50, 51), STONE, STONE_DARK)
    draw_rect(d, (18, 37, 46, 43), WOOD_DARK, OUTLINE)
    d.line((21, 37, 17, 22), fill=WOOD, width=3)
    d.line((43, 37, 47, 22), fill=WOOD, width=3)
    d.line((17, 22, 32, 29), fill=WOOD_LIGHT, width=3)
    d.line((47, 22, 32, 29), fill=WOOD_LIGHT, width=3)
    d.line((23, 31, 41, 31), fill=WOOD_LIGHT, width=3)
    d.line((32, 18, 32, 34), fill=WOOD_DARK, width=2)
    d.line((24, 20, 40, 20), fill=GOLD_LIGHT, width=1)
    d.polygon([(31, 11), (40, 18), (31, 25), (33, 21), (21, 21), (21, 17), (33, 17)], fill=STONE, outline=OUTLINE)
    draw_rect(d, (22, 43, 28, 49), WOOD, WOOD_DARK)
    draw_rect(d, (36, 43, 42, 49), WOOD, WOOD_DARK)
    if tier >= 2:
        draw_rect(d, (16, 39, 48, 43), IRON, IRON_DARK)
        draw_rect(d, (18, 43, 46, 46), IRON_DARK, OUTLINE)
        d.line((18, 24, 15, 18), fill=IRON_DARK, width=2)
        d.line((46, 24, 49, 18), fill=IRON_DARK, width=2)
        d.line((20, 43, 18, 38), fill=IRON, width=2)
        d.line((44, 43, 46, 38), fill=IRON, width=2)
    if tier >= 3:
        d.polygon([(31, 8), (42, 17), (31, 27), (34, 22), (18, 22), (18, 18), (34, 18)], fill=IRON, outline=OUTLINE)
        draw_rect(d, (14, 46, 50, 51), STONE_LIGHT, STONE_DARK)
        draw_banner(d, 44, 15, RED, RED_LIGHT)
    return img


def emberkeep(tier):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 52, 54, 61))
    draw_rect(d, (17, 41, 47, 51), STONE_DARK, OUTLINE)
    draw_rect(d, (22, 27, 42, 41), STONE, STONE_DARK)
    draw_rect(d, (26, 18, 38, 27), WOOD_DARK, OUTLINE)
    draw_polygon(d, [(24, 18), (32, 11), (40, 18), (37, 20), (27, 20)], RED, OUTLINE)
    draw_polygon(d, [(32, 6), (39, 17), (35, 18), (39, 29), (32, 23), (25, 29), (29, 18), (25, 17)], ORANGE, OUTLINE)
    draw_polygon(d, [(32, 11), (36, 18), (34, 19), (36, 24), (32, 20), (28, 24), (30, 19), (28, 18)], FIRE, None)
    draw_rect(d, (28, 31, 36, 41), WOOD_DARK, OUTLINE)
    d.line((21, 45, 43, 45), fill=RED_LIGHT)
    if tier >= 2:
        draw_rect(d, (18, 28, 22, 38), STONE_DARK, OUTLINE)
        draw_rect(d, (42, 28, 46, 38), STONE_DARK, OUTLINE)
        draw_rect(d, (20, 24, 24, 38), STONE_DARK, OUTLINE)
        draw_rect(d, (40, 24, 44, 38), STONE_DARK, OUTLINE)
        draw_rect(d, (20, 46, 44, 51), STONE, STONE_DARK)
    if tier >= 3:
        draw_polygon(d, [(22, 15), (26, 9), (30, 15)], STONE_DARK)
        draw_polygon(d, [(34, 15), (38, 9), (42, 15)], STONE_DARK)
        draw_polygon(d, [(32, 3), (40, 15), (36, 16), (40, 28), (32, 22), (24, 28), (28, 16), (24, 15)], FIRE, OUTLINE)
        draw_rect(d, (18, 48, 46, 51), STONE_LIGHT, STONE_DARK)
    return img


def save_tiered_series(base_name, renderer):
    tier_one_image = None
    for tier in TIERS:
        image = renderer(tier)
        image.save(OUT_DIR / f"{base_name}_t{tier}.png")
        if tier == 1:
            tier_one_image = image
        print(f"saved {base_name}_t{tier}.png")
    if tier_one_image is not None:
        tier_one_image.save(OUT_DIR / f"{base_name}.png")
        print(f"saved {base_name}.png")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sprites = {
        "archer_tower": archer_tower,
        "guard_barracks": guard_barracks,
        "mage_obelisk": mage_obelisk,
        "frost_shrine": frost_shrine,
        "coin_mill": coin_mill,
        "ballista": ballista,
        "emberkeep": emberkeep,
    }
    for base_name, renderer in sprites.items():
        save_tiered_series(base_name, renderer)


if __name__ == "__main__":
    main()
