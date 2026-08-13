# Coin Mill Wave-Only Income Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restrict periodic Coin Mill gold production to active Wave combat and release production version `1.0.34+35`.

**Architecture:** Keep the global Flame update lifecycle unchanged and add a pure, testable predicate for Coin Mill timer advancement. Use that predicate only around the existing periodic timer/payout block in `_updateTowers`; `startNextWave` retains its separate bonus. Production packaging keeps the campaign review flag disabled.

**Tech Stack:** Dart, Flutter, Flame, Flutter tests, Gradle Android App Bundle, Git.

---

### Task 1: Wave-Only Periodic Income

**Files:**
- Create: `lib/game/economy/coin_mill_income_policy.dart`
- Create: `test/coin_mill_income_policy_test.dart`
- Modify: `lib/game/core/depense_game.dart:3180-3200`
- Modify: `docs/product-specs/economy-and-monetization.md`

- [ ] **Step 1: Write the failing policy test**

```dart
import 'package:depense_game/game/economy/coin_mill_income_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('periodic Coin Mill income advances only during an active Wave', () {
    expect(shouldAdvanceCoinMillIncome(waveActive: true), isTrue);
    expect(shouldAdvanceCoinMillIncome(waveActive: false), isFalse);
  });
}
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/coin_mill_income_policy_test.dart`

Expected: compilation fails because the policy file and function do not exist.

- [ ] **Step 3: Add the minimal policy**

```dart
bool shouldAdvanceCoinMillIncome({required bool waveActive}) => waveActive;
```

- [ ] **Step 4: Gate the existing timer block**

Import the policy in `depense_game.dart`. In the Coin Mill branch, decrement
`economyTimer` and award periodic income only when
`shouldAdvanceCoinMillIncome(waveActive: _waveActive)` is true. Always continue
after the Coin Mill branch so it never executes attack logic.

- [ ] **Step 5: Document the economy rule**

Update the Coin Mill bullet to state that periodic income is generated only
during an active Wave, pauses with the Wave timer outside combat, and the
existing Wave-start bonus remains separate.

- [ ] **Step 6: Run targeted tests and commit**

Run:

```powershell
flutter test test/coin_mill_income_policy_test.dart test/tile_grid_stage_data_test.dart test/game_session_controller_test.dart
```

Expected: all targeted tests pass.

Commit:

```powershell
git add -- lib/game/economy/coin_mill_income_policy.dart lib/game/core/depense_game.dart test/coin_mill_income_policy_test.dart docs/product-specs/economy-and-monetization.md
git commit -m "fix: limit coin mill income to active waves"
```

### Task 2: Production Version 1.0.34

**Files:**
- Modify: `pubspec.yaml`
- Modify: `docs/exec-plans/active/initial-defense-game-foundation.md`

- [ ] **Step 1: Increment the package**

Set:

```yaml
version: 1.0.34+35
```

- [ ] **Step 2: Record production behavior**

Add a dated note covering the Wave-only periodic income, preserved Wave-start
bonus, timer freezing behavior, version `1.0.34+35`, and the requirement that
the all-stage review flag remains false.

- [ ] **Step 3: Commit the version**

```powershell
git add -- pubspec.yaml docs/exec-plans/active/initial-defense-game-foundation.md
git commit -m "release: prepare version 1.0.34"
```

### Task 3: Verify, Build, And Push

**Files:**
- Verify: `build/app/outputs/bundle/release/app-release.aab`

- [ ] **Step 1: Format and inspect source state**

Run formatting, `git diff --check`, confirm `version: 1.0.34+35`, and confirm
`kUnlockAllCampaignStagesForDevelopment = false`.

- [ ] **Step 2: Run all gates**

Run:

```powershell
flutter analyze
flutter test
```

Expected: no analysis issues and all tests pass.

- [ ] **Step 3: Build and verify the signed AAB**

Run: `flutter build appbundle --release`

Confirm the release manifest reports version name `1.0.34`, version code `35`,
and `jarsigner -verify` reports `jar verified`.

- [ ] **Step 4: Commit verification evidence and push**

Append exact verification results to the active exec plan, commit them, push
`main` to `origin`, and confirm `origin/main...HEAD` reports `0 0`.

## Plan self-review

- The periodic timer, Wave-start bonus, timer freezing, version, production
  flag, tests, signed artifact, and push each map to an explicit step.
- The change does not modify the global pause/update lifecycle or any economy
  number.
- No placeholders or ambiguous state behavior remain.
