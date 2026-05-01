# Enemy Asset Pipeline

## Goal

Produce directional enemy sprite sets for the new multi-front mode using the existing LPC-based workflow, while keeping asset output structured enough for fast integration and later rerenders.

## Required Skills

Use these local skills for enemy production work:

- `lpc-character-generator`
- `playwright` when browser automation is helpful

## Production Principle

The project should not hand-author every directional frame from scratch.

Use LPC as the canonical source for humanoid enemies, then extract exact directional walk frames and keep metadata beside the outputs.

Important rule:

- `playwright` is optional automation support
- the asset-production spec must remain valid even if the external LPC site is handled manually
- when automation is brittle, fall back to manual ZIP export with the same frame mapping and metadata rules

## Current Asset Reality

The repository currently has one flat enemy package per id used by the existing lane game.

Product rule:

- keep the flat package as a legacy fallback during migration
- generate the new canonical output in per-enemy folders
- add true `north` and `south` exports first
- mirror for `east` in the MVP

## Final File Layout

Target layout:

```text
assets/sprites/enemies/{enemy_id}/
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
```

MVP compromise:

- keep current flat files working as legacy fallback
- allow `east` to be runtime-mirrored for the first playable
- add true `east` folders later only for asymmetric units that need them

## LPC Frame Mapping

Use split ZIP export as the canonical source.

Directional frame mapping:

- `west/base` -> `standard/walk/left/5.png`
- `west/walk_02` -> `standard/walk/left/3.png`
- `west/walk_03` -> `standard/walk/left/7.png`
- `south/base` -> `standard/walk/down/5.png`
- `south/walk_02` -> `standard/walk/down/3.png`
- `south/walk_03` -> `standard/walk/down/7.png`
- `north/base` -> `standard/walk/up/5.png`
- `north/walk_02` -> `standard/walk/up/3.png`
- `north/walk_03` -> `standard/walk/up/7.png`

`east` in the MVP:

- runtime mirror from `west`

## Attack Animation Policy

Current MVP combat readability comes from procedural runtime motion layered over the existing directional walk frames:

- melee heroes and enemies use short lunge, slash-arc, strike-line, and hit-flash effects
- archers use fast projectile trails
- magic attackers use beams and burst rings
- no new LPC attack PNGs are required for this gameplay pass

Next LPC animation expansion:

- extract `slash`, `thrust`, `shoot`, and `spellcast` frames only after the procedural motion pass is validated on device
- keep the same per-unit folder and metadata discipline when attack frames are added
- document the exact split-ZIP source paths beside the existing walk frame mapping

## LPC Workflow

Required workflow:

1. lock the enemy role first
2. choose one silhouette anchor
3. keep the palette constrained
4. export with `ZIP: Split by animation and frame`
5. extract exact directional frames
6. verify every frame stays `64 x 64`
7. keep transparency intact
8. write metadata and credits immediately

## Playwright-Assisted LPC Workflow

If automation is used for LPC generation, use the local `playwright` skill and the LPC site's browser hooks.

Important LPC automation notes:

- use `selectItem(itemId, variant)`
- read item metadata from `window.itemMetadata`
- call `selectItem(itemId, '')` for items with no variants
- do not pass `null` as a variant

## Metadata Requirement

Every enemy package must include:

- enemy id
- gameplay role
- LPC body type
- item ids and variants
- archive paths used
- output files written
- generation date
- attribution location
- east handling status

## Batch Priority

### Batch 1

- Raider
- Scout
- Shield Infantry
- Cult Adept
- Grave Guard
- Warlock

### Batch 2

- Banner Captain
- Wolf Scout
- Skeleton
- Bone Archer
- Plague Bearer
- Corrupted Knight
- Hex Sniper
- Bastion Priest

### Batch 3

- Bastion Overlord

## Mirroring Rule

Allowed in MVP:

- mirror for `east`

Not acceptable as final production for:

- Shield Infantry
- Corrupted Knight
- Bastion Overlord
- any enemy with major asymmetric gear

## Validation Checklist

Before marking an enemy package done:

- all expected files exist
- every file is `64 x 64`
- background is transparent
- metadata is present
- credits are preserved
- runtime naming matches the loader
- the unit reads clearly from the battlefield camera
- side-facing units with shields or asymmetric gear are reviewed for mirroring artifacts
