# Stage 1 Constrained 3/4 Pixel Visual Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove the constrained top-down 3/4 pixel-art direction on the tutorial and Stage 1 using aspect-preserving bottom-center pivots, Y sorting, deterministic connected walls, and a small documented AI-assisted asset set.

**Architecture:** Add opt-in render metadata beside the existing visual catalogs and gate it to tutorial/Stage 1 so later campaign stages retain their current assets. Compose wall connections deterministically from authored modules, collect solid world objects into sortable render items, and keep ranges/VFX/floating text in readability layers above the sorted world pass.

**Tech Stack:** Flutter Canvas, Flame image registry, Dart, PNG assets, Python + Pillow extraction script, built-in image generation

---

## File map

- Create `lib/game/rendering/structure_visual_definition.dart`: footprint, anchor, render size, offset, layer, shadow metadata.
- Create `lib/game/rendering/barrier_connectivity.dart`: four-bit mask and deterministic module selection.
- Create `lib/game/rendering/world_render_item.dart`: stable z/Y comparator.
- Modify `lib/game/rendering/visual_catalog.dart`: Stage 1 metadata catalog.
- Modify `lib/game/rendering/game_visual_registry.dart`: Stage 1 images and wall modules.
- Modify `lib/game/core/depense_game.dart`: aspect-preserving bottom-center drawing, sorted world pass, tile roads, connected barriers.
- Create `tool/extract_stage1_visual_sheet.py`: deterministic crop, chroma removal, trim, resize, export.
- Create `docs/generated/stage1-constrained-b-asset-record.md`: prompts, source, license, export map, fallbacks.
- Add PNGs under `assets/sprites/stage1/`.
- Create `test/structure_visual_definition_test.dart`, `test/barrier_connectivity_test.dart`, `test/world_render_item_test.dart`, and extend `test/run_offers_and_road_tiles_test.dart`.

### Task 1: Render metadata with bottom-center anchors

**Files:**
- Create: `lib/game/rendering/structure_visual_definition.dart`
- Create: `test/structure_visual_definition_test.dart`

- [ ] **Step 1: Write failing geometry tests**

```dart
import 'dart:ui';

import 'package:depense_game/game/rendering/structure_visual_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom-center pivot preserves source aspect ratio', () {
    const visual = StructureVisualDefinition(
      assetPath: 'assets/sprites/stage1/towers/archer.png',
      sourcePixelSize: Size(128, 160),
      footprintTiles: Size(1, 1),
      renderTiles: Size(1, 1.25),
      anchor: Offset(0.5, 0.86),
      drawOffsetTiles: Offset.zero,
      baseLayer: WorldRenderLayer.structure,
      castsShadow: true,
    );
    final rect = visual.destinationRect(worldAnchor: const Offset(200, 300), tileSize: 64);
    expect(rect.width / rect.height, closeTo(128 / 160, 0.001));
    expect(rect.left + rect.width * 0.5, closeTo(200, 0.001));
    expect(rect.top + rect.height * 0.86, closeTo(300, 0.001));
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/structure_visual_definition_test.dart`

Expected: compilation fails because the metadata type is absent.

- [ ] **Step 3: Implement exact metadata and geometry**

```dart
import 'dart:ui';

enum WorldRenderLayer { groundObject, structure, unit }

class StructureVisualDefinition {
  const StructureVisualDefinition({
    required this.assetPath,
    required this.sourcePixelSize,
    required this.footprintTiles,
    required this.renderTiles,
    required this.anchor,
    required this.drawOffsetTiles,
    required this.baseLayer,
    required this.castsShadow,
  });

  final String assetPath;
  final Size sourcePixelSize;
  final Size footprintTiles;
  final Size renderTiles;
  final Offset anchor;
  final Offset drawOffsetTiles;
  final WorldRenderLayer baseLayer;
  final bool castsShadow;

  Rect destinationRect({required Offset worldAnchor, required double tileSize}) {
    final requested = Size(renderTiles.width * tileSize, renderTiles.height * tileSize);
    final sourceRatio = sourcePixelSize.width / sourcePixelSize.height;
    final height = requested.height;
    final width = height * sourceRatio;
    final pivot = worldAnchor + drawOffsetTiles * tileSize;
    return Rect.fromLTWH(
      pivot.dx - width * anchor.dx,
      pivot.dy - height * anchor.dy,
      width,
      height,
    );
  }
}
```

- [ ] **Step 4: Run and commit**

Run: `dart format lib/game/rendering/structure_visual_definition.dart test/structure_visual_definition_test.dart && flutter test test/structure_visual_definition_test.dart`

Expected: geometry test passes.

Commit: `git add lib/game/rendering/structure_visual_definition.dart test/structure_visual_definition_test.dart && git commit -m "feat: add anchored structure render metadata"`

### Task 2: Deterministic connected-wall masks

**Files:**
- Create: `lib/game/rendering/barrier_connectivity.dart`
- Create: `test/barrier_connectivity_test.dart`

- [ ] **Step 1: Write all-mask tests**

```dart
void main() {
  test('four neighbors map to a stable four-bit mask', () {
    expect(BarrierConnectivity.mask(north: true, east: true, south: true, west: true), 15);
    expect(BarrierConnectivity.mask(north: true, east: false, south: true, west: false), 5);
    expect(BarrierConnectivity.mask(north: false, east: true, south: false, west: true), 10);
  });

  test('all sixteen masks resolve to explicit module recipes', () {
    final recipes = {for (var mask = 0; mask < 16; mask++) BarrierConnectivity.recipe(mask)};
    expect(recipes, hasLength(16));
    expect(BarrierConnectivity.recipe(15).shape, BarrierConnectionShape.cross);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/barrier_connectivity_test.dart`

Expected: compilation fails because connectivity types do not exist.

- [ ] **Step 3: Implement masks and explicit recipes**

Use bits north `1`, east `2`, south `4`, west `8`. Define `BarrierConnectionShape` values `isolated`, `cap`, `straight`, `corner`, `tee`, `cross`, and a `BarrierConnectionRecipe(shape, quarterTurns)` table containing exactly sixteen entries. Throw `RangeError.range(mask, 0, 15)` for invalid input. Keep the algorithm independent of wall material so all four existing `BarrierKind` values share the same connection semantics.

- [ ] **Step 4: Run and commit**

Run: `dart format lib/game/rendering/barrier_connectivity.dart test/barrier_connectivity_test.dart && flutter test test/barrier_connectivity_test.dart`

Expected: all 16 cases pass.

Commit: `git add lib/game/rendering/barrier_connectivity.dart test/barrier_connectivity_test.dart && git commit -m "feat: add deterministic connected wall recipes"`

### Task 3: Stable z plus ground-Y ordering

**Files:**
- Create: `lib/game/rendering/world_render_item.dart`
- Create: `test/world_render_item_test.dart`

- [ ] **Step 1: Write failing ordering tests**

```dart
void main() {
  test('items sort by layer then ground y then stable id', () {
    final items = [
      WorldRenderItem(layer: 1, groundY: 200, stableId: 2, draw: (_) {}),
      WorldRenderItem(layer: 1, groundY: 100, stableId: 5, draw: (_) {}),
      WorldRenderItem(layer: 0, groundY: 900, stableId: 1, draw: (_) {}),
      WorldRenderItem(layer: 1, groundY: 200, stableId: 1, draw: (_) {}),
    ]..sort(WorldRenderItem.compare);
    expect(items.map((item) => item.stableId), [1, 5, 1, 2]);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/world_render_item_test.dart`

Expected: compilation fails because `WorldRenderItem` is absent.

- [ ] **Step 3: Implement the render item**

```dart
import 'dart:ui';

class WorldRenderItem {
  const WorldRenderItem({
    required this.layer,
    required this.groundY,
    required this.stableId,
    required this.draw,
  });

  final int layer;
  final double groundY;
  final int stableId;
  final void Function(Canvas canvas) draw;

  static int compare(WorldRenderItem a, WorldRenderItem b) {
    final byLayer = a.layer.compareTo(b.layer);
    if (byLayer != 0) return byLayer;
    final byY = a.groundY.compareTo(b.groundY);
    if (byY != 0) return byY;
    return a.stableId.compareTo(b.stableId);
  }
}
```

- [ ] **Step 4: Run and commit**

Run: `dart format lib/game/rendering/world_render_item.dart test/world_render_item_test.dart && flutter test test/world_render_item_test.dart`

Expected: order test passes.

Commit: `git add lib/game/rendering/world_render_item.dart test/world_render_item_test.dart && git commit -m "feat: add stable world render ordering"`

### Task 4: Generate and export the constrained Stage 1 art set

**Files:**
- Create: `docs/generated/stage1-constrained-b-asset-record.md`
- Create: `tool/extract_stage1_visual_sheet.py`
- Create: `assets/sprites/stage1/tiles/*.png`
- Create: `assets/sprites/stage1/walls/{wood,stone,fortress,keep}/*.png`
- Create: `assets/sprites/stage1/towers/*.png`
- Create: `assets/sprites/stage1/environment/*.png`
- Create: `assets/sprites/stage1/ui/*.png`

- [ ] **Step 1: Generate two labeled source sheets with the built-in image generator**

Sheet A prompt:

```text
Orthographic top-down 3/4 pixel art sprite atlas for a cozy high-readability fantasy tower defense mobile game. Transparent/chroma-key flat magenta background, no scenery, no text, no UI, no perspective variation. Exactly nine isolated objects in a 3x3 grid with generous empty padding: archer tower, guard barracks, mage obelisk, frost shrine, coin mill, ballista tower, ember keep, blue-roof tutorial citadel, wooden supply cart. Consistent light from upper left, crisp 1-pixel dark outlines, compact silhouettes, 32-bit color, each object centered on the same bottom-center ground pivot, no object touches a cell edge.
```

Sheet B prompt:

```text
Orthographic top-down 3/4 pixel art modular tile atlas for a fantasy tower defense game on a flat magenta chroma-key background. Exactly sixteen isolated modules in a 4x4 grid: grass base, grass variation, dirt road straight, dirt road corner, dirt road cap, road fill, wood wall post/rail/corner, stone wall post/rail/corner, fortress wall post/rail/corner, glowing keep wall module. Identical 64-pixel tile footprint and connection points, light from upper left, crisp pixel edges, no text, no characters, no merged background, wide padding.
```

Save raw outputs under `docs/generated/` and record generation date, prompt, model/tool (`OpenAI built-in image generation`), project-owned generation status, and intended in-game exports.

- [ ] **Step 2: Implement deterministic extraction**

`tool/extract_stage1_visual_sheet.py` must use Pillow to open a source sheet, crop by an explicit JSON-like list of `(name, column, row, target_width, target_height)`, remove magenta pixels by HSV distance with a soft one-pixel alpha edge, trim transparent padding, fit without changing aspect ratio, align visible pixels to a supplied bottom-center pivot, disable interpolation (`Image.Resampling.NEAREST`), and save RGBA PNGs. The script accepts `--sheet-a`, `--sheet-b`, and `--output-root`; it exits non-zero if a cell is empty or a required export is missing.

- [ ] **Step 3: Run extraction and validate exports**

Run: `python tool/extract_stage1_visual_sheet.py --sheet-a docs/generated/stage1-structures-source.png --sheet-b docs/generated/stage1-modules-source.png --output-root assets/sprites/stage1`

Expected: 7 T1 tower PNGs at 128×128, citadel at or below 256×256, wall/tile modules at 64×64, and direction markers at 64×64. No output has a non-transparent magenta corner pixel.

- [ ] **Step 4: Commit source record, script, and exports**

Commit: `git add docs/generated/stage1-constrained-b-asset-record.md docs/generated/stage1-structures-source.png docs/generated/stage1-modules-source.png tool/extract_stage1_visual_sheet.py assets/sprites/stage1 && git commit -m "art: add constrained Stage 1 pixel slice"`

### Task 5: Opt-in catalog and registry loading

**Files:**
- Modify: `lib/game/rendering/visual_catalog.dart`
- Modify: `lib/game/rendering/game_visual_registry.dart`
- Create: `test/stage1_visual_catalog_test.dart`

- [ ] **Step 1: Write failing catalog tests**

```dart
void main() {
  test('tutorial and stage one use B metadata while stage two falls back', () {
    expect(StageOneVisualCatalog.enabledForStage(0), isTrue);
    expect(StageOneVisualCatalog.enabledForStage(1), isTrue);
    expect(StageOneVisualCatalog.enabledForStage(2), isFalse);
    expect(StageOneVisualCatalog.tower(TowerKind.archer).anchor.dy, greaterThan(0.5));
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/stage1_visual_catalog_test.dart`

Expected: compilation fails because `StageOneVisualCatalog` does not exist.

- [ ] **Step 3: Add complete Stage 1 metadata and warm-up**

Define entries for seven T1 tower kinds, four barrier materials, citadel, sparse props, grass/path modules, and four direction markers. Every structure entry has explicit source size, footprint, bottom-center anchor, render size, offset, layer, and shadow flag. `GameVisualRegistry.warmUp()` loads these paths alongside existing images; getters return Stage 1 assets only when `stage.number <= 1`, and otherwise return the existing catalog images.

- [ ] **Step 4: Verify and commit**

Run: `dart format lib/game/rendering/visual_catalog.dart lib/game/rendering/game_visual_registry.dart test/stage1_visual_catalog_test.dart && flutter test test/stage1_visual_catalog_test.dart && flutter analyze`

Expected: catalog tests pass; all declared assets load during test warm-up; analysis clean.

Commit: `git add lib/game/rendering/visual_catalog.dart lib/game/rendering/game_visual_registry.dart test/stage1_visual_catalog_test.dart && git commit -m "feat: register Stage 1 constrained visuals"`

### Task 6: Aspect-preserving sorted render pass and connected walls

**Files:**
- Modify: `lib/game/core/depense_game.dart:1132-1162,5265-5304,5430-5509,6111-6181,7319-7355`
- Modify: `test/run_offers_and_road_tiles_test.dart`
- Modify: `test/barrier_connectivity_test.dart`

- [ ] **Step 1: Add render-plan regression tests**

Add pure helper assertions that Stage 1 road paths resolve to straight/corner/cap sprite IDs rather than the Canvas-only tan stroke, adjacent same-material barriers generate the expected masks, mixed materials do not connect, and world-item ground-Y values use collision/placement positions rather than image top-left coordinates.

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/run_offers_and_road_tiles_test.dart test/barrier_connectivity_test.dart test/world_render_item_test.dart`

Expected: new road and material-connectivity assertions fail against the old renderer.

- [ ] **Step 3: Add aspect-preserving drawing**

Add `_drawAnchoredSprite(Canvas, ui.Image, StructureVisualDefinition, Offset worldAnchor, ...)` that uses `definition.destinationRect`, draws an elliptical ground shadow when requested, and calls `drawImageRect` without forcing width and height to be equal. Retain `_drawSprite` for legacy/VFX callers.

- [ ] **Step 4: Add connected barriers and Stage 1 road tiles**

For each barrier, check north/east/south/west grid neighbors of the same `BarrierKind`, compute the mask, resolve the recipe, and draw the material module(s) with fixed connection points. Replace `_drawRoadTiles` only for tutorial/Stage 1 with loaded grass/path straight/corner/cap tiles; retain the existing Canvas path renderer as the Stage 2–30 fallback.

- [ ] **Step 5: Add the sortable solid-world pass**

After ground and roads, collect background obstacles that overlap units, barriers, citadel, towers, heroes, barracks defenders, and enemies into `WorldRenderItem` entries. Sort by `layer`, bottom ground Y, and stable index; draw them in one pass. Draw selection ranges before the solid pass and slashes, projectiles, impacts, floating damage, tutorial highlights, and foreground canopy after it.

- [ ] **Step 6: Verify and commit**

Run: `dart format lib/game/core/depense_game.dart test/run_offers_and_road_tiles_test.dart test/barrier_connectivity_test.dart && flutter test test/structure_visual_definition_test.dart test/barrier_connectivity_test.dart test/world_render_item_test.dart test/run_offers_and_road_tiles_test.dart && flutter analyze`

Expected: all render-plan tests pass; analysis clean.

Commit: `git add lib/game/core/depense_game.dart test/run_offers_and_road_tiles_test.dart test/barrier_connectivity_test.dart && git commit -m "feat: render Stage 1 with connected depth-sorted structures"`

### Task 7: Visual slice regression and device handoff

**Files:**
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`
- Modify: `docs/generated/stage1-constrained-b-asset-record.md`

- [ ] **Step 1: Run automated release checks**

Run: `flutter analyze && flutter test && flutter build apk --debug`

Expected: analysis clean, every test passes, and `build/app/outputs/flutter-apk/app-debug.apk` is produced.

- [ ] **Step 2: Record the slice boundary and device checklist**

Document that tutorial/Stage 1 T1 uses constrained B assets, while T2/T3/branches, heroes/enemies, and Stage 2–30 intentionally retain current fallbacks. Device checks: stable frame pacing, readable 1× and 2.5× zoom, correct pivots, no square stretching, connected straight/corner/T/cross walls, natural overlap while units pass towers/walls, and no combat-stat differences.

- [ ] **Step 3: Commit verification notes**

Commit: `git add docs/exec-plans/active/initial-defense-game-foundation.md docs/generated/stage1-constrained-b-asset-record.md && git commit -m "docs: record Stage 1 visual slice verification"`
