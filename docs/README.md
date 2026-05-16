# Pixel Guard: Wave 문서 허브

이 폴더의 문서는 현재 코드 기준으로 `Pixel Guard: Wave`를 다시 구현할 수 있게
정리한 운영 문서다. 수치와 규칙은 코드가 단일 진실이며, 문서가 코드와 다르면
코드를 우선하고 문서를 갱신한다.

## 읽는 순서

1. `product-specs/core-game-loop.md` - 플레이어가 실제로 겪는 전체 흐름
2. `product-specs/campaign-structure.md` - 30 Stage 구조와 해금/이벤트 규칙
3. `product-specs/roster-and-buildables.md` - 타워, 성벽, 영웅, 적, 보스, 주사위 수치
4. `product-specs/economy-and-monetization.md` - 골드, 보상, 메타 성장
5. `product-specs/runtime-data-contracts.md` - Dart 데이터 모델과 런타임 연결
6. `design-docs/gameplay-balance-pass.md` - 현재 밸런스 의도
7. `design-docs/map-authoring/stage-atlas.md` - Stage 1~30 전장 요약
8. `generated/current-game-data-snapshot.md` - 코드에서 추출한 최신 수치표

## Source Of Truth

- 게임 데이터: `lib/data/campaign/campaign_data.dart`
- Stage/이벤트/성벽 타입: `lib/game/models/stage_definition.dart`
- 적 타입: `lib/game/models/enemy_definition.dart`
- 타워/영웅/주사위: `lib/game/models/*_definition.dart`
- 메타 성장: `lib/data/meta/meta_upgrade_definitions.dart`
- 전투 계산: `lib/game/core/depense_game.dart`
- 진행도 저장: `lib/data/persistence/`

## Generated 영역

`docs/generated`는 자동 산출물, 제출 자료, 이미지 스냅샷을 둔다. 게임 규칙을
확인할 때는 `current-game-data-snapshot.md`만 최신 수치표로 사용한다. 기존
이미지와 외부 참고자료는 삭제하지 않고 보조 자료로 유지한다.

## 용어 원칙

- 플레이어/문서 용어: `Stage`, `Wave`, `Camp`, `설계 카드`, `성벽`, `타워`, `영웅`
- 내부 호환명: `AssaultCycleDefinition`, `SiegeDefinition` 등은 코드 호환용 이름이다.
- 과거 문서의 `Citadel Siege`, `Siege`, `Act`, `Cycle` 표현은 현재 게임 규칙의
  source of truth가 아니다.
