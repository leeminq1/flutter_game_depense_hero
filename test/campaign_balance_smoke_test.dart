import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tower base combat numbers match the current balance pass', () {
    expect(TowerCatalog.byKind(TowerKind.archer).damage, 9.5);
    expect(TowerCatalog.byKind(TowerKind.guardBarracks).damage, 13.5);
    expect(TowerCatalog.byKind(TowerKind.mageObelisk).damage, 17.5);
    expect(TowerCatalog.byKind(TowerKind.frostShrine).damage, 3.5);

    final ballista = TowerCatalog.byKind(TowerKind.ballista);
    expect(ballista.damage, 13.5);
    expect(ballista.range, 8);
    expect(ballista.cooldown, 1.75);

    final emberkeep = TowerCatalog.byKind(TowerKind.emberkeep);
    expect(emberkeep.damage, 9.5);
    expect(emberkeep.range, 6);
    expect(emberkeep.cooldown, 1.35);
  });

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

  test('normal wave pressure follows capped linear balance targets', () {
    const expectedPressures = <int, List<double>>{
      1: [90, 160, 229],
      2: [123, 167, 211, 255],
      3: [234, 284, 335, 385],
      4: [273, 328, 382, 436],
      5: [314, 441, 568, 695],
      6: [127, 166, 206, 245],
      7: [139, 258, 376, 494],
      8: [146, 270, 393, 517],
      9: [152, 281, 410, 539],
      10: [157, 291, 424, 558],
      11: [143, 335, 527, 719],
      12: [166, 370, 574, 778],
      13: [201, 352, 503, 654],
      14: [174, 347, 520, 693],
      15: [202, 441, 681, 920],
      16: [305, 445, 586, 726],
      17: [332, 476, 619, 762],
      18: [350, 490, 630, 770],
      19: [365, 505, 645, 785],
      20: [370, 504, 637, 770],
      21: [1497, 2037, 2576, 3116],
      22: [1515, 2061, 2607, 3153],
      23: [1531, 2083, 2635, 3187],
      24: [1544, 2100, 2657, 3213],
      25: [1555, 2115, 2675, 3235],
      26: [1702, 2315, 2929, 3542],
      27: [1720, 2339, 2959, 3579],
      28: [1734, 2359, 2984, 3609],
      29: [1748, 2377, 3007, 3637],
      30: [1758, 2788, 3818, 4848],
    };

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final pressures = [
        for (final cycle in stage.assaultCycles) _pressureIndex(cycle.groups),
      ];
      final expected = expectedPressures[stageNumber]!;

      for (var index = 0; index < pressures.length; index += 1) {
        expect(
          pressures[index],
          closeTo(expected[index], 3.0),
          reason:
              'Stage $stageNumber wave ${index + 1} pressure should follow '
              'the capped linear target.',
        );
      }

      expect(
        pressures.first,
        closeTo(expected.first, 3.0),
        reason: 'Stage $stageNumber wave 1 should be about 10% easier.',
      );
      expect(
        pressures.last,
        lessThanOrEqualTo(expected.last + 3.0),
        reason: 'Stage $stageNumber final wave should not exceed +30%.',
      );
      for (var index = 1; index < pressures.length; index += 1) {
        expect(
          pressures[index],
          greaterThan(pressures[index - 1]),
          reason: 'Stage $stageNumber pressure should increase each wave.',
        );
      }
    }
  });

  test('wave rebalance preserves stage economy rewards', () {
    const expectedWaveGold = <int, List<int>>{
      1: [75, 90, 112],
      2: [89, 103, 129, 135],
      3: [120, 164, 186, 172],
      4: [139, 179, 174, 165],
      5: [138, 168, 212, 206],
      6: [84, 84, 133, 126],
      7: [92, 125, 148, 170],
      8: [92, 125, 148, 174],
      9: [96, 129, 153, 177],
      10: [99, 133, 157, 177],
      11: [102, 124, 145, 215],
      12: [107, 118, 156, 228],
      13: [113, 104, 166, 195],
      14: [107, 125, 161, 198],
      15: [114, 123, 186, 229],
      16: [162, 195, 227, 248],
      17: [158, 195, 233, 264],
      18: [166, 202, 238, 270],
      19: [178, 211, 247, 274],
      20: [183, 211, 289, 255],
      21: [390, 482, 542, 573],
      22: [397, 491, 552, 583],
      23: [402, 497, 559, 590],
      24: [409, 506, 569, 595],
      25: [414, 512, 576, 607],
      26: [440, 551, 618, 642],
      27: [447, 559, 627, 654],
      28: [452, 566, 635, 659],
      29: [459, 575, 645, 671],
      30: [464, 581, 652, 895],
    };

    for (final MapEntry(key: stageNumber, value: expected)
        in expectedWaveGold.entries) {
      final stage = CampaignData.stage(stageNumber);
      final actual = [
        for (final cycle in stage.assaultCycles)
          cycle.groups.fold<int>(
                0,
                (sum, group) => sum + (group.enemy.rewardCoins * group.count),
              ) +
              cycle.recoveryGoldBonus,
      ];

      expect(
        actual,
        expected,
        reason: 'Stage $stageNumber wave rewards should stay unchanged.',
      );
    }
  });

  test(
    'stage wave snapshot includes gold and pressure deltas around stage 18',
    () {
      final stage17 = CampaignData.stage(17);
      final stage18 = CampaignData.stage(18);
      final stage19 = CampaignData.stage(19);

      expect(stage17.startingCoins, 520);
      expect(stage18.startingCoins - stage17.startingCoins, 20);
      expect(stage19.startingCoins - stage18.startingCoins, 20);

      final stage17WaveGold = [
        for (final cycle in stage17.assaultCycles) _waveGoldGain(cycle),
      ];
      final stage18WaveGold = [
        for (final cycle in stage18.assaultCycles) _waveGoldGain(cycle),
      ];
      final stage19WaveGold = [
        for (final cycle in stage19.assaultCycles) _waveGoldGain(cycle),
      ];
      final stage18Pressures = [
        for (final cycle in stage18.assaultCycles) _pressureIndex(cycle.groups),
      ];
      final stage19Pressures = [
        for (final cycle in stage19.assaultCycles) _pressureIndex(cycle.groups),
      ];

      expect(stage17WaveGold, [158, 195, 233, 264]);
      expect(stage18WaveGold, [166, 202, 238, 270]);
      expect(stage19WaveGold, [178, 211, 247, 274]);
      expect(
        stage18Pressures,
        orderedEquals([
          closeTo(350, 3),
          closeTo(490, 3),
          closeTo(630, 3),
          closeTo(770, 3),
        ]),
      );
      expect(
        stage19Pressures,
        orderedEquals([
          closeTo(365, 3),
          closeTo(505, 3),
          closeTo(645, 3),
          closeTo(785, 3),
        ]),
      );
    },
  );

  test('stage event boss combat snapshots stay unchanged', () {
    const expected = <int, Map<String, List<int>>>{
      4: {
        'elite_shield_breaker': [1366, 96, 98],
      },
      7: {
        'boss_banner_captain': [1419, 68, 55],
        'elite_grave_guard': [3974, 122, 138],
      },
      10: {
        'boss_banner_captain': [1658, 68, 55],
        'elite_grave_guard': [4500, 122, 138],
      },
      13: {
        'boss_corrupted_knight': [4400, 75, 85],
        'boss_warlock': [3177, 65, 56],
      },
      16: {
        'boss_corrupted_knight': [4400, 75, 85],
        'boss_warlock': [3501, 65, 56],
      },
      19: {
        'boss_corrupted_knight': [4400, 75, 85],
        'boss_warlock': [3686, 65, 56],
      },
      22: {
        'boss_bastion_priest': [4500, 66, 60],
        'boss_bastion_overlord': [4500, 78, 88],
      },
      25: {
        'boss_bastion_priest': [4500, 66, 60],
        'boss_bastion_overlord': [4500, 78, 88],
      },
      28: {
        'boss_bastion_priest': [4500, 66, 60],
        'boss_bastion_overlord': [4500, 78, 88],
      },
    };

    for (final MapEntry(key: stageNumber, value: eventSnapshots)
        in expected.entries) {
      final game = _debugGame(stageNumber);
      for (final event in StageEventGenerator.poolForStage(stageNumber)) {
        final boss = game.debugStageEventEnemyDefinition(event);
        expect(
          [
            boss.hitPoints,
            boss.baseStructureDamage,
            boss.baseTowerContactDamage,
          ],
          eventSnapshots[event.id],
          reason: 'Stage $stageNumber ${event.id} should not be rebalanced.',
        );
      }
    }
  });
}

int _waveGoldGain(AssaultCycleDefinition cycle) {
  return cycle.groups.fold<int>(
        0,
        (sum, group) => sum + (group.enemy.rewardCoins * group.count),
      ) +
      cycle.recoveryGoldBonus;
}

double _pressureIndex(List<FrontSpawnGroupDefinition> groups) {
  const baseline = _PressureBudget(389, 96, 104);
  final budget = _pressureBudget(groups);
  return (budget.hitPoints / baseline.hitPoints) * 60 +
      (budget.structureDamage / baseline.structureDamage) * 25 +
      (budget.towerContactDamage / baseline.towerContactDamage) * 15;
}

_PressureBudget _pressureBudget(List<FrontSpawnGroupDefinition> groups) {
  var hitPoints = 0;
  var structureDamage = 0;
  var towerContactDamage = 0;
  for (final group in groups) {
    hitPoints += group.enemy.hitPoints * group.count;
    structureDamage += group.enemy.baseStructureDamage * group.count;
    towerContactDamage += group.enemy.baseTowerContactDamage * group.count;
  }
  return _PressureBudget(hitPoints, structureDamage, towerContactDamage);
}

DefensePrototypeGame _debugGame(int stageNumber) {
  return DefensePrototypeGame(
    stage: CampaignData.stage(stageNumber),
    sessionController: GameSessionController(),
    audioService: GameAudioService(AudioSettingsController()),
    metaUpgrades: const ResolvedMetaUpgrades(),
    chosenHeroKind: HeroKind.knight,
  );
}

class _PressureBudget {
  const _PressureBudget(
    this.hitPoints,
    this.structureDamage,
    this.towerContactDamage,
  );

  final int hitPoints;
  final int structureDamage;
  final int towerContactDamage;
}
