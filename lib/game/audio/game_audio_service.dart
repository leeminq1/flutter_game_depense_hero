import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:depense_game/game/audio/audio_catalog.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:flame_audio/flame_audio.dart' hide AudioEvent;

class GameAudioService {
  GameAudioService(this._settings);

  final AudioSettingsController _settings;
  final Map<String, AudioPool> _pools = {};
  final Map<AudioEvent, int> _roundRobin = {};
  final Random _random = Random();

  Future<void> initialize() async {
    // Note: FlameAudio.bgm.initialize() is often not required and can crash on some platforms.
    // bgm will initialize its player automatically on the first play() call.
    
    final files = <String>{
      for (final entry in AudioCatalog.events.values) ...entry.assets,
    }.toList();

    try {
      // Load all SFX assets into cache.
      await FlameAudio.audioCache.loadAll(files);
      
      // Initialize pools for frequently played sounds (SFX).
      for (final definition in AudioCatalog.events.values.where((e) => e.pooled)) {
        for (final asset in definition.assets) {
          _pools[asset] = await FlameAudio.createPool(
            asset,
            maxPlayers: definition.maxPlayers,
            minPlayers: 1,
          );
        }
      }
    } catch (e, stack) {
      debugPrint('GameAudioService: Initialization error: $e');
      debugPrint(stack.toString());
      // Re-throw to inform bootstrap, but we've logged the detail.
      rethrow;
    }
  }

  Future<void> play(AudioEvent event) async {
    if (_settings.muted) {
      return;
    }

    final entry = AudioCatalog.events[event];
    if (entry == null || entry.assets.isEmpty) {
      return;
    }

    final asset = _pickAsset(event, entry.assets);
    final volume = (_settings.masterVolume * _settings.sfxVolume * entry.baseVolume)
        .clamp(0.0, 1.0);

    try {
      final pool = _pools[asset];
      if (entry.pooled && pool != null) {
        await pool.start(volume: volume);
      } else {
        await FlameAudio.play(asset, volume: volume);
      }
    } catch (_) {
      // Audio must never block gameplay.
    }
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {
      // Ignore stop failures to keep runtime resilient.
    }
  }

  Future<void> refreshVolumes() async {
    if (_settings.muted) {
      await stopMusic();
    }
  }

  String _pickAsset(AudioEvent event, List<String> assets) {
    if (assets.length == 1) {
      return assets.single;
    }

    final current = _roundRobin[event] ?? _random.nextInt(assets.length);
    final next = (current + 1) % assets.length;
    _roundRobin[event] = next;
    return assets[current];
  }
}
