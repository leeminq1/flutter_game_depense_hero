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
  ui.Image? _pathFill;
  ui.Image? _pathStraightHorizontal;
  ui.Image? _pathStraightVertical;
  ui.Image? _pathCapToNorth;
  ui.Image? _pathCapToSouth;
  ui.Image? _pathCapToEast;
  ui.Image? _pathCapToWest;
  ui.Image? _pathTurnNE;
  ui.Image? _pathTurnNW;
  ui.Image? _pathTurnSE;
  ui.Image? _pathTurnSW;

  ui.Image? get grassTile => _grassTile;
  ui.Image? get grassTile2 => _grassTile2;
  ui.Image? get pathFill => _pathFill;
  ui.Image? get pathStraightHorizontal => _pathStraightHorizontal;
  ui.Image? get pathStraightVertical => _pathStraightVertical;
  ui.Image? get pathCapToNorth => _pathCapToNorth;
  ui.Image? get pathCapToSouth => _pathCapToSouth;
  ui.Image? get pathCapToEast => _pathCapToEast;
  ui.Image? get pathCapToWest => _pathCapToWest;
  ui.Image? get pathTurnNE => _pathTurnNE;
  ui.Image? get pathTurnNW => _pathTurnNW;
  ui.Image? get pathTurnSE => _pathTurnSE;
  ui.Image? get pathTurnSW => _pathTurnSW;

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

      for (final direction in const ['west', 'east', 'north', 'south']) {
        final basePath = EnemyVisualCatalog.directionalBaseAssetPath(
          kind,
          direction,
        );
        if (assetKeys.contains(basePath)) {
          _enemySprites[basePath] = await _loadImage(basePath);
        }
        for (var frame = 1; frame < visual.frames; frame++) {
          final framePath = EnemyVisualCatalog.directionalFrameAssetPath(
            kind,
            direction,
            frame,
          );
          if (assetKeys.contains(framePath)) {
            _enemySprites[framePath] = await _loadImage(framePath);
          }
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
    const pathFillPath = 'assets/sprites/tiles/path_fill.png';
    const pathStraightHorizontalPath =
        'assets/sprites/tiles/path_straight_horizontal.png';
    const pathStraightVerticalPath =
        'assets/sprites/tiles/path_straight_vertical.png';
    const pathCapToNorthPath = 'assets/sprites/tiles/path_cap_to_north.png';
    const pathCapToSouthPath = 'assets/sprites/tiles/path_cap_to_south.png';
    const pathCapToEastPath = 'assets/sprites/tiles/path_cap_to_east.png';
    const pathCapToWestPath = 'assets/sprites/tiles/path_cap_to_west.png';
    const pathTurnNEPath = 'assets/sprites/tiles/path_turn_ne.png';
    const pathTurnNWPath = 'assets/sprites/tiles/path_turn_nw.png';
    const pathTurnSEPath = 'assets/sprites/tiles/path_turn_se.png';
    const pathTurnSWPath = 'assets/sprites/tiles/path_turn_sw.png';

    if (assetKeys.contains(grassPath)) {
      _grassTile = await _loadImage(grassPath);
    }
    if (assetKeys.contains(grass2Path)) {
      _grassTile2 = await _loadImage(grass2Path);
    }
    if (assetKeys.contains(pathFillPath)) {
      _pathFill = await _loadImage(pathFillPath);
    }
    if (assetKeys.contains(pathStraightHorizontalPath)) {
      _pathStraightHorizontal = await _loadImage(pathStraightHorizontalPath);
    }
    if (assetKeys.contains(pathStraightVerticalPath)) {
      _pathStraightVertical = await _loadImage(pathStraightVerticalPath);
    }
    if (assetKeys.contains(pathCapToNorthPath)) {
      _pathCapToNorth = await _loadImage(pathCapToNorthPath);
    }
    if (assetKeys.contains(pathCapToSouthPath)) {
      _pathCapToSouth = await _loadImage(pathCapToSouthPath);
    }
    if (assetKeys.contains(pathCapToEastPath)) {
      _pathCapToEast = await _loadImage(pathCapToEastPath);
    }
    if (assetKeys.contains(pathCapToWestPath)) {
      _pathCapToWest = await _loadImage(pathCapToWestPath);
    }
    if (assetKeys.contains(pathTurnNEPath)) {
      _pathTurnNE = await _loadImage(pathTurnNEPath);
    }
    if (assetKeys.contains(pathTurnNWPath)) {
      _pathTurnNW = await _loadImage(pathTurnNWPath);
    }
    if (assetKeys.contains(pathTurnSEPath)) {
      _pathTurnSE = await _loadImage(pathTurnSEPath);
    }
    if (assetKeys.contains(pathTurnSWPath)) {
      _pathTurnSW = await _loadImage(pathTurnSWPath);
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

  ui.Image? directionalEnemySprite(
    EnemyKind kind, {
    required String direction,
    int frame = 0,
  }) {
    final directionalPath = frame <= 0
        ? EnemyVisualCatalog.directionalBaseAssetPath(kind, direction)
        : EnemyVisualCatalog.directionalFrameAssetPath(kind, direction, frame);
    final directionalSprite = _enemySprites[directionalPath];
    if (directionalSprite != null) {
      return directionalSprite;
    }
    return enemySprite(kind, frame: frame);
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
