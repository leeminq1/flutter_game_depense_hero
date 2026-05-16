# Quality Score

## 현재 품질 기준

- `flutter analyze`가 통과해야 한다.
- 핵심 테스트 묶음이 통과해야 한다.
  - `test/tile_grid_stage_data_test.dart`
  - `test/campaign_balance_smoke_test.dart`
  - `test/run_offers_and_road_tiles_test.dart`
  - `test/game_session_controller_test.dart`
- 문서 수치 변경 후 `flutter test tool/export_game_data_docs.dart`로 스냅샷을 재생성한다.

## 문서 품질 기준

- 문서의 수치는 코드에서 추출한 표와 일치해야 한다.
- `Stage`, `Wave`, `Camp`, `설계 카드` 용어를 우선 사용한다.
- 과거 용어가 필요하면 “내부 호환명” 또는 “과거 문서”라고 명시한다.
- 문서만 보고 게임 루프, 데이터 구조, 핵심 수치, Stage 구성, 빌드 절차를 재구현할 수 있어야 한다.

## 릴리즈 전 체크

- 비공개 테스트: 전체 Stage 해금 플래그 유지 가능.
- 운영 배포: 전체 Stage 해금 플래그를 false로 변경하고 문서도 갱신.
- AAB 위치: `build/app/outputs/bundle/release/app-release.aab`
