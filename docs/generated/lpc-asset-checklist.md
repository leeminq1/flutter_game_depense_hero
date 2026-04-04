# LPC Asset Checklist

## Goal

Reserve stable sprite paths and generator prompts before final art import.

## Tower Slots

- `assets/sprites/towers/archer_tower.png`
- `assets/sprites/towers/guard_barracks.png`
- `assets/sprites/towers/mage_obelisk.png`
- `assets/sprites/towers/frost_shrine.png`
- `assets/sprites/towers/coin_mill.png`
- `assets/sprites/towers/ballista.png`
- `assets/sprites/towers/emberkeep.png`

## Enemy Slots

- `assets/sprites/enemies/raider.png`
- `assets/sprites/enemies/scout.png`
- `assets/sprites/enemies/shield_infantry.png`
- `assets/sprites/enemies/cult_adept.png`
- `assets/sprites/enemies/skeleton.png`
- `assets/sprites/enemies/grave_guard.png`
- `assets/sprites/enemies/corrupted_knight.png`
- `assets/sprites/enemies/warlock.png`
- `assets/sprites/enemies/bastion_overlord.png`

## LPC-Friendly Priorities

- Raider, Scout, Cult Adept, Warlock, and Corrupted Knight are strong LPC candidates because humanoid silhouettes read well.
- Skeleton and Grave Guard can also use humanoid LPC workflows, but may need post-edit cleanup for stronger undead readability.
- Bastion Overlord should likely be generated as a custom boss illustration or assembled from LPC references plus manual editing.
- Towers can begin as static painted props even if enemies use character sheets first.

## Recommended Import Order

1. Raider
2. Shield Infantry
3. Cult Adept
4. Skeleton
5. Corrupted Knight
6. Warlock
7. Bastion Overlord
8. Archer Tower
9. Ballista
10. Emberkeep

## Runtime Notes

- The game now uses a visual catalog in code, so these filenames are already reserved.
- Placeholder rendering remains active until real PNG assets are added.
- The runtime now checks the asset manifest and automatically loads any sprite files that exist at the reserved paths.
- Missing files safely fall back to shape-based rendering, so art can be imported incrementally.
