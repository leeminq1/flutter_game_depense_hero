import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
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
      expect(
        offers
            .expand((offer) => offer.modifiers)
            .map((modifier) => modifier.towerKind),
        isNot(contains(TowerKind.ballista)),
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
  });
}
