import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';

/// Tile types for the explicit tile-based grid system.
/// - [path]: monster walking route (not buildable)
/// - [buildable]: player can place towers here
/// - [blocked]: neither path nor buildable (decorative/empty)
enum TileType { path, buildable, blocked, supplyNode, citadel }

enum SpawnDirection { north, south, east, west }

enum StageEnvironmentTheme {
  frontierRoad,
  banditCrossroads,
  graveFields,
  cursedChapel,
  bastionApproach,
  throneMarch,
}

enum StageDecorationLayer { background, foreground }

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

class StageDecorationDefinition {
  const StageDecorationDefinition({
    required this.assetPath,
    required this.position,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.layer = StageDecorationLayer.background,
  });

  final String assetPath;
  final Offset position;
  final double scale;
  final double opacity;
  final StageDecorationLayer layer;
}

class StageObstacleDefinition {
  const StageObstacleDefinition({
    required this.assetPath,
    required this.occupiedCells,
    this.scale = 1.0,
    this.opacity = 1.0,
  });

  final String assetPath;
  final List<List<int>> occupiedCells;
  final double scale;
  final double opacity;
}

class StageBuildZoneDefinition {
  const StageBuildZoneDefinition({
    required this.region,
    this.label = 'Build Zone',
  });

  final Rect region;
  final String label;
}

class AssaultCycleDefinition {
  const AssaultCycleDefinition({
    required this.number,
    required this.activeFronts,
    required this.groups,
    this.recoverySeconds = 30,
    this.recoveryGoldBonus = 0,
    this.isFinalBreach = false,
  });

  final int number;
  final List<SpawnDirection> activeFronts;
  final List<FrontSpawnGroupDefinition> groups;
  final double recoverySeconds;
  final int recoveryGoldBonus;
  final bool isFinalBreach;
}

class FrontSpawnGroupDefinition {
  const FrontSpawnGroupDefinition({
    required this.front,
    required this.enemy,
    required this.count,
    required this.spawnInterval,
  });

  final SpawnDirection front;
  final EnemyDefinition enemy;
  final int count;
  final double spawnInterval;
}

class StageDefinition {
  const StageDefinition({
    required this.number,
    required this.title,
    required this.description,
    required this.startingCoins,
    required this.baseHealth,
    required this.environmentTheme,
    required this.pathNodes,
    required this.buildSlots,
    required this.waves,
    required this.objectives,
    this.buildZones = const [],
    this.pathClearance = 40.0,
    this.buildGridSpacing = 10.0,
    this.decorations = const [],
    this.unlockRequirements = const [],
    this.slotTapRadius = 28,
    this.tileGrid,
    this.pathSequence,
    this.actNumber,
    this.citadelHp,
    this.pathsByDirection,
    this.obstacles = const [],
    this.supplyNodeCells = const [],
    this.assaultCycles = const [],
  });

  final int number;
  final int? actNumber;
  final String title;
  final String description;
  final int startingCoins;
  final int baseHealth;
  final int? citadelHp;
  final StageEnvironmentTheme environmentTheme;
  final List<Offset> pathNodes;
  final List<Offset> buildSlots;
  final List<WaveDefinition> waves;
  final List<StageObjectiveDefinition> objectives;
  final List<StageBuildZoneDefinition> buildZones;
  final double pathClearance;
  final double buildGridSpacing;
  final List<StageDecorationDefinition> decorations;
  final List<StageUnlockRequirement> unlockRequirements;
  final double slotTapRadius;

  /// Explicit tile grid: `tileGrid[row][col]` gives the [TileType] for that cell.
  /// When non-null, overrides the distance-based buildable slot and path detection.
  final List<List<TileType>>? tileGrid;

  /// Ordered list of [col, row] grid coordinates defining the monster path.
  /// Used when [tileGrid] is non-null to set enemy waypoints from tile centers.
  final List<List<int>>? pathSequence;

  /// Future-facing authored routes for `Citadel Siege`.
  final Map<SpawnDirection, List<List<int>>>? pathsByDirection;

  /// Visible environment obstacles that also block building and enemy routing.
  final List<StageObstacleDefinition> obstacles;

  /// Future-facing authored supply-node tiles for `Citadel Siege`.
  final List<List<int>> supplyNodeCells;

  /// Future-facing assault cycle definitions for `Citadel Siege`.
  final List<AssaultCycleDefinition> assaultCycles;

  int get startingGold => startingCoins;
  int get citadelHitPoints => citadelHp ?? baseHealth;
  int get cycleCount =>
      assaultCycles.isNotEmpty ? assaultCycles.length : waves.length;

  StageEvaluationResult evaluateRun(StageRunSummary summary) {
    final results = [
      for (final objective in objectives)
        StageObjectiveResult(
          definition: objective,
          completed: _evaluateObjective(objective, summary),
        ),
    ];

    final stars = results
        .where((result) => result.completed)
        .length
        .clamp(0, 3);
    return StageEvaluationResult(
      starsAwarded: stars,
      objectiveResults: results,
    );
  }

  bool _evaluateObjective(
    StageObjectiveDefinition objective,
    StageRunSummary summary,
  ) {
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

typedef SiegeDefinition = StageDefinition;
typedef SiegeObjectiveDefinition = StageObjectiveDefinition;
typedef SiegeRunSummary = StageRunSummary;
typedef SiegeObjectiveResult = StageObjectiveResult;
typedef SiegeEvaluationResult = StageEvaluationResult;

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
    this.direction,
  });

  final EnemyDefinition enemy;
  final int count;
  final double spawnInterval;
  final SpawnDirection? direction;
}
