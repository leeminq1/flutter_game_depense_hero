# Coin Mill Wave-Only Income Design

## Problem

The Coin Mill's periodic income timer currently advances whenever the Flame
simulation updates. As a result, it produces gold during initial preparation
and between Waves. Manual pause and terminal Stage states already stop the
simulation, but preparation and recovery do not.

## Approved behavior

- Keep the existing one-time Coin Mill bonus when a Wave starts.
- Advance the 4.5-second periodic income timer only while `_waveActive` is true.
- During initial preparation, between-Wave recovery, manual pause, Stage clear,
  and Stage failure, preserve the timer's remaining duration without advancing
  or resetting it.
- When the next Wave starts, periodic income resumes from the preserved timer.
- Do not change Coin Mill cost, income amount, interval, upgrades, branches,
  Wave-start bonus, other rewards, or any combat balance value.

## Implementation boundary

The fix belongs in `DefensePrototypeGame._updateTowers`, where the Coin Mill's
periodic timer is currently decremented. Gate only that timer-and-payout block
with `_waveActive`. Do not gate the Wave-start bonus in `startNextWave` and do
not change the global game update loop.

## Testing

- A deterministic unit test verifies the periodic timer is frozen outside an
  active Wave and resumes during an active Wave.
- Existing tests continue to verify the Wave-start bonus and economy values.
- Full Flutter tests and analysis must pass.

## Production release

- Increment the package from `1.0.33+34` to `1.0.34+35`.
- Keep `kUnlockAllCampaignStagesForDevelopment = false`.
- Build and verify the signed release AAB, then push `main` to GitHub.

## Self-review

- The periodic and Wave-start income sources are explicitly separated.
- Timer preservation semantics are explicit for every non-combat state.
- No unrelated economy or combat behavior is in scope.
