# Tower Upgrade Asset Checklist

## Purpose

Track the first complete tower tier sprite batch and the runtime rules that select `T1`, `T2`, and `T3` art in combat.

References:

- `docs/design-docs/defense-roster-bible.md`
- `docs/design-docs/size-and-silhouette-rules.md`
- `lib/game/rendering/visual_catalog.dart`
- `lib/game/rendering/game_visual_registry.dart`
- `tools/generate_tower_sprites.py`

## Runtime Rule

- Tower level `1` uses `_t1`
- Tower level `2` uses `_t2`
- Tower level `3` uses `_t3`
- If a tier sprite is missing, the runtime falls back to the base tower PNG

## Generated Tower Tier Assets

### Archer Tower

- `assets/sprites/towers/archer_tower_t1.png`
- `assets/sprites/towers/archer_tower_t2.png`
- `assets/sprites/towers/archer_tower_t3.png`

### Guard Barracks

- `assets/sprites/towers/guard_barracks_t1.png`
- `assets/sprites/towers/guard_barracks_t2.png`
- `assets/sprites/towers/guard_barracks_t3.png`

### Mage Obelisk

- `assets/sprites/towers/mage_obelisk_t1.png`
- `assets/sprites/towers/mage_obelisk_t2.png`
- `assets/sprites/towers/mage_obelisk_t3.png`

### Frost Shrine

- `assets/sprites/towers/frost_shrine_t1.png`
- `assets/sprites/towers/frost_shrine_t2.png`
- `assets/sprites/towers/frost_shrine_t3.png`

### Coin Mill

- `assets/sprites/towers/coin_mill_t1.png`
- `assets/sprites/towers/coin_mill_t2.png`
- `assets/sprites/towers/coin_mill_t3.png`

### Ballista

- `assets/sprites/towers/ballista_t1.png`
- `assets/sprites/towers/ballista_t2.png`
- `assets/sprites/towers/ballista_t3.png`

### Emberkeep

- `assets/sprites/towers/emberkeep_t1.png`
- `assets/sprites/towers/emberkeep_t2.png`
- `assets/sprites/towers/emberkeep_t3.png`

## Tier Progression Intent

- `T1`: simple field deployment
- `T2`: reinforced, clearer combat role
- `T3`: elite battlefield anchor with richer silhouette and trim

## Next Art Pass

After this batch:

1. branch-aware final variants for key towers if needed
2. Barracks defender sprites
3. stage-specific decorative set dressing around build pads
