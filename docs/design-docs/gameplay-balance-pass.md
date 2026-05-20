# Gameplay Balance Pass

이 문서는 현재 코드 기준 밸런스 의도를 설명한다. 정확한 표는
`docs/generated/current-game-data-snapshot.md`를 다시 생성해 확인한다.

## 현재 목표

- Stage마다 건물은 초기화되지만, Stage가 오르면 기본 건설 레벨이 올라가 후반 피로도를 줄인다.
- 몬스터 HP는 Stage에 따라 오르되, Stage 10 이후 플레이어 기본 레벨과 성벽 HP도 함께 오른다.
- 보스는 위협적이어야 하지만 성벽/타워를 순식간에 지우면 안 된다.
- Stage 16 이후 이벤트 보스는 HP cap 4500과 피해 캡으로 조정한다.

## 플레이어 성장

| Stage | 새 타워/영웅 기본 레벨 | 성벽 HP 보정 |
| --- | ---: | ---: |
| 1~9 | Lv1 | 1.00x |
| 10~19 | Lv2 | 1.35x |
| 20~30 | Lv3 | 1.75x |

- 최대 전투 레벨은 Lv4다.
- `첫 마법사 탑 +1레벨`은 기본 레벨에 더해지며 Lv4를 넘지 않는다.

## 보스 피해 구분

- 성벽 피해: 보스가 성벽을 직접 때릴 때 들어가는 피해.
- 쇼크웨이브: 성벽 피해 직후 주변 성벽/타워에 추가로 들어가는 범위 피해. 현재 직접 피해의 42%.
- 타워 접촉 피해: 이동 중 가까운 타워를 별도로 때리는 피해.
- 성 도달 피해: 적이 성까지 샜을 때 하트가 깎이는 피해. 보스는 최소 2.

## 이벤트 보스 현재 기준

| 구간 | HP cap | 특수 조정 |
| --- | ---: | --- |
| Stage 4~12 | 4500 | 초반 이벤트 보스용 기본 cap |
| Stage 13~15 | 5200 | 중반 타락 기사 구간 |
| Stage 16~30 | 4500 | 최근 플레이테스트 기준으로 재조정 |

- 이벤트 타락 기사: 물리 피해 75% 수용, 성벽 75, 쇼크웨이브 31.5, 타워 접촉 85.
- 이벤트 성채 군주: 물리 피해 75% 수용, 성벽 95, 쇼크웨이브 39.9, 타워 접촉 110.
- 일반 타락 기사/성채 군주는 기존 물리 피해 55% 수용을 유지한다.

## 경제 밸런스

- 시작 골드는 Stage 1의 230에서 Stage 30의 850까지 오른다.
- 처치 보상은 Stage 보상 계수와 0.90 밸런스 계수를 함께 적용한다.
- 회복 골드는 Wave 사이에 추가 방어선 설계를 유도한다.
- 금화 방앗간은 장기 Wave에서 가치가 있지만, 공격 능력은 없다.

## 다음 밸런스 점검 포인트

- Stage 16, 19 이벤트 보스가 HP 4500에서 적절히 잡히는지.
- Stage 22 이후 성채 군주가 타워 접촉 110으로도 과하게 방어선을 지우지 않는지.
- Stage 20 이후 기본 Lv3 + 성벽 1.75x가 후반을 너무 쉽게 만들지 않는지.
- 빙결 사거리 6이 마법사와 같은 영역을 차지해도 타워 선택이 단조롭지 않은지.
# 2026-05-20 Wave Pressure Rebalance Note

- Normal Stage waves now use a generated pressure index: HP budget 60%, wall
  damage 25%, tower contact damage 15%, with old Stage 1 Wave 1 as 100.
- Each Stage normalizes Wave 1 to about 90% of its former pressure and the
  final Wave to 130%; middle Waves are linearly interpolated.
- Enemy counts, spawn timing, kill rewards, recovery gold, citadel leak damage,
  and Stage Event boss stats are intentionally unchanged.
- The generated snapshot includes `Wave Pressure Index` so future balance passes
  can compare Stage-to-Stage pressure without re-running an ad hoc script.
