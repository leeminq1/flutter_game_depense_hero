import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all campaign stages expose right-entry tile-grid path invariants', () {
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
        7,
        reason: 'Stage $stageNumber path should enter from the right edge.',
      );
      expect(
        pathSequence.last.first,
        0,
        reason: 'Stage $stageNumber path should exit at the left edge.',
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

      final pathCells = {
        for (final cell in pathSequence) '${cell[0]},${cell[1]}',
      };

      for (var index = 1; index < pathSequence.length; index += 1) {
        final previous = pathSequence[index - 1];
        final current = pathSequence[index];
        final dx = current[0] - previous[0];
        final dy = current[1] - previous[1];
        expect(
          dx <= 0,
          isTrue,
          reason: 'Stage $stageNumber path should not move back to the right.',
        );
        expect(
          dx.abs() + dy.abs(),
          1,
          reason:
              'Stage $stageNumber path should advance one orthogonal cell at a time.',
        );
      }

      for (var row = 0; row < tileGrid.length - 1; row += 1) {
        for (var col = 0; col < tileGrid[row].length - 1; col += 1) {
          final square = [
            tileGrid[row][col],
            tileGrid[row][col + 1],
            tileGrid[row + 1][col],
            tileGrid[row + 1][col + 1],
          ];
          expect(
            square.every((tile) => tile == TileType.path),
            isFalse,
            reason: 'Stage $stageNumber should not contain 2x2 path blocks.',
          );
        }
      }

      for (var index = 0; index < pathSequence.length; index += 1) {
        final cell = pathSequence[index];
        final neighbors = [
          (cell[0] + 1, cell[1]),
          (cell[0] - 1, cell[1]),
          (cell[0], cell[1] + 1),
          (cell[0], cell[1] - 1),
        ];
        for (final neighbor in neighbors) {
          final neighborKey = '${neighbor.$1},${neighbor.$2}';
          if (!pathCells.contains(neighborKey)) {
            continue;
          }
          final isPrevious =
              index > 0 &&
              pathSequence[index - 1][0] == neighbor.$1 &&
              pathSequence[index - 1][1] == neighbor.$2;
          final isNext =
              index < pathSequence.length - 1 &&
              pathSequence[index + 1][0] == neighbor.$1 &&
              pathSequence[index + 1][1] == neighbor.$2;
          expect(
            isPrevious || isNext,
            isTrue,
            reason:
                'Stage $stageNumber path should not side-touch non-consecutive cells.',
          );
        }
      }
    }
  });
}
