enum StageOneRoadTileKind { cap, straight, corner, fill }

class StageOneRoadTilePlan {
  const StageOneRoadTilePlan(this.kind, this.quarterTurns);

  final StageOneRoadTileKind kind;
  final int quarterTurns;

  static StageOneRoadTilePlan fromMask(int mask) {
    if (mask < 0 || mask > 15) {
      throw RangeError.range(mask, 0, 15, 'mask');
    }
    return const [
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.cap, 2),
      StageOneRoadTilePlan(StageOneRoadTileKind.cap, 3),
      StageOneRoadTilePlan(StageOneRoadTileKind.corner, 2),
      StageOneRoadTilePlan(StageOneRoadTileKind.cap, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.straight, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.corner, 3),
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.cap, 1),
      StageOneRoadTilePlan(StageOneRoadTileKind.corner, 1),
      StageOneRoadTilePlan(StageOneRoadTileKind.straight, 1),
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.corner, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
      StageOneRoadTilePlan(StageOneRoadTileKind.fill, 0),
    ][mask];
  }
}
