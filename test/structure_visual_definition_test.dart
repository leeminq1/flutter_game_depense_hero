import 'dart:ui';

import 'package:depense_game/game/rendering/structure_visual_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom-center pivot preserves source aspect ratio', () {
    const visual = StructureVisualDefinition(
      assetPath: 'assets/sprites/stage1/towers/archer.png',
      sourcePixelSize: Size(128, 160),
      footprintTiles: Size(1, 1),
      renderTiles: Size(1, 1.25),
      anchor: Offset(0.5, 0.86),
      drawOffsetTiles: Offset.zero,
      baseLayer: WorldRenderLayer.structure,
      castsShadow: true,
    );

    final rect = visual.destinationRect(
      worldAnchor: const Offset(200, 300),
      tileSize: 64,
    );

    expect(rect.width / rect.height, closeTo(128 / 160, 0.001));
    expect(rect.left + rect.width * 0.5, closeTo(200, 0.001));
    expect(rect.top + rect.height * 0.86, closeTo(300, 0.001));
  });
}
