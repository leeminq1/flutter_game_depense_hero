import 'package:isar/isar.dart';

part 'game_collection_models.g.dart';

@collection
class PlayerProfile {
  Id id = Isar.autoIncrement;

  late DateTime createdAt;
  late DateTime lastPlayedAt;
  late int accountLevel;
  late int totalXp;
  late int softCurrency;
  late int premiumCurrency;
}

@collection
class StageProgressRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int stageNumber;

  late bool unlocked;
  late int stars;
  DateTime? firstClearedAt;
  DateTime? lastClearedAt;
}

@collection
class GameSettingsRecord {
  Id id = 1;

  late double masterVolume;
  late double musicVolume;
  late double sfxVolume;
  late bool muted;
}

@collection
class RewardClaimRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String claimKey;

  late String sourceType;
  late int stageNumber;
  late int amount;
  late DateTime grantedAt;
}

@collection
class UpgradeNodeRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String nodeId;

  late int level;
}
