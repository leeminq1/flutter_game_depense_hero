#!/usr/bin/env python3
"""Validate the directional enemy sprite package structure.

Checks every enemy folder under assets/sprites/enemies/ and reports any
missing required files. Exits with code 1 if any issues are found.

Required layout per enemy:
  {enemy}/
    west/base.png
    west/walk_02.png
    west/walk_03.png
    north/base.png
    north/walk_02.png
    north/walk_03.png
    south/base.png
    south/walk_02.png
    south/walk_03.png
    metadata.json
    credits.txt
"""

import json
import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ENEMIES_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites" / "enemies"

REQUIRED_DIRECTIONAL_FILES = [
    "west/base.png",
    "west/walk_02.png",
    "west/walk_03.png",
    "north/base.png",
    "north/walk_02.png",
    "north/walk_03.png",
    "south/base.png",
    "south/walk_02.png",
    "south/walk_03.png",
]

REQUIRED_META_FILES = [
    "metadata.json",
    "credits.txt",
]

KNOWN_ROSTER = [
    "raider",
    "scout",
    "banner_captain",
    "wolf_scout",
    "shield_infantry",
    "cult_adept",
    "skeleton",
    "bone_archer",
    "grave_guard",
    "plague_bearer",
    "corrupted_knight",
    "hex_sniper",
    "warlock",
    "bastion_priest",
    "bastion_overlord",
]

# Fields required inside metadata.json
REQUIRED_META_FIELDS = [
    "id",
    "east_direction",
    "attribution",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def check_enemy(enemy_dir: Path) -> list[str]:
    """Return a list of issue strings for the given enemy folder."""
    issues: list[str] = []
    enemy_id = enemy_dir.name

    for rel in REQUIRED_DIRECTIONAL_FILES + REQUIRED_META_FILES:
        target = enemy_dir / rel
        if not target.exists():
            issues.append(f"  MISSING  {rel}")

    # Validate metadata.json content if it exists
    meta_path = enemy_dir / "metadata.json"
    if meta_path.exists():
        try:
            with meta_path.open(encoding="utf-8") as fh:
                meta = json.load(fh)
            for field in REQUIRED_META_FIELDS:
                if field not in meta:
                    issues.append(f"  META     metadata.json missing field '{field}'")
            # Check id matches folder name
            if meta.get("id") != enemy_id:
                issues.append(
                    f"  META     metadata.json id '{meta.get('id')}' "
                    f"does not match folder name '{enemy_id}'"
                )
        except json.JSONDecodeError as exc:
            issues.append(f"  META     metadata.json is not valid JSON: {exc}")

    return issues


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    if not ENEMIES_DIR.is_dir():
        print(f"ERROR: enemies directory not found: {ENEMIES_DIR}", file=sys.stderr)
        return 1

    # Collect all enemy subdirectories (ignore files like AI_GENERATION_PROMPTS.md)
    enemy_dirs = sorted(
        p for p in ENEMIES_DIR.iterdir() if p.is_dir()
    )

    if not enemy_dirs:
        print("ERROR: no enemy folders found.", file=sys.stderr)
        return 1

    found_ids = {p.name for p in enemy_dirs}

    # Check for roster entries that are completely absent from the filesystem
    missing_from_roster = [e for e in KNOWN_ROSTER if e not in found_ids]

    total_issues = 0
    failed_enemies: list[str] = []

    print(f"Validating {len(enemy_dirs)} enemy folder(s) in:\n  {ENEMIES_DIR}\n")

    for enemy_dir in enemy_dirs:
        issues = check_enemy(enemy_dir)
        if issues:
            total_issues += len(issues)
            failed_enemies.append(enemy_dir.name)
            print(f"[FAIL] {enemy_dir.name}")
            for issue in issues:
                print(issue)
        else:
            print(f"[ OK ] {enemy_dir.name}")

    if missing_from_roster:
        print()
        print("ROSTER GAPS (folders not yet created):")
        for enemy_id in missing_from_roster:
            print(f"  ABSENT   {enemy_id}")
        total_issues += len(missing_from_roster)

    print()
    if total_issues == 0:
        print("All enemy packages passed validation.")
        return 0

    print(
        f"Found {total_issues} issue(s) across "
        f"{len(failed_enemies) + len(missing_from_roster)} enemy package(s)."
    )
    if failed_enemies:
        print("Failed packages:", ", ".join(failed_enemies))
    if missing_from_roster:
        print("Missing from roster:", ", ".join(missing_from_roster))
    return 1


if __name__ == "__main__":
    sys.exit(main())
