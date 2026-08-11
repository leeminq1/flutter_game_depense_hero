# Campaign Visual Expansion Asset Specification

## 1. Road Isolated Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_isolated.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | A road cell with no connected neighbor, used by connection mask 0 |

Style rules:
- Polished top-down 3/4 fantasy pixel art matching the approved Stage 1 terrain.
- Packed tan earth with sparse stones and a narrow dark-green grass fringe.
- Final geometry is normalized by the deterministic road exporter.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one isolated square patch of worn tan dirt road with no exits
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: centered in one exact square atlas cell with generous separation
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: no buildings, units, text, UI, shadows, scenery, watermark, or road opening at any edge; do not use #FF00FF in the tile
```

Acceptance:
- No road-colored pixel touches a cell edge after export.
- Reads as the same material and pixel density as the other five modules.

## 2. Road Cap Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_cap.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | Canonical north-facing single-exit road module |

Style rules:
- Same dirt, grass fringe, outline weight, and lighting as Asset 1.
- One centered connection corridor only.
- Exported edge opening has the canonical campaign road width.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one worn tan dirt road end cap with exactly one centered exit at the north edge
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: centered in one exact square atlas cell
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: mathematically centered north exit only; no east, south, or west exit; no buildings, units, text, UI, shadows, watermark, or extra scenery
```

Acceptance:
- North opening reaches the boundary at the canonical width.
- East, south, and west edges have no road opening.

## 3. Road Straight Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_straight.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | Canonical north-south road module, rotated for east-west use |

Style rules:
- Same road material and fringe as Assets 1-2.
- North and south openings are identical and centered.
- No tapering within the last eight pixels of either connected edge.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one straight worn tan dirt road connecting north edge to south edge
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: exact centered vertical corridor in one square atlas cell
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: identical centered north and south openings; no east or west exit; no taper at connected boundaries; no buildings, units, text, UI, shadows, watermark, or scenery
```

Acceptance:
- Connected edge openings have identical width and pixel positions.
- Repeated and rotated instances form a continuous line without gaps.

## 4. Road Corner Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_corner.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | Canonical north-east 90-degree road module |

Style rules:
- Rounded interior turn with no diagonal movement implication.
- North and east edge openings use the canonical corridor width.
- Rotations preserve pixel alignment.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one worn tan dirt road making a clean 90-degree turn from north to east
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: one exact square module with centered north and east exits
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: north and east exits only; no south or west exit; no diagonal shortcut; no buildings, units, text, UI, shadows, watermark, or scenery
```

Acceptance:
- Both openings exactly match the straight module.
- All four rotations preserve edge continuity.

## 5. Road Tee Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_tee.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | Canonical north-east-west three-way road module |

Style rules:
- Three corridors meet cleanly in one readable central junction.
- The missing south connection remains visually closed.
- Same road material and edge positions as other modules.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one T-shaped worn tan dirt road joining north, east, and west edges
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: exact centered three-way junction in one square atlas cell
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: north, east, and west exits only; south edge must remain closed; no buildings, units, text, UI, shadows, watermark, or scenery
```

Acceptance:
- No false opening exists on the closed side.
- All four rotations match neighboring straight and corner openings.

## 6. Road Cross Module

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/tiles/road_cross.png` |
| Category | terrain tile |
| Size | 64x64 RGBA PNG, transparent outside the road fringe |
| Role | Four-way road junction for connection mask 15 |

Style rules:
- Four equal corridors meet at a centered compact junction.
- No preferred direction or asymmetric decoration.
- Same material and connection width as all other modules.

Prompt:
```text
Use case: stylized-concept
Asset type: modular Flutter + Flame tower-defense road tile
Primary request: one four-way worn tan dirt road crossing connected to all four cell edges
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art matching the supplied Stage 1 road reference
Composition/framing: exact centered symmetric crossing in one square atlas cell
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: equal north, east, south, and west exits; no buildings, units, text, UI, shadows, watermark, or scenery
```

Acceptance:
- All four openings exactly match the canonical corridor.
- Rotation produces no visible change or jitter.

## 7. Bombardment Shell Animation Strip

| Field | Value |
| --- | --- |
| File | `assets/sprites/effects/bombardment_shell_strip.png` |
| Category | combat VFX atlas |
| Size | 384x96 RGBA PNG containing four 96x96 frames |
| Role | Looping visual for a falling, rotating incendiary cannon shell |

Style rules:
- Four left-to-right frames share the same shell silhouette and pivot.
- Flame and pixel smoke change between frames while the shell remains stable.
- Matches the existing dark iron, orange flame, top-down 3/4 pixel style.

Prompt:
```text
Use case: stylized-concept
Asset type: four-frame projectile VFX atlas for a Flutter + Flame fantasy tower-defense game
Input image: the existing cannonball projectile is the identity, palette, and rendering-style reference
Primary request: exactly four isolated animation frames of the same dark iron cannon shell in flight, with changing orange flame tongues, sparks, and compact pixel smoke
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art, hard pixel clusters suitable for chroma-key extraction
Composition/framing: precise 4 by 1 grid, one centered shell per equal cell, identical size and pivot, generous separation
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: exactly four frames; no impact explosion, ground, buildings, characters, text, UI, watermark, soft transparent haze, or cast shadow; do not use #FF00FF in the effect
```

Acceptance:
- Frame cells remain visually registered during looping.
- Transparent corners and no magenta fringe after export.
- Readable at approximately 36-44 logical pixels on a mobile battlefield.

## 8. Bombardment Impact Animation Strip

| Field | Value |
| --- | --- |
| File | `assets/sprites/effects/bombardment_impact_strip.png` |
| Category | combat VFX atlas |
| Size | 576x96 RGBA PNG containing six 96x96 frames |
| Role | Non-looping impact flash, debris, blast, and dissipating pixel smoke |

Style rules:
- Frames progress from compact flash to expanding debris and shrinking smoke.
- The visual center stays fixed in every frame.
- Pixel clusters remain crisp; no photographic or soft volumetric smoke.

Prompt:
```text
Use case: stylized-concept
Asset type: six-frame impact VFX atlas for a Flutter + Flame fantasy tower-defense game
Input image: the existing cannonball projectile is the palette and pixel-style reference
Primary request: exactly six sequential frames showing a cannon shell impact: bright compact flash, orange fire burst, dark debris ring, broad smoky blast, collapsing smoke, final ember wisps
Style/medium: crisp polished top-down 3/4 32-bit fantasy pixel art with hard-edged pixel smoke clusters
Composition/framing: precise 6 by 1 grid, one centered impact per equal cell, identical pivot and generous separation
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background
Constraints: exactly six frames; no projectile in flight, ground plane, crater baked into terrain, buildings, characters, text, UI, watermark, soft transparent haze, or cast shadow; do not use #FF00FF in the effect
```

Acceptance:
- Sequence reads clearly from ignition to dissipation without looping.
- Transparent corners and no magenta fringe after export.
- Does not obscure more than the authored bombardment radius at peak frame.

