import 'package:depense_game/app/ads/result_banner_ad_service.dart';
import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/game_screen.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stage 30 clear shows ending before result and supports replay', (
    tester,
  ) async {
    final store = await _pumpStage(tester, stageNumber: 30);
    final game = tester
        .widget<GameWidget<DefensePrototypeGame>>(
          find.byWidgetPredicate(
            (widget) => widget is GameWidget<DefensePrototypeGame>,
          ),
        )
        .game!;
    game.pauseEngine();

    _finishStage(game, cleared: true);
    await tester.pump();

    expect(find.byKey(const Key('campaign-ending-overlay')), findsOneWidget);
    expect(find.byKey(const Key('campaign-final-result')), findsNothing);

    await tester.tap(find.byKey(const Key('campaign-ending-skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('campaign-ending-overlay')), findsNothing);
    expect(find.byKey(const Key('campaign-final-result')), findsOneWidget);
    expect(
      find.byKey(const Key('campaign-ending-replay-result')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('campaign-final-retry')), findsOneWidget);
    expect(find.byKey(const Key('campaign-final-home')), findsOneWidget);
    expect(find.byKey(const Key('campaign-next-stage')), findsNothing);

    final currencyBeforeReplay = (await store.loadCampaignOverview(
      totalStages: 30,
    )).player.softCurrency;
    await tester.tap(find.byKey(const Key('campaign-ending-replay-result')));
    await tester.pump();

    expect(find.byKey(const Key('campaign-ending-overlay')), findsOneWidget);
    final currencyAfterReplay = (await store.loadCampaignOverview(
      totalStages: 30,
    )).player.softCurrency;
    expect(currencyAfterReplay, currencyBeforeReplay);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stage 29 clear keeps the normal result flow', (tester) async {
    await _pumpStage(tester, stageNumber: 29);
    final game = tester
        .widget<GameWidget<DefensePrototypeGame>>(
          find.byWidgetPredicate(
            (widget) => widget is GameWidget<DefensePrototypeGame>,
          ),
        )
        .game!;
    game.pauseEngine();

    _finishStage(game, cleared: true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('campaign-ending-overlay')), findsNothing);
    expect(find.byKey(const Key('campaign-final-result')), findsOneWidget);
    expect(find.byKey(const Key('campaign-next-stage')), findsOneWidget);
  });

  testWidgets('Stage 30 failure skips the ending', (tester) async {
    await _pumpStage(tester, stageNumber: 30);
    final game = tester
        .widget<GameWidget<DefensePrototypeGame>>(
          find.byWidgetPredicate(
            (widget) => widget is GameWidget<DefensePrototypeGame>,
          ),
        )
        .game!;
    game.pauseEngine();

    _finishStage(game, cleared: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('campaign-ending-overlay')), findsNothing);
    expect(find.byKey(const Key('campaign-final-result')), findsOneWidget);
    expect(
      find.byKey(const Key('campaign-ending-replay-result')),
      findsNothing,
    );
  });
}

Future<InMemoryProgressStore> _pumpStage(
  WidgetTester tester, {
  required int stageNumber,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = await InMemoryProgressStore.open();

  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        bootstrap: _TestBootstrap(store),
        initialStageNumber: stageNumber,
        onExitToCamp: () {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return store;
}

void _finishStage(DefensePrototypeGame game, {required bool cleared}) {
  final session = game.sessionController;
  session.updateRuntime(
    currentWave: session.totalWaves,
    coins: 120,
    baseHealth: cleared ? session.maxBaseHealth : 0,
    waveInProgress: false,
    stageCleared: cleared,
    stageFailed: !cleared,
    isPaused: false,
    towersBuilt: 3,
    maxTowerLevel: 2,
    builtTowerKinds: const {'archer', 'guardBarracks'},
    statusText: cleared ? 'Stage cleared' : 'Stage failed',
    remainingEnemies: 0,
  );
}

class _TestBootstrap extends AppBootstrap {
  _TestBootstrap(this._store) {
    audioSettingsController = AudioSettingsController();
    audioService = GameAudioService(audioSettingsController);
    resultBannerAdService = _NoopResultBannerAdService();
  }

  final ProgressStore _store;

  @override
  ProgressStore get progressStore => _store;
}

class _NoopResultBannerAdService implements ResultBannerAdService {
  @override
  void dispose() {}

  @override
  Future<void> initialize() async {}

  @override
  Future<ResultBannerAdHandle?> load() async => null;
}
