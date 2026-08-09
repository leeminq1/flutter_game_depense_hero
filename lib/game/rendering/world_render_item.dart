import 'dart:ui';

class WorldRenderItem {
  const WorldRenderItem({
    required this.layer,
    required this.groundY,
    required this.stableId,
    required this.draw,
  });

  final int layer;
  final double groundY;
  final int stableId;
  final void Function(Canvas canvas) draw;

  static int compare(WorldRenderItem a, WorldRenderItem b) {
    final byLayer = a.layer.compareTo(b.layer);
    if (byLayer != 0) {
      return byLayer;
    }
    final byGroundY = a.groundY.compareTo(b.groundY);
    if (byGroundY != 0) {
      return byGroundY;
    }
    return a.stableId.compareTo(b.stableId);
  }
}
