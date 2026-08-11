import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/rendering/campaign_road_tile_plan.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial and all 30 campaign stages use campaign visuals', () {
    expect(CampaignVisualCatalog.enabledForStage(0), isTrue);
    for (var stage = 1; stage <= 30; stage += 1) {
      expect(
        CampaignVisualCatalog.enabledForStage(stage),
        isTrue,
        reason: 'Stage $stage',
      );
    }
    expect(CampaignVisualCatalog.enabledForStage(31), isFalse);
  });

  test('all six environment themes have distinct visual treatments', () {
    final treatments = {
      for (final theme in StageEnvironmentTheme.values)
        CampaignVisualCatalog.theme(theme),
    };

    expect(treatments, hasLength(StageEnvironmentTheme.values.length));
    expect(
      treatments.map((treatment) => treatment.groundBaseColor).toSet(),
      hasLength(StageEnvironmentTheme.values.length),
    );
    for (final treatment in treatments) {
      expect(treatment.groundBaseColor.a, 1);
      expect(treatment.groundTextureOpacity, inInclusiveRange(0.04, 0.18));
      expect(treatment.environmentScale, greaterThan(0));
      expect(treatment.landmarkScale, greaterThan(treatment.environmentScale));
    }
  });

  test('all road topology modules and tower tiers are declared', () {
    for (final kind in CampaignRoadTileKind.values) {
      expect(CampaignVisualCatalog.roadAsset(kind), endsWith('.png'));
    }
    for (final kind in TowerKind.values) {
      for (var level = 1; level <= 3; level += 1) {
        expect(
          CampaignVisualCatalog.tower(kind, level: level).assetPath,
          endsWith('.png'),
        );
      }
    }
    for (final kind in BarrierKind.values) {
      expect(
        CampaignVisualCatalog.barrierModulePaths(kind).keys,
        containsAll(<String>['isolated', 'straight', 'corner']),
      );
    }
    expect(
      CampaignVisualCatalog.environmentForLegacyPath(
        'assets/sprites/environment/landmarks/village_gate.png',
      )?.assetPath,
      endsWith('village_gatehouse.png'),
    );
    expect(
      CampaignVisualCatalog.environmentForLegacyPath(
        'assets/sprites/environment/props/wagon_wreck.png',
      )?.assetPath,
      endsWith('broken_supply_wagon.png'),
    );
    expect(
      CampaignVisualCatalog.shouldHideLegacyDecoration(
        'assets/sprites/environment/props/wooden_fence_segment.png',
      ),
      isTrue,
    );
    expect(
      CampaignVisualCatalog.tower(TowerKind.archer).assetPath,
      endsWith('archer.png'),
    );
    expect(
      CampaignVisualCatalog.tower(TowerKind.archer, level: 2).assetPath,
      endsWith('archer_t2.png'),
    );
    expect(
      CampaignVisualCatalog.tower(TowerKind.archer, level: 3).assetPath,
      endsWith('archer_t3.png'),
    );
  });

  test('every declared campaign asset is bundled and non-empty', () async {
    for (final assetPath in CampaignVisualCatalog.assetPaths.toSet()) {
      final data = await rootBundle.load(assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: assetPath);
    }
  });

  test('every authored campaign landmark resolves to upgraded artwork', () {
    final landmarkPaths = <String>{
      for (var stageNumber = 2; stageNumber <= 30; stageNumber += 1)
        for (final decoration in CampaignData.stage(stageNumber).decorations)
          if (decoration.assetPath.contains('/landmarks/'))
            decoration.assetPath,
    };

    expect(landmarkPaths, isNotEmpty);
    for (final legacyPath in landmarkPaths) {
      final definition = CampaignVisualCatalog.environmentForLegacyPath(
        legacyPath,
      );
      expect(definition, isNotNull, reason: legacyPath);
      expect(
        definition!.assetPath,
        isNot(legacyPath),
        reason: '$legacyPath still renders its legacy 96px artwork',
      );
    }
  });

  test('bombardment animation strips are registered and bundled', () async {
    for (final effectId in [
      EffectVisualCatalog.bombardmentShellStrip,
      EffectVisualCatalog.bombardmentImpactStrip,
    ]) {
      final path = EffectVisualCatalog.assetPath(effectId);
      expect(path, endsWith('.png'));
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
