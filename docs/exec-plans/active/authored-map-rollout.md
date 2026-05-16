# Authored Map Rollout

이 계획은 현재 대부분 완료되었고, 최신 구현 요약은
`docs/design-docs/map-authoring/stage-atlas.md`로 이동했다.

## 현재 상태

- Stage 1~30은 모두 `CampaignData.stage(number)`로 생성된다.
- 각 Stage는 성 좌표, 네 방향 route, 장애물, Wave, 이벤트/포격 데이터를 가진다.
- 최신 Stage 요약은 `stage-atlas.md`와 `current-game-data-snapshot.md`를 기준으로 한다.

## 남은 관리 작업

- 플레이테스트에서 성 위치/경로 가독성 문제가 나오면 `CampaignData`를 수정한다.
- 수정 후 `flutter test tool/export_game_data_docs.dart`로 스냅샷을 다시 생성한다.
- 오래된 working card는 참고 메모이며 실제 구현값으로 취급하지 않는다.
