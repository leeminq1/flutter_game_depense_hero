# Stage 1 Device UX And Tower Tiers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the tutorial and combat layout stable on phones, center Stage 1 at a slightly enlarged default view, and give all seven Stage 1 towers matching T2/T3 upgrade art.

**Architecture:** Flutter keeps one bottom build-panel structure in preparation and combat so the Flame viewport does not resize. The tutorial overlay moves inside the battlefield Stack. Flame owns a Stage 1 default camera baseline, while `StageOneVisualCatalog` selects level-specific tower assets independently from combat upgrade logic.

**Tech Stack:** Flutter widgets, Flame input/rendering, Dart unit/widget tests, PNG sprite assets, OpenAI image generation, Android Debug APK/ADB.

---

## File map

- Modify `lib/app/screens/game_screen.dart`: battlefield-scoped tutorial overlay and stable build bar.
- Modify `lib/app/tutorial/tutorial_overlay.dart`: bottom-align every tutorial card.
- Modify `lib/game/input/battlefield_camera_transform.dart`: configurable default camera baseline.
- Modify `lib/game/core/depense_game.dart`: initialize/reset Stage 1 camera and restore centered grid.
- Modify `lib/game/rendering/visual_catalog.dart`: Stage 1 tower tier paths and render definitions.
- Modify `lib/game/rendering/game_visual_registry.dart`: warm all Stage 1 tier assets.
- Modify `test/tutorial_overlay_test.dart`: all steps use bottom guidance placement.
- Modify `test/combat_ux_widget_test.dart`: preparation/combat panel height remains stable.
- Modify `test/battlefield_camera_transform_test.dart`: Stage 1 default baseline semantics.
- Modify `test/stage1_visual_catalog_test.dart`: seven T1/T2/T3 paths and T4-to-T3 clamping.
- Create 14 PNG files under `assets/sprites/stage1/towers/`.
- Create `docs/generated/stage1-tower-tier-assets.md`: prompts, references, paths, and audit.

### Task 1: Battlefield-scoped tutorial guidance

**Files:**
- Modify: `test/tutorial_overlay_test.dart`
- Modify: `lib/app/tutorial/tutorial_overlay.dart`
- Modify: `lib/app/screens/game_screen.dart:820-1100`

- [ ] **Step 1: Write the failing widget test**

Add a test that pumps `TutorialOverlay`, advances the director through placement and recap steps, and checks that `tutorial-guidance-card` remains in the lower half:

```dart
final cardRect = tester.getRect(
  find.byKey(const ValueKey('tutorial-guidance-card')),
);
expect(cardRect.center.dy, greaterThan(400));
```

In `test/tutorial_game_screen_test.dart`, assert that the `TutorialOverlay` ancestor is the widget keyed `battlefield-stack`, not the root screen Stack.

- [ ] **Step 2: Run the tests and confirm RED**

Run:

```powershell
flutter test test/tutorial_overlay_test.dart test/tutorial_game_screen_test.dart
```

Expected: a placement/recap step is top-aligned or the battlefield Stack key/ancestor is absent.

- [ ] **Step 3: Implement bottom guidance and battlefield ownership**

Change `_cardAlignment` to return `Alignment.bottomCenter` for every non-complete step:

```dart
Alignment _cardAlignment(TutorialStep step) => Alignment.bottomCenter;
```

Give the inner battlefield Stack `const ValueKey('battlefield-stack')`. Move the `TutorialOverlay` branch from the outer screen Stack into this battlefield Stack so its `Positioned.fill` covers only the area between `_TopHud` and `_BuildBar`.

- [ ] **Step 4: Run the tests and confirm GREEN**

Run the Task 1 command. Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/tutorial/tutorial_overlay.dart lib/app/screens/game_screen.dart test/tutorial_overlay_test.dart test/tutorial_game_screen_test.dart
git commit -m "fix: anchor tutorial guidance below the battlefield"
```

### Task 2: Stable preparation and combat build panel

**Files:**
- Modify: `test/combat_ux_widget_test.dart`
- Modify: `lib/app/screens/game_screen.dart:2550-2860`

- [ ] **Step 1: Write the failing panel-height test**

Record `preparation-build-panel` height, start Wave 1, and assert the same panel still exists at the same height while cards are disabled:

```dart
final before = tester.getSize(
  find.byKey(const ValueKey('preparation-build-panel')),
).height;
await tester.tap(find.text('WAVE 1 시작').hitTestable());
await tester.pump(const Duration(milliseconds: 50));
final after = tester.getSize(
  find.byKey(const ValueKey('preparation-build-panel')),
).height;
expect(after, before);
expect(
  tester.widget<InkWell>(
    find.descendant(
      of: find.byKey(const ValueKey('tower-card-archer')),
      matching: find.byType(InkWell),
    ),
  ).onTap,
  isNull,
);
```

- [ ] **Step 2: Run the test and confirm RED**

Run:

```powershell
flutter test test/combat_ux_widget_test.dart --plain-name "combat keeps the full build panel height"
```

Expected: `preparation-build-panel` disappears because `_BuildBar.build` returns `combat-status-bar`.

- [ ] **Step 3: Keep one panel structure in both states**

Remove the early `if (widget.waveInProgress) return SizedBox(...)` branch. Keep the tab selector, card row, and action button for all non-tutorial states. Continue using:

```dart
final canBuild = !widget.waveInProgress;
```

Pass `canBuild` into every tower/barrier card and pass `null` to the hero card during combat. `_buildActionButton()` already switches the same 40px button slot to pause/resume.

- [ ] **Step 4: Run the test and confirm GREEN**

Run the Task 2 command, then all of `test/combat_ux_widget_test.dart`. Expected: all tests pass after replacing the former compact-bar assertion.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/screens/game_screen.dart test/combat_ux_widget_test.dart
git commit -m "fix: preserve the build panel during combat"
```

### Task 3: Centered Stage 1 default camera at 1.1x

**Files:**
- Modify: `test/battlefield_camera_transform_test.dart`
- Modify: `test/tile_grid_stage_data_test.dart`
- Modify: `lib/game/input/battlefield_camera_transform.dart`
- Modify: `lib/game/core/depense_game.dart`

- [ ] **Step 1: Write failing baseline tests**

Add a camera test using the wished-for API:

```dart
final camera = BattlefieldCameraTransform(defaultZoom: 1.1);
camera.reset(viewport: const Size(400, 600));
expect(camera.zoom, 1.1);
expect(camera.pan, const Offset(-20, -30));
expect(camera.isTransformed, isFalse);
camera.applyScale(scale: 1.5, focalPoint: const Offset(200, 300));
expect(camera.isTransformed, isTrue);
```

Update the Stage 1 resize test to expect the citadel to remain centered relative to the grid when the build-panel height is stable, rather than relying on the temporary Stage 1 `y=0` origin.

- [ ] **Step 2: Run and confirm RED**

Run:

```powershell
flutter test test/battlefield_camera_transform_test.dart test/tile_grid_stage_data_test.dart --plain-name "Stage 1 default"
```

Expected: the constructor/reset API does not exist and Stage 1 still forces a top origin.

- [ ] **Step 3: Implement the default baseline**

Add `defaultZoom`, store the default centered pan, and compare `isTransformed` with the default snapshot. For a viewport `(w, h)`:

```dart
_zoom = defaultZoom;
_pan = Offset(
  (viewport.width - viewport.width * _zoom) / 2,
  (viewport.height - viewport.height * _zoom) / 2,
);
_defaultSnapshot = BattlefieldCameraSnapshot(zoom: _zoom, pan: _pan);
```

Construct Stage 1 games with `defaultZoom: 1.1`, initialize once after the first valid resize, and make `resetCamera()` return to that baseline. Restore `_resolvedGridOrigin()` to vertical centering for Stage 1 now that Task 2 prevents viewport height changes.

- [ ] **Step 4: Run and confirm GREEN**

Run the Task 3 command plus `test/combat_ux_widget_test.dart`. Expected: all pass and the reset button is hidden at the 1.1x baseline.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/input/battlefield_camera_transform.dart lib/game/core/depense_game.dart test/battlefield_camera_transform_test.dart test/tile_grid_stage_data_test.dart test/combat_ux_widget_test.dart
git commit -m "fix: center the Stage 1 default camera"
```

### Task 4: Stage 1 level-aware visual catalog

**Files:**
- Modify: `test/stage1_visual_catalog_test.dart`
- Modify: `lib/game/rendering/visual_catalog.dart`
- Modify: `lib/game/rendering/game_visual_registry.dart`
- Modify: `lib/game/core/depense_game.dart:6825-6860`

- [ ] **Step 1: Write the failing catalog tests**

For every `TowerKind`, assert three distinct paths and T4 clamping:

```dart
for (final kind in TowerKind.values) {
  final t1 = StageOneVisualCatalog.tower(kind, level: 1).assetPath;
  final t2 = StageOneVisualCatalog.tower(kind, level: 2).assetPath;
  final t3 = StageOneVisualCatalog.tower(kind, level: 3).assetPath;
  expect({t1, t2, t3}, hasLength(3));
  expect(StageOneVisualCatalog.tower(kind, level: 4).assetPath, t3);
}
```

- [ ] **Step 2: Run and confirm RED**

Run:

```powershell
flutter test test/stage1_visual_catalog_test.dart
```

Expected: `tower` has no `level` parameter and only returns the T1 path.

- [ ] **Step 3: Implement level-specific paths**

Change the signature to:

```dart
static StructureVisualDefinition tower(TowerKind kind, {int level = 1}) {
  final tier = level.clamp(1, 3);
  final suffix = tier == 1 ? '' : '_t$tier';
  // Return assets/sprites/stage1/towers/$fileName$suffix.png.
}
```

Yield all three paths per kind from `assetPaths`, warm them in `GameVisualRegistry`, and always use `StageOneVisualCatalog.tower(kind, level: tower.level)` for Stage 1, regardless of branch. Keep Stage 2~30 on `towerSprite`.

- [ ] **Step 4: Run and confirm GREEN**

Run `flutter test test/stage1_visual_catalog_test.dart`. Expected: all tests pass once files from Task 5 exist in the asset bundle.

- [ ] **Step 5: Commit code and tests**

```powershell
git add lib/game/rendering/visual_catalog.dart lib/game/rendering/game_visual_registry.dart lib/game/core/depense_game.dart test/stage1_visual_catalog_test.dart
git commit -m "feat: select Stage 1 tower art by level"
```

### Task 5: Generate fourteen matching Stage 1 tower upgrades

**Files:**
- Create: `assets/sprites/stage1/towers/{archer,guard_barracks,mage_obelisk,frost_shrine,coin_mill,ballista,ember_keep}_t2.png`
- Create: `assets/sprites/stage1/towers/{archer,guard_barracks,mage_obelisk,frost_shrine,coin_mill,ballista,ember_keep}_t3.png`
- Create: `docs/generated/stage1-tower-tier-assets.md`

- [ ] **Step 1: Inspect T1 and legacy tier references**

For each tower pair, inspect:

```text
Stage 1 style: assets/sprites/stage1/towers/<tower>.png
Growth reference: assets/sprites/towers/<legacy-name>_t2.png or _t3.png
```

Map `archer` to `archer_tower`; all other names match except `ember_keep` maps to `emberkeep`.

- [ ] **Step 2: Generate each T2/T3 edit**

Use the image generation edit tool with both files as references and this level-specific prompt:

```text
Create a single transparent-background top-down 3/4 pixel-art tower sprite for Pixel Guard: Wave. Preserve the exact camera angle, lighting direction, palette family, pixel density, ground-contact center, blue player insignia, and recognizable identity of reference image 1 (the Stage 1 T1 tower). Use reference image 2 only to understand the structural progression expected at tier {2|3}; do not copy its older rendering style. Tier 2 should add one clear layer of fortification, equipment, and material detail while retaining the T1 silhouette. Tier 3 should be the strongest readable evolution with a larger crown/weapon/roof treatment and richer materials, while remaining a one-cell building and not touching the image borders. No characters, terrain, text, UI, glow backdrop, border, or cast background. Crisp hard pixel edges, no anti-aliased painterly blur. Output one centered PNG with alpha transparency.
```

- [ ] **Step 3: Validate generated files**

Confirm every file is PNG with alpha, opens successfully, contains visible non-transparent pixels, and has transparent corners. Visually inspect T1/T2/T3 together for consistent pivot and increasing strength.

- [ ] **Step 4: Record provenance and reference audit**

Write `docs/generated/stage1-tower-tier-assets.md` with generation date, common prompt, the two references for each output, output paths, and a note that legacy generic/branch assets remain referenced by Stage 2~30. Run:

```powershell
rg -n "TowerVisualCatalog|tierAssetPath|branchTierAssetPath|assets/sprites/towers" lib test
```

Delete only a file for which no runtime catalog, test, or other asset reference exists. The expected result for this pass is that generic T1/T2/T3 and branch assets remain necessary.

- [ ] **Step 5: Commit assets and provenance**

```powershell
git add assets/sprites/stage1/towers docs/generated/stage1-tower-tier-assets.md
git commit -m "feat: add Stage 1 tower tier artwork"
```

### Task 6: Integrated verification and device install

**Files:**
- Verify only; modify a file only if a failing relevant test exposes a defect.

- [ ] **Step 1: Run targeted tests**

```powershell
flutter test test/tutorial_overlay_test.dart test/tutorial_game_screen_test.dart test/combat_ux_widget_test.dart test/battlefield_camera_transform_test.dart test/stage1_visual_catalog_test.dart test/tile_grid_stage_data_test.dart
```

Expected: all pass.

- [ ] **Step 2: Run static analysis**

```powershell
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 3: Build the Debug APK**

```powershell
flutter build apk --debug
```

Expected: `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 4: Install and launch on the connected phone**

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.min21.pixelguardwave -c android.intent.category.LAUNCHER 1
```

Expected: install success and one launcher event injected.

- [ ] **Step 5: Final commit if verification produced necessary fixes**

Stage only files directly changed for those fixes and commit with a narrow `fix:` message. Preserve the pre-existing Windows generated-file changes and `.superpowers/` directory.
