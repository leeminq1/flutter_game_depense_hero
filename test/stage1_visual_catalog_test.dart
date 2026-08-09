import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial and stage one use B metadata while stage two falls back', () {
    expect(StageOneVisualCatalog.enabledForStage(0), isTrue);
    expect(StageOneVisualCatalog.enabledForStage(1), isTrue);
    expect(StageOneVisualCatalog.enabledForStage(2), isFalse);
    expect(StageOneVisualCatalog.groundBaseColor.a, 1);
    expect(
      StageOneVisualCatalog.groundTextureOpacity,
      inInclusiveRange(0, 0.35),
    );
    expect(
      StageOneVisualCatalog.tower(TowerKind.archer).anchor.dy,
      greaterThan(0.5),
    );
  });

  test('all structures and connected wall modules are declared', () {
    for (final kind in TowerKind.values) {
      expect(StageOneVisualCatalog.tower(kind).assetPath, endsWith('.png'));
    }
    for (final kind in BarrierKind.values) {
      expect(
        StageOneVisualCatalog.barrierModulePaths(kind).keys,
        containsAll(<String>['isolated', 'straight', 'corner']),
      );
    }
    expect(
      StageOneVisualCatalog.environmentForLegacyPath(
        'assets/sprites/environment/landmarks/village_gate.png',
      )?.assetPath,
      endsWith('village_gatehouse.png'),
    );
    expect(
      StageOneVisualCatalog.environmentForLegacyPath(
        'assets/sprites/environment/props/wagon_wreck.png',
      )?.assetPath,
      endsWith('broken_supply_wagon.png'),
    );
    expect(
      StageOneVisualCatalog.shouldHideLegacyDecoration(
        'assets/sprites/environment/props/wooden_fence_segment.png',
      ),
      isTrue,
    );
  });

  test('every declared Stage 1 asset is bundled and non-empty', () async {
    for (final assetPath in StageOneVisualCatalog.assetPaths.toSet()) {
      final data = await rootBundle.load(assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: assetPath);
    }
  });
}
