import 'dart:async';
import 'dart:math';

import 'package:depense_game/game/audio/android_sound_pool_backend.dart';
import 'package:depense_game/game/audio/audio_catalog.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/combat_sfx_backend.dart';
import 'package:depense_game/game/audio/flame_sfx_backend.dart';
import 'package:flame_audio/flame_audio.dart' hide AudioEvent;

const _minIntervalByEvent = {
  AudioEvent.uiClick: 0.05,
  AudioEvent.uiSelect: 0.10,
  AudioEvent.uiConfirm: 0.16,
  AudioEvent.uiError: 0.24,
  AudioEvent.towerPlace: 0.18,
  AudioEvent.towerUpgrade: 0.20,
  AudioEvent.arrowShot: 0.22,
  AudioEvent.slashHit: 0.28,
  AudioEvent.armorHit: 0.30,
  AudioEvent.magicHit: 0.32,
  AudioEvent.enemyDeathElite: 0.45,
  AudioEvent.coinGain: 0.45,
  AudioEvent.baseDamage: 0.48,
};

const _maxPendingSfx = 1;
const _maxQueuedSfx = 3;
const _maxDrainedPerUpdate = 1;
const _globalQueuedSfxGap = 0.14;
const _combatBurstWindow = 0.35;
const _combatBurstThreshold = 4;
const _combatSilenceDuration = 0.70;

const _combatRouteEvents = {
  AudioEvent.uiClick,
  AudioEvent.uiSelect,
  AudioEvent.uiConfirm,
  AudioEvent.uiError,
  AudioEvent.towerPlace,
  AudioEvent.towerUpgrade,
  AudioEvent.arrowShot,
  AudioEvent.slashHit,
  AudioEvent.armorHit,
  AudioEvent.magicHit,
  AudioEvent.enemyDeathElite,
  AudioEvent.coinGain,
  AudioEvent.baseDamage,
};

const _milestoneEvents = {AudioEvent.waveClear, AudioEvent.stageClear};

const _combatHeavyEvents = {
  AudioEvent.arrowShot,
  AudioEvent.slashHit,
  AudioEvent.armorHit,
  AudioEvent.magicHit,
  AudioEvent.enemyDeathElite,
  AudioEvent.coinGain,
  AudioEvent.baseDamage,
};

const _combatRepeatEvents = {
  AudioEvent.arrowShot,
  AudioEvent.slashHit,
  AudioEvent.armorHit,
  AudioEvent.magicHit,
};

const _maxQueuedByEvent = {
  AudioEvent.uiClick: 1,
  AudioEvent.uiSelect: 1,
  AudioEvent.uiConfirm: 1,
  AudioEvent.uiError: 1,
  AudioEvent.towerPlace: 1,
  AudioEvent.towerUpgrade: 1,
  AudioEvent.arrowShot: 1,
  AudioEvent.slashHit: 1,
  AudioEvent.armorHit: 1,
  AudioEvent.magicHit: 1,
  AudioEvent.enemyDeathElite: 1,
  AudioEvent.coinGain: 1,
  AudioEvent.baseDamage: 1,
};

const _drainPriority = [
  AudioEvent.baseDamage,
  AudioEvent.uiError,
  AudioEvent.towerPlace,
  AudioEvent.towerUpgrade,
  AudioEvent.coinGain,
  AudioEvent.enemyDeathElite,
  AudioEvent.armorHit,
  AudioEvent.magicHit,
  AudioEvent.slashHit,
  AudioEvent.arrowShot,
  AudioEvent.uiConfirm,
  AudioEvent.uiSelect,
  AudioEvent.uiClick,
];

class GameAudioService {
  GameAudioService(this._settings);

  final AudioSettingsController _settings;
  final FlameSfxBackend _flameBackend = FlameSfxBackend();
  CombatSfxBackend? _combatBackend;
  final Map<AudioEvent, int> _roundRobin = {};
  final Random _random = Random();
  final Map<AudioEvent, double> _cooldownRemaining = {};
  final Map<AudioEvent, int> _queuedEvents = {};
  final List<AudioEvent> _drainBuffer = [];

  bool _combatBackendReady = false;
  int _pendingCount = 0;
  double _globalCooldownRemaining = 0;
  double _combatBurstRemaining = 0;
  int _combatBurstCount = 0;
  double _combatSilenceRemaining = 0;

  Future<void> initialize() async {
    final flameAssets = <String>{
      for (final event in _milestoneEvents)
        ...?AudioCatalog.events[event]?.assets,
    };
    await _flameBackend.initialize(flameAssets);

    final androidBackend = AndroidSoundPoolBackend();
    final ready = await androidBackend.initialize({
      for (final event in _combatRouteEvents)
        ...?AudioCatalog.events[event]?.assets,
    });
    if (ready) {
      _combatBackend = androidBackend;
      _combatBackendReady = true;
      return;
    }

    await androidBackend.dispose();
    _combatBackend = null;
    _combatBackendReady = false;
  }

  void update(double dt) {
    for (final event in _minIntervalByEvent.keys) {
      final remaining = _cooldownRemaining[event];
      if (remaining != null && remaining > 0) {
        _cooldownRemaining[event] = remaining - dt;
      }
    }
    if (_globalCooldownRemaining > 0) {
      _globalCooldownRemaining = max(0, _globalCooldownRemaining - dt);
    }
    if (_combatBurstRemaining > 0) {
      _combatBurstRemaining = max(0, _combatBurstRemaining - dt);
      if (_combatBurstRemaining == 0) {
        _combatBurstCount = 0;
      }
    }
    if (_combatSilenceRemaining > 0) {
      _combatSilenceRemaining = max(0, _combatSilenceRemaining - dt);
    }
    _drainQueuedEvents();
  }

  Future<void> play(AudioEvent event) async {
    if (_settings.muted) {
      return;
    }

    if (_milestoneEvents.contains(event)) {
      unawaited(_playImmediate(event));
      return;
    }

    if (_combatSilenceRemaining > 0 &&
        _combatHeavyEvents.contains(event) &&
        event != AudioEvent.baseDamage) {
      return;
    }

    if (_combatHeavyEvents.contains(event)) {
      _recordCombatBurst();
    }

    if (_combatRouteEvents.contains(event)) {
      if (_combatRepeatEvents.contains(event) &&
          _queuedEvents.keys.any(_combatRepeatEvents.contains)) {
        return;
      }

      final totalQueued = _queuedEvents.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      if (totalQueued >= _maxQueuedSfx) {
        return;
      }

      final maxQueued = _maxQueuedByEvent[event] ?? 1;
      final current = _queuedEvents[event] ?? 0;
      if (current < maxQueued) {
        _queuedEvents[event] = current + 1;
      }
      return;
    }

    unawaited(_playImmediate(event));
  }

  void _drainQueuedEvents() {
    if (_queuedEvents.isEmpty ||
        _pendingCount >= _maxPendingSfx ||
        _globalCooldownRemaining > 0) {
      return;
    }

    _drainBuffer.clear();
    for (final event in _drainPriority) {
      if ((_queuedEvents[event] ?? 0) > 0) {
        _drainBuffer.add(event);
      }
    }
    for (final event in _queuedEvents.keys) {
      if (!_drainBuffer.contains(event)) {
        _drainBuffer.add(event);
      }
    }

    var playedThisUpdate = 0;
    for (final event in _drainBuffer) {
      if (playedThisUpdate >= _maxDrainedPerUpdate ||
          _pendingCount >= _maxPendingSfx ||
          _globalCooldownRemaining > 0) {
        return;
      }

      final queued = _queuedEvents[event] ?? 0;
      if (queued <= 0) {
        _queuedEvents.remove(event);
        continue;
      }

      _queuedEvents[event] = queued - 1;
      if (_queuedEvents[event] == 0) {
        _queuedEvents.remove(event);
      }

      playedThisUpdate += 1;
      unawaited(_playImmediate(event));
    }
  }

  Future<void> _playImmediate(AudioEvent event) async {
    if (_settings.muted) {
      return;
    }

    final entry = AudioCatalog.events[event];
    if (entry == null || entry.assets.isEmpty) {
      return;
    }

    final minInterval = _minIntervalByEvent[event];
    if (minInterval != null) {
      final remaining = _cooldownRemaining[event] ?? 0.0;
      if (remaining > 0 || _pendingCount >= _maxPendingSfx) {
        return;
      }
      _cooldownRemaining[event] = minInterval;
    }

    if (!_milestoneEvents.contains(event) && _globalCooldownRemaining > 0) {
      return;
    }

    final asset = _pickAsset(event, entry.assets);
    final volume =
        (_settings.masterVolume * _settings.sfxVolume * entry.baseVolume).clamp(
          0.0,
          1.0,
        );

    _pendingCount += 1;
    try {
      final backend = _backendFor(event);
      if (backend == null) {
        return;
      }
      await backend.play(asset, volume: volume);
    } catch (_) {
      // Audio must never block gameplay.
    } finally {
      _pendingCount -= 1;
      if (!_milestoneEvents.contains(event)) {
        _globalCooldownRemaining = _globalQueuedSfxGap;
      }
    }
  }

  CombatSfxBackend? _backendFor(AudioEvent event) {
    if (_milestoneEvents.contains(event)) {
      return _flameBackend;
    }

    if (_combatRouteEvents.contains(event)) {
      if (_combatBackendReady && _combatBackend != null) {
        return _combatBackend!;
      }
      return null;
    }

    return _flameBackend;
  }

  void _recordCombatBurst() {
    if (_combatBurstRemaining <= 0) {
      _combatBurstRemaining = _combatBurstWindow;
      _combatBurstCount = 0;
    }

    _combatBurstCount += 1;
    if (_combatBurstCount < _combatBurstThreshold) {
      return;
    }

    _combatBurstCount = 0;
    _combatSilenceRemaining = _combatSilenceDuration;
    for (final event in _combatHeavyEvents) {
      if (event == AudioEvent.baseDamage) {
        continue;
      }
      _queuedEvents.remove(event);
    }
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {
      // Ignore music teardown failures.
    }
  }

  Future<void> dispose() async {
    await _combatBackend?.dispose();
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
