import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/road_tile_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoadTileResolver', () {
    test('resolves straight, turn, cap, and fill variants', () {
      Set<String> cells(List<(int, int)> values) => {
        for (final cell in values) RoadTileResolver.key(cell.$1, cell.$2),
      };

      expect(
        RoadTileResolver.resolve(
          col: 1,
          row: 1,
          roadCells: cells([(1, 0), (1, 1), (1, 2)]),
        ),
        RoadTileKind.straightVertical,
      );
      expect(
        RoadTileResolver.resolve(
          col: 1,
          row: 1,
          roadCells: cells([(0, 1), (1, 1), (2, 1)]),
        ),
        RoadTileKind.straightHorizontal,
      );
      expect(
        RoadTileResolver.resolve(
          col: 1,
          row: 1,
          roadCells: cells([(1, 0), (1, 1), (2, 1)]),
        ),
        RoadTileKind.turnNE,
      );
      expect(
        RoadTileResolver.resolve(
          col: 1,
          row: 1,
          roadCells: cells([(1, 1), (1, 2)]),
        ),
        RoadTileKind.capToSouth,
      );
      expect(
        RoadTileResolver.resolve(
          col: 1,
          row: 1,
          roadCells: cells([(1, 0), (1, 1), (1, 2), (2, 1)]),
        ),
        RoadTileKind.fill,
      );
    });

    test('stage 1 authored roads resolve to connected tile variants', () {
      final stage = CampaignData.stage(1);
      final cells = <String>{};
      for (final route in stage.spawnRoutes) {
        for (final cell in _routeFromEdgeToCitadelRing(
          route.entryCell,
          route.direction,
          stage.citadelCell!,
        )) {
          cells.add(RoadTileResolver.key(cell[0], cell[1]));
        }
      }

      final kinds = <RoadTileKind>{};
      for (final key in cells) {
        final parts = key.split(':');
        kinds.add(
          RoadTileResolver.resolve(
            col: int.parse(parts[0]),
            row: int.parse(parts[1]),
            roadCells: cells,
          ),
        );
      }

      expect(kinds, contains(RoadTileKind.straightVertical));
      expect(kinds, contains(RoadTileKind.straightHorizontal));
      expect(kinds.difference({RoadTileKind.fill}), isNotEmpty);
    });
  });

  group('BarrierCatalog', () {
    test('uses lowered early fortress planning costs', () {
      expect(BarrierCatalog.byKind(BarrierKind.woodFence).cost, 5);
      expect(BarrierCatalog.byKind(BarrierKind.stoneWall).cost, 15);
      expect(BarrierCatalog.byKind(BarrierKind.reinforcedWall).cost, 35);
      final fortressWall = BarrierCatalog.byKind(BarrierKind.fortressWall);
      expect(fortressWall.cost, 55);
      expect(fortressWall.hitPoints, 720);
      expect(fortressWall.label, '요새 성벽');
    });
  });

  group('Run offers', () {
    test('generator returns three deterministic available offers', () {
      final offers = RunOfferGenerator.generate(
        seed: 1234,
        stageNumber: 1,
        offerIndex: 0,
        unlockedTowers: const {
          TowerKind.archer,
          TowerKind.guardBarracks,
          TowerKind.mageObelisk,
          TowerKind.frostShrine,
          TowerKind.coinMill,
        },
        chosenHeroKind: HeroKind.knight,
      );
      final repeated = RunOfferGenerator.generate(
        seed: 1234,
        stageNumber: 1,
        offerIndex: 0,
        unlockedTowers: const {
          TowerKind.archer,
          TowerKind.guardBarracks,
          TowerKind.mageObelisk,
          TowerKind.frostShrine,
          TowerKind.coinMill,
        },
        chosenHeroKind: HeroKind.knight,
      );

      expect(offers, hasLength(3));
      expect(
        offers.map((offer) => offer.id),
        repeated.map((offer) => offer.id),
      );
      expect(offers.map((offer) => offer.effectLine), everyElement(isNotEmpty));
      expect(
        offers
            .expand((offer) => offer.modifiers)
            .map((modifier) => modifier.towerKind),
        isNot(contains(TowerKind.ballista)),
      );
      expect(
        offers
            .expand((offer) => offer.modifiers)
            .map((modifier) => modifier.type),
        isNot(contains(RunModifierType.disableHeroRevive)),
      );
      expect(
        offers
            .expand((offer) => offer.modifiers)
            .map((modifier) => modifier.type),
        isNot(contains(RunModifierType.barrierRepairCostMultiplier)),
      );
    });

    test(
      'controller rolls, accepts one offer, and resets offers on hydrate',
      () {
        final controller = GameSessionController();
        const offer = RunOfferDefinition(
          id: 'test_archer',
          title: 'Test Archer',
          description: 'Archer range +15%.',
          effectLine: 'Archer range +15%',
          operationLine: 'Archer wall line',
          rarity: RunOfferRarity.common,
          modifiers: [
            RunModifier(
              type: RunModifierType.towerRangeMultiplier,
              towerKind: TowerKind.archer,
              multiplier: 1.15,
            ),
          ],
        );

        controller.prepareRunOfferRoll();
        expect(controller.mustResolveRunOffer, isTrue);
        expect(controller.runOfferFlowState, RunOfferFlowState.awaitingRoll);

        controller.setRunOfferRolling();
        expect(controller.runOfferFlowState, RunOfferFlowState.rolling);

        controller.setPendingRunOffers(const [offer]);
        expect(controller.hasPendingRunOffer, isTrue);
        expect(controller.runOfferFlowState, RunOfferFlowState.awaitingChoice);

        controller.acceptRunOffer(offer);

        expect(controller.pendingRunOffers, isEmpty);
        expect(controller.activeRunOffers, contains(offer));
        expect(controller.mustResolveRunOffer, isFalse);
        expect(controller.runOfferFlowState, RunOfferFlowState.applied);
        expect(
          controller.runModifiers.towerRangeMultiplier(TowerKind.archer),
          1.15,
        );

        controller.hydrate(
          stageNumber: 1,
          totalStages: 30,
          stageTitle: 'Stage 1',
          totalWaves: 3,
          coins: 200,
          baseHealth: 24,
        );

        expect(controller.pendingRunOffers, isEmpty);
        expect(controller.activeRunOffers, isEmpty);
        expect(controller.mustResolveRunOffer, isFalse);
        expect(
          controller.runModifiers.towerRangeMultiplier(TowerKind.archer),
          1,
        );
      },
    );

    test('generator only returns positive numeric first-playable effects', () {
      const unlockedTowers = {
        TowerKind.archer,
        TowerKind.guardBarracks,
        TowerKind.mageObelisk,
        TowerKind.frostShrine,
        TowerKind.coinMill,
        TowerKind.ballista,
        TowerKind.emberkeep,
      };
      const forbiddenTypes = {
        RunModifierType.disableHeroRevive,
        RunModifierType.barrierRepairCostMultiplier,
      };

      for (var seed = 1; seed <= 12; seed += 1) {
        final offers = RunOfferGenerator.generate(
          seed: seed,
          stageNumber: 1,
          offerIndex: 0,
          unlockedTowers: unlockedTowers,
          chosenHeroKind: HeroKind.knight,
        );

        expect(offers, hasLength(3));
        expect(
          offers.map((offer) => offer.effectLine),
          everyElement(isNotEmpty),
        );
        expect(
          offers.map((offer) => offer.operationLine),
          everyElement(isNotEmpty),
        );
        expect(
          offers
              .expand((offer) => offer.modifiers)
              .map((modifier) => modifier.type),
          isNot(anyElement(isIn(forbiddenTypes))),
        );
      }
    });

    test('generator uses the first design-card pool', () {
      const unlockedTowers = {
        TowerKind.archer,
        TowerKind.guardBarracks,
        TowerKind.mageObelisk,
        TowerKind.frostShrine,
        TowerKind.coinMill,
        TowerKind.ballista,
        TowerKind.emberkeep,
      };
      const designCardIds = {
        'archer_wall_line',
        'hero_guard_anchor_knight',
        'mage_first_level',
        'wall_hp_network',
        'barracks_fortress_hold',
        'frost_chokepoint',
      };

      final seenIds = <String>{};
      for (var seed = 1; seed <= 24; seed += 1) {
        final offers = RunOfferGenerator.generate(
          seed: seed,
          stageNumber: 4,
          offerIndex: 0,
          unlockedTowers: unlockedTowers,
          chosenHeroKind: HeroKind.knight,
        );
        seenIds.addAll(offers.map((offer) => offer.id));
        expect(offers, hasLength(3));
        expect(
          offers.map((offer) => offer.id),
          everyElement(isIn(designCardIds)),
        );
        expect(
          offers.map((offer) => offer.operationLine),
          everyElement(isNotEmpty),
        );
      }

      expect(seenIds, designCardIds);
    });

    test(
      'stage event roll follows the dice-stage cadence deterministically',
      () {
        final stage4Event = StageEventGenerator.roll(
          seed: 1234,
          stageNumber: 4,
        );
        final repeated = StageEventGenerator.roll(seed: 1234, stageNumber: 4);
        final nonDiceStageEvent = StageEventGenerator.roll(
          seed: 1234,
          stageNumber: 5,
        );

        expect(stage4Event, isNotNull);
        expect(repeated?.id, stage4Event?.id);
        expect(stage4Event?.trigger, StageEventTrigger.remainingEnemies);
        expect(stage4Event?.remainingEnemiesThreshold, 2);
        expect(stage4Event?.hitPointMultiplier, greaterThanOrEqualTo(3.0));
        expect(stage4Event?.damageMultiplier, greaterThanOrEqualTo(1.5));
        expect(nonDiceStageEvent, isNull);
      },
    );
  });
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
