from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ENEMY_DIR = ROOT / "assets" / "sprites" / "enemies"


def rgba(hex_value: str, alpha: int = 255):
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


OUTLINE = rgba("#1C1614")
STEEL = rgba("#97A0AA")
STEEL_DARK = rgba("#4B515A")
PURPLE = rgba("#7D58C6")
PURPLE_LIGHT = rgba("#D4C4FF")
GREEN = rgba("#5F7A4F")
GREEN_LIGHT = rgba("#A0C27D")
RED = rgba("#A94C33")
RED_DARK = rgba("#6E2C20")
GOLD = rgba("#D2A248")
EMBER = rgba("#E77E36")
BONE = rgba("#D1C9B7")
BROWN = rgba("#7F5733")
OBSIDIAN = rgba("#302A34")


def open_enemy(name: str):
    return Image.open(ENEMY_DIR / f"{name}.png").convert("RGBA")


def save_enemy(name: str, image: Image.Image):
    image.save(ENEMY_DIR / f"{name}.png")
    print(f"polished {name}.png")


def polish_raider():
    img = open_enemy("raider")
    d = ImageDraw.Draw(img)
    d.line((39, 40, 45, 37), fill=STEEL_DARK, width=2)
    d.polygon([(45, 37), (48, 39), (45, 42)], fill=STEEL)
    d.line((30, 27, 36, 27), fill=RED, width=1)
    save_enemy("raider", img)


def polish_scout():
    img = open_enemy("scout")
    d = ImageDraw.Draw(img)
    d.polygon([(16, 24), (10, 28), (14, 34), (19, 31)], fill=GREEN, outline=OUTLINE)
    d.line((29, 29, 36, 26), fill=BROWN, width=1)
    d.line((18, 39, 29, 39), fill=STEEL_DARK, width=2)
    save_enemy("scout", img)


def polish_shield_infantry():
    img = open_enemy("shield_infantry")
    d = ImageDraw.Draw(img)
    d.polygon([(34, 17), (48, 20), (48, 37), (38, 45), (33, 38)], fill=STEEL, outline=OUTLINE)
    d.line((39, 21, 39, 39), fill=GREEN_LIGHT, width=1)
    d.line((35, 28, 43, 28), fill=GREEN_LIGHT, width=1)
    d.rectangle((20, 34, 32, 47), fill=STEEL_DARK, outline=None)
    save_enemy("shield_infantry", img)


def polish_cult_adept():
    img = open_enemy("cult_adept")
    d = ImageDraw.Draw(img)
    d.polygon([(18, 37), (32, 37), (35, 45), (15, 45)], fill=PURPLE, outline=OUTLINE)
    d.line((22, 22, 22, 41), fill=GOLD, width=2)
    d.ellipse((18, 18, 26, 26), fill=PURPLE_LIGHT, outline=OUTLINE)
    d.line((18, 30, 30, 30), fill=GOLD, width=1)
    save_enemy("cult_adept", img)


def polish_skeleton():
    img = open_enemy("skeleton")
    d = ImageDraw.Draw(img)
    d.polygon([(18, 26), (28, 26), (26, 32), (17, 31)], fill=BROWN, outline=OUTLINE)
    d.line((18, 28, 25, 31), fill=GOLD, width=1)
    save_enemy("skeleton", img)


def polish_grave_guard():
    img = open_enemy("grave_guard")
    d = ImageDraw.Draw(img)
    d.rectangle((14, 14, 20, 26), fill=STEEL_DARK, outline=OUTLINE)
    d.rectangle((28, 14, 34, 26), fill=STEEL_DARK, outline=OUTLINE)
    d.line((19, 22, 29, 22), fill=GREEN_LIGHT, width=1)
    d.line((17, 30, 32, 30), fill=GREEN, width=2)
    save_enemy("grave_guard", img)


def polish_corrupted_knight():
    img = open_enemy("corrupted_knight")
    d = ImageDraw.Draw(img)
    d.rectangle((13, 13, 19, 24), fill=OBSIDIAN, outline=OUTLINE)
    d.rectangle((28, 13, 34, 24), fill=OBSIDIAN, outline=OUTLINE)
    d.polygon([(18, 18), (12, 24), (15, 34), (19, 29)], fill=RED_DARK, outline=OUTLINE)
    save_enemy("corrupted_knight", img)


def polish_warlock():
    img = open_enemy("warlock")
    d = ImageDraw.Draw(img)
    d.polygon([(15, 13), (24, 2), (31, 13), (28, 15), (18, 15)], fill=PURPLE, outline=OUTLINE)
    d.rectangle((14, 14, 18, 27), fill=OBSIDIAN, outline=OUTLINE)
    d.rectangle((29, 14, 33, 27), fill=OBSIDIAN, outline=OUTLINE)
    d.line((21, 20, 21, 38), fill=GOLD, width=2)
    d.ellipse((17, 15, 25, 23), fill=EMBER, outline=OUTLINE)
    save_enemy("warlock", img)


def polish_bastion_overlord():
    img = open_enemy("bastion_overlord")
    d = ImageDraw.Draw(img)
    d.rectangle((12, 12, 19, 26), fill=OBSIDIAN, outline=OUTLINE)
    d.rectangle((29, 12, 36, 26), fill=OBSIDIAN, outline=OUTLINE)
    d.line((16, 20, 32, 20), fill=GOLD, width=1)
    d.line((16, 28, 32, 28), fill=EMBER, width=2)
    save_enemy("bastion_overlord", img)


def main():
    polish_raider()
    polish_scout()
    polish_shield_infantry()
    polish_cult_adept()
    polish_skeleton()
    polish_grave_guard()
    polish_corrupted_knight()
    polish_warlock()
    polish_bastion_overlord()


if __name__ == "__main__":
    main()
