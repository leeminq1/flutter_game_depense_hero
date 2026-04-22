# 맵 설계 워크플로우

이 폴더는 `Pixel Guard: Wave`의 Stage 맵을 사용자와 함께 손수 설계하기 위한 기준 문서 묶음이다.

앞으로 이 폴더에서는 실제 게임에서 쓰는 용어만 사용한다.

## 용어 기준

- `Stage`: 실제 맵이 바뀌는 전투 단위
- `Cycle`: 한 Stage 내부에 들어 있는 웨이브 묶음
- `맵 카드`: Stage 하나를 설계하고 잠그기 위한 작업 문서

사용하지 않는 용어:

- `Act`
- `Siege`

## 현재 확정된 기준

- `Stage 1`은 구현 기준 확정 상태다
- `Stage 2~5`는 코드 적용 초안 상태이며, 실제 플레이 검증 후 확정한다
- Stage 1~5는 모두 중앙 성 기준의 사방 압박을 유지한다
- Stage 6부터는 성 위치를 중앙에서 벗어나게 만드는 두 번째 구간으로 검토한다
- 적은 각 변 내부에서 랜덤 위치로 스폰되지만, 전선 화살표는 방향 대표 위치에 고정한다
- 상단 도움말 배너는 HUD 바로 아래에 붙는 위치를 사용한다
- 상단 도움말 배너는 문장 길이에 따라 1줄 또는 2줄로 표시한다
- 건물 선택 액션 바는 3초 뒤 자동으로 사라진다
- 적 이동 방향과 보행 모션 방향은 반드시 일치해야 한다

## Stage별 진행 상태

| Stage | 상태 | 핵심 설계 |
| --- | --- | --- |
| Stage 1 | 구현 기준 확정 | 사방 압박 입문, 장애물 우회 이해 |
| Stage 2 | 코드 적용 초안, 플레이 검증 대기 | 방향별 압박 강약 차이, 동쪽 짧은 압박 |
| Stage 3 | 코드 적용 초안, 플레이 검증 대기 | 첫 중장 체크, 동쪽 방패 보병 압박 |
| Stage 4 | 코드 적용 초안, 플레이 검증 대기 | 성 근처 최종 방어 압박 |
| Stage 5 | 코드 적용 초안, 플레이 검증 대기 | 초반 규칙 종합 시험 |
| Stage 6 | 코드 적용 초안, 플레이 검증 대기 | 오른쪽 위 성 첫 변형 |
| Stage 7~10 | 코드 적용 초안, 플레이 검증 대기 | 1사분면 성 위치 심화 구간 |
| Stage 11 | 코드 적용 초안, 플레이 검증 대기 | 왼쪽 위 성 첫 변형 |
| Stage 12~15 | 코드 적용 초안, 플레이 검증 대기 | 2사분면 성 위치와 오른쪽 넓은 킬존 |
| Stage 16~20 | 구간 계획 | 3사분면 성 위치와 방어선 유지 |
| Stage 21~25 | 구간 계획 | 4사분면 성 위치와 후반 업그레이드 압박 |
| Stage 26~30 | 구간 계획 | 혼합 위치와 최종 시험 |

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
- [campaign-position-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/campaign-position-plan.md)
  - 30 Stage 전체 성 위치 진행과 사분면 구간 계획
- [obstacle-language.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/obstacle-language.md)
  - 장애물이 어떤 플레이를 만들고 어떤 자리에 놓여야 하는지
- [stage-card-template.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-card-template.md)
  - Stage 하나를 설계할 때 복사해서 쓰는 템플릿
- [stage-1-5-map-bible.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-1-5-map-bible.md)
  - Stage 1~5의 큰 설계 흐름
- [stage-1-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-1-working-card.md)
  - 구현 기준으로 확정한 Stage 1 작업 카드
- [stage-2-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-2-working-card.md)
  - Stage 2 구현 초안과 검증 기준
- [stage-3-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-3-working-card.md)
  - Stage 3 구현 초안과 첫 중장 체크 기준
- [stage-4-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-4-working-card.md)
  - Stage 4 구현 초안과 성 근처 압박 기준
- [stage-5-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-5-working-card.md)
  - Stage 5 구현 초안과 초반 종합 시험 기준
- [stage-6-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-6-working-card.md)
  - Stage 6 구현 초안과 오른쪽 위 성 첫 변형 기준
- [stage-6-10-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-6-10-plan.md)
  - Stage 6~10 성 위치 변경 구간 컨셉 계획
- [stage-11-15-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-11-15-plan.md)
  - Stage 11~15 왼쪽 위 성 위치 구간 계획
- [stage-11-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-11-working-card.md)
  - Stage 11 구현 초안과 왼쪽 위 성 첫 변형 기준
- [stage-12-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-12-working-card.md)
  - Stage 12 구현 초안과 북쪽 성문 압박 기준
- [stage-13-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-13-working-card.md)
  - Stage 13 구현 초안과 북서 동시 압박 기준
- [stage-14-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-14-working-card.md)
  - Stage 14 구현 초안과 서쪽 긴급 방어 기준
- [stage-15-working-card.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-15-working-card.md)
  - Stage 15 구현 초안과 좌상단 미니 보스형 기준
- [stage-16-20-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-16-20-plan.md)
  - Stage 16~20 왼쪽 아래 성 위치 구간 계획
- [stage-21-25-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-21-25-plan.md)
  - Stage 21~25 오른쪽 아래 성 위치 구간 계획
- [stage-26-30-plan.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-26-30-plan.md)
  - Stage 26~30 혼합 위치와 최종 시험 구간 계획
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

## 다음 작업

1. Stage 1~10을 실제 기기에서 플레이 검증한다.
2. 성 위치, 장애물, 스폰 화살표, 경로가 문서와 일치하는지 확인한다.
3. Stage 11 작업 카드를 만들고 2사분면 구간을 시작한다.
4. Stage 11~15를 하나씩 코드에 옮긴 뒤 실제 플레이 결과를 문서에 다시 반영한다.
