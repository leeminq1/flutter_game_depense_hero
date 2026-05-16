# Map Production Plan

현재 맵 제작은 14x14 Stage 데이터 작성과 플레이테스트 반복으로 진행한다.

## 핵심 원칙

- 모든 Stage는 `CampaignData.stage(number)`로 재현 가능해야 한다.
- 성 위치는 `citadelCell` 하나로 결정한다.
- 경로는 `pathsByDirection`과 route entry로 관리한다.
- 보이는 장애물은 실제 배치/경로 차단과 일치해야 한다.
- Stage 11~20처럼 성이 상단에 가까운 구간은 안내 배너가 하단에 있어야 한다.

## 제작 산출물

- 코드: `lib/data/campaign/campaign_data.dart`
- 검증 표: `docs/generated/current-game-data-snapshot.md`
- 사람이 읽는 요약: `docs/design-docs/map-authoring/stage-atlas.md`

## 새 Stage 작성 예시

1. `citadelCell`을 `[col,row]`로 정한다.
2. 네 방향 entry route 후보를 만들고 성과 너무 가까운 route를 제외한다.
3. Wave 1은 읽기 쉬운 front 1~2개로 시작한다.
4. 마지막 Wave는 Stage의 핵심 적 조합을 보여준다.
5. 이벤트 Stage라면 `StageEventGenerator.poolForStage` 구간에 맞는 보스 풀을 확인한다.
6. `flutter test tool/export_game_data_docs.dart`를 실행해 표를 갱신한다.
