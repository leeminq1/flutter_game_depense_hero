from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "environment" / "landmarks"
SIZE = 96


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
IRON = rgba("#757C86")
IRON_DARK = rgba("#4D535B")
GREEN = rgba("#587441")
RED = rgba("#A84A31")
RED_LIGHT = rgba("#E0915A")
RED_DARK = rgba("#682A1F")
PURPLE = rgba("#6A4AAC")
PURPLE_LIGHT = rgba("#C9B7FF")
GOLD = rgba("#D3A04D")
FIRE = rgba("#FFD06A")
EMBER = rgba("#E46A2D")
OBSIDIAN = rgba("#35303C")
MOSS = rgba("#60784B")


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


def village_gate():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (12, 82, 84, 92))
    rect(d, (18, 64, 32, 86), STONE, STONE_DARK)
    rect(d, (64, 64, 78, 86), STONE, STONE_DARK)
    rect(d, (22, 32, 74, 64), WOOD, WOOD_DARK)
    for x in range(24, 74, 8):
        rect(d, (x, 26, x + 5, 32), STONE_LIGHT, STONE_DARK)
    rect(d, (38, 46, 58, 86), WOOD_DARK, OUTLINE)
    poly(d, [(24, 32), (48, 16), (72, 32)], RED, RED_DARK)
    rect(d, (44, 20, 52, 28), WOOD_LIGHT, WOOD_DARK)
    rect(d, (20, 52, 30, 60), GREEN, WOOD_DARK)
    rect(d, (66, 52, 76, 60), GREEN, WOOD_DARK)
    return img


def bandit_stockade():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 82, 88, 92))
    for x in range(12, 84, 8):
        poly(d, [(x, 78), (x + 3, 20), (x + 6, 78)], WOOD_LIGHT, WOOD_DARK)
    rect(d, (14, 46, 82, 56), WOOD, WOOD_DARK)
    rect(d, (18, 60, 78, 68), WOOD, WOOD_DARK)
    rect(d, (40, 34, 56, 78), WOOD_DARK, OUTLINE)
    rect(d, (43, 16, 53, 28), RED, RED_DARK)
    line(d, (22, 36, 30, 28), fill=WOOD_DARK, width=2)
    line(d, (68, 38, 76, 30), fill=WOOD_DARK, width=2)
    return img


def mausoleum_gate():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (10, 82, 86, 92))
    rect(d, (18, 48, 32, 86), STONE, STONE_DARK)
    rect(d, (64, 48, 78, 86), STONE, STONE_DARK)
    rect(d, (24, 24, 72, 48), STONE, STONE_DARK)
    poly(d, [(24, 24), (48, 10), (72, 24)], STONE_LIGHT)
    rect(d, (38, 48, 58, 86), IRON_DARK, OUTLINE)
    for x in (42, 47, 52):
        line(d, (x, 50, x, 84), fill=IRON, width=2)
    line(d, (42, 58, 52, 58), fill=IRON, width=2)
    line(d, (42, 69, 52, 69), fill=IRON, width=2)
    line(d, (48, 18, 48, 38), fill=STONE_LIGHT, width=1)
    line(d, (40, 27, 56, 27), fill=STONE_LIGHT, width=1)
    rect(d, (14, 60, 18, 72), MOSS, STONE_DARK)
    rect(d, (78, 64, 82, 76), MOSS, STONE_DARK)
    return img


def cursed_chapel_front():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 82, 88, 92))
    rect(d, (22, 42, 74, 84), STONE, STONE_DARK)
    poly(d, [(18, 42), (48, 18), (78, 42)], STONE_DARK)
    rect(d, (40, 54, 56, 84), OBSIDIAN, OUTLINE)
    rect(d, (30, 54, 38, 66), PURPLE, STONE_DARK)
    rect(d, (58, 54, 66, 66), PURPLE, STONE_DARK)
    line(d, (48, 28, 48, 52), fill=PURPLE_LIGHT, width=2)
    line(d, (40, 36, 56, 36), fill=PURPLE_LIGHT, width=2)
    poly(d, [(22, 18), (28, 10), (36, 22)], OBSIDIAN)
    poly(d, [(60, 22), (68, 10), (74, 18)], OBSIDIAN)
    rect(d, (20, 78, 76, 84), STONE_DARK, OUTLINE)
    return img


def bastion_wall_chunk():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 82, 88, 92))
    rect(d, (12, 34, 84, 84), STONE, STONE_DARK)
    for x in range(16, 84, 10):
        rect(d, (x, 24, x + 7, 34), STONE_LIGHT, STONE_DARK)
    poly(d, [(34, 84), (42, 54), (56, 54), (64, 84)], (0, 0, 0, 0), None)
    rect(d, (18, 48, 28, 58), STONE_LIGHT, STONE_DARK)
    rect(d, (66, 44, 78, 56), STONE_LIGHT, STONE_DARK)
    rect(d, (20, 62, 32, 74), IRON_DARK, OUTLINE)
    rect(d, (64, 62, 76, 74), IRON_DARK, OUTLINE)
    return img


def infernal_gate():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    shadow(d, (8, 82, 88, 92))
    rect(d, (18, 48, 32, 86), OBSIDIAN, OUTLINE)
    rect(d, (64, 48, 78, 86), OBSIDIAN, OUTLINE)
    poly(d, [(18, 48), (26, 24), (32, 48)], OBSIDIAN)
    poly(d, [(64, 48), (70, 24), (78, 48)], OBSIDIAN)
    poly(d, [(26, 48), (48, 18), (70, 48)], RED_DARK)
    rect(d, (38, 48, 58, 86), RED_DARK, OUTLINE)
    poly(d, [(48, 30), (58, 46), (52, 47), (58, 60), (48, 52), (38, 60), (44, 47), (38, 46)], EMBER, OUTLINE)
    poly(d, [(48, 36), (54, 47), (50, 48), (54, 56), (48, 51), (42, 56), (46, 48), (42, 47)], FIRE)
    rect(d, (26, 54, 34, 64), GOLD, OUTLINE)
    rect(d, (62, 54, 70, 64), GOLD, OUTLINE)
    line(d, (48, 18, 48, 10), fill=EMBER, width=2)
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    landmarks = {
        "village_gate.png": village_gate(),
        "bandit_stockade.png": bandit_stockade(),
        "mausoleum_gate.png": mausoleum_gate(),
        "cursed_chapel_front.png": cursed_chapel_front(),
        "bastion_wall_chunk.png": bastion_wall_chunk(),
        "infernal_gate.png": infernal_gate(),
    }
    for filename, image in landmarks.items():
        image.save(OUT_DIR / filename)
        print(f"saved {filename}")


if __name__ == "__main__":
    main()
