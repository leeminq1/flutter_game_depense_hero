import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('training stage is isolated and exposes all four direction markers', () {
    final stage = TutorialStageDefinition.build();

    expect(stage.number, 0);
    expect(stage.title, '훈련장');
    expect(stage.tileGrid, hasLength(14));
    expect(stage.tileGrid!.every((row) => row.length == 14), isTrue);
    expect(stage.spawnRoutes.map((route) => route.direction).toSet(), {
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    });
    expect(stage.startingCoins, greaterThanOrEqualTo(200));
    expect(stage.waves, hasLength(1));
    expect(stage.assaultCycles, isEmpty);
  });

  test('building the tutorial does not mutate campaign stage one', () {
    final campaignStage = CampaignData.stage(1);
    final originalNumber = campaignStage.number;
    final originalWaveCount = campaignStage.cycleCount;

    TutorialStageDefinition.build();

    expect(campaignStage.number, originalNumber);
    expect(campaignStage.cycleCount, originalWaveCount);
  });
}
