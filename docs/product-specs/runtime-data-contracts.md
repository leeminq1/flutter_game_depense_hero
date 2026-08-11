# Runtime Data Contracts

현재 런타임 데이터는 Flutter/Flame UI와 전투 시뮬레이션 사이를 연결한다. 이름이 과거
프로토타입에서 온 타입도 있지만, player-facing 문서와 UI는 `Stage`와 `Wave`를 쓴다.

## CampaignData

- `CampaignData.totalStages = 30`
- `CampaignData.stage(number)`는 안전하게 1~30으로 clamp한다.
- 반환 타입은 `StageDefinition`이다.
- Stage는 성 좌표, 타일 그리드, 경로, 장애물, Wave, 이벤트, 포격을 포함한다.

## StageDefinition 핵심 필드

| 필드 | 의미 |
| --- | --- |
| `number` | Stage 번호 |
| `title`, `description` | UI 표시 텍스트 |
| `startingCoins` / `startingGold` | 시작 골드 |
| `baseHealth` / `citadelHitPoints` | 성 하트/체력 |
| `environmentTheme` | 배경/장식 테마 |
| `tileGrid` | 14x14 `TileType` 그리드 |
| `citadelCell` | 성 중심 좌표 `[col,row]` |
| `pathsByDirection` | 북/동/남/서 경로 좌표 |
| `obstacles` | 보이는 장애물이자 배치/경로 차단물 |
| `waves` | 실제 전투 Wave |
| `assaultCycles` | 내부 호환명. 현재 Wave 데이터와 연결됨 |
| `stageEvents` | 주사위 보스 이벤트 풀 |
| `bombardment` | 포격 이벤트 정의 |

## TileType

| 값 | 의미 |
| --- | --- |
| `path` | 적 이동 경로 |
| `buildable` | 타워/성벽 배치 가능 |
| `blocked` | 배치/이동 불가 |
| `supplyNode` | 과거 보급 노드 호환값 |
| `citadel` | 성 위치 |

## Wave와 Spawn

- `WaveDefinition`은 Wave 번호와 적 그룹을 가진다.
- `SpawnGroupDefinition`과 `FrontSpawnGroupDefinition`은 적 종류, 수량, 스폰 간격, 방향을 가진다.
- `SpawnDirection`은 `north`, `south`, `east`, `west` 네 방향이다.
- Stage 1~30은 각 방향마다 최대 3개 entry route를 가진다.

## StageEventDefinition

- `id`, `title`, `message`, `enemyKind`가 UI와 스폰을 결정한다.
- `hitPointMultiplier`, `damageMultiplier`, `visualScale`은 이벤트 보스 강화값이다.
- 이벤트 트리거는 현재 `remainingEnemies` 하나다.
- 최종 이벤트 보스 수치는 `DefensePrototypeGame._stageEventEnemyDefinition`에서 추가 보정한다.

## Progress Store

- 네이티브/Android는 로컬 persistence store를 사용한다.
- Web 또는 테스트 경로는 in-memory store를 사용할 수 있다.
- 저장 모델은 Stage 진행도, 메타 업그레이드, 오디오 설정, 재화, 이어하기 가능 여부를 보관한다.
- 프로덕션 빌드는 `kUnlockAllCampaignStagesForDevelopment = false`로 Stage 진행 조건을 적용한다.
