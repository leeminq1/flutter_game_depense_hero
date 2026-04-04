import 'dart:async';
import 'dart:ui' as ui;

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flutter/services.dart';

class GameVisualRegistry {
  final Map<String, ui.Image> _towerSprites = {};
  final Map<String, ui.Image> _enemySprites = {};
  final Map<String, ui.Image> _supportSprites = {};
  final Map<String, ui.Image> _environmentSprites = {};

  bool _warmed = false;

  Future<void> warmUp() async {
    if (_warmed) {
      return;
    }

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assetKeys = manifest.listAssets().toSet();

    for (final kind in TowerVisualCatalog.kinds) {
      final visual = TowerVisualCatalog.byKind(kind);
      if (assetKeys.contains(visual.assetPath)) {
        _towerSprites[visual.assetPath] = await _loadImage(visual.assetPath);
      }
      for (var level = 1; level <= TowerVisualCatalog.maxTier; level += 1) {
        final tierAssetPath = TowerVisualCatalog.tierAssetPath(kind, level);
        if (!assetKeys.contains(tierAssetPath)) {
          continue;
        }
        _towerSprites[tierAssetPath] = await _loadImage(tierAssetPath);
      }
      for (final branch in TowerCatalog.byKind(kind).branches) {
        for (var level = 2; level <= TowerVisualCatalog.maxTier; level += 1) {
          final branchAssetPath = TowerVisualCatalog.branchTierAssetPath(
            kind,
            level,
            branch.id,
          );
          if (!assetKeys.contains(branchAssetPath)) {
            continue;
          }
          _towerSprites[branchAssetPath] = await _loadImage(branchAssetPath);
        }
      }
    }

    for (final kind in EnemyVisualCatalog.kinds) {
      final visual = EnemyVisualCatalog.byKind(kind);
      if (!assetKeys.contains(visual.assetPath)) {
        continue;
      }
      _enemySprites[visual.assetPath] = await _loadImage(visual.assetPath);
    }

    final barracksDefenderAssetPaths = <String>{
      for (var level = 1; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(level: level),
      for (var level = 2; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(level: level, branchId: 'vanguard'),
      for (var level = 2; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(level: level, branchId: 'sentinel'),
    };
    for (final assetPath in barracksDefenderAssetPaths) {
      if (!assetKeys.contains(assetPath)) {
        continue;
      }
      _supportSprites[assetPath] = await _loadImage(assetPath);
    }

    for (final assetPath in assetKeys) {
      if (!assetPath.startsWith('assets/sprites/environment/') ||
          !assetPath.endsWith('.png')) {
        continue;
      }
      _environmentSprites[assetPath] = await _loadImage(assetPath);
    }

    _warmed = true;
  }

  ui.Image? towerSprite(TowerKind kind, {int level = 1, String? branchId}) {
    if (branchId != null && level >= 2) {
      final branchAssetPath = TowerVisualCatalog.branchTierAssetPath(
        kind,
        level,
        branchId,
      );
      final branchSprite = _towerSprites[branchAssetPath];
      if (branchSprite != null) {
        return branchSprite;
      }
    }
    final tierAssetPath = TowerVisualCatalog.tierAssetPath(kind, level);
    final fallbackAssetPath = TowerVisualCatalog.byKind(kind).assetPath;
    return _towerSprites[tierAssetPath] ?? _towerSprites[fallbackAssetPath];
  }

  ui.Image? enemySprite(EnemyKind kind) {
    final assetPath = EnemyVisualCatalog.byKind(kind).assetPath;
    return _enemySprites[assetPath];
  }

  ui.Image? barracksDefenderSprite({
    required int level,
    String? branchId,
  }) {
    final assetPath = BarracksDefenderVisualCatalog.assetPath(
      level: level,
      branchId: branchId,
    );
    final fallbackPath = BarracksDefenderVisualCatalog.assetPath(level: level);
    return _supportSprites[assetPath] ?? _supportSprites[fallbackPath];
  }

  ui.Image? environmentSprite(String assetPath) {
    return _environmentSprites[assetPath];
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return _decodeImage(byteData.buffer.asUint8List());
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }
}
