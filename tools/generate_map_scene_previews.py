from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "crest_stage_scene_preview.png"
SPRITES = ROOT / "assets" / "sprites" / "environment"
CELL_W = 280
CELL_H = 176


THEME_BACKGROUNDS = {
    "frontier": ((49, 67, 40), (31, 43, 26)),
    "bandit": ((64, 49, 34), (36, 26, 19)),
    "grave": ((49, 64, 58), (27, 34, 29)),
    "chapel": ((53, 41, 63), (28, 21, 34)),
    "bastion": ((52, 53, 61), (29, 29, 34)),
    "throne": ((70, 42, 32), (28, 18, 16)),
}

GROUND_ACCENTS = {
    "frontier": [(62, 91, 48, 36), (142, 114, 77, 26), (86, 66, 49, 20)],
    "bandit": [(89, 59, 36, 38), (122, 89, 55, 30), (68, 43, 26, 22)],
    "grave": [(61, 81, 71, 38), (110, 109, 97, 26), (66, 74, 68, 22)],
    "chapel": [(75, 55, 96, 38), (122, 91, 144, 26), (53, 42, 68, 22)],
    "bastion": [(75, 77, 87, 40), (107, 111, 119, 26), (56, 58, 64, 22)],
    "throne": [(91, 52, 36, 38), (140, 90, 50, 28), (74, 35, 26, 24)],
}

PATH_COLORS = {
    "frontier": {"glow": (244, 213, 141, 55), "base": (184, 149, 104, 255), "detail": (225, 200, 147, 85), "shadow": (62, 45, 30, 80)},
    "bandit": {"glow": (226, 190, 122, 55), "base": (170, 140, 99, 255), "detail": (217, 183, 126, 85), "shadow": (65, 45, 31, 84)},
    "grave": {"glow": (143, 192, 155, 55), "base": (169, 153, 121, 255), "detail": (154, 179, 161, 85), "shadow": (64, 68, 66, 84)},
    "chapel": {"glow": (199, 165, 240, 55), "base": (155, 135, 110, 255), "detail": (194, 163, 236, 85), "shadow": (64, 51, 79, 84)},
    "bastion": {"glow": (211, 192, 168, 55), "base": (156, 138, 115, 255), "detail": (200, 192, 180, 85), "shadow": (68, 73, 83, 84)},
    "throne": {"glow": (241, 177, 107, 55), "base": (176, 140, 97, 255), "detail": (240, 179, 116, 85), "shadow": (86, 56, 42, 84)},
}


CREST_STAGES = [
    {
        "label": "Stage 5",
        "theme": "frontier",
        "path": [(0.03, 0.68), (0.23, 0.68), (0.23, 0.32), (0.49, 0.32), (0.49, 0.72), (0.75, 0.72), (0.75, 0.44), (0.95, 0.44)],
        "slots": [(0.14, 0.47), (0.16, 0.83), (0.33, 0.50), (0.38, 0.18), (0.58, 0.52), (0.67, 0.86), (0.84, 0.60)],
        "decor": [
            ("landmarks/village_gate.png", 0.55, 0.14, 1.38, "bg"),
            ("props/wagon_wreck.png", 0.10, 0.20, 0.98, "bg"),
            ("props/wooden_fence_segment.png", 0.16, 0.82, 0.98, "bg"),
            ("props/road_signpost.png", 0.77, 0.20, 0.85, "bg"),
            ("props/well.png", 0.86, 0.79, 0.94, "bg"),
            ("props/wooden_fence_segment.png", 0.93, 0.90, 1.04, "fg"),
        ],
    },
    {
        "label": "Stage 10",
        "theme": "bandit",
        "path": [(0.03, 0.38), (0.18, 0.38), (0.18, 0.74), (0.40, 0.74), (0.40, 0.24), (0.67, 0.24), (0.67, 0.70), (0.95, 0.70)],
        "slots": [(0.11, 0.19), (0.22, 0.56), (0.33, 0.85), (0.48, 0.48), (0.58, 0.11), (0.75, 0.58), (0.89, 0.84)],
        "decor": [
            ("landmarks/bandit_stockade.png", 0.56, 0.15, 1.42, "bg"),
            ("props/spike_barricade.png", 0.10, 0.20, 0.98, "bg"),
            ("props/campfire.png", 0.17, 0.80, 0.95, "bg"),
            ("props/supply_crate.png", 0.78, 0.25, 0.95, "bg"),
            ("props/road_signpost.png", 0.89, 0.72, 0.85, "bg"),
            ("props/spike_barricade.png", 0.93, 0.90, 1.02, "fg"),
        ],
    },
    {
        "label": "Stage 15",
        "theme": "grave",
        "path": [(0.05, 0.22), (0.28, 0.22), (0.28, 0.75), (0.55, 0.75), (0.55, 0.35), (0.82, 0.35), (0.82, 0.65), (0.95, 0.65)],
        "slots": [(0.15, 0.10), (0.18, 0.54), (0.39, 0.56), (0.46, 0.88), (0.63, 0.48), (0.72, 0.16), (0.89, 0.49)],
        "decor": [
            ("landmarks/mausoleum_gate.png", 0.55, 0.14, 1.42, "bg"),
            ("props/broken_coffin.png", 0.14, 0.23, 0.96, "bg"),
            ("props/dead_tree_twisted.png", 0.19, 0.79, 1.00, "bg"),
            ("props/bone_pile.png", 0.77, 0.22, 0.92, "bg"),
            ("props/candle_cluster.png", 0.88, 0.76, 0.90, "bg"),
            ("props/grave_marker_tall.png", 0.93, 0.90, 1.00, "fg"),
        ],
    },
    {
        "label": "Stage 20",
        "theme": "chapel",
        "path": [(0.04, 0.58), (0.20, 0.58), (0.20, 0.86), (0.52, 0.86), (0.52, 0.18), (0.78, 0.18), (0.78, 0.55), (0.96, 0.55)],
        "slots": [(0.11, 0.73), (0.26, 0.44), (0.34, 0.92), (0.57, 0.57), (0.63, 0.08), (0.83, 0.32), (0.88, 0.78)],
        "decor": [
            ("landmarks/cursed_chapel_front.png", 0.55, 0.14, 1.46, "bg"),
            ("landmarks/ritual_arch.png", 0.15, 0.77, 1.08, "bg"),
            ("props/brazier_stand.png", 0.20, 0.24, 0.92, "bg"),
            ("props/chapel_rubble.png", 0.79, 0.24, 0.95, "bg"),
            ("props/ward_stone.png", 0.88, 0.79, 0.94, "bg"),
            ("props/candle_cluster.png", 0.92, 0.90, 0.98, "fg"),
        ],
    },
    {
        "label": "Stage 25",
        "theme": "bastion",
        "path": [(0.02, 0.48), (0.18, 0.48), (0.18, 0.18), (0.45, 0.18), (0.45, 0.82), (0.72, 0.82), (0.72, 0.28), (0.97, 0.28)],
        "slots": [(0.12, 0.31), (0.24, 0.66), (0.35, 0.38), (0.40, 0.90), (0.62, 0.53), (0.79, 0.36), (0.86, 0.76)],
        "decor": [
            ("landmarks/bastion_wall_chunk.png", 0.55, 0.14, 1.50, "bg"),
            ("props/fort_wall_breach.png", 0.11, 0.22, 0.98, "bg"),
            ("props/siege_crate.png", 0.18, 0.79, 0.96, "bg"),
            ("props/spear_rack.png", 0.79, 0.23, 0.95, "bg"),
            ("props/brazier_stand.png", 0.89, 0.76, 0.94, "bg"),
            ("props/chain_post.png", 0.93, 0.90, 1.00, "fg"),
        ],
    },
    {
        "label": "Stage 30",
        "theme": "throne",
        "path": [(0.03, 0.68), (0.23, 0.68), (0.23, 0.32), (0.49, 0.32), (0.49, 0.72), (0.75, 0.72), (0.75, 0.44), (0.95, 0.44)],
        "slots": [(0.14, 0.47), (0.16, 0.83), (0.33, 0.50), (0.38, 0.18), (0.58, 0.52), (0.67, 0.86), (0.84, 0.60)],
        "decor": [
            ("landmarks/infernal_gate.png", 0.55, 0.13, 1.52, "bg"),
            ("landmarks/throne_road_monument.png", 0.18, 0.76, 1.12, "bg"),
            ("props/chain_post_heavy.png", 0.10, 0.21, 0.98, "bg"),
            ("props/obsidian_stake.png", 0.80, 0.21, 0.95, "bg"),
            ("props/ember_pile.png", 0.90, 0.78, 1.00, "bg"),
            ("props/chain_post_heavy.png", 0.93, 0.90, 1.02, "fg"),
        ],
    },
]


def gradient_background(theme):
    top, bottom = THEME_BACKGROUNDS[theme]
    img = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    px = img.load()
    for y in range(CELL_H):
        t = y / max(1, CELL_H - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(CELL_W):
            px[x, y] = color
    return img


def draw_ground_texture(draw, theme, config):
    accents = GROUND_ACCENTS[theme]
    for gx in range(8):
        for gy in range(6):
            seed = (gx * 17) + (gy * 13)
            cx = ((gx + 0.5) / 8) * CELL_W + (((seed % 9) - 4) * 3)
            cy = ((gy + 0.5) / 6) * CELL_H + ((((seed // 3) % 9) - 4) * 3)
            if is_texture_suppressed(cx, cy, config, padding=12):
                continue
            color = accents[seed % len(accents)]
            width = 14 + ((seed % 5) * 4)
            height = 8 + (((seed // 2) % 4) * 3)
            box = (cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2)
            if theme in {"frontier", "bandit", "grave", "throne"}:
                draw.ellipse(box, fill=color)
            elif theme == "chapel":
                draw.rounded_rectangle(box, radius=5, fill=color)
            else:
                draw.rectangle(box, fill=color)
            if theme == "throne":
                ember = (255, 155, 82, 40)
                draw.ellipse((cx, cy - 1, cx + 3, cy + 2), fill=ember)


def sample_path_points(points, spacing=54):
    scaled = [(x * CELL_W, y * CELL_H) for x, y in points]
    samples = []
    for start, end in zip(scaled, scaled[1:]):
        sx, sy = start
        ex, ey = end
        dx = ex - sx
        dy = ey - sy
        length = max(1.0, (dx * dx + dy * dy) ** 0.5)
        count = max(1, int(length // spacing))
        for idx in range(1, count + 1):
            t = idx / (count + 1)
            samples.append((sx + dx * t, sy + dy * t))
    return samples


def major_bend_points(points):
    bends = []
    scaled = [(x * CELL_W, y * CELL_H) for x, y in points]
    for a, b, c in zip(scaled, scaled[1:], scaled[2:]):
        v1 = (b[0] - a[0], b[1] - a[1])
        v2 = (c[0] - b[0], c[1] - b[1])
        l1 = max(1.0, (v1[0] ** 2 + v1[1] ** 2) ** 0.5)
        l2 = max(1.0, (v2[0] ** 2 + v2[1] ** 2) ** 0.5)
        dot = ((v1[0] / l1) * (v2[0] / l2)) + ((v1[1] / l1) * (v2[1] / l2))
        if dot < 0.82:
            bends.append(b)
    return bends


def is_texture_suppressed(px, py, config, padding=0):
    for sx, sy in config["slots"]:
        cx = sx * CELL_W
        cy = sy * CELL_H
        dx = cx - px
        dy = cy - py
        if (dx * dx + dy * dy) ** 0.5 <= 30 + padding:
            return True
    for path, x, y, scale, _ in config["decor"]:
        is_landmark = "landmarks" in path
        base_size = 86 if is_landmark else 44
        radius = (base_size * scale * 0.42) + padding
        cx = x * CELL_W
        cy = y * CELL_H
        dx = cx - px
        dy = cy - py
        if (dx * dx + dy * dy) ** 0.5 <= radius:
            return True
    return False


def draw_anchor_cluster(draw, theme, center):
    palette = PATH_COLORS[theme]
    shadow = palette["shadow"]
    detail = palette["detail"]
    px, py = center
    if theme == "frontier":
        draw.ellipse((px - 18, py - 5, px + 10, py + 5), fill=shadow)
        draw.ellipse((px - 1, py - 3, px + 18, py + 4), fill=shadow)
        draw.ellipse((px + 7, py - 6, px + 11, py - 2), fill=detail)
        draw.ellipse((px - 13, py + 4, px - 9, py + 8), fill=detail)
    elif theme == "bandit":
        draw.rectangle((px - 14, py - 4, px + 4, py + 4), fill=shadow)
        draw.rectangle((px + 4, py + 1, px + 15, py + 5), fill=shadow)
        draw.rectangle((px + 7, py - 4, px + 13, py - 2), fill=detail)
    elif theme == "grave":
        draw.ellipse((px - 10, py - 5, px - 2, py + 3), fill=shadow)
        draw.ellipse((px + 2, py - 2, px + 9, py + 4), fill=shadow)
        draw.rectangle((px + 4, py - 5, px + 14, py - 3), fill=detail)
        draw.rectangle((px - 13, py + 4, px - 6, py + 6), fill=detail)
    elif theme == "chapel":
        draw.rounded_rectangle((px - 12, py - 4, px + 2, py + 5), radius=3, fill=shadow)
        draw.rounded_rectangle((px + 3, py - 5, px + 12, py + 1), radius=2, fill=detail)
        draw.ellipse((px + 9, py + 4, px + 13, py + 8), fill=detail)
    elif theme == "bastion":
        draw.rectangle((px - 13, py - 4, px + 1, py + 4), fill=shadow)
        draw.rectangle((px + 2, py - 3, px + 11, py + 3), fill=shadow)
        draw.rectangle((px - 6, py - 6, px + 8, py - 4), fill=detail)
    else:
        draw.ellipse((px - 14, py - 4, px + 2, py + 4), fill=shadow)
        draw.ellipse((px + 2, py + 1, px + 12, py + 5), fill=shadow)
        draw.ellipse((px + 6, py - 6, px + 10, py - 2), fill=detail)
        draw.ellipse((px - 11, py + 4, px - 8, py + 7), fill=detail)


def draw_path(draw, points, theme, config):
    scaled = [(x * CELL_W, y * CELL_H) for x, y in points]
    palette = PATH_COLORS[theme]
    draw.line(scaled, fill=palette["glow"], width=18, joint="curve")
    draw.line(scaled, fill=palette["base"], width=12, joint="curve")
    for px, py in sample_path_points(points):
        if is_texture_suppressed(px, py, config, padding=10):
            continue
        if theme == "frontier":
            draw.ellipse((px - 9, py - 3, px + 9, py + 3), fill=palette["shadow"])
            draw.ellipse((px + 4, py - 2, px + 7, py + 1), fill=palette["detail"])
        elif theme == "bandit":
            draw.rectangle((px - 7, py - 3, px + 7, py + 3), fill=palette["shadow"])
            draw.rectangle((px + 2, py - 2, px + 6, py), fill=palette["detail"])
        elif theme == "grave":
            draw.ellipse((px - 4, py - 4, px + 4, py + 4), fill=palette["shadow"])
            draw.rectangle((px, py - 2, px + 8, py), fill=palette["detail"])
        elif theme == "chapel":
            draw.ellipse((px - 4, py - 4, px + 4, py + 4), fill=palette["shadow"])
            draw.ellipse((px, py - 3, px + 3, py), fill=palette["detail"])
        elif theme == "bastion":
            draw.rectangle((px - 6, py - 3, px + 6, py + 3), fill=palette["shadow"])
            draw.rectangle((px - 4, py - 2, px + 4, py), fill=palette["detail"])
        else:
            draw.ellipse((px - 7, py - 3, px + 7, py + 3), fill=palette["shadow"])
            draw.ellipse((px - 5, py - 2, px - 2, py + 1), fill=palette["detail"])
            draw.ellipse((px + 2, py - 1, px + 4, py + 1), fill=palette["detail"])
    draw_anchor_cluster(draw, theme, scaled[0])
    draw_anchor_cluster(draw, theme, scaled[-1])
    for bend in major_bend_points(points):
        if is_texture_suppressed(bend[0], bend[1], config, padding=8):
            continue
        draw_anchor_cluster(draw, theme, bend)


def draw_slots(draw, points):
    for x, y in points:
        cx = x * CELL_W
        cy = y * CELL_H
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), outline=(232, 201, 123, 230), width=2, fill=(123, 99, 50, 40))


def paste_scaled(base, asset_path, x, y, scale):
    img = Image.open(asset_path).convert("RGBA")
    is_landmark = "landmarks" in asset_path.parts
    target = int((86 if is_landmark else 44) * scale)
    resized = img.resize((target, target), Image.Resampling.NEAREST)
    px = int(x * CELL_W - target / 2)
    py = int(y * CELL_H - target / 2)
    base.alpha_composite(resized, (px, py))


def render_stage(config):
    canvas = gradient_background(config["theme"])
    draw = ImageDraw.Draw(canvas)
    draw_ground_texture(draw, config["theme"], config)
    bg = [item for item in config["decor"] if item[4] == "bg"]
    fg = [item for item in config["decor"] if item[4] == "fg"]
    for path, x, y, scale, _ in bg:
        paste_scaled(canvas, SPRITES / path, x, y, scale)
    draw_path(draw, config["path"], config["theme"], config)
    draw_slots(draw, config["slots"])
    for path, x, y, scale, _ in fg:
        paste_scaled(canvas, SPRITES / path, x, y, scale)
    draw.text((10, 8), config["label"], fill=(245, 240, 232, 255))
    return canvas


def main():
    sheet = Image.new("RGBA", (CELL_W * 2, CELL_H * 3), (14, 14, 14, 255))
    for i, config in enumerate(CREST_STAGES):
        scene = render_stage(config)
        x = (i % 2) * CELL_W
        y = (i // 2) * CELL_H
        sheet.alpha_composite(scene, (x, y))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
