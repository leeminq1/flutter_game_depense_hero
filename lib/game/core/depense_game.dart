import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
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
  double get _tileSize {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) return 44.0;
    final cols = tileGrid.first.length.toDouble();
    final rows = tileGrid.length.toDouble();
    final byWidth = (size.x / cols).floorToDouble();
    final byHeight = (size.y / rows).floorToDouble();
    return math.min(byWidth, byHeight).clamp(22.0, 56.0);
  }

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
  Map<SpawnDirection, List<Vector2>> _pathsByDirection = {};
  Vector2 _gridOrigin = Vector2.zero();
  Vector2 _citadelCenter = Vector2.zero();
  Path _pathRenderPath = Path();
  Map<SpawnDirection, Path> _pathRenderPaths = {};
  MapTexturePlan _mapTexturePlan = MapTexturePlan.empty;

  final List<_Enemy> _enemies = [];
  final List<_TowerPlacement> _towers = [];
  final List<_HeroPlacement> _heroes = [];
  final List<_ProjectileVisual> _projectiles = [];
  final List<_BeamVisual> _beams = [];
  final List<_PulseVisual> _pulses = [];
  final List<_ImpactVisual> _impacts = [];

  int _currentWaveIndex = -1;
  int _spawnedInGroup = 0;
  int _currentSpawnGroupIndex = 0;
  double _spawnTimer = 0;
  bool _waveActive = false;
  bool _recoveryActive = false;
  double _recoveryTimer = 0;
  int _remainingEnemiesInCycle = 0;
  bool _stageCleared = false;
  bool _stageFailed = false;
  bool _pausedManually = false;
  int _coins = 0;
  int _baseHealth = 0;
  String _statusText = '아래 카드를 클릭해서 건물을 배치하세요.';
  int? _selectedTowerIndex;
  int? _selectedHeroIndex;
  double _selectedTowerOverlayTimer = 0;
  int _lastRecoveryReportedSecond = -1;
  int _towersBuilt = 0;
  int _towersSold = 0;
  final Set<String> _builtTowerKinds = {};
  List<SpawnDirection> _activeFronts = const [];
  List<SpawnDirection> _nextFronts = const [];

  double _zoom = 1.0;
  double _scaleStart = 1.0;

  Shader? _cachedBgShader;
  int _maxTowerLevel = 1;
  double _syncTimer = 0.0;
  bool _sessionDirty = false;
  final Vector2 _walkDelta = Vector2.zero();

  bool get _isSiegeMode =>
      stage.assaultCycles.isNotEmpty &&
      (stage.pathsByDirection?.isNotEmpty ?? false);

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
    _baseHealth = stage.citadelHitPoints + metaUpgrades.bonusBaseHealth;
    _pathPoints = [Vector2.zero(), Vector2.all(1)];
    _pathRenderPath = Path();
    _pathRenderPaths = {};
    _mapTexturePlan = MapTexturePlan.empty;
    sessionController.hydrate(
      stageNumber: stage.number,
      totalStages: CampaignData.totalStages,
      stageTitle: stage.title,
      totalWaves: stage.cycleCount,
      coins: _coins,
      baseHealth: _baseHealth,
      actNumber: stage.actNumber ?? (((stage.number - 1) ~/ 5) + 1),
      loopLabel: _isSiegeMode ? 'Cycle' : 'Wave',
    );
    _nextFronts = _nextFrontsForIndex(-1);
    _flushSession();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _cachedBgShader = null;
    _gridOrigin = _resolvedGridOrigin();
    _pathsByDirection = _resolvedPathsByDirection();
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
    if (_pathsByDirection.isNotEmpty) {
      _pathPoints = _pathsByDirection.values.first;
    }
    _pathRenderPath = _buildPathRenderPath();
    _pathRenderPaths = {
      for (final entry in _pathsByDirection.entries)
        entry.key: _buildPathRenderPathFrom(entry.value),
    };
    _citadelCenter = _resolvedCitadelCenter();
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
      _showStatus(
        definition.unlockHint ?? '${definition.label}은(는) 아직 해금되지 않았습니다.',
      );
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    sessionController.setSelectedBuildable(towerKind);
    _clearSelectedTowerSelection();
    _clearSelectedHeroSelection();
    if (towerKind != null) {
      _showStatus(
        '${TowerCatalog.byKind(towerKind).label} 카드를 선택했습니다. 빈 타일을 터치해 배치하세요.',
      );
      audioService.play(AudioEvent.uiSelect);
    } else {
      _showStatus('아래 카드를 클릭해서 건물을 배치하세요.');
    }
    _syncSession();
  }

  void selectHeroBuildable(HeroKind? heroKind) {
    if (heroKind == null) {
      sessionController.setSelectedHeroBuildable(null);
      _showStatus('아래 카드에서 타워나 영웅을 선택하세요.');
      _syncSession();
      return;
    }

    final definition = HeroCatalog.byKind(heroKind);
    if (!definition.isUnlockedForStage(stage.number)) {
      _showStatus(
        '${definition.label}은 Stage ${definition.unlockStage}부터 사용할 수 있습니다.',
      );
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    final existingIndex = _heroes.indexWhere(
      (hero) => hero.definition.kind == heroKind,
    );
    if (existingIndex >= 0) {
      _selectedHeroIndex = existingIndex;
      _selectedTowerIndex = null;
      sessionController.setSelectedHero(_heroes[existingIndex].details);
      _showStatus('${definition.label}을 선택했습니다. 빈 타일을 터치하면 이동합니다.');
      audioService.play(AudioEvent.uiSelect);
      _syncSession();
      return;
    }

    sessionController.setSelectedHeroBuildable(heroKind);
    _clearSelectedTowerSelection();
    _selectedHeroIndex = null;
    _showStatus('${definition.label}을 선택했습니다. 빈 타일을 터치해 배치하세요.');
    audioService.play(AudioEvent.uiSelect);
    _syncSession();
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

  void _showStatus(String message) {
    _statusText = message;
  }

  void _showSelectedTowerOverlay() {
    _selectedTowerOverlayTimer = 3.0;
  }

  void _clearSelectedTowerSelection() {
    _selectedTowerIndex = null;
    sessionController.setSelectedTower(null);
    _selectedTowerOverlayTimer = 0;
  }

  void _clearSelectedHeroSelection() {
    _selectedHeroIndex = null;
    sessionController.setSelectedHero(null);
  }

  void startNextWave() {
    if (_waveActive || _stageCleared || _stageFailed) {
      return;
    }
    if (_recoveryActive) {
      _recoveryActive = false;
      _recoveryTimer = 0;
      _lastRecoveryReportedSecond = -1;
    }
    if (_currentWaveIndex >= stage.waves.length - 1) {
      _statusText = _isSiegeMode
          ? '모든 공세가 이미 종료되었습니다.'
          : '모든 Wave가 이미 종료되었습니다.';
      _syncSession();
      return;
    }

    _currentWaveIndex += 1;
    _currentSpawnGroupIndex = 0;
    _spawnedInGroup = 0;
    _spawnTimer = 0;
    _waveActive = true;
    _remainingEnemiesInCycle = _enemyCountForWave(
      stage.waves[_currentWaveIndex],
    );
    final waveNumber = _currentWaveIndex + 1;
    final cycle = _assaultCycleForIndex(_currentWaveIndex);
    _activeFronts =
        cycle?.activeFronts ?? _frontsForWave(stage.waves[_currentWaveIndex]);
    _nextFronts = _nextFrontsForIndex(_currentWaveIndex);
    _statusText = _isSiegeMode
        ? 'Cycle $waveNumber 시작! ${_frontShortLabel(_activeFronts)} 전선이 열립니다.'
        : waveNumber <= 2
        ? 'Wave $waveNumber 시작! 적 경로를 확인하세요.'
        : 'Wave $waveNumber 시작!';
    for (final tower in _towers.where(
      (tower) => tower.definition.kind == TowerKind.coinMill,
    )) {
      final waveBonus =
          (cycle?.recoveryGoldBonus ?? 4) + metaUpgrades.coinMillIncomeBonus;
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
    _showStatus(_pausedManually ? '일시정지됨' : '전투 재개');
    _syncSession();
  }

  void upgradeSelectedTower() {
    final tower = _selectedTower;
    if (tower == null) {
      _showStatus('업그레이드할 건물이 없습니다.');
      _syncSession();
      return;
    }
    if (!tower.canUpgrade) {
      _showStatus('${tower.definition.label}은(는) 더 이상 업그레이드할 수 없습니다.');
      _syncSession();
      return;
    }
    if (_coins < tower.upgradeCost) {
      _showStatus('${tower.definition.label} 업그레이드에 필요한 코인이 부족합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= tower.upgradeCost;
    tower.totalSpent += tower.upgradeCost;
    final hpRatio = (tower.hitPoints / tower.maxHitPoints).clamp(0.0, 1.0);
    tower.level += 1;
    if (tower.level > _maxTowerLevel) _maxTowerLevel = tower.level;
    tower.hitPoints = math.max(
      tower.hitPoints + 32,
      tower.maxHitPoints * hpRatio,
    );
    tower.cooldownRemaining = math.min(
      tower.cooldownRemaining,
      tower.currentCooldown,
    );
    _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
    _showSelectedTowerOverlay();
    audioService.play(AudioEvent.towerUpgrade);
    _syncSelectedTower();
    _syncSession();
  }

  void sellSelectedTower() {
    final index = _selectedTowerIndex;
    final tower = _selectedTower;
    if (index == null || tower == null) {
      _showStatus('철거할 건물이 없습니다.');
      _syncSession();
      return;
    }

    _coins += tower.sellValue;
    _towers.removeAt(index);
    _towersSold += 1;
    _maxTowerLevel = _towers.isEmpty
        ? 1
        : _towers.map((t) => t.level).reduce(math.max);
    _clearSelectedTowerSelection();
    _showStatus(
      '${tower.definition.label}을(를) 철거하고 ${tower.sellValue} 코인을 회수했습니다.',
    );
    audioService.play(AudioEvent.coinGain);
    _syncSession();
  }

  void upgradeSelectedHero() {
    final hero = _selectedHero;
    if (hero == null) {
      _showStatus('업그레이드할 영웅이 없습니다.');
      _syncSession();
      return;
    }
    if (!hero.canUpgrade) {
      _showStatus('${hero.definition.label}은 더 이상 업그레이드할 수 없습니다.');
      _syncSession();
      return;
    }
    if (_coins < hero.upgradeCost) {
      _showStatus('${hero.definition.label} 업그레이드에 필요한 골드가 부족합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= hero.upgradeCost;
    hero.totalSpent += hero.upgradeCost;
    hero.level += 1;
    hero.cooldownRemaining = math.min(
      hero.cooldownRemaining,
      hero.currentCooldown,
    );
    _showStatus('${hero.definition.label}을 업그레이드했습니다.');
    audioService.play(AudioEvent.towerUpgrade);
    _syncSelectedHero();
    _syncSession();
  }

  void enterHeroMoveMode() {
    if (_selectedHeroIndex == null) return;
    sessionController.setHeroMoveMode(true);
    _showStatus('이동할 빈 타일을 선택하세요.');
    _syncSession();
  }

  void clearSelectedHero() {
    _selectedHeroIndex = null;
    sessionController.setSelectedHero(null);
    sessionController.setHeroMoveMode(false);
    _syncSession();
  }

  void chooseBranchForSelectedTower(String branchId) {
    final tower = _selectedTower;
    if (tower == null) {
      _showStatus('분기를 선택할 건물이 없습니다.');
      _syncSession();
      return;
    }
    if (!tower.canChooseBranch) {
      _showStatus('이 건물은 지금 분기 선택을 할 수 없습니다.');
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
      _showStatus('선택한 분기 정보를 찾을 수 없습니다.');
      _syncSession();
      return;
    }

    tower.branchId = branchId;
    _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
    _showSelectedTowerOverlay();
    audioService.play(AudioEvent.uiConfirm);
    _syncSelectedTower();
    _syncSession();
  }

  @override
  void update(double dt) {
    audioService.update(dt);
    _updateSelectionOverlay(dt);

    if (_pausedManually || _stageCleared || _stageFailed) {
      super.update(dt);
      return;
    }

    _updateRecovery(dt);
    _updateWaveSpawning(dt);
    _updateEnemies(dt);
    _updateTowers(dt);
    _updateHeroes(dt);
    _updateVisuals(dt);
    if (_waveActive &&
        _enemies.isEmpty &&
        _pendingEnemySpawnsForCurrentWave() > 0) {
      _spawnTimer = math.min(_spawnTimer, 0.25);
    }
    _reconcileRemainingEnemyCount();
    _checkWaveResolution();
    _syncTimer += dt;
    if (_syncTimer >= 0.066) {
      _syncTimer = 0;
      if (_sessionDirty) {
        _sessionDirty = false;
        _flushSession();
      }
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _cachedBgShader ??= _backgroundShader();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..shader = _cachedBgShader!,
    );

    _drawGroundTexture(canvas);
    _drawEnvironmentDecorations(canvas, StageDecorationLayer.background);
    _drawPath(canvas);
    _drawObstacles(canvas);
    _drawFrontTelegraphs(canvas);
    _drawSpawnCue(canvas);
    _drawCitadel(canvas);
    _drawSlots(canvas);
    _drawPulses(canvas);
    _drawTowers(canvas);
    _drawHeroes(canvas);
    _drawProjectiles(canvas);
    _drawEnemies(canvas);
    _drawImpacts(canvas);
    _drawEnvironmentDecorations(canvas, StageDecorationLayer.foreground);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _handleTap(event.localPosition);
  }

  void _handleTap(Vector2 position) {
    final heroIndex = _heroIndexAt(position);
    if (heroIndex != null) {
      _selectedHeroIndex = heroIndex;
      _selectedTowerIndex = null;
      sessionController.bumpSelectionVersion();
      sessionController.setSelectedHero(_heroes[heroIndex].details);
      _showStatus('${_heroes[heroIndex].definition.label}을 선택했습니다.');
      _syncSession();
      return;
    }

    final towerIndex = _towerIndexAt(position);
    if (towerIndex != null) {
      _selectedTowerIndex = towerIndex;
      _selectedHeroIndex = null;
      sessionController.bumpSelectionVersion();
      sessionController.setSelectedTower(_towers[towerIndex].details);
      _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
      _showSelectedTowerOverlay();
      _syncSession();
      return;
    }

    _handlePlacement(position);
  }

  void _handlePlacement(Vector2 position) {
    final heroSelection = sessionController.selectedHeroBuildable;
    if (heroSelection != null) {
      _handleHeroPlacement(position, heroSelection);
      return;
    }

    final selectedHero = _selectedHero;
    if (selectedHero != null && sessionController.heroMoveMode) {
      _handleHeroMove(position, selectedHero);
      return;
    }

    final selection = sessionController.selectedBuildable;
    if (selection == null) {
      _clearSelectedTowerSelection();
      _showStatus('아래 카드를 클릭해서 건물을 배치하세요.');
      _syncSession();
      return;
    }

    // Snap to nearest valid grid cell within 42px
    Vector2? snapTarget;
    var bestDist = 42.0;
    for (final cell in _buildGridPositions(selection: selection)) {
      final d = cell.distanceTo(position);
      if (d < bestDist) {
        bestDist = d;
        snapTarget = cell;
      }
    }

    if (snapTarget == null) {
      sessionController.setSelectedBuildable(null);
      _showStatus('유효한 빈 타일을 터치해 건물을 배치하세요.');
      _syncSession();
      return;
    }

    final definition = TowerCatalog.byKind(selection);
    if (!definition.isUnlocked(metaUpgrades)) {
      _showStatus(
        definition.unlockHint ?? '${definition.label}은(는) 아직 해금되지 않았습니다.',
      );
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    if (_coins < definition.cost) {
      _showStatus('${definition.label} 건설에 필요한 코인이 부족합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= definition.cost;
    _towers.add(
      _TowerPlacement(definition: definition, position: snapTarget.clone())
        ..economyIncomeBonus = metaUpgrades.coinMillIncomeBonus,
    );
    _towersBuilt += 1;
    _builtTowerKinds.add(definition.kind.name);
    _selectedTowerIndex = _towers.length - 1;
    sessionController.setSelectedBuildable(null);
    _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
    _showSelectedTowerOverlay();
    audioService.play(AudioEvent.towerPlace);
    _syncSelectedTower();
    _syncSession();
  }

  void _handleHeroPlacement(Vector2 position, HeroKind heroKind) {
    final definition = HeroCatalog.byKind(heroKind);
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
      sessionController.setSelectedHeroBuildable(null);
      _showStatus('영웅을 배치할 빈 타일을 선택하세요.');
      _syncSession();
      return;
    }
    if (_coins < definition.cost) {
      _showStatus('${definition.label} 고용에 필요한 골드가 부족합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= definition.cost;
    _heroes.add(
      _HeroPlacement(definition: definition, position: snapTarget.clone()),
    );
    _selectedHeroIndex = _heroes.length - 1;
    sessionController.setSelectedHeroBuildable(null);
    sessionController.setHeroMoveMode(false);
    _showStatus('${definition.label}을 배치했습니다. 영웅을 선택하면 이동과 업그레이드가 가능합니다.');
    audioService.play(AudioEvent.towerPlace);
    _syncSelectedHero();
    _syncSession();
  }

  void _handleHeroMove(Vector2 position, _HeroPlacement hero) {
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
      _showStatus('이동할 수 있는 빈 타일을 선택하세요.');
      _syncSession();
      return;
    }
    hero.walkTarget = snapTarget.clone();
    sessionController.setHeroMoveMode(false);
    _showStatus('${hero.definition.label}이 이동합니다.');
    _syncSelectedHero();
    _syncSession();
  }

  void _updateSelectionOverlay(double dt) {
    if (_selectedTowerIndex == null || _selectedTowerOverlayTimer <= 0) {
      return;
    }

    _selectedTowerOverlayTimer = math.max(0, _selectedTowerOverlayTimer - dt);
    if (_selectedTowerOverlayTimer > 0) {
      return;
    }

    _clearSelectedTowerSelection();
    _syncSession();
  }

  int? _towerIndexAt(Vector2 position) {
    for (var i = 0; i < _towers.length; i += 1) {
      if (_towers[i].position.distanceTo(position) <= (_tileSize * 0.42)) {
        return i;
      }
    }
    return null;
  }

  int? _heroIndexAt(Vector2 position) {
    for (var i = 0; i < _heroes.length; i += 1) {
      if (_heroes[i].position.distanceTo(position) <= (_tileSize * 0.70)) {
        return i;
      }
    }
    return null;
  }

  void _updateRecovery(double dt) {
    if (!_recoveryActive || _waveActive || _stageCleared || _stageFailed) {
      _lastRecoveryReportedSecond = -1;
      return;
    }
    _recoveryTimer = math.max(0, _recoveryTimer - dt);
    final currentSecond = _recoveryTimer.ceil();
    if (currentSecond != _lastRecoveryReportedSecond) {
      _lastRecoveryReportedSecond = currentSecond;
      _syncSession();
    }
  }

  int _enemyCountForWave(WaveDefinition wave) {
    return wave.groups.fold<int>(0, (sum, group) => sum + group.count);
  }

  bool _isFiniteVector(Vector2 value) {
    return value.x.isFinite && value.y.isFinite;
  }

  double _citadelGoalRadius(_Enemy enemy) {
    final baseRadius = _tileSize * 0.68;
    return switch (enemy.definition.kind) {
      EnemyKind.corruptedKnight ||
      EnemyKind.graveGuard ||
      EnemyKind.bastionOverlord => baseRadius * 1.25,
      _ => baseRadius,
    };
  }

  int _pendingEnemySpawnsForCurrentWave() {
    if (!_waveActive || _currentWaveIndex < 0) {
      return 0;
    }
    final wave = stage.waves[_currentWaveIndex];
    if (_currentSpawnGroupIndex >= wave.groups.length) {
      return 0;
    }

    var pending = 0;
    for (
      var index = _currentSpawnGroupIndex;
      index < wave.groups.length;
      index += 1
    ) {
      final group = wave.groups[index];
      final spawned = index == _currentSpawnGroupIndex ? _spawnedInGroup : 0;
      pending += math.max(0, group.count - spawned);
    }
    return pending;
  }

  bool _isEnemyTerminalForCycle(_Enemy enemy) {
    final path = _pathForEnemy(enemy);
    return enemy.hitPoints <= 0 ||
        enemy.reachedGoal ||
        !_isFiniteVector(enemy.position) ||
        path.length < 2 ||
        enemy.progress >= 0.995 ||
        enemy.distanceToCitadel <= _citadelGoalRadius(enemy);
  }

  void _reconcileRemainingEnemyCount() {
    final nextCount = !_waveActive || _currentWaveIndex < 0
        ? 0
        : _enemies.where((enemy) => !_isEnemyTerminalForCycle(enemy)).length +
              _pendingEnemySpawnsForCurrentWave();
    if (nextCount != _remainingEnemiesInCycle) {
      _remainingEnemiesInCycle = nextCount;
      _syncSession();
    }
  }

  void _consumeRemainingEnemy() {
    _remainingEnemiesInCycle = math.max(0, _remainingEnemiesInCycle - 1);
    _syncSession();
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
    final enemy = _Enemy.fromDefinition(
      group.enemy,
      spawnDirection: group.direction ?? _defaultSpawnDirectionForWave(),
    );
    enemy.customPath = _spawnPathForDirection(enemy.spawnDirection);
    _placeEnemyOnPath(enemy);
    _enemies.add(enemy);
    _spawnedInGroup += 1;
    _spawnTimer = group.spawnInterval;

    if (_spawnedInGroup >= group.count) {
      _currentSpawnGroupIndex += 1;
      _spawnedInGroup = 0;
      _spawnTimer = wave.groupGap;
    }
  }

  void _updateEnemies(double dt) {
    var playedBaseDamageSfx = false;
    for (var index = _enemies.length - 1; index >= 0; index -= 1) {
      final enemy = _enemies[index];
      if (enemy.hitPoints <= 0) {
        _consumeRemainingEnemy();
        _enemies.removeAt(index);
        continue;
      }
      final path = _pathForEnemy(enemy);
      if (path.length < 2 || !_isFiniteVector(enemy.position)) {
        _consumeRemainingEnemy();
        _enemies.removeAt(index);
        continue;
      }
      enemy.tickStatus(dt);
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
      final towerAttackSlow = _applyEnemyTowerAttack(enemy);
      enemy.advance(path, dt, _citadelCenter);
      if (!_isFiniteVector(enemy.position)) {
        _consumeRemainingEnemy();
        _enemies.removeAt(index);
        continue;
      }
      if (towerAttackSlow > 0) {
        enemy.staggerTimer = math.max(enemy.staggerTimer, towerAttackSlow);
      }
      if (!enemy.reachedGoal &&
          enemy.distanceToCitadel <= _citadelGoalRadius(enemy)) {
        enemy.reachedGoal = true;
        enemy.progress = 1;
        enemy.position.setFrom(_citadelCenter);
      }

      if (enemy.reachedGoal) {
        _baseHealth -= enemy.currentBaseDamage;
        if (!playedBaseDamageSfx) {
          playedBaseDamageSfx = true;
          audioService.play(AudioEvent.baseDamage);
        }
        _consumeRemainingEnemy();
        _enemies.removeAt(index);
        if (_baseHealth <= 0) {
          _baseHealth = 0;
          _stageFailed = true;
          _waveActive = false;
          _remainingEnemiesInCycle = 0;
          _showStatus('기지가 함락되었습니다. 다시 도전해 방어선을 정비하세요.');
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

  double _applyEnemyTowerAttack(_Enemy enemy) {
    if (enemy.towerAttackCooldown > 0 || _towers.isEmpty) {
      return 0;
    }

    var targetIndex = -1;
    var bestDistance = _tileSize * 0.92;
    for (var i = 0; i < _towers.length; i += 1) {
      final distance = _towers[i].position.distanceTo(enemy.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        targetIndex = i;
      }
    }
    if (targetIndex < 0) {
      return 0;
    }

    final tower = _towers[targetIndex];
    final damage =
        math.max(6.0, enemy.currentBaseDamage * 7.0) *
        _towerProtectionMultiplier(tower.position);
    tower.hitPoints -= damage;
    enemy.towerAttackCooldown = 1.1;
    enemy.towerAttackVisualTimer = 0.22;
    _spawnImpact(tower.position, const Color(0xAAFF6A4C), 18, 0.16);
    audioService.play(AudioEvent.armorHit);

    if (tower.hitPoints <= 0) {
      _spawnImpact(tower.position, const Color(0xAAFFB15A), 30, 0.28);
      _towers.removeAt(targetIndex);
      if (_selectedTowerIndex == targetIndex) {
        _clearSelectedTowerSelection();
      } else if (_selectedTowerIndex != null &&
          _selectedTowerIndex! > targetIndex) {
        _selectedTowerIndex = _selectedTowerIndex! - 1;
      }
      _showStatus('몬스터가 타워를 파괴했습니다. 해당 칸에 다시 건설할 수 있습니다.');
    }

    return 0.10;
  }

  double _towerProtectionMultiplier(Vector2 towerPosition) {
    var multiplier = 1.0;
    for (final hero in _heroes) {
      if (hero.definition.kind != HeroKind.knight) {
        continue;
      }
      if (hero.position.distanceTo(towerPosition) > hero.currentRange) {
        continue;
      }
      final aura = 0.82 - (metaUpgrades.guardDrillLevel * 0.015);
      multiplier = math.min(multiplier, aura.clamp(0.72, 0.82));
    }
    return multiplier;
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

    if (target.heroMarkedTimer > 0) {
      adjusted *= 1.12 + (metaUpgrades.bowMasteryLevel * 0.01);
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
    _consumeRemainingEnemy();
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
        enemy.supportAbilityTimer = 3.0;
        enemy.supportCastVisualTimer = 0.75;
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFFD36A52),
          maxRadius: 66,
          lifetime: 0.34,
          strokeWidth: 3,
        );
        for (final ally in _enemies) {
          if (ally == enemy || !_isBanditFamily(ally.definition.kind)) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 104) {
            ally.hasteMultiplier = math.max(ally.hasteMultiplier, 1.18);
            ally.hasteTimer = math.max(ally.hasteTimer, 2.2);
            ally.temporaryBaseDamageBonus = math.max(
              ally.temporaryBaseDamageBonus,
              1,
            );
            ally.temporaryDamageBonusTimer = math.max(
              ally.temporaryDamageBonusTimer,
              2.2,
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
        enemy.supportAbilityTimer = 3.8;
        enemy.supportCastVisualTimer = 0.8;
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFF88B16D),
          maxRadius: 70,
          lifetime: 0.4,
          strokeWidth: 3,
        );
        for (final ally in _enemies) {
          if (!_isUndeadFamily(ally.definition.kind)) {
            continue;
          }
          if (ally.position.distanceTo(enemy.position) <= 102) {
            _healEnemy(ally, ally.definition.hitPoints * 0.10);
            _grantDamageReduction(ally, multiplier: 0.86, duration: 1.7);
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
    var bestDistanceToCitadel = double.infinity;
    var bestProgress = -1.0;

    for (final enemy in _enemies) {
      if (origin.distanceTo(enemy.position) > range) {
        continue;
      }
      if (enemy.distanceToCitadel < bestDistanceToCitadel ||
          (enemy.distanceToCitadel == bestDistanceToCitadel &&
              enemy.progress > bestProgress)) {
        target = enemy;
        bestDistanceToCitadel = enemy.distanceToCitadel;
        bestProgress = enemy.progress;
      }
    }

    return target;
  }

  _Enemy? _pickBallistaTarget(Vector2 origin, double range) {
    _Enemy? target;
    var bestPriority = -1;
    var bestDistanceToCitadel = double.infinity;
    var bestProgress = -1.0;

    for (final enemy in _enemies) {
      if (origin.distanceTo(enemy.position) > range) {
        continue;
      }
      final priority = _ballistaPriorityForKind(enemy.definition.kind);
      if (priority > bestPriority ||
          (priority == bestPriority &&
              (enemy.distanceToCitadel < bestDistanceToCitadel ||
                  (enemy.distanceToCitadel == bestDistanceToCitadel &&
                      enemy.progress > bestProgress)))) {
        target = enemy;
        bestPriority = priority;
        bestDistanceToCitadel = enemy.distanceToCitadel;
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
      final score =
          (nearbyCount * 10) + enemy.progress + (300 - enemy.distanceToCitadel);
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
    final enemy = _Enemy.fromDefinition(
      definition,
      spawnDirection: summoner.spawnDirection,
    );
    final summonPath = _pathForEnemy(summoner);
    final summonSegmentProgress = (summoner.segmentProgress - 0.08).clamp(
      0.0,
      1.0,
    );
    enemy.segmentIndex = summoner.segmentIndex.clamp(
      0,
      math.max(0, summonPath.length - 2),
    );
    enemy.segmentProgress = summonSegmentProgress;
    _placeEnemyOnPath(enemy);
    enemy.staggerTimer = 0.28;
    enemy.progress = math.max(0, summoner.progress - 0.04);
    _remainingEnemiesInCycle += 1;
    _syncSession();
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
    final path = _pathForEnemy(enemy);
    if (path.length < 2) {
      enemy.position.setFrom(Vector2.zero());
      return;
    }
    final segmentIndex = enemy.segmentIndex.clamp(0, path.length - 2);
    final currentStart = path[segmentIndex];
    final currentEnd = path[segmentIndex + 1];
    enemy.position.setFrom(
      currentStart + ((currentEnd - currentStart) * enemy.segmentProgress),
    );
    enemy.distanceToCitadel = enemy.position.distanceTo(_citadelCenter);
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
    if (!_waveActive || _currentWaveIndex < 0) {
      return;
    }

    final wave = stage.waves[_currentWaveIndex];
    final finishedSpawning = _currentSpawnGroupIndex >= wave.groups.length;
    if (!finishedSpawning) {
      return;
    }
    _enemies.removeWhere(_isEnemyTerminalForCycle);
    _reconcileRemainingEnemyCount();
    if (_enemies.isNotEmpty) {
      return;
    }

    _waveActive = false;
    _remainingEnemiesInCycle = 0;
    if (_currentWaveIndex == stage.waves.length - 1) {
      _stageCleared = true;
      _activeFronts = const [];
      _nextFronts = const [];
      _statusText = _isSiegeMode
          ? 'Siege clear! 모든 공세를 막아냈습니다.'
          : '스테이지 클리어! 다음 전장으로 진격하세요.';
      audioService.play(AudioEvent.stageClear);
      _syncSession();
      return;
    }

    if (_isSiegeMode) {
      final finishedCycle = _assaultCycleForIndex(_currentWaveIndex);
      _recoveryActive = true;
      _recoveryTimer = finishedCycle?.recoverySeconds ?? 30;
      _activeFronts = const [];
      _nextFronts = _nextFrontsForIndex(_currentWaveIndex);
      _statusText = 'Cycle ${_currentWaveIndex + 1} 방어 성공! 정비 후 다음 공세를 준비하세요.';
    } else {
      _statusText = 'Wave ${_currentWaveIndex + 1} 방어 성공! 다음 Wave를 준비하세요.';
    }
    audioService.play(AudioEvent.waveClear);
    _syncSession();
  }

  Map<SpawnDirection, List<Vector2>> _resolvedPathsByDirection() {
    final tileGrid = stage.tileGrid;
    final authored = stage.pathsByDirection;
    if (tileGrid != null &&
        tileGrid.isNotEmpty &&
        authored != null &&
        authored.isNotEmpty) {
      return {
        for (final entry in authored.entries)
          entry.key: _vectorPathFromCells(
            _resolvedRouteCellsForDirection(entry.key),
            direction: entry.key,
          ),
      };
    }

    final center = _resolvedCitadelCenter();
    final gridWidth = stage.tileGrid?.isNotEmpty == true
        ? stage.tileGrid!.first.length * _tileSize
        : size.x;
    final gridHeight = stage.tileGrid?.isNotEmpty == true
        ? stage.tileGrid!.length * _tileSize
        : size.y;
    final startYNorth = _gridOrigin.y - _tileSize;
    final startYSouth = _gridOrigin.y + gridHeight + _tileSize;
    final startXWest = _gridOrigin.x - _tileSize;
    final startXEast = _gridOrigin.x + gridWidth + _tileSize;

    return {
      SpawnDirection.north: [Vector2(center.x, startYNorth), center],
      SpawnDirection.south: [Vector2(center.x, startYSouth), center],
      SpawnDirection.east: [Vector2(startXEast, center.y), center],
      SpawnDirection.west: [Vector2(startXWest, center.y), center],
    };
  }

  Vector2 _resolvedCitadelCenter() {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return Vector2(size.x / 2, size.y / 2);
    }

    var totalX = 0.0;
    var totalY = 0.0;
    var count = 0;
    for (var row = 0; row < tileGrid.length; row += 1) {
      for (var col = 0; col < tileGrid[row].length; col += 1) {
        if (tileGrid[row][col] != TileType.citadel) {
          continue;
        }
        totalX += _gridOrigin.x + (col * _tileSize) + (_tileSize / 2);
        totalY += _gridOrigin.y + (row * _tileSize) + (_tileSize / 2);
        count += 1;
      }
    }
    if (count == 0) {
      return Vector2(size.x / 2, size.y / 2);
    }
    return Vector2(totalX / count, totalY / count);
  }

  Path _buildPathRenderPathFrom(List<Vector2> points) {
    final previousPath = _pathPoints;
    _pathPoints = points;
    final path = _buildPathRenderPath();
    _pathPoints = previousPath;
    return path;
  }

  AssaultCycleDefinition? _assaultCycleForIndex(int index) {
    if (index < 0 || index >= stage.assaultCycles.length) {
      return null;
    }
    return stage.assaultCycles[index];
  }

  List<SpawnDirection> _nextFrontsForIndex(int currentIndex) {
    final nextIndex = currentIndex + 1;
    final nextCycle = _assaultCycleForIndex(nextIndex);
    if (nextCycle != null) {
      return nextCycle.activeFronts;
    }
    if (nextIndex >= 0 && nextIndex < stage.waves.length) {
      return _frontsForWave(stage.waves[nextIndex]);
    }
    return const [];
  }

  List<SpawnDirection> _frontsForWave(WaveDefinition wave) {
    final fronts = <SpawnDirection>{};
    for (final group in wave.groups) {
      if (group.direction != null) {
        fronts.add(group.direction!);
      }
    }
    if (fronts.isEmpty) {
      fronts.add(_defaultSpawnDirectionForWave());
    }
    return fronts.toList();
  }

  SpawnDirection _defaultSpawnDirectionForWave() {
    if (_pathsByDirection.containsKey(SpawnDirection.east)) {
      return SpawnDirection.east;
    }
    return SpawnDirection.west;
  }

  List<Vector2> _pathForEnemy(_Enemy enemy) {
    if (enemy.customPath != null) return enemy.customPath!;
    return _pathsByDirection[enemy.spawnDirection] ?? _pathPoints;
  }

  SpawnDirection _directionFromDelta(Vector2 delta) {
    if (delta.x.abs() > delta.y.abs()) {
      return delta.x >= 0 ? SpawnDirection.east : SpawnDirection.west;
    }
    return delta.y >= 0 ? SpawnDirection.south : SpawnDirection.north;
  }

  List<Vector2> _spawnPathForDirection(SpawnDirection dir) {
    final resolvedCells = _resolvedRouteCellsForDirection(
      dir,
      includeTowerCells: true,
    );
    if (resolvedCells.isNotEmpty) {
      // Keep live spawns aligned to the authored lane entry so a lone final
      // enemy cannot drift far offscreen before entering the visible field.
      return _vectorPathFromCells(
        resolvedCells,
        direction: dir,
        randomizeEdgeAnchor: false,
      );
    }
    final authoredPath = _pathsByDirection[dir];
    if (authoredPath != null && authoredPath.length >= 2) {
      return authoredPath;
    }
    return _randomEdgePathToCitadel(dir);
  }

  List<List<int>> _resolvedRouteCellsForDirection(
    SpawnDirection dir, {
    bool includeTowerCells = false,
  }) {
    final authored = stage.pathsByDirection?[dir];
    final tileGrid = stage.tileGrid;
    if (authored == null ||
        authored.isEmpty ||
        tileGrid == null ||
        tileGrid.isEmpty) {
      return const [];
    }

    final resolved = _findGridRoute(
      authored.first,
      authored.last,
      dir,
      includeTowerCells: includeTowerCells,
    );
    return resolved.isEmpty ? authored : resolved;
  }

  List<List<int>> _findGridRoute(
    List<int> start,
    List<int> goal,
    SpawnDirection dir, {
    bool includeTowerCells = false,
  }) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return const [];
    }

    final frontier = <List<int>>[start];
    final visited = <String>{_gridCellKey(start[0], start[1])};
    final cameFrom = <String, String>{};
    var head = 0;

    while (head < frontier.length) {
      final current = frontier[head];
      head += 1;
      if (current[0] == goal[0] && current[1] == goal[1]) {
        return _reconstructGridPath(start, goal, cameFrom);
      }

      for (final delta in _neighborOrderForFront(dir)) {
        final nextCol = current[0] + delta.$1;
        final nextRow = current[1] + delta.$2;
        if (nextRow < 0 ||
            nextRow >= tileGrid.length ||
            nextCol < 0 ||
            nextCol >= tileGrid[nextRow].length) {
          continue;
        }

        final nextKey = _gridCellKey(nextCol, nextRow);
        if (visited.contains(nextKey)) {
          continue;
        }

        final isGoal = nextCol == goal[0] && nextRow == goal[1];
        if (!isGoal &&
            _isBlockedForPathing(
              nextCol,
              nextRow,
              includeTowerCells: includeTowerCells,
            )) {
          continue;
        }

        visited.add(nextKey);
        cameFrom[nextKey] = _gridCellKey(current[0], current[1]);
        frontier.add([nextCol, nextRow]);
      }
    }

    return const [];
  }

  List<List<int>> _reconstructGridPath(
    List<int> start,
    List<int> goal,
    Map<String, String> cameFrom,
  ) {
    final route = <List<int>>[goal];
    var currentKey = _gridCellKey(goal[0], goal[1]);

    while (currentKey != _gridCellKey(start[0], start[1])) {
      final previousKey = cameFrom[currentKey];
      if (previousKey == null) {
        return const [];
      }
      final parts = previousKey.split(':');
      route.add([int.parse(parts[0]), int.parse(parts[1])]);
      currentKey = previousKey;
    }

    return route.reversed.toList();
  }

  bool _isBlockedForPathing(
    int col,
    int row, {
    bool includeTowerCells = false,
  }) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null ||
        row < 0 ||
        row >= tileGrid.length ||
        col < 0 ||
        col >= tileGrid[row].length) {
      return true;
    }

    final tile = tileGrid[row][col];
    if (tile == TileType.citadel || _hasObstacleAtCell(col, row)) {
      return true;
    }

    if (!includeTowerCells) {
      return false;
    }

    return _towers.any((tower) {
      final towerCol = ((tower.position.x - _gridOrigin.x) / _tileSize).floor();
      final towerRow = ((tower.position.y - _gridOrigin.y) / _tileSize).floor();
      return towerCol == col && towerRow == row;
    });
  }

  List<(int, int)> _neighborOrderForFront(SpawnDirection dir) {
    return switch (dir) {
      SpawnDirection.north => const [(0, 1), (-1, 0), (1, 0), (0, -1)],
      SpawnDirection.south => const [(0, -1), (-1, 0), (1, 0), (0, 1)],
      SpawnDirection.east => const [(-1, 0), (0, -1), (0, 1), (1, 0)],
      SpawnDirection.west => const [(1, 0), (0, -1), (0, 1), (-1, 0)],
    };
  }

  List<Vector2> _vectorPathFromCells(
    List<List<int>> cells, {
    required SpawnDirection direction,
    bool randomizeEdgeAnchor = false,
  }) {
    if (cells.isEmpty) {
      return const [];
    }
    final citadelCenter = _resolvedCitadelCenter();
    final points = <Vector2>[
      _edgeAnchorForFront(
        direction,
        cells.first,
        randomizeAlongEdge: randomizeEdgeAnchor,
      ),
      for (final cell in cells)
        Vector2(
          _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2),
          _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2),
        ),
    ];
    if (points.last.distanceTo(citadelCenter) > 1) {
      points.add(citadelCenter);
    }
    return points;
  }

  Vector2 _edgeAnchorForFront(
    SpawnDirection front,
    List<int> cell, {
    bool randomizeAlongEdge = false,
  }) {
    final cellCenter = Vector2(
      _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2),
      _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2),
    );
    if (!randomizeAlongEdge) {
      return switch (front) {
        SpawnDirection.north => Vector2(cellCenter.x, 0),
        SpawnDirection.south => Vector2(cellCenter.x, size.y),
        SpawnDirection.east => Vector2(size.x, cellCenter.y),
        SpawnDirection.west => Vector2(0, cellCenter.y),
      };
    }

    final tileGrid = stage.tileGrid;
    final rng = math.Random();
    final gridWidth = tileGrid?.isNotEmpty == true
        ? tileGrid!.first.length * _tileSize
        : size.x;
    final gridHeight = tileGrid?.isNotEmpty == true
        ? tileGrid!.length * _tileSize
        : size.y;
    final minX = _gridOrigin.x;
    final minY = _gridOrigin.y;
    final maxX = minX + gridWidth;
    final maxY = minY + gridHeight;
    return switch (front) {
      SpawnDirection.north => Vector2(
        minX + rng.nextDouble() * gridWidth,
        minY - _tileSize,
      ),
      SpawnDirection.south => Vector2(
        minX + rng.nextDouble() * gridWidth,
        maxY + _tileSize,
      ),
      SpawnDirection.east => Vector2(
        maxX + _tileSize,
        minY + rng.nextDouble() * gridHeight,
      ),
      SpawnDirection.west => Vector2(
        minX - _tileSize,
        minY + rng.nextDouble() * gridHeight,
      ),
    };
  }

  String _gridCellKey(int col, int row) => '$col:$row';

  bool _hasObstacleAtCell(int col, int row) {
    for (final obstacle in stage.obstacles) {
      for (final cell in obstacle.occupiedCells) {
        if (cell[0] == col && cell[1] == row) {
          return true;
        }
      }
    }
    return false;
  }

  List<Vector2> _randomEdgePathToCitadel(SpawnDirection dir) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return _pathsByDirection[dir] ?? _pathPoints;
    }
    final ts = _tileSize;
    final gridW = tileGrid.first.length * ts;
    final gridH = tileGrid.length * ts;
    final ox = _gridOrigin.x;
    final oy = _gridOrigin.y;
    final rng = math.Random();

    final spawnPoint = switch (dir) {
      SpawnDirection.north => Vector2(ox + rng.nextDouble() * gridW, oy - ts),
      SpawnDirection.south => Vector2(
        ox + rng.nextDouble() * gridW,
        oy + gridH + ts,
      ),
      SpawnDirection.east => Vector2(
        ox + gridW + ts,
        oy + rng.nextDouble() * gridH,
      ),
      SpawnDirection.west => Vector2(ox - ts, oy + rng.nextDouble() * gridH),
    };
    return [spawnPoint, _citadelCenter.clone()];
  }

  Color _frontColor(SpawnDirection direction) {
    return switch (direction) {
      SpawnDirection.north => const Color(0xFF4488FF),
      SpawnDirection.south => const Color(0xFFFF4444),
      SpawnDirection.east => const Color(0xFF44FF88),
      SpawnDirection.west => const Color(0xFFFFCC44),
    };
  }

  String _frontLabel(List<SpawnDirection> fronts) {
    if (fronts.isEmpty) {
      return '대기';
    }
    return fronts
        .map((front) {
          return switch (front) {
            SpawnDirection.north => '북쪽',
            SpawnDirection.south => '남쪽',
            SpawnDirection.east => '동쪽',
            SpawnDirection.west => '서쪽',
          };
        })
        .join(' · ');
  }

  String _frontShortLabel(List<SpawnDirection> fronts) {
    if (fronts.isEmpty) {
      return '대기';
    }
    return fronts
        .map((front) {
          return switch (front) {
            SpawnDirection.north => '북',
            SpawnDirection.south => '남',
            SpawnDirection.east => '동',
            SpawnDirection.west => '서',
          };
        })
        .join(' · ');
  }

  Path _buildPathRenderPath() {
    final path = Path();
    if (_pathPoints.isEmpty) {
      return path;
    }
    if (_pathPoints.length == 1) {
      path.addOval(
        Rect.fromCircle(center: _pathPoints.first.toOffset(), radius: 12),
      );
      return path;
    }
    path.moveTo(_pathPoints.first.x, _pathPoints.first.y);
    for (var index = 1; index < _pathPoints.length - 1; index += 1) {
      final previous = _pathPoints[index - 1];
      final current = _pathPoints[index];
      final next = _pathPoints[index + 1];
      final incoming = current - previous;
      final outgoing = next - current;
      final incomingLength = incoming.length;
      final outgoingLength = outgoing.length;
      if (incomingLength == 0 || outgoingLength == 0) {
        path.lineTo(current.x, current.y);
        continue;
      }
      incoming.scale(1 / incomingLength);
      outgoing.scale(1 / outgoingLength);
      final cornerRadius = math.min(
        _tileSize * 0.34,
        math.min(incomingLength, outgoingLength) / 2,
      );
      final entry = current - (incoming * cornerRadius);
      final exit = current + (outgoing * cornerRadius);
      path.lineTo(entry.x, entry.y);
      path.quadraticBezierTo(current.x, current.y, exit.x, exit.y);
    }
    path.lineTo(_pathPoints.last.x, _pathPoints.last.y);
    return path;
  }

  void _drawPath(Canvas canvas) {
    if (_pathPoints.isEmpty && _pathRenderPaths.isEmpty) {
      return;
    }
    final invisibleGlow = Paint()
      ..color = _pathGlowColor().withValues(alpha: 0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final invisibleBase = Paint()
      ..color = _pathBaseColor().withValues(alpha: 0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (_pathRenderPaths.isNotEmpty) {
      for (final path in _pathRenderPaths.values) {
        canvas.drawPath(path, invisibleGlow);
        canvas.drawPath(path, invisibleBase);
      }
      return;
    }

    canvas.drawPath(_pathRenderPath, invisibleGlow);
    canvas.drawPath(_pathRenderPath, invisibleBase);
  }

  void _drawSlots(Canvas canvas) {
    final isHeroMove = sessionController.heroMoveMode;
    final isHeroPlacement = sessionController.selectedHeroBuildable != null;
    final selection = sessionController.selectedBuildable;
    if (selection == null && !isHeroMove && !isHeroPlacement) return;
    final fillPaint = Paint()
      ..color = (isHeroMove || isHeroPlacement)
          ? const Color(0x224FC9FF)
          : _slotFillColor()
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = (isHeroMove || isHeroPlacement)
          ? const Color(0xFF4FC9FF)
          : _slotRingColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final cell in _buildGridPositions(selection: selection)) {
      final rect = Rect.fromCenter(
        center: cell.toOffset(),
        width: _tileSize - 6,
        height: _tileSize - 6,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, ringPaint);
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obstacle in stage.obstacles) {
      if (obstacle.occupiedCells.isEmpty) {
        continue;
      }
      final sprite = _visualRegistry.environmentSprite(obstacle.assetPath);
      final center = _obstacleCenter(obstacle);
      final isLandmark = obstacle.assetPath.contains('/landmarks/');
      final baseSize = isLandmark ? 86.0 : 44.0;
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: center,
          size: baseSize * obstacle.scale,
          fallbackTint: Colors.white,
          opacity: obstacle.opacity,
        );
      }
    }
  }

  Offset _obstacleCenter(StageObstacleDefinition obstacle) {
    var totalX = 0.0;
    var totalY = 0.0;
    for (final cell in obstacle.occupiedCells) {
      totalX += _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2);
      totalY += _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2);
    }
    final count = obstacle.occupiedCells.length.toDouble();
    return Offset(totalX / count, totalY / count);
  }

  void _drawCitadel(Canvas canvas) {
    if (_citadelCenter == Vector2.zero()) {
      return;
    }
    final sprite = _visualRegistry.environmentSprite(
      'assets/sprites/environment/landmarks/central_citadel.png',
    );
    if (sprite != null) {
      _drawSprite(
        canvas,
        sprite,
        center: _citadelCenter.toOffset(),
        size: _tileSize * 2.0,
        fallbackTint: const Color(0xFF6C7E8C),
      );
    } else {
      canvas.drawCircle(
        _citadelCenter.toOffset(),
        46,
        Paint()
          ..color = const Color(0x334FC9FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawFrontTelegraphs(Canvas canvas) {
    if (_pathsByDirection.isEmpty) {
      return;
    }
    final markerSprite = _visualRegistry.environmentSprite(
      'assets/sprites/environment/props/breach_front_marker.png',
    );
    for (final entry in _pathsByDirection.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final front = entry.key;
      final center = _frontMarkerAnchor(front, entry.value).toOffset();
      final isActive = _activeFronts.contains(front);
      final isNext = !_waveActive && _nextFronts.contains(front);
      if (!isActive && !isNext) {
        continue;
      }
      final tint = _frontColor(front).withValues(alpha: isActive ? 1.0 : 0.72);
      if (markerSprite != null) {
        _drawSprite(
          canvas,
          markerSprite,
          center: center,
          size: _tileSize * 0.94,
          fallbackTint: tint,
          tintColor: tint,
          opacity: isActive ? 0.72 : 0.46,
        );
      }
    }
  }

  List<Vector2> _buildGridPositions({TowerKind? selection}) {
    final cells = <Vector2>[];
    final tileGrid = stage.tileGrid;
    if (tileGrid != null && tileGrid.isNotEmpty) {
      for (var row = 0; row < tileGrid.length; row += 1) {
        for (var col = 0; col < tileGrid[row].length; col += 1) {
          final tileType = tileGrid[row][col];
          if (tileType != TileType.buildable) {
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

    final double margin = _tileSize / 2;
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
      if (tower.position.distanceTo(pos) < (_tileSize * 0.72)) return true;
    }
    for (var i = 0; i < _heroes.length; i += 1) {
      if (i == _selectedHeroIndex) {
        continue;
      }
      if (_heroes[i].position.distanceTo(pos) < (_tileSize * 0.72)) {
        return true;
      }
    }
    return false;
  }

  void _updateHeroes(double dt) {
    for (final hero in _heroes) {
      if (hero.walkTarget != null) {
        final target = hero.walkTarget!;
        _walkDelta.setFrom(target);
        _walkDelta.sub(hero.position);
        final dist = _walkDelta.length;
        final step = _HeroPlacement.walkSpeed * dt;
        if (dist <= step) {
          hero.position.setFrom(target);
          hero.walkTarget = null;
        } else {
          _walkDelta.scale(1.0 / dist);
          hero.position.addScaled(_walkDelta, step);
          hero.facing = _directionFromDelta(_walkDelta);
        }
      }
      _applyHeroPassive(hero, dt);
      hero.cooldownRemaining -= dt;
      if (hero.attackVisualTimer > 0) {
        hero.attackVisualTimer = math.max(0, hero.attackVisualTimer - dt);
      }
      hero.animTimer += dt;
      if (hero.animTimer >= 0.15) {
        hero.animTimer -= 0.15;
        hero.animFrame =
            (hero.animFrame + 1) %
            HeroVisualCatalog.byKind(hero.definition.kind).frames;
      }
      if (hero.cooldownRemaining > 0) {
        continue;
      }
      _fireHero(hero);
    }
  }

  void _applyHeroPassive(_HeroPlacement hero, double dt) {
    if (hero.definition.kind != HeroKind.paladin) {
      return;
    }
    hero.supportTimer -= dt;
    if (hero.supportTimer > 0) {
      return;
    }
    hero.supportTimer = math.max(1.8, 2.8 - (hero.level * 0.25));
    _TowerPlacement? target;
    var lowestRatio = 1.0;
    for (final tower in _towers) {
      if (tower.position.distanceTo(hero.position) > hero.currentRange) {
        continue;
      }
      final ratio = (tower.hitPoints / tower.maxHitPoints).clamp(0.0, 1.0);
      if (ratio < lowestRatio) {
        lowestRatio = ratio;
        target = tower;
      }
    }
    if (target == null || lowestRatio >= 0.98) {
      return;
    }
    final healAmount =
        8.0 + (hero.level * 5.0) + (metaUpgrades.guardDrillLevel * 1.5);
    target.hitPoints = math.min(
      target.maxHitPoints,
      target.hitPoints + healAmount,
    );
    _spawnPulse(
      center: target.position,
      color: hero.definition.color.withValues(alpha: 0.72),
      maxRadius: 24,
      lifetime: 0.24,
      strokeWidth: 2.4,
    );
  }

  void _fireHero(_HeroPlacement hero) {
    final target = _pickTarget(hero.position, hero.currentRange);
    if (target == null) {
      return;
    }
    hero.cooldownRemaining = hero.currentCooldown;
    hero.attackVisualTimer = 0.22;
    hero.facing = _directionFromDelta(target.position - hero.position);

    final damageType = switch (hero.definition.kind) {
      HeroKind.mage => _DamageType.magic,
      _ => _DamageType.physical,
    };
    final baseDamage = hero.currentDamage * _heroMetaDamageMultiplier(hero);
    final adjustedDamage = _adjustDamageForEnemy(
      target: target,
      damage: baseDamage,
      damageType: damageType,
    );
    target.hitPoints -= adjustedDamage;

    switch (hero.definition.kind) {
      case HeroKind.mage:
        _spawnBeam(
          from: hero.position,
          to: target.position,
          color: hero.definition.color,
          lifetime: 0.16,
          strokeWidth: 3.2,
        );
        hero.shotCounter += 1;
        if (hero.shotCounter % 3 == 0) {
          for (final splash in _nearbyEnemiesExcluding(
            target,
            target.position,
            54,
            3,
          )) {
            final splashDamage = _adjustDamageForEnemy(
              target: splash,
              damage: baseDamage * 0.42,
              damageType: _DamageType.magic,
            );
            splash.hitPoints -= splashDamage;
            _spawnImpact(splash.position, hero.definition.color, 16, 0.14);
            _resolveEnemyDefeatIfNeeded(splash);
          }
        }
        break;
      case HeroKind.archer:
        _spawnProjectile(
          from: hero.position,
          to: target.position,
          color: hero.definition.color,
          lifetime: 0.15,
          radius: 3.0,
        );
        target.heroMarkedTimer = math.max(target.heroMarkedTimer, 3.2);
        break;
      case HeroKind.ninja:
        _spawnImpact(target.position, hero.definition.color, 20, 0.14);
        if (target.hitPoints > 0 &&
            target.hitPoints / target.definition.hitPoints <=
                (0.28 + (metaUpgrades.frostFocusLevel * 0.01))) {
          target.hitPoints -= target.definition.hitPoints * 0.18;
          target.staggerTimer = math.max(target.staggerTimer, 0.14);
          _spawnImpact(target.position, const Color(0xFFFFD1D6), 26, 0.18);
        }
        break;
      case HeroKind.knight:
      case HeroKind.paladin:
        _spawnImpact(target.position, hero.definition.color, 18, 0.16);
        target.staggerTimer = math.max(target.staggerTimer, 0.08);
        break;
    }

    audioService.play(hero.definition.attackEvent);
    _resolveEnemyDefeatIfNeeded(target);
  }

  double _heroMetaDamageMultiplier(_HeroPlacement hero) {
    return switch (hero.definition.kind) {
      HeroKind.knight ||
      HeroKind.paladin => 1 + (metaUpgrades.guardDrillLevel * 0.05),
      HeroKind.archer => 1 + (metaUpgrades.bowMasteryLevel * 0.06),
      HeroKind.mage => 1 + (metaUpgrades.arcaneMasteryLevel * 0.06),
      HeroKind.ninja => 1 + (metaUpgrades.frostFocusLevel * 0.05),
    };
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
      final towerRenderSize = _tileSize * 0.82;
      final selectionRadius = _tileSize * (isSelected ? 0.46 : 0.40);
      canvas.drawCircle(
        center,
        selectionRadius,
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
          size: towerRenderSize,
          fallbackTint: visual.primaryColor,
        );
      } else {
        _drawTokenShape(
          canvas,
          center,
          shape: visual.shape,
          size: _tileSize * (isSelected ? 0.40 : 0.34),
          fillColor: visual.primaryColor.withValues(
            alpha: isSelected ? 1 : 0.95,
          ),
          accentColor: visual.accentColor,
        );
      }
      if (tower.definition.kind == TowerKind.guardBarracks) {
        _drawBarracksDefenders(canvas, tower);
      }
      final hpRatio = (tower.hitPoints / tower.maxHitPoints).clamp(0.0, 1.0);
      if (hpRatio < 0.98) {
        final barRect = Rect.fromLTWH(
          center.dx - (_tileSize * 0.24),
          center.dy - (_tileSize * 0.48),
          _tileSize * 0.48,
          4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
          Paint()..color = const Color(0x66000000),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              barRect.left,
              barRect.top,
              barRect.width * hpRatio,
              barRect.height,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFFF8A65),
        );
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

  void _drawHeroes(Canvas canvas) {
    for (var i = 0; i < _heroes.length; i += 1) {
      final hero = _heroes[i];
      final visual = HeroVisualCatalog.byKind(hero.definition.kind);
      final directionKey = switch (hero.facing) {
        SpawnDirection.north => 'north',
        SpawnDirection.south => 'south',
        SpawnDirection.east => 'west',
        SpawnDirection.west => 'west',
      };
      final sprite = _visualRegistry.directionalHeroSprite(
        hero.definition.kind,
        direction: directionKey,
        frame: hero.animFrame,
      );
      final center = hero.position.toOffset();
      final isSelected = i == _selectedHeroIndex;
      canvas.drawCircle(
        center,
        _tileSize * (isSelected ? 0.48 : 0.40),
        Paint()
          ..color = hero.definition.color.withValues(
            alpha: isSelected ? 0.30 : 0.16,
          ),
      );
      if (sprite != null) {
        final bob = hero.attackVisualTimer > 0
            ? hero.attackVisualTimer * 10
            : 0;
        _drawSprite(
          canvas,
          sprite,
          center: Offset(center.dx, center.dy - bob),
          size: visual.baseSize * visual.renderScale,
          fallbackTint: visual.primaryColor,
          flipX: hero.facing == SpawnDirection.east,
        );
      } else {
        _drawTokenShape(
          canvas,
          center,
          shape: visual.shape,
          size: visual.baseSize,
          fillColor: visual.primaryColor,
          accentColor: visual.accentColor,
        );
      }
      _labelPaint.render(
        canvas,
        'H${hero.level}',
        Vector2(center.dx - 9, center.dy + 14),
      );
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

    if (grassTile != null) {
      final tilePaint = Paint();
      final cols = (size.x / _tileSize).ceil() + 1;
      final rows = (size.y / _tileSize).ceil() + 1;

      for (var row = 0; row < rows; row += 1) {
        for (var col = 0; col < cols; col += 1) {
          final x = col * _tileSize;
          final y = row * _tileSize;
          final tile = _grassTileForCell(
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

  Vector2 _resolvedGridOrigin() {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return Vector2.zero();
    }
    final gridWidth = tileGrid.first.length * _tileSize;
    final gridHeight = tileGrid.length * _tileSize;
    final verticalSlack = size.y - gridHeight;
    return Vector2(
      math.max(0, (size.x - gridWidth) / 2),
      verticalSlack <= 0 ? 0 : verticalSlack / 2,
    );
  }

  void _drawSpawnCue(Canvas canvas) {
    if (!_waveActive) {
      return;
    }
    if (_pathsByDirection.isNotEmpty) {
      for (final front in _activeFronts) {
        final path = _pathsByDirection[front];
        if (path == null || path.isEmpty) {
          continue;
        }
        _drawSpawnCueAt(
          canvas,
          anchor: _frontMarkerAnchor(front, path).toOffset(),
          color: _frontColor(front),
        );
      }
      return;
    }

    if (_pathPoints.isEmpty) {
      return;
    }
    _drawSpawnCueAt(
      canvas,
      anchor: _pathPoints.first.toOffset(),
      color: const Color(0xFF98D67C),
    );
  }

  void _drawSpawnCueAt(
    Canvas canvas, {
    required Offset anchor,
    required Color color,
  }) {
    final ringCenter = anchor;
    canvas.drawCircle(
      ringCenter,
      14,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      ringCenter,
      14,
      Paint()
        ..color = color.withValues(alpha: 0.68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final chevronPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var index = 0; index < 3; index += 1) {
      final center = Offset(ringCenter.dx - (index * 10), ringCenter.dy);
      final chevron = Path()
        ..moveTo(center.dx + 4, center.dy - 5)
        ..lineTo(center.dx - 3, center.dy)
        ..lineTo(center.dx + 4, center.dy + 5);
      canvas.drawPath(chevron, chevronPaint);
    }
  }

  Vector2 _frontMarkerAnchor(SpawnDirection front, List<Vector2> path) {
    if (path.isEmpty) {
      return _citadelCenter;
    }
    final inset = math.max(18.0, _tileSize * 0.75);
    for (final point in path) {
      if (point.x >= inset &&
          point.x <= size.x - inset &&
          point.y >= inset &&
          point.y <= size.y - inset) {
        return point;
      }
    }
    return switch (front) {
      SpawnDirection.north => Vector2(_citadelCenter.x, inset),
      SpawnDirection.south => Vector2(_citadelCenter.x, size.y - inset),
      SpawnDirection.east => Vector2(size.x - inset, _citadelCenter.y),
      SpawnDirection.west => Vector2(inset, _citadelCenter.y),
    };
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
      final direction = enemy.currentDirection;
      final directionKey = switch (direction) {
        SpawnDirection.north => 'north',
        SpawnDirection.south => 'south',
        SpawnDirection.east => 'west',
        SpawnDirection.west => 'west',
      };
      final sprite = _visualRegistry.directionalEnemySprite(
        enemy.definition.kind,
        direction: directionKey,
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
          flipX: direction == SpawnDirection.east,
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
      if (enemy.towerAttackVisualTimer > 0) {
        canvas.drawCircle(
          enemy.position.toOffset(),
          15 + (enemy.towerAttackVisualTimer * 12),
          Paint()
            ..color = const Color(0x66FF7043)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
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
    bool flipX = false,
    Color? tintColor,
  }) {
    final dst = Rect.fromCenter(center: center, width: size, height: size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
    if (tintColor != null) {
      paint.colorFilter = ColorFilter.mode(tintColor, BlendMode.modulate);
    }
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (!flipX) {
      canvas.drawImageRect(image, src, dst, paint);
      return;
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(-1, 1);
    final mirroredDst = Rect.fromCenter(
      center: Offset.zero,
      width: size,
      height: size,
    );
    canvas.drawImageRect(image, src, mirroredDst, paint);
    canvas.restore();
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
    sessionController.setSelectedTower(_selectedTower?.details);
  }

  void _syncSelectedHero() {
    sessionController.setSelectedHero(_selectedHero?.details);
  }

  /// Marks session state as needing a sync.
  /// Actual Flutter notification happens in the 15fps throttle (update loop).
  void _syncSession() {
    _sessionDirty = true;
  }

  /// Performs the actual session sync — called only from the 15fps throttle.
  void _flushSession() {
    sessionController.updateRuntime(
      currentWave: _currentWaveIndex + 1,
      coins: _coins,
      baseHealth: _baseHealth,
      waveInProgress: _waveActive,
      stageCleared: _stageCleared,
      stageFailed: _stageFailed,
      isPaused: _pausedManually,
      towersBuilt: _towersBuilt,
      maxTowerLevel: _maxTowerLevel,
      builtTowerKinds: _builtTowerKinds,
      statusText: _statusText,
      actNumber: stage.actNumber ?? (((stage.number - 1) ~/ 5) + 1),
      loopLabel: _isSiegeMode ? 'Cycle' : 'Wave',
      activeFronts: _activeFronts.map((front) => _frontLabel([front])).toList(),
      nextFronts: _nextFronts.map((front) => _frontLabel([front])).toList(),
      recoverySecondsRemaining: _recoveryTimer,
      recoveryActive: _recoveryActive,
      battleState: _stageCleared
          ? 'clear'
          : _stageFailed
          ? 'fail'
          : _waveActive
          ? 'assault'
          : _recoveryActive
          ? 'manual_ready'
          : (_currentWaveIndex < 0 ? 'prep' : 'idle'),
      remainingEnemies: _stageFailed ? 0 : _remainingEnemiesInCycle,
    );
  }

  _TowerPlacement? get _selectedTower {
    final index = _selectedTowerIndex;
    if (index == null || index < 0 || index >= _towers.length) {
      return null;
    }
    return _towers[index];
  }

  _HeroPlacement? get _selectedHero {
    final index = _selectedHeroIndex;
    if (index == null || index < 0 || index >= _heroes.length) {
      return null;
    }
    return _heroes[index];
  }
}

class _HeroPlacement {
  _HeroPlacement({required this.definition, required this.position})
    : totalSpent = definition.cost;

  static const double walkSpeed = 90.0;

  final HeroDefinition definition;
  final Vector2 position;
  Vector2? walkTarget;
  int level = 1;
  int totalSpent;
  double cooldownRemaining = 0;
  double attackVisualTimer = 0;
  double supportTimer = 1.0;
  int animFrame = 0;
  double animTimer = 0;
  int shotCounter = 0;
  SpawnDirection facing = SpawnDirection.south;

  double get currentDamage => definition.damage * (1 + ((level - 1) * 0.38));
  double get currentRange => definition.range * (1 + ((level - 1) * 0.07));
  double get currentCooldown =>
      math.max(0.24, definition.cooldown * (1 - ((level - 1) * 0.07)));
  int get upgradeCost => (definition.cost * (0.70 + (level * 0.50))).round();
  bool get canUpgrade => level < 3;

  SelectedHeroDetails get details => SelectedHeroDetails(
    kind: definition.kind,
    label: definition.label,
    level: level,
    upgradeCost: upgradeCost,
    shortDescription: definition.shortDescription,
    abilityLabel: definition.abilityLabel,
    abilityDescription: definition.abilityDescription,
    canUpgrade: canUpgrade,
  );
}

class _TowerPlacement {
  _TowerPlacement({required this.definition, required this.position})
    : totalSpent = definition.cost,
      hitPoints = 120 + (definition.cost * 0.65);

  final TowerDefinition definition;
  final Vector2 position;
  int level = 1;
  int totalSpent;
  double hitPoints;
  double cooldownRemaining = 0;
  double economyTimer = 1.5;
  double attackVisualTimer = 0;
  int shotCounter = 0;
  int lastWaveBonus = 0;
  int economyIncomeBonus = 0;
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
  double get maxHitPoints =>
      120 + (definition.cost * 0.65) + ((level - 1) * 55);

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
    economyIncomePerTick: definition.economyIncome == null
        ? null
        : definition.economyIncome! + economyIncomeBonus,
    economyInterval: definition.economyInterval,
    economyIncomePerSecond:
        definition.economyIncome == null || definition.economyInterval == null
        ? null
        : (definition.economyIncome! + economyIncomeBonus) /
              definition.economyInterval!,
    economyCycleBonus: lastWaveBonus,
    economyBreakEvenSeconds:
        definition.economyIncome == null || definition.economyInterval == null
        ? null
        : definition.cost /
              ((definition.economyIncome! + economyIncomeBonus) /
                  definition.economyInterval!),
    branchId: branchId,
    branchLabel: branchId == null
        ? null
        : definition.branches
              .firstWhere((branch) => branch.id == branchId)
              .label,
  );
}

class _Enemy {
  _Enemy.fromDefinition(this.definition, {required this.spawnDirection})
    : hitPoints = definition.hitPoints.toDouble(),
      position = Vector2.zero(),
      currentDirection = spawnDirection {
    supportAbilityTimer = switch (definition.kind) {
      EnemyKind.bannerCaptain => 1.8,
      EnemyKind.plagueBearer => 2.2,
      EnemyKind.hexSniper => 3.0,
      EnemyKind.bastionPriest => 3.4,
      _ => supportAbilityTimer,
    };
  }

  final EnemyDefinition definition;
  final SpawnDirection spawnDirection;
  SpawnDirection currentDirection;
  final Vector2 position;
  double hitPoints;
  int segmentIndex = 0;
  double segmentProgress = 0;
  double progress = 0;
  double distanceToCitadel = double.infinity;
  bool reachedGoal = false;
  double slowMultiplier = 1;
  double slowTimer = 0;
  double hasteMultiplier = 1;
  double hasteTimer = 0;
  double staggerTimer = 0;
  double cultPulseTimer = 1.4;
  List<Vector2>? customPath;
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
  double towerAttackCooldown = 0;
  double towerAttackVisualTimer = 0;
  double heroMarkedTimer = 0;

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
    if (towerAttackCooldown > 0) {
      towerAttackCooldown -= dt;
    }
    if (towerAttackVisualTimer > 0) {
      towerAttackVisualTimer -= dt;
    }
    if (heroMarkedTimer > 0) {
      heroMarkedTimer -= dt;
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

  void advance(List<Vector2> path, double dt, Vector2 citadelCenter) {
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
      final heading = currentEnd - currentStart;
      if (heading.x.abs() > heading.y.abs()) {
        currentDirection = heading.x >= 0
            ? SpawnDirection.east
            : SpawnDirection.west;
      } else {
        currentDirection = heading.y >= 0
            ? SpawnDirection.south
            : SpawnDirection.north;
      }
      position.setFrom(
        currentStart + (currentEnd - currentStart) * segmentProgress,
      );
      progress = (segmentIndex + segmentProgress) / (path.length - 1);
      distanceToCitadel = position.distanceTo(citadelCenter);
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
