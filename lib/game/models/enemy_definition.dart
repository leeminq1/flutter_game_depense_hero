import 'dart:ui';

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
    this.structureAttackCooldown = 1.2,
    this.canBreachWalls = true,
  });

  final EnemyKind kind;
  final String label;
  final String specialDescription;
  final int hitPoints;
  final double speed;
  final int rewardCoins;
  final int citadelDamage;
  final Color color;
  final int? structureDamage;
  final double structureAttackCooldown;
  final bool canBreachWalls;

  int get baseDamage => citadelDamage;
  int get baseStructureDamage => structureDamage ?? (citadelDamage * 8);
}
