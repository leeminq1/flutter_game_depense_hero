import 'dart:math' as math;
import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';

class SampleCampaign {
  static const int totalStages = 30;

  static StageDefinition stage(int number) {
    final safeStage = number.clamp(1, totalStages);
    final biome = _biomeForStage(safeStage);
    final pathTemplate = _pathTemplates[(safeStage - 1) % _pathTemplates.length];
    final slotTemplate = _slotTemplates[(safeStage - 1) % _slotTemplates.length];
    final waveCount = safeStage >= 21 ? 5 : (safeStage >= 6 ? 4 : 3);
    final title = safeStage == 30 ? 'Stage 30 - Bastion Throne' : 'Stage $safeStage - ${biome.title}';

    return StageDefinition(
      number: safeStage,
      title: title,
      description: _stageDescription(safeStage, biome),
      startingCoins: 170 + (safeStage * 10),
      baseHealth: math.max(12, 20 - ((safeStage - 1) ~/ 6)),
      pathNodes: pathTemplate,
      buildSlots: slotTemplate,
      objectives: _objectivesForStage(safeStage),
      unlockRequirements: _unlockRequirementsForStage(safeStage),
      waves: List.generate(
        waveCount,
        (index) => _buildWave(
          stageNumber: safeStage,
          waveNumber: index + 1,
          waveCount: waveCount,
          biome: biome,
        ),
      ),
    );
  }

  static List<StageDefinition> allStages() {
    return List.generate(totalStages, (index) => stage(index + 1));
  }

  static WaveDefinition _buildWave({
    required int stageNumber,
    required int waveNumber,
    required int waveCount,
    required _BiomeProfile biome,
  }) {
    if (stageNumber == 30 && waveNumber == waveCount) {
      return _buildFinalBossWave(stageNumber: stageNumber, waveNumber: waveNumber);
    }

    final intensity = _waveIntensity(waveNumber);
    final countMultiplier = 1 + ((stageNumber - 1) * 0.06);
    final first = _enemyForRole(
      biome.primary,
      stageNumber: stageNumber,
      intensity: intensity,
    );
    final second = _enemyForRole(
      biome.secondary,
      stageNumber: stageNumber,
      intensity: intensity,
    );

    final groups = <SpawnGroupDefinition>[
      SpawnGroupDefinition(
        enemy: first,
        count: (4 * countMultiplier * intensity).round().clamp(3, 24),
        spawnInterval: math.max(0.38, 0.92 - (stageNumber * 0.01)),
      ),
      SpawnGroupDefinition(
        enemy: second,
        count: (3 * countMultiplier * (intensity + 0.08)).round().clamp(2, 18),
        spawnInterval: math.max(0.42, 1.08 - (stageNumber * 0.012)),
      ),
    ];

    if (stageNumber >= 7 || waveNumber >= 3) {
      groups.add(
        SpawnGroupDefinition(
          enemy: enemyForKind(
            biome.support,
            stageNumber: stageNumber,
            intensity: intensity + 0.1,
          ),
          count: (1 + (stageNumber / 5)).round().clamp(1, 8),
          spawnInterval: math.max(0.65, 1.35 - (stageNumber * 0.01)),
        ),
      );
    }

    if (stageNumber >= 18 && waveNumber >= waveCount - 1) {
      groups.add(
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.graveGuard,
            stageNumber: stageNumber,
            intensity: intensity + 0.12,
          ),
          count: math.max(1, ((stageNumber - 12) / 8).round()),
          spawnInterval: 2.25,
        ),
      );
    }

    if (stageNumber >= 23 && waveNumber >= 3) {
      groups.add(
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.warlock,
            stageNumber: stageNumber,
            intensity: intensity,
          ),
          count: stageNumber >= 28 ? 2 : 1,
          spawnInterval: 3.4,
        ),
      );
    }

    if (waveNumber == waveCount && (stageNumber % 5 == 0 || stageNumber >= 18)) {
      groups.add(
        SpawnGroupDefinition(
          enemy: enemyForKind(
            biome.elite,
            stageNumber: stageNumber,
            intensity: intensity + 0.22,
          ),
          count: math.max(1, (stageNumber / 10).round()),
          spawnInterval: 1.85,
        ),
      );
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber == waveCount ? 1.65 : 1.15,
    );
  }

  static WaveDefinition _buildFinalBossWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    return WaveDefinition(
      number: waveNumber,
      groupGap: 1.95,
      groups: [
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.graveGuard,
            stageNumber: stageNumber,
            intensity: 1.6,
          ),
          count: 2,
          spawnInterval: 1.7,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.warlock,
            stageNumber: stageNumber,
            intensity: 1.2,
          ),
          count: 1,
          spawnInterval: 2.6,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.corruptedKnight,
            stageNumber: stageNumber,
            intensity: 1.45,
          ),
          count: 2,
          spawnInterval: 1.55,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.bastionOverlord,
            stageNumber: stageNumber,
            intensity: 1.0,
          ),
          count: 1,
          spawnInterval: 3.6,
        ),
      ],
    );
  }

  static EnemyDefinition _enemyForRole(
    EnemyKind kind, {
    required int stageNumber,
    required double intensity,
  }) =>
      enemyForKind(
        kind,
        stageNumber: stageNumber,
        intensity: intensity,
      );

  static EnemyDefinition enemyForKind(
    EnemyKind kind, {
    required int stageNumber,
    required double intensity,
  }) {
    final hpMultiplier = 1 + ((stageNumber - 1) * 0.11);
    final speedStep = 1 + (((stageNumber - 1) ~/ 5) * 0.05);

    switch (kind) {
      case EnemyKind.raider:
        return EnemyDefinition(
          kind: kind,
          label: 'Raider',
          specialDescription: 'Enrages below half health and runs faster.',
          hitPoints: (44 * hpMultiplier * intensity).round(),
          speed: 48 * speedStep,
          rewardCoins: math.max(6, (6 + stageNumber * 0.8).round()),
          baseDamage: 1,
          color: const Color(0xFFB85C38),
        );
      case EnemyKind.scout:
        return EnemyDefinition(
          kind: kind,
          label: 'Scout',
          specialDescription: 'Dodges the first physical hit that lands on it.',
          hitPoints: (30 * hpMultiplier * math.max(0.9, intensity)).round(),
          speed: 68 * speedStep,
          rewardCoins: math.max(5, (5 + stageNumber * 0.75).round()),
          baseDamage: 1,
          color: const Color(0xFFD89C45),
        );
      case EnemyKind.shieldInfantry:
        return EnemyDefinition(
          kind: kind,
          label: 'Shield Infantry',
          specialDescription: 'Reduces damage from physical towers.',
          hitPoints: (86 * hpMultiplier * intensity).round(),
          speed: 34 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFF7D8EA3),
        );
      case EnemyKind.cultAdept:
        return EnemyDefinition(
          kind: kind,
          label: 'Cult Adept',
          specialDescription: 'Periodically hastes nearby allies.',
          hitPoints: (58 * hpMultiplier * intensity).round(),
          speed: 42 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber * 0.9).round()),
          baseDamage: 1,
          color: const Color(0xFF6E4EAA),
        );
      case EnemyKind.skeleton:
        return EnemyDefinition(
          kind: kind,
          label: 'Skeleton',
          specialDescription: 'Revives once with partial health.',
          hitPoints: (78 * hpMultiplier * intensity).round(),
          speed: 40 * speedStep,
          rewardCoins: math.max(11, (11 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFFBDB9AA),
        );
      case EnemyKind.graveGuard:
        return EnemyDefinition(
          kind: kind,
          label: 'Grave Guard',
          specialDescription: 'Resists slows and pushes through control effects.',
          hitPoints: (172 * hpMultiplier * (intensity + 0.08)).round(),
          speed: 26 * speedStep,
          rewardCoins: math.max(20, (20 + stageNumber * 1.15).round()),
          baseDamage: 3,
          color: const Color(0xFF63705F),
        );
      case EnemyKind.corruptedKnight:
        return EnemyDefinition(
          kind: kind,
          label: 'Corrupted Knight',
          specialDescription: 'Charges harder when wounded and resists physical fire.',
          hitPoints: (145 * hpMultiplier * (intensity + 0.15)).round(),
          speed: 30 * speedStep,
          rewardCoins: math.max(18, (18 + stageNumber * 1.2).round()),
          baseDamage: 3,
          color: const Color(0xFF7A5151),
        );
      case EnemyKind.warlock:
        return EnemyDefinition(
          kind: kind,
          label: 'Warlock',
          specialDescription: 'Wards allies and summons skeleton reinforcements.',
          hitPoints: (98 * hpMultiplier * intensity).round(),
          speed: 33 * speedStep,
          rewardCoins: math.max(22, (22 + stageNumber * 1.25).round()),
          baseDamage: 2,
          color: const Color(0xFF5E3E88),
        );
      case EnemyKind.bastionOverlord:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Overlord',
          specialDescription: 'Final boss that phases, wards itself, and summons defenders.',
          hitPoints: (1100 * math.max(1.0, intensity)).round(),
          speed: 24 * speedStep,
          rewardCoins: 180,
          baseDamage: 6,
          color: const Color(0xFF8C3F34),
        );
    }
  }

  static double _waveIntensity(int waveNumber) {
    switch (waveNumber) {
      case 1:
        return 1.00;
      case 2:
        return 1.15;
      case 3:
        return 1.35;
      case 4:
        return 1.60;
      default:
        return 1.95;
    }
  }

  static _BiomeProfile _biomeForStage(int stage) {
    if (stage <= 8) {
      return const _BiomeProfile(
        title: 'Forest Edge',
        primary: EnemyKind.raider,
        secondary: EnemyKind.scout,
        support: EnemyKind.shieldInfantry,
        elite: EnemyKind.shieldInfantry,
      );
    }
    if (stage <= 15) {
      return const _BiomeProfile(
        title: 'Ruin Road',
        primary: EnemyKind.shieldInfantry,
        secondary: EnemyKind.cultAdept,
        support: EnemyKind.raider,
        elite: EnemyKind.corruptedKnight,
      );
    }
    if (stage <= 22) {
      return const _BiomeProfile(
        title: 'Grave March',
        primary: EnemyKind.skeleton,
        secondary: EnemyKind.shieldInfantry,
        support: EnemyKind.cultAdept,
        elite: EnemyKind.graveGuard,
      );
    }
    return const _BiomeProfile(
      title: 'Cursed Bastion',
      primary: EnemyKind.graveGuard,
      secondary: EnemyKind.corruptedKnight,
      support: EnemyKind.warlock,
      elite: EnemyKind.corruptedKnight,
    );
  }

  static String _stageDescription(int stage, _BiomeProfile biome) {
    if (stage <= 5) {
      return 'Hold the ${biome.title.toLowerCase()} against early raiders and scouts.';
    }
    if (stage <= 10) {
      return 'Mixed enemy roles begin to pressure weak placements and poor timing.';
    }
    if (stage <= 20) {
      return 'Support units and revived threats demand cleaner tower synergy.';
    }
    if (stage == 30) {
      return 'Final siege. Survive the Bastion Overlord and its summoned defenders to finish the campaign.';
    }
    return 'Late stages layer summoners, control-resistant tanks, and elite bruisers into the same push.';
  }

  static List<StageObjectiveDefinition> _objectivesForStage(int stage) {
    if (stage == 30) {
      return const [
        StageObjectiveDefinition(
          type: StageObjectiveType.clearStage,
          label: 'Defeat the Bastion Overlord',
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.keepBaseHealth,
          label: 'Finish with at least 8 base health',
          threshold: 8,
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Ballista',
          towerKindId: 'ballista',
        ),
      ];
    }

    final healthThreshold = switch (stage) {
      <= 5 => 16,
      <= 10 => 13,
      <= 20 => 10,
      _ => 8,
    };

    final objectives = <StageObjectiveDefinition>[
      const StageObjectiveDefinition(
        type: StageObjectiveType.clearStage,
        label: 'Clear the stage',
      ),
      StageObjectiveDefinition(
        type: StageObjectiveType.keepBaseHealth,
        label: 'Finish with at least $healthThreshold base health',
        threshold: healthThreshold,
      ),
    ];

    if (stage % 3 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Mage tower',
          towerKindId: 'mageObelisk',
        ),
      );
    } else if (stage % 4 == 0) {
      objectives.add(
        StageObjectiveDefinition(
          type: StageObjectiveType.buildAtMost,
          label: 'Build at most 5 towers',
          threshold: 5,
        ),
      );
    } else if (stage % 5 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Coin Mill',
          towerKindId: 'coinMill',
        ),
      );
    } else {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.sellAtMost,
          label: 'Do not sell any towers',
          threshold: 0,
        ),
      );
    }

    return objectives;
  }

  static List<StageUnlockRequirement> _unlockRequirementsForStage(int stage) {
    if (stage <= 1) {
      return const [];
    }

    final requirements = <StageUnlockRequirement>[
      StageUnlockRequirement(
        type: StageUnlockRequirementType.previousStageStars,
        label: 'Earn at least 1 star on Stage ${stage - 1}',
        stageNumber: stage - 1,
        threshold: 1,
      ),
    ];

    if (stage == 6) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 10 total stars',
          threshold: 10,
        ),
      );
    }
    if (stage == 11) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: 'Upgrade Stronghold Masonry to level 1',
          upgradeId: 'stronghold',
          threshold: 1,
        ),
      );
    }
    if (stage == 16) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 24 total stars',
          threshold: 24,
        ),
      );
    }
    if (stage == 21) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: 'Upgrade Bow Mastery to level 2',
          upgradeId: 'bow_mastery',
          threshold: 2,
        ),
      );
    }
    if (stage == 26) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 45 total stars',
          threshold: 45,
        ),
      );
    }

    return requirements;
  }

  static const List<List<Offset>> _pathTemplates = [
    [
      Offset(0.03, 0.68),
      Offset(0.23, 0.68),
      Offset(0.23, 0.32),
      Offset(0.49, 0.32),
      Offset(0.49, 0.72),
      Offset(0.75, 0.72),
      Offset(0.75, 0.44),
      Offset(0.95, 0.44),
    ],
    [
      Offset(0.02, 0.48),
      Offset(0.18, 0.48),
      Offset(0.18, 0.18),
      Offset(0.45, 0.18),
      Offset(0.45, 0.82),
      Offset(0.72, 0.82),
      Offset(0.72, 0.28),
      Offset(0.97, 0.28),
    ],
    [
      Offset(0.05, 0.22),
      Offset(0.28, 0.22),
      Offset(0.28, 0.75),
      Offset(0.55, 0.75),
      Offset(0.55, 0.35),
      Offset(0.82, 0.35),
      Offset(0.82, 0.65),
      Offset(0.95, 0.65),
    ],
    [
      Offset(0.04, 0.58),
      Offset(0.20, 0.58),
      Offset(0.20, 0.86),
      Offset(0.52, 0.86),
      Offset(0.52, 0.18),
      Offset(0.78, 0.18),
      Offset(0.78, 0.55),
      Offset(0.96, 0.55),
    ],
    [
      Offset(0.03, 0.38),
      Offset(0.18, 0.38),
      Offset(0.18, 0.74),
      Offset(0.40, 0.74),
      Offset(0.40, 0.24),
      Offset(0.67, 0.24),
      Offset(0.67, 0.70),
      Offset(0.95, 0.70),
    ],
  ];

  static const List<List<Offset>> _slotTemplates = [
    [
      Offset(0.14, 0.47),
      Offset(0.16, 0.83),
      Offset(0.33, 0.50),
      Offset(0.38, 0.18),
      Offset(0.58, 0.52),
      Offset(0.67, 0.86),
      Offset(0.84, 0.60),
    ],
    [
      Offset(0.12, 0.31),
      Offset(0.24, 0.66),
      Offset(0.35, 0.38),
      Offset(0.40, 0.90),
      Offset(0.62, 0.53),
      Offset(0.79, 0.36),
      Offset(0.86, 0.76),
    ],
    [
      Offset(0.15, 0.10),
      Offset(0.18, 0.54),
      Offset(0.39, 0.56),
      Offset(0.46, 0.88),
      Offset(0.63, 0.48),
      Offset(0.72, 0.16),
      Offset(0.89, 0.49),
    ],
    [
      Offset(0.11, 0.73),
      Offset(0.26, 0.44),
      Offset(0.34, 0.92),
      Offset(0.57, 0.57),
      Offset(0.63, 0.08),
      Offset(0.83, 0.32),
      Offset(0.88, 0.78),
    ],
    [
      Offset(0.11, 0.19),
      Offset(0.22, 0.56),
      Offset(0.33, 0.85),
      Offset(0.48, 0.48),
      Offset(0.58, 0.11),
      Offset(0.75, 0.58),
      Offset(0.89, 0.84),
    ],
  ];
}

class _BiomeProfile {
  const _BiomeProfile({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.support,
    required this.elite,
  });

  final String title;
  final EnemyKind primary;
  final EnemyKind secondary;
  final EnemyKind support;
  final EnemyKind elite;
}
