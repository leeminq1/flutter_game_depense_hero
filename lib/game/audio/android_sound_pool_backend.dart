import 'dart:io';

import 'package:depense_game/game/audio/combat_sfx_backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidSoundPoolBackend implements CombatSfxBackend {
  static const MethodChannel _channel = MethodChannel(
    'depense_game/combat_sfx',
  );

  bool _initialized = false;

  @override
  Future<bool> initialize(Iterable<String> assets) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('preload', {
        'assets': assets.toList(),
      });
      _initialized = success ?? true;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  @override
  Future<void> play(String asset, {required double volume}) async {
    if (!_initialized) {
      return;
    }

    try {
      await _channel.invokeMethod<bool>('play', {
        'asset': asset,
        'volume': volume,
      });
    } catch (_) {
      // Native low-latency playback is opportunistic only.
    }
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }
    _initialized = false;
    try {
      await _channel.invokeMethod<void>('release');
    } catch (_) {
      // Ignore disposal errors during shutdown.
    }
  }
}
