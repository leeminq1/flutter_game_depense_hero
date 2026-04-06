import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/game_collection_models.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/sample/sample_campaign.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/models/stage_definition.dart';

/// In-memory implementation of the progress store for web platform.
/// Mirrors the public API of [LocalProgressStore] without Isar dependency.
class InMemoryProgressStore {
  InMemoryProgressStore._();

  late PlayerProfile _profile;
  final Map<int, StageProgressRecord> _stageRecords = {};
  late GameSettingsRecord _settings;
  final Map<String, RewardClaimRecord> _rewardClaims = {};
  final Map<String, UpgradeNodeRecord> _upgradeNodes = {};

  static Future<InMemoryProgressStore> open() async {
    final store = InMemoryProgressStore._();
    store._seed();
    return store;
  }

  void _seed() {
    final now = DateTime.now();
    _profile = PlayerProfile()
      ..id = 1
      ..createdAt = now
      ..lastPlayedAt = now
      ..accountLevel = 1
      ..totalXp = 0
      ..softCurrency = 0
      ..premiumCurrency = 0;

    _settings = GameSettingsRecord()
      ..id = 1
      ..masterVolume = 0.85
      ..musicVolume = 0.55
      ..sfxVolume = 0.90
      ..muted = false
      ..tutorialDismissed = false;

    _stageRecords[1] = StageProgressRecord()
      ..id = 1
      ..stageNumber = 1
      ..unlocked = true
      ..stars = 0;
  }

  Future<GameSettingsRecord> loadOrCreateSettings() async {
    return _settings;
  }

  Future<void> saveAudioSettings(AudioSettingsController controller) async {
    _settings
      ..masterVolume = controller.masterVolume
      ..musicVolume = controller.musicVolume
      ..sfxVolume = controller.sfxVolume
      ..muted = controller.muted;
  }

  Future<bool> isTutorialDismissed() async {
    return _settings.tutorialDismissed;
  }

  Future<void> setTutorialDismissed(bool dismissed) async {
    _settings.tutorialDismissed = dismissed;
  }

  Future<void> resetCampaignProgress() async {
    final masterVolume = _settings.masterVolume;
    final musicVolume = _settings.musicVolume;
    final sfxVolume = _settings.sfxVolume;
    final muted = _settings.muted;

    _stageRecords.clear();
    _rewardClaims.clear();
    _upgradeNodes.clear();
    _seed();
    _settings
      ..masterVolume = masterVolume
      ..musicVolume = musicVolume
      ..sfxVolume = sfxVolume
      ..muted = muted
      ..tutorialDismissed = false;
  }

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
      final definition = SampleCampaign.stage(stageNumber);
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
        objectives:
            definition.objectives.map((objective) => objective.label).toList(),
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
      ),
      stages: stages,
      metaUpgrades: metaUpgrades,
    );
  }

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
    final starUpgradeBonusAwarded =
        newStarsEarned > 0 ? newStarsEarned * (6 + (stageNumber ~/ 3)) : 0;
    final crestBonusAwarded =
        isFirstClear && stageNumber % 5 == 0 ? 30 + (stageNumber * 3) : 0;
    final softCurrencyAwarded = baseSoftCurrencyAwarded +
        firstClearBonusAwarded +
        starUpgradeBonusAwarded +
        crestBonusAwarded;

    _profile.lastPlayedAt = DateTime.now();
    _profile.totalXp += xpAwarded;
    _profile.softCurrency += softCurrencyAwarded;
    _profile.accountLevel = 1 + (_profile.totalXp ~/ 150);

    final record =
        existingRecord ?? (StageProgressRecord()..stageNumber = stageNumber);
    record.unlocked = true;
    record.stars = starsAwarded > record.stars ? starsAwarded : record.stars;
    record.firstClearedAt ??= DateTime.now();
    record.lastClearedAt = DateTime.now();
    _stageRecords[stageNumber] = record;

    int? unlockedNextStage;
    if (stageNumber < totalStages) {
      final totalAccumulatedStars = _stageRecords.values.fold<int>(
        0,
        (sum, r) => sum + r.stars,
      );
      final metaUpgrades = _loadMetaUpgrades();
      final nextStage = SampleCampaign.stage(stageNumber + 1);
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
      totalStars: record.stars,
      xpAwarded: xpAwarded,
      baseSoftCurrencyAwarded: baseSoftCurrencyAwarded,
      firstClearBonusAwarded: firstClearBonusAwarded,
      starUpgradeBonusAwarded: starUpgradeBonusAwarded,
      crestBonusAwarded: crestBonusAwarded,
      softCurrencyAwarded: softCurrencyAwarded,
      unlockedNextStage: unlockedNextStage,
      objectives: [
        for (final result in evaluation.objectiveResults)
          ObjectiveCompletionSnapshot(
            label: result.definition.label,
            completed: result.completed,
          ),
      ],
    );
  }

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
    _rewardClaims[claimKey] = RewardClaimRecord()
      ..claimKey = claimKey
      ..sourceType = 'rewarded_stage_bonus'
      ..stageNumber = stageNumber
      ..amount = amount
      ..grantedAt = DateTime.now();

    return RewardClaimResult(
      claimedNow: true,
      amountAwarded: amount,
      totalSoftCurrency: _profile.softCurrency,
    );
  }

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

  Future<ResolvedMetaUpgrades> loadResolvedMetaUpgrades() async {
    return MetaUpgradeCatalog.resolve(_loadMetaUpgrades());
  }

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
    final record = existing ?? (UpgradeNodeRecord()..nodeId = nodeId);
    record.level = currentLevel + 1;
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
    required Map<int, StageProgressRecord> byStage,
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

    return _UnlockCheck(
      unlocked: false,
      lockReason: '이전 스테이지를 클리어하면 해금됩니다.',
    );
  }
}

class _UnlockCheck {
  const _UnlockCheck({required this.unlocked, required this.lockReason});

  final bool unlocked;
  final String? lockReason;
}
