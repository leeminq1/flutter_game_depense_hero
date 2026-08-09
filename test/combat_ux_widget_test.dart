import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/game_screen.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preparation panel uses 74 by 82 build cards', (tester) async {
    await _pumpStageOne(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('barrier-card-woodFence'))),
      const Size(74, 82),
    );
    expect(
      find.byKey(const ValueKey('preparation-build-panel')),
      findsOneWidget,
    );
    expect(find.textContaining('다음 WAVE:'), findsNothing);
    expect(find.byKey(const ValueKey('hud-wave')), findsOneWidget);
  });

  testWidgets('active wave replaces cards with a compact combat bar', (
    tester,
  ) async {
    await _pumpStageOne(tester);

    final startWave = find.text('WAVE 1 시작').hitTestable();
    expect(startWave, findsOneWidget);
    await tester.tap(startWave);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('combat-status-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('hud-enemies')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('combat-status-bar'))).height,
      inInclusiveRange(52, 60),
    );
    expect(find.byKey(const ValueKey('preparation-build-panel')), findsNothing);
  });

  testWidgets('pause updates immediately to a resume action', (tester) async {
    await _pumpStageOne(tester);
    await tester.tap(find.text('WAVE 1 시작').hitTestable());
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(
      find.byKey(const ValueKey('combat-pause-toggle')).hitTestable(),
    );
    await tester.pump();

    expect(find.text('재개'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
  });

  testWidgets('camera reset appears after a pinch transform', (tester) async {
    await _pumpStageOne(tester);
    final gameFinder = find.byWidgetPredicate(
      (widget) => widget is GameWidget<DefensePrototypeGame>,
    );
    final center = tester.getCenter(gameFinder);
    final game = tester
        .widget<GameWidget<DefensePrototypeGame>>(gameFinder)
        .game!;

    game.onScaleStart(
      ScaleStartInfo.fromDetails(
        game,
        ScaleStartDetails(focalPoint: center, pointerCount: 2),
      ),
    );
    game.onScaleUpdate(
      ScaleUpdateInfo.fromDetails(
        game,
        ScaleUpdateDetails(
          focalPoint: center,
          scale: 2,
          horizontalScale: 2,
          verticalScale: 2,
          pointerCount: 2,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-reset')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('camera-reset')));
    await tester.pump();
    expect(find.byKey(const ValueKey('camera-reset')), findsNothing);
  });

  testWidgets('battlefield rendering is clipped to its viewport', (
    tester,
  ) async {
    await _pumpStageOne(tester);

    final gameFinder = find.byWidgetPredicate(
      (widget) => widget is GameWidget<DefensePrototypeGame>,
    );

    expect(
      find.ancestor(
        of: gameFinder,
        matching: find.byKey(const ValueKey('battlefield-viewport-clip')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('coin and stage remain visible on a phone-sized HUD', (
    tester,
  ) async {
    await _pumpStageOne(tester);

    final coins = find.byKey(const ValueKey('hud-coins'));
    final stage = find.byKey(const ValueKey('hud-stage'));
    expect(coins, findsOneWidget);
    expect(stage, findsOneWidget);

    for (final finder in [coins, stage]) {
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(430));
    }
  });
}

Future<void> _pumpStageOne(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = await InMemoryProgressStore.open();

  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        bootstrap: _TestBootstrap(store),
        initialStageNumber: 1,
        onExitToCamp: () async {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.widgetWithText(FilledButton, '시작'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  final briefingClose = find.byTooltip('닫기');
  if (briefingClose.evaluate().isNotEmpty) {
    await tester.tap(briefingClose);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
}

class _TestBootstrap extends AppBootstrap {
  _TestBootstrap(this._store) {
    audioSettingsController = AudioSettingsController();
    audioService = GameAudioService(audioSettingsController);
  }

  final ProgressStore _store;

  @override
  ProgressStore get progressStore => _store;
}
