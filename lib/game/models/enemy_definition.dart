import 'dart:ui';

enum EnemyKind {
  raider,
  scout,
  shieldInfantry,
  cultAdept,
  skeleton,
  graveGuard,
  corruptedKnight,
  warlock,
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
    required this.baseDamage,
    required this.color,
  });

  final EnemyKind kind;
  final String label;
  final String specialDescription;
  final int hitPoints;
  final double speed;
  final int rewardCoins;
  final int baseDamage;
  final Color color;
}
