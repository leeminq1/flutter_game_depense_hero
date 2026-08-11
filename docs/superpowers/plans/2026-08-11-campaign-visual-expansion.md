# Campaign Visual Expansion Implementation Plan

> Execute on `main`. Preserve the unrelated Windows generated-plugin changes
> and `.superpowers/` working-tree content.

**Goal:** Extend the approved Stage 1 visual system to all 30 campaign Stages,
eliminate road seams for every route topology, animate bombardment, and prepare
an all-Stages-unlocked Android review build without changing combat balance.

**Architecture:** Replace Stage-number visual branching with a theme-aware
campaign catalog. Keep Stage definitions authoritative for simulation and use a
deterministic six-module road system for all 16 connectivity masks. Add two
age-indexed effect atlases for bombardment rendering only.

**Tech:** Flutter, Flame, Dart canvas rendering, RGBA PNG atlases, Python/Pillow
asset exporters, Flutter tests.

---

## Task 1: Complete the road topology contract

**Files:**
- Create: `lib/game/rendering/campaign_road_tile_plan.dart`
- Create: `test/campaign_road_tile_plan_test.dart`
- Remove after migration: `lib/game/rendering/stage1_road_tile_plan.dart`
- Remove after migration: `test/stage1_road_tile_plan_test.dart`

1. Write failing tests for all 16 masks, including distinct isolated, tee, and
   cross kinds and deterministic rotations.
2. Add edge-opening metadata so tests can assert that resolved tiles expose
   exactly the N/E/S/W bits in the input mask.
3. Implement the minimum six-kind resolver and make the focused test pass.
4. Keep the full-cell barrier plan behavior unchanged while moving it under the
   campaign-named module.

Verify:

```powershell
flutter test test/campaign_road_tile_plan_test.dart
```

## Task 2: Generate and normalize the campaign road assets

**Files:**
- Create: `docs/generated/campaign-road-modules-source.png`
- Create: `tool/build_campaign_road_tiles.py`
- Create: `assets/sprites/campaign/tiles/road_isolated.png`
- Create: `assets/sprites/campaign/tiles/road_cap.png`
- Create: `assets/sprites/campaign/tiles/road_straight.png`
- Create: `assets/sprites/campaign/tiles/road_corner.png`
- Create: `assets/sprites/campaign/tiles/road_tee.png`
- Create: `assets/sprites/campaign/tiles/road_cross.png`
- Update: `docs/generated/campaign-visual-expansion-asset-spec.md`

1. Generate one six-cell source atlas using the existing Stage 1 road modules
   as strict style references.
2. Remove the chroma-key background with the installed image-generation helper.
3. Add a deterministic Pillow exporter that uses the generated source for
   texture but enforces exact 64x64 connection geometry and nearest-neighbor
   output.
4. Add validation for RGBA mode, transparent corners, canonical edge widths,
   and absent false exits.
5. Run the exporter and visually inspect all six final modules.

Verify:

```powershell
python tool/build_campaign_road_tiles.py --check
```

## Task 3: Generalize the visual catalog to the full campaign

**Files:**
- Update: `lib/game/rendering/visual_catalog.dart`
- Update: `lib/game/rendering/game_visual_registry.dart`
- Replace: `test/stage1_visual_catalog_test.dart`
- Create: `test/campaign_visual_catalog_test.dart`

1. Write failing tests that require Stages 1-30 to resolve a campaign visual
   theme and require every declared asset to exist.
2. Introduce theme metadata for ground base/tint, road tint, prop scale, and
   landmark scale for all six `StageEnvironmentTheme` values.
3. Keep the completed Stage 1 tower levels 1-3, barrier modules, and citadel as
   shared campaign player assets.
4. Add the six road module paths and load them through a campaign sprite map.
5. Preserve legacy environment loading while applying campaign anchor/scale
   metadata at render time.

Verify:

```powershell
flutter test test/campaign_visual_catalog_test.dart
```

## Task 4: Render seamless roads and campaign art on Stages 1-30

**Files:**
- Update: `lib/game/core/depense_game.dart`
- Update: `test/tile_grid_stage_data_test.dart`

1. Add failing route-render-contract tests across every Wave of every Stage.
2. Replace `_drawStageOneRoadTiles` with campaign road rendering using isolated,
   cap, straight, corner, tee, and cross modules.
3. Draw tiles at exactly `_tileSize`; remove the 1.04 overscale workaround.
4. Apply theme-aware ground treatment to every Stage.
5. Use the shared campaign tower/barrier/citadel art on every Stage.
6. Render existing authored environment props with normalized bottom-center
   anchors and theme-aware sizes instead of Stage 1-only path substitutions.
7. Keep buildable, enemy route, and world-coordinate calculations unchanged.

Verify:

```powershell
flutter test test/tile_grid_stage_data_test.dart test/campaign_visual_catalog_test.dart
```

## Task 5: Generate and implement bombardment animation

**Files:**
- Create: `docs/generated/campaign-bombardment-source.png`
- Create: `tool/extract_bombardment_effects.py`
- Create: `assets/sprites/effects/bombardment_shell_strip.png`
- Create: `assets/sprites/effects/bombardment_impact_strip.png`
- Update: `lib/game/rendering/visual_catalog.dart`
- Update: `lib/game/rendering/game_visual_registry.dart`
- Update: `lib/game/core/depense_game.dart`
- Create: `test/bombardment_visual_plan_test.dart`

1. Write failing pure-Dart tests for in-flight looping frame selection and
   non-looping impact frame clamping.
2. Generate a keyed projectile/impact source atlas using the existing
   cannonball as the identity reference.
3. Remove chroma key and export registered 96x96 frames into the two strip
   atlases.
4. Load both atlases once and render frame source rectangles by visual age.
5. Add a compact spark/smoke trail and retain the procedural warning and shock
   ring.
6. Do not change bombardment damage, timing, target, count, or probability.

Verify:

```powershell
flutter test test/bombardment_visual_plan_test.dart
```

## Task 6: Enable the all-Stages content-review flag

**Files:**
- Update: `lib/data/persistence/progression_dev_flags.dart`
- Update: `test/progress_store_test.dart`

1. Change the existing test to require all 30 Stages unlocked in the review
   build.
2. Set `kUnlockAllCampaignStagesForDevelopment` to `true` with the release
   warning intact.
3. Run progress-store tests.

Verify:

```powershell
flutter test test/progress_store_test.dart
```

## Task 7: Audit superseded assets and update records

**Files:**
- Update: `docs/generated/campaign-visual-expansion-asset-spec.md`
- Update: `docs/exec-plans/active/initial-defense-game-foundation.md`
- Potentially remove only proven-unreferenced Stage 1 road files.

1. Record built-in image-generation prompts, raw source paths, chroma-removal
   settings, exporter commands, and final outputs.
2. Search code, tests, tools, docs, and `pubspec.yaml` for every candidate old
   path.
3. Remove only superseded road/effect assets with zero live references.
4. Record the six-theme expansion and review-build unlock state in the active
   execution plan.

Verify:

```powershell
rg -n "road_(cap|corner|fill|straight)|cannonball_projectile" lib test tool pubspec.yaml
git diff --check
```

## Task 8: Full verification and device handoff

1. Format changed Dart files.
2. Run targeted road, campaign, bombardment, progression, and Stage data tests.
3. Run the full Flutter suite.
4. Run static analysis.
5. Build an Android debug APK.
6. Confirm the APK path and remind that all 30 Stages are intentionally unlocked
   only for this content-review build.

Verify:

```powershell
dart format lib test
flutter test
flutter analyze
flutter build apk --debug
```

