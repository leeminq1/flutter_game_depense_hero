# Stage 30 Campaign Ending Design

## Goal

Give players an emotional conclusion after clearing Stage 30 while preserving
the existing reward, progress-save, retry, and home-navigation behavior.

The ending thanks players for completing the campaign and offers a hopeful
message to people enduring difficult everyday lives.

## Player Flow

The successful final-stage flow is:

1. Stage 30 combat reaches the existing cleared terminal state.
2. Progress evaluation, stars, rewards, and persistence begin immediately in
   the background through the existing terminal-result preparation flow.
3. The campaign ending appears before the result overlay.
4. The player may watch the ending, tap to advance individual scenes, or skip
   the ending entirely.
5. The existing Stage 30 result overlay appears after the ending completes or
   is skipped.
6. The final result offers `엔딩 다시 보기`, `다시 도전`, and `홈으로`.

Stage 30 failure and all Stage 1-29 terminal states keep their existing result
flow. Every successful Stage 30 run plays the ending; replaying the ending from
the result does not evaluate or save rewards again.

## Ending Structure

The ending contains four automatically advancing scenes with a maximum total
duration of about 20 seconds. A tap advances the current scene immediately.
The upper-right `건너뛰기` action exits directly to the prepared result.

### Scene 1: Silence After The Last Wave

- Duration: 4 seconds.
- Visual: the final battlefield darkens, embers drift, and enemy motion fades.
- Copy: `마지막 공세가 멎었습니다.`

### Scene 2: Those Who Endured

- Duration: 4 seconds.
- Visual: the five hero sprites gather while the final enemies lower their
  weapons and recede into the distance rather than being celebrated as corpses.
- Copy: `우리가 지킨 것은 성벽만이 아니었습니다.`

### Scene 3: A New Morning

- Duration: 5 seconds.
- Visual: warm dawn reaches the citadel and the ruined ground gradually gains
  color. The citadel and hero sprites remain the exact in-game assets.
- Copy: `버텨낸 시간은 결코 사라지지 않습니다.`

### Scene 4: Message To The Player

- Duration: 7 seconds or until the player continues.
- Visual: the citadel stands behind the complete hero party. The last enemy
  silhouettes disappear beyond the bright horizon.
- Copy:

  ```text
  힘든 하루를 지나 여기까지 온 당신에게.

  포기하지 않고 살아낸 오늘은
  이미 하나의 승리입니다.

  이 성과 이야기를 끝까지 지켜 주셔서 고맙습니다.
  ```

- Closing mark: `PIXEL GUARD: WAVE` and `결과 보기`.

## Visual Direction

The ending combines one new AI-assisted environment background with the exact
existing game sprites. AI generation must not redraw the heroes, citadel, or
enemies because their silhouettes and equipment must remain recognizable.

The new background is a portrait top-down 3/4 pixel-art battlefield at dawn:
dark ruined ground at the bottom, a warm horizon at the top, subtle drifting
ash, no people, no creatures, no buildings, no text, and enough central empty
space for composited sprites. Its prompt, source, export process, and final
asset path are recorded under `docs/generated/`.

Runtime composition uses:

- `CampaignVisualCatalog.citadel.assetPath` for the defended castle.
- `HeroVisualCatalog` south-facing base frames for all five heroes.
- `EnemyVisualCatalog` assets for the Bastion Overlord, Corrupted Knight, and
  representative lesser monsters.
- Flutter opacity, translation, scale, warm gradient, vignette, and lightweight
  particle animation. No new Flame simulation runs during the ending.

The final asset is bundled as
`assets/images/campaign_ending_dawn.png` and remains readable on narrow Android
phones without cropping the hero party or closing message.

## Architecture

Flutter owns the ending because it is navigation and presentation, not combat
simulation.

- A focused `CampaignEndingOverlay` stateful widget owns scene timing,
  animation, tap-to-advance, skip, and completion callbacks.
- A small pure flow helper decides whether a terminal state should display the
  ending. It returns true only for a cleared Stage 30 whose ending is not
  currently complete.
- `GameScreen` starts the existing terminal result preparation immediately.
  It layers the ending above the frozen game while withholding the result
  overlay until the ending completes.
- Replaying from the final result resets only ending presentation state. It
  does not reset the game, clear the completion result, load another ad, or
  write progression again.
- Loading a different stage or retrying resets all ending presentation state.

The result data and ending animation therefore run independently: persistence
is never delayed by the cutscene, and the result can appear immediately after
a skip if preparation already finished.

## State Rules

- `Stage 30 + cleared + ending not completed` displays the ending.
- `Stage 30 + failed` never displays the ending.
- `Stage 1-29` never displays the campaign ending.
- Completing or skipping the ending reveals the existing result overlay.
- Replaying the ending hides the result temporarily and starts Scene 1.
- Leaving for home, retrying, or loading another stage cancels ending timers.
- App backgrounding follows the existing lifecycle pause behavior; progress
  persistence continues through the existing terminal save future.

No durable `ending watched` flag is added. The feature is intentionally
replayable on every successful Stage 30 run.

## Final Result Actions

The cleared Stage 30 result keeps existing stars and reward rows and replaces
the absent next-stage action with:

1. `엔딩 다시 보기` — shows the cutscene again without saving rewards.
2. `다시 도전` — uses the existing retry flow.
3. `홈으로` — uses the existing return-to-camp flow.

Failure results keep the existing retry, rewarded retry, and home actions and
do not show `엔딩 다시 보기`.

## Error And Loading Behavior

- If the AI background fails to decode, the overlay renders the same scenes on
  a deterministic dawn gradient so the ending remains usable.
- If terminal progress saving is still running when the ending finishes, the
  existing result-recording indicator remains until the result becomes ready.
- Repeated session notifications cannot restart the ending because the overlay
  state is latched for the current stage run.
- All animation timers are disposed with the overlay and cannot update an
  unmounted `GameScreen`.

## Accessibility And Pacing

- Copy uses high-contrast cream text on a dark translucent panel and respects
  safe areas.
- The ending does not depend on audio to communicate meaning.
- Tap-to-advance and skip provide a fast path for repeat clears.
- The final scene waits for explicit `결과 보기` after its text has appeared,
  so slower readers are not forced into the result screen.
- Animations use opacity and translation rather than rapid flashes.

## Verification

Automated coverage verifies:

- only a cleared Stage 30 requests the ending;
- failure and Stage 1-29 go directly to their existing result flow;
- result preparation begins while the ending is visible;
- skip and completion reveal the result exactly once;
- replay does not call progression recording again;
- Stage 30 result actions are ending replay, retry, and home;
- the background and every referenced sprite are bundled;
- narrow phone layouts show the closing copy and actions without overflow.

Device acceptance on the connected Android phone verifies:

- Stage 30 clear transitions into Scene 1 before the result overlay;
- the four scenes feel readable and emotionally coherent;
- tap advance, skip, `결과 보기`, and `엔딩 다시 보기` work;
- stars and rewards match the completed run;
- retry and home retain their current behavior;
- there is no ending on Stage 30 failure.
