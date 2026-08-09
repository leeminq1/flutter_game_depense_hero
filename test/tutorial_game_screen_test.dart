import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/game_screen.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tutorial mode opens the training map without legacy dialogs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await InMemoryProgressStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          bootstrap: _TestBootstrap(store),
          initialStageNumber: 1,
          tutorialLaunchSource: TutorialLaunchSource.newGame,
          onTutorialComplete: () {},
          onExitToCamp: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('훈련장'), findsWidgets);
    expect(
      find.byKey(const ValueKey('tutorial-guidance-card')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);

    final gameWidget = tester.widget<GameWidget<DefensePrototypeGame>>(
      find.byWidgetPredicate(
        (widget) => widget is GameWidget<DefensePrototypeGame>,
      ),
    );
    expect(gameWidget.game!.stage.number, 0);
    expect(gameWidget.game!.tutorialDirector, isNotNull);

    gameWidget.game!.tutorialDirector!.record(
      const TutorialEvent.cameraChanged(),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('tutorial-required-build-card')),
      findsOneWidget,
    );
    expect(find.text('무료'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('barrier-card-woodFence')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('build-card-archer')), findsNothing);
    expect(find.byType(SegmentedButton), findsNothing);
  });

  testWidgets(
    'stage one recap is compact and does not reopen the old briefing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = await InMemoryProgressStore.open();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            bootstrap: _TestBootstrap(store),
            initialStageNumber: 1,
            showStageOneRecap: true,
            onExitToCamp: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const ValueKey('stage-one-recap')), findsOneWidget);
      expect(find.text('성벽으로 막고, 타워로 공격'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const ValueKey('stage-one-recap-close')), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const ValueKey('stage-one-recap')), findsNothing);
    },
  );

  testWidgets('menu tutorial completion offers replay or home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await InMemoryProgressStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          bootstrap: _TestBootstrap(store),
          initialStageNumber: 1,
          tutorialLaunchSource: TutorialLaunchSource.mainMenu,
          onTutorialComplete: () {},
          onExitToCamp: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final game = tester
        .widget<GameWidget<DefensePrototypeGame>>(
          find.byWidgetPredicate(
            (widget) => widget is GameWidget<DefensePrototypeGame>,
          ),
        )
        .game!;
    final director = game.tutorialDirector!;
    director.record(const TutorialEvent.cameraChanged());
    final lessonWall = TutorialStageDefinition.lessonWallCell;
    director.record(
      TutorialEvent.barrierPlaced(
        kind: BarrierKind.woodFence,
        col: lessonWall.col,
        row: lessonWall.row,
      ),
    );
    director.record(const TutorialEvent.enemyBlockedByWall());
    final lessonTower = TutorialStageDefinition.lessonTowerCell;
    director.record(
      TutorialEvent.towerPlaced(
        kind: TowerKind.archer,
        col: lessonTower.col,
        row: lessonTower.row,
      ),
    );
    director.record(const TutorialEvent.enemyPassedTower());
    final practiceWall = TutorialStageDefinition.practiceWallCell;
    director.record(
      TutorialEvent.barrierPlaced(
        kind: BarrierKind.woodFence,
        col: practiceWall.col,
        row: practiceWall.row,
      ),
    );
    for (final cell in [
      TutorialStageDefinition.practiceRoadTowerCell,
      TutorialStageDefinition.practiceGrassTowerCell,
    ]) {
      director.record(
        TutorialEvent.towerPlaced(
          kind: TowerKind.archer,
          col: cell.col,
          row: cell.row,
        ),
      );
    }
    director.record(const TutorialEvent.waveCleared());
    director.continueCurrentStep();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('tutorial-finish-replay')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorial-finish-home')), findsOneWidget);
    expect(await store.isTutorialDismissed(), isTrue);
  });
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
