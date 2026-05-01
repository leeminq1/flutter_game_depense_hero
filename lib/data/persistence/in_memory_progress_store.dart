import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'dart:math' as math;

import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/persistence/siege_reward_formulas.dart';
import 'package:depense_game/data/persistence/store_models.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/models/stage_definition.dart';

/// In-memory implementation of the progress store for web platform.
class InMemoryProgressStore implements ProgressStore {
  InMemoryProgressStore._();

  late _ProfileSnapshot _profile;
  final Map<int, _StageRecordSnapshot> _stageRecords = {};
  late AudioSettingsSnapshot _settings;
  final Map<String, _RewardClaimSnapshot> _rewardClaims = {};
  final Map<String, _UpgradeNodeSnapshot> _upgradeNodes = {};

  static Future<InMemoryProgressStore> open() async {
    final store = InMemoryProgressStore._();
    store._seed();
    return store;
  }

  void _seed() {
    final now = DateTime.now();
    _profile = _ProfileSnapshot(
      createdAt: now,
      lastPlayedAt: now,
      accountLevel: 1,
      totalXp: 0,
      softCurrency: 0,
      premiumCurrency: 0,
      siegeTokens: 0,
    );

    _settings = const AudioSettingsSnapshot(
      masterVolume: 0.85,
      musicVolume: 0.55,
      sfxVolume: 0.90,
      muted: false,
      tutorialDismissed: false,
    );

    _stageRecords[1] = const _StageRecordSnapshot(
      stageNumber: 1,
      unlocked: true,
      stars: 0,
    );
  }

  @override
  Future<AudioSettingsSnapshot> loadAudioSettings() async {
    return _settings;
  }

  @override
  Future<void> saveAudioSettings(AudioSettingsController controller) async {
    _settings = AudioSettingsSnapshot(
      masterVolume: controller.masterVolume,
      musicVolume: controller.musicVolume,
      sfxVolume: controller.sfxVolume,
      muted: controller.muted,
      tutorialDismissed: _settings.tutorialDismissed,
    );
  }

  @override
  Future<bool> isTutorialDismissed() async {
    return _settings.tutorialDismissed;
  }

  @override
  Future<void> setTutorialDismissed(bool dismissed) async {
    _settings = AudioSettingsSnapshot(
      masterVolume: _settings.masterVolume,
      musicVolume: _settings.musicVolume,
      sfxVolume: _settings.sfxVolume,
      muted: _settings.muted,
      tutorialDismissed: dismissed,
    );
  }

  @override
  Future<void> resetCampaignProgress() async {
    final masterVolume = _settings.masterVolume;
    final musicVolume = _settings.musicVolume;
    final sfxVolume = _settings.sfxVolume;
    final muted = _settings.muted;

    _stageRecords.clear();
    _rewardClaims.clear();
    _upgradeNodes.clear();
    _seed();
    _settings = AudioSettingsSnapshot(
      masterVolume: masterVolume,
      musicVolume: musicVolume,
      sfxVolume: sfxVolume,
      muted: muted,
      tutorialDismissed: false,
    );
  }

  @override
  Future<CampaignOverview> loadCampaignOverview({
    required int totalStages,
  }) async {
    final metaUpgrades = _loadMetaUpgrades();
    final totalStars = _stageRecords.values.fold<int>(
      0,
      (sum, record) => sum + record.stars,
    );

    final stages = List<StageProgressSnapshot>.generate(totalStages, (index) {
      final stageNumber = index + 1;
      final record = _stageRecords[stageNumber];
      final definition = CampaignData.stage(stageNumber);
      final unlockCheck = _checkStageUnlocked(
        stage: definition,
        byStage: _stageRecords,
        totalStars: totalStars,
        metaUpgrades: metaUpgrades,
      );
      return StageProgressSnapshot(
        stageNumber: stageNumber,
        unlocked: unlockCheck.unlocked,
        stars: record?.stars ?? 0,
        cleared: (record?.stars ?? 0) > 0,
        description: definition.description,
        objectives: definition.objectives
            .map((objective) => objective.label)
            .toList(),
        unlockRequirementLabels: definition.unlockRequirements
            .map((requirement) => requirement.label)
            .toList(),
        lockReason: unlockCheck.lockReason,
      );
    });

    var currentCampaignStage = 1;
    for (final stage in stages) {
      if (stage.unlocked && !stage.cleared) {
        currentCampaignStage = stage.stageNumber;
        break;
      }
      if (stage.unlocked) {
        currentCampaignStage = stage.stageNumber;
      }
    }

    final hasMeaningfulProgress =
        _profile.totalXp > 0 ||
        _profile.softCurrency > 0 ||
        _stageRecords.values.any((record) => record.stars > 0) ||
        metaUpgrades.any((upgrade) => upgrade.level > 0);
    final clearedStageCount = _stageRecords.values
        .where((record) => record.stars > 0)
        .length;

    return CampaignOverview(
      player: PlayerProgressSnapshot(
        accountLevel: _profile.accountLevel,
        totalXp: _profile.totalXp,
        softCurrency: _profile.softCurrency,
        premiumCurrency: _profile.premiumCurrency,
        currentCampaignStage: currentCampaignStage,
        clearedStageCount: clearedStageCount,
        hasResumableRun: hasMeaningfulProgress,
        siegeTokens: _profile.siegeTokens,
      ),
      stages: stages,
      metaUpgrades: metaUpgrades,
    );
  }

  @override
  Future<StageCompletionResult> recordStageCompletion({
    required int stageNumber,
    required StageEvaluationResult evaluation,
    required int totalStages,
  }) async {
    final starsAwarded = evaluation.starsAwarded;
    final xpAwarded = (stageNumber * 12) + (starsAwarded * 8);
    final metaEffects = await loadResolvedMetaUpgrades();
    final existingRecord = _stageRecords[stageNumber];
    final previousStars = existingRecord?.stars ?? 0;
    final isFirstClear = existingRecord?.firstClearedAt == null;
    final newStarsEarned = (starsAwarded - previousStars).clamp(0, 3);
    final stageBandRewardMultiplier = switch (stageNumber) {
      >= 6 && <= 10 => 1.12,
      >= 11 && <= 15 => 1.16,
      >= 16 && <= 20 => 1.20,
      >= 21 && <= 25 => 1.24,
      >= 26 && <= 30 => 1.28,
      _ => 1.0,
    };
    final baseSoftCurrencyAwarded =
        (((stageNumber * 18) + (starsAwarded * 7)) *
                metaEffects.stageRewardMultiplier *
                stageBandRewardMultiplier)
            .round();
    final firstClearBonusAwarded = isFirstClear ? 18 + (stageNumber * 4) : 0;
    final starUpgradeBonusAwarded = newStarsEarned > 0
        ? newStarsEarned * (6 + (stageNumber ~/ 3))
        : 0;
    final crestBonusAwarded = isFirstClear && stageNumber % 5 == 0
        ? 30 + (stageNumber * 3)
        : 0;
    final softCurrencyAwarded =
        baseSoftCurrencyAwarded +
        firstClearBonusAwarded +
        starUpgradeBonusAwarded +
        crestBonusAwarded;

    final isCleared = starsAwarded > 0;

    // Siege Tokens: only on clear, never on failure.
    // hp/mastery objective detection uses starsAwarded level as proxy until
    // StageEvaluationResult carries explicit objective flags.
    final hpObjectiveMet = isCleared && starsAwarded >= 2;
    final masteryObjectiveMet = isCleared && starsAwarded >= 3;
    final tokensEarned = SiegeRewardFormulas.computeSiegeTokensEarned(
      cleared: isCleared,
      hpObjectiveMet: hpObjectiveMet,
      masteryObjectiveMet: masteryObjectiveMet,
    );

    _profile.lastPlayedAt = DateTime.now();
    _profile.totalXp += xpAwarded;
    _profile.softCurrency += softCurrencyAwarded;
    _profile.siegeTokens += tokensEarned;
    _profile.accountLevel = 1 + (_profile.totalXp ~/ 150);

    final record =
        existingRecord ??
        _StageRecordSnapshot(
          stageNumber: stageNumber,
          unlocked: true,
          stars: 0,
        );
    final updatedRecord = record.copyWith(
      unlocked: true,
      stars: starsAwarded > 0
          ? math.max(starsAwarded, record.stars)
          : record.stars,
      firstClearedAt: isCleared
          ? record.firstClearedAt ?? DateTime.now()
          : record.firstClearedAt,
      lastClearedAt: isCleared ? DateTime.now() : record.lastClearedAt,
    );
    _stageRecords[stageNumber] = updatedRecord;
    if (isCleared && stageNumber < totalStages) {
      final existingNext = _stageRecords[stageNumber + 1];
      _stageRecords[stageNumber + 1] =
          existingNext?.copyWith(unlocked: true) ??
          _StageRecordSnapshot(
            stageNumber: stageNumber + 1,
            unlocked: true,
            stars: 0,
          );
    }

    int? unlockedNextStage;
    if (stageNumber < totalStages) {
      final totalAccumulatedStars = _stageRecords.values.fold<int>(
        0,
        (sum, r) => sum + r.stars,
      );
      final metaUpgrades = _loadMetaUpgrades();
      final nextStage = CampaignData.stage(stageNumber + 1);
      final unlocked = _checkStageUnlocked(
        stage: nextStage,
        byStage: _stageRecords,
        totalStars: totalAccumulatedStars,
        metaUpgrades: metaUpgrades,
      );
      if (unlocked.unlocked) {
        unlockedNextStage = stageNumber + 1;
      }
    }

    return StageCompletionResult(
      stageNumber: stageNumber,
      starsAwarded: starsAwarded,
      totalStars: updatedRecord.stars,
      xpAwarded: xpAwarded,
      baseSoftCurrencyAwarded: baseSoftCurrencyAwarded,
      firstClearBonusAwarded: firstClearBonusAwarded,
      starUpgradeBonusAwarded: starUpgradeBonusAwarded,
      crestBonusAwarded: crestBonusAwarded,
      softCurrencyAwarded: softCurrencyAwarded,
      unlockedNextStage: unlockedNextStage,
      siegeTokensEarned: tokensEarned,
      siegeTokensTotal: _profile.siegeTokens,
      isFailureReward: !isCleared,
      objectives: [
        for (final result in evaluation.objectiveResults)
          ObjectiveCompletionSnapshot(
            label: result.definition.label,
            completed: result.completed,
          ),
      ],
    );
  }

  @override
  Future<RewardClaimResult> claimStageClearBonus({
    required int stageNumber,
    required int amount,
  }) async {
    final claimKey = 'stage_bonus_$stageNumber';
    if (_rewardClaims.containsKey(claimKey)) {
      return RewardClaimResult(
        claimedNow: false,
        amountAwarded: 0,
        totalSoftCurrency: _profile.softCurrency,
      );
    }

    _profile.softCurrency += amount;
    _rewardClaims[claimKey] = _RewardClaimSnapshot(
      claimKey: claimKey,
      sourceType: 'rewarded_stage_bonus',
      stageNumber: stageNumber,
      amount: amount,
      grantedAt: DateTime.now(),
    );

    return RewardClaimResult(
      claimedNow: true,
      amountAwarded: amount,
      totalSoftCurrency: _profile.softCurrency,
    );
  }

  @override
  Future<bool> hasClaimedStageClearBonus(int stageNumber) async {
    return _rewardClaims.containsKey('stage_bonus_$stageNumber');
  }

  List<MetaUpgradeSnapshot> _loadMetaUpgrades() {
    return [
      for (final definition in MetaUpgradeCatalog.upgrades)
        MetaUpgradeSnapshot(
          id: definition.id,
          level: _upgradeNodes[definition.id]?.level ?? 0,
        ),
    ];
  }

  @override
  Future<ResolvedMetaUpgrades> loadResolvedMetaUpgrades() async {
    return MetaUpgradeCatalog.resolve(_loadMetaUpgrades());
  }

  @override
  Future<MetaUpgradePurchaseResult> purchaseMetaUpgrade(String nodeId) async {
    final definition = MetaUpgradeCatalog.byId(nodeId);
    final existing = _upgradeNodes[nodeId];
    final currentLevel = existing?.level ?? 0;

    if (currentLevel >= definition.maxLevel) {
      return MetaUpgradePurchaseResult(
        purchased: false,
        newLevel: currentLevel,
        remainingCurrency: _profile.softCurrency,
        message: '${definition.label}은(는) 이미 최대 레벨입니다.',
      );
    }

    final cost = definition.costForLevel(currentLevel);
    if (_profile.softCurrency < cost) {
      return MetaUpgradePurchaseResult(
        purchased: false,
        newLevel: currentLevel,
        remainingCurrency: _profile.softCurrency,
        message: '${definition.label} 업그레이드에는 메타 골드 $cost이(가) 필요합니다.',
      );
    }

    _profile.softCurrency -= cost;
    final record = (existing ?? _UpgradeNodeSnapshot(nodeId: nodeId, level: 0))
        .copyWith(level: currentLevel + 1);
    _upgradeNodes[nodeId] = record;

    return MetaUpgradePurchaseResult(
      purchased: true,
      newLevel: record.level,
      remainingCurrency: _profile.softCurrency,
      message: '${definition.label}이(가) 레벨 ${record.level}(으)로 강화되었습니다.',
    );
  }

  _UnlockCheck _checkStageUnlocked({
    required StageDefinition stage,
    required Map<int, _StageRecordSnapshot> byStage,
    required int totalStars,
    required List<MetaUpgradeSnapshot> metaUpgrades,
  }) {
    if (stage.number == 1) {
      return const _UnlockCheck(unlocked: true, lockReason: null);
    }
    final existingRecord = byStage[stage.number];
    if (existingRecord?.unlocked == true) {
      return const _UnlockCheck(unlocked: true, lockReason: null);
    }

    final previousStage = byStage[stage.number - 1];
    final previousCleared = (previousStage?.stars ?? 0) > 0;
    if (previousCleared) {
      return const _UnlockCheck(unlocked: true, lockReason: null);
    }

    return _UnlockCheck(unlocked: false, lockReason: '이전 스테이지를 클리어하면 해금됩니다.');
  }
}

class _UnlockCheck {
  const _UnlockCheck({required this.unlocked, required this.lockReason});

  final bool unlocked;
  final String? lockReason;
}

class _ProfileSnapshot {
  _ProfileSnapshot({
    required this.createdAt,
    required this.lastPlayedAt,
    required this.accountLevel,
    required this.totalXp,
    required this.softCurrency,
    required this.premiumCurrency,
    this.siegeTokens = 0,
  });

  final DateTime createdAt;
  DateTime lastPlayedAt;
  int accountLevel;
  int totalXp;
  int softCurrency;
  int premiumCurrency;
  int siegeTokens;
}

class _StageRecordSnapshot {
  const _StageRecordSnapshot({
    required this.stageNumber,
    required this.unlocked,
    required this.stars,
    this.firstClearedAt,
    this.lastClearedAt,
  });

  final int stageNumber;
  final bool unlocked;
  final int stars;
  final DateTime? firstClearedAt;
  final DateTime? lastClearedAt;

  _StageRecordSnapshot copyWith({
    bool? unlocked,
    int? stars,
    DateTime? firstClearedAt,
    DateTime? lastClearedAt,
  }) {
    return _StageRecordSnapshot(
      stageNumber: stageNumber,
      unlocked: unlocked ?? this.unlocked,
      stars: stars ?? this.stars,
      firstClearedAt: firstClearedAt ?? this.firstClearedAt,
      lastClearedAt: lastClearedAt ?? this.lastClearedAt,
    );
  }
}

class _RewardClaimSnapshot {
  const _RewardClaimSnapshot({
    required this.claimKey,
    required this.sourceType,
    required this.stageNumber,
    required this.amount,
    required this.grantedAt,
  });

  final String claimKey;
  final String sourceType;
  final int stageNumber;
  final int amount;
  final DateTime grantedAt;
}

class _UpgradeNodeSnapshot {
  const _UpgradeNodeSnapshot({required this.nodeId, required this.level});

  final String nodeId;
  final int level;

  _UpgradeNodeSnapshot copyWith({int? level}) {
    return _UpgradeNodeSnapshot(nodeId: nodeId, level: level ?? this.level);
  }
}
