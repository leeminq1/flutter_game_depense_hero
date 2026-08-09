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

enum StageOneBarrierTileKind { isolated }

/// Stage 1 always uses one self-contained, full-cell wall module. Neighboring
/// roads and barriers must not change its image or rotation.
class StageOneBarrierTilePlan {
  const StageOneBarrierTilePlan(this.kind, this.quarterTurns);

  static const fullCell = StageOneBarrierTilePlan(
    StageOneBarrierTileKind.isolated,
    0,
  );

  final StageOneBarrierTileKind kind;
  final int quarterTurns;

  static StageOneBarrierTilePlan fromRoadMask(int mask) {
    if (mask < 0 || mask > 15) {
      throw RangeError.range(mask, 0, 15, 'mask');
    }
    return fullCell;
  }
}
