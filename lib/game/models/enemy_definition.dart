import 'dart:ui';

const double _structureDamageBalanceMultiplier = 0.7;

enum EnemyKind {
  raider,
  scout,
  bannerCaptain,
  wolfScout,
  shieldInfantry,
  cultAdept,
  skeleton,
  boneArcher,
  graveGuard,
  plagueBearer,
  corruptedKnight,
  hexSniper,
  warlock,
  bastionPriest,
  bastionOverlord,
}

enum EnemyWallBehavior { rerouteFirst, mixedBreaker, forceBreaker }

class EnemyDefinition {
  const EnemyDefinition({
    required this.kind,
    required this.label,
    required this.specialDescription,
    required this.hitPoints,
    required this.speed,
    required this.rewardCoins,
    required this.citadelDamage,
    required this.color,
    this.structureDamage,
    this.towerContactDamage,
    this.citadelLeakDamage = 1,
    this.structureAttackCooldown = 1.2,
    this.canBreachWalls = true,
    EnemyWallBehavior? wallBehavior,
    double? wallBreakChance,
  }) : _wallBehavior = wallBehavior,
       _wallBreakChance = wallBreakChance;

  final EnemyKind kind;
  final String label;
  final String specialDescription;
  final int hitPoints;
  final double speed;
  final int rewardCoins;
  final int citadelDamage;
  final Color color;
  final int? structureDamage;
  final int? towerContactDamage;
  final int citadelLeakDamage;
  final double structureAttackCooldown;
  final bool canBreachWalls;
  final EnemyWallBehavior? _wallBehavior;
  final double? _wallBreakChance;

  int get baseDamage => citadelDamage;
  EnemyWallBehavior get wallBehavior =>
      _wallBehavior ?? defaultWallBehaviorFor(kind);
  double get wallBreakChance =>
      _wallBreakChance ?? defaultWallBreakChanceFor(kind);
  int get baseStructureDamage => _balancedStructureDamage(
    structureDamage ?? defaultStructureDamageFor(kind),
  );
  int get baseTowerContactDamage =>
      towerContactDamage ?? defaultTowerContactDamageFor(kind);

  static int _balancedStructureDamage(int damage) {
    return (damage * _structureDamageBalanceMultiplier).round().clamp(1, damage);
  }

  static EnemyWallBehavior defaultWallBehaviorFor(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.scout ||
      EnemyKind.wolfScout ||
      EnemyKind.boneArcher ||
      EnemyKind.hexSniper => EnemyWallBehavior.rerouteFirst,
      EnemyKind.shieldInfantry ||
      EnemyKind.graveGuard ||
      EnemyKind.corruptedKnight ||
      EnemyKind.bastionOverlord => EnemyWallBehavior.forceBreaker,
      _ => EnemyWallBehavior.mixedBreaker,
    };
  }

  static double defaultWallBreakChanceFor(EnemyKind kind) {
    return switch (defaultWallBehaviorFor(kind)) {
      EnemyWallBehavior.rerouteFirst => 0,
      EnemyWallBehavior.mixedBreaker => 0.7,
      EnemyWallBehavior.forceBreaker => 1,
    };
  }

  static int defaultStructureDamageFor(EnemyKind kind) {
    return switch (defaultWallBehaviorFor(kind)) {
      EnemyWallBehavior.rerouteFirst => 10,
      EnemyWallBehavior.mixedBreaker => 28,
      EnemyWallBehavior.forceBreaker => switch (kind) {
        EnemyKind.bastionOverlord => 72,
        EnemyKind.corruptedKnight || EnemyKind.graveGuard => 52,
        _ => 42,
      },
    };
  }

  static int defaultTowerContactDamageFor(EnemyKind kind) {
    return switch (defaultWallBehaviorFor(kind)) {
      EnemyWallBehavior.rerouteFirst => 8,
      EnemyWallBehavior.mixedBreaker => 22,
      EnemyWallBehavior.forceBreaker => switch (kind) {
        EnemyKind.bastionOverlord => 90,
        EnemyKind.corruptedKnight || EnemyKind.graveGuard => 58,
        _ => 42,
      },
    };
  }
}
