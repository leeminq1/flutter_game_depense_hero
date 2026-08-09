# Guided Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Stage 1 briefing popup with a fail-less 2–3 minute training map that teaches camera controls, enemy directions, walls, safe towers, tower contact damage, wall-plus-tower defense, and a mini wave, with correct new-game and main-menu completion routes.

**Architecture:** Introduce a deterministic tutorial state machine that consumes explicit game events and publishes an immutable snapshot to Flutter. Reuse `DefensePrototypeGame` through an optional tutorial director and dedicated non-campaign stage definition; `GameScreen` owns overlays and routing, while the existing `tutorialDismissed` persisted field is treated as tutorial completion to avoid an Isar schema migration.

**Tech Stack:** Flutter, Flame, Dart sealed/enums, existing `ProgressStore`, `flutter_test`

---

## File map

- Create `lib/game/tutorial/tutorial_models.dart`: steps, launch source, events, immutable snapshot.
- Create `lib/game/tutorial/tutorial_director.dart`: deterministic event/timer state machine.
- Create `lib/game/tutorial/tutorial_stage_definition.dart`: isolated 14×14 training map.
- Create `lib/app/tutorial/tutorial_overlay.dart`: spotlight card, action buttons, completion dialog.
- Modify `lib/game/core/depense_game.dart`: optional tutorial callbacks, fail-less demo hooks, 1.5× tutorial-only simulation.
- Modify `lib/app/screens/game_screen.dart`: tutorial mode, Stage 1 recap, remove automatic Stage 1 briefing.
- Modify `lib/app/screens/title_screen.dart`: main-menu tutorial entry and new-game routing.
- Modify persistence implementations only at API naming/comments; retain the stored `tutorialDismissed` property.
- Create `test/tutorial_director_test.dart`, `test/tutorial_navigation_test.dart`, `test/tutorial_stage_definition_test.dart`.

### Task 1: Tutorial state model and director

**Files:**
- Create: `lib/game/tutorial/tutorial_models.dart`
- Create: `lib/game/tutorial/tutorial_director.dart`
- Create: `test/tutorial_director_test.dart`

- [ ] **Step 1: Write failing state-machine tests**

```dart
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera step can be skipped after five seconds', () {
    final director = TutorialDirector();
    director.advanceTime(const Duration(seconds: 4));
    expect(director.snapshot.canSkip, isFalse);
    director.advanceTime(const Duration(seconds: 1));
    expect(director.snapshot.canSkip, isTrue);
    director.skipCurrentStep();
    expect(director.snapshot.step, TutorialStep.enemyDirections);
  });

  test('required placement events advance wall and tower lessons', () {
    final director = TutorialDirector(initialStep: TutorialStep.blockWithWall);
    director.record(const TutorialEvent.barrierPlaced(onRoad: true));
    expect(director.snapshot.step, TutorialStep.safeTower);
    director.record(const TutorialEvent.towerPlaced(onRoad: false, behindWall: false));
    expect(director.snapshot.step, TutorialStep.dangerousTowerDemo);
  });

  test('danger demo is fixed to tutorial-only 1.5 speed and explicit copy', () {
    final director = TutorialDirector(initialStep: TutorialStep.dangerousTowerDemo);
    expect(director.snapshot.simulationSpeed, 1.5);
    expect(
      director.snapshot.body,
      '타워만으로는 몬스터를 막지 못합니다. 몬스터가 통과하면서 종류별 접촉 피해를 줍니다.',
    );
  });

  test('pause freezes tutorial timers', () {
    final director = TutorialDirector(initialStep: TutorialStep.dangerousTowerDemo);
    director.setPaused(true);
    director.advanceTime(const Duration(seconds: 30));
    expect(director.snapshot.step, TutorialStep.dangerousTowerDemo);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/tutorial_director_test.dart`

Expected: compilation fails because tutorial models do not exist.

- [ ] **Step 3: Define exact tutorial types**

```dart
enum TutorialLaunchSource { newGame, mainMenu }

enum TutorialStep {
  cameraControls,
  enemyDirections,
  blockWithWall,
  safeTower,
  dangerousTowerDemo,
  combinedDefense,
  miniWave,
  recap,
  complete,
}

enum TutorialEventType { cameraChanged, barrierPlaced, towerPlaced, waveStarted, waveCleared }

class TutorialEvent {
  const TutorialEvent._(this.type, {this.onRoad = false, this.behindWall = false});
  const TutorialEvent.cameraChanged() : this._(TutorialEventType.cameraChanged);
  const TutorialEvent.barrierPlaced({required bool onRoad})
      : this._(TutorialEventType.barrierPlaced, onRoad: onRoad);
  const TutorialEvent.towerPlaced({required bool onRoad, required bool behindWall})
      : this._(TutorialEventType.towerPlaced, onRoad: onRoad, behindWall: behindWall);
  const TutorialEvent.waveStarted() : this._(TutorialEventType.waveStarted);
  const TutorialEvent.waveCleared() : this._(TutorialEventType.waveCleared);

  final TutorialEventType type;
  final bool onRoad;
  final bool behindWall;
}

class TutorialSnapshot {
  const TutorialSnapshot({
    required this.step,
    required this.title,
    required this.body,
    required this.canSkip,
    required this.simulationSpeed,
    required this.allowedActions,
  });
  final TutorialStep step;
  final String title;
  final String body;
  final bool canSkip;
  final double simulationSpeed;
  final Set<TutorialEventType> allowedActions;
}
```

- [ ] **Step 4: Implement `TutorialDirector` as `ChangeNotifier`**

Implement a single switch-based state machine. Camera controls advance after `cameraChanged` or manual skip; directions advance from an overlay continue action; required wall/tower events validate road/behind-wall flags; the danger demo advances after its scripted pass/damage sequence reports completion; mini wave advances only after `waveCleared`; recap advances to complete. `advanceTime` does nothing while paused and only exposes camera skip after five seconds. The danger step always publishes `simulationSpeed: 1.5`; every other step publishes `1.0`.

- [ ] **Step 5: Run, format, and commit**

Run: `dart format lib/game/tutorial test/tutorial_director_test.dart && flutter test test/tutorial_director_test.dart`

Expected: all director tests pass.

Commit: `git add lib/game/tutorial/tutorial_models.dart lib/game/tutorial/tutorial_director.dart test/tutorial_director_test.dart && git commit -m "feat: add deterministic tutorial director"`

### Task 2: Dedicated training map

**Files:**
- Create: `lib/game/tutorial/tutorial_stage_definition.dart`
- Create: `test/tutorial_stage_definition_test.dart`

- [ ] **Step 1: Write failing map invariants**

```dart
void main() {
  test('training stage is isolated from campaign rewards and has four labeled fronts', () {
    final stage = TutorialStageDefinition.build();
    expect(stage.number, 0);
    expect(stage.tileGrid, hasLength(14));
    expect(stage.tileGrid!.every((row) => row.length == 14), isTrue);
    expect(stage.spawnRoutes.map((route) => route.direction).toSet(), {
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    });
    expect(stage.startingCoins, greaterThanOrEqualTo(200));
  });
}
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/tutorial_stage_definition_test.dart`

Expected: compilation fails because `TutorialStageDefinition` is absent.

- [ ] **Step 3: Build the 14×14 authored stage**

Create a stage with a central citadel, one short north/west teaching route highlighted first, green off-road tower cells, a road cell reserved for the dangerous tower demonstration, and a wall-plus-behind-tower lane. Use existing `EnemyDefinition`, `WaveDefinition`, and `StageDefinition` constructors with one short mini wave; set number to `0`, title to `훈련장`, no campaign reward metadata, and enough starting coins to make every required placement fail-less. Do not alter any catalog cost or enemy stat.

- [ ] **Step 4: Run tests and commit**

Run: `dart format lib/game/tutorial/tutorial_stage_definition.dart test/tutorial_stage_definition_test.dart && flutter test test/tutorial_stage_definition_test.dart test/tile_grid_stage_data_test.dart`

Expected: tutorial invariants and campaign tile-grid tests pass.

Commit: `git add lib/game/tutorial/tutorial_stage_definition.dart test/tutorial_stage_definition_test.dart && git commit -m "feat: add dedicated tutorial training map"`

### Task 3: Game event integration and fail-less demonstration

**Files:**
- Modify: `lib/game/core/depense_game.dart`
- Modify: `lib/game/core/game_session_controller.dart`
- Modify: `test/tutorial_director_test.dart`

- [ ] **Step 1: Add tests for speed isolation**

```dart
test('finishing danger demo restores normal speed', () {
  final director = TutorialDirector(initialStep: TutorialStep.dangerousTowerDemo);
  director.recordDangerDemoCompleted();
  expect(director.snapshot.step, TutorialStep.combinedDefense);
  expect(director.snapshot.simulationSpeed, 1.0);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/tutorial_director_test.dart`

Expected: FAIL because `recordDangerDemoCompleted` does not exist.

- [ ] **Step 3: Wire optional tutorial hooks**

Add `TutorialDirector? tutorialDirector` to `DefensePrototypeGame`. Report camera changes, successful barrier placements, successful tower placements, wave start, and wave clear. Calculate `onRoad` from the stage path cells and `behindWall` from adjacent placed barriers. During `dangerousTowerDemo`, spawn a separate scripted preview monster and tower state that cannot consume coins, damage the campaign citadel, or mark a wave complete. Advance it at `dt * 1.5`, draw the tower HP and contact-damage number, then notify `recordDangerDemoCompleted()` and remove preview entities.

In `update(double dt)`, call `tutorialDirector?.advanceTime(Duration(microseconds: (dt * 1000000).round()))`; if the game is paused, Flame update is already stopped, and `togglePaused` also calls `director.setPaused(...)` so Flutter-driven timers remain synchronized.

- [ ] **Step 4: Verify focused tests and analysis**

Run: `dart format lib/game/core/depense_game.dart lib/game/core/game_session_controller.dart lib/game/tutorial && flutter test test/tutorial_director_test.dart test/game_session_controller_test.dart && flutter analyze`

Expected: tests pass and analysis is clean.

- [ ] **Step 5: Commit**

Commit: `git add lib/game/core/depense_game.dart lib/game/core/game_session_controller.dart lib/game/tutorial test/tutorial_director_test.dart && git commit -m "feat: connect tutorial lessons to battle events"`

### Task 4: Tutorial overlay and action gating

**Files:**
- Create: `lib/app/tutorial/tutorial_overlay.dart`
- Modify: `lib/app/screens/game_screen.dart`
- Create: `test/tutorial_navigation_test.dart`

- [ ] **Step 1: Write failing overlay behavior tests**

```dart
testWidgets('tutorial spotlight only allows the current lesson action', (tester) async {
  final director = TutorialDirector(initialStep: TutorialStep.blockWithWall);
  await tester.pumpWidget(MaterialApp(home: TutorialOverlay(director: director)));
  expect(find.text('성벽으로 길 막기'), findsOneWidget);
  expect(find.text('길 위의 강조 칸에 성벽을 배치하세요.'), findsOneWidget);
  expect(find.text('건너뛰기'), findsNothing);
});

testWidgets('camera lesson exposes skip after five seconds', (tester) async {
  final director = TutorialDirector();
  await tester.pumpWidget(MaterialApp(home: TutorialOverlay(director: director)));
  director.advanceTime(const Duration(seconds: 5));
  await tester.pump();
  expect(find.text('건너뛰기'), findsOneWidget);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/tutorial_navigation_test.dart`

Expected: compilation fails because `TutorialOverlay` does not exist.

- [ ] **Step 3: Implement the transparent overlay**

Build `TutorialOverlay` with `AnimatedBuilder`, `IgnorePointer` outside the current callout/action area, a translucent scrim, spotlight painter, progress text (`3 / 8`), title/body, and only actions allowed by the snapshot. The direction step must display `북·남·동·서` and `표시된 방향에서 적이 등장합니다.` The danger step must display the exact approved two-sentence text while the 1.5× preview runs. Avoid a blocking full-screen dialog during the lessons.

- [ ] **Step 4: Integrate tutorial mode into `GameScreen`**

Add constructor fields:

```dart
final TutorialLaunchSource? tutorialLaunchSource;
final VoidCallback? onTutorialFinishedFromMenu;
final VoidCallback? onTutorialExitToHome;
```

When `tutorialLaunchSource != null`, load `TutorialStageDefinition.build()` and a fresh `TutorialDirector`, hide campaign result/reward flows, pass action gates into the build panel, and layer `TutorialOverlay` above the `GameWidget` but below pause. Remove `_stageOneBriefingShown` and the automatic `stageNumber == 1` call to `_showStageBriefing`; keep the stage-info button for user-requested reference information.

- [ ] **Step 5: Run and commit**

Run: `dart format lib/app/tutorial/tutorial_overlay.dart lib/app/screens/game_screen.dart test/tutorial_navigation_test.dart && flutter test test/tutorial_navigation_test.dart && flutter analyze`

Expected: overlay tests pass; analysis clean.

Commit: `git add lib/app/tutorial/tutorial_overlay.dart lib/app/screens/game_screen.dart test/tutorial_navigation_test.dart && git commit -m "feat: add in-battle guided tutorial overlay"`

### Task 5: Menu, new-game, completion, and Stage 1 recap routes

**Files:**
- Modify: `lib/app/screens/title_screen.dart`
- Modify: `lib/app/screens/game_screen.dart`
- Modify: `lib/data/persistence/progress_store.dart`
- Modify: `lib/data/persistence/in_memory_progress_store.dart`
- Modify: `lib/data/persistence/local_progress_store.dart`
- Modify: `test/title_screen_test.dart`
- Modify: `test/tutorial_navigation_test.dart`

- [ ] **Step 1: Write failing navigation tests**

```dart
testWidgets('main menu has a first-class tutorial button', (tester) async {
  await pumpMenu(tester);
  expect(find.byKey(const ValueKey('main-menu-tutorial')), findsOneWidget);
});

testWidgets('new game enters tutorial before stage one', (tester) async {
  await pumpMenu(tester);
  await tester.tap(find.byKey(const ValueKey('main-menu-new-game')));
  await tester.pumpAndSettle();
  expect(find.text('훈련장'), findsOneWidget);
});

testWidgets('menu tutorial completion offers replay or home', (tester) async {
  await pumpCompletedTutorial(tester, source: TutorialLaunchSource.mainMenu);
  expect(find.text('다시 보기'), findsOneWidget);
  expect(find.text('홈 화면'), findsOneWidget);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/title_screen_test.dart test/tutorial_navigation_test.dart`

Expected: FAIL because the tutorial menu entry and routes are absent.

- [ ] **Step 3: Add explicit title flow**

Extend `AppFlowState` with `tutorial`, add `_tutorialSource`, and pass `onTutorial` into `_MainMenu`. Insert a menu button keyed `main-menu-tutorial`, labeled `튜토리얼`, subtitle `성벽·타워·출현 방향을 직접 연습`, between continue/new-game and settings. New game resets campaign progress, checks `isTutorialDismissed()`, and enters training; if previously completed, show an inline `건너뛰고 Stage 1` action. Main-menu tutorial never resets progress.

- [ ] **Step 4: Implement exact completion routes**

On tutorial completion call `setTutorialDismissed(true)`.

- New-game source: directly load Stage 1 with no completion popup, then show a short non-blocking spotlight recap for direction, wall, tower, and combination rules.
- Main-menu source: show an `AlertDialog` with only `다시 보기` and `홈 화면`; replay creates a new director, home returns to `AppFlowState.menu`.
- Continue source: never starts tutorial or Stage 1 recap.

Retain the stored field name `tutorialDismissed` in Isar; expose compatibility methods in `ProgressStore` so no schema/version generation is needed.

- [ ] **Step 5: Verify persistence and routes**

Run: `dart format lib/app/screens/title_screen.dart lib/app/screens/game_screen.dart lib/data/persistence test/title_screen_test.dart test/tutorial_navigation_test.dart && flutter test test/title_screen_test.dart test/tutorial_navigation_test.dart test/progress_store_test.dart && flutter analyze`

Expected: all route/persistence tests pass; analysis clean.

- [ ] **Step 6: Commit**

Commit: `git add lib/app/screens/title_screen.dart lib/app/screens/game_screen.dart lib/data/persistence test/title_screen_test.dart test/tutorial_navigation_test.dart && git commit -m "feat: route new games through guided training"`

### Task 6: Tutorial regression gate

**Files:**
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`

- [ ] **Step 1: Run all automated checks**

Run: `flutter analyze && flutter test`

Expected: zero analyzer issues and all tests pass; campaign balance smoke tests remain unchanged.

- [ ] **Step 2: Record remaining device checks**

Document that real-device acceptance still covers 2–3 minute completion time, readable transparent callouts, camera skip at five seconds, 1.5× danger demo pacing, pause freezing demo time, automatic Stage 1 transition, and menu completion dialog.

- [ ] **Step 3: Commit**

Commit: `git add docs/exec-plans/active/initial-defense-game-foundation.md && git commit -m "docs: record tutorial verification"`
