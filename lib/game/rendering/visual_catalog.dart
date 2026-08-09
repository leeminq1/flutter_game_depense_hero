import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/structure_visual_definition.dart';

enum VisualTokenShape {
  circle,
  diamond,
  square,
  hexagon,
  shrine,
  mill,
  brute,
  caster,
  boss,
}

class UnitVisualDefinition {
  const UnitVisualDefinition({
    required this.assetPath,
    required this.shape,
    required this.primaryColor,
    required this.accentColor,
    required this.baseSize,
    required this.renderScale,
    required this.generatorHint,
    this.frames = 1,
  });

  final String assetPath;
  final VisualTokenShape shape;
  final Color primaryColor;
  final Color accentColor;
  final double baseSize;
  final double renderScale;
  final String generatorHint;
  final int frames;
}

class StageOneVisualCatalog {
  static const String _root = 'assets/sprites/stage1';
  static const Color groundBaseColor = Color(0xFF789322);
  static const double groundTextureOpacity = 0.22;

  static bool enabledForStage(int stageNumber) => stageNumber <= 1;

  static StructureVisualDefinition tower(TowerKind kind) {
    final fileName = switch (kind) {
      TowerKind.archer => 'archer',
      TowerKind.guardBarracks => 'guard_barracks',
      TowerKind.mageObelisk => 'mage_obelisk',
      TowerKind.frostShrine => 'frost_shrine',
      TowerKind.coinMill => 'coin_mill',
      TowerKind.ballista => 'ballista',
      TowerKind.emberkeep => 'ember_keep',
    };
    return StructureVisualDefinition(
      assetPath: '$_root/towers/$fileName.png',
      sourcePixelSize: const Size(128, 160),
      footprintTiles: const Size(1, 1),
      renderTiles: const Size(1, 1.58),
      anchor: const Offset(0.5, 0.86),
      drawOffsetTiles: const Offset(0, 0.08),
      baseLayer: WorldRenderLayer.structure,
      castsShadow: true,
    );
  }

  static const StructureVisualDefinition citadel = StructureVisualDefinition(
    assetPath: '$_root/environment/tutorial_citadel.png',
    sourcePixelSize: Size(224, 224),
    footprintTiles: Size(3, 3),
    renderTiles: Size(3.25, 3.25),
    anchor: Offset(0.5, 0.82),
    drawOffsetTiles: Offset(0, 0.45),
    baseLayer: WorldRenderLayer.structure,
    castsShadow: true,
  );

  static const StructureVisualDefinition villageGatehouse =
      StructureVisualDefinition(
        assetPath: '$_root/environment/village_gatehouse.png',
        sourcePixelSize: Size(256, 256),
        footprintTiles: Size(2, 3),
        renderTiles: Size(2.7, 2.7),
        anchor: Offset(0.5, 0.92),
        drawOffsetTiles: Offset(0, 0.08),
        baseLayer: WorldRenderLayer.structure,
        castsShadow: true,
      );

  static const StructureVisualDefinition roadSignpost =
      StructureVisualDefinition(
        assetPath: '$_root/environment/road_signpost.png',
        sourcePixelSize: Size(112, 144),
        footprintTiles: Size(1, 1),
        renderTiles: Size(0.95, 1.2),
        anchor: Offset(0.5, 0.92),
        drawOffsetTiles: Offset.zero,
        baseLayer: WorldRenderLayer.groundObject,
        castsShadow: true,
      );

  static const StructureVisualDefinition well = StructureVisualDefinition(
    assetPath: '$_root/environment/well.png',
    sourcePixelSize: Size(160, 160),
    footprintTiles: Size(1, 1),
    renderTiles: Size(1.35, 1.35),
    anchor: Offset(0.5, 0.9),
    drawOffsetTiles: Offset.zero,
    baseLayer: WorldRenderLayer.groundObject,
    castsShadow: true,
  );

  static const StructureVisualDefinition brokenSupplyWagon =
      StructureVisualDefinition(
        assetPath: '$_root/environment/broken_supply_wagon.png',
        sourcePixelSize: Size(192, 160),
        footprintTiles: Size(1, 1),
        renderTiles: Size(1.5, 1.25),
        anchor: Offset(0.5, 0.88),
        drawOffsetTiles: Offset.zero,
        baseLayer: WorldRenderLayer.groundObject,
        castsShadow: true,
      );

  static const StructureVisualDefinition supplyCart = StructureVisualDefinition(
    assetPath: '$_root/environment/supply_cart.png',
    sourcePixelSize: Size(128, 128),
    footprintTiles: Size(1, 1),
    renderTiles: Size(1.2, 1.2),
    anchor: Offset(0.5, 0.88),
    drawOffsetTiles: Offset.zero,
    baseLayer: WorldRenderLayer.groundObject,
    castsShadow: true,
  );

  static StructureVisualDefinition? environmentForLegacyPath(String path) {
    if (path.endsWith('/village_gate.png')) {
      return villageGatehouse;
    }
    if (path.endsWith('/road_signpost.png')) {
      return roadSignpost;
    }
    if (path.endsWith('/well.png')) {
      return well;
    }
    if (path.endsWith('/wagon_wreck.png')) {
      return brokenSupplyWagon;
    }
    if (path.endsWith('/supply_crate.png')) {
      return supplyCart;
    }
    return null;
  }

  static bool shouldHideLegacyDecoration(String path) =>
      path.endsWith('/wooden_fence_segment.png');

  static const String grassBase = '$_root/tiles/grass_base.png';
  static const String grassAlt = '$_root/tiles/grass_alt.png';
  static const String roadStraight = '$_root/tiles/road_straight.png';
  static const String roadCorner = '$_root/tiles/road_corner.png';
  static const String roadCap = '$_root/tiles/road_cap.png';
  static const String roadFill = '$_root/tiles/road_fill.png';

  static Map<String, String> barrierModulePaths(BarrierKind kind) {
    final material = switch (kind) {
      BarrierKind.woodFence => 'wood',
      BarrierKind.stoneWall => 'stone',
      BarrierKind.reinforcedWall || BarrierKind.fortressWall => 'fortress',
    };
    return {
      'isolated': '$_root/walls/$material/isolated.png',
      'straight': '$_root/walls/$material/straight.png',
      'corner': '$_root/walls/$material/corner.png',
    };
  }

  static Iterable<String> get assetPaths sync* {
    for (final kind in TowerKind.values) {
      yield tower(kind).assetPath;
    }
    yield citadel.assetPath;
    yield villageGatehouse.assetPath;
    yield roadSignpost.assetPath;
    yield well.assetPath;
    yield brokenSupplyWagon.assetPath;
    yield supplyCart.assetPath;
    yield grassBase;
    yield grassAlt;
    yield roadStraight;
    yield roadCorner;
    yield roadCap;
    yield roadFill;
    for (final kind in BarrierKind.values) {
      yield* barrierModulePaths(kind).values;
    }
    yield '$_root/walls/keep/straight.png';
  }
}

class TowerVisualCatalog {
  static const List<TowerKind> kinds = TowerKind.values;
  static const int maxTier = 3;

  static UnitVisualDefinition byKind(TowerKind kind) {
    switch (kind) {
      case TowerKind.archer:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/archer_tower.png',
          shape: VisualTokenShape.circle,
          primaryColor: Color(0xFF5E8F4C),
          accentColor: Color(0xFFE7D99A),
          baseSize: 18,
          renderScale: 3.0,
          generatorHint:
              'wooden archer post, green hood banner, fantasy defense tower',
          frames: 3,
        );
      case TowerKind.guardBarracks:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/guard_barracks.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFF84634C),
          accentColor: Color(0xFFF1D6AE),
          baseSize: 18,
          renderScale: 3.15,
          generatorHint:
              'small fantasy barracks, shield rack, brown timber guard post',
          frames: 3,
        );
      case TowerKind.mageObelisk:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/mage_obelisk.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFF6D63B8),
          accentColor: Color(0xFFCBBEFF),
          baseSize: 18,
          renderScale: 3.0,
          generatorHint: 'arcane obelisk, violet crystal, fantasy magic tower',
          frames: 3,
        );
      case TowerKind.frostShrine:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/frost_shrine.png',
          shape: VisualTokenShape.shrine,
          primaryColor: Color(0xFF4C8E96),
          accentColor: Color(0xFFC9F5FF),
          baseSize: 18,
          renderScale: 3.0,
          generatorHint: 'icy shrine, blue crystal altar, frost defense tower',
          frames: 3,
        );
      case TowerKind.coinMill:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/coin_mill.png',
          shape: VisualTokenShape.mill,
          primaryColor: Color(0xFFB59344),
          accentColor: Color(0xFFFBE0A2),
          baseSize: 18,
          renderScale: 3.05,
          generatorHint:
              'golden coin mill, fantasy workshop, economic support building',
          frames: 3,
        );
      case TowerKind.ballista:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/ballista.png',
          shape: VisualTokenShape.hexagon,
          primaryColor: Color(0xFF7C5E3A),
          accentColor: Color(0xFFF0D8B5),
          baseSize: 19,
          renderScale: 3.2,
          generatorHint:
              'heavy ballista emplacement, siege wood frame, defense turret',
          frames: 3,
        );
      case TowerKind.emberkeep:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/emberkeep.png',
          shape: VisualTokenShape.shrine,
          primaryColor: Color(0xFFBC5B2C),
          accentColor: Color(0xFFFFD0A1),
          baseSize: 19,
          renderScale: 3.1,
          generatorHint:
              'fire brazier keep, ember brazier, fantasy flame tower',
          frames: 3,
        );
    }
  }

  static String tierAssetPath(TowerKind kind, int level) {
    final visual = byKind(kind);
    final tier = level.clamp(1, maxTier);
    final dotIndex = visual.assetPath.lastIndexOf('.');
    if (dotIndex == -1) {
      return '${visual.assetPath}_t$tier';
    }
    final prefix = visual.assetPath.substring(0, dotIndex);
    final suffix = visual.assetPath.substring(dotIndex);
    return '${prefix}_t$tier$suffix';
  }

  static String branchTierAssetPath(
    TowerKind kind,
    int level,
    String branchId,
  ) {
    final visual = byKind(kind);
    final tier = level.clamp(1, maxTier);
    final dotIndex = visual.assetPath.lastIndexOf('.');
    if (dotIndex == -1) {
      return '${visual.assetPath}_${branchId}_t$tier';
    }
    final prefix = visual.assetPath.substring(0, dotIndex);
    final suffix = visual.assetPath.substring(dotIndex);
    return '${prefix}_${branchId}_t$tier$suffix';
  }
}

class BarracksDefenderVisualCatalog {
  static const String _basePath = 'assets/sprites/defenders';
  static const double renderSize = 24;

  static List<String> assetPaths() {
    return const [
      'assets/sprites/defenders/barracks_defender_t1.png',
      'assets/sprites/defenders/barracks_defender_t2.png',
      'assets/sprites/defenders/barracks_defender_t3.png',
      'assets/sprites/defenders/barracks_defender_vanguard_t2.png',
      'assets/sprites/defenders/barracks_defender_vanguard_t3.png',
      'assets/sprites/defenders/barracks_defender_sentinel_t2.png',
      'assets/sprites/defenders/barracks_defender_sentinel_t3.png',
    ];
  }

  static String assetPath({required int level, String? branchId}) {
    final tier = level.clamp(1, TowerVisualCatalog.maxTier);
    if (branchId != null && tier >= 2) {
      return '$_basePath/barracks_defender_${branchId}_t$tier.png';
    }
    return '$_basePath/barracks_defender_t$tier.png';
  }
}

class BarrierVisualCatalog {
  static const String _basePath = 'assets/sprites/barriers';

  static List<String> assetPaths() {
    return BarrierKind.values.map(assetPath).toList(growable: false);
  }

  static String assetPath(BarrierKind kind) {
    return switch (kind) {
      BarrierKind.woodFence => '$_basePath/wood_fence.png',
      BarrierKind.stoneWall => '$_basePath/stone_wall.png',
      BarrierKind.reinforcedWall => '$_basePath/reinforced_wall.png',
      BarrierKind.fortressWall => '$_basePath/fortress_wall.png',
    };
  }
}

class EffectVisualCatalog {
  static const arrowProjectile = 'arrow_projectile';
  static const siegeBoltProjectile = 'siege_bolt_projectile';
  static const arcaneBoltProjectile = 'arcane_bolt_projectile';
  static const cannonballProjectile = 'cannonball_projectile';
  static const shurikenProjectile = 'shuriken_projectile';
  static const bossShockwaveImpact = 'boss_shockwave_impact';
  static const frostImpact = 'frost_impact';
  static const flameImpact = 'flame_impact';

  static const String _basePath = 'assets/sprites/effects';

  static const Map<String, String> _assetPaths = {
    arrowProjectile: '$_basePath/arrow_projectile.png',
    siegeBoltProjectile: '$_basePath/siege_bolt_projectile.png',
    arcaneBoltProjectile: '$_basePath/arcane_bolt_projectile.png',
    cannonballProjectile: '$_basePath/cannonball_projectile.png',
    shurikenProjectile: '$_basePath/shuriken_projectile.png',
    bossShockwaveImpact: '$_basePath/boss_shockwave_impact.png',
    frostImpact: '$_basePath/frost_impact.png',
    flameImpact: '$_basePath/flame_impact.png',
  };

  static Iterable<String> get ids => _assetPaths.keys;

  static String assetPath(String id) => _assetPaths[id] ?? '';
}

class EnemyVisualCatalog {
  static const List<EnemyKind> kinds = EnemyKind.values;

  static UnitVisualDefinition byKind(EnemyKind kind) {
    switch (kind) {
      case EnemyKind.raider:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/raider.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFFB85C38),
          accentColor: Color(0xFFFFC18E),
          baseSize: 18,
          renderScale: 2.15,
          generatorHint:
              'bandit raider, rugged leather armor, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.scout:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/scout.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFFD89C45),
          accentColor: Color(0xFFFFEDB1),
          baseSize: 16,
          renderScale: 2.05,
          generatorHint: 'fast rogue scout, light gear, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.bannerCaptain:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/banner_captain.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFF9E523C),
          accentColor: Color(0xFFFFD4A0),
          baseSize: 18,
          renderScale: 2.12,
          generatorHint:
              'bandit banner captain, leather leader, spear and plume, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.wolfScout:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/wolf_scout.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFF8B7A57),
          accentColor: Color(0xFFF5E5BE),
          baseSize: 16,
          renderScale: 2.08,
          generatorHint:
              'wolf scout, beastfolk skirmisher, fast dark fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.shieldInfantry:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/shield_infantry.png',
          shape: VisualTokenShape.hexagon,
          primaryColor: Color(0xFF7D8EA3),
          accentColor: Color(0xFFDCEBFF),
          baseSize: 18,
          renderScale: 2.15,
          generatorHint: 'armored infantry, shield bearer, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.cultAdept:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/cult_adept.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF6E4EAA),
          accentColor: Color(0xFFD5C2FF),
          baseSize: 18,
          renderScale: 2.1,
          generatorHint:
              'hooded cult adept, ritual caster, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.skeleton:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/skeleton.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFFBDB9AA),
          accentColor: Color(0xFFF8F4E2),
          baseSize: 18,
          renderScale: 2.05,
          generatorHint:
              'animated skeleton soldier, bone warrior, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.boneArcher:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/bone_archer.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFFC8C1AF),
          accentColor: Color(0xFFFFF0D6),
          baseSize: 17,
          renderScale: 2.08,
          generatorHint:
              'bone archer, undead bow skirmisher, dark fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.graveGuard:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/grave_guard.png',
          shape: VisualTokenShape.brute,
          primaryColor: Color(0xFF63705F),
          accentColor: Color(0xFFDAE5D1),
          baseSize: 20,
          renderScale: 2.2,
          generatorHint:
              'undead grave guard, heavy armor, dark green elite enemy',
          frames: 3,
        );
      case EnemyKind.plagueBearer:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/plague_bearer.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF5E7152),
          accentColor: Color(0xFFCDE2A8),
          baseSize: 18,
          renderScale: 2.12,
          generatorHint:
              'plague bearer, undead support, plague hood and censer, fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.corruptedKnight:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/corrupted_knight.png',
          shape: VisualTokenShape.brute,
          primaryColor: Color(0xFF7A5151),
          accentColor: Color(0xFFF0CBCB),
          baseSize: 20,
          renderScale: 2.25,
          generatorHint:
              'corrupted knight, dark plate armor, cursed elite enemy',
          frames: 3,
        );
      case EnemyKind.hexSniper:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/hex_sniper.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF5C4B73),
          accentColor: Color(0xFFCBE4B7),
          baseSize: 18,
          renderScale: 2.1,
          generatorHint:
              'hex sniper, cursed crossbow support, dark fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.warlock:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/warlock.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF5E3E88),
          accentColor: Color(0xFFD7BEFF),
          baseSize: 19,
          renderScale: 2.15,
          generatorHint:
              'warlock summoner, purple robes, dark fantasy pixel caster',
          frames: 3,
        );
      case EnemyKind.bastionPriest:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/bastion_priest.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF8A7A5E),
          accentColor: Color(0xFFFFE7B8),
          baseSize: 19,
          renderScale: 2.16,
          generatorHint:
              'bastion priest, plated cleric support, dark fantasy pixel enemy',
          frames: 3,
        );
      case EnemyKind.bastionOverlord:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/bastion_overlord.png',
          shape: VisualTokenShape.boss,
          primaryColor: Color(0xFF8C3F34),
          accentColor: Color(0xFFFFD5A8),
          baseSize: 28,
          renderScale: 2.65,
          generatorHint:
              'final boss overlord, cursed fortress lord, huge dark fantasy pixel enemy',
          frames: 3,
        );
    }
  }

  /// Returns the asset path for a specific animation frame (frame >= 1).
  /// Frame 0 uses the base assetPath. Frame 1+ uses _walk_02, _walk_03, etc.
  static String frameAssetPath(EnemyKind kind, int frame) {
    final visual = byKind(kind);
    final base = visual.assetPath;
    if (frame <= 0) return base;
    final dotIndex = base.lastIndexOf('.');
    if (dotIndex == -1) return base;
    final prefix = base.substring(0, dotIndex);
    final suffix = base.substring(dotIndex);
    // frame 0 → base file, frame 1 → _walk_02, frame 2 → _walk_03
    return '${prefix}_walk_0${frame + 1}$suffix';
  }

  static String enemyId(EnemyKind kind) {
    final assetPath = byKind(kind).assetPath;
    final slashIndex = assetPath.lastIndexOf('/');
    final dotIndex = assetPath.lastIndexOf('.');
    return assetPath.substring(slashIndex + 1, dotIndex);
  }

  static String directionalBaseAssetPath(EnemyKind kind, String direction) {
    return 'assets/sprites/enemies/${enemyId(kind)}/$direction/base.png';
  }

  static String directionalFrameAssetPath(
    EnemyKind kind,
    String direction,
    int frame,
  ) {
    if (frame <= 0) {
      return directionalBaseAssetPath(kind, direction);
    }
    return 'assets/sprites/enemies/${enemyId(kind)}/$direction/walk_0${frame + 1}.png';
  }
}

class HeroVisualCatalog {
  static const List<HeroKind> kinds = HeroKind.values;

  static UnitVisualDefinition byKind(HeroKind kind) {
    switch (kind) {
      case HeroKind.knight:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/heroes/knight/south/base.png',
          shape: VisualTokenShape.hexagon,
          primaryColor: Color(0xFF77A7FF),
          accentColor: Color(0xFFE6F0FF),
          baseSize: 20,
          renderScale: 2.15,
          generatorHint: 'hero knight, blue cloak, bright plate armor',
          frames: 3,
        );
      case HeroKind.archer:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/heroes/archer/south/base.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFF9AD66F),
          accentColor: Color(0xFFE6FFD0),
          baseSize: 18,
          renderScale: 2.1,
          generatorHint: 'hero archer, green cloak, elegant longbow',
          frames: 3,
        );
      case HeroKind.mage:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/heroes/mage/south/base.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFFC07BFF),
          accentColor: Color(0xFFF2D8FF),
          baseSize: 19,
          renderScale: 2.12,
          generatorHint: 'hero mage, ornate purple robe, arcane staff',
          frames: 3,
        );
      case HeroKind.ninja:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/heroes/ninja/south/base.png',
          shape: VisualTokenShape.diamond,
          primaryColor: Color(0xFFFF6D7A),
          accentColor: Color(0xFFFFD0D5),
          baseSize: 18,
          renderScale: 2.08,
          generatorHint: 'hero ninja, dark hood, crimson scarf, dual blades',
          frames: 3,
        );
      case HeroKind.paladin:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/heroes/paladin/south/base.png',
          shape: VisualTokenShape.brute,
          primaryColor: Color(0xFFFFD166),
          accentColor: Color(0xFFFFF0BC),
          baseSize: 21,
          renderScale: 2.2,
          generatorHint: 'hero paladin, white gold armor, holy mace and cape',
          frames: 3,
        );
    }
  }

  static String directionalBaseAssetPath(HeroKind kind, String direction) {
    return 'assets/sprites/heroes/${HeroCatalog.heroId(kind)}/$direction/base.png';
  }

  static String directionalFrameAssetPath(
    HeroKind kind,
    String direction,
    int frame,
  ) {
    if (frame <= 0) {
      return directionalBaseAssetPath(kind, direction);
    }
    return 'assets/sprites/heroes/${HeroCatalog.heroId(kind)}/$direction/walk_0${frame + 1}.png';
  }
}
