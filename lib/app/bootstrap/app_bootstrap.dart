import 'package:depense_game/app/ads/result_banner_ad_service.dart';
import 'package:depense_game/app/ads/rewarded_retry_ad_service.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progress_store_factory.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';

class AppBootstrap {
  AppBootstrap({
    RewardedRetryAdService? rewardedRetryAdService,
    ResultBannerAdService? resultBannerAdService,
  }) : _rewardedRetryAdServiceOverride = rewardedRetryAdService,
       _resultBannerAdServiceOverride = resultBannerAdService;

  final RewardedRetryAdService? _rewardedRetryAdServiceOverride;
  final ResultBannerAdService? _resultBannerAdServiceOverride;

  late final AudioSettingsController audioSettingsController;
  late final GameAudioService audioService;
  late final ProgressStore progressStore;
  late final RewardedRetryAdService rewardedRetryAdService;
  late final ResultBannerAdService resultBannerAdService;

  Future<void> initialize() async {
    progressStore = await openProgressStore();

    final savedSettings = await progressStore.loadAudioSettings();
    audioSettingsController = AudioSettingsController.fromSnapshot(
      savedSettings,
    );

    audioService = GameAudioService(audioSettingsController);
    await audioService.initialize();

    rewardedRetryAdService =
        _rewardedRetryAdServiceOverride ?? createRewardedRetryAdService();
    await rewardedRetryAdService.initialize();

    resultBannerAdService =
        _resultBannerAdServiceOverride ?? createResultBannerAdService();
    await resultBannerAdService.initialize();
  }

  Future<void> persistAudioSettings() {
    return progressStore.saveAudioSettings(audioSettingsController);
  }
}
