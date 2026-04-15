import asyncio, zipfile, io, json
from pathlib import Path
from PIL import Image
from playwright.async_api import async_playwright

OUTPUT_DIR   = Path(__file__).parent.parent / "assets" / "sprites" / "enemies"
DOWNLOAD_TMP = Path(__file__).parent.parent / "tmp" / "lpc_downloads"
LPC_URL      = "https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/"
DIRECTION_ROW = {"south": 0, "west": 1, "north": 3}
FRAME_COL     = {"base": 4, "walk_02": 2, "walk_03": 6}

ENEMY_NAME = "bastion_overlord"
ITEMS = [
    ("torso_armour_plate",         "gold"),
    ("hat_helmet_horned",          "gold"),
    ("hat_visor_horned",           "gold"),
    ("hat_accessory_horns_upward", ""),
    ("shoulders_plate",            "gold"),
    ("weapon_sword_arming",        ""),
    ("cape_solid",                 "red"),
]


async def run():
    DOWNLOAD_TMP.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False, slow_mo=100)
        context = await browser.new_context(accept_downloads=True)
        page    = await context.new_page()

        print("Navigating to LPC site...")
        await page.goto(LPC_URL, wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(3000)

        print("Resetting character...")
        await page.evaluate("window.setDefaultSelections ? window.setDefaultSelections() : null")
        await page.wait_for_timeout(1000)
        await page.evaluate("""
            async () => {
                const mod = await import('./sources/state/state.js');
                if (mod.resetAll) await mod.resetAll();
                window._selectItem = mod.selectItem;
            }
        """)
        await page.wait_for_timeout(1000)

        for item_id, variant in ITEMS:
            r = await page.evaluate(f"""
                async () => {{
                    if (!window._selectItem) {{
                        const mod = await import('./sources/state/state.js');
                        window._selectItem = mod.selectItem;
                    }}
                    window._selectItem('{item_id}', '{variant}');
                    return 'ok: {item_id}';
                }}
            """)
            print(f"  {r}")
            await page.wait_for_timeout(300)

        await page.wait_for_timeout(1500)

        zip_path = DOWNLOAD_TMP / f"{ENEMY_NAME}.zip"
        print("Downloading ZIP...")
        async with page.expect_download(timeout=30000) as dl_info:
            await page.evaluate("""
                () => {
                    const btns = Array.from(document.querySelectorAll('button, input[type=button]'));
                    const z = btns.find(b => b.textContent && b.textContent.includes('ZIP') && b.textContent.includes('Split'));
                    if (z) { z.click(); return; }
                    const z2 = btns.find(b => b.textContent && b.textContent.toLowerCase().includes('zip'));
                    if (z2) z2.click();
                }
            """)
        dl = await dl_info.value
        await dl.save_as(str(zip_path))
        print(f"Saved: {zip_path.stat().st_size:,} bytes")

        with zipfile.ZipFile(zip_path) as zf:
            sheet = Image.open(io.BytesIO(zf.read("standard/walk.png")))
        print(f"Sheet: {sheet.size}")

        out_base = OUTPUT_DIR / ENEMY_NAME
        for direction, row in DIRECTION_ROW.items():
            d = out_base / direction
            d.mkdir(parents=True, exist_ok=True)
            for fk, col in FRAME_COL.items():
                x, y = col * 64, row * 64
                sheet.crop((x, y, x + 64, y + 64)).save(str(d / f"{fk}.png"), "PNG")

        meta = {
            "id": ENEMY_NAME,
            "description": "Boss overlord, gold horned plate, visor, upward horns, solid red cape",
            "lpc_items": ITEMS,
            "direction_rows": DIRECTION_ROW,
            "frame_cols": FRAME_COL,
            "east_direction": "runtime_mirrored_from_west",
            "attribution": "Universal LPC Spritesheet Character Generator"
        }
        (out_base / "metadata.json").write_text(json.dumps(meta, indent=2))
        (out_base / "credits.txt").write_text(
            "Source: Universal LPC Spritesheet Character Generator\n"
            "URL: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/\n"
            "License: CC-BY-SA 3.0 / GPL 3.0\n"
        )
        print("[DONE] bastion_overlord: 9 frames extracted")
        await browser.close()


if __name__ == "__main__":
    asyncio.run(run())
