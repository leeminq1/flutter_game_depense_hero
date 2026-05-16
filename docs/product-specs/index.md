# 제품 사양 인덱스

이 폴더는 현재 구현된 `Pixel Guard: Wave`의 제품 사양 source of truth다.
문서는 한국어 중심으로 작성하고, 코드 식별자는 영어 원문을 병기한다.

## 핵심 문서

| 문서 | 상태 | 목적 |
| --- | --- | --- |
| `core-game-loop.md` | active | 타이틀, 캠프, 전투, 결과, 설정까지 전체 플레이 흐름 |
| `campaign-structure.md` | active | 30 Stage 구조, 해금, Wave, 주사위 이벤트, 포격 |
| `economy-and-monetization.md` | active | 전투 골드, 보상, Meta Gold, Siege Token, 메타 업그레이드 |
| `roster-and-buildables.md` | active | 타워, 성벽, 영웅, 적, 보스, 주사위 카드 수치 |
| `runtime-data-contracts.md` | active | 현재 Dart 타입과 런타임 데이터 계약 |
| `new-user-onboarding.md` | active | Stage 1~5 학습 흐름과 안내 UI |
| `map-production-plan.md` | support | 맵 제작 절차. 최신 좌표표는 `design-docs/map-authoring/stage-atlas.md` |
| `enemy-asset-pipeline.md` | support | LPC 적 에셋 제작 원칙 |
| `web-verification-and-tooling.md` | support | Flutter Web/브라우저 검증 절차 |

## 수치표

최신 수치표는 코드에서 생성한다.

- 생성 명령: `flutter test tool/export_game_data_docs.dart`
- 출력 파일: `docs/generated/current-game-data-snapshot.md`

수치를 손으로 복사해야 할 때는 이 스냅샷을 기준으로 한다. 밸런스 변경 후에는
반드시 스냅샷을 다시 생성한다.

## 오래된 문서 처리

과거 `Citadel Siege`, `Siege`, `Act`, `Cycle` 용어가 남은 문서는 역사적 맥락이나
내부 호환명 설명일 때만 허용한다. 현재 플레이어-facing 문서는 `Stage`와 `Wave`를
사용한다.
