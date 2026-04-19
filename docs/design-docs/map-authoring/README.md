# 맵 설계 워크플로우

이 폴더는 `Pixel Guard: Wave`의 스테이지 맵을 사용자와 함께 손수 설계하기 위한 기준 문서 묶음이다.

앞으로 이 폴더에서는 실제 게임에서 쓰는 용어만 사용한다.

## 용어 기준

- `Stage`
  - 실제 맵이 바뀌는 전투 단위
  - Stage를 클리어하면 다음 Stage로 넘어가며 난이도가 상승한다
- `Cycle`
  - 한 Stage 내부에 들어 있는 웨이브 묶음
  - 현재 기준으로 한 Stage에는 보통 `3~4 Cycle`이 들어간다
- `맵 카드`
  - Stage 하나를 설계하고 잠그기 위한 한 장짜리 작업 문서

사용하지 않는 용어:

- `Act`
- `Siege`

## 현재 확정된 기준

- `Stage 1`은 현재 기준 맵으로 잠근다
- Stage 1은 `사방 압박 + 장애물 우회 + 중앙 성` 구조를 기준으로 한다
- 적은 각 변 내부에서 랜덤 위치로 스폰되지만, 전선 화살표는 방향 대표 위치에 고정한다
- 상단 도움말 배너는 HUD 바로 아래에 붙는 위치를 사용한다
- 상단 도움말 배너는 문장 길이에 따라 1줄 또는 2줄로 표시한다
- 건물 선택 액션 바는 3초 뒤 자동으로 사라진다
- 적 이동 방향과 보행 모션 방향은 반드시 일치해야 한다

## 왜 수작업 맵이 중요한가

이 게임은 단순히 적 체력과 공격력만 올리는 방식보다, `맵 구조가 플레이를 바꾸는 방식`이 훨씬 중요하다.

맵이 바뀌면 아래가 함께 바뀐다.

- 성 위치가 바뀌면 수비 우선순위가 바뀐다
- 스폰 방향과 순서가 바뀌면 플레이어 판단이 바뀐다
- 장애물 배치가 바뀌면 적의 우회 동선과 킬존이 바뀐다
- Stage가 달라지면 같은 타워 조합도 강한 자리와 약한 자리가 달라진다

즉, 이 게임은 `랜덤 장애물형 디펜스`보다 `읽을 수 있는 공성 퍼즐형 디펜스`에 더 가깝다.

## 문서 구성

- [map-pillars.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/map-pillars.md)
  - 좋은 맵이 가져야 할 설계 원칙
- [castle-and-spawn-rules.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/castle-and-spawn-rules.md)
  - 성 위치, 스폰 위치, 전선 화살표 기준
- [obstacle-language.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/obstacle-language.md)
  - 장애물이 어떤 플레이를 만들고 어떤 자리에 놓여야 하는지
- [stage-card-template.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-card-template.md)
  - Stage 하나를 설계할 때 복사해서 쓰는 템플릿
- [stage-1-5-map-bible.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-1-5-map-bible.md)
  - Stage 1~5의 큰 설계 흐름
- [stage-1-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-1-working-card.md)
  - 현재 확정 기준인 Stage 1 작업 카드
- [visual-guide.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/visual-guide.md)
  - Mermaid, ASCII, 좌표 설명용 시각 가이드

## 함께 작업하는 순서

1. Stage 목표를 먼저 정한다.
2. 성 위치와 스폰 방향을 정한다.
3. 장애물이 적을 어디로 우회시키는지 정한다.
4. 첫 킬존과 보조 킬존을 정한다.
5. Cycle별로 어떤 압박이 더 강해지는지 정한다.
6. 좌표와 ASCII로 잠근다.
7. 코드 데이터로 옮긴다.
8. 실제 플레이 후 문서를 다시 잠근다.

## 현재 진행 상태

- `Stage 1`: 구현 기준 확정
- `Stage 2`: 다음 작업 대상
- `Stage 3~5`: 방향만 정의, 세부 좌표 미확정
- `Stage 6 이후`: 성 위치 이동형 맵으로 확장 예정
