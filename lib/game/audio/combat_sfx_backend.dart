abstract class CombatSfxBackend {
  Future<bool> initialize(Iterable<String> assets);

  Future<void> play(String asset, {required double volume});

  Future<void> dispose();
}
