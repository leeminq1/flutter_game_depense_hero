# Stage 30 Campaign Ending Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a hopeful four-scene ending after a successful Stage 30 clear, then reveal the existing result screen with ending replay, retry, and home actions.

**Architecture:** Flutter owns a new `CampaignEndingOverlay`; Flame remains frozen in its existing cleared state. A pure flow helper determines eligibility, while `GameScreen` continues terminal persistence immediately and gates only result presentation until the ending completes or is skipped.

**Tech Stack:** Flutter widgets and animation, existing Flame session controller, Flutter asset bundle, image generation for one background, `flutter_test`.

---

## File Structure

- Create `lib/app/ending/campaign_ending_flow.dart`: pure Stage 30 ending eligibility rule.
- Create `lib/app/widgets/campaign_ending_overlay.dart`: four-scene visual presentation and local timing state.
- Modify `lib/app/screens/game_screen.dart`: terminal overlay ordering, replay state, and final result action wiring.
- Create `assets/images/campaign_ending_dawn.png`: character-free dawn battlefield background.
- Create `docs/generated/campaign-ending-asset-spec.md`: image prompt, source, export, and license record.
- Modify `pubspec.yaml`: bundle `assets/images/`.
- Create `test/campaign_ending_flow_test.dart`: pure flow coverage.
- Create `test/campaign_ending_overlay_test.dart`: pacing, controls, sprite composition, and narrow-layout coverage.
- Create `test/campaign_ending_game_screen_test.dart`: Stage 30 terminal integration and replay behavior.
- Modify `test/campaign_visual_catalog_test.dart`: final background bundle check.
- Modify `docs/exec-plans/active/initial-defense-game-foundation.md`: implementation and verification note.

### Task 1: Pure Campaign Ending Flow

**Files:**
- Create: `lib/app/ending/campaign_ending_flow.dart`
- Create: `test/campaign_ending_flow_test.dart`

- [ ] **Step 1: Write the failing flow tests**

```dart
import 'package:depense_game/app/ending/campaign_ending_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only a successful unfinished Stage 30 run requests the ending', () {
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: false,
      ),
      isTrue,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 29,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: false,
      ),
      isFalse,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: false,
        stageFailed: true,
        endingCompleted: false,
      ),
      isFalse,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: true,
      ),
      isFalse,
    );
  });
}
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test test/campaign_ending_flow_test.dart`

Expected: compilation failure because `campaign_ending_flow.dart` and
`shouldPlayCampaignEnding` do not exist.

- [ ] **Step 3: Implement the minimal pure rule**

```dart
const int finalCampaignStageNumber = 30;

bool shouldPlayCampaignEnding({
  required int stageNumber,
  required bool stageCleared,
  required bool stageFailed,
  required bool endingCompleted,
}) {
  return stageNumber == finalCampaignStageNumber &&
      stageCleared &&
      !stageFailed &&
      !endingCompleted;
}
```

- [ ] **Step 4: Run the test and verify GREEN**

Run: `flutter test test/campaign_ending_flow_test.dart`

Expected: all flow assertions pass.

- [ ] **Step 5: Commit the flow rule**

```powershell
git add -- lib/app/ending/campaign_ending_flow.dart test/campaign_ending_flow_test.dart
git commit -m "feat: define final campaign ending flow"
```

### Task 2: Ending Background Asset

**Files:**
- Create: `docs/generated/campaign-ending-asset-spec.md`
- Create: `docs/generated/campaign-ending-dawn-source.png`
- Create: `assets/images/campaign_ending_dawn.png`
- Modify: `pubspec.yaml`
- Modify: `test/campaign_visual_catalog_test.dart`

- [ ] **Step 1: Add a failing bundle test**

Add this test to `test/campaign_visual_catalog_test.dart`:

```dart
test('campaign ending dawn background is bundled', () async {
  final data = await rootBundle.load(
    'assets/images/campaign_ending_dawn.png',
  );
  expect(data.lengthInBytes, greaterThan(10000));
});
```

- [ ] **Step 2: Run the bundle test and verify RED**

Run: `flutter test test/campaign_visual_catalog_test.dart --plain-name "campaign ending dawn background is bundled"`

Expected: asset-not-found failure.

- [ ] **Step 3: Record the exact generation contract**

Create `docs/generated/campaign-ending-asset-spec.md` with this prompt and
export contract:

```text
Portrait 9:16 high-angle top-down 3/4 fantasy pixel-art battlefield at dawn,
matching the detailed Pixel Guard campaign environment. Dark battle-worn earth
and a few extinguished embers in the lower third, warm gold and pale blue dawn
light on the horizon, subtle drifting ash, hopeful atmosphere after a long
siege, clean layered depth, central empty composition space for separately
placed character and castle sprites. No characters, no creatures, no monsters,
no buildings, no castle, no weapons, no UI, no lettering, no logo, no border.
```

Record the built-in image generation tool as the source, the final asset path,
the intended ending-only use, and that no third-party artwork is included.

- [ ] **Step 4: Generate and inspect the background**

Use the built-in image generation tool with the Stage 30 visual palette as the
style reference. Save the untouched output to
`docs/generated/campaign-ending-dawn-source.png` and the accepted game copy to
`assets/images/campaign_ending_dawn.png`. Inspect the final image at original
detail and reject it if it contains people, buildings, text, or a blocked
center composition.

- [ ] **Step 5: Bundle the directory**

Add under `flutter/assets` in `pubspec.yaml`:

```yaml
    - assets/images/
```

- [ ] **Step 6: Run the bundle test and verify GREEN**

Run: `flutter test test/campaign_visual_catalog_test.dart --plain-name "campaign ending dawn background is bundled"`

Expected: the background loads and exceeds 10 KB.

- [ ] **Step 7: Commit the background pipeline**

```powershell
git add -- assets/images/campaign_ending_dawn.png docs/generated/campaign-ending-asset-spec.md docs/generated/campaign-ending-dawn-source.png pubspec.yaml test/campaign_visual_catalog_test.dart
git commit -m "feat: add final campaign dawn artwork"
```

### Task 3: Four-Scene Ending Overlay

**Files:**
- Create: `lib/app/widgets/campaign_ending_overlay.dart`
- Create: `test/campaign_ending_overlay_test.dart`

- [ ] **Step 1: Write failing widget tests**

The tests must pump a `MaterialApp` containing `CampaignEndingOverlay` on a
430x900 surface and assert:

```dart
expect(find.byKey(const ValueKey('campaign-ending-overlay')), findsOneWidget);
expect(find.byKey(const ValueKey('campaign-ending-scene-0')), findsOneWidget);
expect(find.text('마지막 공세가 멎었습니다.'), findsOneWidget);
expect(find.byKey(const ValueKey('campaign-ending-skip')), findsOneWidget);
expect(find.byKey(const ValueKey('campaign-ending-enemy-group')), findsOneWidget);
expect(find.byKey(const ValueKey('campaign-ending-citadel')), findsNothing);
```

Tap once and assert `campaign-ending-hero-knight` appears in Scene 2. Tap again
and assert `campaign-ending-citadel` appears in Scene 3. Tap a third time and
assert the final message and `campaign-ending-result` action appear. Tap skip
in a separate test and assert the completion callback fires once. Pump 4
seconds and assert automatic advancement to Scene 2. Use
`tester.takeException()` to assert no phone-layout overflow.

- [ ] **Step 2: Run the overlay tests and verify RED**

Run: `flutter test test/campaign_ending_overlay_test.dart`

Expected: compilation failure because `CampaignEndingOverlay` does not exist.

- [ ] **Step 3: Implement the focused stateful overlay**

Create a public widget with this interface:

```dart
class CampaignEndingOverlay extends StatefulWidget {
  const CampaignEndingOverlay({
    required this.onComplete,
    required this.onSkip,
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onSkip;
}
```

Implementation requirements:

- Keep a local `_sceneIndex` and one nullable `Timer`.
- Schedule scene durations `4s`, `4s`, and `5s`; Scene 4 waits for explicit
  `결과 보기`.
- Cancel and replace the timer on tap advancement; cancel it in `dispose`.
- Wrap the overlay in `SafeArea` and key it `campaign-ending-overlay`.
- Render the dawn asset with `Image.asset(..., fit: BoxFit.cover)` and an
  `errorBuilder` returning a navy-to-gold `DecoratedBox` gradient.
- Use `AnimatedSwitcher`, `AnimatedOpacity`, and `AnimatedSlide`; do not run a
  Flame game or create a per-frame controller.
- Compose the exact existing sprite paths from `CampaignVisualCatalog`,
  `HeroVisualCatalog`, and `EnemyVisualCatalog`.
- Place all five heroes on Scenes 2-4, representative enemies on Scenes 1-2,
  and the citadel on Scenes 3-4.
- Add stable keys for every scene, skip, result, hero, enemy group, and citadel.
- Use the exact approved Korean copy from the design document.
- Call `onSkip` only from `건너뛰기`; call `onComplete` only from
  `결과 보기`. Guard both through a local `_finished` latch.

- [ ] **Step 4: Run the overlay tests and verify GREEN**

Run: `flutter test test/campaign_ending_overlay_test.dart`

Expected: timing, controls, assets, and 430x900 layout pass.

- [ ] **Step 5: Commit the overlay**

```powershell
git add -- lib/app/widgets/campaign_ending_overlay.dart test/campaign_ending_overlay_test.dart
git commit -m "feat: add final campaign ending overlay"
```

### Task 4: Stage 30 Terminal Integration

**Files:**
- Modify: `lib/app/screens/game_screen.dart`
- Create: `test/campaign_ending_game_screen_test.dart`

- [ ] **Step 1: Write failing integration tests**

Build `GameScreen` with `InMemoryProgressStore`, `initialStageNumber: 30`, and a
430x900 surface. Retrieve `DefensePrototypeGame` from its `GameWidget`, call
`game.pauseEngine()` so the simulation cannot overwrite the injected state,
then drive its public session controller to terminal state with
`updateRuntime(stageCleared: true, stageFailed: false, ...)`.

Assert:

```dart
expect(find.byKey(const ValueKey('campaign-ending-overlay')), findsOneWidget);
expect(find.text('STAGE 클리어'), findsNothing);
```

Tap `campaign-ending-skip`, pump terminal preparation, and assert the result
appears with `campaign-ending-replay-result`, `다시 도전`, and
`캠프로 돌아가기`, but without `다음 STAGE`.

Add separate tests that Stage 29 clear and Stage 30 failure do not show the
ending. Track `InMemoryProgressStore` completion data before and after ending
replay and assert replay does not award or record again.

- [ ] **Step 2: Run the integration tests and verify RED**

Run: `flutter test test/campaign_ending_game_screen_test.dart`

Expected: Stage 30 goes directly to the existing result overlay and the new
keys/actions are absent.

- [ ] **Step 3: Add ending state to `_GameScreenState`**

Add:

```dart
bool _campaignEndingCompleted = false;
int _campaignEndingEpoch = 0;

void _completeCampaignEnding() {
  if (!mounted || _campaignEndingCompleted) return;
  setState(() => _campaignEndingCompleted = true);
}

void _replayCampaignEnding() {
  if (!mounted) return;
  setState(() {
    _campaignEndingCompleted = false;
    _campaignEndingEpoch += 1;
  });
}
```

Reset both fields in `_resetTerminalResultUi` so retrying or loading another
stage starts with clean ending state.

- [ ] **Step 4: Gate terminal presentation without gating persistence**

Inside `build`, calculate:

```dart
final showCampaignEnding = shouldPlayCampaignEnding(
  stageNumber: _stageNumber,
  stageCleared: session.stageCleared,
  stageFailed: session.stageFailed,
  endingCompleted: _campaignEndingCompleted,
);
```

Keep `_prepareTerminalResultIfNeeded()` in `_handleSessionChanged` unchanged.
In the terminal `Positioned.fill`, show:

```dart
if (showCampaignEnding)
  CampaignEndingOverlay(
    key: ValueKey('campaign-ending-$_campaignEndingEpoch'),
    onComplete: _completeCampaignEnding,
    onSkip: _completeCampaignEnding,
  )
else
  // existing result-ready/result-recording branch
```

- [ ] **Step 5: Add the final-result replay action**

Add nullable `VoidCallback? onReplayEnding` to `_ResultOverlay`. For a cleared
stage with `hasNextStage == false`, insert before retry:

```dart
_LargeButton(
  label: '엔딩 다시 보기',
  color: const Color(0xFFE4C67A),
  onPressed: isSavingProgress ? null : onReplayEnding,
),
const SizedBox(height: 12),
```

Key the button `campaign-ending-replay-result` through an optional `key`
parameter added to `_LargeButton`. Pass `_replayCampaignEnding` only when
`_stageNumber == finalCampaignStageNumber && session.stageCleared`.

Update the private button constructor without changing other callers:

```dart
const _LargeButton({
  required this.label,
  required this.color,
  required this.onPressed,
  this.isOutline = false,
  super.key,
});
```

Then construct the replay action with:

```dart
_LargeButton(
  key: const ValueKey('campaign-ending-replay-result'),
  label: '엔딩 다시 보기',
  color: const Color(0xFFE4C67A),
  onPressed: isSavingProgress ? null : onReplayEnding,
),
```

- [ ] **Step 6: Run the integration and existing result tests**

Run:

```powershell
flutter test test/campaign_ending_game_screen_test.dart test/game_session_controller_test.dart test/progress_store_test.dart
```

Expected: ending ordering, replay idempotence, existing persistence, and session
tests pass.

- [ ] **Step 7: Commit terminal integration**

```powershell
git add -- lib/app/screens/game_screen.dart test/campaign_ending_game_screen_test.dart
git commit -m "feat: play ending before final stage result"
```

### Task 5: Documentation And Full Verification

**Files:**
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`

- [ ] **Step 1: Record implementation behavior**

Append a dated note covering Stage 30-only eligibility, background progress
save, four scenes, skip/tap/replay behavior, exact existing sprite reuse, and
the production requirement to disable the all-stage unlock flag later.

- [ ] **Step 2: Run formatting and asset checks**

Run:

```powershell
dart format lib/app/ending/campaign_ending_flow.dart lib/app/widgets/campaign_ending_overlay.dart lib/app/screens/game_screen.dart test/campaign_ending_flow_test.dart test/campaign_ending_overlay_test.dart test/campaign_ending_game_screen_test.dart test/campaign_visual_catalog_test.dart
git diff --check
```

Expected: formatter completes and diff check exits zero apart from existing
line-ending warnings.

- [ ] **Step 3: Run the full test and analysis gates**

Run:

```powershell
flutter test
flutter analyze
```

Expected: all tests pass and analysis reports no issues.

- [ ] **Step 4: Build the device review APK**

Run: `flutter build apk --debug`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` is created.

- [ ] **Step 5: Install and launch on the connected Stage 30 review device**

Confirm `kUnlockAllCampaignStagesForDevelopment == true`, then run:

```powershell
flutter run -d R3CX70DGKGA --debug --no-resident
```

Expected: the latest debug build installs and launches on SM F741N with all
stages available for review.

- [ ] **Step 6: Commit the verification note**

```powershell
git add -- docs/exec-plans/active/initial-defense-game-foundation.md
git commit -m "docs: record final campaign ending verification"
```
