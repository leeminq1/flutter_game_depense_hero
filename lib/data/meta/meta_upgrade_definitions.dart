import 'dart:ui';

import 'package:depense_game/data/persistence/progression_models.dart';

class MetaUpgradeDefinition {
  const MetaUpgradeDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.levelCostMultipliers,
    required this.focusLabel,
    required this.color,
    this.milestoneLevel,
    this.milestoneLabel,
  });

  final String id;
  final String label;
  final String description;
  final int maxLevel;
  final int baseCost;
  final List<double> levelCostMultipliers;
  final String focusLabel;
  final Color color;
  final int? milestoneLevel;
  final String? milestoneLabel;

  int costForLevel(int level) {
    final index = level.clamp(0, levelCostMultipliers.length - 1);
    return (baseCost * levelCostMultipliers[index]).round();
  }
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
      levelCostMultipliers: [1.0, 1.35, 1.8, 2.45, 3.2],
      focusLabel: 'Defense',
      color: Color(0xFFAA7846),
    ),
    MetaUpgradeDefinition(
      id: 'supply_cache',
      label: 'Supply Cache',
      description: 'Start each stage with more build gold.',
      maxLevel: 5,
      baseCost: 85,
      levelCostMultipliers: [1.0, 1.32, 1.75, 2.35, 3.05],
      focusLabel: 'Economy',
      color: Color(0xFF8B9E51),
    ),
    MetaUpgradeDefinition(
      id: 'bow_mastery',
      label: 'Bow Mastery',
      description:
          'Increase archer damage and critical volleys. Unlocks Ballista at level 2.',
      maxLevel: 5,
      baseCost: 100,
      levelCostMultipliers: [1.0, 1.34, 1.9, 2.6, 3.45],
      focusLabel: 'Unlock',
      color: Color(0xFF568C4D),
      milestoneLevel: 2,
      milestoneLabel: 'Ballista unlocked at level 2.',
    ),
    MetaUpgradeDefinition(
      id: 'guard_drill',
      label: 'Guard Drill',
      description: 'Improve barracks damage and stagger duration.',
      maxLevel: 5,
      baseCost: 100,
      levelCostMultipliers: [1.0, 1.3, 1.82, 2.45, 3.2],
      focusLabel: 'Control',
      color: Color(0xFF8B6A56),
      milestoneLevel: 2,
      milestoneLabel: 'Stronger defender line at level 2 pacing.',
    ),
    MetaUpgradeDefinition(
      id: 'arcane_mastery',
      label: 'Arcane Mastery',
      description:
          'Increase mage burst and chain output. Unlocks Emberkeep at level 2.',
      maxLevel: 5,
      baseCost: 110,
      levelCostMultipliers: [1.0, 1.34, 1.88, 2.58, 3.42],
      focusLabel: 'Unlock',
      color: Color(0xFF6D63B8),
      milestoneLevel: 2,
      milestoneLabel: 'Emberkeep unlocked at level 2.',
    ),
    MetaUpgradeDefinition(
      id: 'frost_focus',
      label: 'Frost Focus',
      description: 'Improve frost slow strength and pulse reach.',
      maxLevel: 5,
      baseCost: 100,
      levelCostMultipliers: [1.0, 1.3, 1.8, 2.4, 3.18],
      focusLabel: 'Control',
      color: Color(0xFF4C8E96),
      milestoneLevel: 2,
      milestoneLabel: 'Slows become noticeably stronger at level 2.',
    ),
    MetaUpgradeDefinition(
      id: 'commerce_guild',
      label: 'Commerce Guild',
      description: 'Increase coin mill income and stage rewards.',
      maxLevel: 5,
      baseCost: 108,
      levelCostMultipliers: [1.0, 1.28, 1.72, 2.28, 3.0],
      focusLabel: 'Economy',
      color: Color(0xFFB59344),
      milestoneLevel: 2,
      milestoneLabel: 'Coin Mill economy spikes harder from level 2 onward.',
    ),
  ];

  static MetaUpgradeDefinition byId(String id) {
    return upgrades.firstWhere((upgrade) => upgrade.id == id);
  }

  static String effectSummary(String id, int level) {
    switch (id) {
      case 'stronghold':
        return 'Base HP +${level * 2}';
      case 'supply_cache':
        return 'Starting Coins +${level * 25}';
      case 'bow_mastery':
        final unlockText = level >= 2 ? ' • Ballista unlocked' : '';
        return 'Archer Damage +${level * 12}%$unlockText';
      case 'guard_drill':
        return 'Barracks Damage +${level * 12}% • Stun +${level * 8}%';
      case 'arcane_mastery':
        final unlockText = level >= 2 ? ' • Emberkeep unlocked' : '';
        return 'Mage Damage +${level * 10}%$unlockText';
      case 'frost_focus':
        return 'Slow +${level * 6}% • Range +${level * 8}%';
      case 'commerce_guild':
        return 'Coin Mill Income +$level • Stage Rewards +${level * 8}%';
      default:
        return 'No effect summary available';
    }
  }

  static String nextEffectSummary(String id, int level) {
    final definition = byId(id);
    if (level >= definition.maxLevel) {
      return 'Maxed';
    }
    return effectSummary(id, level + 1);
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
