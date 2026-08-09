import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('training stage is a central-citadel single-lane sandbox', () {
    final stage = TutorialStageDefinition.build();

    expect(stage.number, 0);
    expect(stage.title, '기초 방어 훈련');
    expect(stage.tileGrid, hasLength(14));
    expect(stage.tileGrid!.every((row) => row.length == 14), isTrue);
    expect(stage.citadelCell, [7, 8]);
    expect(stage.spawnRoutes, hasLength(1));
    expect(stage.spawnRoutes.single.direction, SpawnDirection.north);
    expect(stage.pathsByDirection!.keys, {SpawnDirection.north});
    expect(stage.decorations, isEmpty);
    expect(stage.obstacles, isEmpty);
    expect(stage.supplyNodeCells, isEmpty);
    expect(stage.startingCoins, 0);
    expect(stage.waves, hasLength(1));
    expect(stage.waves.single.groups.single.count, 2);
    expect(stage.assaultCycles, isEmpty);
  });

  test(
    'every guided placement cell is buildable and road targets are authored',
    () {
      final stage = TutorialStageDefinition.build();
      final grid = stage.tileGrid!;

      for (final cell in TutorialStageDefinition.guidedBuildCells) {
        expect(grid[cell.row][cell.col], TileType.buildable);
      }
      final road = stage.pathsByDirection![SpawnDirection.north]!;
      final roadCells = road.map((cell) => (cell[0], cell[1])).toSet();
      expect(
        roadCells,
        contains((
          TutorialStageDefinition.lessonWallCell.col,
          TutorialStageDefinition.lessonWallCell.row,
        )),
      );
      expect(
        roadCells,
        contains((
          TutorialStageDefinition.practiceRoadTowerCell.col,
          TutorialStageDefinition.practiceRoadTowerCell.row,
        )),
      );
      expect(
        roadCells,
        isNot(
          contains((
            TutorialStageDefinition.practiceGrassTowerCell.col,
            TutorialStageDefinition.practiceGrassTowerCell.row,
          )),
        ),
      );
    },
  );

  test('building the tutorial does not mutate campaign stage one', () {
    final campaignStage = CampaignData.stage(1);
    final originalNumber = campaignStage.number;
    final originalWaveCount = campaignStage.cycleCount;

    TutorialStageDefinition.build();

    expect(campaignStage.number, originalNumber);
    expect(campaignStage.cycleCount, originalWaveCount);
  });
}
