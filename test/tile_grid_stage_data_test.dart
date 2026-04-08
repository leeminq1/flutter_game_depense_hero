import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all sample stages expose centered tile-grid path data', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final tileGrid = stage.tileGrid;
      final pathSequence = stage.pathSequence;

      expect(
        tileGrid,
        isNotNull,
        reason: 'Stage $stageNumber should define tileGrid.',
      );
      expect(
        pathSequence,
        isNotNull,
        reason: 'Stage $stageNumber should define pathSequence.',
      );
      expect(
        tileGrid,
        isNotEmpty,
        reason: 'Stage $stageNumber grid should not be empty.',
      );
      expect(
        tileGrid!.length,
        14,
        reason: 'Stage $stageNumber should use 14 tile rows.',
      );
      expect(
        tileGrid.first.length,
        8,
        reason: 'Stage $stageNumber should use 8 tile columns.',
      );
      expect(
        pathSequence!,
        isNotEmpty,
        reason: 'Stage $stageNumber path should not be empty.',
      );
      expect(
        pathSequence.first.first,
        0,
        reason: 'Stage $stageNumber path should enter from the left edge.',
      );
      expect(
        pathSequence.last.first,
        7,
        reason: 'Stage $stageNumber path should exit at the right edge.',
      );

      final buildableCount = tileGrid
          .expand((row) => row)
          .where((tile) => tile == TileType.buildable)
          .length;
      expect(
        buildableCount,
        greaterThan(0),
        reason: 'Stage $stageNumber should retain playable build cells.',
      );
    }
  });
}
