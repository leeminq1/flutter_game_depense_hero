# 게임성 개선 통합 패스

## 목적

이번 패스는 초반 이탈을 줄이면서도 Stage 1부터 긴장감을 주기 위한 1차 게임성 개선이다. 기준은 “실수하면 성 체력이 깎이지만, 올바르게 배치하면 안정적으로 클리어 가능”이다.

## 확정 변경

- 시작 골드는 Stage 1~5를 `150, 155, 160, 165, 170`으로 낮추고, Stage 6부터는 `170 + (Stage - 5) * 2`로 완만하게 상승시킨다.
- 적 체력 스케일은 Stage당 `15%`에서 `18%`로 올린다.
- Stage 1은 입문용 3 Cycle을 유지하고, Stage 2부터 4 Cycle 구조로 전환한다.
- Stage 1~30은 모두 `citadelCell`, `pathsByDirection`, `obstacles`, `assaultCycles`를 가진 authored 맵으로 다룬다.
- 몬스터의 타워 공격은 더 체감되도록 기본 피해와 공격 주기를 강화한다.
- 코인밀은 카드/선택 UI에서 초당 수익과 예상 회수 시간을 보여준다.

## 히어로 역할

| 히어로 | 고유 능력 | 메타 연동 |
| --- | --- | --- |
| 기사 | 주변 타워 피해 감소 | `Guard Drill` |
| 궁사 | 표식으로 받는 피해 증가 | `Bow Mastery` |
| 마법사 | 세 번째 공격마다 주변 광역 피해 | `Arcane Mastery` |
| 닌자 | 낮은 체력 적 추가 피해 | `Frost Focus` |
| 성기사 | 주변 손상 타워 주기적 회복 | `Guard Drill` |

## 적 가족 시너지

- 산적 계열은 배너 캡틴 주변에서 더 오래 지속되는 이동/성 피해 버프를 받는다.
- 언데드 계열은 역병사 주변에서 더 넓은 회복/피해 감소 지원을 받는다.
- 수치는 낮게 시작하고, 실제 플레이에서 지원 유닛을 먼저 잡아야 한다는 느낌이 생기는지 확인한다.

## 검증 기준

- Stage 1은 처음부터 사방 압박이 보이되, 기본 타워 2개와 올바른 추가 배치로 클리어 가능해야 한다.
- Stage 6과 Stage 11에서 시작 골드가 갑자기 튀지 않아야 한다.
- Stage 16~30이 fallback 맵으로 돌아가지 않아야 한다.
- 몬스터가 타워를 파괴하는 장면이 실전에서 가끔 발생해야 한다.
- 코인밀은 플레이어가 손익분기 시간을 UI에서 이해할 수 있어야 한다.

# 2026-05-10 UI and Difficulty Follow-up

- Build cards now stay active after a successful tower or wall placement, so players can place multiple copies without reselecting the card. The mode ends when the same card is tapped again or when `WAVE` starts.
- Selecting an existing tower or hero should show a translucent range circle using that unit's current runtime range. Non-combat economy buildings with `range == 0` do not draw a range circle.
- Stage 1-5 enemy HP is reduced to 50% of the previous curve, and enemy contact damage against walls, towers, and heroes is reduced to 70%. Citadel leak damage remains fixed at 1.
- Stage 6-30 now use a smoother HP/contact-damage ramp: HP balance `0.62 / 0.72 / 0.82 / 0.92 / 1.00` by five-stage band, contact damage `0.78 / 0.84 / 0.90 / 0.95 / 1.00`.
- Starting Gold and recovery Gold now rise gradually by stage/act so later stages can ask for more planning without forcing early-stage grind.
- A follow-up readability pass changed range rings to yellow, reduced selected-unit action panels to a compact upper-right overlay, and tightened combat ranges to grid-sized coverage: barracks/melee heroes about `2x2`, archer/frost/ballista/emberkeep/ranged heroes about `3x3`, and mage about `5x5`.
