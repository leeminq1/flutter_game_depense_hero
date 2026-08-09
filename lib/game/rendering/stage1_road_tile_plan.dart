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

enum StageOneBarrierTileKind { straight, isolated }

/// Stage 1 walls are barricades: their long edge must cross the road axis.
/// A corner or junction uses the self-contained module instead of guessing an
/// adjacency direction from neighboring barriers.
class StageOneBarrierTilePlan {
  const StageOneBarrierTilePlan(this.kind, this.quarterTurns);

  final StageOneBarrierTileKind kind;
  final int quarterTurns;

  static StageOneBarrierTilePlan fromRoadMask(int mask) {
    if (mask < 0 || mask > 15) {
      throw RangeError.range(mask, 0, 15, 'mask');
    }
    final hasVerticalRoad = (mask & 5) != 0;
    final hasHorizontalRoad = (mask & 10) != 0;
    if (hasVerticalRoad && !hasHorizontalRoad) {
      return const StageOneBarrierTilePlan(StageOneBarrierTileKind.straight, 0);
    }
    if (hasHorizontalRoad && !hasVerticalRoad) {
      return const StageOneBarrierTilePlan(StageOneBarrierTileKind.straight, 1);
    }
    return const StageOneBarrierTilePlan(StageOneBarrierTileKind.isolated, 0);
  }
}
