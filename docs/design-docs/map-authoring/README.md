# 맵 설계 워크플로우

이 폴더는 `수작업 전장 설계`를 위한 협업용 기준 문서 폴더입니다.

이 폴더는 아래를 함께 결정할 때 사용합니다.

- 스테이지마다 성이 어디에 위치하는지
- 각 사이클에서 어느 방향 전선이 열리는지
- 어떤 칸이 보이는 장애물 때문에 막히는지
- 어디에 킬존과 후퇴 거점을 만들지
- 왜 어떤 공성전이 다른 공성전보다 다르게 느껴지는지

## 기본 방향

캠페인 맵은 `완전 랜덤 장애물 생성`보다 `수작업 authored 맵`을 우선합니다.

이유:

- 이 게임은 고변수 로그라이크 보드보다 읽을 수 있는 공성 퍼즐형 디펜스에 더 잘 맞습니다
- 플레이어가 왜 졌는지 배치, 동선, 조합 관점에서 배울 수 있어야 합니다
- 스테이지 개성은 수치 증가보다 지형과 구조에서 먼저 나와야 합니다

랜덤은 보조 역할로만 허용합니다.

- 소규모 장식 변주
- 동일 역할을 하는 가벼운 소품 교체
- 미리 승인된 작은 장애물 후보군 안에서의 제한적 변형

메인 30스테이지 캠페인에는 `무제한 랜덤 장애물 레이아웃`을 사용하지 않습니다.

## 협업 방식

우리는 아래 순서로 캠페인 맵을 만듭니다.

1. 공통 맵 원칙과 규칙을 먼저 잠근다
2. 액트 하나를 고르고 그 액트의 5개 스테이지 학습 목표를 정한다
3. 스테이지 카드 한 장을 작성한다
4. 성 위치, 스폰 방향, 장애물 배치, 킬존 의도를 함께 리뷰한다
5. 구현 가능 상태로 승인한다
6. 승인된 스테이지 카드를 실제 런타임 데이터로 옮긴다

## 파일 안내

- [map-pillars.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/map-pillars.md): 이 프로젝트에서 맵이 재미있어지기 위한 핵심 기준
- [castle-and-spawn-rules.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/castle-and-spawn-rules.md): 성 위치와 전선 등장 패턴 규칙
- [obstacle-language.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/obstacle-language.md): 장애물이 어떤 플레이를 만들고 어떤 역할을 해야 하는지
- [stage-card-template.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-card-template.md): 스테이지 한 장을 설계할 때 쓰는 템플릿
- [act-1-map-bible.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/act-1-map-bible.md): Act 1의 첫 5개 수작업 맵 초안
- [siege-1-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/siege-1-working-card.md): 첫 번째 실제 작업 카드

## 현재 결정

지금 목표는 30개를 한 번에 잠그는 것이 아닙니다.

지금 목표는 아래입니다.

- 맵 설계 워크플로우를 고정한다
- `Act 1`을 손수 설계한다
- 실제 플레이 감각을 확인한다
- 그다음 같은 방식으로 다음 액트로 확장한다
