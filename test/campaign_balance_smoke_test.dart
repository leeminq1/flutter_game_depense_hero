import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign economy stays inside broad playable smoke bounds', () {
    final averageTowerCost =
        TowerCatalog.buildMenu
            .where((tower) => tower.cost > 0)
            .map((tower) => tower.cost)
            .reduce((a, b) => a + b) /
        TowerCatalog.buildMenu.where((tower) => tower.cost > 0).length;

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final expectedKillReward = stage.waves
          .expand((wave) => wave.groups)
          .fold<int>(
            0,
            (sum, group) => sum + (group.enemy.rewardCoins * group.count),
          );
      final recoveryReward = stage.assaultCycles.fold<int>(
        0,
        (sum, cycle) => sum + cycle.recoveryGoldBonus,
      );
      final startingBuildCount = stage.startingCoins / averageTowerCost;

      expect(
        startingBuildCount,
        greaterThanOrEqualTo(3),
        reason: 'Stage $stageNumber should allow an initial fortress plan.',
      );
      expect(
        startingBuildCount,
        lessThanOrEqualTo(19),
        reason: 'Stage $stageNumber should not start with runaway gold.',
      );
      expect(
        expectedKillReward,
        lessThanOrEqualTo(stage.startingCoins * 5),
        reason: 'Stage $stageNumber kill rewards look outsized.',
      );
      expect(
        recoveryReward,
        lessThanOrEqualTo(stage.startingCoins * 2),
        reason: 'Stage $stageNumber recovery rewards look outsized.',
      );
    }
  });
}
