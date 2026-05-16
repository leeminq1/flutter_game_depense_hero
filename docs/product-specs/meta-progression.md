# Meta Progression

메타 진행은 전투마다 초기화되는 건물 구조를 보완하는 영구 성장축이다. 현재 구현의
source of truth는 `MetaUpgradeCatalog`와 `ProgressStore`다.

## 저장되는 값

- 계정 레벨과 XP
- Meta Gold(`softCurrency`)
- Siege Token(`siegeTokens`)
- Stage별 별/클리어/해금 상태
- 메타 업그레이드 레벨

## 업그레이드 목록

최신 비용과 효과는 `docs/generated/current-game-data-snapshot.md`의 Meta Upgrades 표를
사용한다.

| ID | 역할 |
| --- | --- |
| `stronghold` | 성 HP 증가 |
| `supply_cache` | 시작 골드 증가 |
| `bow_mastery` | 궁수 강화, Lv2 발리스타 해금 |
| `guard_drill` | 병영/기사/성기사 계열 강화 |
| `arcane_mastery` | 마법사 강화, Lv2 엠버킵 해금 |
| `frost_focus` | 빙결/닌자 계열 강화 |
| `commerce_guild` | 금화 방앗간과 Stage 보상 강화 |

## 현재 해금 정책

- 영웅은 전원 시작부터 선택 가능하다.
- 발리스타는 `bow_mastery >= 2`에서 열린다.
- 엠버킵은 `arcane_mastery >= 2`에서 열린다.
- 현재 비공개 테스트 빌드는 전체 Stage 해금 플래그를 켠다.

## 설계 의도

- 플레이어는 매 Stage 건물을 다시 짓지만, 메타 업그레이드로 기본 전투 여유가 늘어난다.
- Stage 10/20의 기본 레벨 보정과 메타 업그레이드가 함께 후반 피로를 낮춘다.
- 운영 배포 전에는 전체 Stage 해금 플래그를 끄고 정상 해금 흐름을 다시 검증한다.
