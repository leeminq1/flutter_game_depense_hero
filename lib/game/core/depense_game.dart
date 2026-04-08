import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/game_visual_registry.dart';
import 'package:depense_game/game/rendering/map_texture_planner.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Route;

class DefensePrototypeGame extends FlameGame with TapCallbacks, ScaleDetector {
  static const double _tileSize = 52.0;

  DefensePrototypeGame({
    required this.stage,
    required this.sessionController,
    required this.audioService,
    required this.metaUpgrades,
  });

  final StageDefinition stage;
  final GameSessionController sessionController;
  final GameAudioService audioService;
  final ResolvedMetaUpgrades metaUpgrades;

  final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFF7F3E8),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
  final GameVisualRegistry _visualRegistry = GameVisualRegistry();

  late List<Vector2> _pathPoints;
  Vector2 _gridOrigin = Vector2.zero();
  Path _pathRenderPath = Path();
  MapTexturePlan _mapTexturePlan = MapTexturePlan.empty;

  final List<_Enemy> _enemies = [];
  final List<_TowerPlacement> _towers = [];
  final List<_ProjectileVisual> _projectiles = [];
  final List<_BeamVisual> _beams = [];
  final List<_PulseVisual> _pulses = [];
  final List<_ImpactVisual> _impacts = [];

  int _currentWaveIndex = -1;
  int _spawnedInGroup = 0;
  int _currentSpawnGroupIndex = 0;
  double _spawnTimer = 0;
  bool _waveActive = false;
  bool _stageCleared = false;
  bool _stageFailed = false;
  bool _pausedManually = false;
  int _coins = 0;
  int _baseHealth = 0;
  String _statusText = '타워를 선택하고 빛나는 슬롯을 탭하세요.';
  int? _selectedTowerIndex;
  int _towersBuilt = 0;
  int _towersSold = 0;
  final Set<String> _builtTowerKinds = {};

  double _zoom = 1.0;
  double _scaleStart = 1.0;

  @override
  void onScaleStart(ScaleStartInfo info) {
    _scaleStart = _zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    _zoom = (_scaleStart * info.scale.global.x).clamp(0.7, 2.5);
    camera.viewfinder.zoom = _zoom;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _visualRegistry.warmUp();
    _coins = stage.startingCoins + metaUpgrades.bonusStartingCoins;
    _baseHealth = stage.baseHealth + metaUpgrades.bonusBaseHealth;
    _pathPoints = [Vector2.zero(), Vector2.all(1)];
    _pathRenderPath = Path();
    _mapTexturePlan = MapTexturePlan.empty;
    sessionController.hydrate(
      stageNumber: stage.number,
      totalStages: CampaignData.totalStages,
      stageTitle: stage.title,
      totalWaves: stage.waves.length,
      coins: _coins,
      baseHealth: _baseHealth,
    );
    _syncSession();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gridOrigin = _resolvedGridOrigin();
    final pathSequence = stage.pathSequence;
    if (pathSequence != null && pathSequence.isNotEmpty) {
      _pathPoints = pathSequence
          .map(
            (cell) => Vector2(
              _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2),
              _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2),
            ),
          )
          .toList();
    } else {
      _pathPoints = stage.pathNodes
          .map((node) => Vector2(node.dx * size.x, node.dy * size.y))
          .toList();
    }
    _pathRenderPath = _buildPathRenderPath();
    _mapTexturePlan = MapTexturePlanner.build(
      stageNumber: stage.number,
      theme: stage.environmentTheme,
      canvasSize: size,
      pathPoints: _pathPoints,
      buildSlots: _buildGridPositions().map((v) => v.toOffset()).toList(),
      decorations: stage.decorations,
    );
  }

  void selectBuildable(TowerKind? towerKind) {
    if (towerKind != null &&
        !TowerCatalog.isUnlocked(towerKind, metaUpgrades)) {
      final definition = TowerCatalog.byKind(towerKind);
      _statusText =
          definition.unlockHint ?? '${definition.label}은(는) 아직 해금되지 않았습니다.';
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    sessionController.setSelectedBuildable(towerKind);
    _selectedTowerIndex = null;
    if (towerKind != null) {
      _statusText = '${TowerCatalog.byKind(towerKind).label} 선택됨. 슬롯을 탭하세요.';
      audioService.play(AudioEvent.uiSelect);
    } else {
      _statusText = '선택이 해제되었습니다.';
    }
    _syncSession();
  }

  Future<void> refreshAudioSettings() {
    return audioService.refreshVolumes();
  }

  StageEvaluationResult evaluateCurrentRun() {
    return stage.evaluateRun(
      StageRunSummary(
        cleared: _stageCleared,
        baseHealthRemaining: _baseHealth,
        maxBaseHealth: sessionController.maxBaseHealth,
        towersBuilt: _towersBuilt,
        towersSold: _towersSold,
        builtTowerKinds: _builtTowerKinds,
      ),
    );
  }

  void startNextWave() {
    if (_waveActive || _stageCleared || _stageFailed) {
      return;
    }
    if (_currentWaveIndex >= stage.waves.length - 1) {
      _statusText = '모든 웨이브가 이미 완료되었습니다.';
      _syncSession();
      return;
    }

    _currentWaveIndex += 1;
    _currentSpawnGroupIndex = 0;
    _spawnedInGroup = 0;
    _spawnTimer = 0;
    _waveActive = true;
    _statusText = '웨이브 ${_currentWaveIndex + 1} 시작!';
    for (final tower in _towers.where(
      (tower) => tower.definition.kind == TowerKind.coinMill,
    )) {
      final waveBonus = 4 + metaUpgrades.coinMillIncomeBonus;
      _coins += waveBonus;
      tower.lastWaveBonus = waveBonus;
      audioService.play(AudioEvent.coinGain);
    }
    audioService.play(AudioEvent.uiConfirm);
    _syncSession();
  }

  void togglePaused() {
    _pausedManually = !_pausedManually;
    paused = _pausedManually;
    _statusText = _pausedManually ? '일시정지됨.' : '게임 재개.';
    _syncSession();
  }

  void upgradeSelectedTower() {
    final tower = _selectedTower;
    if (tower == null) {
      _statusText = '업그레이드할 타워를 선택하세요.';
      _syncSession();
      return;
    }
    if (!tower.canUpgrade) {
      _statusText = '${tower.definition.label}은(는) 이미 최고 레벨입니다.';
      _syncSession();
      return;
    }
    if (_coins < tower.upgradeCost) {
      _statusText = '${tower.definition.label} 업그레이드에 코인이 부족합니다.';
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= tower.upgradeCost;
    tower.totalSpent += tower.upgradeCost;
    tower.level += 1;
    tower.cooldownRemaining = math.min(
      tower.cooldownRemaining,
      tower.currentCooldown,
    );
    _statusText = '${tower.definition.label} 레벨 ${tower.level}(으)로 업그레이드!';
    audioService.play(AudioEvent.towerUpgrade);
    _syncSelectedTower();
    _syncSession();
  }

  void sellSelectedTower() {
    final index = _selectedTowerIndex;
    final tower = _selectedTower;
    if (index == null || tower == null) {
      _statusText = '판매할 타워를 선택하세요.';
      _syncSession();
      return;
    }

    _coins += tower.sellValue;
    _towers.removeAt(index);
    _towersSold += 1;
    _selectedTowerIndex = null;
    sessionController.setSelectedTower(null);
    _statusText = '${tower.definition.label} ${tower.sellValue} 코인에 판매 완료.';
    audioService.play(AudioEvent.coinGain);
    _syncSession();
  }

  void chooseBranchForSelectedTower(String branchId) {
    final tower = _selectedTower;
    if (tower == null) {
      _statusText = '먼저 타워를 선택하세요.';
      _syncSession();
      return;
    }
    if (!tower.canChooseBranch) {
      _statusText = '이 타워는 지금 브랜치를 선택할 수 없습니다.';
      _syncSession();
      return;
    }

    TowerBranchDefinition? branch;
    for (final entry in tower.definition.branches) {
      if (entry.id == branchId) {
        branch = entry;
        break;
      }
    }
    if (branch == null) {
      _statusText = '알 수 없는 브랜치 선택입니다.';
      _syncSession();
      return;
    }

    tower.branchId = branchId;
    _statusText = '${tower.definition.label}이(가) ${branch.label} 브랜치로 특화되었습니다.';
    audioService.play(AudioEvent.uiConfirm);
    _syncSelectedTower();
    _syncSession();
  }

  @override
  void update(double dt) {
    if (_pausedManually || _stageCleared || _stageFailed) {
      super.update(dt);
      return;
    }

    _updateWaveSpawning(dt);
    _updateEnemies(dt);
    _updateTowers(dt);
    _updateVisuals(dt);
    _checkWaveResolution();
    _syncSession();
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..shader = _backgroundShader(),
    );

    _drawGroundTexture(canvas);
    _drawEnvironmentDecorations(canvas, StageDecorationLayer.background);
    _drawPath(canvas);
    _drawSlots(canvas);
    _drawPulses(canvas);
    _drawTowers(canvas);
    _drawProjectiles(canvas);
    _drawEnemies(canvas);
    _drawImpacts(canvas);
    _drawEnvironmentDecorations(canvas, StageDecorationLayer.foreground);
    _drawHints(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _handleTap(event.localPosition);
  }

  void _handleTap(Vector2 position) {
    final towerIndex = _towerIndexAt(position);
    if (towerIndex != null) {
      _selectedTowerIndex = towerIndex;
      sessionController.setSelectedTower(_towers[towerIndex].details);
      _statusText = '${_towers[towerIndex].definition.label} 선택됨.';
      _syncSession();
      return;
    }

    _handlePlacement(position);
  }

  void _handlePlacement(Vector2 position) {
    final selection = sessionController.selectedBuildable;
    if (selection == null) {
      sessionController.setSelectedTower(null);
      _selectedTowerIndex = null;
      _statusText = '타워 카드를 선택하거나 배치된 타워를 탭하세요.';
      _syncSession();
      return;
    }

    // Snap to nearest valid grid cell within 42px
    Vector2? snapTarget;
    var bestDist = 42.0;
    for (final cell in _buildGridPositions()) {
      final d = cell.distanceTo(position);
      if (d < bestDist) {
        bestDist = d;
        snapTarget = cell;
      }
    }

    if (snapTarget == null) {
      // 유효한 슬롯 밖을 탭하면 카드 선택 취소
      sessionController.setSelectedBuildable(null);
      _statusText = '타워 카드를 선택하거나 배치된 타워를 탭하세요.';
      _syncSession();
      return;
    }

    final definition = TowerCatalog.byKind(selection);
    if (!definition.isUnlocked(metaUpgrades)) {
      _statusText =
          definition.unlockHint ?? '${definition.label}은(는) 아직 해금되지 않았습니다.';
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    if (_coins < definition.cost) {
      _statusText = '${definition.label} 건설에 코인이 부족합니다.';
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= definition.cost;
    _towers.add(
      _TowerPlacement(definition: definition, position: snapTarget.clone()),
    );
    _towersBuilt += 1;
    _builtTowerKinds.add(definition.kind.name);
    _selectedTowerIndex = _towers.length - 1;
    sessionController.setSelectedBuildable(null);
    _statusText = '${definition.label} 배치 완료. 전투 중에도 계속 건설할 수 있습니다.';
    audioService.play(AudioEvent.towerPlace);
    _syncSelectedTower();
    _syncSession();
  }

  int? _towerIndexAt(Vector2 position) {
    for (var i = 0; i < _towers.length; i += 1) {
      if (_towers[i].position.distanceTo(position) <= 24) {
        return i;
      }
    }
    return null;
  }

  void _updateWaveSpawning(double dt) {
    if (!_waveActive || _currentWaveIndex < 0) {
      return;
    }

    final wave = stage.waves[_currentWaveIndex];
    if (_currentSpawnGroupIndex >= wave.groups.length) {
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer > 0) {
      return;
    }

    final group = wave.groups[_currentSpawnGroupIndex];
    _enemies.add(_Enemy.fromDefinition(group.enemy));
    _spawnedInGroup += 1;
    _spawnTimer = group.spawnInterval;

    if (_spawnedInGroup >= group.count) {
      _currentSpawnGroupIndex += 1;
      _spawnedInGroup = 0;
      _spawnTimer = wave.groupGap;
    }
  }

  void _updateEnemies(double dt) {
    for (var index = _enemies.length - 1; index >= 0; index -= 1) {
      final enemy = _enemies[index];
      enemy.tickStatus(dt);
      // Update walk animation frame (3-frame cycle at ~0.15s per frame)
      enemy.animTimer += dt;
      if (enemy.animTimer >= 0.15) {
        enemy.animTimer -= 0.15;
        final totalFrames = EnemyVisualCatalog.byKind(
          enemy.definition.kind,
        ).frames;
        enemy.animFrame = (enemy.animFrame + 1) % totalFrames;
      }
      final burnDamage = enemy.tickBurn(dt);
      if (burnDamage > 0) {
        enemy.hitPoints -= burnDamage;
        if (_resolveEnemyDefeatIfNeeded(enemy)) {
          continue;
        }
      }
      _applyEnemyAbility(enemy, dt);
      enemy.advance(_pathPoints, dt);

      if (enemy.reachedGoal) {
        _baseHealth -= enemy.currentBaseDamage;
        audioService.play(AudioEvent.baseDamage);
        _enemies.removeAt(index);
        if (_baseHealth <= 0) {
          _baseHealth = 0;
          _stageFailed = true;
          _waveActive = false;
          _statusText = '기지가 함락되었습니다. 타워를 강화하고 다시 도전하세요.';
        }
      }
    }
  }

  void _updateTowers(double dt) {
    for (final tower in _towers) {
      tower.cooldownRemaining -= dt;
      if (tower.attackVisualTimer > 0) {
        tower.attackVisualTimer = math.max(0, tower.attackVisualTimer - dt);
      }

      if (tower.definition.kind == TowerKind.coinMill) {
        tower.economyTimer -= dt;
        if (tower.economyTimer <= 0) {
          tower.economyTimer = tower.definition.economyInterval ?? 3;
          _coins +=
              (tower.definition.economyIncome ?? 1) +
              metaUpgrades.coinMillIncomeBonus;
          audioService.play(AudioEvent.coinGain);
        }
        continue;
      }

      if (tower.cooldownRemaining > 0) {
        continue;
      }

      _fireTower(tower);
    }
  }

  void _fireTower(_TowerPlacement tower) {
    switch (tower.definition.kind) {
      case TowerKind.archer:
        _fireArcherTower(tower);
        break;
      case TowerKind.guardBarracks:
        _fireBarracksTower(tower);
        break;
      case TowerKind.mageObelisk:
        _fireMageTower(tower);
        break;
      case TowerKind.frostShrine:
        _fireFrostTower(tower);
        break;
      case TowerKind.coinMill:
        break;
      case TowerKind.ballista:
        _fireBallistaTower(tower);
        break;
      case TowerKind.emberkeep:
        _fireEmberkeepTower(tower);
        break;
    }
  }

  void _fireArcherTower(_TowerPlacement tower) {
    final target = _pickTarget(tower.position, tower.currentRange);
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    tower.shotCounter += 1;
    var damage = tower.currentDamage * metaUpgrades.archerDamageMultiplier;
    final criticalVolley = tower.shotCounter % 3 == 0;
    if (criticalVolley) {
      damage *= 1.8;
      if (tower.branchId == 'ranger') {
        damage *= 1.25;
      }
    }

    _applyTowerDamage(
      tower: tower,
      target: target,
      damage: damage,
      damageType: _DamageType.physical,
    );
    _spawnProjectile(
      from: tower.position,
      to: target.position,
      color: tower.definition.color,
      lifetime: 0.16,
      radius: criticalVolley ? 4.2 : 3.2,
    );

    if (criticalVolley) {
      final secondaryTargets = tower.branchId == 'multishot'
          ? _nearbyEnemiesExcluding(target, target.position, 62, 2)
          : _singleEnemyList(
              _nearestEnemyExcluding(target, target.position, 48),
            );
      for (final secondary in secondaryTargets) {
        _applyTowerDamage(
          tower: tower,
          target: secondary,
          damage: damage * (tower.branchId == 'multishot' ? 0.82 : 0.65),
          damageType: _DamageType.physical,
        );
        _spawnProjectile(
          from: tower.position,
          to: secondary.position,
          color: tower.definition.color.withValues(alpha: 0.85),
          lifetime: 0.16,
          radius: 3.0,
        );
      }
    }

    audioService.play(tower.definition.attackEvent);
  }

  void _fireBarracksTower(_TowerPlacement tower) {
    final target = _pickTarget(tower.position, tower.currentRange);
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    final damage = tower.currentDamage * metaUpgrades.barracksDamageMultiplier;
    _applyTowerDamage(
      tower: tower,
      target: target,
      damage: damage,
      damageType: _DamageType.physical,
    );
    _spawnImpact(target.position, tower.definition.color, 24, 0.22);

    final cleaveRadius = tower.branchId == 'sentinel' ? 46.0 : 30.0;
    final cleaveCount = tower.branchId == 'sentinel' ? 3 : 2;
    final splashTargets = _enemies
        .where(
          (enemy) =>
              enemy != target &&
              enemy.position.distanceTo(target.position) <= cleaveRadius,
        )
        .take(cleaveCount)
        .toList();
    for (final splash in splashTargets) {
      _applyTowerDamage(
        tower: tower,
        target: splash,
        damage: damage * 0.45,
        damageType: _DamageType.physical,
      );
      _spawnImpact(
        splash.position,
        tower.definition.color.withValues(alpha: 0.75),
        18,
        0.18,
      );
    }

    final staggerDuration =
        0.35 +
        metaUpgrades.barracksStunBonus +
        ((tower.level - 1) * 0.08) +
        (tower.branchId == 'vanguard' ? 0.18 : 0);
    target.staggerTimer = math.max(target.staggerTimer, staggerDuration);
    tower.attackVisualTimer = 0.2;
    tower.shotCounter += 1;
    audioService.play(tower.definition.attackEvent);
  }

  void _fireMageTower(_TowerPlacement tower) {
    final target = _pickTarget(tower.position, tower.currentRange);
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    final baseDamage = tower.currentDamage * metaUpgrades.mageDamageMultiplier;
    final tunedBaseDamage = tower.branchId == 'rune'
        ? baseDamage * 1.18
        : baseDamage;
    _applyTowerDamage(
      tower: tower,
      target: target,
      damage: _mageAdjustedDamage(tunedBaseDamage, target, tower.branchId),
      damageType: _DamageType.magic,
    );
    _spawnBeam(
      from: tower.position,
      to: target.position,
      color: tower.definition.color,
      lifetime: 0.15,
      strokeWidth: 3.5,
    );

    final maxChains = tower.branchId == 'storm' ? 3 : 2;
    final chained = _enemies
        .where(
          (enemy) =>
              enemy != target &&
              enemy.position.distanceTo(target.position) <= 90,
        )
        .take(maxChains)
        .toList();
    var bounce = 0;
    for (final enemy in chained) {
      final falloff = bounce == 0 ? 0.7 : 0.45;
      _applyTowerDamage(
        tower: tower,
        target: enemy,
        damage: _mageAdjustedDamage(
          tunedBaseDamage * falloff,
          enemy,
          tower.branchId,
        ),
        damageType: _DamageType.magic,
      );
      _spawnBeam(
        from: bounce == 0 ? target.position : chained[bounce - 1].position,
        to: enemy.position,
        color: tower.definition.color.withValues(alpha: 0.78),
        lifetime: 0.14,
        strokeWidth: 2.8,
      );
      bounce += 1;
    }

    audioService.play(tower.definition.attackEvent);
  }

  void _fireFrostTower(_TowerPlacement tower) {
    final enemiesInRange = _enemies
        .where(
          (enemy) =>
              tower.position.distanceTo(enemy.position) <= tower.currentRange,
        )
        .toList();
    if (enemiesInRange.isEmpty) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    _spawnPulse(
      center: tower.position,
      color: tower.definition.color,
      maxRadius: tower.currentRange * 0.82,
      lifetime: 0.34,
      strokeWidth: 3,
    );
    final slowBase =
        (tower.definition.slowFactor ?? 0.55) -
        ((tower.level - 1) * 0.08) -
        metaUpgrades.frostSlowBonus -
        (tower.branchId == 'glacier' ? 0.08 : 0);
    final slowValue = slowBase.clamp(0.22, 0.9);
    final frostDamageMultiplier = tower.branchId == 'shatter' ? 0.9 : 0.55;

    for (final enemy in enemiesInRange) {
      enemy.slowMultiplier = math.min(enemy.slowMultiplier, slowValue);
      enemy.slowTimer = 1.05;
      final alreadySlowed = enemy.wasSlowedRecently;
      _applyTowerDamage(
        tower: tower,
        target: enemy,
        damage:
            tower.currentDamage *
            frostDamageMultiplier *
            ((tower.branchId == 'shatter' && alreadySlowed) ? 1.45 : 1),
        damageType: _DamageType.magic,
      );
      enemy.wasSlowedRecently = true;
      if ((enemy.hitPoints / enemy.definition.hitPoints) < 0.35) {
        enemy.staggerTimer = math.max(enemy.staggerTimer, 0.22);
      }
    }

    audioService.play(tower.definition.attackEvent);
  }

  void _fireBallistaTower(_TowerPlacement tower) {
    final target = _pickBallistaTarget(tower.position, tower.currentRange);
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    var damage =
        tower.currentDamage * (1.55 + (tower.branchId == 'siege' ? 0.22 : 0));
    if (target.definition.kind == EnemyKind.corruptedKnight ||
        target.definition.kind == EnemyKind.shieldInfantry ||
        target.definition.kind == EnemyKind.bastionOverlord) {
      damage *= tower.branchId == 'siege' ? 1.38 : 1.24;
    }

    _applyTowerDamage(
      tower: tower,
      target: target,
      damage: damage,
      damageType: _DamageType.physical,
    );
    _spawnProjectile(
      from: tower.position,
      to: target.position,
      color: tower.definition.color,
      lifetime: 0.20,
      radius: 5.2,
    );
    _spawnImpact(target.position, tower.definition.color, 32, 0.24);

    final pinDuration = 0.42 + (tower.branchId == 'harpoon' ? 0.28 : 0.12);
    target.staggerTimer = math.max(target.staggerTimer, pinDuration);
    if (tower.branchId == 'siege') {
      for (final splash in _nearbyEnemiesExcluding(
        target,
        target.position,
        30,
        1,
      )) {
        _applyTowerDamage(
          tower: tower,
          target: splash,
          damage: damage * 0.42,
          damageType: _DamageType.physical,
        );
      }
    }

    audioService.play(tower.definition.attackEvent);
  }

  void _fireEmberkeepTower(_TowerPlacement tower) {
    final target = _pickClusterTarget(tower.position, tower.currentRange);
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = tower.currentCooldown;
    final splashRadius = tower.branchId == 'inferno' ? 58.0 : 46.0;
    final burnDuration = tower.branchId == 'cinder' ? 4.8 : 3.4;
    final burnDps =
        (6.0 + (tower.level * 1.8)) * (tower.branchId == 'inferno' ? 1.2 : 1.0);
    final enemiesInBlast = _enemies
        .where(
          (enemy) => enemy.position.distanceTo(target.position) <= splashRadius,
        )
        .toList();

    for (final enemy in enemiesInBlast) {
      final isPrimaryTarget = identical(enemy, target);
      _applyTowerDamage(
        tower: tower,
        target: enemy,
        damage: tower.currentDamage * (isPrimaryTarget ? 1.0 : 0.7),
        damageType: _DamageType.magic,
      );
      _applyBurn(enemy, dps: burnDps, duration: burnDuration);
    }

    _spawnPulse(
      center: target.position,
      color: tower.definition.color,
      maxRadius: splashRadius,
      lifetime: 0.30,
      strokeWidth: 4,
    );
    _spawnImpact(target.position, tower.definition.color, 28, 0.28);
    audioService.play(tower.definition.attackEvent);
  }

  double _mageAdjustedDamage(
    double baseDamage,
    _Enemy enemy,
    String? branchId,
  ) {
    if (enemy.definition.kind == EnemyKind.shieldInfantry ||
        enemy.definition.kind == EnemyKind.corruptedKnight) {
      return baseDamage * (branchId == 'rune' ? 1.6 : 1.35);
    }
    return baseDamage;
  }

  void _applyTowerDamage({
    required _TowerPlacement tower,
    required _Enemy target,
    required double damage,
    required _DamageType damageType,
  }) {
    final adjustedDamage = _adjustDamageForEnemy(
      target: target,
      damage: damage,
      damageType: damageType,
    );
    target.hitPoints -= adjustedDamage;
    _spawnImpact(
      target.position,
      damageType == _DamageType.magic
          ? tower.definition.color.withValues(alpha: 0.9)
          : const Color(0x99FFF1CC),
      damageType == _DamageType.magic ? 18 : 14,
      0.14,
    );
    _resolveEnemyDefeatIfNeeded(target);
  }

  double _adjustDamageForEnemy({
    required _Enemy target,
    required double damage,
    required _DamageType damageType,
  }) {
    var adjusted = damage;

    if ((target.definition.kind == EnemyKind.scout ||
            target.definition.kind == EnemyKind.wolfScout) &&
        damageType == _DamageType.physical &&
        target.dodgeReady) {
      adjusted *= 0.2;
      target.dodgeReady = false;
      target.dodgeFlashTimer = 0.5;
    }

    if ((target.definition.kind == EnemyKind.shieldInfantry ||
            target.definition.kind == EnemyKind.corruptedKnight ||
            target.definition.kind == EnemyKind.bastionOverlord) &&
        damageType == _DamageType.physical) {
      adjusted *= 0.55;
    }

    if (target.wardCharges > 0) {
      adjusted *= 0.45;
      target.wardCharges -= 1;
      target.wardFlashTimer = 0.45;
      if (target.wardCharges <= 0) {
        target.wardVisualTimer = 0;
      }
    }

    if (target.damageReductionTimer > 0) {
      adjusted *= target.damageReductionMultiplier;
    }

    return adjusted;
  }

  bool _resolveEnemyDefeatIfNeeded(_Enemy target) {
    if (target.hitPoints > 0) {
      return false;
    }

    if (target.definition.kind == EnemyKind.skeleton && !target.reviveUsed) {
      target.reviveUsed = true;
      target.hitPoints = target.definition.hitPoints * 0.4;
      target.staggerTimer = 0.4;
      _spawnImpact(target.position, const Color(0xFFDDD7C2), 26, 0.35);
      return false;
    }

    if (target.definition.kind == EnemyKind.boneArcher &&
        !target.deathSpawnUsed) {
      target.deathSpawnUsed = true;
      _spawnSummonedEnemy(summoner: target, kind: EnemyKind.skeleton);
    }

    _coins += target.definition.rewardCoins;
    if (target.definition.kind == EnemyKind.corruptedKnight ||
        target.definition.kind == EnemyKind.graveGuard ||
        target.definition.kind == EnemyKind.warlock ||
        target.definition.kind == EnemyKind.bastionPriest ||
        target.definition.kind == EnemyKind.bastionOverlord) {
      audioService.play(AudioEvent.enemyDeathElite);
    } else {
      audioService.play(AudioEvent.coinGain);
    }
    _enemies.remove(target);
    _spawnImpact(target.position, const Color(0x88FFD27A), 22, 0.24);
    return true;
  }

  void _applyEnemyAbility(_Enemy enemy, double dt) {
    if (enemy.definition.kind == EnemyKind.cultAdept) {
      enemy.cultPulseTimer -= dt;
      if (enemy.cultPulseTimer <= 0) {
        enemy.cultPulseTimer = 2.8;
        enemy.cultPulseVisualTimer = 0.65;
        for (final ally in _enemies) {
          if (ally == enemy) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 90) {
            ally.hasteMultiplier = math.max(ally.hasteMultiplier, 1.18);
            ally.hasteTimer = 1.6;
          }
        }
      }
    }

    if (enemy.definition.kind == EnemyKind.bannerCaptain) {
      enemy.supportAbilityTimer -= dt;
      if (enemy.supportAbilityTimer <= 0) {
        enemy.supportAbilityTimer = 3.2;
        enemy.supportCastVisualTimer = 0.75;
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFFD36A52),
          maxRadius: 58,
          lifetime: 0.34,
          strokeWidth: 3,
        );
        for (final ally in _enemies) {
          if (ally == enemy || !_isBanditFamily(ally.definition.kind)) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 94) {
            ally.hasteMultiplier = math.max(ally.hasteMultiplier, 1.15);
            ally.hasteTimer = math.max(ally.hasteTimer, 1.8);
            ally.temporaryBaseDamageBonus = math.max(
              ally.temporaryBaseDamageBonus,
              1,
            );
            ally.temporaryDamageBonusTimer = math.max(
              ally.temporaryDamageBonusTimer,
              1.8,
            );
          }
        }
      }
    }

    if (enemy.definition.kind == EnemyKind.raider &&
        !enemy.enrageTriggered &&
        enemy.hitPoints <= enemy.definition.hitPoints * 0.5) {
      enemy.enrageTriggered = true;
      enemy.hasteMultiplier = math.max(enemy.hasteMultiplier, 1.28);
      enemy.hasteTimer = 99;
      enemy.enrageVisualTimer = 99;
    }

    if (enemy.definition.kind == EnemyKind.wolfScout &&
        !enemy.feralTriggered &&
        enemy.hitPoints <= enemy.definition.hitPoints * 0.6) {
      enemy.feralTriggered = true;
      enemy.hasteMultiplier = math.max(enemy.hasteMultiplier, 1.2);
      enemy.hasteTimer = 99;
      enemy.chargeVisualTimer = 99;
    }

    if (enemy.definition.kind == EnemyKind.corruptedKnight &&
        !enemy.chargeTriggered &&
        enemy.hitPoints <= enemy.definition.hitPoints * 0.6) {
      enemy.chargeTriggered = true;
      enemy.hasteMultiplier = math.max(enemy.hasteMultiplier, 1.22);
      enemy.hasteTimer = 99;
      enemy.bonusBaseDamage = 1;
      enemy.chargeVisualTimer = 99;
    }

    if (enemy.definition.kind == EnemyKind.graveGuard) {
      if (enemy.slowTimer > 0) {
        enemy.slowMultiplier = math.max(enemy.slowMultiplier, 0.72);
      }
      if (enemy.staggerTimer > 0.18) {
        enemy.staggerTimer = 0.18;
      }
    }

    if (enemy.definition.kind == EnemyKind.plagueBearer) {
      enemy.supportAbilityTimer -= dt;
      if (enemy.supportAbilityTimer <= 0) {
        enemy.supportAbilityTimer = 4.0;
        enemy.supportCastVisualTimer = 0.8;
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFF88B16D),
          maxRadius: 62,
          lifetime: 0.4,
          strokeWidth: 3,
        );
        for (final ally in _enemies) {
          if (!_isUndeadFamily(ally.definition.kind)) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 92) {
            _healEnemy(ally, ally.definition.hitPoints * 0.08);
            _grantDamageReduction(ally, multiplier: 0.88, duration: 1.5);
          }
        }
      }
    }

    if (enemy.definition.kind == EnemyKind.hexSniper) {
      enemy.supportAbilityTimer -= dt;
      if (enemy.supportAbilityTimer <= 0) {
        enemy.supportAbilityTimer = 5.0;
        enemy.supportCastVisualTimer = 0.8;
        _grantWard(enemy, charges: 1, duration: 4.2);
        final target = _pickPrioritySupportTarget(enemy, radius: 104);
        if (target != null) {
          _grantWard(target, charges: 1, duration: 4.2);
          _spawnBeam(
            from: enemy.position,
            to: target.position,
            color: const Color(0xFF9CCB7D),
            lifetime: 0.18,
            strokeWidth: 2.8,
          );
        }
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFF7AAE7A),
          maxRadius: 54,
          lifetime: 0.34,
          strokeWidth: 3,
        );
      }
    }

    if (enemy.definition.kind == EnemyKind.warlock) {
      enemy.summonTimer -= dt;
      if (enemy.summonTimer <= 0) {
        enemy.summonTimer = math.max(3.6, 5.4 - (stage.number * 0.04));
        enemy.warlockCastVisualTimer = 0.7;
        _applyWarlockWard(enemy);
        if (enemy.summonsUsed < _warlockSummonLimit()) {
          enemy.summonsUsed += 1;
          _spawnSummonedEnemy(
            summoner: enemy,
            kind: stage.number >= 26
                ? EnemyKind.graveGuard
                : EnemyKind.skeleton,
          );
        }
      }
    }

    if (enemy.definition.kind == EnemyKind.bastionPriest) {
      enemy.supportAbilityTimer -= dt;
      if (enemy.supportAbilityTimer <= 0) {
        enemy.supportAbilityTimer = 4.8;
        enemy.supportCastVisualTimer = 0.8;
        final target = _pickPrioritySupportTarget(
          enemy,
          radius: 100,
          eliteOnly: true,
        );
        if (target != null) {
          _healEnemy(target, target.definition.hitPoints * 0.14);
          _grantWard(target, charges: 1, duration: 4.5);
          _spawnBeam(
            from: enemy.position,
            to: target.position,
            color: const Color(0xFFE2C57A),
            lifetime: 0.18,
            strokeWidth: 3,
          );
        } else {
          _healEnemy(enemy, enemy.definition.hitPoints * 0.07);
        }
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFFE2C57A),
          maxRadius: 56,
          lifetime: 0.36,
          strokeWidth: 3,
        );
      }
    }

    if (enemy.definition.kind == EnemyKind.bastionOverlord) {
      enemy.bossPulseTimer -= dt;

      if (!enemy.bossPhaseOneTriggered &&
          enemy.hitPoints <= enemy.definition.hitPoints * 0.72) {
        enemy.bossPhaseOneTriggered = true;
        enemy.wardCharges = 2;
        enemy.wardVisualTimer = 6.0;
        enemy.wardFlashTimer = 0.35;
        enemy.bossAuraVisualTimer = 1.1;
        enemy.hasteMultiplier = math.max(enemy.hasteMultiplier, 1.12);
        enemy.hasteTimer = 99;
        _spawnBossEscort(enemy, EnemyKind.graveGuard);
        _spawnBossEscort(enemy, EnemyKind.warlock);
      }

      if (!enemy.bossPhaseTwoTriggered &&
          enemy.hitPoints <= enemy.definition.hitPoints * 0.36) {
        enemy.bossPhaseTwoTriggered = true;
        enemy.wardCharges = 3;
        enemy.wardVisualTimer = 7.5;
        enemy.wardFlashTimer = 0.45;
        enemy.bossAuraVisualTimer = 1.4;
        enemy.hasteMultiplier = math.max(enemy.hasteMultiplier, 1.24);
        enemy.hasteTimer = 99;
        enemy.bonusBaseDamage = 2;
        _spawnBossEscort(enemy, EnemyKind.corruptedKnight);
        _spawnBossEscort(enemy, EnemyKind.graveGuard);
      }

      if (enemy.bossPulseTimer <= 0) {
        enemy.bossPulseTimer = enemy.bossPhaseTwoTriggered ? 4.0 : 5.6;
        enemy.bossAuraVisualTimer = 0.95;
        enemy.wardCharges = math.max(
          enemy.wardCharges,
          enemy.bossPhaseTwoTriggered ? 2 : 1,
        );
        enemy.wardVisualTimer = math.max(enemy.wardVisualTimer, 3.6);
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFFB85749),
          maxRadius: enemy.bossPhaseTwoTriggered ? 94 : 72,
          lifetime: 0.42,
          strokeWidth: 4,
        );
        for (final ally in _enemies) {
          if (ally == enemy) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 88) {
            ally.hasteMultiplier = math.max(ally.hasteMultiplier, 1.12);
            ally.hasteTimer = 1.8;
          }
        }
      }
    }
  }

  _Enemy? _pickTarget(Vector2 origin, double range) {
    _Enemy? target;
    var bestProgress = -1.0;

    for (final enemy in _enemies) {
      if (origin.distanceTo(enemy.position) > range) {
        continue;
      }
      if (enemy.progress > bestProgress) {
        target = enemy;
        bestProgress = enemy.progress;
      }
    }

    return target;
  }

  _Enemy? _pickBallistaTarget(Vector2 origin, double range) {
    _Enemy? target;
    var bestPriority = -1;
    var bestProgress = -1.0;

    for (final enemy in _enemies) {
      if (origin.distanceTo(enemy.position) > range) {
        continue;
      }
      final priority = _ballistaPriorityForKind(enemy.definition.kind);
      if (priority > bestPriority ||
          (priority == bestPriority && enemy.progress > bestProgress)) {
        target = enemy;
        bestPriority = priority;
        bestProgress = enemy.progress;
      }
    }

    return target;
  }

  _Enemy? _pickClusterTarget(Vector2 origin, double range) {
    _Enemy? target;
    var bestScore = -1.0;

    for (final enemy in _enemies) {
      if (origin.distanceTo(enemy.position) > range) {
        continue;
      }
      final nearbyCount = _enemies
          .where((other) => other.position.distanceTo(enemy.position) <= 52)
          .length;
      final score = (nearbyCount * 10) + enemy.progress;
      if (score > bestScore) {
        bestScore = score;
        target = enemy;
      }
    }

    return target;
  }

  _Enemy? _nearestEnemyExcluding(
    _Enemy excluded,
    Vector2 origin,
    double radius,
  ) {
    _Enemy? target;
    var bestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (enemy == excluded) {
        continue;
      }
      final distance = origin.distanceTo(enemy.position);
      if (distance <= radius && distance < bestDistance) {
        bestDistance = distance;
        target = enemy;
      }
    }
    return target;
  }

  List<_Enemy> _nearbyEnemiesExcluding(
    _Enemy excluded,
    Vector2 origin,
    double radius,
    int limit,
  ) {
    final nearby =
        _enemies
            .where(
              (enemy) =>
                  enemy != excluded &&
                  origin.distanceTo(enemy.position) <= radius,
            )
            .toList()
          ..sort(
            (a, b) => origin
                .distanceTo(a.position)
                .compareTo(origin.distanceTo(b.position)),
          );
    return nearby.take(limit).toList();
  }

  List<_Enemy> _singleEnemyList(_Enemy? enemy) {
    if (enemy == null) {
      return const [];
    }
    return [enemy];
  }

  void _applyBurn(
    _Enemy enemy, {
    required double dps,
    required double duration,
  }) {
    enemy.burnDps = math.max(enemy.burnDps, dps);
    enemy.burnTimer = math.max(enemy.burnTimer, duration);
    enemy.burnTickTimer = math.min(enemy.burnTickTimer, 0.18);
  }

  bool _isBanditFamily(EnemyKind kind) {
    return kind == EnemyKind.raider ||
        kind == EnemyKind.scout ||
        kind == EnemyKind.bannerCaptain ||
        kind == EnemyKind.wolfScout ||
        kind == EnemyKind.shieldInfantry;
  }

  bool _isUndeadFamily(EnemyKind kind) {
    return kind == EnemyKind.skeleton ||
        kind == EnemyKind.boneArcher ||
        kind == EnemyKind.graveGuard ||
        kind == EnemyKind.plagueBearer;
  }

  bool _isEliteEnemy(EnemyKind kind) {
    return kind == EnemyKind.corruptedKnight ||
        kind == EnemyKind.graveGuard ||
        kind == EnemyKind.bastionOverlord;
  }

  int _ballistaPriorityForKind(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.bastionOverlord => 6,
      EnemyKind.corruptedKnight => 5,
      EnemyKind.graveGuard => 5,
      EnemyKind.shieldInfantry => 3,
      EnemyKind.warlock => 3,
      EnemyKind.hexSniper => 3,
      EnemyKind.plagueBearer => 3,
      EnemyKind.bastionPriest => 3,
      EnemyKind.skeleton => 2,
      EnemyKind.boneArcher => 2,
      EnemyKind.cultAdept => 2,
      EnemyKind.bannerCaptain => 2,
      EnemyKind.raider => 1,
      EnemyKind.scout => 1,
      EnemyKind.wolfScout => 1,
    };
  }

  int _supportPriorityForKind(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.bastionOverlord => 6,
      EnemyKind.corruptedKnight => 5,
      EnemyKind.graveGuard => 5,
      EnemyKind.bastionPriest => 4,
      EnemyKind.warlock => 4,
      EnemyKind.hexSniper => 4,
      EnemyKind.plagueBearer => 3,
      EnemyKind.shieldInfantry => 3,
      EnemyKind.bannerCaptain => 2,
      EnemyKind.cultAdept => 2,
      EnemyKind.boneArcher => 2,
      EnemyKind.skeleton => 2,
      EnemyKind.raider => 1,
      EnemyKind.scout => 1,
      EnemyKind.wolfScout => 1,
    };
  }

  void _healEnemy(_Enemy target, double amount) {
    target.hitPoints = math.min(
      target.definition.hitPoints.toDouble(),
      target.hitPoints + amount,
    );
  }

  void _grantWard(
    _Enemy target, {
    required int charges,
    required double duration,
  }) {
    target.wardCharges = math.max(target.wardCharges, charges);
    target.wardVisualTimer = math.max(target.wardVisualTimer, duration);
    target.wardFlashTimer = math.max(target.wardFlashTimer, 0.18);
  }

  void _grantDamageReduction(
    _Enemy target, {
    required double multiplier,
    required double duration,
  }) {
    target.damageReductionMultiplier = math.min(
      target.damageReductionMultiplier,
      multiplier,
    );
    target.damageReductionTimer = math.max(
      target.damageReductionTimer,
      duration,
    );
  }

  _Enemy? _pickPrioritySupportTarget(
    _Enemy source, {
    required double radius,
    bool eliteOnly = false,
  }) {
    _Enemy? target;
    var bestPriority = -1;
    var bestProgress = -1.0;

    for (final enemy in _enemies) {
      if (enemy == source) {
        continue;
      }
      if (enemy.position.distanceTo(source.position) > radius) {
        continue;
      }
      if (eliteOnly && !_isEliteEnemy(enemy.definition.kind)) {
        continue;
      }

      final priority = _supportPriorityForKind(enemy.definition.kind);
      if (priority > bestPriority ||
          (priority == bestPriority && enemy.progress > bestProgress)) {
        target = enemy;
        bestPriority = priority;
        bestProgress = enemy.progress;
      }
    }

    return target;
  }

  void _applyWarlockWard(_Enemy warlock) {
    final target = _pickPrioritySupportTarget(warlock, radius: 96) ?? warlock;
    _grantWard(target, charges: 1, duration: 4.2);
    _spawnBeam(
      from: warlock.position,
      to: target.position,
      color: const Color(0xFF9465FF),
      lifetime: 0.18,
      strokeWidth: 3,
    );
    _spawnPulse(
      center: warlock.position,
      color: const Color(0xFF7F57D9),
      maxRadius: 52,
      lifetime: 0.34,
      strokeWidth: 3,
    );
  }

  void _spawnSummonedEnemy({
    required _Enemy summoner,
    required EnemyKind kind,
  }) {
    final definition = CampaignData.enemyForKind(
      kind,
      stageNumber: stage.number,
      intensity: 0.85,
    );
    final enemy = _Enemy.fromDefinition(definition);
    final summonSegmentProgress = (summoner.segmentProgress - 0.08).clamp(
      0.0,
      1.0,
    );
    enemy.segmentIndex = summoner.segmentIndex.clamp(
      0,
      math.max(0, _pathPoints.length - 2),
    );
    enemy.segmentProgress = summonSegmentProgress;
    _placeEnemyOnPath(enemy);
    enemy.staggerTimer = 0.28;
    enemy.progress = math.max(0, summoner.progress - 0.04);
    _enemies.add(enemy);
    _spawnImpact(enemy.position, const Color(0xFF8B6AE8), 26, 0.3);
  }

  void _spawnBossEscort(_Enemy boss, EnemyKind kind) {
    _spawnSummonedEnemy(summoner: boss, kind: kind);
    _spawnPulse(
      center: boss.position,
      color: const Color(0xFFCC7B56),
      maxRadius: 42,
      lifetime: 0.24,
      strokeWidth: 3,
    );
  }

  int _warlockSummonLimit() {
    if (stage.number >= 29) {
      return 3;
    }
    if (stage.number >= 25) {
      return 2;
    }
    return 1;
  }

  void _placeEnemyOnPath(_Enemy enemy) {
    if (_pathPoints.length < 2) {
      enemy.position.setFrom(Vector2.zero());
      return;
    }
    final segmentIndex = enemy.segmentIndex.clamp(0, _pathPoints.length - 2);
    final currentStart = _pathPoints[segmentIndex];
    final currentEnd = _pathPoints[segmentIndex + 1];
    enemy.position.setFrom(
      currentStart + ((currentEnd - currentStart) * enemy.segmentProgress),
    );
  }

  void _updateVisuals(double dt) {
    for (var index = _projectiles.length - 1; index >= 0; index -= 1) {
      final projectile = _projectiles[index];
      projectile.age += dt;
      if (projectile.age >= projectile.lifetime) {
        _projectiles.removeAt(index);
      }
    }
    for (var index = _beams.length - 1; index >= 0; index -= 1) {
      final beam = _beams[index];
      beam.age += dt;
      if (beam.age >= beam.lifetime) {
        _beams.removeAt(index);
      }
    }
    for (var index = _pulses.length - 1; index >= 0; index -= 1) {
      final pulse = _pulses[index];
      pulse.age += dt;
      if (pulse.age >= pulse.lifetime) {
        _pulses.removeAt(index);
      }
    }
    for (var index = _impacts.length - 1; index >= 0; index -= 1) {
      final impact = _impacts[index];
      impact.age += dt;
      if (impact.age >= impact.lifetime) {
        _impacts.removeAt(index);
      }
    }
  }

  void _checkWaveResolution() {
    if (!_waveActive) {
      return;
    }

    final wave = stage.waves[_currentWaveIndex];
    final finishedSpawning = _currentSpawnGroupIndex >= wave.groups.length;
    if (!finishedSpawning || _enemies.isNotEmpty) {
      return;
    }

    _waveActive = false;
    if (_currentWaveIndex == stage.waves.length - 1) {
      _stageCleared = true;
      _statusText = '스테이지 클리어! 진행 보상이 지급됩니다.';
      audioService.play(AudioEvent.stageClear);
      return;
    }

    _statusText = '웨이브 ${_currentWaveIndex + 1} 클리어! 다음 웨이브 전에 타워를 보강하세요.';
    audioService.play(AudioEvent.waveClear);
  }

  Path _buildPathRenderPath() {
    final path = Path();
    if (_pathPoints.isEmpty) {
      return path;
    }
    path.moveTo(_pathPoints.first.x, _pathPoints.first.y);
    for (final point in _pathPoints.skip(1)) {
      path.lineTo(point.x, point.y);
    }
    return path;
  }

  void _drawPath(Canvas canvas) {
    if (_pathPoints.isEmpty) {
      return;
    }

    // When tile-based rendering is active, path tiles are drawn in _drawGroundTexture
    // so we skip the stroke path here. Only draw decorative marks on top.
    if (_visualRegistry.grassTile != null) {
      for (final mark in _mapTexturePlan.pathMarks) {
        _drawTextureMark(canvas, mark);
      }
      for (final mark in _mapTexturePlan.anchorMarks) {
        _drawTextureMark(canvas, mark);
      }
      for (final mark in _mapTexturePlan.crestMarks) {
        _drawTextureMark(canvas, mark);
      }
      return;
    }

    // Fallback: original stroke-based path
    final pathGlowPaint = Paint()
      ..color = _pathGlowColor()
      ..strokeWidth = 42
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pathPaint = Paint()
      ..color = _pathBaseColor()
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_pathRenderPath, pathGlowPaint);
    canvas.drawPath(_pathRenderPath, pathPaint);
    for (final mark in _mapTexturePlan.pathMarks) {
      _drawTextureMark(canvas, mark);
    }
    for (final mark in _mapTexturePlan.anchorMarks) {
      _drawTextureMark(canvas, mark);
    }
    for (final mark in _mapTexturePlan.crestMarks) {
      _drawTextureMark(canvas, mark);
    }
  }

  void _drawSlots(Canvas canvas) {
    if (sessionController.selectedBuildable == null) return;
    final fillPaint = Paint()
      ..color = _slotFillColor()
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = _slotRingColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final cell in _buildGridPositions()) {
      final rect = Rect.fromCenter(
        center: cell.toOffset(),
        width: 48,
        height: 48,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, ringPaint);
    }
  }

  List<Vector2> _buildGridPositions() {
    final cells = <Vector2>[];
    final tileGrid = stage.tileGrid;
    if (tileGrid != null && tileGrid.isNotEmpty) {
      for (var row = 0; row < tileGrid.length; row += 1) {
        for (var col = 0; col < tileGrid[row].length; col += 1) {
          if (tileGrid[row][col] != TileType.buildable) {
            continue;
          }
          final pos = Vector2(
            _gridOrigin.x + (col * _tileSize) + (_tileSize / 2),
            _gridOrigin.y + (row * _tileSize) + (_tileSize / 2),
          );
          if (!_isTooCloseToTower(pos)) {
            cells.add(pos);
          }
        }
      }
      return cells;
    }

    const double margin = _tileSize / 2;
    if (size.x <= 0 || size.y <= 0) return cells;
    for (var x = margin; x < size.x - margin / 2; x += _tileSize) {
      for (var y = margin; y < size.y - margin / 2; y += _tileSize) {
        final pos = Vector2(x, y);
        if (!_isTooCloseToPath(pos) && !_isTooCloseToTower(pos)) {
          cells.add(pos);
        }
      }
    }
    return cells;
  }

  bool _isTooCloseToPath(Vector2 pos) {
    final clearance =
        (stage.pathClearance > 0 ? stage.pathClearance : 36.0) + 14.0;
    for (var i = 0; i < _pathPoints.length - 1; i++) {
      if (_distanceToSegment(pos, _pathPoints[i], _pathPoints[i + 1]) <
          clearance) {
        return true;
      }
    }
    return false;
  }

  bool _isTooCloseToTower(Vector2 pos) {
    for (final tower in _towers) {
      if (tower.position.distanceTo(pos) < 32.0) return true;
    }
    return false;
  }

  double _distanceToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final ap = p - a;
    final lenSq = ab.dot(ab);
    if (lenSq == 0) return p.distanceTo(a);
    final t = (ap.dot(ab) / lenSq).clamp(0.0, 1.0);
    final closest = a + (ab * t);
    return p.distanceTo(closest);
  }

  void _drawTowers(Canvas canvas) {
    for (var i = 0; i < _towers.length; i += 1) {
      final tower = _towers[i];
      final visual = TowerVisualCatalog.byKind(tower.definition.kind);
      final sprite = _visualRegistry.towerSprite(
        tower.definition.kind,
        level: tower.level,
        branchId: tower.branchId,
      );
      final center = tower.position.toOffset();
      final isSelected = i == _selectedTowerIndex;
      canvas.drawCircle(
        center,
        isSelected ? visual.baseSize + 5 : visual.baseSize + 2,
        Paint()
          ..color = visual.accentColor.withValues(
            alpha: isSelected ? 0.34 : 0.18,
          ),
      );
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: center,
          size: visual.baseSize * visual.renderScale,
          fallbackTint: visual.primaryColor,
        );
      } else {
        _drawTokenShape(
          canvas,
          center,
          shape: visual.shape,
          size: isSelected ? visual.baseSize + 4 : visual.baseSize,
          fillColor: visual.primaryColor.withValues(
            alpha: isSelected ? 1 : 0.95,
          ),
          accentColor: visual.accentColor,
        );
      }
      if (tower.definition.kind == TowerKind.guardBarracks) {
        _drawBarracksDefenders(canvas, tower);
      }
      if (tower.level > 1) {
        _labelPaint.render(
          canvas,
          'L${tower.level}',
          Vector2(center.dx - 8, center.dy + 12),
        );
      }
    }
  }

  Shader _backgroundShader() {
    final colors = switch (stage.environmentTheme) {
      StageEnvironmentTheme.frontierRoad => const [
        Color(0xFF314328),
        Color(0xFF1F2B1A),
      ],
      StageEnvironmentTheme.banditCrossroads => const [
        Color(0xFF403122),
        Color(0xFF241A13),
      ],
      StageEnvironmentTheme.graveFields => const [
        Color(0xFF31403A),
        Color(0xFF1B221D),
      ],
      StageEnvironmentTheme.cursedChapel => const [
        Color(0xFF35293F),
        Color(0xFF1C1522),
      ],
      StageEnvironmentTheme.bastionApproach => const [
        Color(0xFF34353D),
        Color(0xFF1D1D22),
      ],
      StageEnvironmentTheme.throneMarch => const [
        Color(0xFF462A20),
        Color(0xFF1C1210),
      ],
    };
    return ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.x, size.y),
      colors,
    );
  }

  Color _pathBaseColor() {
    return switch (stage.environmentTheme) {
      StageEnvironmentTheme.frontierRoad => const Color(0xFFB89568),
      StageEnvironmentTheme.banditCrossroads => const Color(0xFFAA8C63),
      StageEnvironmentTheme.graveFields => const Color(0xFFA99979),
      StageEnvironmentTheme.cursedChapel => const Color(0xFF9B876E),
      StageEnvironmentTheme.bastionApproach => const Color(0xFF9C8A73),
      StageEnvironmentTheme.throneMarch => const Color(0xFFB08C61),
    };
  }

  Color _pathGlowColor() {
    return switch (stage.environmentTheme) {
      StageEnvironmentTheme.frontierRoad => const Color(0x33F4D58D),
      StageEnvironmentTheme.banditCrossroads => const Color(0x33E2BE7A),
      StageEnvironmentTheme.graveFields => const Color(0x338FC09B),
      StageEnvironmentTheme.cursedChapel => const Color(0x33C7A5F0),
      StageEnvironmentTheme.bastionApproach => const Color(0x33D3C0A8),
      StageEnvironmentTheme.throneMarch => const Color(0x33F1B16B),
    };
  }

  Color _slotRingColor() {
    return switch (stage.environmentTheme) {
      StageEnvironmentTheme.frontierRoad => const Color(0xAAE8C97B),
      StageEnvironmentTheme.banditCrossroads => const Color(0xAAD9B56A),
      StageEnvironmentTheme.graveFields => const Color(0xAAAEC89B),
      StageEnvironmentTheme.cursedChapel => const Color(0xAACFB4F4),
      StageEnvironmentTheme.bastionApproach => const Color(0xAACFC4B5),
      StageEnvironmentTheme.throneMarch => const Color(0xAAEAB06B),
    };
  }

  Color _slotFillColor() {
    return switch (stage.environmentTheme) {
      StageEnvironmentTheme.frontierRoad => const Color(0x227B6332),
      StageEnvironmentTheme.banditCrossroads => const Color(0x226E4F2B),
      StageEnvironmentTheme.graveFields => const Color(0x22435A45),
      StageEnvironmentTheme.cursedChapel => const Color(0x22463659),
      StageEnvironmentTheme.bastionApproach => const Color(0x223E4148),
      StageEnvironmentTheme.throneMarch => const Color(0x2254332B),
    };
  }

  void _drawGroundTexture(Canvas canvas) {
    final grassTile = _visualRegistry.grassTile;
    final grassTile2 = _visualRegistry.grassTile2;
    final pathTile = _visualRegistry.pathTile;

    if (grassTile != null && stage.tileGrid != null) {
      final tileGrid = stage.tileGrid!;
      final tilePaint = Paint();

      for (var row = 0; row < tileGrid.length; row += 1) {
        for (var col = 0; col < tileGrid[row].length; col += 1) {
          final x = _gridOrigin.x + (col * _tileSize);
          final y = _gridOrigin.y + (row * _tileSize);
          final tileType = tileGrid[row][col];
          final tile = tileType == TileType.path && pathTile != null
              ? pathTile
              : _grassTileForCell(
                  row: row,
                  col: col,
                  primary: grassTile,
                  secondary: grassTile2,
                );
          final src = Rect.fromLTWH(
            0,
            0,
            tile.width.toDouble(),
            tile.height.toDouble(),
          );
          final dst = Rect.fromLTWH(x, y, _tileSize, _tileSize);
          canvas.drawImageRect(tile, src, dst, tilePaint);
          if (tileType == TileType.path) {
            _drawPathTileTrim(canvas, row: row, col: col);
          }
        }
      }
    } else if (grassTile != null) {
      final cols = (size.x / _tileSize).ceil() + 1;
      final rows = (size.y / _tileSize).ceil() + 1;
      final tilePaint = Paint();

      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          final x = col * _tileSize;
          final y = row * _tileSize;
          final center = Vector2(x + _tileSize / 2, y + _tileSize / 2);
          final onPath = _isOnPathForTile(center, 30.0);
          final tile = (onPath && pathTile != null)
              ? pathTile
              : _grassTileForCell(
                  row: row,
                  col: col,
                  primary: grassTile,
                  secondary: grassTile2,
                );
          final src = Rect.fromLTWH(
            0,
            0,
            tile.width.toDouble(),
            tile.height.toDouble(),
          );
          final dst = Rect.fromLTWH(x, y, _tileSize, _tileSize);
          canvas.drawImageRect(tile, src, dst, tilePaint);
        }
      }
    } else {
      // Fallback: original procedural ground marks
      for (final mark in _mapTexturePlan.groundMarks) {
        _drawTextureMark(canvas, mark);
      }
    }
  }

  ui.Image _grassTileForCell({
    required int row,
    required int col,
    required ui.Image primary,
    ui.Image? secondary,
  }) {
    if (secondary == null) {
      return primary;
    }
    return (row + col).isEven ? primary : secondary;
  }

  void _drawPathTileTrim(Canvas canvas, {required int row, required int col}) {
    final overlays = <ui.Image>[
      if (!_isPathTile(row - 1, col) && _visualRegistry.pathEdgeN != null)
        _visualRegistry.pathEdgeN!,
      if (!_isPathTile(row + 1, col) && _visualRegistry.pathEdgeS != null)
        _visualRegistry.pathEdgeS!,
      if (!_isPathTile(row, col + 1) && _visualRegistry.pathEdgeE != null)
        _visualRegistry.pathEdgeE!,
      if (!_isPathTile(row, col - 1) && _visualRegistry.pathEdgeW != null)
        _visualRegistry.pathEdgeW!,
      if (!_isPathTile(row - 1, col) &&
          !_isPathTile(row, col + 1) &&
          _visualRegistry.pathCornerNE != null)
        _visualRegistry.pathCornerNE!,
      if (!_isPathTile(row - 1, col) &&
          !_isPathTile(row, col - 1) &&
          _visualRegistry.pathCornerNW != null)
        _visualRegistry.pathCornerNW!,
      if (!_isPathTile(row + 1, col) &&
          !_isPathTile(row, col + 1) &&
          _visualRegistry.pathCornerSE != null)
        _visualRegistry.pathCornerSE!,
      if (!_isPathTile(row + 1, col) &&
          !_isPathTile(row, col - 1) &&
          _visualRegistry.pathCornerSW != null)
        _visualRegistry.pathCornerSW!,
    ];
    if (overlays.isEmpty) {
      return;
    }

    final dst = Rect.fromLTWH(
      _gridOrigin.x + (col * _tileSize),
      _gridOrigin.y + (row * _tileSize),
      _tileSize,
      _tileSize,
    );
    final paint = Paint();
    for (final overlay in overlays) {
      final src = Rect.fromLTWH(
        0,
        0,
        overlay.width.toDouble(),
        overlay.height.toDouble(),
      );
      canvas.drawImageRect(overlay, src, dst, paint);
    }
  }

  bool _isPathTile(int row, int col) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null ||
        row < 0 ||
        row >= tileGrid.length ||
        col < 0 ||
        col >= tileGrid[row].length) {
      return false;
    }
    return tileGrid[row][col] == TileType.path;
  }

  Vector2 _resolvedGridOrigin() {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return Vector2.zero();
    }
    final gridWidth = tileGrid.first.length * _tileSize;
    final gridHeight = tileGrid.length * _tileSize;
    return Vector2(
      math.max(0, (size.x - gridWidth) / 2),
      math.max(0, (size.y - gridHeight) / 2),
    );
  }

  bool _isOnPathForTile(Vector2 pos, double halfWidth) {
    for (var i = 0; i < _pathPoints.length - 1; i++) {
      if (_distanceToSegment(pos, _pathPoints[i], _pathPoints[i + 1]) <
          halfWidth) {
        return true;
      }
    }
    return false;
  }

  void _drawTextureMark(Canvas canvas, MapTextureMark mark) {
    final paint = Paint()..color = mark.color;
    switch (mark.shape) {
      case MapTextureMarkShape.oval:
        canvas.drawOval(
          Rect.fromCenter(
            center: mark.center,
            width: mark.width,
            height: mark.height,
          ),
          paint,
        );
        break;
      case MapTextureMarkShape.rect:
        canvas.drawRect(
          Rect.fromCenter(
            center: mark.center,
            width: mark.width,
            height: mark.height,
          ),
          paint,
        );
        break;
      case MapTextureMarkShape.roundedRect:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: mark.center,
              width: mark.width,
              height: mark.height,
            ),
            Radius.circular(mark.cornerRadius),
          ),
          paint,
        );
        break;
      case MapTextureMarkShape.circle:
        canvas.drawCircle(mark.center, mark.radius, paint);
        break;
    }
  }

  void _drawEnvironmentDecorations(Canvas canvas, StageDecorationLayer layer) {
    for (final decoration in stage.decorations) {
      if (decoration.layer != layer) {
        continue;
      }
      final sprite = _visualRegistry.environmentSprite(decoration.assetPath);
      if (sprite == null) {
        continue;
      }
      final isLandmark = decoration.assetPath.contains('/landmarks/');
      final baseSize = isLandmark ? 86.0 : 44.0;
      final center = Offset(
        decoration.position.dx * size.x,
        decoration.position.dy * size.y,
      );
      _drawSprite(
        canvas,
        sprite,
        center: center,
        size: baseSize * decoration.scale,
        fallbackTint: Colors.white,
        opacity: decoration.opacity,
      );
    }
  }

  void _drawBarracksDefenders(Canvas canvas, _TowerPlacement tower) {
    final defenderSprite = _visualRegistry.barracksDefenderSprite(
      level: tower.level,
      branchId: tower.branchId,
    );
    final center = tower.position.toOffset();
    final attackOffset = tower.attackVisualTimer > 0
        ? 4.5 * (tower.attackVisualTimer / 0.2).clamp(0.0, 1.0)
        : 0.0;
    final offsets = switch (tower.level) {
      1 => [Offset(-16 - attackOffset, 13)],
      2 => [Offset(-18 - attackOffset, 12), Offset(18 + attackOffset, 12)],
      _ => [
        Offset(-18 - attackOffset, 12),
        Offset(0, 17),
        Offset(18 + attackOffset, 12),
      ],
    };
    final size = switch (tower.level) {
      1 => 22.0,
      2 => 25.0,
      _ => 27.0,
    };

    for (var index = 0; index < offsets.length; index += 1) {
      final defenderCenter = center + offsets[index];
      if (defenderSprite != null) {
        _drawSprite(
          canvas,
          defenderSprite,
          center: defenderCenter,
          size: size,
          fallbackTint: tower.definition.color,
        );
      } else {
        _drawTokenShape(
          canvas,
          defenderCenter,
          shape: VisualTokenShape.square,
          size: 10,
          fillColor: tower.definition.color.withValues(alpha: 0.92),
          accentColor: const Color(0xFFF1D6AE),
        );
      }
    }
  }

  void _drawProjectiles(Canvas canvas) {
    for (final pulse in _beams) {
      final alpha = 1 - (pulse.age / pulse.lifetime);
      canvas.drawLine(
        pulse.from.toOffset(),
        pulse.to.toOffset(),
        Paint()
          ..color = pulse.color.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..strokeWidth = pulse.strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final projectile in _projectiles) {
      final t = (projectile.age / projectile.lifetime).clamp(0.0, 1.0);
      final position =
          projectile.from + ((projectile.to - projectile.from) * t);
      canvas.drawCircle(
        position.toOffset(),
        projectile.radius,
        Paint()..color = projectile.color.withValues(alpha: 1 - (t * 0.3)),
      );
    }
  }

  void _drawEnemies(Canvas canvas) {
    for (final enemy in _enemies) {
      final visual = EnemyVisualCatalog.byKind(enemy.definition.kind);
      final sprite = _visualRegistry.enemySprite(
        enemy.definition.kind,
        frame: enemy.animFrame,
      );
      final rect = Rect.fromCenter(
        center: enemy.position.toOffset(),
        width: visual.baseSize,
        height: visual.baseSize,
      );
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: enemy.position.toOffset(),
          size: visual.baseSize * visual.renderScale,
          fallbackTint: visual.primaryColor,
        );
      } else {
        _drawTokenShape(
          canvas,
          enemy.position.toOffset(),
          shape: visual.shape,
          size: visual.baseSize,
          fillColor: visual.primaryColor,
          accentColor: visual.accentColor,
        );
      }

      if (enemy.definition.kind == EnemyKind.shieldInfantry) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          12,
          Paint()
            ..color = const Color(0x55A7C5FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (enemy.definition.kind == EnemyKind.graveGuard) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          13,
          Paint()
            ..color = const Color(0x447FA56D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      if (enemy.definition.kind == EnemyKind.bastionOverlord) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          22,
          Paint()
            ..color = const Color(0x44D69F4C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      if (enemy.dodgeFlashTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          14 + (enemy.dodgeFlashTimer * 8),
          Paint()
            ..color = const Color(0x66FFF1A8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (enemy.enrageVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          16,
          Paint()..color = const Color(0x33FF4B3A),
        );
      }
      if (enemy.cultPulseVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          22 + ((0.65 - enemy.cultPulseVisualTimer) * 38),
          Paint()
            ..color = const Color(0x447C55FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      if (enemy.chargeVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          18,
          Paint()
            ..color = const Color(0x44F25C54)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      if (enemy.warlockCastVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          16 + ((0.7 - enemy.warlockCastVisualTimer) * 18),
          Paint()
            ..color = const Color(0x55895CFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      if (enemy.supportCastVisualTimer > 0) {
        final supportColor = switch (enemy.definition.kind) {
          EnemyKind.bannerCaptain => const Color(0x55D36A52),
          EnemyKind.plagueBearer => const Color(0x5595BD73),
          EnemyKind.hexSniper => const Color(0x559CCB7D),
          EnemyKind.bastionPriest => const Color(0x55E2C57A),
          _ => const Color(0x55895CFF),
        };
        canvas.drawCircle(
          enemy.position.toOffset(),
          16 + ((0.8 - enemy.supportCastVisualTimer) * 18),
          Paint()
            ..color = supportColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      if (enemy.wardVisualTimer > 0 || enemy.wardFlashTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          (enemy.definition.kind == EnemyKind.bastionOverlord ? 21 : 15) +
              (enemy.wardFlashTimer * 6),
          Paint()
            ..color = const Color(0x559E7AFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
      if (enemy.bossAuraVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          24 + ((1.0 - (enemy.bossAuraVisualTimer / 1.4).clamp(0.0, 1.0)) * 34),
          Paint()
            ..color = const Color(0x55E98259)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      if (enemy.burnTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          13,
          Paint()
            ..color = const Color(0x44FF7E3F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
      if (enemy.damageReductionTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          12,
          Paint()
            ..color = const Color(0x448ACB8B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final hpRatio = (enemy.hitPoints / enemy.definition.hitPoints).clamp(
        0.0,
        1.0,
      );
      final hpRect = Rect.fromLTWH(
        rect.left,
        rect.top - 10,
        visual.baseSize * hpRatio,
        4,
      );
      canvas.drawRect(hpRect, Paint()..color = const Color(0xFF88D66C));
    }
  }

  void _drawPulses(Canvas canvas) {
    for (final pulse in _pulses) {
      final t = (pulse.age / pulse.lifetime).clamp(0.0, 1.0);
      canvas.drawCircle(
        pulse.center.toOffset(),
        pulse.maxRadius * t,
        Paint()
          ..color = pulse.color.withValues(alpha: (1 - t) * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = pulse.strokeWidth,
      );
    }
  }

  void _drawImpacts(Canvas canvas) {
    for (final impact in _impacts) {
      final t = (impact.age / impact.lifetime).clamp(0.0, 1.0);
      canvas.drawCircle(
        impact.center.toOffset(),
        impact.maxRadius * (0.35 + (t * 0.65)),
        Paint()
          ..color = impact.color.withValues(alpha: (1 - t) * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawHints(Canvas canvas) {
    _labelPaint.render(
      canvas,
      '타워를 탭하여 업그레이드 또는 판매. 잠긴 타워는 메타 업그레이드로 해금.',
      Vector2(18, size.y - 170),
    );
  }

  void _spawnProjectile({
    required Vector2 from,
    required Vector2 to,
    required Color color,
    required double lifetime,
    required double radius,
  }) {
    _projectiles.add(
      _ProjectileVisual(
        from: from.clone(),
        to: to.clone(),
        color: color,
        lifetime: lifetime,
        radius: radius,
      ),
    );
  }

  void _spawnBeam({
    required Vector2 from,
    required Vector2 to,
    required Color color,
    required double lifetime,
    required double strokeWidth,
  }) {
    _beams.add(
      _BeamVisual(
        from: from.clone(),
        to: to.clone(),
        color: color,
        lifetime: lifetime,
        strokeWidth: strokeWidth,
      ),
    );
  }

  void _spawnPulse({
    required Vector2 center,
    required Color color,
    required double maxRadius,
    required double lifetime,
    required double strokeWidth,
  }) {
    _pulses.add(
      _PulseVisual(
        center: center.clone(),
        color: color,
        maxRadius: maxRadius,
        lifetime: lifetime,
        strokeWidth: strokeWidth,
      ),
    );
  }

  void _spawnImpact(
    Vector2 center,
    Color color,
    double maxRadius,
    double lifetime,
  ) {
    _impacts.add(
      _ImpactVisual(
        center: center.clone(),
        color: color,
        maxRadius: maxRadius,
        lifetime: lifetime,
      ),
    );
  }

  void _drawSprite(
    Canvas canvas,
    ui.Image image, {
    required Offset center,
    required double size,
    required Color fallbackTint,
    double opacity = 1.0,
  }) {
    final dst = Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRect(dst, Paint()..color = fallbackTint.withValues(alpha: 0.12));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
  }

  void _drawTokenShape(
    Canvas canvas,
    Offset center, {
    required VisualTokenShape shape,
    required double size,
    required Color fillColor,
    required Color accentColor,
  }) {
    final fillPaint = Paint()..color = fillColor;
    final outlinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (shape) {
      case VisualTokenShape.circle:
        canvas.drawCircle(center, size, fillPaint);
        canvas.drawCircle(center, size, outlinePaint);
      case VisualTokenShape.square:
        final rect = Rect.fromCenter(
          center: center,
          width: size * 1.9,
          height: size * 1.9,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          outlinePaint,
        );
      case VisualTokenShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx + size, center.dy)
          ..lineTo(center.dx, center.dy + size)
          ..lineTo(center.dx - size, center.dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, outlinePaint);
      case VisualTokenShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i += 1) {
          final angle = (math.pi / 3 * i) - (math.pi / 6);
          final x = center.dx + (math.cos(angle) * size);
          final y = center.dy + (math.sin(angle) * size);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, outlinePaint);
      case VisualTokenShape.shrine:
        final baseRect = Rect.fromCenter(
          center: Offset(center.dx, center.dy + (size * 0.2)),
          width: size * 1.5,
          height: size * 1.5,
        );
        final roof = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx + size, center.dy - (size * 0.15))
          ..lineTo(center.dx - size, center.dy - (size * 0.15))
          ..close();
        canvas.drawRRect(
          RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
          fillPaint,
        );
        canvas.drawPath(
          roof,
          Paint()..color = accentColor.withValues(alpha: 0.9),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
          outlinePaint,
        );
      case VisualTokenShape.mill:
        canvas.drawCircle(center, size * 0.82, fillPaint);
        canvas.drawCircle(center, size * 0.82, outlinePaint);
        canvas.drawLine(
          Offset(center.dx - size, center.dy),
          Offset(center.dx + size, center.dy),
          outlinePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - size),
          Offset(center.dx, center.dy + size),
          outlinePaint,
        );
      case VisualTokenShape.brute:
        final rect = Rect.fromCenter(
          center: center,
          width: size * 2.0,
          height: size * 1.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          outlinePaint,
        );
      case VisualTokenShape.caster:
        final bodyRect = Rect.fromCenter(
          center: Offset(center.dx, center.dy + (size * 0.12)),
          width: size * 1.5,
          height: size * 1.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
          fillPaint,
        );
        canvas.drawCircle(
          Offset(center.dx, center.dy - (size * 0.62)),
          size * 0.45,
          Paint()..color = accentColor.withValues(alpha: 0.9),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
          outlinePaint,
        );
      case VisualTokenShape.boss:
        final bodyRect = Rect.fromCenter(
          center: center,
          width: size * 1.9,
          height: size * 1.9,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(7)),
          fillPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(7)),
          outlinePaint,
        );
        final crown = Path()
          ..moveTo(center.dx - (size * 0.95), center.dy - (size * 0.35))
          ..lineTo(center.dx - (size * 0.45), center.dy - (size * 1.05))
          ..lineTo(center.dx, center.dy - (size * 0.45))
          ..lineTo(center.dx + (size * 0.45), center.dy - (size * 1.05))
          ..lineTo(center.dx + (size * 0.95), center.dy - (size * 0.35))
          ..close();
        canvas.drawPath(
          crown,
          Paint()..color = accentColor.withValues(alpha: 0.95),
        );
    }
  }

  void _syncSelectedTower() {
    final tower = _selectedTower;
    sessionController.setSelectedTower(tower?.details);
  }

  void _syncSession() {
    sessionController.updateRuntime(
      currentWave: _currentWaveIndex + 1,
      coins: _coins,
      baseHealth: _baseHealth,
      waveInProgress: _waveActive,
      stageCleared: _stageCleared,
      stageFailed: _stageFailed,
      isPaused: _pausedManually,
      towersBuilt: _towersBuilt,
      maxTowerLevel: _towers.isEmpty
          ? 1
          : _towers.map((tower) => tower.level).reduce(math.max),
      builtTowerKinds: _builtTowerKinds,
      statusText: _statusText,
    );
  }

  _TowerPlacement? get _selectedTower {
    final index = _selectedTowerIndex;
    if (index == null || index < 0 || index >= _towers.length) {
      return null;
    }
    return _towers[index];
  }
}

class _TowerPlacement {
  _TowerPlacement({required this.definition, required this.position})
    : totalSpent = definition.cost;

  final TowerDefinition definition;
  final Vector2 position;
  int level = 1;
  int totalSpent;
  double cooldownRemaining = 0;
  double economyTimer = 1.5;
  double attackVisualTimer = 0;
  int shotCounter = 0;
  int lastWaveBonus = 0;
  String? branchId;

  double get currentDamage => definition.damage * (1 + ((level - 1) * 0.45));
  double get currentRange {
    final branchRange = switch (branchId) {
      'ranger' => 1.18,
      'sentinel' => 1.12,
      'glacier' => 1.15,
      'siege' => 1.10,
      'inferno' => 1.08,
      _ => 1.0,
    };
    return definition.range * (1 + ((level - 1) * 0.08)) * branchRange;
  }

  double get currentCooldown => math.max(
    0.28,
    definition.cooldown *
        (1 - ((level - 1) * 0.08)) *
        switch (branchId) {
          'storm' => 0.9,
          'harpoon' => 0.94,
          'cinder' => 0.92,
          _ => 1.0,
        },
  );
  int get upgradeCost => (definition.cost * (0.75 + (level * 0.55))).round();
  bool get canUpgrade => level < 3;
  bool get canChooseBranch => level >= 2 && branchId == null;
  int get sellValue =>
      (totalSpent * (branchId == 'tribute' ? 0.82 : 0.7)).round();

  SelectedTowerDetails get details => SelectedTowerDetails(
    kind: definition.kind,
    label: definition.label,
    level: level,
    upgradeCost: upgradeCost,
    sellValue: sellValue,
    shortDescription: definition.shortDescription,
    abilityDescription: definition.abilityDescription,
    canUpgrade: canUpgrade,
    canChooseBranch: canChooseBranch,
    branchChoices: [
      for (final branch in definition.branches)
        TowerBranchChoiceDetails(
          id: branch.id,
          label: branch.label,
          description: branch.description,
        ),
    ],
    branchId: branchId,
    branchLabel: branchId == null
        ? null
        : definition.branches
              .firstWhere((branch) => branch.id == branchId)
              .label,
  );
}

class _Enemy {
  _Enemy.fromDefinition(this.definition)
    : hitPoints = definition.hitPoints.toDouble(),
      position = Vector2.zero() {
    supportAbilityTimer = switch (definition.kind) {
      EnemyKind.bannerCaptain => 1.8,
      EnemyKind.plagueBearer => 2.2,
      EnemyKind.hexSniper => 3.0,
      EnemyKind.bastionPriest => 3.4,
      _ => supportAbilityTimer,
    };
  }

  final EnemyDefinition definition;
  final Vector2 position;
  double hitPoints;
  int segmentIndex = 0;
  double segmentProgress = 0;
  double progress = 0;
  bool reachedGoal = false;
  double slowMultiplier = 1;
  double slowTimer = 0;
  double hasteMultiplier = 1;
  double hasteTimer = 0;
  double staggerTimer = 0;
  double cultPulseTimer = 1.4;
  bool dodgeReady = true;
  bool reviveUsed = false;
  bool deathSpawnUsed = false;
  bool enrageTriggered = false;
  bool chargeTriggered = false;
  bool feralTriggered = false;
  int bonusBaseDamage = 0;
  int temporaryBaseDamageBonus = 0;
  double temporaryDamageBonusTimer = 0;
  double dodgeFlashTimer = 0;
  double cultPulseVisualTimer = 0;
  double enrageVisualTimer = 0;
  double chargeVisualTimer = 0;
  double warlockCastVisualTimer = 0;
  double supportCastVisualTimer = 0;
  double bossAuraVisualTimer = 0;
  double burnTimer = 0;
  double burnDps = 0;
  double burnTickTimer = 0.2;
  double wardVisualTimer = 0;
  double wardFlashTimer = 0;
  double damageReductionMultiplier = 1;
  double damageReductionTimer = 0;
  double summonTimer = 4.5;
  double bossPulseTimer = 4.8;
  double supportAbilityTimer = 1.6;
  int summonsUsed = 0;
  int wardCharges = 0;
  bool bossPhaseOneTriggered = false;
  bool bossPhaseTwoTriggered = false;
  bool wasSlowedRecently = false;

  // Animation
  int animFrame = 0;
  double animTimer = 0;

  int get currentBaseDamage =>
      definition.baseDamage + bonusBaseDamage + temporaryBaseDamageBonus;

  void tickStatus(double dt) {
    if (slowTimer > 0) {
      slowTimer -= dt;
      if (slowTimer <= 0) {
        slowMultiplier = 1;
      }
    }
    if (hasteTimer > 0) {
      hasteTimer -= dt;
      if (hasteTimer <= 0) {
        hasteMultiplier = 1;
      }
    }
    if (staggerTimer > 0) {
      staggerTimer -= dt;
    }
    if (dodgeFlashTimer > 0) {
      dodgeFlashTimer -= dt;
    }
    if (temporaryDamageBonusTimer > 0) {
      temporaryDamageBonusTimer -= dt;
      if (temporaryDamageBonusTimer <= 0) {
        temporaryDamageBonusTimer = 0;
        temporaryBaseDamageBonus = 0;
      }
    }
    if (cultPulseVisualTimer > 0) {
      cultPulseVisualTimer -= dt;
    }
    if (enrageVisualTimer > 0 && hasteTimer <= 0) {
      enrageVisualTimer = 0;
    }
    if (chargeVisualTimer > 0 && hasteTimer <= 0) {
      chargeVisualTimer = 0;
    }
    if (warlockCastVisualTimer > 0) {
      warlockCastVisualTimer -= dt;
    }
    if (supportCastVisualTimer > 0) {
      supportCastVisualTimer -= dt;
    }
    if (bossAuraVisualTimer > 0) {
      bossAuraVisualTimer -= dt;
    }
    if (wardVisualTimer > 0) {
      wardVisualTimer -= dt;
      if (wardVisualTimer <= 0) {
        wardVisualTimer = 0;
        wardCharges = 0;
      }
    }
    if (wardFlashTimer > 0) {
      wardFlashTimer -= dt;
    }
    if (damageReductionTimer > 0) {
      damageReductionTimer -= dt;
      if (damageReductionTimer <= 0) {
        damageReductionTimer = 0;
        damageReductionMultiplier = 1;
      }
    }
    if (burnTimer > 0) {
      burnTimer -= dt;
      if (burnTimer <= 0) {
        burnTimer = 0;
        burnDps = 0;
        burnTickTimer = 0.2;
      }
    }
    if (slowTimer <= 0) {
      wasSlowedRecently = false;
    }
  }

  double tickBurn(double dt) {
    if (burnTimer <= 0 || burnDps <= 0) {
      return 0;
    }

    burnTickTimer -= dt;
    var damage = 0.0;
    while (burnTickTimer <= 0 && burnTimer > 0) {
      damage += burnDps * 0.2;
      burnTickTimer += 0.2;
    }
    return damage;
  }

  void advance(List<Vector2> path, double dt) {
    if (reachedGoal || path.length < 2) {
      return;
    }

    final staggerMultiplier = staggerTimer > 0 ? 0.15 : 1.0;
    var remainingDistance =
        definition.speed *
        slowMultiplier *
        hasteMultiplier *
        staggerMultiplier *
        dt;

    while (remainingDistance > 0 && !reachedGoal) {
      if (segmentIndex >= path.length - 1) {
        reachedGoal = true;
        return;
      }

      final start = path[segmentIndex];
      final end = path[segmentIndex + 1];
      final segment = end - start;
      final length = segment.length;
      final traveled = segmentProgress * length;
      final leftOnSegment = length - traveled;

      if (remainingDistance < leftOnSegment) {
        segmentProgress += remainingDistance / length;
        remainingDistance = 0;
      } else {
        remainingDistance -= leftOnSegment;
        segmentIndex += 1;
        segmentProgress = 0;
        if (segmentIndex >= path.length - 1) {
          reachedGoal = true;
          position.setFrom(path.last);
          progress = 1;
          return;
        }
      }

      final currentStart = path[segmentIndex];
      final currentEnd = path[segmentIndex + 1];
      position.setFrom(
        currentStart + (currentEnd - currentStart) * segmentProgress,
      );
      progress = (segmentIndex + segmentProgress) / (path.length - 1);
    }

    if (position == Vector2.zero()) {
      position.setFrom(path.first);
    }
  }
}

enum _DamageType { physical, magic }

class _ProjectileVisual {
  _ProjectileVisual({
    required this.from,
    required this.to,
    required this.color,
    required this.lifetime,
    required this.radius,
  });

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double lifetime;
  final double radius;
  double age = 0;
}

class _BeamVisual {
  _BeamVisual({
    required this.from,
    required this.to,
    required this.color,
    required this.lifetime,
    required this.strokeWidth,
  });

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double lifetime;
  final double strokeWidth;
  double age = 0;
}

class _PulseVisual {
  _PulseVisual({
    required this.center,
    required this.color,
    required this.maxRadius,
    required this.lifetime,
    required this.strokeWidth,
  });

  final Vector2 center;
  final Color color;
  final double maxRadius;
  final double lifetime;
  final double strokeWidth;
  double age = 0;
}

class _ImpactVisual {
  _ImpactVisual({
    required this.center,
    required this.color,
    required this.maxRadius,
    required this.lifetime,
  });

  final Vector2 center;
  final Color color;
  final double maxRadius;
  final double lifetime;
  double age = 0;
}
