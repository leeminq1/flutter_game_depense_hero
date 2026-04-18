import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:depense_game/game/audio/audio_catalog.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:flame_audio/flame_audio.dart' hide AudioEvent;

/// 전투 SFX 최소 재생 간격 (초). 이 간격보다 빠르게 반복 요청되면 드롭.
const _minIntervalByEvent = {
  AudioEvent.arrowShot: 0.05,
  AudioEvent.slashHit: 0.04,
  AudioEvent.armorHit: 0.04,
  AudioEvent.magicHit: 0.06,
  AudioEvent.coinGain: 0.10,
};

/// 동시에 처리 중인 SFX 요청 최대 수. 초과 시 전투 SFX는 드롭.
const _maxPendingSfx = 8;

class GameAudioService {
  GameAudioService(this._settings);

  final AudioSettingsController _settings;
  final Map<String, AudioPool> _pools = {};
  final Map<AudioEvent, int> _roundRobin = {};
  final Random _random = Random();

  /// 이벤트별 남은 쿨다운 시간.
  final Map<AudioEvent, double> _cooldownRemaining = {};

  /// 현재 처리 중인 SFX 요청 수.
  int _pendingCount = 0;

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

  /// 게임 루프에서 매 프레임 호출 — 이벤트별 쿨다운 차감.
  void update(double dt) {
    for (final event in _minIntervalByEvent.keys) {
      final remaining = _cooldownRemaining[event];
      if (remaining != null && remaining > 0) {
        _cooldownRemaining[event] = remaining - dt;
      }
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

    // 전투 SFX 쓰로틀링: 쿨다운 중이거나 pending 초과 시 드롭.
    final minInterval = _minIntervalByEvent[event];
    if (minInterval != null) {
      final remaining = _cooldownRemaining[event] ?? 0.0;
      if (remaining > 0) {
        return; // 쿨다운 중 — 드롭
      }
      if (_pendingCount >= _maxPendingSfx) {
        return; // 동시 요청 초과 — 드롭
      }
      _cooldownRemaining[event] = minInterval;
    }

    final asset = _pickAsset(event, entry.assets);
    final volume = (_settings.masterVolume * _settings.sfxVolume * entry.baseVolume)
        .clamp(0.0, 1.0);

    _pendingCount++;
    try {
      final pool = _pools[asset];
      if (entry.pooled && pool != null) {
        await pool.start(volume: volume);
      } else {
        await FlameAudio.play(asset, volume: volume);
      }
    } catch (_) {
      // Audio must never block gameplay.
    } finally {
      _pendingCount--;
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
