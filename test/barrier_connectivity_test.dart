import 'package:depense_game/game/rendering/barrier_connectivity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four neighbors map to a stable four-bit mask', () {
    expect(
      BarrierConnectivity.mask(
        north: true,
        east: true,
        south: true,
        west: true,
      ),
      15,
    );
    expect(
      BarrierConnectivity.mask(
        north: true,
        east: false,
        south: true,
        west: false,
      ),
      5,
    );
    expect(
      BarrierConnectivity.mask(
        north: false,
        east: true,
        south: false,
        west: true,
      ),
      10,
    );
  });

  test('all sixteen masks resolve to explicit module recipes', () {
    final recipes = {
      for (var mask = 0; mask < 16; mask++) BarrierConnectivity.recipe(mask),
    };

    expect(recipes, hasLength(16));
    expect(BarrierConnectivity.recipe(15).shape, BarrierConnectionShape.cross);
  });

  test('invalid masks are rejected', () {
    expect(() => BarrierConnectivity.recipe(-1), throwsRangeError);
    expect(() => BarrierConnectivity.recipe(16), throwsRangeError);
  });
}
