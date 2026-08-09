# Stage 1 Tower Tier Asset Record

## Scope

- Generated: 2026-08-09
- Runtime scope: tutorial and Stage 1 tower upgrades only.
- Outputs: seven level-2 and seven level-3 tower sprites.
- Gameplay scope: visual-only. Tower costs, stats, upgrade behavior, branches, and combat balance were not changed.
- Tool: OpenAI built-in image generation, followed by the installed chroma-key removal helper and local canvas normalization.
- Use case: `precise-object-edit`

## Source and usage

- Image 1 for every output was the matching project-owned Stage 1 level-1 sprite and was treated as the strict identity, palette, lighting, camera, and pixel-density reference.
- Image 2 was the matching existing generic level-2 or level-3 runtime sprite and was used only as a structural progression reference.
- No new third-party image source was introduced. Generated outputs are project-controlled assets subject to the image-generation service/account terms under which they were created.
- Built-in source outputs remain under the Codex generated-image store. Final project-consumed exports are the normalized PNGs listed below.

## Common prompt contract

```text
Use case: precise-object-edit
Asset type: production tower-defense game sprite, level {2|3} upgrade
Input images: Image 1 is the Stage 1 tower edit target and strict style/identity reference; Image 2 is only a functional tier-progression reference.
Primary request: Create the requested upgrade as a direct evolution of Image 1. Preserve its recognizable building identity, one-cell footprint, blue player heraldry, palette family, materials, camera angle, ground contact, and lighting. Tier 2 adds one clear layer of fortification, equipment, and material detail. Tier 3 is the strongest readable evolution with a larger core weapon, crown, or roof treatment, but remains compact and unmistakably the same tower.
Style/medium: crisp polished top-down 3/4 fantasy pixel art matching Image 1 viewpoint, outline weight, and pixel density.
Composition/framing: one centered isolated structure, fully visible with generous padding.
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background, uniform with no texture, gradient, floor, or lighting variation.
Constraints: no characters, terrain, projectiles, text, UI, watermark, cast shadow, contact shadow, or reflection; do not use #FF00FF in the subject.
```

Each generation call added tower-specific upgrade details:

- Archer: stronger stone drum, battlements, timber braces, quiver racks, and upgraded crossbow mechanism.
- Guard barracks: fortified stone gate, layered blue roof, palisade, lookout posts, and shield/spear racks.
- Mage obelisk: larger blue crystal crown, carved rune channels, gold focusing rings, and upgraded corner pylons.
- Frost shrine: broader ice crown, frozen stone dais, frost runes, icicle armor, and ornate capped pylons.
- Coin mill: reinforced masonry, blue roof, brass-rimmed wheel/gears, gold hopper, crates, and locked chest.
- Ballista: fortified round turret, heavier bow arms, bolt rail, winch gears, spare bolts, and blue-metal braces.
- Ember keep: layered basalt battlements, contained brazier, furnace stacks, iron bands, glowing runes, and brass-red armor.

## Input and output map

| Tower | Tier | Stage 1 identity reference | Progression reference | Final output |
|---|---:|---|---|---|
| Archer | 2 | `assets/sprites/stage1/towers/archer.png` | `assets/sprites/towers/archer_tower_t2.png` | `assets/sprites/stage1/towers/archer_t2.png` |
| Archer | 3 | `assets/sprites/stage1/towers/archer.png` | `assets/sprites/towers/archer_tower_t3.png` | `assets/sprites/stage1/towers/archer_t3.png` |
| Guard barracks | 2 | `assets/sprites/stage1/towers/guard_barracks.png` | `assets/sprites/towers/guard_barracks_t2.png` | `assets/sprites/stage1/towers/guard_barracks_t2.png` |
| Guard barracks | 3 | `assets/sprites/stage1/towers/guard_barracks.png` | `assets/sprites/towers/guard_barracks_t3.png` | `assets/sprites/stage1/towers/guard_barracks_t3.png` |
| Mage obelisk | 2 | `assets/sprites/stage1/towers/mage_obelisk.png` | `assets/sprites/towers/mage_obelisk_t2.png` | `assets/sprites/stage1/towers/mage_obelisk_t2.png` |
| Mage obelisk | 3 | `assets/sprites/stage1/towers/mage_obelisk.png` | `assets/sprites/towers/mage_obelisk_t3.png` | `assets/sprites/stage1/towers/mage_obelisk_t3.png` |
| Frost shrine | 2 | `assets/sprites/stage1/towers/frost_shrine.png` | `assets/sprites/towers/frost_shrine_t2.png` | `assets/sprites/stage1/towers/frost_shrine_t2.png` |
| Frost shrine | 3 | `assets/sprites/stage1/towers/frost_shrine.png` | `assets/sprites/towers/frost_shrine_t3.png` | `assets/sprites/stage1/towers/frost_shrine_t3.png` |
| Coin mill | 2 | `assets/sprites/stage1/towers/coin_mill.png` | `assets/sprites/towers/coin_mill_t2.png` | `assets/sprites/stage1/towers/coin_mill_t2.png` |
| Coin mill | 3 | `assets/sprites/stage1/towers/coin_mill.png` | `assets/sprites/towers/coin_mill_t3.png` | `assets/sprites/stage1/towers/coin_mill_t3.png` |
| Ballista | 2 | `assets/sprites/stage1/towers/ballista.png` | `assets/sprites/towers/ballista_t2.png` | `assets/sprites/stage1/towers/ballista_t2.png` |
| Ballista | 3 | `assets/sprites/stage1/towers/ballista.png` | `assets/sprites/towers/ballista_t3.png` | `assets/sprites/stage1/towers/ballista_t3.png` |
| Ember keep | 2 | `assets/sprites/stage1/towers/ember_keep.png` | `assets/sprites/towers/emberkeep_t2.png` | `assets/sprites/stage1/towers/ember_keep_t2.png` |
| Ember keep | 3 | `assets/sprites/stage1/towers/ember_keep.png` | `assets/sprites/towers/emberkeep_t3.png` | `assets/sprites/stage1/towers/ember_keep_t3.png` |

## Export and validation

- Chroma key: border-sampled `#FF00FF`, soft matte, despill, transparent threshold 12, opaque threshold 220.
- Final format: 128x160 RGBA PNG.
- Alignment: visible subject centered horizontally and grounded at canvas y=150, matching the Stage 1 level-1 pivot convention.
- Tier silhouettes were normalized to increase in width and/or height while remaining inside the canonical canvas.
- Validation requires a readable RGBA file, visible non-transparent pixels, transparent corners, and successful Flutter asset-bundle loading.

## Legacy asset audit

The existing generic T1/T2/T3 sprites and branch sprites under `assets/sprites/towers/` remain referenced by `TowerVisualCatalog`, `tierAssetPath`, `branchTierAssetPath`, Stage 2-30 rendering, and related tests. None were deleted in this pass.
