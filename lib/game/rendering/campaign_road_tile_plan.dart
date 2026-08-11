import 'package:depense_game/game/rendering/barrier_connectivity.dart';

enum CampaignRoadTileKind { isolated, cap, straight, corner, tee, cross }

class CampaignRoadTilePlan {
  const CampaignRoadTilePlan(this.kind, this.quarterTurns);

  final CampaignRoadTileKind kind;
  final int quarterTurns;

  int get resolvedMask => _rotateMask(_baseMask(kind), quarterTurns);

  static CampaignRoadTilePlan fromMask(int mask) {
    final recipe = BarrierConnectivity.recipe(mask);
    return CampaignRoadTilePlan(switch (recipe.shape) {
      BarrierConnectionShape.isolated => CampaignRoadTileKind.isolated,
      BarrierConnectionShape.cap => CampaignRoadTileKind.cap,
      BarrierConnectionShape.straight => CampaignRoadTileKind.straight,
      BarrierConnectionShape.corner => CampaignRoadTileKind.corner,
      BarrierConnectionShape.tee => CampaignRoadTileKind.tee,
      BarrierConnectionShape.cross => CampaignRoadTileKind.cross,
    }, recipe.quarterTurns);
  }

  static int _baseMask(CampaignRoadTileKind kind) {
    return switch (kind) {
      CampaignRoadTileKind.isolated => 0,
      CampaignRoadTileKind.cap => 1,
      CampaignRoadTileKind.straight => 5,
      CampaignRoadTileKind.corner => 3,
      CampaignRoadTileKind.tee => 11,
      CampaignRoadTileKind.cross => 15,
    };
  }

  static int _rotateMask(int mask, int quarterTurns) {
    var rotated = mask;
    for (var turn = 0; turn < quarterTurns % 4; turn += 1) {
      rotated = ((rotated << 1) & 0xF) | ((rotated >> 3) & 0x1);
    }
    return rotated;
  }
}

enum CampaignBarrierTileKind { isolated }

/// Campaign barriers always use one self-contained full-cell module. Road
/// direction and neighboring barriers must not change their footprint or art.
class CampaignBarrierTilePlan {
  const CampaignBarrierTilePlan(this.kind, this.quarterTurns);

  static const fullCell = CampaignBarrierTilePlan(
    CampaignBarrierTileKind.isolated,
    0,
  );

  final CampaignBarrierTileKind kind;
  final int quarterTurns;

  static CampaignBarrierTilePlan fromRoadMask(int mask) {
    if (mask < 0 || mask > 15) {
      throw RangeError.range(mask, 0, 15, 'mask');
    }
    return fullCell;
  }
}
