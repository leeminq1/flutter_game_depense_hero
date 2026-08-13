# Economy And Monetization

현재 구현은 전투 내 골드와 로컬 메타 성장 중심이다. 실제 결제 상품은 구현되어 있지
않고, 광고는 재시도 보상 흐름을 위한 서비스 구조만 가진다.

## 전투 골드

- 시작 골드: `CampaignData._startingCoinsForStage`에서 계산하고 0.765 밸런스 배율을 적용한다.
- 대표값:
  - Stage 1: 230
  - Stage 10: 375
  - Stage 16: 495
  - Stage 20: 585
  - Stage 25: 710
  - Stage 30: 850
- 처치 보상은 적 기본 보상, Stage 보상 배율, 강도, 0.90 밸런스 배율로 계산한다.
- Wave 회복 골드는 Stage/Wave 정의의 `recoveryGoldBonus`를 사용한다.
- 금화 방앗간(`coinMill`)은 WAVE 전투가 진행되는 동안에만 4.5초마다 기본 4골드를
  생산하고, `commerce_guild` 레벨만큼 수익이 추가된다. 준비·WAVE 사이 대기·일시정지
  중에는 남은 생산 시간이 동결되며, 기존 WAVE 시작 보너스는 별도로 유지된다.

## Meta Gold

- 코드명은 `softCurrency`지만 문서와 UI 맥락에서는 Meta Gold로 설명한다.
- 캠프 상단에는 표시하지 않는다.
- Stage 보상과 실패 보상으로 누적되고, 메타 업그레이드 구매에 쓴다.

## Siege Token

- `siegeTokens`는 클리어 보상으로 얻는 내구성 높은 성장 재화다.
- 현재 핵심 소비처는 제한적이며, 진행도 모델에 보관된다.
- 운영 밸런스가 확정되기 전까지 Meta Gold와 분리해 기록한다.

## 메타 업그레이드

최신 비용/효과 표는 `docs/generated/current-game-data-snapshot.md`의 Meta Upgrades 표를
기준으로 한다.

| ID | 핵심 효과 |
| --- | --- |
| `stronghold` | 기본 성 HP +2/레벨 |
| `supply_cache` | 시작 골드 +25/레벨 |
| `bow_mastery` | 궁수 피해 +12%/레벨, Lv2 발리스타 해금 |
| `guard_drill` | 병영 피해 +12%/레벨, 기사 보호 오라 강화 |
| `arcane_mastery` | 마법사 피해 +10%/레벨, Lv2 엠버킵 해금 |
| `frost_focus` | 감속 +6%/레벨, 빙결 사거리 +8%/레벨 |
| `commerce_guild` | 금화 방앗간 수익 +1/레벨, Stage 보상 +8%/레벨 |

## 수익화 상태

- Google Mobile Ads 의존성은 포함되어 있다.
- 현재 문서 기준으로 비공개 테스트는 밸런스/안정성 검증 목적이다.
- 실제 결제, 상품 가격, 유료 재화 패키지는 아직 source of truth가 없다.
