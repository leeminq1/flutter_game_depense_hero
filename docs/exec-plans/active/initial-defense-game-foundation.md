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
