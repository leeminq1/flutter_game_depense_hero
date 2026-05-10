from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "raw_file"
OUT_DIR = ROOT / "screenshots"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FONT_BOLD_CANDIDATES = [
    Path("C:/Windows/Fonts/malgunbd.ttf"),
    Path("C:/Windows/Fonts/malgun.ttf"),
    Path("C:/Windows/Fonts/NanumGothicBold.ttf"),
]
FONT_REGULAR_CANDIDATES = [
    Path("C:/Windows/Fonts/malgun.ttf"),
    Path("C:/Windows/Fonts/NanumGothic.ttf"),
]

FONT_BOLD = next((path for path in FONT_BOLD_CANDIDATES if path.exists()), None)
FONT_REGULAR = next((path for path in FONT_REGULAR_CANDIDATES if path.exists()), FONT_BOLD)

if FONT_BOLD is None:
    raise SystemExit("No Korean-capable font found.")


def fit_font(text: str, start_size: int, max_width: int, *, bold: bool) -> ImageFont.FreeTypeFont:
    font_path = FONT_BOLD if bold else FONT_REGULAR
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for size in range(start_size, 20, -2):
        font = ImageFont.truetype(str(font_path), size)
        if probe.textbbox((0, 0), text, font=font)[2] <= max_width:
            return font
    return ImageFont.truetype(str(font_path), 22)


def draw_panel(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], radius: int) -> None:
    draw.rounded_rectangle(
        xy,
        radius=radius,
        fill=(7, 20, 33, 218),
        outline=(75, 255, 174, 70),
        width=2,
    )


def add_caption(
    image: Image.Image,
    *,
    kicker: str,
    title: str,
    body: str,
    align: str,
) -> Image.Image:
    base = image.convert("RGB")
    width, height = base.size
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    if align == "bottom":
        start_y, end_y = height - 560, height - 88
        for y in range(start_y, end_y):
            alpha = int(222 * ((y - start_y) / max(1, end_y - start_y)))
            draw.line([(0, y), (width, y)], fill=(3, 9, 16, alpha))
        panel = (64, height - 480, width - 64, height - 130)
    else:
        start_y, end_y = 0, 520
        for y in range(start_y, end_y):
            alpha = int(224 * (1 - (y / max(1, end_y))))
            draw.line([(0, y), (width, y)], fill=(3, 9, 16, alpha))
        panel = (64, 112, width - 64, 462)

    draw_panel(draw, panel, 34)

    x = panel[0] + 42
    y = panel[1] + 34
    max_text_width = panel[2] - panel[0] - 84

    kicker_font = fit_font(kicker, 30, max_text_width, bold=False)
    title_font = fit_font(title, 66, max_text_width, bold=True)
    body_font = fit_font(body, 34, max_text_width, bold=False)

    kicker_bbox = draw.textbbox((0, 0), kicker, font=kicker_font)
    pill_width = kicker_bbox[2] + 42
    draw.rounded_rectangle((x, y, x + pill_width, y + 48), radius=24, fill=(57, 229, 154, 235))
    draw.text((x + 21, y + 7), kicker, font=kicker_font, fill=(4, 18, 19, 255))

    y += 72
    draw.text(
        (x, y),
        title,
        font=title_font,
        fill=(245, 255, 250, 255),
        stroke_width=2,
        stroke_fill=(0, 0, 0, 120),
    )
    y += 92
    draw.text((x, y), body, font=body_font, fill=(205, 226, 237, 255), spacing=8)

    brand = "PIXEL GUARD:WAVE"
    brand_font = fit_font(brand, 24, 320, bold=False)
    brand_bbox = draw.textbbox((0, 0), brand, font=brand_font)
    draw.text(
        (panel[2] - (brand_bbox[2] - brand_bbox[0]) - 42, panel[3] - 50),
        brand,
        font=brand_font,
        fill=(144, 176, 191, 235),
    )

    return Image.alpha_composite(base.convert("RGBA"), overlay).convert("RGB")


SCREENSHOTS = [
    {
        "src": "KakaoTalk_20260510_113516405.jpg",
        "kicker": "비공개 테스트",
        "title": "성채를 지켜라",
        "body": "짧고 전술적인 픽셀 공성 방어",
        "align": "bottom",
        "out": "phone-screenshot-01-title.png",
    },
    {
        "src": "KakaoTalk_20260510_113516405_01.jpg",
        "kicker": "캠페인",
        "title": "캠페인을 준비하라",
        "body": "스테이지를 선택하고 다음 전투를 계획",
        "align": "bottom",
        "out": "phone-screenshot-02-camp.png",
    },
    {
        "src": "KakaoTalk_20260510_113516405_02.jpg",
        "kicker": "영웅 선택",
        "title": "영웅을 선택하라",
        "body": "역할이 다른 수비 전력으로 전장을 설계",
        "align": "bottom",
        "out": "phone-screenshot-03-hero.png",
    },
    {
        "src": "KakaoTalk_20260510_113516405_07.jpg",
        "kicker": "브리핑",
        "title": "공성 정보를 확인하라",
        "body": "적 경로와 웨이브를 읽고 방어선을 구축",
        "align": "top",
        "out": "phone-screenshot-04-briefing.png",
    },
    {
        "src": "KakaoTalk_20260510_113516405_14.jpg",
        "kicker": "전투",
        "title": "모든 전선을 버텨라",
        "body": "타워와 벽으로 몰려오는 웨이브를 저지",
        "align": "top",
        "out": "phone-screenshot-05-battle.png",
    },
]


def main() -> None:
    generated = []
    for spec in SCREENSHOTS:
        source = Image.open(RAW_DIR / spec["src"])
        output = add_caption(
            source,
            kicker=spec["kicker"],
            title=spec["title"],
            body=spec["body"],
            align=spec["align"],
        )
        if output.size != source.size:
            raise SystemExit(f"Size changed for {spec['out']}")
        out_path = OUT_DIR / spec["out"]
        output.save(out_path, format="PNG", optimize=True)
        generated.append(out_path)

    contact = Image.new("RGB", (5 * 260 + 20, 700), (24, 24, 28))
    draw = ImageDraw.Draw(contact)
    label_font = ImageFont.truetype(str(FONT_REGULAR), 18)
    for index, path in enumerate(generated):
        preview = Image.open(path).convert("RGB")
        preview.thumbnail((240, 586), Image.Resampling.LANCZOS)
        x = 20 + index * 260
        contact.paste(preview, (x + (240 - preview.width) // 2, 20))
        draw.text((x, 622), path.name, fill=(235, 235, 235), font=label_font)
        draw.text((x, 648), f"{Image.open(path).size[0]}x{Image.open(path).size[1]}", fill=(180, 180, 180), font=label_font)
    contact_path = ROOT.parents[2] / "tmp" / "google-play-polished-screenshots.jpg"
    contact_path.parent.mkdir(parents=True, exist_ok=True)
    contact.save(contact_path, quality=92)

    for path in generated:
        print(path)
    print(contact_path)


if __name__ == "__main__":
    main()
