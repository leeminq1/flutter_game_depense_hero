# Campaign Ending Swipe And Production Release Design

## Scope

Change only the Stage 30 ending navigation and production packaging state.
Combat, progression rules, ending copy, artwork, result ordering, rewards, and
all other Stage behavior remain unchanged.

## Ending navigation

- Remove all timer-based scene advancement.
- Remove tap-to-advance from the full-screen ending surface.
- A deliberate leftward horizontal swipe advances one scene.
- A deliberate rightward horizontal swipe returns one scene.
- Ignore backward swipes on scene 0 and forward swipes on scene 3.
- Require either at least 44 logical pixels of horizontal travel or a horizontal
  release velocity of at least 350 logical pixels per second.
- Ignore vertical-dominant drags so normal hand movement does not change scenes.
- Keep `건너뛰기` on scenes 0-2, `결과 보기` on scene 3, progress dots, and the
  result screen's `엔딩 다시 보기` action.
- Replaying the ending remains presentation-only and never records completion
  or awards currency again.

## Production release

- Increment `pubspec.yaml` from `1.0.32+33` to `1.0.33+34`.
- Set `kUnlockAllCampaignStagesForDevelopment` to `false`.
- Replace the development-unlock regression assertion with a production
  assertion that a fresh profile unlocks Stage 1 only.
- Update product documentation that currently describes the all-stage review
  build so it reflects production progression.
- Build `build/app/outputs/bundle/release/app-release.aab` using the existing
  release signing configuration.
- Commit the ending interaction and production release changes on `main`, then
  push `main` to the configured GitHub `origin`.

## Verification

- Widget tests prove that waiting and tapping do not advance the ending.
- Widget tests prove left-next, right-previous, boundary behavior, skip, and
  final result callbacks.
- Progress-store tests prove a fresh production profile does not expose all
  stages.
- Run formatting, `git diff --check`, `flutter analyze`, and the full
  `flutter test` suite.
- Build the release AAB and inspect its version name/code before pushing.

## Self-review

- No placeholders or deferred decisions remain.
- Swipe direction, thresholds, boundary behavior, and retained controls are
  explicit.
- The release version is greater than the current remote version.
- The all-stage review flag is explicitly forbidden in the production build.
