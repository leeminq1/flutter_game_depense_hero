import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StageEvaluationResult evaluate({
    required bool cleared,
    required int hp,
    required int gold,
  }) {
    return CampaignData.stage(1).evaluateRun(
      StageRunSummary(
        cleared: cleared,
        baseHealthRemaining: hp,
        maxBaseHealth: 3,
        remainingGold: gold,
        towersBuilt: 0,
        towersSold: 0,
        builtTowerKinds: const {},
      ),
    );
  }

  test('stage stars require both citadel hp and remaining gold', () {
    expect(evaluate(cleared: true, hp: 3, gold: 50).starsAwarded, 3);
    expect(evaluate(cleared: true, hp: 3, gold: 30).starsAwarded, 2);
    expect(evaluate(cleared: true, hp: 2, gold: 50).starsAwarded, 2);
    expect(evaluate(cleared: true, hp: 1, gold: 99).starsAwarded, 1);
    expect(evaluate(cleared: true, hp: 3, gold: 0).starsAwarded, 1);
    expect(evaluate(cleared: false, hp: 3, gold: 99).starsAwarded, 0);
  });

  test(
    'current run evaluation uses terminal session values for result save',
    () {
      final sessionController = GameSessionController();
      sessionController.updateRuntime(
        currentWave: 4,
        coins: 338,
        baseHealth: 3,
        waveInProgress: false,
        stageCleared: true,
        stageFailed: false,
        isPaused: false,
        towersBuilt: 0,
        maxTowerLevel: 1,
        builtTowerKinds: const {},
        statusText: 'Stage clear',
        remainingEnemies: 0,
      );
      final game = DefensePrototypeGame(
        stage: CampaignData.stage(5),
        sessionController: sessionController,
        audioService: GameAudioService(AudioSettingsController()),
        metaUpgrades: const ResolvedMetaUpgrades(),
        chosenHeroKind: HeroKind.knight,
      );

      expect(game.evaluateCurrentRun().starsAwarded, 3);
    },
  );
}
