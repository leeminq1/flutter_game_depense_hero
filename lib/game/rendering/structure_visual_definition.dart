import 'dart:ui';

enum WorldRenderLayer { groundObject, structure, unit }

class StructureVisualDefinition {
  const StructureVisualDefinition({
    required this.assetPath,
    required this.sourcePixelSize,
    required this.footprintTiles,
    required this.renderTiles,
    required this.anchor,
    required this.drawOffsetTiles,
    required this.baseLayer,
    required this.castsShadow,
  });

  final String assetPath;
  final Size sourcePixelSize;
  final Size footprintTiles;
  final Size renderTiles;
  final Offset anchor;
  final Offset drawOffsetTiles;
  final WorldRenderLayer baseLayer;
  final bool castsShadow;

  Rect destinationRect({
    required Offset worldAnchor,
    required double tileSize,
  }) {
    final requestedHeight = renderTiles.height * tileSize;
    final sourceRatio = sourcePixelSize.width / sourcePixelSize.height;
    final width = requestedHeight * sourceRatio;
    final pivot = worldAnchor + drawOffsetTiles * tileSize;
    return Rect.fromLTWH(
      pivot.dx - width * anchor.dx,
      pivot.dy - requestedHeight * anchor.dy,
      width,
      requestedHeight,
    );
  }
}
