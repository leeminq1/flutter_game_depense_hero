# Map Production Plan

## Purpose

Turn the current abstract combat field into real stage maps that visually match the 30-stage campaign arc.

This document connects:

- stage data
- environment assets
- runtime rendering
- future set-dressing work

## Current State

Map-related foundations already exist:

- each stage has `pathNodes`
- each stage has `buildSlots`
- stage brackets already map to biome themes through campaign data
- reusable props and landmark sprites already exist under `assets/sprites/environment`
- the runtime already draws lane pathing and tower placement points
- stages can now carry `environmentTheme` and decorative environment placements
- the runtime can now render current prop and landmark sprites behind the battlefield

What is still missing is the richer authored map layer that makes each stage feel fully bespoke rather than only bracket-themed.

## Map Production Goal

Each stage should eventually read as:

- a clear lane to defend
- a recognizable biome bracket
- one authored landmark story
- enough decorative clutter to feel alive
- enough empty space to stay readable during combat

## Production Layers

Maps should be built in five layers.

### 1. Background Ground Layer

Purpose:

- establish biome palette
- separate one stage bracket from another

Examples:

- frontier dirt and grass
- grave soil and dead grass
- chapel stone and ritual stains
- bastion road and military ash
- throne-march blackstone and ember glow

### 2. Path Layer

Purpose:

- make enemy movement feel embedded in the world, not painted on top of it

Examples:

- wagon road
- broken stone path
- grave lane
- siege road
- infernal marchway

### 3. Structural Layer

Purpose:

- define the map's authored identity

Examples:

- village gate
- bandit stockade
- mausoleum gate
- cursed chapel front
- bastion wall chunk
- infernal gate

### 4. Set-Dressing Layer

Purpose:

- make the stage feel inhabited and intentional without hurting readability

Examples:

- fences
- grave markers
- crates
- rubble
- braziers
- altars
- chain posts

### 5. Foreground Accent Layer

Purpose:

- add depth and premium look with a small number of overlaps

Examples:

- banner edge
- dead branch tip
- brazier glow
- chain silhouette

## Runtime Implementation Order

### Phase 1: Environment Placements

Extend stage data so each stage can declare:

- `backgroundThemeId`
- `landmarkPlacements`
- `propPlacements`
- optional `foregroundPlacements`

This should stay decorative only.

### Phase 2: Environment Rendering

Draw environment art in `depense_game.dart` with this order:

1. background
2. path
3. landmarks and props
4. path overlays if needed
5. towers and enemies
6. foreground accents

Current implementation note:

- stage themes now also tint path and build-slot presentation so each biome bracket has a slightly different battlefield feel
- stage themes now also generate lightweight ground accents and lane-detail motifs so the battlefield reads as dirt road, grave lane, chapel stone, bastion road, or throne march instead of only a recolored line
- runtime ground, lane, and anchor marks are now precomputed into a cached texture plan on resize instead of being recomputed ad hoc inside every draw step
- stage resize now builds a cached `MapTexturePlanner` result so ground marks, path detail marks, and anchor emphasis are sampled once and then reused by runtime rendering

### Phase 3: Stage Bracket Presets

Build reusable placement presets for:

- stages 1-5 frontier road
- stages 6-10 bandit crossroads
- stages 11-15 grave fields
- stages 16-20 cursed chapel belt
- stages 21-25 bastion approach
- stages 26-30 throne march

### Phase 4: Crest Stage Authorship

Hand-author stronger visual compositions for:

- stage 5
- stage 10
- stage 15
- stage 20
- stage 25
- stage 30

These are the first stages that should feel custom rather than template-driven.

Current implementation status:

- stages `5, 10, 15, 20, 25, 30` now have dedicated manual decoration layouts
- these layouts use stronger landmark placement than normal stages in the same bracket
- future passes should refine density and composition, not revert to generic template placement
- a generated crest-scene overview now exists at `output/crest_stage_scene_preview.png` for quick visual review
- the current environment manifest batch is now fully generated, so the next map work is about composition quality rather than missing core slots
- crest stages now also receive an extra cached ground-overlay layer so they can carry bespoke stains, ritual traces, or military wear without forcing those motifs into every stage in the bracket

## Priority Backlog

### Immediate

- keep current tower/building asset work moving
- tune and expand stage environment placements now that decorative rendering exists
- make crest stages feel more custom than the baseline bracket templates

### Next

- add more small clutter props
- add foreground depth accents
- refine ground motifs around major bends, spawn zones, and base approach areas

### Later

- stage-specific hero props
- animated environmental accents
- biome-specific particle ambience

## Readability Rules

- environment must never obscure enemy path readability
- build slots must remain obvious on mobile
- landmark count should stay low enough that towers remain the main gameplay focal point
- foreground accents should be rare and never cover core interactions
- keep roughly `70%` clean gameplay space, `20%` light texture variation, and `10%` focal decoration
- treat the path as the largest continuous value shape on screen and keep the center of that lane cleaner than the edges
- reserve a clean exclusion zone around build slots so cracks, seams, ruts, or glow marks do not compete with placement readability
- reserve quiet buffers around large props and landmarks so terrain texture does not blur together with set dressing
- let spawn, core approach, and major bends be the only lane areas that receive stronger texture emphasis

## Ground And Path Motif Rules

The current ground/path texture pass should stay cheap, stable, and readable.

- Frontier road: broad dirt ribbon, sparse rut ovals, pebble dots, and restrained grass-edge noise
- Bandit crossroads: trampled road, darker scuff marks, short plank patches, and rougher edge damage
- Grave fields: cold soil mottling, sunken patches, stone chips, and dead-grass specks without strong bone clutter
- Cursed chapel: cracked slab seams, ash smears, tiny stain pools, and very sparse ritual glow fragments near edges only
- Bastion approach: worn block seams, rubble hints, patch-plate marks, and militarized straight-line scuffs
- Throne march: blackened plates, ember dust, narrow corruption veins, and scorch-smudge borders with restrained glow

Implementation rule:

- prefer a small repeated vocabulary of dots, short lines, small quads, and soft circles rather than heavy texture noise
- keep regular stages sparser than crest stages
- strengthen spawn and core approach with local motif clusters, but keep them weaker than active enemy or tower contrast
- bias extra bend detail toward the outside of turns and keep the apex cleaner for enemy readability
- allow crest stages to add one bespoke terrain-story layer on top of the shared planner, such as militia road wear, bandit choke grime, grave seep, ritual residue, siege abrasion, or infernal march scars

Runtime rule:

- use a stage-level `MapTexturePlanner` style pass to cache ground marks, path marks, and anchor marks once per battlefield layout change
- keep `depense_game.dart` focused on drawing cached marks rather than owning all terrain-generation logic directly

## Relationship To Tower / Building Art

Tower and building art still matters first because those are the objects the player interacts with directly.

But map work is now the next major visual layer after the current tower/building passes.

That means the practical production order is:

1. finish current tower/building art direction passes
2. attach environment placements to stages
3. render maps with existing landmark and prop assets
4. add stage-specific set dressing
