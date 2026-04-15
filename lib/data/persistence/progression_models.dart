import 'package:collection/collection.dart';

class MetaUpgradeSnapshot {
  const MetaUpgradeSnapshot({required this.id, required this.level});

  final String id;
  final int level;
}

class PlayerProgressSnapshot {
  const PlayerProgressSnapshot({
    required this.accountLevel,
    required this.totalXp,
    required this.softCurrency,
    required this.premiumCurrency,
    this.currentCampaignStage = 1,
    this.clearedStageCount = 0,
    this.hasResumableRun = false,
    // Meta Gold is the runtime alias for softCurrency (economy spec).
    // Siege Tokens are the durable milestone reward currency.
    this.siegeTokens = 0,
  });

  final int accountLevel;
  final int totalXp;
  /// In-game Meta Gold balance (maps to [softCurrency] internally).
  final int softCurrency;
  final int premiumCurrency;
  final int currentCampaignStage;
  final int clearedStageCount;
  final bool hasResumableRun;
  /// Total unspent Siege Tokens held by the player.
  final int siegeTokens;
}

class StageProgressSnapshot {
  const StageProgressSnapshot({
    required this.stageNumber,
    required this.unlocked,
    required this.stars,
    required this.cleared,
    required this.description,
    required this.objectives,
    required this.unlockRequirementLabels,
    this.lockReason,
  });

  final int stageNumber;
  final bool unlocked;
  final int stars;
  final bool cleared;
  final String description;
  final List<String> objectives;
  final List<String> unlockRequirementLabels;
  final String? lockReason;
}

class CampaignOverview {
  const CampaignOverview({
    required this.player,
    required this.stages,
    required this.metaUpgrades,
  });

  final PlayerProgressSnapshot player;
  final List<StageProgressSnapshot> stages;
  final List<MetaUpgradeSnapshot> metaUpgrades;

  bool get hasMeaningfulProgress => 
    player.clearedStageCount > 0 || metaUpgrades.any((u) => u.level > 0);

  int get totalStars => stages.fold(0, (sum, s) => sum + s.stars);

  int get currentCampaignStage => player.currentCampaignStage;

  StageProgressSnapshot? get recommendedStage {
    return stages.firstWhereOrNull((s) => s.unlocked && !s.cleared) ?? 
           stages.firstWhereOrNull((s) => s.unlocked);
  }
}

class StageCompletionResult {
  const StageCompletionResult({
    required this.stageNumber,
    required this.starsAwarded,
    required this.totalStars,
    required this.xpAwarded,
    required this.baseSoftCurrencyAwarded,
    required this.firstClearBonusAwarded,
    required this.starUpgradeBonusAwarded,
    required this.crestBonusAwarded,
    required this.softCurrencyAwarded,
    required this.unlockedNextStage,
    required this.objectives,
    this.siegeTokensEarned = 0,
    this.siegeTokensTotal = 0,
    this.isFailureReward = false,
  });

  final int stageNumber;
  final int starsAwarded;
  final int totalStars;
  final int xpAwarded;
  final int baseSoftCurrencyAwarded;
  final int firstClearBonusAwarded;
  final int starUpgradeBonusAwarded;
  final int crestBonusAwarded;
  final int softCurrencyAwarded;
  final int? unlockedNextStage;
  final List<ObjectiveCompletionSnapshot> objectives;

  /// Siege Tokens earned from this siege result (0 on failure, 1–3 on clear).
  final int siegeTokensEarned;

  /// Player's total Siege Token balance after this result.
  final int siegeTokensTotal;

  /// True when this result was recorded for a failed siege (partial reward).
  final bool isFailureReward;

  /// Convenience: starsAwarded > 0 means a successful clear.
  bool get isCleared => starsAwarded > 0;
}

class ObjectiveCompletionSnapshot {
  const ObjectiveCompletionSnapshot({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;
}

class RewardClaimResult {
  const RewardClaimResult({
    required this.claimedNow,
    required this.amountAwarded,
    required this.totalSoftCurrency,
  });

  final bool claimedNow;
  final int amountAwarded;
  final int totalSoftCurrency;
}

class MetaUpgradePurchaseResult {
  const MetaUpgradePurchaseResult({
    required this.purchased,
    required this.newLevel,
    required this.remainingCurrency,
    required this.message,
  });

  final bool purchased;
  final int newLevel;
  final int remainingCurrency;
  final String message;
}

typedef SiegeCompletionResult = StageCompletionResult;
