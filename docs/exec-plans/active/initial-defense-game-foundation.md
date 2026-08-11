# Initial Defense Game Foundation

이 계획은 first playable 구축 기록에서 시작했지만, 현재 프로젝트는 비공개 테스트 빌드
단계에 있다. 최신 구현의 source of truth는 코드와 현재 문서 허브다.

## 현재 완료 상태

- Flutter + Flame 전투 런타임 구축.
- Stage 1~30 캠페인 데이터 구축.
- 타워, 성벽, 영웅, 적, 이벤트 보스, 설계 카드 주사위 구현.
- 로컬 진행도 저장, 오디오 설정 저장, 보상형 재시도 광고 서비스 구현.
- Android release AAB 빌드 가능.
- 문서 스냅샷 생성 도구 `tool/export_game_data_docs.dart` 추가.

## 현재 릴리스 빌드

- 버전: `1.0.31+32`
- 패키지: `com.min21.pixelguardwave`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- 전체 Stage 해금 디버그: 꺼짐

## 다음 운영 전환 체크

- 개인정보처리방침과 Google Play 데이터 보안 양식 최종 확인.
- Stage 16 이후 이벤트 보스 체감 재검증.
- 문서 스냅샷 재생성 후 AAB 빌드.

## 2026-05-17 Balance Verification Note

- Fixed stage result evaluation to prefer the authoritative game terminal
  state, and verified Stage 17 with 3 HP and 541 gold awards 3 stars.
- Tuned event bosses so stage-event enemies take full physical damage.
- Tuned event Bastion Overlord to sit just above the event Corrupted Knight
  in HP and contact pressure while preserving the 2 HP boss leak rule.
- Raised general enemy HP by 10%; contact damage now uses +2 for weak
  reroute-first enemies, +1 for standard enemies, and no increase for Grave
  Guard, Corrupted Knight, or Bastion Overlord.
- Raised bombardment minimum odds to 50% from Stage 2 onward. Stage 15+
  now rolls a second late-wave bombardment on the opposite wave, scaling from
  28% to 40%.
# 2026-05-20 Balance Implementation Note

- Implemented capped linear normal-wave pressure normalization across Stage 1~30.
- Wave 1 targets about 90% of prior pressure; final Wave targets 130%; middle
  Waves interpolate linearly.
- Gold rewards, spawn timing, enemy counts, citadel leak damage, and Stage Event
  boss stats stay unchanged.

# 2026-05-26 Wave Slope Tuning Intent

- Tune only normal Stage wave pressure targets.
- Keep Wave 1 pressure unchanged.
- Increase current intra-stage pressure gaps by about +10% for Wave 1 to 2,
  +20% for Wave 2 to 3, and +10% for Wave 3 to 4.
- Keep enemy counts, rewards, stage event bosses, bombardment, and maps unchanged.

# 2026-05-26 Wave Slope Tuning Verification

- Updated normal Stage wave pressure targets only.
- Regenerated `docs/generated/current-game-data-snapshot.md`.
- Bumped app version to `1.0.27+28`.
- Verified with `flutter test test/campaign_balance_smoke_test.dart`.
- Verified with the required smoke test bundle from `QUALITY_SCORE.md`.
- Verified with `flutter analyze`.
- Built release AAB at `build/app/outputs/bundle/release/app-release.aab`.

# 2026-06-01 Difficulty Ramp And Boss Tuning Note

- Retuned normal Stage wave pressure ramps to target about 160% for Stage 1-10,
  145% for Stage 11-20, and 135% for Stage 21-30.
- Changed Stage Event boss HP to a Stage-based piecewise curve: Stage 4 starts
  at 1000 HP, Stage 4-10 adds 285 per event tier, Stage 13-19 adds 370 per
  event tier, and Stage 22-28 adds 450 per event tier.
- Capped high-damage Stage Event wall breakers so Stage 7/10 Grave Guard no
  longer has a larger damage spike than later bosses.
- Added `tool/export_difficulty_audit.dart` and generated
  `docs/generated/difficulty-audit.md` for verification-friendly balance tables.
- Bumped release version to `1.0.28+29`, disabled
  `kUnlockAllCampaignStagesForDevelopment`, and built
  `build/app/outputs/bundle/release/app-release.aab`.
- Verified with `flutter test test/tile_grid_stage_data_test.dart
  test/campaign_balance_smoke_test.dart test/run_offers_and_road_tiles_test.dart
  test/game_session_controller_test.dart tool/export_game_data_docs.dart
  tool/export_difficulty_audit.dart`, `flutter analyze`, and `git diff --check`.

# 2026-06-13 Settings And Credits Note

- Added a Settings entry for third-party credits and licenses.
- Added a bundled `assets/legal/lpc_credits.txt` file for LPC attribution and
  release review.
- Expanded Settings audio controls to cover master, music, and SFX volume plus
  mute persistence.
- Bumped release version to `1.0.30+31`.
- Verified phone-sized Settings behavior with `test/settings_screen_test.dart`.
- Verified with `flutter test`, `flutter analyze`, `git diff --check`, and
  `flutter build appbundle`.
- Confirmed the release AAB includes
  `base/assets/flutter_assets/assets/legal/lpc_credits.txt`.

# 2026-06-29 Production Release Verification Note

- Changed the title screen footer stats to show cleared Stage count as `Lv`,
  total stars, and no separate cleared-count chip.
- Added a phone-sized title-screen widget test for the `Lv.19`, `55`, hidden
  `19/30`, and Stage 20 continue-state display.
- Bumped release version to `1.0.31+32` for a new production upload.
- Verified with `flutter test`, `flutter analyze`, `git diff --check`, and
  `flutter build appbundle --release`.
- Confirmed the release manifest has `versionName="1.0.31"` and
  `versionCode="32"`, and the AAB includes bundled legal credits.

# 2026-08-09 Combat UX, Tutorial, And Stage 1 Visual Slice Note

- Added bounded 0.7x–2.5x battlefield pan/zoom, tap suppression after drag,
  conditional camera reset, explicit enemy-front labels, and immediate
  pause/resume state updates.
- Rebuilt the lower construction UI as a state-adaptive panel with 74×82
  cards during preparation and a 52–60px combat bar during an active Wave.
- Replaced the automatic Stage 1 briefing with an eight-step fail-less training
  map. New games continue directly to Stage 1; the title-screen tutorial ends
  with replay/home choices. The tutorial includes all four spawn directions,
  wall blocking, safe tower placement, a 1.5x pass-through/contact-damage demo,
  combined defense, and a mini Wave.
- Enabled constrained top-down 3/4 pixel visuals only for the tutorial and
  Stage 1: T1 towers, citadel, roads, connected walls, village gatehouse,
  signpost, well, and supply wagons. T2/T3/branches, heroes/enemies, and Stage
  2–30 intentionally keep the current fallbacks until device acceptance.
- Kept enemy stats, Wave composition, tower/barrier stats, economy, and
  difficulty data unchanged.
- Verified the 430×900 browser preview for the compact tutorial card, visible
  four-direction lesson, terrain, connected wall pass, and Stage 1 prop style.
- Automated verification: `flutter test` (125 passed), `flutter analyze`
  (zero issues), `flutter build apk --debug`, and `git diff --check`.
- Device acceptance remains: frame pacing, 1x/2.5x pivot readability, pinch
  focal stability, no accidental placement after drag, connected T/cross walls,
  natural unit overlap, 2–3 minute tutorial pacing, pause behavior, automatic
  Stage 1 transition, and menu replay/home completion routes.

# 2026-08-09 Stage 1 Device UX Correction Note

- Added an explicit Flutter clip directly around the Flame `GameWidget`, so a
  2.5x canvas transform cannot paint across the top HUD or system SafeArea.
- Changed the camera range to 1.0x–2.5x. The default/reset state fills the
  battlefield without exposing the undersized 0.7x map.
- Kept coin and Stage chips fixed on the compact HUD while Wave, enemy count,
  and spawn direction use the middle horizontal scroller.
- Made the Stage 1 recap non-blocking: it has no close button and disappears
  after three seconds.
- Limited Stage 1 barriers to the currently visible road cells while towers
  retain road and grass placement. Stage 2–30 placement behavior is unchanged
  pending Stage 1 device acceptance.
- Reduced Stage 1 grass repetition contrast, softened tower placement slots,
  and reduced the visual citadel from 3.25 to 2.6 tiles without changing its
  logical footprint or combat position.
- Verification: `flutter test` passed 128 tests, `flutter analyze` reported no
  issues, `flutter build apk --debug` succeeded, and `adb install -r` succeeded
  on the connected SM-F741N (`R3CX70DGKGA`).

# 2026-08-11 Campaign Visual Expansion Review-Build Note

- Fast-forwarded the accepted Stage 1 work into local `main` and removed the
  redundant local feature branch so device testing continues from one working
  tree.
- Replaced the Stage 1-only visual switch with a campaign visual catalog used
  by the tutorial and Stages 1-30.
- Kept the completed level 1-3 tower art, full-cell barrier art, and player
  citadel consistent across the campaign.
- Added six environment treatments aligned with the existing five-Stage theme
  brackets. Stage data, enemy stats, Wave pressure, structure values, and
  combat balance were not changed.
- Replaced the incomplete four-module road family with deterministic isolated,
  cap, straight, corner, tee, and cross modules. All 16 connectivity masks and
  every active Wave route across Stages 1-30 are covered by tests.
- Removed the four superseded Stage 1 road files after verifying they had no
  remaining runtime, test, tool, or asset-manifest references.
- Added a four-frame bombardment shell strip and six-frame non-looping impact
  strip while preserving bombardment probability, target selection, damage,
  radius, and timing.
- Enabled `kUnlockAllCampaignStagesForDevelopment` for the requested local
  content-review build. It remains release-unsafe and must be disabled before
  production packaging.
- Current verification: deterministic asset exporters pass `--check`, all 140
  Flutter tests pass, and `flutter analyze` reports no issues. Android debug
  build and real-device review remain the final handoff gates.

# 2026-08-11 Device Review Correction: Heroes And Landmarks

- Device screenshots confirmed Stage 2-30 heroes spawned inside the enlarged
  citadel artwork because the shared candidate list preferred a one-cell offset.
- Hero auto-placement now starts outside the full citadel render footprint,
  preferring the visually forward/south side and falling back to clear side cells.
- Eleven remaining legacy 96px campaign landmarks were replaced by theme-aware
  256px top-down 3/4 assets and mapped through `CampaignVisualCatalog`.
- Regression coverage checks every campaign hero spawn and every authored
  landmark path rather than sampling Stage 1 only.

# 2026-08-11 Device Review Correction: Placement And Projectile Trails

- Removed the supplemental line trails drawn behind regular projectiles and
  bombardment shells. Authored projectile sprites remain responsible for their
  own readable motion effects.
- Applied the road-only barrier placement rule to Stages 1-30 instead of Stage
  1 alone. Barrier slot guidance and tap placement now use the same filtered
  cells for the currently visible Wave routes.
- Added regression coverage for every Wave in every campaign Stage and a
  renderer source contract that rejects supplemental guide-line trails.

# 2026-08-11 Stage 30 Campaign Ending Verification Note

- Added a Stage 30-only campaign ending that plays on any successful clear
  before the existing result overlay. Stage 30 failure and Stages 1-29 retain
  their existing result flow.
- Kept terminal progress recording in the background as soon as the run ends,
  so the ending does not delay or duplicate reward persistence.
- Added four tap-advance scenes with automatic 4s/4s/5s pacing, a skip action,
  an explicit final `결과 보기` action, and a result-screen `엔딩 다시 보기`
  action that does not save or award progress again.
- Reused the exact campaign citadel, five hero sprites, and representative
  enemy sprites over a newly generated portrait dawn battlefield. The prompt,
  source, provenance, export path, and runtime usage are recorded in
  `docs/generated/campaign-ending-asset-spec.md`.
- Verified `flutter analyze` with zero issues, all 152 Flutter tests, and
  `flutter build apk --debug`. Installed and launched the build on SM F741N
  (`R3CX70DGKGA`).
- `kUnlockAllCampaignStagesForDevelopment` remains enabled for this requested
  review build and must be disabled before production AAB packaging.
