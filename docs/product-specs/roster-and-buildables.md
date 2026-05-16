# Roster And Buildables

이 문서는 현재 코드 기준 전투 로스터를 설명한다. 긴 수치표는
`docs/generated/current-game-data-snapshot.md`에서 자동 생성한다.

## 타워

| 타워 | 코드 | 비용 | 사거리 | 피해 | 쿨다운 | 역할 |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 궁수 | `archer` | 35 | 4 | 14 | 0.85 | 저렴한 단일 물리 화력 |
| 병영 | `guardBarracks` | 45 | 3 | 18 | 1.15 | 전선 유지와 근접 제어 |
| 마법사 | `mageObelisk` | 65 | 6 | 25 | 1.25 | 방어 관통 마법 화력 |
| 빙결 | `frostShrine` | 55 | 6 | 7 | 1.05 | 감속과 구역 제어 |
| 금화 방앗간 | `coinMill` | 65 | 0 | 0 | 0 | 전투 중 골드 생산 |
| 발리스타 | `ballista` | 85 | 4 | 50 | 1.95 | 장거리 대형 적 대응 |
| 엠버킵 | `emberkeep` | 80 | 4 | 17 | 1.30 | 지속 폭발/화상 |

- 빙결 타워의 카탈로그 사거리는 마법사와 동일하게 6이다.
- 런타임 기본 사거리도 마법사와 같은 계수로 계산한다.
- 발리스타는 `bow_mastery >= 2`, 엠버킵은 `arcane_mastery >= 2`에서 해금된다.

## 성벽

| 성벽 | 코드 | 비용 | 기본 HP | 수리 비용 |
| --- | --- | ---: | ---: | ---: |
| 나무 울타리 | `woodFence` | 5 | 80 | 3 |
| 돌 성벽 | `stoneWall` | 15 | 220 | 9 |
| 강화 성벽 | `reinforcedWall` | 35 | 420 | 21 |
| 요새 성벽 | `fortressWall` | 55 | 720 | 33 |

- Stage 10~19에서는 성벽 HP에 1.35배 보정이 들어간다.
- Stage 20~30에서는 성벽 HP에 1.75배 보정이 들어간다.
- `버티는 성벽망` 주사위는 모든 성벽 HP에 추가 1.20배를 곱한다.

## 영웅

모든 영웅은 시작부터 선택 가능하다. `unlockStage` 값은 과거 호환 데이터로 남아 있지만
현재 해금 조건으로 쓰지 않는다.

| 영웅 | 코드 | 비용 | 사거리 | 피해 | 쿨다운 | 능력 |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 기사 | `knight` | 120 | 2 | 24 | 0.95 | 주변 타워 피해 감소 |
| 궁사 | `archer` | 145 | 3 | 18 | 0.72 | 표식으로 받는 피해 증가 |
| 마법사 | `mage` | 175 | 5 | 34 | 1.18 | 세 번째 공격 광역 마법 |
| 닌자 | `ninja` | 165 | 2 | 21 | 0.48 | 저체력 적 처형 |
| 성기사 | `paladin` | 210 | 2 | 42 | 1.32 | 주변 손상 타워 회복 |

## 기본 레벨과 업그레이드

- Stage 1~9: 새 타워/영웅 Lv1
- Stage 10~19: 새 타워/영웅 Lv2
- Stage 20~30: 새 타워/영웅 Lv3
- 최대 레벨: Lv4
- 주사위의 첫 타워 +1레벨 효과는 위 기본 레벨에 더한다.

## 적과 보스

- 모든 적은 `EnemyKind`로 정의된다.
- 물리 저항:
  - `shieldInfantry`, 일반 `corruptedKnight`, 일반 `bastionOverlord`: 물리 피해 55% 수용
  - 이벤트 보스 `corruptedKnight`, 이벤트 보스 `bastionOverlord`: 물리 피해 75% 수용
  - 나머지 적: 물리 피해 100% 수용
- 이벤트 보스는 성벽 공격 후 쇼크웨이브를 만든다.
- 쇼크웨이브 피해는 성벽 직접 피해의 42%다.
- Stage 16 이후 이벤트 보스 HP cap은 4500이다.

대표 수치는 `docs/generated/current-game-data-snapshot.md`의 Enemy Representative Stats와
Stage Event Boss Dice 표를 기준으로 한다.

## 설계 카드 주사위

- Stage 4부터 3 Stage 간격으로 등장한다.
- 매번 3장을 제시하고 1장을 고른다.
- 현재 카드 풀:
  - `archer_wall_line`: 궁수 사거리 +15%
  - `hero_guard_anchor_{hero}`: 선택 영웅 피해 +15%
  - `mage_first_level`: 첫 마법사 탑 +1레벨
  - `wall_hp_network`: 모든 성벽 HP +20%
  - `barracks_fortress_hold`: 병영 피해 +15%
  - `frost_chokepoint`: 빙결 공격 주기 0.88배
