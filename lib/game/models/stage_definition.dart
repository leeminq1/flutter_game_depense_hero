import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';

enum StageObjectiveType {
  clearStage,
  keepBaseHealth,
  buildAtMost,
  sellAtMost,
  buildSpecificTower,
}

enum StageUnlockRequirementType {
  previousStageStars,
  totalStars,
  metaUpgradeLevel,
}

class StageObjectiveDefinition {
  const StageObjectiveDefinition({
    required this.type,
    required this.label,
    this.threshold,
    this.towerKindId,
  });

  final StageObjectiveType type;
  final String label;
  final int? threshold;
  final String? towerKindId;
}

class StageUnlockRequirement {
  const StageUnlockRequirement({
    required this.type,
    required this.label,
    this.stageNumber,
    this.threshold,
    this.upgradeId,
  });

  final StageUnlockRequirementType type;
  final String label;
  final int? stageNumber;
  final int? threshold;
  final String? upgradeId;
}

class StageRunSummary {
  const StageRunSummary({
    required this.cleared,
    required this.baseHealthRemaining,
    required this.maxBaseHealth,
    required this.towersBuilt,
    required this.towersSold,
    required this.builtTowerKinds,
  });

  final bool cleared;
  final int baseHealthRemaining;
  final int maxBaseHealth;
  final int towersBuilt;
  final int towersSold;
  final Set<String> builtTowerKinds;
}

class StageObjectiveResult {
  const StageObjectiveResult({
    required this.definition,
    required this.completed,
  });

  final StageObjectiveDefinition definition;
  final bool completed;
}

class StageEvaluationResult {
  const StageEvaluationResult({
    required this.starsAwarded,
    required this.objectiveResults,
  });

  final int starsAwarded;
  final List<StageObjectiveResult> objectiveResults;
}

class StageDefinition {
  const StageDefinition({
    required this.number,
    required this.title,
    required this.description,
    required this.startingCoins,
    required this.baseHealth,
    required this.pathNodes,
    required this.buildSlots,
    required this.waves,
    required this.objectives,
    this.unlockRequirements = const [],
    this.slotTapRadius = 28,
  });

  final int number;
  final String title;
  final String description;
  final int startingCoins;
  final int baseHealth;
  final List<Offset> pathNodes;
  final List<Offset> buildSlots;
  final List<WaveDefinition> waves;
  final List<StageObjectiveDefinition> objectives;
  final List<StageUnlockRequirement> unlockRequirements;
  final double slotTapRadius;

  StageEvaluationResult evaluateRun(StageRunSummary summary) {
    final results = [
      for (final objective in objectives)
        StageObjectiveResult(
          definition: objective,
          completed: _evaluateObjective(objective, summary),
        ),
    ];

    final stars = results.where((result) => result.completed).length.clamp(0, 3);
    return StageEvaluationResult(
      starsAwarded: stars,
      objectiveResults: results,
    );
  }

  bool _evaluateObjective(StageObjectiveDefinition objective, StageRunSummary summary) {
    switch (objective.type) {
      case StageObjectiveType.clearStage:
        return summary.cleared;
      case StageObjectiveType.keepBaseHealth:
        final threshold = objective.threshold ?? 1;
        return summary.baseHealthRemaining >= threshold;
      case StageObjectiveType.buildAtMost:
        final threshold = objective.threshold ?? 999;
        return summary.towersBuilt <= threshold;
      case StageObjectiveType.sellAtMost:
        final threshold = objective.threshold ?? 999;
        return summary.towersSold <= threshold;
      case StageObjectiveType.buildSpecificTower:
        final towerKindId = objective.towerKindId;
        if (towerKindId == null) {
          return false;
        }
        return summary.builtTowerKinds.contains(towerKindId);
    }
  }
}

class WaveDefinition {
  const WaveDefinition({
    required this.number,
    required this.groups,
    this.groupGap = 1.25,
  });

  final int number;
  final List<SpawnGroupDefinition> groups;
  final double groupGap;
}

class SpawnGroupDefinition {
  const SpawnGroupDefinition({
    required this.enemy,
    required this.count,
    required this.spawnInterval,
  });

  final EnemyDefinition enemy;
  final int count;
  final double spawnInterval;
}
