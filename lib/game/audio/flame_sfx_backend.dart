import 'package:depense_game/game/audio/combat_sfx_backend.dart';
import 'package:flame_audio/flame_audio.dart';

class FlameSfxBackend implements CombatSfxBackend {
  @override
  Future<bool> initialize(Iterable<String> assets) async {
    await FlameAudio.audioCache.loadAll(assets.toList());
    return true;
  }

  @override
  Future<void> play(String asset, {required double volume}) {
    return FlameAudio.play(asset, volume: volume);
  }

  @override
  Future<void> dispose() async {}
}
