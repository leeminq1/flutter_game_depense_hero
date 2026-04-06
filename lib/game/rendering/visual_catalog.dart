import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';

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
          generatorHint: 'wooden archer post, green hood banner, fantasy defense tower',
          frames: 1,
        );
      case TowerKind.guardBarracks:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/guard_barracks.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFF84634C),
          accentColor: Color(0xFFF1D6AE),
          baseSize: 18,
          renderScale: 3.15,
          generatorHint: 'small fantasy barracks, shield rack, brown timber guard post',
          frames: 1,
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
          frames: 1,
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
          frames: 1,
        );
      case TowerKind.coinMill:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/coin_mill.png',
          shape: VisualTokenShape.mill,
          primaryColor: Color(0xFFB59344),
          accentColor: Color(0xFFFBE0A2),
          baseSize: 18,
          renderScale: 3.05,
          generatorHint: 'golden coin mill, fantasy workshop, economic support building',
          frames: 1,
        );
      case TowerKind.ballista:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/ballista.png',
          shape: VisualTokenShape.hexagon,
          primaryColor: Color(0xFF7C5E3A),
          accentColor: Color(0xFFF0D8B5),
          baseSize: 19,
          renderScale: 3.2,
          generatorHint: 'heavy ballista emplacement, siege wood frame, defense turret',
          frames: 1,
        );
      case TowerKind.emberkeep:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/towers/emberkeep.png',
          shape: VisualTokenShape.shrine,
          primaryColor: Color(0xFFBC5B2C),
          accentColor: Color(0xFFFFD0A1),
          baseSize: 19,
          renderScale: 3.1,
          generatorHint: 'fire brazier keep, ember brazier, fantasy flame tower',
          frames: 1,
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

  static String assetPath({
    required int level,
    String? branchId,
  }) {
    final tier = level.clamp(1, TowerVisualCatalog.maxTier);
    if (branchId != null && tier >= 2) {
      return '$_basePath/barracks_defender_${branchId}_t$tier.png';
    }
    return '$_basePath/barracks_defender_t$tier.png';
  }
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
          generatorHint: 'bandit raider, rugged leather armor, fantasy pixel enemy',
          frames: 1,
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
          frames: 1,
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
          frames: 1,
        );
      case EnemyKind.cultAdept:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/cult_adept.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF6E4EAA),
          accentColor: Color(0xFFD5C2FF),
          baseSize: 18,
          renderScale: 2.1,
          generatorHint: 'hooded cult adept, ritual caster, fantasy pixel enemy',
          frames: 1,
        );
      case EnemyKind.skeleton:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/skeleton.png',
          shape: VisualTokenShape.square,
          primaryColor: Color(0xFFBDB9AA),
          accentColor: Color(0xFFF8F4E2),
          baseSize: 18,
          renderScale: 2.05,
          generatorHint: 'animated skeleton soldier, bone warrior, fantasy pixel enemy',
          frames: 1,
        );
      case EnemyKind.graveGuard:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/grave_guard.png',
          shape: VisualTokenShape.brute,
          primaryColor: Color(0xFF63705F),
          accentColor: Color(0xFFDAE5D1),
          baseSize: 20,
          renderScale: 2.2,
          generatorHint: 'undead grave guard, heavy armor, dark green elite enemy',
          frames: 1,
        );
      case EnemyKind.corruptedKnight:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/corrupted_knight.png',
          shape: VisualTokenShape.brute,
          primaryColor: Color(0xFF7A5151),
          accentColor: Color(0xFFF0CBCB),
          baseSize: 20,
          renderScale: 2.25,
          generatorHint: 'corrupted knight, dark plate armor, cursed elite enemy',
          frames: 1,
        );
      case EnemyKind.warlock:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/warlock.png',
          shape: VisualTokenShape.caster,
          primaryColor: Color(0xFF5E3E88),
          accentColor: Color(0xFFD7BEFF),
          baseSize: 19,
          renderScale: 2.15,
          generatorHint: 'warlock summoner, purple robes, dark fantasy pixel caster',
          frames: 1,
        );
      case EnemyKind.bastionOverlord:
        return const UnitVisualDefinition(
          assetPath: 'assets/sprites/enemies/bastion_overlord.png',
          shape: VisualTokenShape.boss,
          primaryColor: Color(0xFF8C3F34),
          accentColor: Color(0xFFFFD5A8),
          baseSize: 28,
          renderScale: 2.65,
          generatorHint: 'final boss overlord, cursed fortress lord, huge dark fantasy pixel enemy',
          frames: 1,
        );
    }
  }
}
