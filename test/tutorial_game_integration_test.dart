import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
