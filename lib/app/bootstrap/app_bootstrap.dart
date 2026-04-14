import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progress_store_factory.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';

class AppBootstrap {
  late final AudioSettingsController audioSettingsController;
  late final GameAudioService audioService;
  late final ProgressStore progressStore;

  Future<void> initialize() async {
    progressStore = await openProgressStore();

    final savedSettings = await progressStore.loadAudioSettings();
    audioSettingsController = AudioSettingsController.fromSnapshot(
      savedSettings,
    );

    audioService = GameAudioService(audioSettingsController);
    await audioService.initialize();
  }

  Future<void> persistAudioSettings() {
    return progressStore.saveAudioSettings(audioSettingsController);
  }
}
