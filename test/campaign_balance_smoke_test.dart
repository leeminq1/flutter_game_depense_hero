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

  test('normal wave pressure follows tuned stage-band ramp targets', () {
    List<double>? previousPressures;

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final pressures = [
        for (final cycle in stage.assaultCycles) _pressureIndex(cycle.groups),
      ];
      final expected = _expectedPressureTargets(stageNumber);
      final stageScore =
          pressures.reduce((total, pressure) => total + pressure) /
          pressures.length;

      for (var index = 0; index < pressures.length; index += 1) {
        expect(
          pressures[index],
          closeTo(expected[index], 3.0),
          reason:
              'Stage $stageNumber wave ${index + 1} pressure should follow '
              'the tuned stage-band ramp target.',
        );
      }

      expect(
        pressures.first,
        closeTo(expected.first, 3.0),
        reason: 'Stage $stageNumber wave 1 should anchor the Stage curve.',
      );
      expect(
        pressures.last,
        lessThanOrEqualTo(expected.last + 3.0),
        reason:
            'Stage $stageNumber final wave should stay within the target '
            'stage-band ramp.',
      );
      for (var index = 1; index < pressures.length; index += 1) {
        expect(
          pressures[index],
          greaterThan(pressures[index - 1]),
          reason: 'Stage $stageNumber pressure should increase each wave.',
        );
      }

      if (previousPressures != null) {
        expect(
          pressures.first,
          greaterThan(previousPressures.first),
          reason:
              'Stage $stageNumber opening pressure should be higher than the '
              'previous stage.',
        );
        expect(
          stageScore,
          greaterThan(
            previousPressures.reduce((total, pressure) => total + pressure) /
                previousPressures.length,
          ),
          reason:
              'Stage $stageNumber average pressure should be higher than the '
              'previous stage.',
        );
      }
      previousPressures = pressures;
    }
  });

  test('wave rewards do not regress between stages', () {
    List<int>? previousWaveGold;

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final actual = [
        for (final cycle in stage.assaultCycles)
          cycle.groups.fold<int>(
                0,
                (sum, group) => sum + (group.enemy.rewardCoins * group.count),
              ) +
              cycle.recoveryGoldBonus,
      ];

      for (var index = 1; index < actual.length; index += 1) {
        expect(
          actual[index],
          greaterThan(actual[index - 1]),
          reason: 'Stage $stageNumber wave rewards should increase by wave.',
        );
      }
      if (previousWaveGold != null) {
        for (
          var index = 0;
          index < previousWaveGold.length && index < actual.length;
          index += 1
        ) {
          expect(
            actual[index],
            greaterThanOrEqualTo(previousWaveGold[index]),
            reason:
                'Stage $stageNumber wave ${index + 1} reward should not dip '
                'below the previous stage.',
          );
        }
      }
      previousWaveGold = actual;
    }
  });

  test('early and mid campaign waves keep readable enemy counts', () {
    expect(_enemyCountsForStage(5), [7, 9, 11, 12]);
    expect(_enemyCountsForStage(10), [7, 10, 12, 13]);
    expect(_enemyCountsForStage(11), [7, 10, 12, 13]);
    expect(_enemyCountsForStage(20), [7, 10, 12, 13]);
    expect(_enemyCountsForStage(21), [8, 11, 13, 14]);
  });

  test('stage event boss HP follows the staged piecewise curve', () {
    const expected = <int, Map<String, List<int>>>{
      4: {
        'elite_shield_breaker': [1000, 72, 74],
      },
      7: {
        'boss_banner_captain': [1285, 68, 55],
        'elite_grave_guard': [1285, 74, 76],
      },
      10: {
        'boss_banner_captain': [1570, 68, 55],
        'elite_grave_guard': [1570, 76, 78],
      },
      13: {
        'boss_corrupted_knight': [1940, 75, 80],
        'boss_warlock': [1940, 65, 56],
      },
      16: {
        'boss_corrupted_knight': [2310, 75, 82],
        'boss_warlock': [2310, 65, 56],
      },
      19: {
        'boss_corrupted_knight': [2680, 75, 84],
        'boss_warlock': [2680, 65, 56],
      },
      22: {
        'boss_bastion_priest': [3130, 66, 60],
        'boss_bastion_overlord': [3130, 78, 86],
      },
      25: {
        'boss_bastion_priest': [3580, 66, 60],
        'boss_bastion_overlord': [3580, 78, 88],
      },
      28: {
        'boss_bastion_priest': [4030, 66, 60],
        'boss_bastion_overlord': [4030, 78, 88],
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
          reason:
              'Stage $stageNumber ${event.id} should follow the linear '
              'event boss curve.',
        );
      }
    }
  });
}

List<double> _expectedPressureTargets(int stageNumber) {
  if (stageNumber == 1) {
    return _linearRampPressureTargets(const [90], 1.60, 3);
  }

  final offset = stageNumber - 2;
  final lateOffset = stageNumber > 20 ? stageNumber - 20 : 0;
  final wave1 = (105 + (offset * 14) + (lateOffset * 5)).toDouble();
  return _linearRampPressureTargets(
    [wave1],
    _targetRampForStage(stageNumber),
    4,
  );
}

double _targetRampForStage(int stageNumber) {
  if (stageNumber <= 10) {
    return 1.60;
  }
  if (stageNumber <= 20) {
    return 1.45;
  }
  return 1.35;
}

List<double> _linearRampPressureTargets(
  List<double> current,
  double ramp,
  int cycleCount,
) {
  final first = current.first;
  final last = first * (1 + ramp);
  if (cycleCount == 1) {
    return [first];
  }
  final step = (last - first) / (cycleCount - 1);
  return [
    for (var index = 0; index < cycleCount; index += 1) first + step * index,
  ];
}

List<int> _enemyCountsForStage(int stageNumber) {
  return [
    for (final cycle in CampaignData.stage(stageNumber).assaultCycles)
      cycle.groups.fold<int>(0, (sum, group) => sum + group.count),
  ];
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
