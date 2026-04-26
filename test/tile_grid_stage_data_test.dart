import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign stages use the fortress-builder battlefield contract', () {
    const allFronts = {
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    };

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final tileGrid = stage.tileGrid!;

      expect(tileGrid.length, 14);
      expect(tileGrid.first.length, 14);
      expect(stage.pathsByDirection?.keys.toSet(), allFronts);
      expect(stage.spawnRoutes.length, 12);
      expect(stage.obstacles, isEmpty);
      expect(stage.supplyNodeCells, isEmpty);
      expect(
        tileGrid
            .expand((row) => row)
            .where((tile) => tile == TileType.citadel)
            .length,
        1,
      );
      expect(
        tileGrid
            .expand((row) => row)
            .where((tile) => tile == TileType.buildable)
            .length,
        greaterThan(150),
      );

      for (final direction in SpawnDirection.values) {
        final routes = stage.spawnRoutes.where(
          (route) => route.direction == direction,
        );
        expect(routes.length, 3);
      }
    }
  });

  test('stages follow the v2 citadel position arc', () {
    const expectedCells = {
      1: [1, 12],
      2: [2, 12],
      3: [2, 11],
      4: [3, 10],
      5: [4, 9],
      6: [12, 12],
      7: [11, 12],
      8: [11, 11],
      9: [10, 10],
      10: [9, 9],
      11: [12, 1],
      12: [12, 2],
      13: [11, 2],
      14: [10, 3],
      15: [9, 4],
      16: [1, 1],
      17: [2, 1],
      18: [2, 2],
      19: [3, 3],
      20: [4, 4],
      21: [6, 6],
      22: [7, 6],
      23: [6, 7],
      24: [7, 7],
      25: [6, 6],
      26: [6, 6],
      27: [7, 6],
      28: [6, 7],
      29: [7, 7],
      30: [6, 6],
    };

    for (final entry in expectedCells.entries) {
      final stage = CampaignData.stage(entry.key);
      final cell = entry.value;
      expect(stage.citadelCell, orderedEquals(cell));
      expect(stage.tileGrid![cell[1]][cell[0]], TileType.citadel);
    }
  });

  test('starting gold reflects the wall-building economy brackets', () {
    expect(CampaignData.stage(1).startingCoins, 300);
    expect(CampaignData.stage(6).startingCoins, 330);
    expect(CampaignData.stage(11).startingCoins, 360);
    expect(CampaignData.stage(16).startingCoins, 390);
    expect(CampaignData.stage(21).startingCoins, 420);
    expect(CampaignData.stage(26).startingCoins, 450);
  });

  test('barriers and heroes expose the v2 build metadata', () {
    expect(BarrierCatalog.byKind(BarrierKind.woodFence).cost, 15);
    expect(BarrierCatalog.byKind(BarrierKind.stoneWall).hitPoints, 220);
    expect(BarrierCatalog.byKind(BarrierKind.reinforcedWall).repairCost, 45);
    expect(BarrierCatalog.byKind(BarrierKind.gate).hitPoints, 180);

    for (final hero in HeroCatalog.buildMenu) {
      expect(hero.isUnlockedForStage(1), isTrue);
      expect(hero.abilityLabel, isNotEmpty);
      expect(hero.abilityDescription, isNotEmpty);
      expect(hero.roleTags, isNotEmpty);
    }
  });

  test('coin mill still exposes economy values for ROI UI', () {
    final coinMill = TowerCatalog.byKind(TowerKind.coinMill);

    expect(coinMill.economyIncome, 4);
    expect(coinMill.economyInterval, 4.5);
  });

  test('stage 1 budget supports the recommended learning build', () {
    final archer = TowerCatalog.byKind(TowerKind.archer).cost;
    final barracks = TowerCatalog.byKind(TowerKind.guardBarracks).cost;
    final fences = BarrierCatalog.byKind(BarrierKind.woodFence).cost * 4;
    final walls = BarrierCatalog.byKind(BarrierKind.stoneWall).cost * 2;

    expect(archer, 50);
    expect(barracks, 65);
    expect(archer + barracks + fences + walls, lessThanOrEqualTo(245));
    expect(
      CampaignData.stage(1).startingCoins,
      greaterThanOrEqualTo(archer + barracks + fences + walls),
    );
  });
}
