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
          reason:
              'Stage $stageNumber authored grids should use 14 tile columns.',
        );

        expect(
          tileGrid
              .expand((row) => row)
              .where((tile) => tile == TileType.citadel)
              .length,
          1,
          reason: 'Stage $stageNumber authored grids should use a 1x1 citadel.',
        );
        expect(stage.supplyNodeCells, isEmpty);
        expect(
          stage.obstacles,
          isNotEmpty,
          reason: 'Stage $stageNumber authored grids should define obstacles.',
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

          final citadelCell = stage.citadelCell ?? const [6, 6];
          final citadelCol = citadelCell[0];
          final citadelRow = citadelCell[1];
          final endsAtCitadelRing = switch (direction) {
            SpawnDirection.north =>
              end[0] == citadelCol && end[1] == citadelRow - 1,
            SpawnDirection.south =>
              end[0] == citadelCol && end[1] == citadelRow + 1,
            SpawnDirection.east =>
              end[0] == citadelCol + 1 && end[1] == citadelRow,
            SpawnDirection.west =>
              end[0] == citadelCol - 1 && end[1] == citadelRow,
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

  test('authored Stage 1-10 maps expose four-front assault cycles', () {
    const allFronts = {
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    };

    final expectedObstacleCounts = {
      1: 20,
      2: 19,
      3: 17,
      4: 14,
      5: 17,
      6: 18,
      7: 17,
      8: 17,
      9: 17,
      10: 17,
    };

    final expectedCycleCounts = {
      1: 3,
      2: 3,
      3: 4,
      4: 4,
      5: 4,
      6: 4,
      7: 4,
      8: 4,
      9: 4,
      10: 4,
    };

    for (var stageNumber = 1; stageNumber <= 10; stageNumber += 1) {
      final stage = CampaignData.stage(stageNumber);

      expect(
        stage.pathsByDirection?.keys.toSet(),
        allFronts,
        reason: 'Stage $stageNumber should keep the four-front map language.',
      );
      expect(
        stage.assaultCycles.length,
        expectedCycleCounts[stageNumber],
        reason: 'Stage $stageNumber should use the authored Cycle count.',
      );
      expect(
        stage.obstacles.length,
        expectedObstacleCounts[stageNumber],
        reason:
            'Stage $stageNumber should keep its authored obstacle count until rebalanced.',
      );

      for (final cycle in stage.assaultCycles) {
        expect(
          cycle.activeFronts.toSet(),
          allFronts,
          reason:
              'Stage $stageNumber Cycle ${cycle.number} should pressure all four fronts.',
        );
      }
    }
  });

  test('authored Stage 1-10 obstacles do not sit on monster routes', () {
    for (var stageNumber = 1; stageNumber <= 10; stageNumber += 1) {
      final stage = CampaignData.stage(stageNumber);
      final obstacleCells = {
        for (final obstacle in stage.obstacles)
          for (final cell in obstacle.occupiedCells) '${cell[0]},${cell[1]}',
      };
      final routeCells = {
        for (final route in stage.pathsByDirection!.values)
          for (final cell in route) '${cell[0]},${cell[1]}',
      };

      expect(
        obstacleCells.intersection(routeCells),
        isEmpty,
        reason:
            'Stage $stageNumber should keep authored obstacles off monster routes.',
      );
    }
  });

  test('authored Stage 1-10 obstacle counts are intentionally hand-tuned', () {
    final obstacleCounts = [
      for (var stageNumber = 1; stageNumber <= 10; stageNumber += 1)
        CampaignData.stage(stageNumber).obstacles.length,
    ];

    expect(
      obstacleCounts,
      orderedEquals([20, 19, 17, 14, 17, 18, 17, 17, 17, 17]),
    );
  });

  test('stage 6-10 move the citadel through the first quadrant arc', () {
    const expectedCells = {
      6: [7, 5],
      7: [8, 5],
      8: [8, 4],
      9: [9, 5],
      10: [9, 4],
    };

    for (final entry in expectedCells.entries) {
      final stage = CampaignData.stage(entry.key);

      expect(stage.citadelCell, orderedEquals(entry.value));
      expect(stage.tileGrid![entry.value[1]][entry.value[0]], TileType.citadel);
    }
  });

  test('stage 7 no longer uses the legacy fallback map', () {
    final stage = CampaignData.stage(7);

    expect(stage.tileGrid!.length, 14);
    expect(stage.tileGrid!.first.length, 14);
    expect(stage.pathsByDirection?.keys.toSet(), {
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    });
    expect(stage.assaultCycles, isNotEmpty);
  });

  test('stage 6 keeps the first shifted citadel position', () {
    final stage = CampaignData.stage(6);

    expect(stage.citadelCell, orderedEquals([7, 5]));
    expect(stage.tileGrid![5][7], TileType.citadel);
  });
}
