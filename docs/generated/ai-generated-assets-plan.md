# AI-Generated Assets Plan

## Purpose

This document is the canonical production brief for all new AI-assisted or LPC-assisted assets required by the first playable of `Citadel Siege`.

Rules:

- do not invent extra assets outside this list for the first playable
- follow the file paths exactly
- keep new enemy exports in per-enemy folders under `assets/sprites/enemies`
- use `lpc-character-generator` as the required enemy-production workflow
- use `playwright` only when LPC browser automation is actually helpful

## Existing Assets That Are Already Sufficient

The first playable does not require new families for:

- buildable towers
- barracks defenders
- enemy roster count
- most act-specific environment props and landmarks

The first playable will reuse:

- the existing 7 tower families and their upgrade sprites
- the existing barracks defender sprites
- the existing 15 enemy ids
- the current environment prop and landmark library

## Blocker Assets

### 1. Central Citadel

| Field | Value |
| --- | --- |
| File | `assets/sprites/environment/landmarks/central_citadel.png` |
| Category | `landmark` |
| Size | `192x192 PNG`, transparent |
| Role | central `3 x 3` citadel visual |

Style rules:

- high-angle pixel art
- neutral player fortress, not a villain fortress
- blue banners, silver-gray stone, gold trim
- strong silhouette at mobile zoom
- must not read like a placeable tower

Prompt:

```text
pixel art fantasy citadel, central player fortress, top-down high-angle view, compact stone keep, blue banners, silver stone, gold trim, strong readable silhouette, transparent background, mobile game battlefield readability, no characters, no ground plane, no UI, no side view
```

Acceptance:

- readable at `0.55x` minimum zoom
- still clearly reads as the battle core on `360x800`, `412x915`, `768x1024`, and `834x1194` portrait viewports

### 2. Supply Node Idle

| Field | Value |
| --- | --- |
| File | `assets/sprites/environment/props/supply_node_idle.png` |
| Category | `prop/tile marker` |
| Size | `64x64 PNG`, transparent |
| Role | build-only marker for Coin Mill placement |

Prompt:

```text
pixel art magical supply node marker, top-down tile decal, circular stone base with embedded pale crystal, subtle blue-gold glow, transparent background, readable as special build tile, not a tower, not a character, mobile strategy readability
```

Acceptance:

- clearly different from normal buildable ground
- still reads as a floor marker when a Coin Mill sits above it

### 3. Supply Node Occupied

| Field | Value |
| --- | --- |
| File | `assets/sprites/environment/props/supply_node_occupied.png` |
| Category | `prop/tile marker` |
| Size | `64x64 PNG`, transparent |
| Role | active marker under a placed Coin Mill |

Prompt:

```text
pixel art active supply node marker, top-down tile decal, circular stone logistics sigil with brighter gold-blue crystal glow, transparent background, readable under an economy building, subtle but clear special tile state
```

Acceptance:

- distinguishable from the idle node
- does not overpower the building placed above it

### 4. Breach Front Marker

| Field | Value |
| --- | --- |
| File | `assets/sprites/environment/props/breach_front_marker.png` |
| Category | `prop/telegraph overlay` |
| Size | `64x64 PNG`, transparent |
| Role | front-edge telegraph marker for active and next fronts |

Tint colors:

- `north`: `#4488FF`
- `south`: `#FF4444`
- `east`: `#44FF88`
- `west`: `#FFCC44`

Prompt:

```text
pixel art siege breach marker, top-down cracked stone rune, neutral shape for tinting, transparent background, readable edge telegraph decal, fantasy warfare aesthetic, not a tower, not a unit
```

Acceptance:

- all four tint variants remain readable
- still reads as a front telegraph on top of path tiles

## Directional Enemy Package Plan

### Final Folder Structure

```text
assets/sprites/enemies/
  raider/
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

Rules:

- `east` is runtime-mirrored in the MVP
- existing flat files remain as legacy fallback during migration
- `metadata.json` and `credits.txt` are required in every enemy folder

### Required Roster

- `raider`
- `scout`
- `banner_captain`
- `wolf_scout`
- `shield_infantry`
- `cult_adept`
- `skeleton`
- `bone_archer`
- `grave_guard`
- `plague_bearer`
- `corrupted_knight`
- `hex_sniper`
- `warlock`
- `bastion_priest`
- `bastion_overlord`

### LPC Frame Mapping

- `west/base -> standard/walk/left/5.png`
- `west/walk_02 -> standard/walk/left/3.png`
- `west/walk_03 -> standard/walk/left/7.png`
- `north/base -> standard/walk/up/5.png`
- `north/walk_02 -> standard/walk/up/3.png`
- `north/walk_03 -> standard/walk/up/7.png`
- `south/base -> standard/walk/down/5.png`
- `south/walk_02 -> standard/walk/down/3.png`
- `south/walk_03 -> standard/walk/down/7.png`

### Production Rules

- use `lpc-character-generator` for enemy generation
- use split ZIP export as the canonical source
- keep every PNG `64x64`
- preserve transparency
- write `metadata.json` and `credits.txt` immediately after export
- inherit the role prompt anchors from `assets/sprites/enemies/AI_GENERATION_PROMPTS.md`

### Batch Priority

#### Batch 1

- `raider`
- `scout`
- `shield_infantry`
- `cult_adept`
- `grave_guard`
- `warlock`

#### Batch 2

- `banner_captain`
- `wolf_scout`
- `skeleton`
- `bone_archer`
- `plague_bearer`
- `corrupted_knight`
- `hex_sniper`
- `bastion_priest`

#### Batch 3

- `bastion_overlord`

### True East Review Targets

These may use runtime mirroring in MVP, but should receive true `east` exports in a polish pass:

- `banner_captain`
- `shield_infantry`
- `bone_archer`
- `corrupted_knight`
- `hex_sniper`
- `bastion_priest`
- `bastion_overlord`

## Optional Polish Assets

These are not first-playable blockers.

| File | Size | Purpose |
| --- | --- | --- |
| `assets/sprites/environment/props/boss_warning_sigil.png` | `64x64` | final breach warning |
| `assets/sprites/environment/props/citadel_guard_ring.png` | `96x96` | citadel selection or shield-ring accent |
| `assets/sprites/environment/props/front_banner_badge.png` | `64x64` | optional HUD or result-screen badge |

## Validation Checklist

- every new enemy frame is `64x64` with transparency
- every new non-enemy asset matches the required source size
- `central_citadel.png` reads clearly in all required portrait sizes
- `supply_node` markers are visually distinct from normal buildable tiles
- `breach_front_marker` remains legible after runtime tinting
- the first playable remains valid without adding new tower families or new enemy families
