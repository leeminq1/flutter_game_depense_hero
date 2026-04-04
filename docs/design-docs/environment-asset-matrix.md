# Environment Asset Matrix

## Purpose

Map stage brackets to the prop and landmark sets that should be generated next.

This is the bridge between campaign progression and actual environment art production.

## Shared Asset Categories

Every stage bracket should draw from these categories:

- `path edge props`
- `small clutter`
- `mid props`
- `landmark props`
- `banner or ritual accent`

## Stage Bracket Matrix

| Stage bracket | Theme | Path edge props | Small clutter | Mid props | Landmark props | Accent |
| --- | --- | --- | --- | --- | --- | --- |
| 1-5 | Frontier Road | fences, signposts | sacks, brush, stones | carts, crates, wells | road gate, village watch post | green cloth banner |
| 6-10 | Bandit Crossroads | sharpened stakes, barricades | rope bundles, broken barrels | campfires, wagon wrecks | bandit stockade, checkpoint tower | patched red banner |
| 11-15 | Grave Fields | grave borders, dead roots | bone piles, candles, cracked stones | grave markers, broken coffins | mausoleum gate, cemetery statue | pale green necro glow |
| 16-20 | Cursed Chapel Belt | black thorns, chapel rubble | candles, skulls, occult debris | altars, ruined pews, ward stones | fallen chapel facade, ritual arch | violet ritual glow |
| 21-25 | Bastion Approach | wall debris, spear racks | broken shields, rubble, chains | siege crates, brazier stands | breached wall chunk, fort gate remains | dark red military banner |
| 26-30 | Throne March | black parapet fragments, chain posts | ember piles, brass debris | braziers, throne sigils, obsidian stakes | infernal gate, bastion arch, throne-road monument | crimson and gold fire |

## First Environment Production Batch

Generate these first because they can be reused across many stages:

- `road_signpost`
- `wooden_fence_segment`
- `supply_crate`
- `wagon_wreck`
- `grave_marker_tall`
- `dead_tree_twisted`
- `bone_pile`
- `chapel_rubble`
- `ritual_altar`
- `fort_wall_breach`
- `brazier_large`
- `chain_post`

## Landmark Batch

Generate these after the reusable props:

- `village_gate`
- `bandit_stockade`
- `mausoleum_gate`
- `cursed_chapel_front`
- `bastion_wall_chunk`
- `infernal_gate`

## Placement Intent

### Path Edge Props

Used to frame lane curvature and support travel logic.

Examples:

- fences
- stakes
- grave borders
- chain posts

### Small Clutter

Used to prevent maps from feeling empty without affecting readability.

Examples:

- stones
- candles
- sacks
- skulls
- broken shields

### Mid Props

Used to make each map feel authored.

Examples:

- wagons
- altars
- brazier stands
- siege crates

### Landmark Props

Used to define the stage bracket or crest stage.

Examples:

- chapel front
- wall breach
- gate
- stockade

## Interaction Rule

Environment props should be decorative by default.

If a prop becomes interactive later:

- it needs a separate visual family
- it should not reuse purely decorative art without a clear cue

## Next Generation Order

After the current tower pass:

1. reusable environment props
2. crest-stage landmarks
3. tower upgrade variants
4. stage-specific set dressing
