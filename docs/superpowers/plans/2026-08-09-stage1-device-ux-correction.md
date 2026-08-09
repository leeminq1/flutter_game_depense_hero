# Stage 1 Device UX Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct the Stage 1 device UX regression so the battlefield stays inside its viewport, opens at a useful scale, preserves key HUD information, and clearly separates road-only wall placement from flexible tower placement.

**Architecture:** Flutter owns the clipped viewport, HUD layout, and timed recap overlay. Flame owns camera bounds, build-cell eligibility, map rendering contrast, and structure render metadata. Stage 1 remains a constrained slice; campaign balance and Stage 2–30 behavior remain unchanged.

**Tech Stack:** Flutter widgets/tests, Flame canvas/input, Dart unit tests, Android debug APK.

**Status:** Implemented and verified on 2026-08-09. The debug APK was installed with data preservation on the connected SM-F741N for device acceptance.

---

### Task 1: Lock viewport and camera behavior

**Files:**
- Modify: `test/combat_ux_widget_test.dart`
- Modify: `test/battlefield_camera_transform_test.dart`
- Modify: `lib/app/screens/game_screen.dart`
- Modify: `lib/game/input/battlefield_camera_transform.dart`

- [ ] Add a widget test requiring a keyed `ClipRect` ancestor around the `GameWidget`.
- [ ] Change the camera test to require a 1.0–2.5 range and verify a sub-1.0 pinch clamps to 1.0 with zero pan.
- [ ] Run both tests and confirm they fail for the missing clip and old 0.7 minimum.
- [ ] Wrap the battlefield stack in `ClipRect(key: ValueKey('battlefield-viewport-clip'))` and set `minZoom` to 1.0.
- [ ] Re-run both tests and confirm they pass.

### Task 2: Keep critical HUD state visible and auto-dismiss recap

**Files:**
- Modify: `test/combat_ux_widget_test.dart`
- Modify: `test/tutorial_game_screen_test.dart`
- Modify: `lib/app/screens/game_screen.dart`

- [ ] Add phone-sized tests requiring `hud-coins` and `hud-stage` to remain within screen bounds, plus a recap test that disappears after three seconds without a close button.
- [ ] Run the tests and confirm the fixed keys/timer behavior are absent.
- [ ] Keep coin and Stage chips fixed at the sides of the mobile second row; place Wave, remaining enemies, and direction in a non-reversed middle scroller.
- [ ] Add and dispose a dedicated three-second recap timer; remove the close action from the recap card.
- [ ] Re-run the widget tests and confirm they pass.

### Task 3: Clarify Stage 1 build surfaces

**Files:**
- Modify: `test/tile_grid_stage_data_test.dart`
- Modify: `lib/game/core/depense_game.dart`

- [ ] Add tests proving Stage 1 barrier candidates are a non-empty subset of the visible Wave road cells while tower candidates still include grass cells.
- [ ] Run the focused test and confirm the unrestricted barrier grid fails it.
- [ ] Derive Stage 1 barrier slots from the same visible route cells used by the road renderer; keep the general tower grid unchanged.
- [ ] Use the barrier-only grid for barrier placement and highlighted slots, and show a road-specific invalid-placement message.
- [ ] Re-run the focused test and confirm it passes.

### Task 4: Reduce visual noise and structure overlap

**Files:**
- Modify: `test/stage1_visual_catalog_test.dart`
- Modify: `lib/game/rendering/visual_catalog.dart`
- Modify: `lib/game/core/depense_game.dart`

- [ ] Add catalog assertions for low grass texture opacity and a smaller/lower-offset Stage 1 citadel.
- [ ] Run the test and confirm the current 0.22 opacity and 3.25-tile citadel fail.
- [ ] Lower the grass texture opacity, shrink the citadel render metadata without changing its logical footprint, and soften non-barrier build-slot outlines.
- [ ] Re-run the visual tests and confirm they pass.

### Task 5: Verify and install

**Files:**
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`

- [ ] Run `dart format` on changed Dart files.
- [ ] Run focused tests, then `flutter test`, `flutter analyze`, and `git diff --check`.
- [ ] Build with `flutter build apk --debug`.
- [ ] Install the debug APK on the connected device and launch `com.min21.pixelguardwave`.
- [ ] Record the verification and remaining device checks in the active execution plan.

## Verification Record

- `flutter test`: 128 tests passed.
- `flutter analyze`: no issues found.
- `flutter build apk --debug`: succeeded.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: succeeded on `SM-F741N` (`R3CX70DGKGA`).
- Remaining manual check: maximum zoom must stay below the full top HUD, coin/Stage must remain visible during placement, and Stage 1 walls must accept road cells only.
