import 'package:depense_game/game/rendering/world_render_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('items sort by layer then ground y then stable id', () {
    final items = [
      WorldRenderItem(layer: 1, groundY: 200, stableId: 2, draw: (_) {}),
      WorldRenderItem(layer: 1, groundY: 100, stableId: 5, draw: (_) {}),
      WorldRenderItem(layer: 0, groundY: 900, stableId: 1, draw: (_) {}),
      WorldRenderItem(layer: 1, groundY: 200, stableId: 1, draw: (_) {}),
    ]..sort(WorldRenderItem.compare);

    expect(items.map((item) => item.stableId), [1, 5, 1, 2]);
  });
}
