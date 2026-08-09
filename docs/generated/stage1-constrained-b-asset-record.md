# Stage 1 Constrained-B Asset Record

## Scope

- Runtime scope: tutorial map and Stage 1 only.
- New assets: seven tier-1 towers, tutorial citadel, five frontier props, two grass tiles, four road modules, and connected wall modules.
- Intentional fallbacks: tower tier 2/3 and branches, heroes, enemies, VFX, and Stage 2-30 keep the current art until the slice passes device review.
- Gameplay data, enemy stats, wave composition, tower stats, and difficulty were not changed by this visual slice.

## Generation source and usage

- Generated: 2026-08-09
- Tool: OpenAI built-in image generation
- Use case: `stylized-concept`
- Source status: AI-generated specifically for this project; no third-party sprite pack was used as an image input.
- Project use: exported PNGs are project-controlled generated assets. Use remains subject to the service/account terms under which they were generated.
- Raw sources:
  - `docs/generated/stage1-structures-source.png`
  - `docs/generated/stage1-modules-source.png`
  - `docs/generated/stage1-props-source.png`
- Chroma-key intermediates:
  - `docs/generated/stage1-structures-source-alpha.png`
  - `docs/generated/stage1-modules-source-alpha.png`
  - `docs/generated/stage1-props-source-alpha.png`
- Deterministic exporter: `tool/extract_stage1_visual_sheet.py`

## Final prompts

### Structure sheet

```text
Use case: stylized-concept
Asset type: production game sprite atlas source sheet for Flutter + Flame tower defense
Primary request: orthographic top-down 3/4 pixel-art atlas containing exactly nine isolated fantasy defense objects in a precise 3 by 3 grid.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal; absolutely uniform, no texture, no shadows, no gradient, no floor plane.
Subject, row 1 left to right: archer tower, guard barracks, mage obelisk.
Subject, row 2 left to right: frost shrine, coin mill, ballista tower.
Subject, row 3 left to right: ember keep, blue-roof tutorial citadel, wooden supply cart.
Style/medium: polished high-readability 32-bit pixel art; cozy fantasy; crisp one-pixel dark outlines; consistent detail density and palette.
Composition/framing: each object centered inside an equal atlas cell with generous empty padding; consistent orthographic top-down 3/4 view; same bottom-center ground pivot; objects must not touch or overlap cell edges.
Lighting/mood: clean upper-left key light, subtle self-contained object shading only.
Constraints: exactly nine objects and no others; no text, labels, UI, characters, scenery, watermark, cast shadow, contact shadow, reflection, or merged ground; no perspective variation; do not use #ff00ff in any object; crisp separable silhouettes suitable for chroma-key extraction.
```

### Modular terrain and wall sheet

```text
Use case: stylized-concept
Asset type: production modular terrain and connected-wall sprite atlas source sheet for Flutter + Flame tower defense
Primary request: orthographic top-down 3/4 pixel-art atlas containing exactly sixteen isolated square-footprint modules in a precise 4 by 4 grid.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal; absolutely uniform, no texture, no shadows, no gradient, no floor plane.
Subject, row 1 left to right: seamless grass base tile, alternate grass tile, dirt road straight vertical tile, dirt road 90-degree corner tile.
Subject, row 2 left to right: dirt road end-cap tile, dirt road four-way fill tile, wooden wall isolated post, wooden wall straight rail module.
Subject, row 3 left to right: wooden wall corner module, stone wall isolated post, stone wall straight module, stone wall corner module.
Subject, row 4 left to right: reinforced fortress wall isolated post, reinforced fortress wall straight module, reinforced fortress wall corner module, blue-rune keep wall module.
Style/medium: polished high-readability 32-bit pixel art matching a cozy fantasy defense game; crisp one-pixel dark outlines; consistent stone, wood, dirt, and grass palette.
Composition/framing: each module centered inside an equal atlas cell with generous empty padding; identical square 64-pixel gameplay footprint and mathematically consistent connection points at cell-edge midpoints; same orthographic top-down 3/4 camera and upper-left light; modules must not touch or overlap neighboring atlas cells.
Constraints: exactly sixteen modules and no others; no text, labels, UI, characters, scenery, watermark, cast shadow, contact shadow, reflection, or merged background; no perspective variation; do not use #ff00ff inside modules; crisp separable silhouettes; wall ends must align when tiles are placed edge-to-edge.
```

### Frontier environment prop sheet

```text
Use case: stylized-concept
Asset type: production environment prop sprite atlas source sheet for a Flutter + Flame fantasy tower-defense game
Primary request: create exactly four isolated orthographic top-down 3/4 pixel-art environment props in a precise 2 by 2 grid, matching a polished cozy fantasy 32-bit pixel-art tower-defense visual style.
Scene/backdrop: perfectly flat uniform solid #ff00ff chroma-key background, no texture, no gradient, no floor plane.
Subject, row 1 left to right: a compact timber-and-stone village gatehouse with a warm brown shingle roof and open central passage; a readable wooden road signpost with two arrow boards.
Subject, row 2 left to right: a round stone well with a small blue-gray shingle canopy and wooden crank; a broken wooden supply wagon with one damaged wheel, a small crate, and folded beige canvas.
Style/medium: polished high-readability pixel art, cozy fantasy, crisp one-pixel dark outlines, consistent palette and detail density with top-down 3/4 towers, buildings and modular walls; readable on a portrait mobile game battlefield.
Composition/framing: exact equal 2x2 atlas cells; each object centered with generous empty padding; identical orthographic top-down 3/4 camera; upper-left key light; consistent bottom-center ground pivot; no object touches or overlaps cell boundaries. Gatehouse may be larger than the other props but must stay entirely within its cell.
Constraints: exactly four objects and no others; no text, labels, UI, characters, scenery, watermark, cast shadow, contact shadow, reflection, or merged ground; no perspective variation; do not use #ff00ff inside any object; crisp separable silhouettes suitable for chroma-key extraction.
```

## Export and render rules

- Source sheets are keyed with the installed image-generation chroma-removal helper using border sampling, soft matte, despill, and a one-pixel edge contraction.
- The exporter crops fixed atlas cells, trims alpha bounds, preserves aspect ratio, resizes with nearest-neighbor sampling, and aligns visible content to a bottom-center pivot.
- Towers export to 128x160 RGBA, the citadel to 224x224 RGBA, the four frontier props to explicit 112–256px RGBA canvases, and terrain/wall modules to 64x64 RGBA.
- Runtime structures use explicit source size, footprint, render size, pivot, draw offset, layer, and shadow metadata.
- Connected walls resolve a deterministic N/E/S/W four-bit mask; mixed materials do not connect.
- Stage 1 solid structures and units are ordered by their ground Y coordinate with a stable tie-breaker.

## Device acceptance checklist

- Stable frame pacing on the target Android device.
- Tower/citadel proportions remain correct at 1x and 2.5x zoom.
- No magenta fringe or opaque corner pixels.
- Bottom-center pivots stay on their placement cells.
- Straight, corner, T, and cross wall arrangements remain visually connected.
- Units pass in front of or behind solid objects according to ground Y.
- Tutorial callouts and combat UI remain readable over the new art.
- No difference in wave pressure, enemy behavior, damage, economy, or stage-clear results.

## Automated verification

- `flutter test`: 125 tests passed.
- `flutter analyze`: no issues.
- `flutter build apk --debug`: produced `build/app/outputs/flutter-apk/app-debug.apk`.
- 430×900 browser preview: verified terrain blend, compact tutorial card, four-direction lesson placement, new citadel/walls, and frontier prop replacements.
- Real-device visual and frame-pacing checks remain intentionally open for the Stage 1 slice decision.
