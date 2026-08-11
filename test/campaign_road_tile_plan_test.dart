import 'package:depense_game/game/rendering/campaign_road_tile_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all road masks expose exactly their authored connections', () {
    for (var mask = 0; mask < 16; mask += 1) {
      final plan = CampaignRoadTilePlan.fromMask(mask);

      expect(plan.resolvedMask, mask, reason: 'mask $mask');
    }
  });

  test('isolated tee and cross masks use distinct modules', () {
    expect(
      CampaignRoadTilePlan.fromMask(0).kind,
      CampaignRoadTileKind.isolated,
    );
    expect(CampaignRoadTilePlan.fromMask(7).kind, CampaignRoadTileKind.tee);
    expect(CampaignRoadTilePlan.fromMask(11).kind, CampaignRoadTileKind.tee);
    expect(CampaignRoadTilePlan.fromMask(15).kind, CampaignRoadTileKind.cross);
  });

  test('canonical module rotations are deterministic', () {
    expect(CampaignRoadTilePlan.fromMask(1).quarterTurns, 0);
    expect(CampaignRoadTilePlan.fromMask(2).quarterTurns, 1);
    expect(CampaignRoadTilePlan.fromMask(5).quarterTurns, 0);
    expect(CampaignRoadTilePlan.fromMask(10).quarterTurns, 1);
    expect(CampaignRoadTilePlan.fromMask(3).quarterTurns, 0);
    expect(CampaignRoadTilePlan.fromMask(12).quarterTurns, 2);
    expect(CampaignRoadTilePlan.fromMask(11).quarterTurns, 0);
    expect(CampaignRoadTilePlan.fromMask(14).quarterTurns, 2);
  });

  test(
    'campaign barriers retain one full-cell visual for every road shape',
    () {
      for (var roadMask = 0; roadMask < 16; roadMask += 1) {
        final plan = CampaignBarrierTilePlan.fromRoadMask(roadMask);

        expect(plan.kind, CampaignBarrierTileKind.isolated);
        expect(plan.quarterTurns, 0);
      }
    },
  );

  test('invalid masks are rejected', () {
    expect(() => CampaignRoadTilePlan.fromMask(-1), throwsRangeError);
    expect(() => CampaignRoadTilePlan.fromMask(16), throwsRangeError);
    expect(() => CampaignBarrierTilePlan.fromRoadMask(-1), throwsRangeError);
    expect(() => CampaignBarrierTilePlan.fromRoadMask(16), throwsRangeError);
  });
}
