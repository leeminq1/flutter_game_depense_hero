"""
LPC Character Generator - Batch 1 Enemy 4-Direction Sprite Extractor
Uses Playwright + PIL to automate the LPC site, download walk.png (832x256),
then crop 64x64 frames from the correct row/column for each direction.

walk.png layout (4 rows x 13 cols of 64x64 each):
  Row 0 (y=0):   SOUTH / Down  (walking toward viewer)
  Row 1 (y=64):  WEST  / Left  (walking left)
  Row 2 (y=128): EAST  / Right (walking right - runtime mirror in MVP)
  Row 3 (y=192): NORTH / Up    (walking away from viewer)

Frame indices within each row (0-indexed):
  base    -> col 4 (frame /5 in 1-indexed LPC naming)
  walk_02 -> col 2 (frame /3)
  walk_03 -> col 6 (frame /7)
"""

import asyncio
import zipfile
import io
import json
import shutil
from pathlib import Path
from playwright.async_api import async_playwright

# Output directory (relative to project root)
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "sprites" / "enemies"
DOWNLOAD_TMP = Path(__file__).parent.parent / "tmp" / "lpc_downloads"

# Frame layout in walk.png: row index per direction, column index per frame name
# walk.png is 832x256 (13 cols x 4 rows of 64x64 frames)
DIRECTION_ROW = {
    "south": 0,  # Row 0: walking toward viewer
    "west":  1,  # Row 1: walking left
    "east":  2,  # Row 2: walking right (runtime-mirrored in MVP, skip for now)
    "north": 3,  # Row 3: walking away from viewer
}
FRAME_COL = {
    "base":    4,  # col 4 = LPC frame /5 (neutral planted)
    "walk_02": 2,  # col 2 = LPC frame /3
    "walk_03": 6,  # col 6 = LPC frame /7
}
TARGET_DIRECTIONS = ["west", "north", "south"]  # east is runtime-mirrored

# Batch 1 enemy recipes (item_id -> variant, '' for no variant)
ENEMIES = {
    "raider": {
        "items": [
            ("torso_armour_leather", "brown"),
            ("hat_hood_cloth", "brown"),
            ("weapon_sword_dagger", ""),
            ("cape_tattered", "maroon"),
            ("belt_leather", ""),
        ],
        "body": "male",
        "description": "fast melee bandit, brown leather, maroon tattered cape, dagger"
    },
    "scout": {
        "items": [
            ("torso_armour_leather", "forest"),
            ("hat_hood_cloth", "forest"),
            ("weapon_ranged_bow_normal", ""),
            ("belt_double", ""),
        ],
        "body": "male",
        "description": "mobile ranged, forest leather, bow"
    },
    "shield_infantry": {
        "items": [
            ("torso_armour_plate", "steel"),
            ("hat_helmet_legion", "steel"),
            ("weapon_sword_arming", ""),
            ("shield_round", ""),
        ],
        "body": "male",
        "description": "frontline tank, steel plate, legion helm, round shield"
    },
    "cult_adept": {
        "items": [
            ("torso_clothes_robe", "purple"),
            ("hat_hood_cloth", "black"),
            ("weapon_magic_simple", ""),
            ("belt_mage", ""),
            ("cape_solid", "black"),
        ],
        "body": "male",
        "description": "fragile caster, purple robe, black hood, magic staff"
    },
    "grave_guard": {
        "items": [
            ("body_skeleton", ""),
            ("heads_skeleton", ""),
            ("torso_armour_plate", "iron"),
            ("hat_helmet_close", "iron"),
            ("shield_round", ""),
            ("weapon_sword_arming", ""),
            ("cape_tattered", "forest"),
        ],
        "body": "male",
        "description": "undead tank, skeleton body, iron plate, close helm"
    },
    "warlock": {
        "items": [
            ("torso_clothes_robe", "charcoal"),
            ("hat_hood_cloth", "black"),
            ("weapon_magic_loop", ""),
            ("belt_mage", ""),
            ("cape_solid", "purple"),
        ],
        "body": "male",
        "description": "dark summoner, charcoal robe, black hood, solid purple cape"
    },
}

LPC_URL = "https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/"


async def configure_character(page, enemy_data):
    """Configure LPC character using the site's JS API."""
    print("  Waiting for site to initialize...")
    await page.wait_for_timeout(3000)

    # Reset all selections
    await page.evaluate("window.setDefaultSelections ? window.setDefaultSelections() : null")
    await page.wait_for_timeout(1000)

    # Import state module and reset
    reset_result = await page.evaluate("""
        async () => {
            try {
                const mod = await import('./sources/state/state.js');
                if (mod.resetAll) await mod.resetAll();
                window._selectItem = mod.selectItem;
                return 'ok';
            } catch(e) {
                return 'error: ' + e.message;
            }
        }
    """)
    print(f"  Reset result: {reset_result}")
    await page.wait_for_timeout(1000)

    # Select each item
    for item_id, variant in enemy_data["items"]:
        result = await page.evaluate(f"""
            async () => {{
                try {{
                    if (!window._selectItem) {{
                        const mod = await import('./sources/state/state.js');
                        window._selectItem = mod.selectItem;
                    }}
                    window._selectItem('{item_id}', '{variant}');
                    return 'selected {item_id}';
                }} catch(e) {{
                    return 'error selecting {item_id}: ' + e.message;
                }}
            }}
        """)
        print(f"  {result}")
        await page.wait_for_timeout(300)

    await page.wait_for_timeout(1500)


async def download_zip(page, download_dir: Path, enemy_name: str):
    """Trigger ZIP download and return the zip file path."""
    download_dir.mkdir(parents=True, exist_ok=True)

    print(f"  Triggering ZIP download...")
    async with page.expect_download(timeout=30000) as download_info:
        # Click the ZIP split button
        await page.evaluate("""
            () => {
                const buttons = Array.from(document.querySelectorAll('button, input[type=button]'));
                const zipBtn = buttons.find(b => b.textContent && b.textContent.includes('ZIP') && b.textContent.includes('Split'));
                if (zipBtn) {
                    zipBtn.click();
                    return 'clicked ZIP split button';
                }
                // fallback: try any button with ZIP text
                const anyZip = buttons.find(b => b.textContent && b.textContent.toLowerCase().includes('zip'));
                if (anyZip) { anyZip.click(); return 'clicked any ZIP button'; }
                return 'no ZIP button found';
            }
        """)
    
    download = await download_info.value
    zip_path = download_dir / f"{enemy_name}.zip"
    await download.save_as(str(zip_path))
    print(f"  Saved ZIP to: {zip_path} ({zip_path.stat().st_size} bytes)")
    return zip_path


def extract_frames(zip_path: Path, enemy_name: str):
    """Crop 64x64 frames from walk.png spritesheet (832x256, 4 rows x 13 cols)."""
    from PIL import Image
    import io

    out_base = OUTPUT_DIR / enemy_name
    extracted = {}

    with zipfile.ZipFile(zip_path, 'r') as zf:
        walk_data = zf.read('standard/walk.png')
        sheet = Image.open(io.BytesIO(walk_data))
        w, h = sheet.size
        print(f"  walk.png: {w}x{h}, mode={sheet.mode}")

        for direction in TARGET_DIRECTIONS:
            row = DIRECTION_ROW[direction]
            dir_out = out_base / direction
            dir_out.mkdir(parents=True, exist_ok=True)

            for frame_key, col in FRAME_COL.items():
                x = col * 64
                y = row * 64
                frame = sheet.crop((x, y, x + 64, y + 64))
                out_file = dir_out / f"{frame_key}.png"
                frame.save(str(out_file), 'PNG')
                extracted[f"{direction}/{frame_key}"] = str(out_file)
                print(f"    Cropped: {direction}/{frame_key}.png  (row={row}, col={col}, x={x}, y={y})")

    return extracted


def write_metadata(enemy_name: str, enemy_data: dict, extracted: dict):
    """Write metadata.json and credits.txt for the enemy."""
    out_base = OUTPUT_DIR / enemy_name
    
    metadata = {
        "id": enemy_name,
        "description": enemy_data["description"],
        "lpc_items": [{
            "item_id": item_id,
            "variant": variant
        } for item_id, variant in enemy_data["items"]],
        "frame_map": FRAME_MAP,
        "east_direction": "runtime_mirrored_from_west",
        "extracted_files": extracted,
        "attribution": "Universal LPC Spritesheet Character Generator - https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/"
    }
    
    (out_base / "metadata.json").write_text(json.dumps(metadata, indent=2))
    (out_base / "credits.txt").write_text(
        f"Enemy: {enemy_name}\n"
        f"Source: Universal LPC Spritesheet Character Generator\n"
        f"URL: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/\n"
        f"License: CC-BY-SA 3.0 / GPL 3.0 (see generator credits page)\n"
        f"Items used: {', '.join(i[0] for i in enemy_data['items'])}\n"
    )
    print(f"  Wrote metadata.json and credits.txt")


async def process_enemy(browser, enemy_name: str, enemy_data: dict):
    """Open a new page, configure, download, extract for one enemy."""
    print(f"\n{'='*50}")
    print(f"Processing: {enemy_name}")
    print(f"  {enemy_data['description']}")
    
    context = await browser.new_context(accept_downloads=True)
    page = await context.new_page()
    
    try:
        await page.goto(LPC_URL, wait_until="networkidle", timeout=30000)

        await configure_character(page, enemy_data)

        zip_path = await download_zip(page, DOWNLOAD_TMP, enemy_name)
        extracted = extract_frames(zip_path, enemy_name)
        write_metadata(enemy_name, enemy_data, extracted)

        print(f"  DONE: {len(extracted)} frames extracted for {enemy_name}")
        return extracted

    except Exception as e:
        print(f"  ERROR processing {enemy_name}: {e}")
        return {}
    finally:
        await context.close()


async def main():
    DOWNLOAD_TMP.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Processing {len(ENEMIES)} enemies: {', '.join(ENEMIES.keys())}")

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False, slow_mo=200)
        
        results = {}
        for enemy_name, enemy_data in ENEMIES.items():
            result = await process_enemy(browser, enemy_name, enemy_data)
            results[enemy_name] = result

        await browser.close()

    print(f"\n{'='*50}")
    print("BATCH 1 COMPLETE")
    for enemy, frames in results.items():
        print(f"  {enemy}: {len(frames)} frames")

    return results


if __name__ == "__main__":
    asyncio.run(main())
