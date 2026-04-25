import 'package:depense_game/game/audio/audio_event.dart';

class AudioEntry {
  const AudioEntry({required this.assets, required this.baseVolume});

  final List<String> assets;
  final double baseVolume;
}

class AudioCatalog {
  static const Map<AudioEvent, AudioEntry> events = {
    AudioEvent.uiClick: AudioEntry(
      assets: ['sfx/ui/click_primary.ogg'],
      baseVolume: 0.55,
    ),
    AudioEvent.uiSelect: AudioEntry(
      assets: ['sfx/ui/select_primary.ogg'],
      baseVolume: 0.55,
    ),
    AudioEvent.uiConfirm: AudioEntry(
      assets: ['sfx/ui/confirm_primary.ogg'],
      baseVolume: 0.60,
    ),
    AudioEvent.uiError: AudioEntry(
      assets: ['sfx/ui/error_primary.ogg'],
      baseVolume: 0.60,
    ),
    AudioEvent.towerPlace: AudioEntry(
      assets: [
        'sfx/build/tower_place_light_01.ogg',
        'sfx/build/tower_place_light_02.ogg',
        'sfx/build/tower_place_wood_01.ogg',
        'sfx/build/tower_place_wood_02.ogg',
      ],
      baseVolume: 0.85,
    ),
    AudioEvent.towerUpgrade: AudioEntry(
      assets: ['sfx/build/upgrade_click.ogg'],
      baseVolume: 0.75,
    ),
    AudioEvent.arrowShot: AudioEntry(
      assets: [
        'sfx/combat/projectile_slice_01.ogg',
        'sfx/combat/projectile_slice_02.ogg',
      ],
      baseVolume: 0.80,
    ),
    AudioEvent.slashHit: AudioEntry(
      assets: ['sfx/combat/hit_flesh_01.ogg', 'sfx/combat/hit_flesh_02.ogg'],
      baseVolume: 0.70,
    ),
    AudioEvent.armorHit: AudioEntry(
      assets: [
        'sfx/combat/hit_armor_light_01.ogg',
        'sfx/combat/hit_armor_light_02.ogg',
        'sfx/combat/hit_armor_heavy_01.ogg',
      ],
      baseVolume: 0.75,
    ),
    AudioEvent.magicHit: AudioEntry(
      assets: ['sfx/combat/hit_magic_01.ogg', 'sfx/combat/hit_magic_02.ogg'],
      baseVolume: 0.72,
    ),
    AudioEvent.enemyDeathElite: AudioEntry(
      assets: ['sfx/combat/enemy_death_elite_01.ogg'],
      baseVolume: 0.70,
    ),
    AudioEvent.coinGain: AudioEntry(
      assets: ['sfx/economy/coin_gain_01.ogg', 'sfx/economy/coin_gain_02.ogg'],
      baseVolume: 0.65,
    ),
    AudioEvent.waveClear: AudioEntry(
      assets: ['jingles/wave_clear.ogg'],
      baseVolume: 0.75,
    ),
    AudioEvent.stageClear: AudioEntry(
      assets: ['jingles/stage_clear.ogg'],
      baseVolume: 0.85,
    ),
    AudioEvent.baseDamage: AudioEntry(
      assets: ['sfx/ui/error_primary.ogg'],
      baseVolume: 0.80,
    ),
  };
}
