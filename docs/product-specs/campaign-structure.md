# Campaign Structure

캠페인은 `CampaignData.totalStages = 30`인 30 Stage 구조다. 플레이어-facing 용어는
`Stage`와 `Wave`만 사용한다. 코드에는 `AssaultCycleDefinition` 같은 과거 호환명이
남아 있지만 문서에서는 내부 구현명으로만 다룬다.

## Stage 진행

- Stage 1은 입문용 3 Wave다.
- Stage 2~30은 현재 4 Wave 구조다.
- 각 Stage는 성 좌표, 14x14 타일 그리드, 네 방향 경로, 장애물, Wave 그룹을 가진다.
- Stage 제목, 성 좌표, 시작 골드, 이벤트 여부는
  `docs/generated/current-game-data-snapshot.md`의 Stage Atlas 표를 기준으로 한다.

## 해금과 이어하기

- 저장소는 `currentCampaignStage`, Stage별 별, 클리어 여부, 메타 업그레이드를 저장한다.
- `hasResumableRun`은 `currentCampaignStage > 1`일 때 true다.
- Stage 1만 실패하거나 중단한 상태에서는 이어하기가 비활성이다.
- 현재 비공개 테스트 빌드에서는 `kUnlockAllCampaignStagesForDevelopment = true`라 모든
  Stage 선택이 열린다. 운영 배포 전에는 false로 바꾼다.

## Stage 이벤트 주사위

- 이벤트 주사위는 Stage 4부터 3 Stage 간격으로 열린다.
- 조건: `stageNumber >= 4 && (stageNumber - 4) % 3 == 0`
- 대상 Stage: 4, 7, 10, 13, 16, 19, 22, 25, 28
- 이벤트는 마지막 Wave에서 남은 적 수가 임계값 이하가 되면 보스 한 마리를 추가한다.
- 이벤트 풀과 수치는 `StageEventGenerator.poolForStage`가 관리한다.

## 이벤트 보스 밸런스

- Stage 이벤트 보스 HP는 계산값과 HP cap 중 낮은 값을 사용한다.
- Stage 16 이후 이벤트 보스 HP cap은 4500이다.
- 타락 기사(`corruptedKnight`)와 성채 군주(`bastionOverlord`)가 이벤트 보스로 등장하면
  물리 피해를 75% 받는다. 일반 개체는 기존 55% 물리 피해 수용을 유지한다.
- 타락 기사 이벤트 보스:
  - 성벽 피해 최대 75
  - 쇼크웨이브 약 31.5
  - 타워 접촉 피해 최대 85
- 성채 군주 이벤트 보스:
  - 성벽 피해 최대 95
  - 쇼크웨이브 약 39.9
  - 타워 접촉 피해 최대 110

## 포격 이벤트

- Stage 2부터 포격(`StageBombardmentDefinition`)이 생길 수 있다.
- 포격은 지정 Wave에서 한 번만 굴린다.
- 피해량은 Stage가 오를수록 증가하며, 현재 값은 스냅샷 Stage Atlas에 기록한다.
- 포격은 경고 후 외곽 방어선 3곳을 타격한다.

## Stage 구간 의도

| Stage | 테마 | 의도 |
| --- | --- | --- |
| 1~5 | frontierRoad | 성벽/타워/영웅 기본기와 첫 주사위 학습 |
| 6~10 | banditCrossroads | 우상단 성 위치와 빠른 적/중장 혼합 |
| 11~15 | graveFields | 상단 성 위치, 저주/언데드 압박 |
| 16~20 | cursedChapel | 좌하단 성 위치, 보스 난이도 검증 |
| 21~25 | bastionApproach | 사방 공세와 성채 계열 적 |
| 26~30 | throneMarch | 최종 사방 압박과 Stage 30 성채 군주 |
