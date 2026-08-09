enum BarrierConnectionShape { isolated, cap, straight, corner, tee, cross }

class BarrierConnectionRecipe {
  const BarrierConnectionRecipe(this.shape, this.quarterTurns);

  final BarrierConnectionShape shape;
  final int quarterTurns;
}

class BarrierConnectivity {
  static const List<BarrierConnectionRecipe> _recipes = [
    BarrierConnectionRecipe(BarrierConnectionShape.isolated, 0),
    BarrierConnectionRecipe(BarrierConnectionShape.cap, 0),
    BarrierConnectionRecipe(BarrierConnectionShape.cap, 1),
    BarrierConnectionRecipe(BarrierConnectionShape.corner, 0),
    BarrierConnectionRecipe(BarrierConnectionShape.cap, 2),
    BarrierConnectionRecipe(BarrierConnectionShape.straight, 0),
    BarrierConnectionRecipe(BarrierConnectionShape.corner, 1),
    BarrierConnectionRecipe(BarrierConnectionShape.tee, 1),
    BarrierConnectionRecipe(BarrierConnectionShape.cap, 3),
    BarrierConnectionRecipe(BarrierConnectionShape.corner, 3),
    BarrierConnectionRecipe(BarrierConnectionShape.straight, 1),
    BarrierConnectionRecipe(BarrierConnectionShape.tee, 0),
    BarrierConnectionRecipe(BarrierConnectionShape.corner, 2),
    BarrierConnectionRecipe(BarrierConnectionShape.tee, 3),
    BarrierConnectionRecipe(BarrierConnectionShape.tee, 2),
    BarrierConnectionRecipe(BarrierConnectionShape.cross, 0),
  ];

  static int mask({
    required bool north,
    required bool east,
    required bool south,
    required bool west,
  }) {
    return (north ? 1 : 0) | (east ? 2 : 0) | (south ? 4 : 0) | (west ? 8 : 0);
  }

  static BarrierConnectionRecipe recipe(int mask) {
    if (mask < 0 || mask >= _recipes.length) {
      throw RangeError.range(mask, 0, _recipes.length - 1, 'mask');
    }
    return _recipes[mask];
  }
}
