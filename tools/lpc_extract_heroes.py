"""
LPC Hero Sprite Generator - Python + Playwright (Clipboard JSON Import)
Generates sprites for 5 heroes using LPC site's "Import from Clipboard (JSON)" API.

sources/state/state.js is 404 on the new Vite build — use clipboard import instead.

walk.png layout (832x256 = 13 cols x 4 rows of 64x64):
  Row 0 (y=0):   NORTH / Up
  Row 1 (y=64):  WEST / Left
  Row 2 (y=128): SOUTH / Down
  Row 3 (y=192): EAST / Right  (runtime-mirrored, skipped)

Frame columns (0-indexed):
  base    = col 4 (x=256)
  walk_02 = col 2 (x=128)
  walk_03 = col 6 (x=384)
"""

import asyncio
import zipfile
import io
import json
from pathlib import Path
from PIL import Image
from playwright.async_api import async_playwright

OUTPUT_DIR   = Path(__file__).parent.parent / "assets" / "sprites" / "heroes"
DOWNLOAD_TMP = Path(__file__).parent.parent / "tmp" / "lpc_hero_downloads"
LPC_URL      = "https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/"

DIRECTION_ROW = {"north": 0, "west": 1, "south": 2}
FRAME_COL     = {"base": 4, "walk_02": 2, "walk_03": 6}
TARGET_DIRECTIONS = ["south", "west", "north"]
SPLIT_DIR = {"north": "up", "west": "left", "south": "down"}

# Each item: (item_id, variant, recolor)
HEROES = {
    "knight": {
        "body_type": "muscular",
        "description": "Full plate knight, gold armor, blue cape, kite shield",
        "items": [
            ("torso_armour_plate",  "",         "gold"),
            ("shoulders_plate",     "",         "gold"),
            ("hat_helmet_close",    "",         "gold"),
            ("weapon_sword_arming", "",         ""),
            ("shield_kite",         "",         ""),
            ("cape_solid",          "",         "blue"),
        ],
    },
    "archer": {
        "body_type": "female",
        "description": "Elf ranger, forest leather, bow, pointed ears",
        "items": [
            ("head_ears_elven",          "",  ""),
            ("torso_armour_leather",     "",  "forest"),
            ("shoulders_leather",        "",  "forest"),
            ("weapon_ranged_bow_normal", "",  ""),
            ("belt_double",              "",  ""),
            ("cape_solid",               "",  "forest"),
        ],
    },
    "mage": {
        "body_type": "male",
        "description": "Fire wizard, red robe, black hood, magic staff, red cape",
        "items": [
            ("torso_clothes_robe",  "",           "red"),
            ("shoulders_mantal",    "",           "maroon"),
            ("hat_hood_cloth",      "hood_black", ""),
            ("weapon_magic_loop",   "",           ""),
            ("belt_mage",           "",           ""),
            ("cape_solid",          "",           "red"),
        ],
    },
    "paladin": {
        "body_type": "male",
        "description": "Holy cleric, legion armor, gold helm, mace, white cape",
        "items": [
            ("torso_armour_legion", "",  ""),
            ("shoulders_legion",    "",  ""),
            ("hat_helmet_legion",   "",  "gold"),
            ("weapon_blunt_mace",   "",  ""),
            ("belt_mage",           "",  ""),
            ("cape_solid",          "",  "white"),
        ],
    },
    "ninja": {
        "body_type": "teen",
        "description": "Crimson assassin, dark hood, daggers, red cape",
        "items": [
            ("torso_armour_leather", "",           "brown"),
            ("hat_hood_cloth",       "hood_black", ""),
            ("belt_double",          "",           ""),
            ("weapon_sword_dagger",  "",           ""),
            ("cape_solid",           "",           "red"),
        ],
    },
}


def build_json_config(hero_id: str, hero: dict) -> dict:
    """Build v2 JSON config for LPC clipboard import."""
    selections = {}
    for i, (item_id, variant, recolor) in enumerate(hero["items"]):
        selections[f"item_{i}"] = {
            "itemId": item_id,
            "variant": variant,
            "recolor": recolor,
        }
    return {
        "version": 2,
        "bodyType": hero["body_type"],
        "selections": selections,
        "selectedAnimation": "walk",
    }


async def configure_and_download(page, hero_id: str, hero: dict, download_dir: Path) -> Path:
    """Import hero config via clipboard JSON and download split ZIP."""
    config = build_json_config(hero_id, hero)

    print(f"  Resetting defaults...")
    await page.evaluate("() => window.setDefaultSelections()")
    await page.wait_for_timeout(2000)

    print(f"  Writing config to clipboard...")
    await page.evaluate("(cfg) => navigator.clipboard.writeText(JSON.stringify(cfg))", config)
    await page.wait_for_timeout(500)

    print(f"  Importing from clipboard...")
    await page.get_by_text("Import from Clipboard (JSON)").click()
    await page.wait_for_timeout(4000)

    print(f"  Downloading ZIP...")
    download_dir.mkdir(parents=True, exist_ok=True)
    zip_path = download_dir / f"{hero_id}.zip"

    async with page.expect_download(timeout=60000) as dl_info:
        await page.get_by_text("ZIP: Split by animation and frame").click()
    download = await dl_info.value
    await download.save_as(str(zip_path))
    size = zip_path.stat().st_size
    print(f"  Saved ZIP: {zip_path} ({size} bytes)")
    return zip_path


def extract_frames(zip_path: Path, hero_id: str) -> dict:
    """Crop 64x64 frames from standard/walk.png (832x256)."""
    out_base = OUTPUT_DIR / hero_id
    extracted = {}

    with zipfile.ZipFile(zip_path, "r") as zf:
        names = zf.namelist()
        walk_candidates = [n for n in names if "walk.png" in n and "standard" in n]
        print(f"  Walk PNG candidates: {walk_candidates}")

        walk_key = "standard/walk.png"
        if walk_key in names:
            sheet = Image.open(io.BytesIO(zf.read(walk_key)))
            w, h = sheet.size
            print(f"  walk.png: {w}x{h}, mode={sheet.mode}")
        else:
            sheet = None
            print("  Using split standard/walk/{direction}/{frame}.png frames")

    for direction in TARGET_DIRECTIONS:
        dir_out = out_base / direction
        dir_out.mkdir(parents=True, exist_ok=True)

        for frame_key, col in FRAME_COL.items():
            if sheet is not None:
                row = DIRECTION_ROW[direction]
                x = col * 64
                y = row * 64
                frame = sheet.crop((x, y, x + 64, y + 64))
            else:
                split_key = f"standard/walk/{SPLIT_DIR[direction]}/{col + 1}.png"
                if split_key not in names:
                    raise FileNotFoundError(f"{split_key} not in ZIP")
                with zipfile.ZipFile(zip_path, "r") as frame_zf:
                    frame = Image.open(io.BytesIO(frame_zf.read(split_key))).convert("RGBA")
            out_file = dir_out / f"{frame_key}.png"
            frame.save(str(out_file), "PNG")
            extracted[f"{direction}/{frame_key}"] = str(out_file)
            print(f"    {direction}/{frame_key}.png (col={col})")

    return extracted


def write_metadata(hero_id: str, hero: dict, extracted: dict):
    out_base = OUTPUT_DIR / hero_id
    metadata = {
        "id": hero_id,
        "description": hero["description"],
        "body_type": hero["body_type"],
        "lpc_items": [
            {"item_id": item_id, "variant": variant, "recolor": recolor}
            for item_id, variant, recolor in hero["items"]
        ],
        "frame_layout": {
            "spritesheet": "standard/walk.png (832x256)",
            "directions": DIRECTION_ROW,
            "frames": {k: {"col": v, "x": v * 64} for k, v in FRAME_COL.items()},
        },
        "east_direction": "runtime_mirrored_from_west",
        "extracted_files": extracted,
        "attribution": "Universal LPC Spritesheet Character Generator",
        "url": LPC_URL,
    }
    (out_base / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    (out_base / "credits.txt").write_text(
        f"Hero: {hero_id}\n"
        f"Description: {hero['description']}\n"
        f"Source: Universal LPC Spritesheet Character Generator\n"
        f"URL: {LPC_URL}\n"
        f"License: CC-BY-SA 3.0 / GPL 3.0 (see generator credits page)\n"
        f"Items: {', '.join(i[0] for i in hero['items'])}\n",
        encoding="utf-8",
    )
    print(f"  Wrote metadata.json and credits.txt")


async def process_hero(browser, hero_id: str, hero: dict):
    print(f"\n{'='*55}")
    print(f"Processing: {hero_id}  [{hero['body_type']}]")
    print(f"  {hero['description']}")

    context = await browser.new_context(
        permissions=["clipboard-read", "clipboard-write"]
    )
    page = await context.new_page()

    try:
        await page.goto(LPC_URL, wait_until="networkidle", timeout=60000)
        await page.wait_for_function(
            "() => typeof window.setDefaultSelections === 'function'",
            timeout=30000,
        )
        await page.wait_for_timeout(3000)

        zip_path = await configure_and_download(page, hero_id, hero, DOWNLOAD_TMP)
        extracted = extract_frames(zip_path, hero_id)
        write_metadata(hero_id, hero, extracted)
        print(f"  DONE: {len(extracted)} frames for {hero_id}")
        return extracted

    except Exception as e:
        print(f"  ERROR [{hero_id}]: {e}")
        import traceback
        traceback.print_exc()
        return {}
    finally:
        await context.close()


async def main():
    DOWNLOAD_TMP.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output: {OUTPUT_DIR}")
    print(f"Heroes: {', '.join(HEROES.keys())}")

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)

        results = {}
        for hero_id, hero in HEROES.items():
            result = await process_hero(browser, hero_id, hero)
            results[hero_id] = result

        await browser.close()

    print(f"\n{'='*55}")
    print("COMPLETE")
    for hero_id, frames in results.items():
        status = "OK" if frames else "FAILED"
        print(f"  [{status}] {hero_id}: {len(frames)} frames")


if __name__ == "__main__":
    asyncio.run(main())
