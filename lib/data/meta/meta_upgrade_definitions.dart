import 'dart:ui';

import 'package:depense_game/data/persistence/progression_models.dart';

class MetaUpgradeDefinition {
  const MetaUpgradeDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.color,
  });

  final String id;
  final String label;
  final String description;
  final int maxLevel;
  final int baseCost;
  final Color color;

  int costForLevel(int level) => (baseCost * (1 + (level * 0.65))).round();
}

class ResolvedMetaUpgrades {
  const ResolvedMetaUpgrades({
    this.strongholdLevel = 0,
    this.supplyCacheLevel = 0,
    this.bowMasteryLevel = 0,
    this.guardDrillLevel = 0,
    this.arcaneMasteryLevel = 0,
    this.frostFocusLevel = 0,
    this.commerceGuildLevel = 0,
    this.bonusBaseHealth = 0,
    this.bonusStartingCoins = 0,
    this.archerDamageMultiplier = 1,
    this.barracksDamageMultiplier = 1,
    this.barracksStunBonus = 0,
    this.mageDamageMultiplier = 1,
    this.frostSlowBonus = 0,
    this.frostRangeMultiplier = 1,
    this.coinMillIncomeBonus = 0,
    this.stageRewardMultiplier = 1,
    this.ballistaUnlocked = false,
    this.emberkeepUnlocked = false,
  });

  final int strongholdLevel;
  final int supplyCacheLevel;
  final int bowMasteryLevel;
  final int guardDrillLevel;
  final int arcaneMasteryLevel;
  final int frostFocusLevel;
  final int commerceGuildLevel;
  final int bonusBaseHealth;
  final int bonusStartingCoins;
  final double archerDamageMultiplier;
  final double barracksDamageMultiplier;
  final double barracksStunBonus;
  final double mageDamageMultiplier;
  final double frostSlowBonus;
  final double frostRangeMultiplier;
  final int coinMillIncomeBonus;
  final double stageRewardMultiplier;
  final bool ballistaUnlocked;
  final bool emberkeepUnlocked;
}

class MetaUpgradeCatalog {
  static const List<MetaUpgradeDefinition> upgrades = [
    MetaUpgradeDefinition(
      id: 'stronghold',
      label: 'Stronghold Masonry',
      description: 'Increase base durability for every stage.',
      maxLevel: 5,
      baseCost: 90,
      color: Color(0xFFAA7846),
    ),
    MetaUpgradeDefinition(
      id: 'supply_cache',
      label: 'Supply Cache',
      description: 'Start each stage with more build gold.',
      maxLevel: 5,
      baseCost: 85,
      color: Color(0xFF8B9E51),
    ),
    MetaUpgradeDefinition(
      id: 'bow_mastery',
      label: 'Bow Mastery',
      description: 'Increase archer damage and critical volleys. Unlocks Ballista at level 2.',
      maxLevel: 5,
      baseCost: 100,
      color: Color(0xFF568C4D),
    ),
    MetaUpgradeDefinition(
      id: 'guard_drill',
      label: 'Guard Drill',
      description: 'Improve barracks damage and stagger duration.',
      maxLevel: 5,
      baseCost: 100,
      color: Color(0xFF8B6A56),
    ),
    MetaUpgradeDefinition(
      id: 'arcane_mastery',
      label: 'Arcane Mastery',
      description: 'Increase mage burst and chain output. Unlocks Emberkeep at level 2.',
      maxLevel: 5,
      baseCost: 110,
      color: Color(0xFF6D63B8),
    ),
    MetaUpgradeDefinition(
      id: 'frost_focus',
      label: 'Frost Focus',
      description: 'Improve frost slow strength and pulse reach.',
      maxLevel: 5,
      baseCost: 100,
      color: Color(0xFF4C8E96),
    ),
    MetaUpgradeDefinition(
      id: 'commerce_guild',
      label: 'Commerce Guild',
      description: 'Increase coin mill income and stage rewards.',
      maxLevel: 5,
      baseCost: 120,
      color: Color(0xFFB59344),
    ),
  ];

  static MetaUpgradeDefinition byId(String id) {
    return upgrades.firstWhere((upgrade) => upgrade.id == id);
  }

  static ResolvedMetaUpgrades resolve(List<MetaUpgradeSnapshot> snapshots) {
    final levelById = {
      for (final upgrade in snapshots) upgrade.id: upgrade.level,
    };
    final stronghold = levelById['stronghold'] ?? 0;
    final supplyCache = levelById['supply_cache'] ?? 0;
    final bowMastery = levelById['bow_mastery'] ?? 0;
    final guardDrill = levelById['guard_drill'] ?? 0;
    final arcaneMastery = levelById['arcane_mastery'] ?? 0;
    final frostFocus = levelById['frost_focus'] ?? 0;
    final commerceGuild = levelById['commerce_guild'] ?? 0;

    return ResolvedMetaUpgrades(
      strongholdLevel: stronghold,
      supplyCacheLevel: supplyCache,
      bowMasteryLevel: bowMastery,
      guardDrillLevel: guardDrill,
      arcaneMasteryLevel: arcaneMastery,
      frostFocusLevel: frostFocus,
      commerceGuildLevel: commerceGuild,
      bonusBaseHealth: stronghold * 2,
      bonusStartingCoins: supplyCache * 25,
      archerDamageMultiplier: 1 + (bowMastery * 0.12),
      barracksDamageMultiplier: 1 + (guardDrill * 0.12),
      barracksStunBonus: guardDrill * 0.08,
      mageDamageMultiplier: 1 + (arcaneMastery * 0.10),
      frostSlowBonus: frostFocus * 0.06,
      frostRangeMultiplier: 1 + (frostFocus * 0.08),
      coinMillIncomeBonus: commerceGuild,
      stageRewardMultiplier: 1 + (commerceGuild * 0.08),
      ballistaUnlocked: bowMastery >= 2,
      emberkeepUnlocked: arcaneMastery >= 2,
    );
  }
}
