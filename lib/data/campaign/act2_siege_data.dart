import 'dart:ui' show Color;

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';

/// Authored data for Act 2: Crossroads War – Sieges 6-10.
///
/// This file is a self-contained helper that can be merged into
/// [CampaignData] without a big refactor.  To integrate, call
/// [Act2SiegeData.authored] from [CampaignData.stage] for siegeNumbers 6-10
/// instead of the generic template builder.
///
/// Campaign spec reference: docs/product-specs/campaign-structure.md
/// Map spec reference:      docs/product-specs/map-production-plan.md
///
/// Act 2 shared constants (economy spec):
///   Starting gold : 350
///   Citadel HP    : 36
class Act2SiegeData {
  Act2SiegeData._();

  // -------------------------------------------------------------------------
  // Act 2 shared constants
  // -------------------------------------------------------------------------

  static const int startingGold = 350;
  static const int citadelHp = 36;

  /// Returns the fully-authored [SiegeDefinition] for sieges 6-10,
  /// or null for any number outside that range.
  ///
  /// Callers should treat the returned definition as the canonical source and
  /// merge it with the generic [CampaignData.stage] fallback for any field
  /// not explicitly authored here.
  static ({
    Map<SpawnDirection, List<List<int>>> pathsByDirection,
    List<List<int>> supplyNodeCells,
    List<AssaultCycleDefinition> assaultCycles,
    int startingGold,
    int citadelHp,
  })? authoredFields(int siegeNumber) {
    return switch (siegeNumber) {
      6 => (
        pathsByDirection: _paths6,
        supplyNodeCells: _supplyNodes6,
        assaultCycles: _cycles6,
        startingGold: startingGold,
        citadelHp: citadelHp,
      ),
      7 => (
        pathsByDirection: _paths7,
        supplyNodeCells: _supplyNodes7,
        assaultCycles: _cycles7,
        startingGold: startingGold,
        citadelHp: citadelHp,
      ),
      8 => (
        pathsByDirection: _paths8,
        supplyNodeCells: _supplyNodes8,
        assaultCycles: _cycles8,
        startingGold: startingGold,
        citadelHp: citadelHp,
      ),
      9 => (
        pathsByDirection: _paths9,
        supplyNodeCells: _supplyNodes9,
        assaultCycles: _cycles9,
        startingGold: startingGold,
        citadelHp: citadelHp,
      ),
      10 => (
        pathsByDirection: _paths10,
        supplyNodeCells: _supplyNodes10,
        assaultCycles: _cycles10,
        startingGold: startingGold,
        citadelHp: citadelHp,
      ),
      _ => null,
    };
  }

  // =========================================================================
  // Siege 6 – "First true 3-front prioritization"
  //
  // Front pattern: North → North+West → North+West+East  (4 cycles)
  // Final breach : 3-front armor push
  //
  // Map: Straight north route, west bends into the inner ring, east mirrors.
  // =========================================================================

  static const _paths6 = <SpawnDirection, List<List<int>>>{
    SpawnDirection.north: [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4]],
    SpawnDirection.south: [[6, 13], [6, 12], [6, 11], [6, 10], [6, 9], [6, 8]],
    SpawnDirection.east: [[13, 6], [12, 6], [11, 6], [10, 6], [9, 6], [8, 6]],
    SpawnDirection.west: [[0, 6], [1, 6], [2, 6], [3, 6], [4, 6]],
  };

  static const _supplyNodes6 = <List<int>>[
    [3, 3],
    [10, 3],
    [3, 10],
    [10, 10],
  ];

  static List<AssaultCycleDefinition> get _cycles6 => [
    // Cycle 1: North only – orientation check
    AssaultCycleDefinition(
      number: 1,
      activeFronts: const [SpawnDirection.north],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 2, 1.08),
        _fg(SpawnDirection.north, EnemyKind.raider, 4, 0.98),
      ],
      recoverySeconds: 28,
      recoveryGoldBonus: 40,
    ),
    // Cycle 2: North + West – first split attention
    AssaultCycleDefinition(
      number: 2,
      activeFronts: const [SpawnDirection.north, SpawnDirection.west],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 2, 1.06),
        _fg(SpawnDirection.north, EnemyKind.raider, 4, 0.96),
        _fg(SpawnDirection.west, EnemyKind.scout, 4, 0.94),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.1),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 40,
    ),
    // Cycle 3: North + West + East – first real 3-front load
    AssaultCycleDefinition(
      number: 3,
      activeFronts: const [
        SpawnDirection.north,
        SpawnDirection.west,
        SpawnDirection.east,
      ],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.north, EnemyKind.raider, 4, 0.94),
        _fg(SpawnDirection.west, EnemyKind.scout, 4, 0.92),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.06),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.88),
        _fg(SpawnDirection.east, EnemyKind.raider, 3, 0.96),
      ],
      recoverySeconds: 32,
      recoveryGoldBonus: 40,
    ),
    // Cycle 4 (Final breach): 3-front armor push
    AssaultCycleDefinition(
      number: 4,
      activeFronts: const [
        SpawnDirection.north,
        SpawnDirection.west,
        SpawnDirection.east,
      ],
      isFinalBreach: true,
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 3, 1.02),
        _fg(SpawnDirection.north, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.west, EnemyKind.raider, 5, 0.9),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.84),
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 2, 1.06),
      ],
      recoverySeconds: 0,
      recoveryGoldBonus: 0,
    ),
  ];

  // =========================================================================
  // Siege 7 – "West+East pressure with delayed North"
  //
  // Front pattern: West+East → West+East → West+East+North → all  (4 cycles)
  // Final breach : Cult Adept backline finale
  //
  // Map: West and East routes bend slightly toward inner ring before citadel.
  // =========================================================================

  static const _paths7 = <SpawnDirection, List<List<int>>>{
    SpawnDirection.north: [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4]],
    SpawnDirection.south: [[6, 13], [6, 12], [6, 11], [6, 10], [6, 9], [6, 8]],
    // West route bends through row 7 before converging
    SpawnDirection.west: [
      [0, 7], [1, 7], [2, 7], [3, 7], [3, 6], [4, 6],
    ],
    // East route bends through row 5 before converging
    SpawnDirection.east: [
      [13, 5], [12, 5], [11, 5], [10, 5], [10, 6], [9, 6], [8, 6],
    ],
  };

  static const _supplyNodes7 = <List<int>>[
    [2, 4],
    [11, 4],
    [3, 10],
    [10, 10],
  ];

  static List<AssaultCycleDefinition> get _cycles7 => [
    // Cycle 1: West + East – early flank pressure
    AssaultCycleDefinition(
      number: 1,
      activeFronts: const [SpawnDirection.west, SpawnDirection.east],
      groups: [
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.08),
        _fg(SpawnDirection.west, EnemyKind.scout, 4, 0.94),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.88),
        _fg(SpawnDirection.east, EnemyKind.raider, 4, 0.96),
      ],
      recoverySeconds: 28,
      recoveryGoldBonus: 40,
    ),
    // Cycle 2: West + East + first Cult Adept hint
    AssaultCycleDefinition(
      number: 2,
      activeFronts: const [SpawnDirection.west, SpawnDirection.east],
      groups: [
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 3, 1.06),
        _fg(SpawnDirection.west, EnemyKind.cultAdept, 1, 2.0),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.86),
        _fg(SpawnDirection.east, EnemyKind.raider, 5, 0.94),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 40,
    ),
    // Cycle 3: West + East + North opens
    AssaultCycleDefinition(
      number: 3,
      activeFronts: const [
        SpawnDirection.west,
        SpawnDirection.east,
        SpawnDirection.north,
      ],
      groups: [
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.west, EnemyKind.cultAdept, 1, 2.0),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 2, 0.84),
        _fg(SpawnDirection.east, EnemyKind.raider, 4, 0.92),
        _fg(SpawnDirection.north, EnemyKind.scout, 4, 0.92),
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 2, 1.08),
      ],
      recoverySeconds: 32,
      recoveryGoldBonus: 40,
    ),
    // Cycle 4 (Final breach): Cult Adept backline finale
    AssaultCycleDefinition(
      number: 4,
      activeFronts: const [
        SpawnDirection.west,
        SpawnDirection.east,
        SpawnDirection.north,
      ],
      isFinalBreach: true,
      groups: [
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 4, 1.02),
        _fg(SpawnDirection.west, EnemyKind.cultAdept, 2, 1.95),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 2, 0.82),
        _fg(SpawnDirection.east, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.9),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 1, 2.0),
      ],
      recoverySeconds: 0,
      recoveryGoldBonus: 0,
    ),
  ];

  // =========================================================================
  // Siege 8 – "East-heavy start, then split 3-front"
  //
  // Front pattern: East → East+North → East+North+West → 3-front  (4 cycles)
  // Final breach : Leader-backed split breach
  //
  // Map: East route has a wider approach arc through the outer ring.
  // =========================================================================

  static const _paths8 = <SpawnDirection, List<List<int>>>{
    SpawnDirection.north: [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4]],
    SpawnDirection.south: [[6, 13], [6, 12], [6, 11], [6, 10], [6, 9], [6, 8]],
    SpawnDirection.west: [[0, 6], [1, 6], [2, 6], [3, 6], [4, 6]],
    // East route arcs slightly south before converging
    SpawnDirection.east: [
      [13, 7], [12, 7], [11, 7], [11, 6], [10, 6], [9, 6], [8, 6],
    ],
  };

  static const _supplyNodes8 = <List<int>>[
    [3, 3],
    [11, 3],
    [2, 10],
    [10, 10],
  ];

  static List<AssaultCycleDefinition> get _cycles8 => [
    // Cycle 1: East-heavy – learns east angle read
    AssaultCycleDefinition(
      number: 1,
      activeFronts: const [SpawnDirection.east],
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.86),
        _fg(SpawnDirection.east, EnemyKind.raider, 5, 0.94),
      ],
      recoverySeconds: 28,
      recoveryGoldBonus: 48,
    ),
    // Cycle 2: East + North – two-front commitment
    AssaultCycleDefinition(
      number: 2,
      activeFronts: const [SpawnDirection.east, SpawnDirection.north],
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 1, 0.84),
        _fg(SpawnDirection.east, EnemyKind.cultAdept, 1, 2.0),
        _fg(SpawnDirection.north, EnemyKind.raider, 4, 0.92),
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 2, 1.08),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 48,
    ),
    // Cycle 3: East + North + West – full 3-front
    AssaultCycleDefinition(
      number: 3,
      activeFronts: const [
        SpawnDirection.east,
        SpawnDirection.north,
        SpawnDirection.west,
      ],
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 4, 1.02),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 2, 0.82),
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.9),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 1, 1.98),
        _fg(SpawnDirection.west, EnemyKind.scout, 4, 0.92),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.06),
      ],
      recoverySeconds: 32,
      recoveryGoldBonus: 48,
    ),
    // Cycle 4 (Final breach): Leader-backed split breach
    AssaultCycleDefinition(
      number: 4,
      activeFronts: const [
        SpawnDirection.east,
        SpawnDirection.north,
        SpawnDirection.west,
      ],
      isFinalBreach: true,
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 4, 1.0),
        _fg(SpawnDirection.east, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 2, 0.8),
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.88),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 2, 1.95),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.west, EnemyKind.bannerCaptain, 1, 2.25),
      ],
      recoverySeconds: 0,
      recoveryGoldBonus: 0,
    ),
  ];

  // =========================================================================
  // Siege 9 – "Rotating 3-front emphasis"
  //
  // Front pattern: North+West → East+West → North+East → all 4  (4 cycles)
  // Final breach : Rotating pressure capstone
  //
  // Map: Routes with gentle bends for variety, north bends west before entry.
  // =========================================================================

  static const _paths9 = <SpawnDirection, List<List<int>>>{
    // North route bends slightly east
    SpawnDirection.north: [
      [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [6, 4],
    ],
    SpawnDirection.south: [[6, 13], [6, 12], [6, 11], [6, 10], [6, 9], [6, 8]],
    SpawnDirection.east: [[13, 6], [12, 6], [11, 6], [10, 6], [9, 6], [8, 6]],
    // West route bends into row 5 approach
    SpawnDirection.west: [
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [4, 6],
    ],
  };

  static const _supplyNodes9 = <List<int>>[
    [3, 3],
    [10, 3],
    [2, 9],
    [11, 9],
  ];

  static List<AssaultCycleDefinition> get _cycles9 => [
    // Cycle 1: North + West
    AssaultCycleDefinition(
      number: 1,
      activeFronts: const [SpawnDirection.north, SpawnDirection.west],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.raider, 4, 0.96),
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 2, 1.06),
        _fg(SpawnDirection.west, EnemyKind.scout, 4, 0.94),
        _fg(SpawnDirection.west, EnemyKind.wolfScout, 1, 0.86),
      ],
      recoverySeconds: 28,
      recoveryGoldBonus: 48,
    ),
    // Cycle 2: East + West – lateral squeeze
    AssaultCycleDefinition(
      number: 2,
      activeFronts: const [SpawnDirection.east, SpawnDirection.west],
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.east, EnemyKind.cultAdept, 1, 2.0),
        _fg(SpawnDirection.west, EnemyKind.wolfScout, 2, 0.84),
        _fg(SpawnDirection.west, EnemyKind.raider, 5, 0.92),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.06),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 48,
    ),
    // Cycle 3: North + East – diagonal pressure
    AssaultCycleDefinition(
      number: 3,
      activeFronts: const [SpawnDirection.north, SpawnDirection.east],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.9),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 1, 1.98),
        _fg(SpawnDirection.north, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 4, 1.02),
        _fg(SpawnDirection.east, EnemyKind.wolfScout, 2, 0.82),
      ],
      recoverySeconds: 32,
      recoveryGoldBonus: 48,
    ),
    // Cycle 4 (Final breach): All 4 fronts – rotating capstone
    AssaultCycleDefinition(
      number: 4,
      activeFronts: const [
        SpawnDirection.north,
        SpawnDirection.east,
        SpawnDirection.west,
        SpawnDirection.south,
      ],
      isFinalBreach: true,
      groups: [
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.88),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 2, 1.95),
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 4, 1.0),
        _fg(SpawnDirection.east, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.west, EnemyKind.wolfScout, 2, 0.8),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.south, EnemyKind.scout, 3, 0.92),
      ],
      recoverySeconds: 0,
      recoveryGoldBonus: 0,
    ),
  ];

  // =========================================================================
  // Siege 10 – "Four-front leader-heavy climax" (Act 2 finale)
  //
  // Front pattern: North+West → East+West+South → all four → all four  (4 cycles)
  // Final breach : Four-front Banner Captain finale
  //
  // Map: All four routes use slight bends to signal the act-climax complexity.
  // =========================================================================

  static const _paths10 = <SpawnDirection, List<List<int>>>{
    // North bends east then south into citadel approach
    SpawnDirection.north: [
      [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5],
    ],
    // South bends west then north
    SpawnDirection.south: [
      [5, 13], [5, 12], [5, 11], [5, 10], [5, 9], [5, 8],
    ],
    // East route bends into row 7 approach
    SpawnDirection.east: [
      [13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7],
    ],
    // West route bends into row 5 approach
    SpawnDirection.west: [
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [4, 6],
    ],
  };

  static const _supplyNodes10 = <List<int>>[
    [3, 2],
    [10, 2],
    [3, 11],
    [10, 11],
    [2, 6],
    [11, 6],
  ];

  static List<AssaultCycleDefinition> get _cycles10 => [
    // Cycle 1: North + West – open with familiar 2-front
    AssaultCycleDefinition(
      number: 1,
      activeFronts: const [SpawnDirection.north, SpawnDirection.west],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 3, 1.04),
        _fg(SpawnDirection.north, EnemyKind.raider, 5, 0.92),
        _fg(SpawnDirection.west, EnemyKind.wolfScout, 1, 0.86),
        _fg(SpawnDirection.west, EnemyKind.scout, 5, 0.9),
        _fg(SpawnDirection.west, EnemyKind.shieldInfantry, 2, 1.08),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 48,
    ),
    // Cycle 2: East + West + South – triple-front stress
    AssaultCycleDefinition(
      number: 2,
      activeFronts: const [
        SpawnDirection.east,
        SpawnDirection.west,
        SpawnDirection.south,
      ],
      groups: [
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 3, 1.02),
        _fg(SpawnDirection.east, EnemyKind.cultAdept, 1, 1.98),
        _fg(SpawnDirection.west, EnemyKind.wolfScout, 2, 0.84),
        _fg(SpawnDirection.west, EnemyKind.raider, 5, 0.9),
        _fg(SpawnDirection.south, EnemyKind.scout, 4, 0.92),
        _fg(SpawnDirection.south, EnemyKind.shieldInfantry, 2, 1.06),
      ],
      recoverySeconds: 30,
      recoveryGoldBonus: 48,
    ),
    // Cycle 3: All four fronts – full board
    AssaultCycleDefinition(
      number: 3,
      activeFronts: const [
        SpawnDirection.north,
        SpawnDirection.south,
        SpawnDirection.east,
        SpawnDirection.west,
      ],
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 4, 1.0),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 1, 1.96),
        _fg(SpawnDirection.south, EnemyKind.raider, 5, 0.88),
        _fg(SpawnDirection.south, EnemyKind.wolfScout, 1, 0.82),
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 3, 1.02),
        _fg(SpawnDirection.east, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.west, EnemyKind.scout, 5, 0.88),
        _fg(SpawnDirection.west, EnemyKind.cultAdept, 2, 1.94),
      ],
      recoverySeconds: 32,
      recoveryGoldBonus: 48,
    ),
    // Cycle 4 (Final breach): Four-front Banner Captain finale
    AssaultCycleDefinition(
      number: 4,
      activeFronts: const [
        SpawnDirection.north,
        SpawnDirection.south,
        SpawnDirection.east,
        SpawnDirection.west,
      ],
      isFinalBreach: true,
      groups: [
        _fg(SpawnDirection.north, EnemyKind.shieldInfantry, 4, 0.98),
        _fg(SpawnDirection.north, EnemyKind.bannerCaptain, 1, 2.15),
        _fg(SpawnDirection.north, EnemyKind.cultAdept, 2, 1.92),
        _fg(SpawnDirection.south, EnemyKind.raider, 6, 0.86),
        _fg(SpawnDirection.south, EnemyKind.wolfScout, 2, 0.8),
        _fg(SpawnDirection.south, EnemyKind.bannerCaptain, 1, 2.2),
        _fg(SpawnDirection.east, EnemyKind.shieldInfantry, 5, 0.96),
        _fg(SpawnDirection.east, EnemyKind.cultAdept, 2, 1.9),
        _fg(SpawnDirection.west, EnemyKind.scout, 5, 0.86),
        _fg(SpawnDirection.west, EnemyKind.bannerCaptain, 1, 2.25),
      ],
      recoverySeconds: 0,
      recoveryGoldBonus: 0,
    ),
  ];

  // =========================================================================
  // Private helper
  // =========================================================================

  /// Creates a [FrontSpawnGroupDefinition] using a scaled [EnemyDefinition]
  /// appropriate for Act 2 difficulty.
  static FrontSpawnGroupDefinition _fg(
    SpawnDirection front,
    EnemyKind kind,
    int count,
    double spawnInterval,
  ) {
    return FrontSpawnGroupDefinition(
      front: front,
      enemy: _act2Enemy(kind),
      count: count,
      spawnInterval: spawnInterval,
    );
  }

  /// Returns an [EnemyDefinition] at Act 2 baseline stat scaling.
  ///
  /// Stat scale reference (economy spec Act 2 band):
  ///   hp multiplier  : 1.12
  ///   speed mult     : 1.04
  ///   reward mult    : 1.08
  static EnemyDefinition _act2Enemy(EnemyKind kind) {
    const hpMult = 1.12;
    const speedMult = 1.04;
    const rewardMult = 1.08;
    return switch (kind) {
      EnemyKind.raider => EnemyDefinition(
        kind: kind,
        label: 'Raider',
        specialDescription: 'Fast melee attacker with light armour.',
        hitPoints: (62 * hpMult).round(),
        speed: 48 * speedMult,
        rewardCoins: (8 * rewardMult).round(),
        citadelDamage: 1,
        color: const Color(0xFFA0522D),
      ),
      EnemyKind.scout => EnemyDefinition(
        kind: kind,
        label: 'Scout',
        specialDescription: 'Very fast, low health – punishes gaps in coverage.',
        hitPoints: (38 * hpMult).round(),
        speed: 62 * speedMult,
        rewardCoins: (7 * rewardMult).round(),
        citadelDamage: 1,
        color: const Color(0xFF8B7A57),
      ),
      EnemyKind.shieldInfantry => EnemyDefinition(
        kind: kind,
        label: 'Shield Infantry',
        specialDescription: 'Reduces damage from physical towers.',
        hitPoints: (86 * hpMult).round(),
        speed: 34 * speedMult,
        rewardCoins: (10 * rewardMult).round(),
        citadelDamage: 2,
        color: const Color(0xFF7D8EA3),
      ),
      EnemyKind.wolfScout => EnemyDefinition(
        kind: kind,
        label: 'Wolf Scout',
        specialDescription: 'Extreme speed; slips through narrow kill windows.',
        hitPoints: (44 * hpMult).round(),
        speed: 70 * speedMult,
        rewardCoins: (9 * rewardMult).round(),
        citadelDamage: 1,
        color: const Color(0xFF7A6E55),
      ),
      EnemyKind.cultAdept => EnemyDefinition(
        kind: kind,
        label: 'Cult Adept',
        specialDescription: 'Periodically hastes nearby allies.',
        hitPoints: (58 * hpMult).round(),
        speed: 42 * speedMult,
        rewardCoins: (10 * rewardMult).round(),
        citadelDamage: 2,
        color: const Color(0xFF6E4EAA),
      ),
      EnemyKind.bannerCaptain => EnemyDefinition(
        kind: kind,
        label: 'Banner Captain',
        specialDescription: 'Rallies nearby troops, boosting their speed.',
        hitPoints: (148 * hpMult).round(),
        speed: 28 * speedMult,
        rewardCoins: (22 * rewardMult).round(),
        citadelDamage: 3,
        color: const Color(0xFF8B3A3A),
      ),
      _ => EnemyDefinition(
        kind: kind,
        label: kind.name,
        specialDescription: '',
        hitPoints: (60 * hpMult).round(),
        speed: 40 * speedMult,
        rewardCoins: (9 * rewardMult).round(),
        citadelDamage: 1,
        color: const Color(0xFF888888),
      ),
    };
  }
}
