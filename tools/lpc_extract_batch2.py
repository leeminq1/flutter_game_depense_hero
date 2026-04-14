"""
LPC Character Generator - Batch 2 Enemy 4-Direction Sprite Extractor
Enemies: banner_captain, wolf_scout, skeleton, bone_archer,
         plague_bearer, corrupted_knight, hex_sniper, bastion_priest

walk.png layout (832x256 = 13 cols x 4 rows of 64x64):
  Row 0 (y=0):   SOUTH / Down
  Row 1 (y=64):  WEST  / Left
  Row 2 (y=128): EAST  / Right  (runtime-mirrored, skipped)
  Row 3 (y=192): NORTH / Up

Frame columns (0-indexed):
  base    = col 4
  walk_02 = col 2
  walk_03 = col 6
"""

import asyncio
import zipfile
import io
import json
from pathlib import Path
from PIL import Image
from playwright.async_api import async_playwright

OUTPUT_DIR   = Path(__file__).parent.parent / "assets" / "sprites" / "enemies"
DOWNLOAD_TMP = Path(__file__).parent.parent / "tmp" / "lpc_downloads"
LPC_URL      = "https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/"

DIRECTION_ROW = {"south": 0, "west": 1, "north": 3}
FRAME_COL     = {"base": 4, "walk_02": 2, "walk_03": 6}

ENEMIES = {
    "banner_captain": {
        "items": [
            ("torso_armour_leather",          "brown"),
            ("shoulders_leather",             ""),
            ("belt_double",                   ""),
            ("hat_bicorne_athwart_captain",   ""),
            ("hat_accessory_plumage_centurion", ""),
            ("weapon_polearm_spear",          ""),
            ("cape_tattered",                 "red"),
        ],
        "description": "early support leader, captain hat, red tattered cape, spear",
    },
    "wolf_scout": {
        "items": [
            ("heads_wolf_male",       ""),
            ("head_ears_wolf",        ""),
            ("tail_wolf",             ""),
            ("torso_armour_leather",  "forest"),
            ("shoulders_leather",     ""),
            ("belt_double",           ""),
            ("weapon_ranged_bow_normal", ""),
        ],
        "description": "beastfolk speed threat, wolf head, forest leather, bow",
    },
    "skeleton": {
        "items": [
            ("body_skeleton",         ""),
            ("heads_skeleton",        ""),
            ("weapon_sword_dagger",   ""),
        ],
        "description": "basic undead runner, bare skeleton, dagger",
    },
    "bone_archer": {
        "items": [
            ("body_skeleton",             ""),
            ("heads_skeleton",            ""),
            ("weapon_ranged_bow_normal",  ""),
            ("belt_leather",              ""),
            ("cape_tattered",             "charcoal"),
        ],
        "description": "undead skirmisher, skeleton body, bow, charcoal tattered cape",
    },
    "plague_bearer": {
        "items": [
            ("torso_clothes_robe",    "forest"),
            ("hat_hood_cloth",        "charcoal"),
            ("shoulders_mantal",      ""),
            ("weapon_magic_gnarled",  ""),
            ("belt_robe",             ""),
            ("cape_solid",            "forest"),
        ],
        "description": "undead sustain support, green robe, charcoal hood, gnarled staff",
    },
    "corrupted_knight": {
        "items": [
            ("torso_armour_plate",    "iron"),
            ("hat_helmet_horned",     "iron"),
            ("hat_visor_horned",      "iron"),
            ("weapon_sword_arming",   ""),
            ("shield_kite",           ""),
            ("cape_tattered",         "maroon"),
            ("shoulders_plate",       "iron"),
        ],
        "description": "fallen elite, horned iron plate, kite shield, maroon tattered cape",
    },
    "hex_sniper": {
        "items": [
            ("torso_clothes_robe",    "charcoal"),
            ("hat_hood_cloth",        "charcoal"),
            ("shoulders_mantal",      ""),
            ("weapon_ranged_crossbow", ""),
            ("belt_mage",             ""),
            ("cape_solid",            "purple"),
        ],
        "description": "cursed ranged disruptor, charcoal robe, crossbow, purple solid cape",
    },
    "bastion_priest": {
        "items": [
            ("torso_armour_legion",   ""),
            ("shoulders_legion",      ""),
            ("hat_helmet_legion",     "gold"),
            ("weapon_blunt_mace",     ""),
            ("belt_mage",             ""),
            ("cape_solid",            "white"),
        ],
        "description": "plated elite support, gold legion helm, white cape, mace",
    },
}


async def configure_character(page, items):
    print("  Resetting site...")
    await page.wait_for_timeout(3000)
    await page.evaluate("window.setDefaultSelections ? window.setDefaultSelections() : null")
    await page.wait_for_timeout(1000)
    reset = await page.evaluate("""
        async () => {
            try {
                const mod = await import('./sources/state/state.js');
                if (mod.resetAll) await mod.resetAll();
                window._selectItem = mod.selectItem;
                return 'ok';
            } catch(e) { return 'error: ' + e.message; }
        }
    """)
    print(f"  Reset: {reset}")
    await page.wait_for_timeout(1000)

    for item_id, variant in items:
        result = await page.evaluate(f"""
            async () => {{
                try {{
                    if (!window._selectItem) {{
                        const mod = await import('./sources/state/state.js');
                        window._selectItem = mod.selectItem;
                    }}
                    window._selectItem('{item_id}', '{variant}');
                    return 'ok: {item_id}';
                }} catch(e) {{ return 'err {item_id}: ' + e.message; }}
            }}
        """)
        print(f"  {result}")
        await page.wait_for_timeout(300)

    await page.wait_for_timeout(1500)


async def download_zip(page, enemy_name):
    zip_path = DOWNLOAD_TMP / f"{enemy_name}.zip"
    print(f"  Downloading ZIP...")
    async with page.expect_download(timeout=30000) as dl_info:
        await page.evaluate("""
            () => {
                const btns = Array.from(document.querySelectorAll('button, input[type=button]'));
                const zipBtn = btns.find(b => b.textContent && b.textContent.includes('ZIP') && b.textContent.includes('Split'));
                if (zipBtn) { zipBtn.click(); return; }
                const anyZip = btns.find(b => b.textContent && b.textContent.toLowerCase().includes('zip'));
                if (anyZip) anyZip.click();
            }
        """)
    dl = await dl_info.value
    await dl.save_as(str(zip_path))
    print(f"  Saved: {zip_path.name} ({zip_path.stat().st_size:,} bytes)")
    return zip_path


def extract_frames(zip_path, enemy_name):
    out_base = OUTPUT_DIR / enemy_name
    with zipfile.ZipFile(zip_path) as zf:
        walk_data = zf.read("standard/walk.png")
    sheet = Image.open(io.BytesIO(walk_data))
    print(f"  Sheet: {sheet.size}")

    for direction, row in DIRECTION_ROW.items():
        dir_out = out_base / direction
        dir_out.mkdir(parents=True, exist_ok=True)
        for frame_key, col in FRAME_COL.items():
            x, y = col * 64, row * 64
            frame = sheet.crop((x, y, x + 64, y + 64))
            frame.save(str(dir_out / f"{frame_key}.png"), "PNG")
    print(f"  Extracted 9 frames (3 dirs x 3 frames)")


def write_metadata(enemy_name, enemy_data):
    out_base = OUTPUT_DIR / enemy_name
    meta = {
        "id": enemy_name,
        "description": enemy_data["description"],
        "lpc_items": enemy_data["items"],
        "direction_rows": DIRECTION_ROW,
        "frame_cols": FRAME_COL,
        "east_direction": "runtime_mirrored_from_west",
        "attribution": "Universal LPC Spritesheet Character Generator - https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/",
    }
    (out_base / "metadata.json").write_text(json.dumps(meta, indent=2))
    (out_base / "credits.txt").write_text(
        f"Enemy: {enemy_name}\n"
        "Source: Universal LPC Spritesheet Character Generator\n"
        "URL: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/\n"
        "License: CC-BY-SA 3.0 / GPL 3.0\n"
    )


async def process_enemy(browser, enemy_name, enemy_data):
    print(f"\n{'='*55}")
    print(f"  {enemy_name}  --  {enemy_data['description']}")
    context = await browser.new_context(accept_downloads=True)
    page = await context.new_page()
    try:
        await page.goto(LPC_URL, wait_until="networkidle", timeout=30000)
        await configure_character(page, enemy_data["items"])
        zip_path = await download_zip(page, enemy_name)
        extract_frames(zip_path, enemy_name)
        write_metadata(enemy_name, enemy_data)
        print(f"  [DONE]: {enemy_name}")
    except Exception as e:
        print(f"  [ERROR]: {enemy_name}: {e}")
    finally:
        await context.close()


async def main():
    DOWNLOAD_TMP.mkdir(parents=True, exist_ok=True)
    print(f"Batch 2: {len(ENEMIES)} enemies")
    print(f"Output: {OUTPUT_DIR}")

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False, slow_mo=100)
        for name, data in ENEMIES.items():
            await process_enemy(browser, name, data)
        await browser.close()

    print(f"\n{'='*55}")
    print("BATCH 2 COMPLETE")
    for name in ENEMIES:
        frames = list((OUTPUT_DIR / name).rglob("*.png"))
        print(f"  {name:20s}: {len(frames)} PNGs")


if __name__ == "__main__":
    asyncio.run(main())
