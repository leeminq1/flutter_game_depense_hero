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

## 현재 테스트 빌드

- 버전: `1.0.27+28`
- 패키지: `com.min21.pixelguardwave`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- 전체 Stage 해금 디버그: 켜짐

## 다음 운영 전환 체크

- 전체 Stage 해금 디버그 끄기.
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
