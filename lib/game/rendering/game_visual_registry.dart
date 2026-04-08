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

  ui.Image? _grassTile;
  ui.Image? _grassTile2;
  ui.Image? _pathTile;
  ui.Image? _pathEdgeN;
  ui.Image? _pathEdgeS;
  ui.Image? _pathEdgeE;
  ui.Image? _pathEdgeW;
  ui.Image? _pathCornerNE;
  ui.Image? _pathCornerNW;
  ui.Image? _pathCornerSE;
  ui.Image? _pathCornerSW;

  ui.Image? get grassTile => _grassTile;
  ui.Image? get grassTile2 => _grassTile2;
  ui.Image? get pathTile => _pathTile;
  ui.Image? get pathEdgeN => _pathEdgeN;
  ui.Image? get pathEdgeS => _pathEdgeS;
  ui.Image? get pathEdgeE => _pathEdgeE;
  ui.Image? get pathEdgeW => _pathEdgeW;
  ui.Image? get pathCornerNE => _pathCornerNE;
  ui.Image? get pathCornerNW => _pathCornerNW;
  ui.Image? get pathCornerSE => _pathCornerSE;
  ui.Image? get pathCornerSW => _pathCornerSW;

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
      if (assetKeys.contains(visual.assetPath)) {
        _enemySprites[visual.assetPath] = await _loadImage(visual.assetPath);
      }
      // Load additional animation frames (walk_02, walk_03, ...)
      for (var frame = 1; frame < visual.frames; frame++) {
        final framePath = EnemyVisualCatalog.frameAssetPath(kind, frame);
        if (assetKeys.contains(framePath)) {
          _enemySprites[framePath] = await _loadImage(framePath);
        }
      }
    }

    final barracksDefenderAssetPaths = <String>{
      for (var level = 1; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(level: level),
      for (var level = 2; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(
          level: level,
          branchId: 'vanguard',
        ),
      for (var level = 2; level <= TowerVisualCatalog.maxTier; level += 1)
        BarracksDefenderVisualCatalog.assetPath(
          level: level,
          branchId: 'sentinel',
        ),
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

    const grassPath = 'assets/sprites/tiles/grass.png';
    const grass2Path = 'assets/sprites/tiles/grass2.png';
    const pathTilePath = 'assets/sprites/tiles/path.png';
    const pathEdgeNPath = 'assets/sprites/tiles/path_edge_n.png';
    const pathEdgeSPath = 'assets/sprites/tiles/path_edge_s.png';
    const pathEdgeEPath = 'assets/sprites/tiles/path_edge_e.png';
    const pathEdgeWPath = 'assets/sprites/tiles/path_edge_w.png';
    const pathCornerNEPath = 'assets/sprites/tiles/path_corner_ne.png';
    const pathCornerNWPath = 'assets/sprites/tiles/path_corner_nw.png';
    const pathCornerSEPath = 'assets/sprites/tiles/path_corner_se.png';
    const pathCornerSWPath = 'assets/sprites/tiles/path_corner_sw.png';

    if (assetKeys.contains(grassPath)) {
      _grassTile = await _loadImage(grassPath);
    }
    if (assetKeys.contains(grass2Path)) {
      _grassTile2 = await _loadImage(grass2Path);
    }
    if (assetKeys.contains(pathTilePath)) {
      _pathTile = await _loadImage(pathTilePath);
    }
    if (assetKeys.contains(pathEdgeNPath)) {
      _pathEdgeN = await _loadImage(pathEdgeNPath);
    }
    if (assetKeys.contains(pathEdgeSPath)) {
      _pathEdgeS = await _loadImage(pathEdgeSPath);
    }
    if (assetKeys.contains(pathEdgeEPath)) {
      _pathEdgeE = await _loadImage(pathEdgeEPath);
    }
    if (assetKeys.contains(pathEdgeWPath)) {
      _pathEdgeW = await _loadImage(pathEdgeWPath);
    }
    if (assetKeys.contains(pathCornerNEPath)) {
      _pathCornerNE = await _loadImage(pathCornerNEPath);
    }
    if (assetKeys.contains(pathCornerNWPath)) {
      _pathCornerNW = await _loadImage(pathCornerNWPath);
    }
    if (assetKeys.contains(pathCornerSEPath)) {
      _pathCornerSE = await _loadImage(pathCornerSEPath);
    }
    if (assetKeys.contains(pathCornerSWPath)) {
      _pathCornerSW = await _loadImage(pathCornerSWPath);
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

  ui.Image? enemySprite(EnemyKind kind, {int frame = 0}) {
    final visual = EnemyVisualCatalog.byKind(kind);
    if (visual.frames > 1 && frame > 0) {
      final frameAssetPath = EnemyVisualCatalog.frameAssetPath(kind, frame);
      final frameSprite = _enemySprites[frameAssetPath];
      if (frameSprite != null) return frameSprite;
    }
    return _enemySprites[visual.assetPath];
  }

  ui.Image? barracksDefenderSprite({required int level, String? branchId}) {
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
