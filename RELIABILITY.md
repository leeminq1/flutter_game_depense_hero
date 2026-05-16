# Reliability

## Goals

- 전투가 멈추지 않고 Wave가 끝까지 정리되어야 한다.
- 진행도 저장 실패가 플레이를 망치지 않게 UI가 명확해야 한다.
- 보스/포격/쇼크웨이브 같은 큰 이벤트가 겹쳐도 원인이 읽혀야 한다.

## Runtime Rules

- 남은 적 카운트는 alive enemy와 pending spawn을 기준으로 재조정한다.
- 성 도달, 적 사망, Wave 종료, Stage 종료는 세션 컨트롤러에 즉시 반영한다.
- Stage 실패/클리어 시 결과 팝업이 나타나야 하며, 저장이 지연될 때 버튼 상태를 막는다.
- 광고 재시도는 실패해도 일반 재시도 흐름을 막지 않는다.

## Data Reliability

- durable state는 `ProgressStore`에 저장한다.
- 전투 중 임시 상태는 DB에 쓰지 않는다.
- Web/test 환경은 in-memory store를 허용한다.
- 현재 테스트 빌드는 전체 Stage 해금 플래그가 켜져 있으므로, 해금 관련 QA는 운영 플래그에서 다시 확인한다.
