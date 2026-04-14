import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/persistence/store_models.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/models/stage_definition.dart';

abstract class ProgressStore {
  Future<AudioSettingsSnapshot> loadAudioSettings();

  Future<void> saveAudioSettings(AudioSettingsController controller);

  Future<bool> isTutorialDismissed();

  Future<void> setTutorialDismissed(bool dismissed);

  Future<void> resetCampaignProgress();

  Future<CampaignOverview> loadCampaignOverview({
    required int totalStages,
  });

  Future<StageCompletionResult> recordStageCompletion({
    required int stageNumber,
    required StageEvaluationResult evaluation,
    required int totalStages,
  });

  Future<RewardClaimResult> claimStageClearBonus({
    required int stageNumber,
    required int amount,
  });

  Future<bool> hasClaimedStageClearBonus(int stageNumber);

  Future<ResolvedMetaUpgrades> loadResolvedMetaUpgrades();

  Future<MetaUpgradePurchaseResult> purchaseMetaUpgrade(String nodeId);
}
