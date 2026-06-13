import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/settings_screen.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings screen persists mute and volume changes on phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await InMemoryProgressStore.open();
    final controller = AudioSettingsController();
    final bootstrap = _SettingsTestBootstrap(
      store: store,
      audioSettingsController: controller,
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(bootstrap: bootstrap)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    var saved = await store.loadAudioSettings();
    expect(controller.muted, isTrue);
    expect(saved.muted, isTrue);

    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(3));

    await tester.drag(sliders.first, const Offset(-220, 0));
    await tester.pumpAndSettle();

    saved = await store.loadAudioSettings();
    expect(controller.masterVolume, lessThan(0.85));
    expect(saved.masterVolume, controller.masterVolume);

    await tester.drag(sliders.at(1), const Offset(220, 0));
    await tester.pumpAndSettle();

    saved = await store.loadAudioSettings();
    expect(controller.musicVolume, greaterThan(0.55));
    expect(saved.musicVolume, controller.musicVolume);
  });

  testWidgets('settings screen opens discoverable third-party licenses', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await InMemoryProgressStore.open();
    final bootstrap = _SettingsTestBootstrap(
      store: store,
      audioSettingsController: AudioSettingsController(),
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(bootstrap: bootstrap)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Credits & Licenses'));
    await tester.pumpAndSettle();

    expect(find.text('Third-party Licenses'), findsWidgets);
    expect(
      find.textContaining('Universal LPC Spritesheet Character Generator'),
      findsWidgets,
    );
    expect(find.textContaining('CC-BY-SA 3.0'), findsWidgets);
    expect(find.textContaining('OpenGameArt'), findsWidgets);

    final details = await rootBundle.loadString('assets/legal/lpc_credits.txt');
    expect(details, contains('Universal LPC Spritesheet Character Generator'));
    expect(details, contains('CC-BY-SA 3.0'));
  });
}

class _SettingsTestBootstrap extends AppBootstrap {
  _SettingsTestBootstrap({
    required ProgressStore store,
    required AudioSettingsController audioSettingsController,
  }) : _store = store,
       _audioSettingsController = audioSettingsController;

  final ProgressStore _store;
  final AudioSettingsController _audioSettingsController;

  @override
  ProgressStore get progressStore => _store;

  @override
  AudioSettingsController get audioSettingsController =>
      _audioSettingsController;

  @override
  Future<void> persistAudioSettings() {
    return _store.saveAudioSettings(_audioSettingsController);
  }
}
