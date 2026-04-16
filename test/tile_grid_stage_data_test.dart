import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign stages expose tile-grid invariants for their current mode', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final tileGrid = stage.tileGrid;
      final pathSequence = stage.pathSequence;
      final authoredPaths = stage.pathsByDirection;

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
        pathSequence!,
        isNotEmpty,
        reason: 'Stage $stageNumber path should not be empty.',
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

      if (authoredPaths != null && authoredPaths.isNotEmpty) {
        expect(
          tileGrid.first.length,
          14,
          reason: 'Stage $stageNumber siege grids should use 14 tile columns.',
        );

        expect(
          tileGrid
              .expand((row) => row)
              .where((tile) => tile == TileType.citadel)
              .length,
          1,
          reason: 'Stage $stageNumber siege grids should use a 1x1 citadel.',
        );
        expect(stage.supplyNodeCells, isEmpty);
        expect(
          stage.obstacles,
          isNotEmpty,
          reason: 'Stage $stageNumber siege grids should define obstacles.',
        );

        for (final entry in authoredPaths.entries) {
          final direction = entry.key;
          final route = entry.value;
          expect(
            route,
            isNotEmpty,
            reason:
                'Stage $stageNumber route for $direction should not be empty.',
          );

          final start = route.first;
          final end = route.last;
          final startsOnEdge = switch (direction) {
            SpawnDirection.north => start[1] == 0,
            SpawnDirection.south => start[1] == 13,
            SpawnDirection.east => start[0] == 13,
            SpawnDirection.west => start[0] == 0,
          };
          expect(
            startsOnEdge,
            isTrue,
            reason:
                'Stage $stageNumber route for $direction should start on its matching edge.',
          );

          final endsAtCitadelRing = switch (direction) {
            SpawnDirection.north => end[0] == 6 && end[1] == 5,
            SpawnDirection.south => end[0] == 6 && end[1] == 7,
            SpawnDirection.east => end[0] == 7 && end[1] == 6,
            SpawnDirection.west => end[0] == 5 && end[1] == 6,
          };
          expect(
            endsAtCitadelRing,
            isTrue,
            reason:
                'Stage $stageNumber route for $direction should end on the citadel ring.',
          );

          for (var index = 1; index < route.length; index += 1) {
            final previous = route[index - 1];
            final current = route[index];
            final dx = (current[0] - previous[0]).abs();
            final dy = (current[1] - previous[1]).abs();
            expect(
              dx + dy,
              1,
              reason:
                  'Stage $stageNumber route for $direction should advance one orthogonal cell at a time.',
            );
          }
        }

        final obstacleCells = <String>{};
        for (final obstacle in stage.obstacles) {
          for (final cell in obstacle.occupiedCells) {
            final key = '${cell[0]},${cell[1]}';
            expect(
              obstacleCells.add(key),
              isTrue,
              reason:
                  'Stage $stageNumber should not overlap obstacle cells at $key.',
            );
            expect(
              tileGrid[cell[1]][cell[0]],
              TileType.blocked,
              reason:
                  'Stage $stageNumber obstacle cell $key should be blocked in tileGrid.',
            );
          }
        }
        continue;
      }

      expect(
        tileGrid.first.length,
        8,
        reason: 'Stage $stageNumber legacy grids should use 8 tile columns.',
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

  test('act 1 siege stages reduce obstacle density as stage number rises', () {
    final obstacleCounts = [
      for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1)
        CampaignData.stage(stageNumber).obstacles.length,
    ];

    expect(obstacleCounts, orderedEquals([12, 10, 8, 6, 4]));
  });
}
