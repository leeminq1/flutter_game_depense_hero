import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/game_collection_models.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/sample/sample_campaign.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class LocalProgressStore {
  LocalProgressStore._(this.isar);

  final Isar isar;

  static Future<LocalProgressStore> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final instance = await Isar.open(
      [
        PlayerProfileSchema,
        StageProgressRecordSchema,
        GameSettingsRecordSchema,
        RewardClaimRecordSchema,
        UpgradeNodeRecordSchema,
      ],
      directory: directory.path,
      name: 'depense_game_db',
    );

    final store = LocalProgressStore._(instance);
    await store._seedIfNeeded();
    return store;
  }

  Future<void> _seedIfNeeded() async {
    final settings = await isar.gameSettingsRecords.get(1);
    if (settings != null) {
      return;
    }

    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.playerProfiles.put(
        PlayerProfile()
          ..createdAt = now
          ..lastPlayedAt = now
          ..accountLevel = 1
          ..totalXp = 0
          ..softCurrency = 0
          ..premiumCurrency = 0,
      );

      await isar.gameSettingsRecords.put(
        GameSettingsRecord()
          ..masterVolume = 0.85
          ..musicVolume = 0.55
          ..sfxVolume = 0.90
          ..muted = false,
      );

      await isar.stageProgressRecords.put(
        StageProgressRecord()
          ..stageNumber = 1
          ..unlocked = true
          ..stars = 0,
      );
    });
  }

  Future<GameSettingsRecord> loadOrCreateSettings() async {
    final settings = await isar.gameSettingsRecords.get(1);
    if (settings != null) {
      return settings;
    }

    final fallback = GameSettingsRecord()
      ..masterVolume = 0.85
      ..musicVolume = 0.55
      ..sfxVolume = 0.90
      ..muted = false;

    await isar.writeTxn(() async {
      await isar.gameSettingsRecords.put(fallback);
    });

    return fallback;
  }

  Future<void> saveAudioSettings(AudioSettingsController controller) async {
    await isar.writeTxn(() async {
      await isar.gameSettingsRecords.put(
        GameSettingsRecord()
          ..id = 1
          ..masterVolume = controller.masterVolume
          ..musicVolume = controller.musicVolume
          ..sfxVolume = controller.sfxVolume
          ..muted = controller.muted,
      );
    });
  }

  Future<CampaignOverview> loadCampaignOverview({required int totalStages}) async {
    final profile = await _loadOrCreateProfile();
    final allRecords = await isar.stageProgressRecords.where().findAll();
    final byStage = {
      for (final record in allRecords) record.stageNumber: record,
    };
    final metaUpgrades = await _loadMetaUpgrades();
    final totalStars = allRecords.fold<int>(0, (sum, record) => sum + record.stars);

    final stages = List<StageProgressSnapshot>.generate(totalStages, (index) {
      final stageNumber = index + 1;
      final record = byStage[stageNumber];
      final definition = SampleCampaign.stage(stageNumber);
      final unlockCheck = _checkStageUnlocked(
        stage: definition,
        byStage: byStage,
        totalStars: totalStars,
        metaUpgrades: metaUpgrades,
      );
      return StageProgressSnapshot(
        stageNumber: stageNumber,
        unlocked: unlockCheck.unlocked,
        stars: record?.stars ?? 0,
        cleared: (record?.stars ?? 0) > 0,
        description: definition.description,
        objectives: definition.objectives.map((objective) => objective.label).toList(),
        unlockRequirementLabels:
            definition.unlockRequirements.map((requirement) => requirement.label).toList(),
        lockReason: unlockCheck.lockReason,
      );
    });

    return CampaignOverview(
      player: PlayerProgressSnapshot(
        accountLevel: profile.accountLevel,
        totalXp: profile.totalXp,
        softCurrency: profile.softCurrency,
        premiumCurrency: profile.premiumCurrency,
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
    final softCurrencyAwarded =
        (((stageNumber * 18) + (starsAwarded * 7)) * metaEffects.stageRewardMultiplier).round();

    int totalStars = starsAwarded;

    await isar.writeTxn(() async {
      final profile = await _loadProfileInTxn();
      profile.lastPlayedAt = DateTime.now();
      profile.totalXp += xpAwarded;
      profile.softCurrency += softCurrencyAwarded;
      profile.accountLevel = 1 + (profile.totalXp ~/ 150);
      await isar.playerProfiles.put(profile);

      final existing = await isar.stageProgressRecords
          .filter()
          .stageNumberEqualTo(stageNumber)
          .findFirst();

      final record = existing ?? (StageProgressRecord()..stageNumber = stageNumber);
      record.unlocked = true;
      record.stars = starsAwarded > record.stars ? starsAwarded : record.stars;
      record.firstClearedAt ??= DateTime.now();
      record.lastClearedAt = DateTime.now();
      totalStars = record.stars;
      await isar.stageProgressRecords.put(record);

    });

    int? unlockedNextStage;
    if (stageNumber < totalStages) {
      final allRecords = await isar.stageProgressRecords.where().findAll();
      final byStage = {
        for (final record in allRecords) record.stageNumber: record,
      };
      final totalAccumulatedStars = allRecords.fold<int>(0, (sum, record) => sum + record.stars);
      final metaUpgrades = await _loadMetaUpgrades();
      final nextStage = SampleCampaign.stage(stageNumber + 1);
      final unlocked = _checkStageUnlocked(
        stage: nextStage,
        byStage: byStage,
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
      totalStars: totalStars,
      xpAwarded: xpAwarded,
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
    final existing = await isar.rewardClaimRecords.filter().claimKeyEqualTo(claimKey).findFirst();
    if (existing != null) {
      final profile = await _loadOrCreateProfile();
      return RewardClaimResult(
        claimedNow: false,
        amountAwarded: 0,
        totalSoftCurrency: profile.softCurrency,
      );
    }

    late int totalSoftCurrency;
    await isar.writeTxn(() async {
      final profile = await _loadProfileInTxn();
      profile.softCurrency += amount;
      totalSoftCurrency = profile.softCurrency;
      await isar.playerProfiles.put(profile);

      await isar.rewardClaimRecords.put(
        RewardClaimRecord()
          ..claimKey = claimKey
          ..sourceType = 'rewarded_stage_bonus'
          ..stageNumber = stageNumber
          ..amount = amount
          ..grantedAt = DateTime.now(),
      );
    });

    return RewardClaimResult(
      claimedNow: true,
      amountAwarded: amount,
      totalSoftCurrency: totalSoftCurrency,
    );
  }

  Future<bool> hasClaimedStageClearBonus(int stageNumber) {
    return isar.rewardClaimRecords
        .filter()
        .claimKeyEqualTo('stage_bonus_$stageNumber')
        .findFirst()
        .then((value) => value != null);
  }

  Future<List<MetaUpgradeSnapshot>> _loadMetaUpgrades() async {
    final records = await isar.upgradeNodeRecords.where().findAll();
    final byId = {
      for (final record in records) record.nodeId: record.level,
    };

    return [
      for (final definition in MetaUpgradeCatalog.upgrades)
        MetaUpgradeSnapshot(
          id: definition.id,
          level: byId[definition.id] ?? 0,
        ),
    ];
  }

  Future<ResolvedMetaUpgrades> loadResolvedMetaUpgrades() async {
    final snapshots = await _loadMetaUpgrades();
    return MetaUpgradeCatalog.resolve(snapshots);
  }

  Future<MetaUpgradePurchaseResult> purchaseMetaUpgrade(String nodeId) async {
    final definition = MetaUpgradeCatalog.byId(nodeId);
    final existing = await isar.upgradeNodeRecords.filter().nodeIdEqualTo(nodeId).findFirst();
    final currentLevel = existing?.level ?? 0;

    if (currentLevel >= definition.maxLevel) {
      final profile = await _loadOrCreateProfile();
      return MetaUpgradePurchaseResult(
        purchased: false,
        newLevel: currentLevel,
        remainingCurrency: profile.softCurrency,
        message: '${definition.label} is already maxed.',
      );
    }

    final cost = definition.costForLevel(currentLevel);
    final profile = await _loadOrCreateProfile();
    if (profile.softCurrency < cost) {
      return MetaUpgradePurchaseResult(
        purchased: false,
        newLevel: currentLevel,
        remainingCurrency: profile.softCurrency,
        message: 'Need $cost meta gold for ${definition.label}.',
      );
    }

    late int remainingCurrency;
    late int newLevel;
    await isar.writeTxn(() async {
      final txnProfile = await _loadProfileInTxn();
      txnProfile.softCurrency -= cost;
      remainingCurrency = txnProfile.softCurrency;
      await isar.playerProfiles.put(txnProfile);

      final record = existing ?? (UpgradeNodeRecord()..nodeId = nodeId);
      record.level = currentLevel + 1;
      newLevel = record.level;
      await isar.upgradeNodeRecords.put(record);
    });

    return MetaUpgradePurchaseResult(
      purchased: true,
      newLevel: newLevel,
      remainingCurrency: remainingCurrency,
      message: '${definition.label} upgraded to level $newLevel.',
    );
  }

  Future<PlayerProfile> _loadOrCreateProfile() async {
    final profile = await isar.playerProfiles.where().findFirst();
    if (profile != null) {
      return profile;
    }

    final seeded = PlayerProfile()
      ..createdAt = DateTime.now()
      ..lastPlayedAt = DateTime.now()
      ..accountLevel = 1
      ..totalXp = 0
      ..softCurrency = 0
      ..premiumCurrency = 0;

    await isar.writeTxn(() async {
      await isar.playerProfiles.put(seeded);
    });
    return seeded;
  }

  Future<PlayerProfile> _loadProfileInTxn() async {
    final profile = await isar.playerProfiles.where().findFirst();
    if (profile != null) {
      return profile;
    }

    final seeded = PlayerProfile()
      ..createdAt = DateTime.now()
      ..lastPlayedAt = DateTime.now()
      ..accountLevel = 1
      ..totalXp = 0
      ..softCurrency = 0
      ..premiumCurrency = 0;

    await isar.playerProfiles.put(seeded);
    return seeded;
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

    final metaById = {
      for (final upgrade in metaUpgrades) upgrade.id: upgrade.level,
    };

    for (final requirement in stage.unlockRequirements) {
      switch (requirement.type) {
        case StageUnlockRequirementType.previousStageStars:
          final stageNumber = requirement.stageNumber ?? (stage.number - 1);
          final threshold = requirement.threshold ?? 1;
          final stars = byStage[stageNumber]?.stars ?? 0;
          if (stars < threshold) {
            return _UnlockCheck(unlocked: false, lockReason: requirement.label);
          }
        case StageUnlockRequirementType.totalStars:
          final threshold = requirement.threshold ?? 0;
          if (totalStars < threshold) {
            return _UnlockCheck(unlocked: false, lockReason: requirement.label);
          }
        case StageUnlockRequirementType.metaUpgradeLevel:
          final requiredLevel = requirement.threshold ?? 1;
          final currentLevel = metaById[requirement.upgradeId] ?? 0;
          if (currentLevel < requiredLevel) {
            return _UnlockCheck(unlocked: false, lockReason: requirement.label);
          }
      }
    }

    return const _UnlockCheck(unlocked: true, lockReason: null);
  }
}

class _UnlockCheck {
  const _UnlockCheck({
    required this.unlocked,
    required this.lockReason,
  });

  final bool unlocked;
  final String? lockReason;
}
