import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defense game accepts an optional tutorial director', () {
    final director = TutorialDirector();
    final game = DefensePrototypeGame(
      stage: CampaignData.stage(1),
      sessionController: GameSessionController(),
      audioService: GameAudioService(AudioSettingsController()),
      metaUpgrades: const ResolvedMetaUpgrades(),
      chosenHeroKind: HeroKind.knight,
      tutorialDirector: director,
    );

    expect(game.tutorialDirector, same(director));
  });

  test(
    'real simulation completes both demonstrations and the two-enemy defense',
    () {
      final director = TutorialDirector(
        initialStep: TutorialStep.lessonWallPlacement,
      );
      final session = GameSessionController();
      final game = DefensePrototypeGame(
        stage: TutorialStageDefinition.build(),
        sessionController: session,
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
        tutorialDirector: director,
      );
      game.onGameResize(Vector2(420, 560));

      game.prepareTutorialStep(TutorialStep.lessonWallPlacement);
      game.debugPlaceTutorialTarget();
      expect(director.snapshot.step, TutorialStep.lessonWallObservation);
      expect(game.debugTutorialCoinCount, 0);
      expect(game.debugTutorialBarrierCount, 1);

      game.prepareTutorialStep(TutorialStep.lessonWallObservation);
      _advanceUntil(
        game,
        () => director.snapshot.step == TutorialStep.lessonTowerPlacement,
      );

      game.prepareTutorialStep(TutorialStep.lessonTowerPlacement);
      game.debugPlaceTutorialTarget();
      expect(director.snapshot.step, TutorialStep.lessonTowerObservation);
      expect(game.debugTutorialCoinCount, 0);
      expect(game.debugTutorialTowerCount, 1);

      game.prepareTutorialStep(TutorialStep.lessonTowerObservation);
      _advanceUntil(
        game,
        () => director.snapshot.step == TutorialStep.practiceWallPlacement,
      );

      game.prepareTutorialStep(TutorialStep.practiceWallPlacement);
      game.debugPlaceTutorialTarget();
      game.prepareTutorialStep(TutorialStep.practiceRoadTowerPlacement);
      game.debugPlaceTutorialTarget();
      game.prepareTutorialStep(TutorialStep.practiceGrassTowerPlacement);
      game.debugPlaceTutorialTarget();
      expect(director.snapshot.step, TutorialStep.practiceDefense);
      expect(game.debugTutorialBarrierCount, 1);
      expect(game.debugTutorialTowerCount, 2);
      expect(game.debugTutorialCoinCount, 0);

      game.prepareTutorialStep(TutorialStep.practiceDefense);
      game.startNextWave();
      expect(session.remainingEnemies, 2);
      _advanceUntil(
        game,
        () => director.snapshot.step == TutorialStep.recap,
        maxFrames: 1800,
      );
      expect(game.debugTutorialEnemyCount, 0);
    },
  );
}

void _advanceUntil(
  DefensePrototypeGame game,
  bool Function() condition, {
  int maxFrames = 900,
}) {
  for (var frame = 0; frame < maxFrames && !condition(); frame += 1) {
    game.update(1 / 60);
  }
  expect(condition(), isTrue);
}
