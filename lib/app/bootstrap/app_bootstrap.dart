import 'package:depense_game/data/persistence/local_progress_store.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';

class AppBootstrap {
  late final AudioSettingsController audioSettingsController;
  late final GameAudioService audioService;
  late final LocalProgressStore progressStore;

  Future<void> initialize() async {
    progressStore = await LocalProgressStore.open();

    final savedSettings = await progressStore.loadOrCreateSettings();
    audioSettingsController = AudioSettingsController.fromRecord(savedSettings);

    audioService = GameAudioService(audioSettingsController);
    await audioService.initialize();
  }

  Future<void> persistAudioSettings() {
    return progressStore.saveAudioSettings(audioSettingsController);
  }
}
