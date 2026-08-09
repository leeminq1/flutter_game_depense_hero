import 'dart:io';

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
import 'package:depense_game/game/rendering/visual_catalog.dart';
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
      expect(stage.obstacles, isNotEmpty);
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

      for (final cell in stageCitadelBuildBlockedCells(stage.citadelCell)) {
        expect(
          buildSlotCells.contains(cell),
          isFalse,
          reason:
              'Stage $stageNumber build slot should not cover citadel $cell',
        );
        occupied.add(cell);
      }

      occupied.addAll(stageCitadelFootprintCells(stage.citadelCell));

      for (final obstacle in stage.obstacles) {
        for (final cell in obstacle.occupiedCells) {
          final occupiedCell = (cell[0], cell[1]);
          expect(
            occupied.add(occupiedCell),
            isTrue,
            reason: 'Stage $stageNumber obstacle footprint overlaps $cell',
          );
          expect(
            buildSlotCells.contains(occupiedCell),
            isFalse,
            reason:
                'Stage $stageNumber build slot should not cover obstacle $cell',
          );
        }
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

  test('promoted prop obstacles occupy only their snapped cell', () {
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      for (final obstacle in stage.obstacles) {
        if (obstacle.assetPath.contains('/landmarks/')) {
          continue;
        }

        expect(
          obstacle.occupiedCells.length,
          1,
          reason:
              'Stage $stageNumber prop obstacle ${obstacle.assetPath} should '
              'snap into one grid cell instead of sitting between cells.',
        );
      }
    }
  });

  test('citadel-adjacent spawn routes are filtered out', () {
    final stage7Routes = CampaignData.stage(
      7,
    ).assaultCycles.first.activeRouteIds;
    expect(stage7Routes, isNot(contains('south_3')));
    expect(stage7Routes, isNot(contains('east_3')));
    expect(stage7Routes, contains('south_1'));

    final stage13Routes = CampaignData.stage(
      13,
    ).assaultCycles.first.activeRouteIds;
    expect(stage13Routes, isNot(contains('east_1')));
    expect(stage13Routes, isNot(contains('north_3')));
    expect(stage13Routes, contains('east_3'));
  });

  test('archer and barracks runtime ranges include the playtest buff', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    game.onGameResize(Vector2(728, 728));

    expect(
      game.debugTowerBaseRangeFor(TowerKind.archer),
      closeTo(52 * 3.05, 0.001),
    );
    expect(
      game.debugTowerBaseRangeFor(TowerKind.frostShrine),
      closeTo(52 * 3.05, 0.001),
    );
    expect(
      game.debugTowerBaseRangeFor(TowerKind.emberkeep),
      closeTo(52 * 3.05, 0.001),
    );
    expect(
      game.debugTowerBaseRangeFor(TowerKind.ballista),
      closeTo(52 * 4.05, 0.001),
    );
    expect(
      game.debugTowerBaseRangeFor(TowerKind.guardBarracks),
      closeTo(52 * 2.55, 0.001),
    );
  });

  test('hero attack styles match ranged and melee class fantasy', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    expect(game.debugHeroAttackStyleFor(HeroKind.knight), 'melee_slash');
    expect(game.debugHeroAttackStyleFor(HeroKind.paladin), 'melee_slash');
    expect(
      game.debugHeroAttackStyleFor(HeroKind.archer),
      EffectVisualCatalog.arrowProjectile,
    );
    expect(game.debugHeroAttackStyleFor(HeroKind.mage), 'arcane_beam');
    expect(
      game.debugHeroAttackStyleFor(HeroKind.ninja),
      EffectVisualCatalog.shurikenProjectile,
    );
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

  test('stage 1 default hero spawn stays clear of the citadel artwork', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    game.onGameResize(Vector2(430, 560));

    expect(game.debugHeroSpawnCell(), (3, 12));
  });

  test('stage 1 grid remains centered when the battlefield height changes', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    game.onGameResize(Vector2(430, 560));
    final before = game.debugCitadelCenter();
    game.onGameResize(Vector2(430, 760));

    expect(game.debugCitadelCenter().x, before.x);
    expect(game.debugCitadelCenter().y - before.y, closeTo(100, 0.001));
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
        final entryCenter = Vector2(
          (route.entryCell[0] * 52) + 26,
          (route.entryCell[1] * 52) + 26,
        );
        final gateCenter = Vector2(
          (gateCell[0] * 52) + 26,
          (gateCell[1] * 52) + 26,
        );

        expect(
          path.first.distanceTo(entryCenter),
          lessThan(0.001),
          reason:
              'Stage $stageNumber route ${route.id} should spawn on its '
              'visible entry cell',
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

  test('stage 7 and 11 visible roads match their runtime spawn routes', () {
    for (final stageNumber in [7, 11]) {
      final stage = CampaignData.stage(stageNumber);
      final game = DefensePrototypeGame(
        stage: stage,
        sessionController: GameSessionController(),
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
      );

      game.onGameResize(Vector2(728, 728));

      for (var waveIndex = 0; waveIndex < stage.waves.length; waveIndex += 1) {
        final visibleRouteCells = {
          for (final path in game.debugRoadRouteCellsForWaveIndex(waveIndex))
            _cellPathKey(path),
        };
        final activeFronts = stage.assaultCycles[waveIndex].activeFronts;
        final activeRouteIds = stage.assaultCycles[waveIndex].activeRouteIds;
        final activeRoutes = stage.spawnRoutes.where(
          (route) =>
              activeFronts.contains(route.direction) &&
              activeRouteIds.contains(route.id),
        );

        for (final route in activeRoutes) {
          final routeCells = _routeFromEdgeToCitadelRing(
            route.entryCell,
            route.direction,
            stage.citadelCell!,
          );

          expect(
            visibleRouteCells,
            contains(_cellPathKey(routeCells)),
            reason:
                'Stage $stageNumber wave ${waveIndex + 1} should draw the '
                'same road cells used by route ${route.id}',
          );
        }
      }
    }
  });

  test('stage 10 prop blocking only removes the prop cell', () {
    final stage = CampaignData.stage(10);
    final buildSlotCells = {
      for (final slot in stage.buildSlots)
        ((slot.dx * 13).round(), (slot.dy * 13).round()),
    };
    final blockedCells = <(int, int)>{
      ...stageCitadelBuildBlockedCells(stage.citadelCell),
      for (final decoration in stage.decorations)
        ...stageDecorationFootprintCells(decoration),
    };

    for (final decoration in stage.decorations) {
      if (decoration.assetPath.contains('/landmarks/')) {
        continue;
      }
      final footprint = stageDecorationFootprintCells(decoration);

      expect(footprint.length, 1);
      expect(buildSlotCells, isNot(contains(footprint.single)));

      for (final neighbor in _orthogonalNeighbors(footprint.single)) {
        if (neighbor.$1 < 0 ||
            neighbor.$1 >= 14 ||
            neighbor.$2 < 0 ||
            neighbor.$2 >= 14 ||
            blockedCells.contains(neighbor) ||
            stage.tileGrid![neighbor.$2][neighbor.$1] != TileType.buildable) {
          continue;
        }

        expect(
          buildSlotCells,
          contains(neighbor),
          reason:
              '${decoration.assetPath} should not block adjacent build cell '
              '$neighbor',
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
    expect(CampaignData.stage(1).startingCoins, 230);
    expect(CampaignData.stage(5).startingCoins, 290);
    expect(CampaignData.stage(6).startingCoins, 315);
    expect(CampaignData.stage(10).startingCoins, 375);
    expect(CampaignData.stage(11).startingCoins, 400);
    expect(CampaignData.stage(15).startingCoins, 470);
    expect(CampaignData.stage(16).startingCoins, 495);
    expect(CampaignData.stage(20).startingCoins, 585);
    expect(CampaignData.stage(21).startingCoins, 610);
    expect(CampaignData.stage(25).startingCoins, 710);
    expect(CampaignData.stage(26).startingCoins, 740);
    expect(CampaignData.stage(30).startingCoins, 850);
  });

  test('stage bombardment uses higher early odds and late secondary rolls', () {
    expect(CampaignData.stage(1).bombardment, isNull);

    for (
      var stageNumber = 2;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final bombardment = stage.bombardment;

      expect(bombardment, isNotNull);
      expect(bombardment!.targetWaveNumber, anyOf(3, 4));
      expect(bombardment.targetWaveNumber, lessThanOrEqualTo(stage.cycleCount));
      expect(bombardment.rollChance, inInclusiveRange(0.50, 0.82));
      expect(bombardment.shellCount, 3);
      expect(bombardment.minImpactSpacingTiles, 1.25);
      expect(bombardment.projectileSeconds, 2.1);
      expect(bombardment.warningSeconds, 2.1);
      expect(bombardment.damage, greaterThanOrEqualTo(62));
      expect(bombardment.radiusTiles, 1.05);

      if (stageNumber < 15) {
        expect(bombardment.secondaryTargetWaveNumber, isNull);
        expect(bombardment.secondaryRollChance, isNull);
      } else {
        expect(bombardment.secondaryTargetWaveNumber, anyOf(3, 4));
        expect(
          bombardment.secondaryTargetWaveNumber,
          isNot(bombardment.targetWaveNumber),
        );
        expect(
          bombardment.secondaryTargetWaveNumber,
          lessThanOrEqualTo(stage.cycleCount),
        );
        expect(bombardment.secondaryRollChance, inInclusiveRange(0.28, 0.40));
      }
    }

    expect(CampaignData.stage(2).bombardment!.rollChance, closeTo(0.50, 0.001));
    expect(
      CampaignData.stage(15).bombardment!.rollChance,
      closeTo(0.63, 0.001),
    );
    expect(
      CampaignData.stage(15).bombardment!.secondaryRollChance,
      closeTo(0.28, 0.001),
    );
    expect(
      CampaignData.stage(30).bombardment!.rollChance,
      closeTo(0.82, 0.001),
    );
    expect(
      CampaignData.stage(30).bombardment!.secondaryRollChance,
      closeTo(0.40, 0.001),
    );
  });

  test('boss shockwave classification covers stage-event bosses', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(4),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    expect(game.debugEnemyKindUsesBossShockwave(EnemyKind.raider), isFalse);
    expect(
      game.debugEnemyKindUsesBossShockwave(EnemyKind.raider, stageEvent: true),
      isTrue,
    );
    expect(
      game.debugEnemyKindUsesBossShockwave(EnemyKind.bastionOverlord),
      isTrue,
    );
    expect(
      game.debugEnemyKindCanDamageTowersOnContact(EnemyKind.skeleton),
      isTrue,
    );
    expect(
      game.debugEnemyKindCanDamageTowersOnContact(EnemyKind.bastionOverlord),
      isTrue,
    );
    expect(
      game.debugEnemyKindCanDamageTowersOnContact(
        EnemyKind.bastionOverlord,
        hasActiveBreachTarget: true,
      ),
      isTrue,
    );
  });

  test('late tower cards are unlocked for playtest builds', () {
    const meta = ResolvedMetaUpgrades();

    expect(TowerCatalog.isUnlocked(TowerKind.ballista, meta), isTrue);
    expect(TowerCatalog.isUnlocked(TowerKind.emberkeep, meta), isTrue);
  });

  test('enemy pass-through contact damages every tower it crosses', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    game.debugAddTowerForContactTest(TowerKind.archer, Vector2(100, 100));
    game.debugAddTowerForContactTest(TowerKind.mageObelisk, Vector2(145, 100));
    game.debugAddTowerForContactTest(TowerKind.frostShrine, Vector2(260, 100));

    final before = game.debugTowerHitPoints();
    final totalDamage = game.debugApplyEnemyTowerContactDamageForTest(
      EnemyKind.raider,
      from: Vector2(60, 100),
      to: Vector2(185, 100),
    );
    final after = game.debugTowerHitPoints();

    expect(totalDamage, greaterThan(0));
    expect(after[0], lessThan(before[0]));
    expect(after[1], lessThan(before[1]));
    expect(after[2], before[2]);
  });

  test('enemy pass-through contact ignores adjacent off-road tower cells', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    game.debugAddTowerForContactTest(TowerKind.archer, Vector2(145, 160));

    final before = game.debugTowerHitPoints();
    final totalDamage = game.debugApplyEnemyTowerContactDamageForTest(
      EnemyKind.raider,
      from: Vector2(60, 100),
      to: Vector2(185, 100),
    );
    final after = game.debugTowerHitPoints();

    expect(totalDamage, 0);
    expect(after.single, before.single);
  });

  test('enemy pass-through contact still applies while breaching', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    game.debugAddTowerForContactTest(TowerKind.archer, Vector2(145, 100));

    final before = game.debugTowerHitPoints();
    final totalDamage = game.debugApplyEnemyTowerContactDamageForTest(
      EnemyKind.raider,
      from: Vector2(60, 100),
      to: Vector2(185, 100),
      hasActiveBreachTarget: true,
    );
    final after = game.debugTowerHitPoints();

    expect(totalDamage, greaterThan(0));
    expect(after.single, lessThan(before.single));
  });

  test('enemy leak frame applies tower contact damage before removal', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    final damage = game.debugApplyLeakFrameTowerContactForTest(
      EnemyKind.raider,
      towerKind: TowerKind.archer,
      towerPosition: game.debugCitadelCenter() + Vector2(44, 0),
    );

    expect(damage, greaterThan(0));
  });

  test('emberkeep launches a visible fire projectile before impact', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    final effectIds = game.debugFireTowerAtEnemyForTest(
      TowerKind.emberkeep,
      towerPosition: Vector2(100, 100),
      enemyPosition: Vector2(160, 100),
    );

    expect(effectIds, contains(EffectVisualCatalog.cannonballProjectile));
  });

  test('emberkeep applies visible burn state after impact', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    final burnTimers = game.debugFireTowerAtEnemyBurnTimersForTest(
      TowerKind.emberkeep,
      towerPosition: Vector2(100, 100),
      enemyPosition: Vector2(160, 100),
    );

    expect(burnTimers.single, greaterThan(3));
  });

  test('bosses deal two citadel hp on leak instead of one', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(4),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    expect(game.debugCitadelLeakDamageForEnemyKind(EnemyKind.raider), 1);
    expect(
      game.debugCitadelLeakDamageForEnemyKind(
        EnemyKind.raider,
        stageEvent: true,
      ),
      2,
    );
    expect(
      game.debugCitadelLeakDamageForEnemyKind(EnemyKind.bastionOverlord),
      2,
    );
  });

  test('late stage-event bosses use tuned hp damage and armor caps', () {
    final expectedHpByStage = {
      16: 2310,
      19: 2680,
      22: 3130,
      25: 3580,
      28: 4030,
    };

    for (final entry in expectedHpByStage.entries) {
      final stageNumber = entry.key;
      final game = DefensePrototypeGame(
        stage: CampaignData.stage(stageNumber),
        sessionController: GameSessionController(),
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
      );

      for (final event in StageEventGenerator.poolForStage(stageNumber)) {
        final boss = game.debugStageEventEnemyDefinition(event);

        expect(
          boss.hitPoints,
          entry.value,
          reason:
              'Stage $stageNumber ${event.id} HP should follow the staged '
              'event boss curve.',
        );

        if (boss.kind == EnemyKind.corruptedKnight) {
          expect(boss.baseStructureDamage, lessThanOrEqualTo(75));
          expect(boss.baseTowerContactDamage, lessThanOrEqualTo(85));
          expect(
            game.debugPhysicalDamageMultiplierForEnemyKind(
              boss.kind,
              stageEvent: true,
            ),
            1.0,
          );
        }

        if (boss.kind == EnemyKind.bastionOverlord) {
          expect(boss.citadelDamage, 15);
          expect(boss.baseStructureDamage, lessThanOrEqualTo(78));
          expect(boss.baseTowerContactDamage, lessThanOrEqualTo(88));
          expect(
            game.debugPhysicalDamageMultiplierForEnemyKind(
              boss.kind,
              stageEvent: true,
            ),
            1.0,
          );
        }
      }
    }

    final game = DefensePrototypeGame(
      stage: CampaignData.stage(16),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );

    expect(
      game.debugPhysicalDamageMultiplierForEnemyKind(EnemyKind.corruptedKnight),
      0.55,
    );
    expect(
      game.debugPhysicalDamageMultiplierForEnemyKind(EnemyKind.bastionOverlord),
      0.55,
    );

    for (final event in StageEventGenerator.poolForStage(4)) {
      expect(
        game.debugPhysicalDamageMultiplierForEnemyKind(
          event.enemyKind,
          stageEvent: true,
        ),
        1.0,
      );
    }
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
        expect(enemy.baseStructureDamage, 7);
        expect(enemy.baseTowerContactDamage, 8);
      } else if (heavy.contains(kind)) {
        expect(enemy.wallBehavior, EnemyWallBehavior.forceBreaker);
        expect(enemy.wallBreakChance, 1);
        final expectedStructureDamage = switch (kind) {
          EnemyKind.bastionOverlord => 35,
          EnemyKind.corruptedKnight || EnemyKind.graveGuard => 25,
          _ => 21,
        };
        final expectedTowerDamage = switch (kind) {
          EnemyKind.bastionOverlord => 63,
          EnemyKind.corruptedKnight || EnemyKind.graveGuard => 41,
          _ => 30,
        };
        expect(enemy.baseStructureDamage, expectedStructureDamage);
        expect(enemy.baseTowerContactDamage, expectedTowerDamage);
      } else {
        expect(enemy.wallBehavior, EnemyWallBehavior.mixedBreaker);
        expect(enemy.wallBreakChance, 0.7);
        expect(enemy.baseStructureDamage, 15);
        expect(enemy.baseTowerContactDamage, 16);
      }
    }
  });

  test('late normal enemies use tiered contact damage buffs', () {
    final skeleton = CampaignData.enemyForKind(
      EnemyKind.skeleton,
      stageNumber: 16,
      intensity: 1,
    );
    final boneArcher = CampaignData.enemyForKind(
      EnemyKind.boneArcher,
      stageNumber: 16,
      intensity: 1,
    );
    final graveGuard = CampaignData.enemyForKind(
      EnemyKind.graveGuard,
      stageNumber: 16,
      intensity: 1,
    );
    final corruptedKnight = CampaignData.enemyForKind(
      EnemyKind.corruptedKnight,
      stageNumber: 16,
      intensity: 1,
    );

    expect(skeleton.baseStructureDamage, 16);
    expect(skeleton.baseTowerContactDamage, 17);
    expect(boneArcher.baseStructureDamage, 7);
    expect(boneArcher.baseTowerContactDamage, 8);
    expect(graveGuard.baseStructureDamage, 27);
    expect(graveGuard.baseTowerContactDamage, 43);
    expect(corruptedKnight.baseStructureDamage, 27);
    expect(corruptedKnight.baseTowerContactDamage, 43);
  });

  test('enemy hp balance multipliers ease early stages then ramp smoothly', () {
    final expectations = {
      1: _expectedRaiderHp(stageNumber: 1, hpBalance: 0.50, hpPacing: 1.00),
      5: _expectedRaiderHp(stageNumber: 5, hpBalance: 0.50, hpPacing: 1.00),
      6: _expectedRaiderHp(stageNumber: 6, hpBalance: 0.62, hpPacing: 0.976),
      11: _expectedRaiderHp(stageNumber: 11, hpBalance: 0.72, hpPacing: 0.856),
      16: _expectedRaiderHp(stageNumber: 16, hpBalance: 0.82, hpPacing: 0.74),
      21: _expectedRaiderHp(stageNumber: 21, hpBalance: 0.92, hpPacing: 0.644),
      26: _expectedRaiderHp(stageNumber: 26, hpBalance: 1.00, hpPacing: 0.568),
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

  test('stage 1 walls use visible roads while towers keep grass cells', () {
    final dynamic game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(430, 620));

    final visibleRoadCells = <(int, int)>{
      for (final path
          in game.debugRoadRouteCellsForWaveIndex(0) as List<List<List<int>>>)
        for (final cell in path) (cell[0], cell[1]),
    };
    final barrierCells =
        game.debugBarrierBuildCellsForWaveIndex(0) as Set<(int, int)>;
    final towerCells = game.debugTowerBuildCells() as Set<(int, int)>;

    expect(barrierCells, isNotEmpty);
    expect(barrierCells.difference(visibleRoadCells), isEmpty);
    expect(towerCells.difference(visibleRoadCells), isNotEmpty);
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

  test('tower and hero range labels use compact grid coverage values', () {
    expect(TowerCatalog.byKind(TowerKind.guardBarracks).range, 3);
    expect(TowerCatalog.byKind(TowerKind.archer).range, 4);
    expect(TowerCatalog.byKind(TowerKind.frostShrine).range, 6);
    expect(TowerCatalog.byKind(TowerKind.ballista).range, 8);
    expect(TowerCatalog.byKind(TowerKind.emberkeep).range, 6);
    expect(TowerCatalog.byKind(TowerKind.mageObelisk).range, 6);
    expect(TowerCatalog.byKind(TowerKind.coinMill).range, 0);

    expect(HeroCatalog.byKind(HeroKind.knight).range, 2);
    expect(HeroCatalog.byKind(HeroKind.ninja).range, 2);
    expect(HeroCatalog.byKind(HeroKind.paladin).range, 2);
    expect(HeroCatalog.byKind(HeroKind.archer).range, 3);
    expect(HeroCatalog.byKind(HeroKind.mage).range, 5);
  });

  test('tower and hero selection range indicators match live behavior', () {
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
    );
    game.onGameResize(Vector2(728, 728));

    for (final kind in TowerKind.values) {
      for (final level in [1, 3]) {
        expect(
          game.debugTowerDisplayedRangeFor(kind, level: level),
          game.debugTowerCombatRangeFor(kind, level: level),
          reason: '${kind.name} level $level displayed tower range',
        );
      }
    }

    for (final kind in HeroKind.values) {
      for (final level in [1, 3]) {
        expect(
          game.debugHeroDisplayedRangeFor(kind, level: level),
          game.debugHeroEngagementRangeFor(kind, level: level),
          reason: '${kind.name} level $level displayed hero engagement range',
        );
      }
    }
  });

  test('ballista and emberkeep art paths load and level 4 reuses tier 3', () {
    final expectedPaths = <String>[
      'assets/sprites/towers/ballista.png',
      'assets/sprites/towers/ballista_t1.png',
      'assets/sprites/towers/ballista_t2.png',
      'assets/sprites/towers/ballista_t3.png',
      'assets/sprites/towers/ballista_siege_t2.png',
      'assets/sprites/towers/ballista_siege_t3.png',
      'assets/sprites/towers/ballista_harpoon_t2.png',
      'assets/sprites/towers/ballista_harpoon_t3.png',
      'assets/sprites/towers/emberkeep.png',
      'assets/sprites/towers/emberkeep_t1.png',
      'assets/sprites/towers/emberkeep_t2.png',
      'assets/sprites/towers/emberkeep_t3.png',
      'assets/sprites/towers/emberkeep_inferno_t2.png',
      'assets/sprites/towers/emberkeep_inferno_t3.png',
      'assets/sprites/towers/emberkeep_cinder_t2.png',
      'assets/sprites/towers/emberkeep_cinder_t3.png',
    ];

    for (final assetPath in expectedPaths) {
      expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
    }

    expect(
      TowerVisualCatalog.tierAssetPath(TowerKind.ballista, 4),
      'assets/sprites/towers/ballista_t3.png',
    );
    expect(
      TowerVisualCatalog.branchTierAssetPath(TowerKind.ballista, 4, 'siege'),
      'assets/sprites/towers/ballista_siege_t3.png',
    );
    expect(
      TowerVisualCatalog.tierAssetPath(TowerKind.emberkeep, 4),
      'assets/sprites/towers/emberkeep_t3.png',
    );
    expect(
      TowerVisualCatalog.branchTierAssetPath(TowerKind.emberkeep, 4, 'inferno'),
      'assets/sprites/towers/emberkeep_inferno_t3.png',
    );
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

int _expectedRaiderHp({
  required int stageNumber,
  required double hpBalance,
  required double hpPacing,
}) {
  final durabilityMultiplier = stageNumber <= 5
      ? 1.75
      : stageNumber <= 15
      ? 1.55
      : 1.40;
  final hpMultiplier =
      (1 + ((stageNumber - 1) * 0.18)) *
      durabilityMultiplier *
      hpBalance *
      hpPacing *
      1.10;
  return (57 * hpMultiplier).round();
}

String _cellPathKey(List<List<int>> cells) {
  return cells.map((cell) => '${cell[0]},${cell[1]}').join('|');
}

List<(int, int)> _orthogonalNeighbors((int, int) cell) {
  return [
    (cell.$1 - 1, cell.$2),
    (cell.$1 + 1, cell.$2),
    (cell.$1, cell.$2 - 1),
    (cell.$1, cell.$2 + 1),
  ];
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
