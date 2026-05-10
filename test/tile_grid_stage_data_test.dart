import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(stage.decorations, isNotEmpty);
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

  test('early fortress stages expose three valid routes per front', () {
    for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1) {
      final stage = CampaignData.stage(stageNumber);
      final citadelCell = stage.citadelCell!;

      for (final direction in SpawnDirection.values) {
        final routes = stage.spawnRoutes
            .where((route) => route.direction == direction)
            .toList(growable: false);

        expect(routes.length, 3);
        for (final route in routes) {
          expect(route.id, '${direction.name}_${route.routeIndex + 1}');
          expect(_startsOnExpectedEdge(route.entryCell, direction), isTrue);

          final routeCells = _routeFromEdgeToCitadelRing(
            route.entryCell,
            direction,
            citadelCell,
          );
          expect(
            _touchesCitadelRing(routeCells.last, direction, citadelCell),
            isTrue,
          );
        }
      }

      for (final cycle in stage.assaultCycles) {
        for (final direction in cycle.activeFronts) {
          final activeRoutes = cycle.activeRouteIds.where(
            (routeId) => routeId.startsWith('${direction.name}_'),
          );
          expect(activeRoutes.length, 3);
        }
      }
    }
  });

  test('static object footprints do not overlap build slots', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final buildSlotCells = {
        for (final slot in stage.buildSlots)
          ((slot.dx * 13).round(), (slot.dy * 13).round()),
      };
      final occupied = <(int, int)>{};

      for (final cell in stageCitadelFootprintCells(stage.citadelCell)) {
        expect(
          buildSlotCells.contains(cell),
          isFalse,
          reason:
              'Stage $stageNumber build slot should not cover citadel $cell',
        );
        occupied.add(cell);
      }

      for (final decoration in stage.decorations) {
        final footprint = stageDecorationFootprintCells(decoration);
        for (final cell in footprint) {
          expect(
            occupied.add(cell),
            isTrue,
            reason: 'Stage $stageNumber decoration footprint overlaps $cell',
          );
          expect(
            buildSlotCells.contains(cell),
            isFalse,
            reason:
                'Stage $stageNumber build slot should not cover decoration $cell',
          );
        }
      }
    }
  });

  test('stage 1 citadel gate cells align with the visible leak threshold', () {
    final citadelCell = CampaignData.stage(1).citadelCell;

    expect(
      citadelGateCellForDirection(citadelCell, SpawnDirection.north),
      orderedEquals([1, 11]),
    );
    expect(
      citadelGateCellForDirection(citadelCell, SpawnDirection.south),
      orderedEquals([1, 13]),
    );
    expect(
      citadelGateCellForDirection(citadelCell, SpawnDirection.west),
      orderedEquals([0, 12]),
    );
    expect(
      citadelGateCellForDirection(citadelCell, SpawnDirection.east),
      orderedEquals([2, 12]),
    );
  });

  test('runtime spawn routes stop at gate cells', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final game = DefensePrototypeGame(
        stage: stage,
        sessionController: GameSessionController(),
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
      );

      game.onGameResize(Vector2(728, 728));

      for (final route in stage.spawnRoutes) {
        final path = game.debugSpawnPathForRoute(route);
        final gateCell = citadelGateCellForDirection(
          stage.citadelCell,
          route.direction,
        )!;
        final gateCenter = Vector2(
          (gateCell[0] * 52) + 26,
          (gateCell[1] * 52) + 26,
        );

        expect(
          path.last.distanceTo(gateCenter),
          lessThan(0.001),
          reason: 'Stage $stageNumber route ${route.id} should end at gate',
        );
        expect(
          path.last.distanceTo(game.debugCitadelCenter()),
          greaterThan(20),
          reason:
              'Stage $stageNumber route ${route.id} should not add '
              'a hidden segment into citadel',
        );
      }
    }
  });

  test('runtime barrier approach paths stay on assigned routes', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final game = DefensePrototypeGame(
        stage: stage,
        sessionController: GameSessionController(),
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
      );

      game.onGameResize(Vector2(728, 728));

      for (final route in stage.spawnRoutes) {
        final routeCells = _routeFromEdgeToCitadelRing(
          route.entryCell,
          route.direction,
          stage.citadelCell!,
        );
        final barrierCell = routeCells[routeCells.length ~/ 2];
        final approachPath = game.debugBarrierApproachPathForRoute(
          route,
          barrierCell,
        );
        final barrierCenter = Vector2(
          (barrierCell[0] * 52) + 26,
          (barrierCell[1] * 52) + 26,
        );

        expect(
          approachPath.last.distanceTo(barrierCenter),
          lessThan(0.001),
          reason:
              'Stage $stageNumber route ${route.id} should approach '
              'the barrier on its assigned route',
        );
        expect(
          approachPath.last.distanceTo(game.debugCitadelCenter()),
          greaterThan(20),
          reason:
              'Stage $stageNumber route ${route.id} should not approach '
              'a barrier through the citadel center',
        );
      }
    }
  });

  test('summoned skeletons inherit their summoner route', () {
    final stage = CampaignData.stage(3);
    final game = DefensePrototypeGame(
      stage: stage,
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    game.onGameResize(Vector2(728, 728));

    for (final route in stage.spawnRoutes) {
      final placement = game.debugSummonedEnemyPlacementForRoute(route);

      expect(placement.routeId, route.id);
      expect(
        placement.position.distanceTo(placement.expectedPosition),
        lessThan(0.001),
        reason:
            'Summoned skeleton on ${route.id} should stay on the summoner path',
      );
    }
  });

  test('citadel gate helper clamps to the battlefield edge', () {
    const cornerCitadel = [0, 0];

    expect(
      citadelGateCellForDirection(cornerCitadel, SpawnDirection.north),
      orderedEquals([0, 0]),
    );
    expect(
      citadelGateCellForDirection(cornerCitadel, SpawnDirection.west),
      orderedEquals([0, 0]),
    );
  });

  test('stage 3 decorations keep the corner citadel readable', () {
    final stage = CampaignData.stage(3);
    final citadelCell = stage.citadelCell!;
    final citadelCenter = (
      dx: (citadelCell[0] + 0.5) / 14,
      dy: (citadelCell[1] + 0.5) / 14,
    );

    for (final decoration in stage.decorations) {
      final dx = decoration.position.dx - citadelCenter.dx;
      final dy = decoration.position.dy - citadelCenter.dy;
      final minDistance = decoration.assetPath.contains('/landmarks/')
          ? 0.33
          : 0.23;

      expect(
        (dx * dx) + (dy * dy),
        greaterThanOrEqualTo(minDistance * minDistance),
        reason: '${decoration.assetPath} is too close to the Stage 3 citadel.',
      );
    }
  });

  test('stages follow the v2 citadel position arc', () {
    const expectedCells = {
      1: [1, 12],
      2: [1, 12],
      3: [1, 12],
      4: [1, 12],
      5: [1, 12],
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
    expect(CampaignData.stage(5).startingCoins, 380);
    expect(CampaignData.stage(6).startingCoins, 410);
    expect(CampaignData.stage(10).startingCoins, 490);
    expect(CampaignData.stage(11).startingCoins, 520);
    expect(CampaignData.stage(15).startingCoins, 616);
    expect(CampaignData.stage(16).startingCoins, 650);
    expect(CampaignData.stage(20).startingCoins, 762);
    expect(CampaignData.stage(21).startingCoins, 800);
    expect(CampaignData.stage(25).startingCoins, 928);
    expect(CampaignData.stage(26).startingCoins, 970);
    expect(CampaignData.stage(30).startingCoins, 1114);
  });

  test('barriers and heroes expose the v2 build metadata', () {
    expect(BarrierCatalog.byKind(BarrierKind.woodFence).cost, 5);
    expect(BarrierCatalog.byKind(BarrierKind.stoneWall).hitPoints, 220);
    expect(BarrierCatalog.byKind(BarrierKind.reinforcedWall).cost, 35);
    final fortressWall = BarrierCatalog.byKind(BarrierKind.fortressWall);
    expect(fortressWall.cost, 55);
    expect(fortressWall.hitPoints, 720);

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

  test('citadel health uses the three-leak rule', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);

      expect(stage.baseHealth, 3);
      expect(stage.citadelHitPoints, 3);
    }
  });

  test('enemy combat profiles expose wall and tower interaction rules', () {
    const fast = {
      EnemyKind.scout,
      EnemyKind.wolfScout,
      EnemyKind.boneArcher,
      EnemyKind.hexSniper,
    };
    const heavy = {
      EnemyKind.shieldInfantry,
      EnemyKind.graveGuard,
      EnemyKind.corruptedKnight,
      EnemyKind.bastionOverlord,
    };

    for (final kind in EnemyKind.values) {
      final enemy = CampaignData.enemyForKind(
        kind,
        stageNumber: 5,
        intensity: 1,
      );

      expect(enemy.citadelLeakDamage, 1);
      expect(enemy.baseStructureDamage, greaterThan(0));
      expect(enemy.baseTowerContactDamage, greaterThan(0));
      if (fast.contains(kind)) {
        expect(enemy.wallBehavior, EnemyWallBehavior.rerouteFirst);
        expect(enemy.wallBreakChance, 0);
        expect(enemy.baseStructureDamage, 5);
        expect(enemy.baseTowerContactDamage, 6);
      } else if (heavy.contains(kind)) {
        expect(enemy.wallBehavior, EnemyWallBehavior.forceBreaker);
        expect(enemy.wallBreakChance, 1);
        final expectedStructureDamage = switch (kind) {
          EnemyKind.bastionOverlord => 35,
          EnemyKind.corruptedKnight || EnemyKind.graveGuard => 25,
          _ => 20,
        };
        final expectedTowerDamage = switch (kind) {
          EnemyKind.bastionOverlord => 63,
          EnemyKind.corruptedKnight || EnemyKind.graveGuard => 41,
          _ => 29,
        };
        expect(enemy.baseStructureDamage, expectedStructureDamage);
        expect(enemy.baseTowerContactDamage, expectedTowerDamage);
      } else {
        expect(enemy.wallBehavior, EnemyWallBehavior.mixedBreaker);
        expect(enemy.wallBreakChance, 0.7);
        expect(enemy.baseStructureDamage, 14);
        expect(enemy.baseTowerContactDamage, 15);
      }
    }
  });

  test('enemy hp balance multipliers ease early stages then ramp smoothly', () {
    final expectations = {
      1: _expectedRaiderHp(stageNumber: 1, hpBalance: 0.50),
      5: _expectedRaiderHp(stageNumber: 5, hpBalance: 0.50),
      6: _expectedRaiderHp(stageNumber: 6, hpBalance: 0.62),
      11: _expectedRaiderHp(stageNumber: 11, hpBalance: 0.72),
      16: _expectedRaiderHp(stageNumber: 16, hpBalance: 0.82),
      21: _expectedRaiderHp(stageNumber: 21, hpBalance: 0.92),
      26: _expectedRaiderHp(stageNumber: 26, hpBalance: 1.00),
    };

    for (final entry in expectations.entries) {
      expect(
        CampaignData.enemyForKind(
          EnemyKind.raider,
          stageNumber: entry.key,
          intensity: 1,
        ).hitPoints,
        entry.value,
      );
    }
  });

  test('stage 1 budget supports the recommended learning build', () {
    final archer = TowerCatalog.byKind(TowerKind.archer).cost;
    final barracks = TowerCatalog.byKind(TowerKind.guardBarracks).cost;
    final fences = BarrierCatalog.byKind(BarrierKind.woodFence).cost * 4;
    final walls = BarrierCatalog.byKind(BarrierKind.stoneWall).cost * 2;

    expect(archer, 35);
    expect(barracks, 45);
    expect(archer + barracks + fences + walls, lessThanOrEqualTo(245));
    expect(
      CampaignData.stage(1).startingCoins,
      greaterThanOrEqualTo(archer + barracks + fences + walls),
    );
  });

  test('tower build costs use the development affordability pass', () {
    expect(TowerCatalog.byKind(TowerKind.archer).cost, 35);
    expect(TowerCatalog.byKind(TowerKind.guardBarracks).cost, 45);
    expect(TowerCatalog.byKind(TowerKind.mageObelisk).cost, 65);
    expect(TowerCatalog.byKind(TowerKind.frostShrine).cost, 55);
    expect(TowerCatalog.byKind(TowerKind.coinMill).cost, 65);
    expect(TowerCatalog.byKind(TowerKind.ballista).cost, 85);
    expect(TowerCatalog.byKind(TowerKind.emberkeep).cost, 80);
  });

  test('stage 1 to 5 teach fortress design before full randomness', () {
    expect(_frontPattern(CampaignData.stage(1)), [
      ['north'],
      ['north'],
      ['north'],
    ]);
    expect(_frontPattern(CampaignData.stage(2)), [
      ['north'],
      ['north', 'east'],
      ['north', 'east'],
      ['north', 'east'],
    ]);
    expect(_frontPattern(CampaignData.stage(3)), [
      ['north'],
      ['north', 'east'],
      ['north', 'east'],
      ['north', 'east'],
    ]);
    for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1) {
      for (final fronts in _frontPattern(CampaignData.stage(stageNumber))) {
        expect(fronts, isNot(contains('west')));
        expect(fronts, isNot(contains('south')));
      }
    }
  });

  test('stage 1 to 5 introduce the intended early enemy roles', () {
    expect(
      _enemyKinds(CampaignData.stage(1)),
      containsAll([
        EnemyKind.raider,
        EnemyKind.scout,
        EnemyKind.shieldInfantry,
      ]),
    );
    expect(
      _enemyKinds(CampaignData.stage(2)),
      containsAll([EnemyKind.wolfScout, EnemyKind.cultAdept]),
    );
    expect(
      _enemyKinds(CampaignData.stage(3)),
      containsAll([EnemyKind.skeleton, EnemyKind.boneArcher]),
    );
    expect(_enemyKinds(CampaignData.stage(4)), contains(EnemyKind.graveGuard));
    expect(
      _enemyKinds(CampaignData.stage(5)),
      containsAll([
        EnemyKind.raider,
        EnemyKind.scout,
        EnemyKind.wolfScout,
        EnemyKind.shieldInfantry,
        EnemyKind.skeleton,
        EnemyKind.boneArcher,
        EnemyKind.cultAdept,
        EnemyKind.graveGuard,
      ]),
    );
  });

  test('stage 7 to 10 add smoother midgame enemy roles', () {
    for (var stageNumber = 7; stageNumber <= 10; stageNumber += 1) {
      expect(
        _enemyKinds(CampaignData.stage(stageNumber)),
        containsAll([
          EnemyKind.raider,
          EnemyKind.wolfScout,
          EnemyKind.shieldInfantry,
          EnemyKind.cultAdept,
          EnemyKind.bannerCaptain,
        ]),
      );
    }
  });

  test('wave variants are previewable and seed deterministic', () {
    final stage = CampaignData.stage(4);
    final variants = stage.assaultCycles.expand((cycle) => cycle.variants);

    expect(variants, isNotEmpty);
    expect(
      variants.expand((variant) => variant.threatTags),
      containsAll(['빠른 압박', '성벽 파괴']),
    );
    expect(
      WaveVariantSelector.indexFor(
        seed: 1514,
        stageNumber: 4,
        waveIndex: 0,
        cycleNumber: 1,
        variantCount: 2,
      ),
      WaveVariantSelector.indexFor(
        seed: 1514,
        stageNumber: 4,
        waveIndex: 0,
        cycleNumber: 1,
        variantCount: 2,
      ),
    );
  });
}

List<List<String>> _frontPattern(StageDefinition stage) {
  return [
    for (final cycle in stage.assaultCycles)
      [for (final front in cycle.activeFronts) front.name],
  ];
}

Set<EnemyKind> _enemyKinds(StageDefinition stage) {
  return {
    for (final cycle in stage.assaultCycles)
      for (final group in cycle.groups) group.enemy.kind,
    for (final cycle in stage.assaultCycles)
      for (final variant in cycle.variants)
        for (final group in variant.groups) group.enemy.kind,
  };
}

int _expectedRaiderHp({required int stageNumber, required double hpBalance}) {
  final durabilityMultiplier = stageNumber <= 5
      ? 1.75
      : stageNumber <= 15
      ? 1.55
      : 1.40;
  final hpMultiplier =
      (1 + ((stageNumber - 1) * 0.18)) * durabilityMultiplier * hpBalance;
  return (57 * hpMultiplier).round();
}

bool _startsOnExpectedEdge(List<int> cell, SpawnDirection direction) {
  return switch (direction) {
    SpawnDirection.north => cell[1] == 0,
    SpawnDirection.south => cell[1] == 13,
    SpawnDirection.east => cell[0] == 13,
    SpawnDirection.west => cell[0] == 0,
  };
}

bool _touchesCitadelRing(
  List<int> cell,
  SpawnDirection direction,
  List<int> citadelCell,
) {
  final citadelCol = citadelCell[0];
  final citadelRow = citadelCell[1];
  return switch (direction) {
    SpawnDirection.north => cell[0] == citadelCol && cell[1] == citadelRow - 1,
    SpawnDirection.south => cell[0] == citadelCol && cell[1] == citadelRow + 1,
    SpawnDirection.east => cell[0] == citadelCol + 1 && cell[1] == citadelRow,
    SpawnDirection.west => cell[0] == citadelCol - 1 && cell[1] == citadelRow,
  };
}

List<List<int>> _routeFromEdgeToCitadelRing(
  List<int> entry,
  SpawnDirection direction,
  List<int> citadelCell,
) {
  final goal = switch (direction) {
    SpawnDirection.north => [citadelCell[0], citadelCell[1] - 1],
    SpawnDirection.south => [citadelCell[0], citadelCell[1] + 1],
    SpawnDirection.west => [citadelCell[0] - 1, citadelCell[1]],
    SpawnDirection.east => [citadelCell[0] + 1, citadelCell[1]],
  };
  final routeCells = <List<int>>[];
  var col = entry[0];
  var row = entry[1];
  routeCells.add([col, row]);

  void addStep(int nextCol, int nextRow) {
    col = nextCol;
    row = nextRow;
    routeCells.add([col, row]);
  }

  if (direction == SpawnDirection.north || direction == SpawnDirection.south) {
    while (row != goal[1]) {
      addStep(col, row + (row < goal[1] ? 1 : -1));
    }
    while (col != goal[0]) {
      addStep(col + (col < goal[0] ? 1 : -1), row);
    }
  } else {
    while (col != goal[0]) {
      addStep(col + (col < goal[0] ? 1 : -1), row);
    }
    while (row != goal[1]) {
      addStep(col, row + (row < goal[1] ? 1 : -1));
    }
  }

  return routeCells;
}
