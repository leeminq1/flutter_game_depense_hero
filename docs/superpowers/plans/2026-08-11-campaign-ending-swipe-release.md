# Campaign Ending Swipe Production Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace timed ending advancement with deliberate bidirectional swipes and produce the locked-progression `1.0.33+34` production AAB.

**Architecture:** Keep scene ownership inside `CampaignEndingOverlay`; accumulate only horizontal-dominant drag distance and advance or rewind at gesture end. Keep `GameScreen` result/persistence behavior unchanged. Production progression remains controlled by the existing single development flag, which is disabled and covered by a fresh-profile store test.

**Tech Stack:** Flutter widgets and gesture callbacks, Flutter widget tests, Dart progress-store tests, Gradle Android App Bundle, Git.

---

### Task 1: Bidirectional Ending Swipes

**Files:**
- Modify: `test/campaign_ending_overlay_test.dart`
- Modify: `lib/app/widgets/campaign_ending_overlay.dart`

- [ ] **Step 1: Write failing interaction tests**

Replace tap and timer advancement with assertions that waiting 15 seconds and
tapping do not leave scene 0, a left swipe reaches scene 1, a right swipe
returns to scene 0, and repeated boundary swipes remain bounded.

```dart
await tester.pump(const Duration(seconds: 15));
await tester.tap(find.byKey(const Key('campaign-ending-overlay')));
expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);

await tester.drag(
  find.byKey(const Key('campaign-ending-overlay')),
  const Offset(-90, 0),
);
expect(find.byKey(const Key('campaign-ending-scene-1')), findsOneWidget);

await tester.drag(
  find.byKey(const Key('campaign-ending-overlay')),
  const Offset(90, 0),
);
expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);
```

- [ ] **Step 2: Run the overlay test and verify RED**

Run: `flutter test test/campaign_ending_overlay_test.dart`

Expected: FAIL because timers/taps still advance and horizontal drags do not
implement previous-scene navigation.

- [ ] **Step 3: Implement minimal swipe navigation**

Remove `dart:async`, `_sceneDurations`, `_timer`, timer lifecycle methods, and
`onTap`. Track horizontal and vertical drag totals, then apply one scene change
at drag end only when horizontal movement dominates and either distance is at
least 44 pixels or horizontal release velocity is at least 350 pixels/second.

```dart
double _dragDx = 0;
double _dragDy = 0;

void _handleDragUpdate(DragUpdateDetails details) {
  _dragDx += details.delta.dx;
  _dragDy += details.delta.dy;
}

void _handleDragEnd(DragEndDetails details) {
  final velocity = details.primaryVelocity ?? 0;
  final horizontal = _dragDx.abs() > _dragDy.abs();
  final deliberate = _dragDx.abs() >= 44 || velocity.abs() >= 350;
  if (horizontal && deliberate) {
    _setScene(_dragDx < 0 || velocity < -350 ? _scene + 1 : _scene - 1);
  }
  _dragDx = 0;
  _dragDy = 0;
}
```

- [ ] **Step 4: Run overlay and GameScreen ending tests**

Run:

```powershell
flutter test test/campaign_ending_overlay_test.dart test/campaign_ending_game_screen_test.dart
```

Expected: all ending tests pass, including skip, result, and replay behavior.

- [ ] **Step 5: Commit swipe interaction**

```powershell
git add -- lib/app/widgets/campaign_ending_overlay.dart test/campaign_ending_overlay_test.dart
git commit -m "fix: require swipes for campaign ending scenes"
```

### Task 2: Production Version And Progression Lock

**Files:**
- Modify: `test/progress_store_test.dart`
- Modify: `lib/data/persistence/progression_dev_flags.dart`
- Modify: `pubspec.yaml`
- Modify: `docs/product-specs/campaign-structure.md`
- Modify: `docs/product-specs/core-game-loop.md`
- Modify: `docs/product-specs/runtime-data-contracts.md`
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`

- [ ] **Step 1: Write the failing production progression test**

Change the development-unlock test to require a fresh profile to expose only
Stage 1.

```dart
test('production profile starts with Stage 1 only', () async {
  final store = await InMemoryProgressStore.open();
  final overview = await store.loadCampaignOverview(totalStages: 30);
  expect(overview.stages.where((stage) => stage.unlocked), hasLength(1));
  expect(overview.stages.first.unlocked, isTrue);
  expect(overview.stages.skip(1).every((stage) => !stage.unlocked), isTrue);
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/progress_store_test.dart --plain-name "production profile starts with Stage 1 only"`

Expected: FAIL because all 30 stages are currently unlocked.

- [ ] **Step 3: Disable the review flag and bump the version**

Set:

```dart
const bool kUnlockAllCampaignStagesForDevelopment = false;
```

Set `pubspec.yaml` to:

```yaml
version: 1.0.33+34
```

- [ ] **Step 4: Update production-facing documentation**

Replace the three product-spec statements claiming the current build exposes
all stages with the production rule that only authored progression unlocks
stages. Add a dated exec-plan note recording swipe-only ending navigation,
version `1.0.33+34`, and the disabled review flag.

- [ ] **Step 5: Run the progression test and verify GREEN**

Run: `flutter test test/progress_store_test.dart`

Expected: all progress-store tests pass.

- [ ] **Step 6: Commit production configuration**

```powershell
git add -- test/progress_store_test.dart lib/data/persistence/progression_dev_flags.dart pubspec.yaml docs/product-specs/campaign-structure.md docs/product-specs/core-game-loop.md docs/product-specs/runtime-data-contracts.md docs/exec-plans/active/initial-defense-game-foundation.md
git commit -m "release: prepare version 1.0.33"
```

### Task 3: Verification, AAB, And GitHub Push

**Files:**
- Verify: `build/app/outputs/bundle/release/app-release.aab`

- [ ] **Step 1: Format and check the diff**

Run:

```powershell
dart format lib/app/widgets/campaign_ending_overlay.dart test/campaign_ending_overlay_test.dart test/progress_store_test.dart
git diff --check
```

Expected: no formatting changes remain and diff check exits zero.

- [ ] **Step 2: Run all automated gates**

Run:

```powershell
flutter analyze
flutter test
```

Expected: analysis reports no issues and all tests pass.

- [ ] **Step 3: Build the signed release AAB**

Run: `flutter build appbundle --release`

Expected: `build/app/outputs/bundle/release/app-release.aab` exists and the
command exits zero using the configured release signing setup.

- [ ] **Step 4: Inspect production artifact metadata**

Use Android build outputs and bundle metadata to confirm version name
`1.0.33`, version code `34`, and that the source review flag is false.

- [ ] **Step 5: Verify Git state and push main**

Run:

```powershell
git status --short
git push origin main
git rev-list --left-right --count origin/main...HEAD
```

Expected: only pre-existing unrelated Windows generated files and
`.superpowers/` remain uncommitted, push succeeds, and divergence is `0 0`.

## Plan self-review

- Every approved swipe direction, boundary, retained control, version, flag,
  test gate, artifact check, and push requirement maps to an explicit step.
- No placeholder or deferred implementation step remains.
- Widget names, keys, files, and version values match the current code and
  approved design.
