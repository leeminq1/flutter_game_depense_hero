# Architecture

`Pixel Guard: Wave`는 Flutter UI와 Flame 전투 런타임을 함께 쓰는 Android 우선 2D 타워
디펜스다.

## Top-Level

- `lib/app/`: Flutter 화면, 라우팅, 부트스트랩, 광고 재시도 서비스.
- `lib/game/core/depense_game.dart`: Flame 기반 전투 시뮬레이션, 배치, 공격, 적 이동,
  Wave 상태, 보스 쇼크웨이브, UI 세션 동기화.
- `lib/game/models/`: 타워, 영웅, 성벽, 적, Stage, 설계 카드 데이터 타입.
- `lib/data/campaign/campaign_data.dart`: Stage 1~30의 단일 source of truth.
- `lib/data/meta/`: 메타 업그레이드 정의와 해석.
- `lib/data/persistence/`: Isar 기반 로컬 진행도 저장과 web/test용 in-memory 저장.
- `docs/generated/current-game-data-snapshot.md`: 코드에서 추출한 최신 수치 문서.

## Runtime Boundary

- 전투 중 임시 상태는 `DefensePrototypeGame` 안에 둔다.
- Flutter 오버레이는 `GameSessionController` 스냅샷만 읽고, 전투 계산을 직접 하지 않는다.
- 진행도, 오디오 설정, 메타 업그레이드는 `ProgressStore`를 통해 저장한다.
- Web 또는 테스트 환경은 네이티브 DB 대신 in-memory store를 사용할 수 있다.

## Data Contracts

- Stage: `StageDefinition`
- Wave: `WaveDefinition`
- 내부 Wave 호환명: `AssaultCycleDefinition`
- 적: `EnemyDefinition`, `EnemyKind`
- 타워: `TowerDefinition`, `TowerKind`
- 영웅: `HeroDefinition`, `HeroKind`
- 성벽: `BarrierDefinition`, `BarrierKind`
- 설계 카드: `RunOfferDefinition`, `RunModifier`
- 메타 성장: `MetaUpgradeDefinition`, `ResolvedMetaUpgrades`

## Performance Rules

- 모바일 60 FPS를 우선한다.
- 전투 오디오와 HUD 동기화는 과도한 프레임당 rebuild를 피한다.
- 적 경로는 Stage 데이터의 경로 좌표를 사용하고, 런타임에서 불필요한 전역 탐색을 피한다.
- 시각 효과는 전투 원인 구분이 가능해야 하며, 특히 보스 쇼크웨이브와 포격은 겹쳐도 읽혀야 한다.

## Build And Release

- 현재 비공개 테스트 버전: `1.0.20+21`
- Android 패키지: `com.min21.pixelguardwave`
- Play 업로드 산출물: `build/app/outputs/bundle/release/app-release.aab`
- 현재 테스트 빌드는 전체 Stage 해금 플래그를 켠다.
- 운영 배포 전에는 `kUnlockAllCampaignStagesForDevelopment`를 false로 돌린다.
