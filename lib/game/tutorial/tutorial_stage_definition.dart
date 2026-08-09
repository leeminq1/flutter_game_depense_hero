import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';

class TutorialStageDefinition {
  static StageDefinition build() {
    final source = CampaignData.stage(1);
    final northRoute = source.spawnRoutes.firstWhere(
      (route) => route.direction == SpawnDirection.north,
      orElse: () => source.spawnRoutes.first,
    );
    final trainingEnemy = source.waves.first.groups.first.enemy;

    return StageDefinition(
      number: 0,
      actNumber: 1,
      title: '훈련장',
      description: '성벽과 타워의 역할, 출현 방향, 카메라 조작을 직접 연습합니다.',
      startingCoins: 230,
      baseHealth: source.baseHealth,
      citadelHp: source.citadelHp,
      citadelCell: source.citadelCell,
      environmentTheme: source.environmentTheme,
      pathNodes: source.pathNodes,
      buildSlots: source.buildSlots,
      waves: [
        WaveDefinition(
          number: 1,
          groups: [
            SpawnGroupDefinition(
              enemy: trainingEnemy,
              count: 4,
              spawnInterval: 0.7,
              direction: SpawnDirection.north,
              routeId: northRoute.id,
            ),
          ],
        ),
      ],
      objectives: const [],
      buildZones: source.buildZones,
      pathClearance: source.pathClearance,
      buildGridSpacing: source.buildGridSpacing,
      decorations: source.decorations,
      unlockRequirements: const [],
      slotTapRadius: source.slotTapRadius,
      tileGrid: source.tileGrid,
      pathSequence: source.pathSequence,
      pathsByDirection: source.pathsByDirection,
      obstacles: source.obstacles,
      supplyNodeCells: source.supplyNodeCells,
      assaultCycles: const [],
      spawnRoutes: source.spawnRoutes,
      initialBarrierOptions: source.initialBarrierOptions,
      stageEvents: const [],
    );
  }
}
