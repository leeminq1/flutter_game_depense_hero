# Barracks Defender Asset Checklist

## Purpose

Track the first attached Barracks defender sprite family used by the runtime combat view.

References:

- `docs/design-docs/defense-roster-bible.md`
- `lib/game/rendering/visual_catalog.dart`
- `lib/game/rendering/game_visual_registry.dart`
- `lib/game/core/depense_game.dart`
- `tools/generate_barracks_defender_sprites.py`

## Runtime Rule

- Guard Barracks does not yet spawn fully independent defender entities.
- The current prototype uses attached defender visuals anchored to the Barracks tower.
- Defender visuals react to tower `level` and `branchId`.
- Level 1 shows one defender.
- Level 2 shows branched or unbranched veteran defender art.
- Level 3 shows a fuller garrison read with larger defender presence.

## Generated Assets

### Base

- `assets/sprites/defenders/barracks_defender_t1.png`
- `assets/sprites/defenders/barracks_defender_t2.png`
- `assets/sprites/defenders/barracks_defender_t3.png`

### Vanguard Branch

- `assets/sprites/defenders/barracks_defender_vanguard_t2.png`
- `assets/sprites/defenders/barracks_defender_vanguard_t3.png`

### Sentinel Branch

- `assets/sprites/defenders/barracks_defender_sentinel_t2.png`
- `assets/sprites/defenders/barracks_defender_sentinel_t3.png`

## Visual Intent

- `base`: militia to veteran town guard
- `vanguard`: heavier shield wall and sturdier brawl read
- `sentinel`: reach weapon and wider interception read

## Preview

- `output/barracks_defender_preview.png`

## Next Pass

1. Add directional or attack-pose variants if Barracks combat animation becomes richer
2. Convert attached visuals into true defender entities only if gameplay simulation needs it
