# 맵 제작 워크플로우

이 폴더는 현재 `Pixel Guard: Wave`의 Stage 맵 제작 규칙을 정리한다. 실제 구현값은
`stage-atlas.md`와 `docs/generated/current-game-data-snapshot.md`를 기준으로 한다.

## 현재 구현 단위

- `Stage`: 맵과 적 조합이 바뀌는 전투 단위
- `Wave`: 한 Stage 안의 적 공격 단위
- `citadelCell`: 성 중심 좌표 `[col,row]`
- `pathsByDirection`: 북/동/남/서 경로 좌표
- `TileType.path`: 적 이동 경로
- `TileType.buildable`: 배치 가능 칸
- `StageObstacleDefinition`: 보이는 장애물이자 배치/경로 차단물

## 제작 순서

1. 성 좌표를 정한다.
2. 네 방향마다 최대 3개 entry route가 성 주변 한 칸으로 닿게 한다.
3. 경로가 너무 짧은 front는 초반 Wave에서 제외하거나 적 수를 줄인다.
4. 장애물은 경로를 가리지 않되 배치 선택을 만들 정도로만 둔다.
5. Wave마다 front, 적 종류, 수량, 간격을 정한다.
6. Stage 이벤트 주사위와 포격이 겹칠 때 화면이 읽히는지 확인한다.
7. `flutter test tool/export_game_data_docs.dart`로 Stage Atlas 스냅샷을 갱신한다.

## 오래된 작업 카드

`stage-*-working-card.md` 파일들은 제작 과정의 메모로 남아 있다. 실제 좌표/골드/Wave가
다르면 `stage-atlas.md`와 코드가 우선한다. 새로 구현할 때는 작업 카드보다
`CampaignData.stage(number)`의 결과를 확인한다.

## 검증 체크리스트

- 성이 화면 가장자리 UI와 겹치지 않는가.
- 안내 배너가 Stage 11~20에서 하단에 나와 성과 몬스터를 가리지 않는가.
- 첫 Wave에서 플레이어가 적이 오는 방향을 읽을 수 있는가.
- 포격/보스/쇼크웨이브가 동시에 나와도 피해 원인이 구분되는가.
- Stage 10 이후 기본 레벨 보정 때문에 초반 배치 선택이 무의미해지지 않는가.
