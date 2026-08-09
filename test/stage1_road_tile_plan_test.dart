import 'package:depense_game/game/rendering/stage1_road_tile_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('road masks resolve to cap straight corner and fill modules', () {
    expect(StageOneRoadTilePlan.fromMask(4).kind, StageOneRoadTileKind.cap);
    expect(
      StageOneRoadTilePlan.fromMask(5).kind,
      StageOneRoadTileKind.straight,
    );
    expect(StageOneRoadTilePlan.fromMask(12).kind, StageOneRoadTileKind.corner);
    expect(StageOneRoadTilePlan.fromMask(7).kind, StageOneRoadTileKind.fill);
    expect(StageOneRoadTilePlan.fromMask(15).kind, StageOneRoadTileKind.fill);
  });

  test('base source rotations are deterministic', () {
    expect(StageOneRoadTilePlan.fromMask(4).quarterTurns, 0);
    expect(StageOneRoadTilePlan.fromMask(1).quarterTurns, 2);
    expect(StageOneRoadTilePlan.fromMask(10).quarterTurns, 1);
    expect(StageOneRoadTilePlan.fromMask(12).quarterTurns, 0);
  });

  test('stage 1 barriers face across the road instead of along it', () {
    final verticalRoad = StageOneBarrierTilePlan.fromRoadMask(5);
    final horizontalRoad = StageOneBarrierTilePlan.fromRoadMask(10);
    final cornerRoad = StageOneBarrierTilePlan.fromRoadMask(12);

    expect(verticalRoad.kind, StageOneBarrierTileKind.straight);
    expect(verticalRoad.quarterTurns, 0);
    expect(horizontalRoad.kind, StageOneBarrierTileKind.straight);
    expect(horizontalRoad.quarterTurns, 1);
    expect(cornerRoad.kind, StageOneBarrierTileKind.isolated);
  });
}
