import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';

class TutorialStageDefinition {
  static const lessonWallCell = TutorialCell(7, 4);
  static const lessonTowerCell = TutorialCell(7, 4);
  static const practiceWallCell = TutorialCell(7, 4);
  static const practiceRoadTowerCell = TutorialCell(7, 5);
  static const practiceGrassTowerCell = TutorialCell(6, 5);

  static const guidedBuildCells = <TutorialCell>[
    lessonWallCell,
    lessonTowerCell,
    practiceRoadTowerCell,
    practiceGrassTowerCell,
  ];

  static const _routeId = 'tutorial_north_lane';
  static const _northPath = <List<int>>[
    [7, 0],
    [7, 1],
    [7, 2],
    [7, 3],
    [7, 4],
    [7, 5],
    [7, 6],
    [7, 7],
  ];

  static const demonstrationEnemy = EnemyDefinition(
    kind: EnemyKind.raider,
    label: '훈련 약탈자',
    specialDescription: '성벽과 타워의 차이를 보여주는 훈련용 적',
    hitPoints: 999,
    speed: 22,
    rewardCoins: 0,
    citadelDamage: 1,
    color: Color(0xFFB85C38),
    structureDamage: 1,
    towerContactDamage: 18,
    structureAttackCooldown: 1.4,
    wallBehavior: EnemyWallBehavior.forceBreaker,
  );

  static const finalPracticeEnemy = EnemyDefinition(
    kind: EnemyKind.raider,
    label: '훈련 약탈자',
    specialDescription: '기초 방어 실습용 적',
    hitPoints: 42,
    speed: 20,
    rewardCoins: 0,
    citadelDamage: 1,
    color: Color(0xFFB85C38),
    structureDamage: 2,
    towerContactDamage: 8,
    structureAttackCooldown: 1.5,
    wallBehavior: EnemyWallBehavior.forceBreaker,
  );

  static StageDefinition build() {
    final grid = List.generate(
      14,
      (_) => List<TileType>.filled(14, TileType.buildable),
    );
    grid[8][7] = TileType.citadel;

    return StageDefinition(
      number: 0,
      actNumber: 1,
      title: '기초 방어 훈련',
      description: '성벽으로 한 길을 막고 궁수 타워로 공격하는 기본 규칙을 연습합니다.',
      startingCoins: 0,
      baseHealth: 3,
      citadelHp: 3,
      citadelCell: const [7, 8],
      environmentTheme: StageEnvironmentTheme.frontierRoad,
      pathNodes: const [Offset(0.54, 0), Offset(0.54, 0.61)],
      buildSlots: const [],
      waves: const [
        WaveDefinition(
          number: 1,
          groups: [
            SpawnGroupDefinition(
              enemy: finalPracticeEnemy,
              count: 2,
              spawnInterval: 1.0,
              direction: SpawnDirection.north,
              routeId: _routeId,
            ),
          ],
        ),
      ],
      objectives: const [],
      buildZones: const [
        StageBuildZoneDefinition(region: Rect.fromLTWH(0, 0, 1080, 1920)),
      ],
      pathClearance: 0,
      buildGridSpacing: 0,
      decorations: const [],
      unlockRequirements: const [],
      tileGrid: grid,
      pathSequence: _northPath,
      pathsByDirection: const {SpawnDirection.north: _northPath},
      obstacles: const [],
      supplyNodeCells: const [],
      assaultCycles: const [],
      spawnRoutes: const [
        SpawnRouteDefinition(
          id: _routeId,
          direction: SpawnDirection.north,
          routeIndex: 0,
          entryCell: [7, 0],
        ),
      ],
      initialBarrierOptions: const [BarrierKind.woodFence],
      stageEvents: const [],
    );
  }
}
