enum RoadTileKind {
  fill,
  straightHorizontal,
  straightVertical,
  capToNorth,
  capToSouth,
  capToEast,
  capToWest,
  turnNE,
  turnNW,
  turnSE,
  turnSW,
}

class RoadTileResolver {
  const RoadTileResolver._();

  static RoadTileKind resolve({
    required int col,
    required int row,
    required Set<String> roadCells,
  }) {
    final north = roadCells.contains(key(col, row - 1));
    final south = roadCells.contains(key(col, row + 1));
    final east = roadCells.contains(key(col + 1, row));
    final west = roadCells.contains(key(col - 1, row));
    final count = [north, south, east, west].where((value) => value).length;

    if (count >= 3) {
      return RoadTileKind.fill;
    }
    if (north && south && !east && !west) {
      return RoadTileKind.straightVertical;
    }
    if (east && west && !north && !south) {
      return RoadTileKind.straightHorizontal;
    }
    if (north && east) {
      return RoadTileKind.turnNE;
    }
    if (north && west) {
      return RoadTileKind.turnNW;
    }
    if (south && east) {
      return RoadTileKind.turnSE;
    }
    if (south && west) {
      return RoadTileKind.turnSW;
    }
    if (north) {
      return RoadTileKind.capToNorth;
    }
    if (south) {
      return RoadTileKind.capToSouth;
    }
    if (east) {
      return RoadTileKind.capToEast;
    }
    if (west) {
      return RoadTileKind.capToWest;
    }
    return RoadTileKind.fill;
  }

  static String key(int col, int row) => '$col:$row';
}
