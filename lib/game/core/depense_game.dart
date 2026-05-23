import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/audio/audio_event.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/rendering/game_visual_registry.dart';
import 'package:depense_game/game/rendering/map_texture_planner.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;

const double _enemyMoveSpeedMultiplier = 2.0;
const int _maxCombatUnitLevel = 4;
const double _stageEventBossHpBalanceMultiplier = 0.90;
const double _stageEventBossDamageBalanceMultiplier = 0.70;
const double _stageEventStructureDamageBalanceMultiplier = 0.70;
const double _stageEventBossPhysicalDamageMultiplier = 1.0;
const int _stageEventCorruptedKnightTargetHp = 4400;
const int _stageEventBastionOverlordTargetHp = 4500;

int _coinMillWaveStartBonusFor({
  required int level,
  required int incomeBonus,
  String? branchId,
}) {
  return 8 +
      ((math.max(1, level) - 1) * 2) +
      incomeBonus +
      (branchId == 'tribute' ? 4 : 0);
}

double _towerDamageForLevel(TowerDefinition definition, int level) {
  if (definition.damage <= 0) {
    return 0;
  }
  final safeLevel = math.max(1, level);
  final preReductionBaseDamage = switch (definition.kind) {
    TowerKind.mageObelisk => 23.0,
    TowerKind.ballista => 12.0,
    _ => definition.damage + 2.5,
  };
  final unreduced = preReductionBaseDamage * (1 + ((safeLevel - 1) * 0.45));
  final reduction = safeLevel == 1 ? 2.5 : 1.5;
  final roleAdjustment = switch (definition.kind) {
    TowerKind.mageObelisk => safeLevel == 1 ? -3.0 : -5.0,
    TowerKind.ballista => 4.0,
    _ => 0.0,
  };
  return ((unreduced - reduction + roleAdjustment) * 10).roundToDouble() / 10;
}

class DefensePrototypeGame extends FlameGame with TapCallbacks, ScaleDetector {
  static const bool _combatDebugLogsEnabled = false;

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
    required this.chosenHeroKind,
    this.startingCoinBonus = 0,
  });

  final StageDefinition stage;
  final GameSessionController sessionController;
  final GameAudioService audioService;
  final ResolvedMetaUpgrades metaUpgrades;
  final HeroKind chosenHeroKind;
  final int startingCoinBonus;

  final GameVisualRegistry _visualRegistry = GameVisualRegistry();

  late List<Vector2> _pathPoints;
  Map<SpawnDirection, List<Vector2>> _pathsByDirection = {};
  Vector2 _gridOrigin = Vector2.zero();
  Vector2 _citadelCenter = Vector2.zero();
  MapTexturePlan _mapTexturePlan = MapTexturePlan.empty;

  final List<_Enemy> _enemies = [];
  final List<_TowerPlacement> _towers = [];
  final List<_BarrierPlacement> _barriers = [];
  final List<_HeroPlacement> _heroes = [];
  final List<_ProjectileVisual> _projectiles = [];
  final List<_BombardmentVisual> _bombardments = [];
  final List<_BeamVisual> _beams = [];
  final List<_PulseVisual> _pulses = [];
  final List<_ImpactVisual> _impacts = [];
  final List<_SlashVisual> _slashes = [];
  final List<_StrikeVisual> _strikes = [];
  final List<_FloatingTextVisual> _floatingTexts = [];

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
  int? _selectedBarrierIndex;
  double _selectedTowerOverlayTimer = 0;
  int _lastRecoveryReportedSecond = -1;
  int _towersBuilt = 0;
  bool _heroSummonedThisStage = false;
  bool _autoHeroPlaced = false;
  bool _heroReviveUsed = false;
  int _towersSold = 0;
  final Set<String> _builtTowerKinds = {};
  final Set<TowerKind> _firstLevelBonusUsed = {};
  List<SpawnDirection> _activeFronts = const [];
  List<SpawnDirection> _nextFronts = const [];
  int _runOfferSeed = 0;
  int _runOfferRollIndex = 0;
  StageEventDefinition? _stageEvent;
  bool _stageEventTriggered = false;
  final Set<int> _bombardmentRolledWaveNumbers = <int>{};
  final Set<int> _bombardmentLaunchedWaveNumbers = <int>{};
  double _bombardmentTimer = -1;
  int? _pendingBombardmentWaveNumber;
  int _nextEnemyDebugId = 1;
  double _combatDebugSummaryTimer = 0;
  int? _lastLoggedUiBaseHealth;
  int? _lastLoggedUiRemainingEnemies;
  int? _lastLoggedUiActiveEnemies;
  int? _lastLoggedUiWave;
  String? _lastLoggedUiBattleState;

  double _zoom = 1.0;
  double _scaleStart = 1.0;

  Shader? _cachedBgShader;
  int _maxTowerLevel = 1;
  double _syncTimer = 0.0;
  bool _sessionDirty = false;
  bool _heroAutoPlacePending = false;
  final Vector2 _walkDelta = Vector2.zero();

  bool get _isSiegeMode =>
      stage.assaultCycles.isNotEmpty &&
      (stage.pathsByDirection?.isNotEmpty ?? false);

  RunModifierSet get _runModifiers => sessionController.runModifiers;

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
    _coins =
        stage.startingCoins +
        metaUpgrades.bonusStartingCoins +
        startingCoinBonus;
    _baseHealth = stage.citadelHitPoints;
    _pathPoints = [Vector2.zero(), Vector2.all(1)];
    _mapTexturePlan = MapTexturePlan.empty;
    sessionController.hydrate(
      stageNumber: stage.number,
      totalStages: CampaignData.totalStages,
      stageTitle: stage.title,
      totalWaves: stage.cycleCount,
      coins: _coins,
      baseHealth: _baseHealth,
      actNumber: stage.actNumber ?? (((stage.number - 1) ~/ 5) + 1),
      loopLabel: 'WAVE',
    );
    sessionController.setChosenHero(chosenHeroKind);
    sessionController.setHeroSummonState(summoned: true, available: false);
    sessionController.setChosenHeroStatus(
      alive: false,
      reviveAvailable: false,
      hitPoints: 0,
      maxHitPoints: 0,
    );
    _runOfferSeed =
        (DateTime.now().microsecondsSinceEpoch ^ identityHashCode(this)) &
        0x7fffffff;
    sessionController.setRunOfferSeed(_runOfferSeed);
    final stageEvents = stage.stageEvents;
    _stageEvent = stageEvents.isEmpty
        ? StageEventGenerator.roll(
            seed: _runOfferSeed,
            stageNumber: stage.number,
            rollIndex: _runOfferRollIndex,
          )
        : stageEvents[math.Random(
            _runOfferSeed + (stage.number * 15401),
          ).nextInt(stageEvents.length)];
    if (_usesRunOfferDice) {
      _prepareRunOfferRoll();
    } else {
      _showStatus(_stageOpeningOperationLine());
    }
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
    _citadelCenter = _resolvedCitadelCenter();
    _queueChosenHeroAutoPlace();
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
    _clearSelectedBarrierSelection();
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

  void selectBarrierBuildable(BarrierKind? barrierKind) {
    sessionController.setSelectedBarrierBuildable(barrierKind);
    _clearSelectedTowerSelection();
    _clearSelectedHeroSelection();
    _clearSelectedBarrierSelection();
    if (barrierKind != null) {
      final definition = BarrierCatalog.byKind(barrierKind);
      _showStatus('${definition.label} 선택됨. 빈 타일을 터치해 배치하세요.');
      audioService.play(AudioEvent.uiSelect);
    } else {
      _showStatus('아래 배치 카드를 선택하세요.');
    }
    _syncSession();
  }

  void selectHeroBuildable(HeroKind? heroKind) {
    if (heroKind == null) {
      sessionController.setSelectedHeroBuildable(null);
      _showStatus('영웅 상태를 확인하거나 전투 중에도 1회 부활할 수 있습니다.');
      _syncSession();
      return;
    }

    final definition = HeroCatalog.byKind(heroKind);
    final existingIndex = _heroes.indexWhere(
      (hero) => hero.definition.kind == heroKind,
    );
    if (existingIndex >= 0) {
      _selectedHeroIndex = existingIndex;
      _selectedTowerIndex = null;
      _clearSelectedBarrierSelection();
      sessionController.setSelectedHero(_heroes[existingIndex].details);
      _showStatus('${definition.label}을 선택했습니다. 빈 타일을 터치하면 방어 위치를 지정합니다.');
      audioService.play(AudioEvent.uiSelect);
      _syncSession();
      return;
    }

    reviveChosenHero();
  }

  void reviveChosenHero() {
    final definition = HeroCatalog.byKind(chosenHeroKind);
    if (_heroes.isNotEmpty) {
      _showStatus('${definition.label}은 이미 전장에 있습니다.');
      _syncSession();
      return;
    }
    if (_heroReviveUsed) {
      _showStatus('이번 STAGE의 영웅 부활은 이미 사용했습니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    if (!_heroSummonedThisStage) {
      _ensureChosenHeroAutoPlaced();
      return;
    }
    final position = _heroSpawnPosition();
    if (position == null) {
      _showStatus('영웅이 부활할 빈 공간이 없습니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    _heroes.add(
      _HeroPlacement(
        definition: definition,
        position: position,
        initialLevel: _baseBuildLevelForStage(),
      ),
    );
    _heroReviveUsed = true;
    _selectedHeroIndex = _heroes.length - 1;
    _selectedBarrierIndex = null;
    sessionController.setHeroSummonState(summoned: true, available: false);
    sessionController.setHeroMoveMode(false);
    _showStatus('${definition.label}이 성 옆에서 다시 일어났습니다.');
    audioService.play(AudioEvent.towerPlace);
    _syncSelectedHero();
    _syncHeroStatus();
    _syncSession();
  }

  StageEvaluationResult evaluateCurrentRun() {
    final gameIsTerminal = _stageCleared || _stageFailed;
    final sessionIsTerminal =
        sessionController.stageCleared || sessionController.stageFailed;
    return stage.evaluateRun(
      StageRunSummary(
        cleared: _stageCleared || sessionController.stageCleared,
        baseHealthRemaining: gameIsTerminal
            ? _baseHealth
            : sessionIsTerminal
            ? sessionController.baseHealth
            : _baseHealth,
        maxBaseHealth: sessionController.maxBaseHealth,
        remainingGold: gameIsTerminal
            ? _coins
            : sessionIsTerminal
            ? sessionController.coins
            : _coins,
        towersBuilt: gameIsTerminal
            ? _towersBuilt
            : sessionIsTerminal
            ? sessionController.towersBuilt
            : _towersBuilt,
        towersSold: _towersSold,
        builtTowerKinds: gameIsTerminal
            ? _builtTowerKinds
            : sessionIsTerminal
            ? sessionController.builtTowerKinds
            : _builtTowerKinds,
      ),
    );
  }

  void _showStatus(String message) {
    _statusText = message;
    _syncSession();
  }

  bool get _usesRunOfferDice =>
      stage.number >= 4 && (stage.number - 4) % 3 == 0;

  String _stageOpeningOperationLine() {
    return switch (stage.number) {
      1 => 'STAGE 브리핑을 눌러 적과 성벽 대응을 확인하세요.',
      2 => 'STAGE 브리핑을 눌러 이번 전선과 타워 배치를 확인하세요.',
      3 => 'STAGE 브리핑을 눌러 영웅 방어 위치와 적 조합을 확인하세요.',
      _ => 'STAGE 브리핑에서 다음 압박을 확인하고 방어망을 설계하세요.',
    };
  }

  String _stageFailureHint() {
    return switch (stage.number) {
      1 => '기지가 함락되었습니다. 성벽으로 북쪽 적을 늦추고 궁수 사거리 안에서 처리하세요.',
      2 => '기지가 함락되었습니다. 한쪽에만 몰아짓지 말고 북쪽과 동쪽 사거리를 겹치세요.',
      3 => '기지가 함락되었습니다. 영웅 방어 위치를 성벽 뒤로 옮기고 장갑 적에는 마법 화력을 준비하세요.',
      4 => '기지가 함락되었습니다. 선택한 설계 카드의 작전 방향에 맞춰 성벽과 타워를 다시 배치하세요.',
      5 => '기지가 함락되었습니다. 성벽, 타워 조합, 영웅 방어 위치를 모두 나눠 준비하세요.',
      _ => '기지가 함락되었습니다. 다시 도전해 방어선을 정비하세요.',
    };
  }

  void _showSelectedTowerOverlay() {
    _selectedTowerOverlayTimer = 3.0;
  }

  void _prepareRunOfferRoll() {
    sessionController.prepareRunOfferRoll();
    _showStatus('작전 주사위를 굴려 이번 STAGE의 설계 카드를 선택하세요.');
  }

  Future<void> rollRunOfferDice() async {
    if (sessionController.runOfferFlowState != RunOfferFlowState.awaitingRoll) {
      return;
    }
    sessionController.setRunOfferRolling();
    _showStatus('주사위를 굴리는 중...');
    audioService.play(AudioEvent.uiSelect);
    _syncSession();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (sessionController.runOfferFlowState != RunOfferFlowState.rolling ||
        _stageCleared ||
        _stageFailed) {
      return;
    }
    _rollRunOffers();
  }

  void _rollRunOffers() {
    final unlockedTowers = {
      for (final tower in TowerCatalog.buildMenu)
        if (tower.isUnlocked(metaUpgrades)) tower.kind,
    };
    final offers = RunOfferGenerator.generate(
      seed: _runOfferSeed,
      stageNumber: stage.number,
      offerIndex: _runOfferRollIndex,
      unlockedTowers: unlockedTowers,
      chosenHeroKind: chosenHeroKind,
    );
    sessionController.setPendingRunOffers(offers);
    _showStatus('제안 1개를 선택하세요.');
  }

  void acceptRunOffer(String offerId) {
    RunOfferDefinition? offer;
    for (final candidate in sessionController.pendingRunOffers) {
      if (candidate.id == offerId) {
        offer = candidate;
        break;
      }
    }
    if (offer == null) {
      _showStatus('이미 사라진 제안입니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    sessionController.acceptRunOffer(offer);
    _runOfferRollIndex += 1;
    if (_runModifiers.disablesHeroRevive && !_heroReviveUsed) {
      _heroReviveUsed = true;
      _syncHeroStatus();
    }
    _showStatus(
      '작전: ${offer.operationLine} - ${offer.effectLine}. STAGE 브리핑에서 적 대응을 확인하세요.',
    );
    audioService.play(AudioEvent.uiConfirm);
    _syncSelectedTower();
    _syncSelectedHero();
    _syncSession();
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

  void _clearSelectedBarrierSelection() {
    _selectedBarrierIndex = null;
    sessionController.setSelectedBarrier(null);
  }

  void _queueChosenHeroAutoPlace() {
    if (_heroAutoPlacePending ||
        _autoHeroPlaced ||
        _heroes.isNotEmpty ||
        _citadelCenter == Vector2.zero()) {
      return;
    }
    _heroAutoPlacePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroAutoPlacePending = false;
      _ensureChosenHeroAutoPlaced();
    });
  }

  void _ensureChosenHeroAutoPlaced() {
    if (_autoHeroPlaced ||
        _heroes.isNotEmpty ||
        _citadelCenter == Vector2.zero()) {
      return;
    }
    final position = _heroSpawnPosition();
    if (position == null) {
      return;
    }
    final definition = HeroCatalog.byKind(chosenHeroKind);
    _heroes.add(
      _HeroPlacement(
        definition: definition,
        position: position,
        initialLevel: _baseBuildLevelForStage(),
      ),
    );
    _autoHeroPlaced = true;
    _heroSummonedThisStage = true;
    sessionController.setHeroSummonState(summoned: true, available: false);
    _showStatus(
      _usesRunOfferDice
          ? '${definition.label}이 성 옆에 배치되었습니다.'
          : _stageOpeningOperationLine(),
    );
    _syncHeroStatus();
  }

  Vector2? _heroSpawnPosition() {
    final citadelCell = stage.citadelCell;
    if (citadelCell == null || citadelCell.length < 2) {
      return null;
    }
    final preferred = <List<int>>[
      [citadelCell[0] + 1, citadelCell[1]],
      [citadelCell[0], citadelCell[1] - 1],
      [citadelCell[0], citadelCell[1] + 1],
      [citadelCell[0] - 1, citadelCell[1]],
    ];
    for (final cell in preferred) {
      if (_isHeroSpawnCellAvailable(cell)) {
        return _cellCenter(cell);
      }
    }
    for (var radius = 1; radius <= 4; radius += 1) {
      for (var dx = -radius; dx <= radius; dx += 1) {
        for (var dy = -radius; dy <= radius; dy += 1) {
          if (dx.abs() + dy.abs() != radius) {
            continue;
          }
          final cell = [citadelCell[0] + dx, citadelCell[1] + dy];
          if (_isHeroSpawnCellAvailable(cell)) {
            return _cellCenter(cell);
          }
        }
      }
    }
    return null;
  }

  bool _isHeroSpawnCellAvailable(List<int> cell) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty || cell.length < 2) {
      return false;
    }
    final col = cell[0];
    final row = cell[1];
    if (row < 0 ||
        row >= tileGrid.length ||
        col < 0 ||
        col >= tileGrid[row].length) {
      return false;
    }
    if (tileGrid[row][col] != TileType.buildable) {
      return false;
    }
    if (_isStaticObjectCell(col, row)) {
      return false;
    }
    final center = _cellCenter(cell);
    return !_isTooCloseToTower(center);
  }

  Vector2 _cellCenter(List<int> cell) {
    return Vector2(
      _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2),
      _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2),
    );
  }

  int _towerBuildCost(TowerDefinition definition) {
    return math.max(
      1,
      (definition.cost * _runModifiers.towerCostMultiplier(definition.kind))
          .round(),
    );
  }

  int _barrierBuildCost(BarrierDefinition definition) {
    return math.max(
      1,
      (definition.cost * _runModifiers.barrierCostMultiplier(definition.kind))
          .round(),
    );
  }

  int _barrierHitPoints(BarrierDefinition definition) {
    return math.max(
      1,
      (definition.hitPoints *
              _barrierStageHitPointMultiplier() *
              _runModifiers.barrierHitPointMultiplier(definition.kind))
          .round(),
    );
  }

  int _barrierRepairCost(BarrierDefinition definition) {
    return math.max(
      1,
      (definition.repairCost *
              _runModifiers.barrierRepairCostMultiplier(definition.kind))
          .round(),
    );
  }

  int _baseBuildLevelForStage() {
    if (stage.number >= 20) {
      return 3;
    }
    if (stage.number >= 10) {
      return 2;
    }
    return 1;
  }

  double _barrierStageHitPointMultiplier() {
    if (stage.number >= 20) {
      return 1.75;
    }
    if (stage.number >= 10) {
      return 1.35;
    }
    return 1.0;
  }

  double _towerCurrentRange(_TowerPlacement tower) {
    final levelRange = 1 + ((tower.level - 1) * 0.07);
    final branchRange = switch (tower.branchId) {
      'ranger' => 1.18,
      'sentinel' => 1.12,
      'glacier' => 1.15,
      'siege' => 1.10,
      _ => 1.0,
    };
    return _towerBaseRange(tower.definition.kind) *
        levelRange *
        branchRange *
        _runModifiers.towerRangeMultiplier(tower.definition.kind);
  }

  double _towerBaseRange(TowerKind kind) {
    return switch (kind) {
      TowerKind.coinMill => 0,
      TowerKind.guardBarracks => _tileSize * 2.55,
      TowerKind.archer => _tileSize * 3.05,
      TowerKind.ballista => _tileSize * 4.05,
      TowerKind.emberkeep => _tileSize * 3.05,
      TowerKind.frostShrine || TowerKind.mageObelisk => _tileSize * 3.05,
    };
  }

  @visibleForTesting
  double debugTowerBaseRangeFor(TowerKind kind) => _towerBaseRange(kind);

  double _heroCurrentRange(_HeroPlacement hero) {
    final levelRange = 1 + ((hero.level - 1) * 0.07);
    final baseRange = switch (hero.definition.kind) {
      HeroKind.knight || HeroKind.ninja || HeroKind.paladin => _tileSize * 1.05,
      HeroKind.archer => _tileSize * 1.55,
      HeroKind.mage => _tileSize * 2.55,
    };
    return baseRange * levelRange;
  }

  double _heroGuardRadius(_HeroPlacement hero) {
    return _tileSize * 3.2;
  }

  double _heroSelectionRange(_HeroPlacement hero) {
    return math.max(_heroCurrentRange(hero), _heroGuardRadius(hero));
  }

  @visibleForTesting
  String debugHeroAttackStyleFor(HeroKind kind) {
    return switch (kind) {
      HeroKind.knight || HeroKind.paladin => 'melee_slash',
      HeroKind.archer => EffectVisualCatalog.arrowProjectile,
      HeroKind.mage => 'arcane_beam',
      HeroKind.ninja => EffectVisualCatalog.shurikenProjectile,
    };
  }

  double _towerCurrentDamage(_TowerPlacement tower) {
    return tower.currentDamage *
        _runModifiers.towerDamageMultiplier(tower.definition.kind);
  }

  double _towerCurrentCooldown(_TowerPlacement tower) {
    return math.max(
      0.18,
      tower.currentCooldown *
          _runModifiers.towerCooldownMultiplier(tower.definition.kind),
    );
  }

  double _heroCurrentDamage(_HeroPlacement hero) {
    return hero.currentDamage *
        _runModifiers.heroDamageMultiplier(hero.definition.kind);
  }

  void startNextWave() {
    if (_waveActive || _stageCleared || _stageFailed) {
      return;
    }
    if (sessionController.mustResolveRunOffer) {
      _showStatus('작전 주사위를 굴리고 제안 1개를 선택하세요.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
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
          : '모든 WAVE가 이미 종료되었습니다.';
      _syncSession();
      return;
    }

    _currentWaveIndex += 1;
    _clearSelectedHeroSelection();
    _clearSelectedTowerSelection();
    _clearSelectedBarrierSelection();
    sessionController.setSelectedBuildable(null);
    sessionController.setSelectedBarrierBuildable(null);
    sessionController.setSelectedHeroBuildable(null);
    sessionController.setHeroMoveMode(false);
    _currentSpawnGroupIndex = 0;
    _spawnedInGroup = 0;
    _spawnTimer = 0;
    _waveActive = true;
    final wave = _waveForIndex(_currentWaveIndex);
    _remainingEnemiesInCycle = _enemyCountForWave(wave);
    final waveNumber = _currentWaveIndex + 1;
    _prepareBombardmentForWave(waveNumber);
    final cycle = _assaultCycleForIndex(_currentWaveIndex);
    _activeFronts = cycle?.activeFronts ?? _frontsForWave(wave);
    _nextFronts = _nextFrontsForIndex(_currentWaveIndex);
    final threatLine = _threatPreviewForIndex(_currentWaveIndex);
    _statusText = _isSiegeMode
        ? 'WAVE $waveNumber 시작! ${_frontShortLabel(_activeFronts)} 전선. $threatLine'
        : waveNumber <= 2
        ? 'WAVE $waveNumber 시작! 적 경로를 확인하세요.'
        : 'WAVE $waveNumber 시작!';
    final groupSummary = wave.groups
        .map((group) {
          final direction = group.direction?.name ?? 'default';
          final route = group.routeId ?? '-';
          return '${group.count}x${group.enemy.kind.name}'
              '@$direction/$route/${group.spawnInterval.toStringAsFixed(2)}s';
        })
        .join(' | ');
    _combatLog(
      'WAVE_START',
      'wave=$waveNumber base=$_baseHealth/${stage.citadelHitPoints} '
          'expectedEnemies=$_remainingEnemiesInCycle '
          'activeFronts=${_activeFronts.map((front) => front.name).join(',')} '
          'threat="$threatLine" groups=[$groupSummary]',
    );
    _logEnemySummary('wave_start');
    for (final tower in _towers.where(
      (tower) => tower.definition.kind == TowerKind.coinMill,
    )) {
      final waveBonus = tower.economyWaveStartBonus;
      _coins += waveBonus;
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
    late final TowerDefinition definition;
    if (tower == null) {
      _showStatus('업그레이드할 건물이 없습니다.');
      _syncSession();
      return;
    }
    definition = tower.definition;
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
      _towerCurrentCooldown(tower),
    );
    _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
    _showSelectedTowerOverlay();
    _showStatus('${definition.label} 건설 완료. 다시 탭하면 업그레이드/철거.');
    _showStatus('${tower.definition.label} 업그레이드 완료.');
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

  void sellSelectedBarrier() {
    final index = _selectedBarrierIndex;
    final barrier = _selectedBarrier;
    if (index == null || barrier == null) {
      _showStatus('철거할 성벽이 없습니다.');
      _syncSession();
      return;
    }

    _coins += barrier.sellValue;
    _barriers.removeAt(index);
    _clearSelectedBarrierSelection();
    _showStatus(
      '${barrier.definition.label}을(를) 철거하고 ${barrier.sellValue} 코인을 회수했습니다.',
    );
    audioService.play(AudioEvent.coinGain);
    _rerouteEnemies();
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
    _clearSelectedHeroSelection();
    _syncSession();
  }

  void enterHeroMoveMode() {
    if (_selectedHeroIndex == null) return;
    if (_waveActive) {
      _showStatus('WAVE 중에는 영웅 방어 위치를 바꿀 수 없습니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    sessionController.setHeroMoveMode(true);
    sessionController.setSelectedHero(null);
    _showStatus('영웅이 지킬 방어 위치를 선택하세요.');
    _syncSession();
  }

  void clearSelectedHero() {
    _selectedHeroIndex = null;
    sessionController.setSelectedHero(null);
    sessionController.setHeroMoveMode(false);
    _syncSession();
  }

  void clearSelectedTower() {
    _clearSelectedTowerSelection();
    _syncSession();
  }

  void clearSelectedBarrier() {
    _clearSelectedBarrierSelection();
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
      if (_sessionDirty) {
        _sessionDirty = false;
        _flushSession();
      }
      super.update(dt);
      return;
    }

    _updateRecovery(dt);
    _updateWaveSpawning(dt);
    _updateEnemies(dt);
    _updateTowers(dt);
    _updateHeroes(dt);
    _updateBombardments(dt);
    _updateVisuals(dt);
    if (_waveActive &&
        _enemies.isEmpty &&
        _pendingEnemySpawnsForCurrentWave() > 0) {
      _spawnTimer = math.min(_spawnTimer, 0.25);
    }
    _reconcileRemainingEnemyCount();
    _maybeTriggerStageEvent();
    _checkWaveResolution();
    _updateCombatDebugSummary(dt);
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
    _drawRoadTiles(canvas);
    _drawObstacles(canvas);
    _drawBarriers(canvas);
    _drawFrontTelegraphs(canvas);
    _drawSpawnCue(canvas);
    _drawCitadel(canvas);
    _drawSlots(canvas);
    _drawSelectionRanges(canvas);
    _drawPulses(canvas);
    _drawTowers(canvas);
    _drawHeroes(canvas);
    _drawSlashes(canvas);
    _drawStrikes(canvas);
    _drawProjectiles(canvas);
    _drawBombardments(canvas);
    _drawEnemies(canvas);
    _drawImpacts(canvas);
    _drawFloatingTexts(canvas);
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
      _clearSelectedBarrierSelection();
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
      _clearSelectedBarrierSelection();
      sessionController.bumpSelectionVersion();
      sessionController.setSelectedTower(_towers[towerIndex].details);
      _showStatus('건물을 선택해 업그레이드나 철거가 가능합니다.');
      _showSelectedTowerOverlay();
      _syncSession();
      return;
    }

    final barrierIndex = _barrierIndexAt(position);
    if (barrierIndex != null) {
      _selectedBarrierIndex = barrierIndex;
      _selectedTowerIndex = null;
      _selectedHeroIndex = null;
      final barrier = _barriers[barrierIndex];
      sessionController.bumpSelectionVersion();
      sessionController.setSelectedBarrier(barrier.details);
      _showStatus('${barrier.definition.label} 선택됨. WAVE 중에도 철거할 수 있습니다.');
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

    final barrierSelection = sessionController.selectedBarrierBuildable;
    if (barrierSelection != null) {
      _handleBarrierPlacement(position, barrierSelection);
      return;
    }

    final selection = sessionController.selectedBuildable;
    if (selection == null) {
      _clearSelectedTowerSelection();
      _showStatus('아래 카드를 클릭해서 건물을 배치하세요.');
      _syncSession();
      return;
    }
    if (_waveActive) {
      _showStatus('WAVE 중에는 타워를 건설할 수 없습니다. 회복 시간에 배치하세요.');
      audioService.play(AudioEvent.uiError);
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
    final buildCost = _towerBuildCost(definition);
    if (_coins < buildCost) {
      _showStatus('${definition.label} 건설에 필요한 코인이 부족합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= buildCost;
    final alreadyBuiltKind = _towers.any(
      (tower) => tower.definition.kind == definition.kind,
    );
    final levelBonus =
        alreadyBuiltKind || _firstLevelBonusUsed.contains(selection)
        ? 0
        : _runModifiers.firstTowerLevelBonus(selection);
    final initialLevel = (_baseBuildLevelForStage() + levelBonus).clamp(
      1,
      _maxCombatUnitLevel,
    );
    if (levelBonus > 0) {
      _firstLevelBonusUsed.add(selection);
    }
    final tower = _TowerPlacement(
      definition: definition,
      position: snapTarget.clone(),
      initialLevel: initialLevel,
      totalSpent: buildCost,
    )..economyIncomeBonus = metaUpgrades.coinMillIncomeBonus;
    _towers.add(tower);
    if (initialLevel > _maxTowerLevel) {
      _maxTowerLevel = initialLevel;
    }
    _towersBuilt += 1;
    _builtTowerKinds.add(definition.kind.name);
    _selectedTowerIndex = _towers.length - 1;
    _selectedHeroIndex = null;
    _selectedBarrierIndex = null;
    _showSelectedTowerOverlay();
    _spawnImpact(snapTarget, definition.color, 18, 0.18);
    audioService.play(AudioEvent.towerPlace);
    _showStatus('${definition.label} 건설 완료. 사거리를 확인하고 다음 배치를 준비하세요.');
    _syncSelectedTower();
    _syncSession();
  }

  void _handleHeroPlacement(Vector2 position, HeroKind heroKind) {
    final definition = HeroCatalog.byKind(heroKind);
    if (_heroSummonedThisStage || _heroes.isNotEmpty) {
      sessionController.setSelectedHeroBuildable(null);
      _showStatus('선택한 영웅은 성 옆에 자동 배치됩니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
    if (_waveActive) {
      _showStatus(
        'Build during prep or recovery. Hold the line until the cycle ends.',
      );
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }
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
    _heroes.add(
      _HeroPlacement(
        definition: definition,
        position: snapTarget.clone(),
        initialLevel: _baseBuildLevelForStage(),
      ),
    );
    _heroSummonedThisStage = true;
    _selectedHeroIndex = _heroes.length - 1;
    sessionController.setSelectedHeroBuildable(null);
    sessionController.setHeroSummonState(summoned: true, available: false);
    sessionController.setHeroMoveMode(false);
    _showStatus(
      '${definition.label}을 배치했습니다. 영웅을 선택하면 방어 위치 지정과 업그레이드가 가능합니다.',
    );
    audioService.play(AudioEvent.towerPlace);
    _syncSelectedHero();
    _syncHeroStatus();
    _syncSession();
  }

  void _handleBarrierPlacement(Vector2 position, BarrierKind barrierKind) {
    if (_waveActive) {
      _showStatus('성벽은 준비 또는 회복 중에만 지을 수 있습니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    final definition = BarrierCatalog.byKind(barrierKind);
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
      _showStatus('성벽을 배치할 수 있는 빈 타일을 선택하세요.');
      _syncSession();
      return;
    }
    final buildCost = _barrierBuildCost(definition);
    if (_coins < buildCost) {
      _showStatus('${definition.label} 배치에 ${definition.cost} 골드가 필요합니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

    _coins -= buildCost;
    _barriers.add(
      _BarrierPlacement(
        definition: definition,
        position: snapTarget.clone(),
        maxHitPoints: _barrierHitPoints(definition).toDouble(),
        repairCost: _barrierRepairCost(definition),
      ),
    );
    _selectedBarrierIndex = null;
    sessionController.setSelectedBarrier(null);
    _showStatus('${definition.label} 배치 완료. 빈 타일을 탭하면 계속 배치합니다.');
    audioService.play(AudioEvent.towerPlace);
    _rerouteEnemies();
    _syncSession();
  }

  void _handleHeroMove(Vector2 position, _HeroPlacement hero) {
    if (_waveActive) {
      sessionController.setHeroMoveMode(false);
      _showStatus('WAVE 중에는 영웅 방어 위치를 바꿀 수 없습니다.');
      audioService.play(AudioEvent.uiError);
      _syncSession();
      return;
    }

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
      _showStatus('방어 위치로 지정할 수 있는 빈 타일을 선택하세요.');
      _syncSession();
      return;
    }
    hero.guardAnchor.setFrom(snapTarget);
    hero.walkTarget = snapTarget.clone();
    _clearSelectedHeroSelection();
    sessionController.setHeroMoveMode(false);
    _showStatus('${hero.definition.label}의 방어 위치를 지정했습니다.');
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

  int? _barrierIndexAt(Vector2 position) {
    for (var i = 0; i < _barriers.length; i += 1) {
      if (_barriers[i].position.distanceTo(position) <= (_tileSize * 0.48)) {
        return i;
      }
    }
    return null;
  }

  int? _barrierIndexAtCell(int col, int row) {
    for (var i = 0; i < _barriers.length; i += 1) {
      final cell = _cellForWorldPosition(_barriers[i].position);
      if (cell != null && cell.$1 == col && cell.$2 == row) {
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

  WaveDefinition _waveForIndex(int index) {
    final baseWave = stage.waves[index];
    final cycle = _assaultCycleForIndex(index);
    final variant = _variantForCycle(index, cycle);
    if (variant == null) {
      return baseWave;
    }
    return WaveDefinition(
      number: baseWave.number,
      groupGap: baseWave.groupGap,
      groups: [
        for (final group in variant.groups)
          SpawnGroupDefinition(
            enemy: group.enemy,
            count: group.count,
            spawnInterval: group.spawnInterval,
            direction: group.front,
            routeId: group.routeId,
          ),
      ],
    );
  }

  WaveVariantDefinition? _variantForCycle(
    int index,
    AssaultCycleDefinition? cycle,
  ) {
    if (cycle == null || cycle.variants.isEmpty) {
      return null;
    }
    final variantIndex = WaveVariantSelector.indexFor(
      seed: _runOfferSeed,
      stageNumber: stage.number,
      waveIndex: index,
      cycleNumber: cycle.number,
      variantCount: cycle.variants.length,
    );
    return cycle.variants[variantIndex];
  }

  String _threatPreviewForIndex(int index) {
    if (index < 0 || index >= stage.waves.length) {
      return '';
    }
    final variant = _variantForCycle(index, _assaultCycleForIndex(index));
    if (variant != null && variant.threatTags.isNotEmpty) {
      return '위협: ${variant.threatTags.join(' + ')}';
    }
    final tags = <String>{};
    for (final group in _waveForIndex(index).groups) {
      switch (group.enemy.wallBehavior) {
        case EnemyWallBehavior.rerouteFirst:
          tags.add('빠른 압박');
          break;
        case EnemyWallBehavior.mixedBreaker:
          tags.add('혼합 압박');
          break;
        case EnemyWallBehavior.forceBreaker:
          tags.add('성벽 파괴');
          break;
      }
      if (group.enemy.kind == EnemyKind.cultAdept ||
          group.enemy.kind == EnemyKind.bannerCaptain ||
          group.enemy.kind == EnemyKind.plagueBearer ||
          group.enemy.kind == EnemyKind.warlock ||
          group.enemy.kind == EnemyKind.bastionPriest) {
        tags.add('지원몹');
      }
    }
    return tags.isEmpty ? '위협: 기본 압박' : '위협: ${tags.take(3).join(' + ')}';
  }

  bool _isFiniteVector(Vector2 value) {
    return value.x.isFinite && value.y.isFinite;
  }

  void _combatLog(String event, String details) {
    if (!kDebugMode || !_combatDebugLogsEnabled) {
      return;
    }
    debugPrint(
      '[CITADEL_DEBUG][$event][S${stage.number} W${_currentWaveIndex + 1}/${stage.waves.length}] $details',
    );
  }

  String _formatVector(Vector2 value) =>
      '(${value.x.toStringAsFixed(1)},${value.y.toStringAsFixed(1)})';

  String _formatCell((int, int)? cell) {
    if (cell == null) {
      return '-';
    }
    return '${cell.$1},${cell.$2}';
  }

  String _formatEnemy(_Enemy enemy) {
    final cell = _cellForWorldPosition(enemy.position);
    final route = enemy.routeId ?? '-';
    return '#${enemy.debugId}:${enemy.definition.kind.name} '
        'hp=${enemy.hitPoints.toStringAsFixed(1)}/${enemy.definition.hitPoints.toStringAsFixed(1)} '
        'pos=${_formatVector(enemy.position)} cell=${_formatCell(cell)} '
        'dir=${enemy.spawnDirection.name} route=$route '
        'progress=${enemy.progress.toStringAsFixed(2)} '
        'distance=${enemy.distanceToCitadel.toStringAsFixed(1)} '
        'breach=${_formatCell(enemy.breachTargetCell)} '
        'touchesCitadel=${_enemyTouchesCitadel(enemy)} '
        'blockingBarrier=${_hasBlockingCitadelBarrier(enemy)}';
  }

  void _logEnemyEvent(String event, _Enemy enemy, [String details = '']) {
    _combatLog(
      event,
      '${_formatEnemy(enemy)} $details '
      'base=$_baseHealth/${stage.citadelHitPoints} '
      'active=${_enemies.length} remainingModel=$_remainingEnemiesInCycle '
      'pending=${_pendingEnemySpawnsForCurrentWave()}',
    );
  }

  void _logEnemySummary(String reason) {
    if (!kDebugMode || !_combatDebugLogsEnabled) {
      return;
    }
    final enemySamples = _enemies
        .take(12)
        .map((enemy) {
          final cell = _cellForWorldPosition(enemy.position);
          return '#${enemy.debugId}:${enemy.definition.kind.name}'
              ':hp=${enemy.hitPoints.toStringAsFixed(0)}'
              ':cell=${_formatCell(cell)}'
              ':touch=${_enemyTouchesCitadel(enemy)}'
              ':block=${_hasBlockingCitadelBarrier(enemy)}'
              ':breach=${_formatCell(enemy.breachTargetCell)}';
        })
        .join(' | ');
    final more = _enemies.length > 12 ? ' | +${_enemies.length - 12} more' : '';
    _combatLog(
      'SUMMARY',
      'reason=$reason base=$_baseHealth/${stage.citadelHitPoints} '
          'active=${_enemies.length} remainingModel=$_remainingEnemiesInCycle '
          'pending=${_pendingEnemySpawnsForCurrentWave()} '
          'waveActive=$_waveActive recovery=$_recoveryActive '
          'enemies=[$enemySamples$more]',
    );
  }

  void _logCitadelTouchIfBlocked(_Enemy enemy) {
    if (!kDebugMode ||
        !_combatDebugLogsEnabled ||
        enemy.debugTouchBlockedLogged ||
        !_enemyTouchesCitadel(enemy) ||
        !_hasBlockingCitadelBarrier(enemy)) {
      return;
    }
    enemy.debugTouchBlockedLogged = true;
    _logEnemyEvent(
      'CITADEL_TOUCH_BLOCKED',
      enemy,
      'reason=barrier_between_enemy_and_citadel',
    );
  }

  void _updateCombatDebugSummary(double dt) {
    if (!kDebugMode || !_combatDebugLogsEnabled || !_waveActive) {
      _combatDebugSummaryTimer = 0;
      return;
    }
    _combatDebugSummaryTimer += dt;
    if (_combatDebugSummaryTimer < 1.0) {
      return;
    }
    _combatDebugSummaryTimer = 0;
    _logEnemySummary('tick');
  }

  void _logUiSnapshotIfChanged(String battleState, int runtimeRemaining) {
    if (!kDebugMode || !_combatDebugLogsEnabled) {
      return;
    }
    final wave = _currentWaveIndex + 1;
    if (_lastLoggedUiBaseHealth == _baseHealth &&
        _lastLoggedUiRemainingEnemies == runtimeRemaining &&
        _lastLoggedUiActiveEnemies == _enemies.length &&
        _lastLoggedUiWave == wave &&
        _lastLoggedUiBattleState == battleState) {
      return;
    }
    _lastLoggedUiBaseHealth = _baseHealth;
    _lastLoggedUiRemainingEnemies = runtimeRemaining;
    _lastLoggedUiActiveEnemies = _enemies.length;
    _lastLoggedUiWave = wave;
    _lastLoggedUiBattleState = battleState;
    _combatLog(
      'UI_SYNC',
      'battleState=$battleState uiWave=$wave '
          'uiBase=$_baseHealth/${stage.citadelHitPoints} '
          'uiRemaining=$runtimeRemaining active=${_enemies.length} '
          'pending=${_pendingEnemySpawnsForCurrentWave()} '
          'status="${_statusText.replaceAll('\n', ' ')}"',
    );
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

  (int, int)? _citadelGateCellFor(SpawnDirection direction) {
    final tileGrid = stage.tileGrid;
    final columns = tileGrid?.isNotEmpty == true ? tileGrid!.first.length : 14;
    final rows = tileGrid?.length ?? 14;
    final cell = citadelGateCellForDirection(
      stage.citadelCell,
      direction,
      columns: columns,
      rows: rows,
    );
    if (cell == null || cell.length < 2) {
      return null;
    }
    return (cell[0], cell[1]);
  }

  Vector2? _citadelGateCenterForDirection(SpawnDirection direction) {
    final cell = _citadelGateCellFor(direction);
    if (cell == null) {
      return null;
    }
    return _cellCenter([cell.$1, cell.$2]);
  }

  bool _cellMatches((int, int)? cell, int col, int row) {
    return cell != null && cell.$1 == col && cell.$2 == row;
  }

  bool _shouldResolveEnemyLeak(_Enemy enemy) {
    if (!_enemyTouchesCitadel(enemy)) {
      return false;
    }
    if (_isSiegeMode && _hasBlockingCitadelBarrier(enemy)) {
      return false;
    }
    return enemy.reachedGoal || !_hasBlockingCitadelBarrier(enemy);
  }

  bool _enemyTouchesCitadel(_Enemy enemy) {
    final citadelCell = stage.citadelCell;
    final enemyCell = _cellForWorldPosition(enemy.position);
    final gateCell = _citadelGateCellFor(enemy.spawnDirection);

    if (_isSiegeMode && gateCell != null) {
      if (_cellMatches(enemyCell, gateCell.$1, gateCell.$2)) {
        return true;
      }
      final gateCenter = _citadelGateCenterForDirection(enemy.spawnDirection);
      if (gateCenter != null &&
          enemy.position.distanceTo(gateCenter) <=
              math.max(8.0, _tileSize * 0.48)) {
        return true;
      }
      return enemy.reachedGoal;
    }

    if (citadelCell != null && citadelCell.length >= 2) {
      if (enemyCell != null &&
          enemyCell.$1 == citadelCell[0] &&
          enemyCell.$2 == citadelCell[1]) {
        return true;
      }
    }

    final footprintHalfSize = _tileSize * 0.82;
    final delta = enemy.position - _citadelCenter;
    return (delta.x.abs() <= footprintHalfSize &&
            delta.y.abs() <= footprintHalfSize) ||
        enemy.distanceToCitadel <= _citadelGoalRadius(enemy);
  }

  bool _hasBlockingCitadelBarrier(_Enemy enemy) {
    final targetCell =
        enemy.breachTargetCell ?? _citadelGateCellFor(enemy.spawnDirection);
    if (targetCell == null) {
      return false;
    }
    final barrierIndex = _barrierIndexAtCell(targetCell.$1, targetCell.$2);
    if (barrierIndex == null) {
      return false;
    }
    final barrier = _barriers[barrierIndex];
    final barrierDistance = barrier.position.distanceTo(_citadelCenter);
    final enemyDistance = enemy.position.distanceTo(_citadelCenter);
    return barrierDistance <= enemyDistance + (_tileSize * 0.35);
  }

  int _pendingEnemySpawnsForCurrentWave() {
    if (!_waveActive || _currentWaveIndex < 0) {
      return 0;
    }
    final wave = _waveForIndex(_currentWaveIndex);
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
    return enemy.hitPoints <= 0 || !_isFiniteVector(enemy.position);
  }

  void _reconcileRemainingEnemyCount() {
    final nextCount = !_waveActive || _currentWaveIndex < 0
        ? 0
        : _enemies.where((enemy) => !_isEnemyTerminalForCycle(enemy)).length +
              _pendingEnemySpawnsForCurrentWave();
    if (nextCount != _remainingEnemiesInCycle) {
      _combatLog(
        'REMAINING_RECONCILE',
        'remaining=$_remainingEnemiesInCycle->$nextCount '
            'active=${_enemies.length} pending=${_pendingEnemySpawnsForCurrentWave()} '
            'base=$_baseHealth/${stage.citadelHitPoints}',
      );
      _remainingEnemiesInCycle = nextCount;
      _syncSession();
    }
  }

  void _consumeRemainingEnemy([String reason = 'unknown']) {
    final before = _remainingEnemiesInCycle;
    _remainingEnemiesInCycle = math.max(0, _remainingEnemiesInCycle - 1);
    _combatLog(
      'REMAINING_CONSUME',
      'reason=$reason remaining=$before->$_remainingEnemiesInCycle '
          'active=${_enemies.length} pending=${_pendingEnemySpawnsForCurrentWave()} '
          'base=$_baseHealth/${stage.citadelHitPoints}',
    );
    _syncSession();
  }

  void _resolveEnemyLeakAt(int index, _Enemy enemy) {
    final baseBefore = _baseHealth;
    final positionBefore = _formatVector(enemy.position);
    final cellBefore = _formatCell(_cellForWorldPosition(enemy.position));
    final touchesBefore = _enemyTouchesCitadel(enemy);
    final blockingBefore = _hasBlockingCitadelBarrier(enemy);
    final leakCenter =
        _citadelGateCenterForDirection(enemy.spawnDirection) ?? _citadelCenter;
    final leakCell = _citadelGateCellFor(enemy.spawnDirection);
    enemy.reachedGoal = true;
    enemy.progress = 1;
    enemy.position.setFrom(leakCenter);
    final leakDamage = _citadelLeakDamageFor(enemy);
    _baseHealth -= leakDamage;
    _spawnImpact(leakCenter, const Color(0xCCFF6A4C), 34, 0.28);
    _spawnImpact(leakCenter, const Color(0x88FFF1B8), 20, 0.18);
    _spawnFloatingText(
      leakCenter + Vector2(0, -24),
      '-$leakDamage',
      const Color(0xFFFF6A4C),
      lifetime: 0.72,
    );
    _logEnemyEvent(
      'LEAK_CITADEL',
      enemy,
      'base=$baseBefore->$_baseHealth '
          'leakDamage=$leakDamage '
          'leakCell=${_formatCell(leakCell)} leakPos=${_formatVector(leakCenter)} '
          'beforePos=$positionBefore beforeCell=$cellBefore '
          'touchesBefore=$touchesBefore blockingBefore=$blockingBefore',
    );
    _consumeRemainingEnemy('reached_goal');
    _enemies.removeAt(index);
    if (_baseHealth <= 0) {
      _baseHealth = 0;
      _stageFailed = true;
      _waveActive = false;
      _remainingEnemiesInCycle = 0;
      _showStatus(_stageFailureHint());
    }
  }

  void _updateWaveSpawning(double dt) {
    if (!_waveActive || _currentWaveIndex < 0) {
      return;
    }

    final wave = _waveForIndex(_currentWaveIndex);
    if (_currentSpawnGroupIndex >= wave.groups.length) {
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer > 0) {
      return;
    }

    final group = wave.groups[_currentSpawnGroupIndex];
    final spawnDirection = group.direction ?? _defaultSpawnDirectionForWave();
    final routeId =
        group.routeId ??
        _routeIdForSpawn(spawnDirection, _currentWaveIndex, _spawnedInGroup);
    final enemy = _Enemy.fromDefinition(
      group.enemy,
      spawnDirection: spawnDirection,
      routeId: routeId,
    );
    enemy.debugId = _nextEnemyDebugId++;
    _assignSiegePathForEnemy(enemy);
    _placeEnemyOnPath(enemy);
    _enemies.add(enemy);
    _spawnedInGroup += 1;
    _spawnTimer = group.spawnInterval;
    _logEnemyEvent(
      'SPAWN',
      enemy,
      'group=$_currentSpawnGroupIndex spawnedInGroup=$_spawnedInGroup/${group.count} '
          'nextSpawnIn=${_spawnTimer.toStringAsFixed(2)}',
    );

    if (_spawnedInGroup >= group.count) {
      _currentSpawnGroupIndex += 1;
      _spawnedInGroup = 0;
      _spawnTimer = wave.groupGap;
    }
  }

  void _maybeTriggerStageEvent() {
    final event = _stageEvent;
    if (event == null || _stageEventTriggered || !_waveActive) {
      return;
    }
    if (_currentWaveIndex != stage.waves.length - 1) {
      return;
    }
    if (event.trigger != StageEventTrigger.remainingEnemies) {
      return;
    }
    if (_pendingEnemySpawnsForCurrentWave() > 0) {
      return;
    }
    final aliveEnemies = _enemies.where((enemy) => enemy.hitPoints > 0).length;
    final remaining = math.max(_remainingEnemiesInCycle, aliveEnemies);
    if (remaining > event.remainingEnemiesThreshold) {
      return;
    }

    final activeFronts = _activeFronts.isNotEmpty
        ? _activeFronts
        : (_assaultCycleForIndex(_currentWaveIndex)?.activeFronts ??
              SpawnDirection.values);
    final direction =
        activeFronts[(_runOfferSeed + stage.number + _currentWaveIndex) %
            activeFronts.length];
    final routeId = _routeIdForSpawn(direction, _currentWaveIndex, 0);
    final enemy =
        _Enemy.fromDefinition(
            _stageEventEnemyDefinition(event),
            spawnDirection: direction,
            routeId: routeId,
          )
          ..debugId = _nextEnemyDebugId++
          ..visualScale = event.visualScale
          ..stageEventLabel = event.title
          ..bossAuraVisualTimer = 1.4;
    _assignSiegePathForEnemy(enemy);
    _placeEnemyOnPath(enemy);
    _enemies.add(enemy);
    _remainingEnemiesInCycle += 1;
    _stageEventTriggered = true;
    _showStatus(event.message);
    _spawnFloatingText(
      enemy.position + Vector2(0, -34),
      '보스 등장!',
      const Color(0xFFFFD27A),
      lifetime: 1.1,
    );
    _spawnPulse(
      center: enemy.position,
      color: const Color(0xFFE98259),
      maxRadius: 44,
      lifetime: 0.55,
      strokeWidth: 4,
    );
    audioService.play(AudioEvent.enemyDeathElite);
    _logEnemyEvent('STAGE_EVENT_SPAWN', enemy, 'event=${event.id}');
  }

  EnemyDefinition _stageEventEnemyDefinition(StageEventDefinition event) {
    final base = CampaignData.enemyForKind(
      event.enemyKind,
      stageNumber: stage.number,
      intensity: 1.0,
      applyGeneralHpBuff: false,
    );
    final hitPoints = _stageEventBossHitPoints(base, event);
    return EnemyDefinition(
      kind: base.kind,
      label: '${event.title} ${base.label}',
      specialDescription: base.specialDescription,
      hitPoints: hitPoints,
      speed: base.speed * 0.95,
      rewardCoins: math.max(1, (base.rewardCoins * 1.15).round()),
      citadelDamage: _stageEventBossCitadelDamage(base, event),
      color: base.color,
      structureDamage: _stageEventBossStructureDamage(base.kind, event),
      towerContactDamage: _stageEventBossTowerContactDamage(base, event),
      citadelLeakDamage: base.citadelLeakDamage,
      structureAttackCooldown: base.structureAttackCooldown,
      canBreachWalls: base.canBreachWalls,
      wallBehavior: base.wallBehavior,
      wallBreakChance: base.wallBreakChance,
    );
  }

  int _stageEventBossHitPoints(
    EnemyDefinition base,
    StageEventDefinition event,
  ) {
    final targetHitPoints = switch (base.kind) {
      EnemyKind.corruptedKnight => _stageEventCorruptedKnightTargetHp,
      EnemyKind.bastionOverlord => _stageEventBastionOverlordTargetHp,
      _ => null,
    };
    if (targetHitPoints != null) {
      return targetHitPoints.clamp(1, _stageEventBossHpCap()).toInt();
    }

    return (base.hitPoints *
            event.hitPointMultiplier *
            _stageEventBossHpBalanceMultiplier)
        .round()
        .clamp(1, _stageEventBossHpCap())
        .toInt();
  }

  int _stageEventBossHpCap() {
    if (stage.number <= 12) {
      return 4500;
    }
    if (stage.number <= 15) {
      return 5200;
    }
    return 4500;
  }

  int _stageEventBossCitadelDamage(
    EnemyDefinition base,
    StageEventDefinition event,
  ) {
    if (base.kind == EnemyKind.bastionOverlord) {
      return 15;
    }
    return math.max(
      1,
      (base.citadelDamage *
              event.damageMultiplier *
              _stageEventBossDamageBalanceMultiplier)
          .round(),
    );
  }

  int _stageEventBossStructureDamage(
    EnemyKind kind,
    StageEventDefinition event,
  ) {
    if (kind == EnemyKind.bastionOverlord) {
      return _rawStructureDamageCapForBalancedDamage(78);
    }
    final scaled = math.max(
      1,
      (EnemyDefinition.defaultStructureDamageFor(kind) *
              event.damageMultiplier *
              _stageEventBossDamageBalanceMultiplier)
          .round(),
    );
    final cap = _stageEventBossStructureDamageCap(kind);
    if (cap == null) {
      return scaled;
    }
    return math.min(scaled, _rawStructureDamageCapForBalancedDamage(cap));
  }

  int _stageEventBossTowerContactDamage(
    EnemyDefinition base,
    StageEventDefinition event,
  ) {
    if (base.kind == EnemyKind.bastionOverlord) {
      return 88;
    }
    final scaled = math.max(
      1,
      (base.baseTowerContactDamage *
              event.damageMultiplier *
              _stageEventBossDamageBalanceMultiplier)
          .round(),
    );
    final cap = _stageEventBossTowerContactDamageCap(base.kind);
    return cap == null ? scaled : math.min(scaled, cap);
  }

  int? _stageEventBossStructureDamageCap(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.corruptedKnight => 75,
      EnemyKind.bastionOverlord => 78,
      _ => null,
    };
  }

  int? _stageEventBossTowerContactDamageCap(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.corruptedKnight => 85,
      EnemyKind.bastionOverlord => 88,
      _ => null,
    };
  }

  int _rawStructureDamageCapForBalancedDamage(int balancedDamage) {
    return math.max(
      1,
      ((balancedDamage + 0.499) / _stageEventStructureDamageBalanceMultiplier)
          .floor(),
    );
  }

  bool _isBossEnemy(_Enemy enemy) {
    return enemy.stageEventLabel != null ||
        enemy.definition.kind == EnemyKind.bastionOverlord;
  }

  bool _canEnemyDamageTowersOnContact(_Enemy enemy) =>
      enemy.definition.baseTowerContactDamage > 0;

  int _citadelLeakDamageFor(_Enemy enemy) {
    if (_isBossEnemy(enemy)) {
      return math.max(2, enemy.definition.citadelLeakDamage);
    }
    return enemy.definition.citadelLeakDamage;
  }

  double _enemyAttackVisualDuration(_Enemy enemy) =>
      _isBossEnemy(enemy) ? 0.44 : 0.22;

  void _spawnBossShockwaveVisual(_Enemy enemy, Vector2 center) {
    if (!_isBossEnemy(enemy)) {
      return;
    }
    final radius =
        _tileSize *
        (enemy.definition.kind == EnemyKind.bastionOverlord
            ? (enemy.stageEventLabel != null ? 1.46 : 1.65)
            : 1.42);
    enemy.bossAuraVisualTimer = math.max(enemy.bossAuraVisualTimer, 1.15);
    _spawnImpact(
      center,
      const Color(0xFFFFB05F),
      radius,
      0.46,
      effectId: EffectVisualCatalog.bossShockwaveImpact,
    );
    _spawnPulse(
      center: center,
      color: const Color(0xFFFFB05F),
      maxRadius: radius,
      lifetime: 0.44,
      strokeWidth: 4.8,
    );
  }

  void _applyBossShockwave(
    _Enemy enemy, {
    required Vector2 center,
    required double damage,
    required Vector2 primaryPosition,
  }) {
    if (!_isBossEnemy(enemy)) {
      return;
    }
    _spawnBossShockwaveVisual(enemy, center);
    final radius =
        _tileSize *
        (enemy.definition.kind == EnemyKind.bastionOverlord
            ? (enemy.stageEventLabel != null ? 1.46 : 1.65)
            : 1.42);
    final splashDamage = math.max(1.0, damage * 0.42);
    var removedBarrier = false;
    var removedTower = false;

    for (var index = _barriers.length - 1; index >= 0; index -= 1) {
      final barrier = _barriers[index];
      if (barrier.position.distanceTo(primaryPosition) < 1.0 ||
          barrier.position.distanceTo(center) > radius) {
        continue;
      }
      barrier.hitPoints -= splashDamage;
      _spawnFloatingText(
        barrier.position + Vector2(0, -18),
        '-${splashDamage.round()}',
        const Color(0xFFFFB05F),
        lifetime: 0.52,
      );
      if (barrier.hitPoints > 0) {
        continue;
      }
      _barriers.removeAt(index);
      removedBarrier = true;
      if (_selectedBarrierIndex == index) {
        _selectedBarrierIndex = null;
      } else if (_selectedBarrierIndex != null &&
          _selectedBarrierIndex! > index) {
        _selectedBarrierIndex = _selectedBarrierIndex! - 1;
      }
    }

    for (var index = _towers.length - 1; index >= 0; index -= 1) {
      final tower = _towers[index];
      if (tower.position.distanceTo(primaryPosition) < 1.0 ||
          tower.position.distanceTo(center) > radius) {
        continue;
      }
      tower.hitPoints -= splashDamage;
      _spawnFloatingText(
        tower.position + Vector2(0, -20),
        '-${splashDamage.round()}',
        const Color(0xFFFFB05F),
        lifetime: 0.52,
      );
      if (tower.hitPoints > 0) {
        continue;
      }
      _towers.removeAt(index);
      removedTower = true;
      if (_selectedTowerIndex == index) {
        _selectedTowerIndex = null;
      } else if (_selectedTowerIndex != null && _selectedTowerIndex! > index) {
        _selectedTowerIndex = _selectedTowerIndex! - 1;
      }
    }

    if (removedBarrier) {
      _rerouteEnemies();
    }
    if (removedTower) {
      _maxTowerLevel = _towers.isEmpty
          ? 1
          : _towers.map((tower) => tower.level).reduce(math.max);
    }
    _syncSelectedTower();
    _syncSelectedBarrier();
  }

  @visibleForTesting
  bool debugEnemyKindUsesBossShockwave(
    EnemyKind kind, {
    bool stageEvent = false,
  }) {
    return stageEvent || kind == EnemyKind.bastionOverlord;
  }

  @visibleForTesting
  EnemyDefinition debugStageEventEnemyDefinition(StageEventDefinition event) {
    return _stageEventEnemyDefinition(event);
  }

  @visibleForTesting
  int debugCoinMillWaveStartBonus({required int level, String? branchId}) {
    return _coinMillWaveStartBonusFor(
      level: level,
      incomeBonus: metaUpgrades.coinMillIncomeBonus,
      branchId: branchId,
    );
  }

  @visibleForTesting
  double debugTowerDamageForLevel(TowerKind kind, int level) {
    return _towerDamageForLevel(TowerCatalog.byKind(kind), level);
  }

  @visibleForTesting
  double debugPhysicalDamageMultiplierForEnemyKind(
    EnemyKind kind, {
    bool stageEvent = false,
  }) {
    return _physicalDamageMultiplierForEnemyKind(kind, stageEvent: stageEvent);
  }

  @visibleForTesting
  bool debugEnemyKindCanDamageTowersOnContact(
    EnemyKind kind, {
    bool hasActiveBreachTarget = false,
  }) {
    final enemy = _Enemy.fromDefinition(
      EnemyDefinition(
        kind: kind,
        label: kind.name,
        specialDescription: '',
        hitPoints: 1,
        speed: 1,
        rewardCoins: 0,
        citadelDamage: 1,
        color: const Color(0xFFFFFFFF),
      ),
      spawnDirection: SpawnDirection.north,
    );
    if (hasActiveBreachTarget) {
      enemy.breachTargetCell = (0, 0);
    }
    return _shouldApplyEnemyTowerContactDamage(enemy);
  }

  @visibleForTesting
  int debugCitadelLeakDamageForEnemyKind(
    EnemyKind kind, {
    bool stageEvent = false,
  }) {
    final baseDamage = EnemyDefinition(
      kind: kind,
      label: kind.name,
      specialDescription: '',
      hitPoints: 1,
      speed: 1,
      rewardCoins: 0,
      citadelDamage: 1,
      color: const Color(0xFFFFFFFF),
    ).citadelLeakDamage;
    return stageEvent || kind == EnemyKind.bastionOverlord
        ? math.max(2, baseDamage)
        : baseDamage;
  }

  void _prepareBombardmentForWave(int waveNumber) {
    _bombardmentTimer = -1;
    _pendingBombardmentWaveNumber = null;
    final definition = stage.bombardment;
    final rollChance = definition?.rollChanceForWave(waveNumber);
    if (definition == null ||
        rollChance == null ||
        _bombardmentRolledWaveNumbers.contains(waveNumber) ||
        _bombardmentLaunchedWaveNumbers.contains(waveNumber)) {
      return;
    }

    _bombardmentRolledWaveNumbers.add(waveNumber);
    final random = math.Random(
      _runOfferSeed + (stage.number * 31091) + (waveNumber * 9173),
    );
    if (random.nextDouble() > rollChance) {
      return;
    }

    _bombardmentTimer = 2.4 + (random.nextDouble() * 2.2);
    _pendingBombardmentWaveNumber = waveNumber;
    _showStatus('적 포격 징후가 포착되었습니다. 성벽과 타워를 주의하세요.');
  }

  void _updateBombardments(double dt) {
    for (var index = _bombardments.length - 1; index >= 0; index -= 1) {
      final bombardment = _bombardments[index];
      bombardment.age += dt;
      if (bombardment.age < 0) {
        continue;
      }
      if (!bombardment.impacted &&
          bombardment.age >= bombardment.warningSeconds) {
        bombardment.impacted = true;
        _resolveBombardmentImpact(bombardment);
      }
      if (bombardment.age >= bombardment.lifetime) {
        _bombardments.removeAt(index);
      }
    }

    if (!_waveActive ||
        _bombardmentTimer < 0 ||
        _pendingBombardmentWaveNumber == null ||
        _bombardmentLaunchedWaveNumbers.contains(
          _pendingBombardmentWaveNumber,
        )) {
      return;
    }
    _bombardmentTimer -= dt;
    if (_bombardmentTimer > 0) {
      return;
    }
    _bombardmentTimer = -1;
    final waveNumber = _pendingBombardmentWaveNumber;
    _pendingBombardmentWaveNumber = null;
    if (waveNumber != null) {
      _launchStageBombardment(waveNumber);
    }
  }

  void _launchStageBombardment(int waveNumber) {
    final definition = stage.bombardment;
    if (definition == null ||
        _bombardmentLaunchedWaveNumbers.contains(waveNumber)) {
      return;
    }
    final targets = _selectBombardmentTargets(definition);
    if (targets.isEmpty) {
      return;
    }

    final random = math.Random(
      _runOfferSeed + (stage.number * 7117) + ((_currentWaveIndex + 1) * 1297),
    );
    final radius = definition.radiusTiles * _tileSize;
    for (var index = 0; index < targets.length; index += 1) {
      final target = targets[index];
      final fromSide = random.nextBool() ? -1.0 : 1.0;
      final from = Vector2(
        fromSide < 0 ? -_tileSize * 2.2 : size.x + (_tileSize * 2.2),
        (target.position.y - (size.y * 0.42) - (random.nextDouble() * 90))
            .clamp(-_tileSize * 2, size.y * 0.25)
            .toDouble(),
      );
      _bombardments.add(
        _BombardmentVisual(
          from: from,
          to: target.position.clone(),
          radius: radius,
          damage: definition.damage,
          warningSeconds: definition.projectileSeconds,
          lifetime: definition.projectileSeconds + 0.55,
          launchDelay: index * 0.3,
        ),
      );
      _spawnFloatingText(
        target.position + Vector2(0, -30),
        '포격!',
        const Color(0xFFFFB05F),
        lifetime: 0.95 + (index * 0.12),
      );
    }
    _bombardmentLaunchedWaveNumbers.add(waveNumber);
    _showStatus('적 포격! 성 외곽 가까운 방어선 3곳이 공격받습니다.');
    audioService.play(AudioEvent.baseDamage);
  }

  List<({Vector2 position, String label})> _selectBombardmentTargets(
    StageBombardmentDefinition definition,
  ) {
    final radius = definition.radiusTiles * _tileSize;
    final minSpacing = math.max(
      definition.minImpactSpacingTiles * _tileSize,
      radius * 2.15,
    );
    final candidates =
        <({Vector2 position, String label})>[
          for (final barrier in _barriers)
            (
              position: barrier.position.clone(),
              label: barrier.definition.label,
            ),
          for (final tower in _towers)
            (position: tower.position.clone(), label: tower.definition.label),
        ]..sort(
          (a, b) => a.position
              .distanceTo(_citadelCenter)
              .compareTo(b.position.distanceTo(_citadelCenter)),
        );

    final selected = <({Vector2 position, String label})>[];
    for (final candidate in candidates) {
      if (_overlapsSelectedBombardmentTarget(
        candidate.position,
        selected,
        minSpacing,
      )) {
        continue;
      }
      selected.add(candidate);
      if (selected.length >= definition.shellCount) {
        return selected;
      }
    }

    final fallbackDistance = minSpacing + (_tileSize * 0.45);
    final directions = <Vector2>[
      Vector2(1, 0),
      Vector2(0, -1),
      Vector2(0, 1),
      Vector2(-1, 0),
      Vector2(1, -1),
      Vector2(1, 1),
      Vector2(-1, -1),
      Vector2(-1, 1),
    ];
    for (final rawDirection in directions) {
      final direction = rawDirection.normalized();
      final position = _clampToBattlefield(
        _citadelCenter + (direction * fallbackDistance),
      );
      if (_overlapsSelectedBombardmentTarget(position, selected, minSpacing)) {
        continue;
      }
      selected.add((position: position, label: '외곽 지점'));
      if (selected.length >= definition.shellCount) {
        break;
      }
    }
    return selected;
  }

  bool _overlapsSelectedBombardmentTarget(
    Vector2 position,
    List<({Vector2 position, String label})> selected,
    double minSpacing,
  ) {
    for (final target in selected) {
      if (target.position.distanceTo(position) < minSpacing) {
        return true;
      }
    }
    return false;
  }

  Vector2 _clampToBattlefield(Vector2 position) {
    return Vector2(
      position.x.clamp(_tileSize * 0.5, size.x - (_tileSize * 0.5)).toDouble(),
      position.y.clamp(_tileSize * 0.5, size.y - (_tileSize * 0.5)).toDouble(),
    );
  }

  @visibleForTesting
  List<Vector2> debugBombardmentTargetsForCurrentState() {
    final definition = stage.bombardment;
    if (definition == null) {
      return const [];
    }
    return [
      for (final target in _selectBombardmentTargets(definition))
        target.position.clone(),
    ];
  }

  void _resolveBombardmentImpact(_BombardmentVisual bombardment) {
    final damage = bombardment.damage.toDouble();
    var removedBarrier = false;
    var removedTower = false;

    for (var index = _barriers.length - 1; index >= 0; index -= 1) {
      final barrier = _barriers[index];
      if (barrier.position.distanceTo(bombardment.to) > bombardment.radius) {
        continue;
      }
      barrier.hitPoints -= damage;
      _spawnFloatingText(
        barrier.position + Vector2(0, -18),
        '-${damage.round()}',
        const Color(0xFFFF8C64),
        lifetime: 0.58,
      );
      if (barrier.hitPoints > 0) {
        continue;
      }
      _barriers.removeAt(index);
      removedBarrier = true;
      if (_selectedBarrierIndex == index) {
        _selectedBarrierIndex = null;
      } else if (_selectedBarrierIndex != null &&
          _selectedBarrierIndex! > index) {
        _selectedBarrierIndex = _selectedBarrierIndex! - 1;
      }
    }

    for (var index = _towers.length - 1; index >= 0; index -= 1) {
      final tower = _towers[index];
      if (tower.position.distanceTo(bombardment.to) > bombardment.radius) {
        continue;
      }
      tower.hitPoints -= damage;
      _spawnFloatingText(
        tower.position + Vector2(0, -20),
        '-${damage.round()}',
        const Color(0xFFFF8C64),
        lifetime: 0.58,
      );
      if (tower.hitPoints > 0) {
        continue;
      }
      _towers.removeAt(index);
      removedTower = true;
      if (_selectedTowerIndex == index) {
        _selectedTowerIndex = null;
      } else if (_selectedTowerIndex != null && _selectedTowerIndex! > index) {
        _selectedTowerIndex = _selectedTowerIndex! - 1;
      }
    }

    if (removedBarrier) {
      _rerouteEnemies();
    }
    if (removedTower) {
      _maxTowerLevel = _towers.isEmpty
          ? 1
          : _towers.map((tower) => tower.level).reduce(math.max);
    }
    _spawnImpact(
      bombardment.to,
      const Color(0xFFFF7A4D),
      bombardment.radius * 0.9,
      0.42,
      effectId: EffectVisualCatalog.flameImpact,
    );
    _spawnPulse(
      center: bombardment.to,
      color: const Color(0xFFFFB05F),
      maxRadius: bombardment.radius,
      lifetime: 0.42,
      strokeWidth: 4,
    );
    audioService.play(AudioEvent.armorHit);
    _syncSelectedTower();
    _syncSelectedBarrier();
    _syncSession();
  }

  void _updateEnemies(double dt) {
    var playedBaseDamageSfx = false;
    for (var index = _enemies.length - 1; index >= 0; index -= 1) {
      final enemy = _enemies[index];
      if (enemy.hitPoints <= 0) {
        _logEnemyEvent('REMOVE_DEAD_CLEANUP', enemy);
        _consumeRemainingEnemy('dead_cleanup');
        _enemies.removeAt(index);
        continue;
      }
      if (!_isFiniteVector(enemy.position)) {
        _logEnemyEvent('REMOVE_INVALID_POSITION', enemy);
        _consumeRemainingEnemy('invalid_position');
        _enemies.removeAt(index);
        continue;
      }

      final towerAttackSlow = _tickEnemyCombatState(enemy, dt);
      if (enemy.hitPoints <= 0 || !_enemies.contains(enemy)) {
        continue;
      }
      if (towerAttackSlow > 0) {
        enemy.staggerTimer = math.max(enemy.staggerTimer, towerAttackSlow);
      }
      _logCitadelTouchIfBlocked(enemy);

      if (_shouldResolveEnemyLeak(enemy)) {
        if (!playedBaseDamageSfx) {
          playedBaseDamageSfx = true;
          audioService.play(AudioEvent.baseDamage);
        }
        _resolveEnemyLeakAt(index, enemy);
        continue;
      }

      if (_updateEnemyHeroBlockAttack(enemy, dt)) {
        continue;
      }

      if (enemy.breachTargetCell != null) {
        if (!_updateEnemyBreachAttack(enemy, dt)) {
          _logEnemyEvent('BREACH_TARGET_LOST_REPATH', enemy);
          _assignSiegePathForEnemy(enemy, preservePosition: true);
        }
        continue;
      }

      if (_shouldApplyEnemyTowerContactDamage(enemy)) {
        _applyEnemyTowerContactDamage(enemy);
      }

      final path = _pathForEnemy(enemy);
      if (path.length < 2) {
        if (!_updateEnemyBreachAttack(enemy, dt)) {
          _logEnemyEvent('REMOVE_INVALID_PATH', enemy);
          _consumeRemainingEnemy('invalid_path');
          _enemies.removeAt(index);
        }
        continue;
      }
      enemy.advance(path, dt, _citadelCenter);
      if (!_isFiniteVector(enemy.position)) {
        _logEnemyEvent('REMOVE_NON_FINITE_AFTER_ADVANCE', enemy);
        _consumeRemainingEnemy('non_finite_after_advance');
        _enemies.removeAt(index);
        continue;
      }
      _logCitadelTouchIfBlocked(enemy);
      if (!enemy.reachedGoal && _shouldResolveEnemyLeak(enemy)) {
        enemy.reachedGoal = true;
        enemy.progress = 1;
      }

      if (enemy.reachedGoal) {
        if (!playedBaseDamageSfx) {
          playedBaseDamageSfx = true;
          audioService.play(AudioEvent.baseDamage);
        }
        _resolveEnemyLeakAt(index, enemy);
      }
    }
  }

  double _tickEnemyCombatState(_Enemy enemy, double dt) {
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
      _recordEnemyDamage(
        enemy,
        burnDamage,
        const Color(0xFFFFA04D),
        showNumber: burnDamage >= 2,
      );
      if (_resolveEnemyDefeatIfNeeded(enemy)) {
        return 0;
      }
    }

    _applyEnemyAbility(enemy, dt);
    final heroAttackSlow = _applyEnemyHeroAttack(enemy);
    if (heroAttackSlow > 0) {
      return heroAttackSlow;
    }
    return 0;
  }

  bool _shouldApplyEnemyTowerContactDamage(_Enemy enemy) {
    return _canEnemyDamageTowersOnContact(enemy) &&
        enemy.breachTargetCell == null;
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

  double _applyEnemyTowerContactDamage(_Enemy enemy) {
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
        enemy.definition.baseTowerContactDamage *
        _towerProtectionMultiplier(tower.position);
    final hitPointsBefore = tower.hitPoints;
    tower.hitPoints -= damage;
    _logEnemyEvent(
      'HIT_TOWER_PASS_THROUGH',
      enemy,
      'tower=${tower.definition.kind.name} towerIndex=$targetIndex '
          'damage=${damage.toStringAsFixed(1)} '
          'towerHp=${hitPointsBefore.toStringAsFixed(1)}->${tower.hitPoints.toStringAsFixed(1)}',
    );
    _spawnFloatingText(
      tower.position + Vector2(0, -22),
      '-${damage.round()}',
      const Color(0xFFFF8A65),
      lifetime: 0.48,
    );
    enemy.towerAttackCooldown = 1.1;
    _spawnImpact(tower.position, const Color(0xAAFF6A4C), 14, 0.14);
    audioService.play(AudioEvent.armorHit);

    if (tower.hitPoints <= 0) {
      _logEnemyEvent(
        'DESTROY_TOWER',
        enemy,
        'tower=${tower.definition.kind.name} towerIndex=$targetIndex',
      );
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

    return 0;
  }

  double _applyEnemyHeroAttack(_Enemy enemy) {
    if (enemy.towerAttackCooldown > 0 || _heroes.isEmpty) {
      return 0;
    }

    var targetIndex = -1;
    var bestDistance = _tileSize * 0.82;
    for (var i = 0; i < _heroes.length; i += 1) {
      final distance = _heroes[i].position.distanceTo(enemy.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        targetIndex = i;
      }
    }
    if (targetIndex < 0) {
      return 0;
    }

    final hero = _heroes[targetIndex];
    final damage = _enemyHeroContactDamage(enemy);
    final hitPointsBefore = hero.hitPoints;
    hero.hitPoints -= damage;
    _logEnemyEvent(
      'HIT_HERO',
      enemy,
      'hero=${hero.definition.kind.name} heroIndex=$targetIndex '
          'damage=${damage.toStringAsFixed(1)} '
          'heroHp=${hitPointsBefore.toStringAsFixed(1)}->${hero.hitPoints.toStringAsFixed(1)}',
    );
    enemy.towerAttackCooldown = 1.0;
    enemy.towerAttackVisualTimer = _enemyAttackVisualDuration(enemy);
    _setEnemyAttackDirection(enemy, hero.position);
    _spawnStrike(
      from: enemy.position,
      to: hero.position,
      color: const Color(0xAAFF6A4C),
      lifetime: 0.16,
    );
    _spawnImpact(hero.position, const Color(0xAAFF6A4C), 18, 0.16);
    _spawnBossShockwaveVisual(enemy, hero.position);
    audioService.play(AudioEvent.armorHit);
    if (hero.hitPoints <= 0) {
      _logEnemyEvent(
        'DEFEAT_HERO',
        enemy,
        'hero=${hero.definition.kind.name} heroIndex=$targetIndex',
      );
      _spawnImpact(hero.position, const Color(0xAA77A7FF), 30, 0.24);
      _heroes.removeAt(targetIndex);
      if (_selectedHeroIndex == targetIndex) {
        _clearSelectedHeroSelection();
      } else if (_selectedHeroIndex != null &&
          _selectedHeroIndex! > targetIndex) {
        _selectedHeroIndex = _selectedHeroIndex! - 1;
      }
      _showStatus(
        _heroReviveUsed
            ? '영웅이 쓰러졌습니다. 이번 STAGE에서는 더 부활할 수 없습니다.'
            : '영웅이 쓰러졌습니다. 영웅 탭에서 한 번 무료 부활할 수 있습니다.',
      );
      sessionController.setHeroSummonState(
        summoned: true,
        available: !_heroReviveUsed,
      );
      _syncHeroStatus();
    }
    return 0.10;
  }

  int? _heroIndexBlockingEnemy(_Enemy enemy) {
    if (_heroes.isEmpty) {
      return null;
    }
    final path = _pathForEnemy(enemy);
    if (path.length < 2) {
      return null;
    }
    final enemyProjection = _nearestPathProjection(enemy.position, path);
    var bestIndex = -1;
    var bestScore = double.infinity;

    for (var i = 0; i < _heroes.length; i += 1) {
      final hero = _heroes[i];
      if (hero.hitPoints <= 0) {
        continue;
      }
      final heroProjection = _nearestPathProjection(hero.position, path);
      if (heroProjection.distance > _tileSize * 0.46) {
        continue;
      }
      final progressDelta = heroProjection.progress - enemyProjection.progress;
      if (progressDelta < -_tileSize * 0.18 ||
          progressDelta > _tileSize * 1.20) {
        continue;
      }
      final heroDistance = hero.position.distanceTo(enemy.position);
      if (heroDistance <= 0 || heroDistance > _tileSize * 1.10) {
        continue;
      }
      final score =
          progressDelta.abs() + (heroProjection.distance * 2.0) + heroDistance;
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    return bestIndex < 0 ? null : bestIndex;
  }

  ({double distance, double progress}) _nearestPathProjection(
    Vector2 point,
    List<Vector2> path,
  ) {
    var bestDistance = double.infinity;
    var bestProgress = 0.0;
    var traversed = 0.0;

    for (var i = 0; i < path.length - 1; i += 1) {
      final start = path[i];
      final end = path[i + 1];
      final segment = end - start;
      final lengthSquared = segment.dot(segment);
      if (lengthSquared <= 0) {
        continue;
      }
      final segmentLength = math.sqrt(lengthSquared);
      final toPoint = point - start;
      final t = (toPoint.dot(segment) / lengthSquared).clamp(0.0, 1.0);
      final closest = start + (segment * t);
      final distance = point.distanceTo(closest);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestProgress = traversed + (segmentLength * t);
      }
      traversed += segmentLength;
    }

    return (distance: bestDistance, progress: bestProgress);
  }

  bool _updateEnemyHeroBlockAttack(_Enemy enemy, double _) {
    final targetIndex = _heroIndexBlockingEnemy(enemy);
    if (targetIndex == null) {
      return false;
    }
    final hero = _heroes[targetIndex];
    final distance = hero.position.distanceTo(enemy.position);
    final attackRange = _tileSize * 0.72;
    if (distance > attackRange) {
      return false;
    }

    if (enemy.towerAttackCooldown > 0) {
      return true;
    }

    final damage = _enemyHeroContactDamage(enemy);
    final hitPointsBefore = hero.hitPoints;
    hero.hitPoints -= damage;
    _logEnemyEvent(
      'HIT_HERO_BLOCKER',
      enemy,
      'hero=${hero.definition.kind.name} heroIndex=$targetIndex '
          'damage=${damage.toStringAsFixed(1)} '
          'heroHp=${hitPointsBefore.toStringAsFixed(1)}->${hero.hitPoints.toStringAsFixed(1)}',
    );
    _spawnFloatingText(
      hero.position + Vector2(0, -22),
      '-${damage.round()}',
      const Color(0xFF77A7FF),
      lifetime: 0.48,
    );
    enemy.towerAttackCooldown = 1.0;
    enemy.towerAttackVisualTimer = _enemyAttackVisualDuration(enemy);
    _setEnemyAttackDirection(enemy, hero.position);
    _spawnStrike(
      from: enemy.position,
      to: hero.position,
      color: const Color(0xAA77A7FF),
      lifetime: 0.16,
    );
    _spawnImpact(hero.position, const Color(0xAA77A7FF), 20, 0.18);
    _spawnBossShockwaveVisual(enemy, hero.position);
    audioService.play(AudioEvent.armorHit);

    if (hero.hitPoints <= 0) {
      _logEnemyEvent(
        'DEFEAT_HERO_BLOCKER',
        enemy,
        'hero=${hero.definition.kind.name} heroIndex=$targetIndex',
      );
      _spawnImpact(hero.position, const Color(0xAA77A7FF), 30, 0.24);
      _heroes.removeAt(targetIndex);
      if (_selectedHeroIndex == targetIndex) {
        _clearSelectedHeroSelection();
      } else if (_selectedHeroIndex != null &&
          _selectedHeroIndex! > targetIndex) {
        _selectedHeroIndex = _selectedHeroIndex! - 1;
      }
      _showStatus(
        _heroReviveUsed
            ? '?곸썒???곕윭議뚯뒿?덈떎. ?대쾲 STAGE?먯꽌????遺?쒗븷 ???놁뒿?덈떎.'
            : '?곸썒???곕윭議뚯뒿?덈떎. ?곸썒 ??뿉????踰?臾대즺 遺?쒗븷 ???덉뒿?덈떎.',
      );
      sessionController.setHeroSummonState(
        summoned: true,
        available: !_heroReviveUsed,
      );
      _syncHeroStatus();
    }

    return true;
  }

  bool _updateEnemyBreachAttack(_Enemy enemy, double dt) {
    if (!enemy.definition.canBreachWalls || _barriers.isEmpty) {
      return false;
    }
    var targetIndex = -1;
    var bestDistance = double.infinity;

    final breachCell = enemy.breachTargetCell;
    if (breachCell != null) {
      targetIndex = _barrierIndexAtCell(breachCell.$1, breachCell.$2) ?? -1;
      if (targetIndex >= 0) {
        bestDistance = _barriers[targetIndex].position.distanceTo(
          enemy.position,
        );
      } else {
        _logEnemyEvent(
          'BARRIER_TARGET_MISSING',
          enemy,
          'breachCell=${_formatCell(breachCell)}',
        );
        enemy.breachTargetCell = null;
        return false;
      }
    } else {
      if (_isSiegeMode) {
        return false;
      }
      for (var i = 0; i < _barriers.length; i += 1) {
        final distance = _barriers[i].position.distanceTo(enemy.position);
        if (distance < bestDistance) {
          bestDistance = distance;
          targetIndex = i;
        }
      }
    }

    if (targetIndex < 0) {
      return false;
    }

    final target = _barriers[targetIndex];
    final attackRange = _tileSize * 0.72;
    if (bestDistance > attackRange) {
      final path = _pathForEnemy(enemy);
      if (path.length >= 2 && enemy.segmentIndex < path.length - 1) {
        enemy.reachedGoal = false;
        enemy.advance(path, dt, _citadelCenter);
        enemy.reachedGoal = false;
        return true;
      }

      final direction = target.position - enemy.position;
      final length = direction.length;
      if (length > 0) {
        direction.scale(1 / length);
        enemy.position.addScaled(
          direction,
          enemy.definition.speed * _enemyMoveSpeedMultiplier * dt * 0.72,
        );
        enemy.currentDirection = _directionFromDelta(direction);
        enemy.distanceToCitadel = enemy.position.distanceTo(_citadelCenter);
      }
      return true;
    }

    if (enemy.towerAttackCooldown > 0) {
      return true;
    }
    final targetPosition = target.position.clone();
    final damage = enemy.definition.baseStructureDamage;
    final hitPointsBefore = target.hitPoints;
    target.hitPoints -= damage;
    _logEnemyEvent(
      'HIT_BARRIER',
      enemy,
      'barrier=${target.definition.kind.name} barrierIndex=$targetIndex '
          'barrierCell=${_formatCell(_cellForWorldPosition(target.position))} '
          'damage=${damage.toStringAsFixed(1)} '
          'barrierHp=${hitPointsBefore.toStringAsFixed(1)}->${target.hitPoints.toStringAsFixed(1)}',
    );
    _spawnFloatingText(
      target.position + Vector2(0, -20),
      '-${damage.round()}',
      const Color(0xFFE4C67A),
      lifetime: 0.48,
    );
    enemy.towerAttackCooldown = enemy.definition.structureAttackCooldown;
    enemy.towerAttackVisualTimer = _enemyAttackVisualDuration(enemy);
    _setEnemyAttackDirection(enemy, target.position);
    _spawnStrike(
      from: enemy.position,
      to: target.position,
      color: const Color(0xAAFFB15A),
      lifetime: 0.17,
      strokeWidth: 3.4,
    );
    _spawnImpact(target.position, const Color(0xAAFFB15A), 20, 0.18);
    audioService.play(AudioEvent.armorHit);
    if (_selectedBarrierIndex == targetIndex) {
      _syncSelectedBarrier();
    }
    if (target.hitPoints <= 0) {
      _spawnImpact(target.position, const Color(0xAAE4C67A), 34, 0.24);
      final destroyedCell = enemy.breachTargetCell;
      _logEnemyEvent(
        'DESTROY_BARRIER',
        enemy,
        'barrier=${target.definition.kind.name} barrierIndex=$targetIndex '
            'destroyedCell=${_formatCell(destroyedCell)}',
      );
      _barriers.removeAt(targetIndex);
      for (final other in _enemies) {
        if (other.breachTargetCell == destroyedCell) {
          other.breachTargetCell = null;
        }
      }
      if (_selectedBarrierIndex == targetIndex) {
        _clearSelectedBarrierSelection();
      } else if (_selectedBarrierIndex != null &&
          _selectedBarrierIndex! > targetIndex) {
        _selectedBarrierIndex = _selectedBarrierIndex! - 1;
        _syncSelectedBarrier();
      }
      _showStatus('성벽이 파괴되었습니다. 다음 회복 시간에 다시 지으세요.');
      _rerouteEnemies();
    }
    _applyBossShockwave(
      enemy,
      center: targetPosition,
      damage: damage.toDouble(),
      primaryPosition: targetPosition,
    );
    return true;
  }

  void _setEnemyAttackDirection(_Enemy enemy, Vector2 target) {
    final direction = target - enemy.position;
    if (direction.length2 <= 0.0001) {
      return;
    }
    direction.normalize();
    enemy.attackDirection.setFrom(direction);
    enemy.currentDirection = _directionFromDelta(direction);
  }

  double _towerProtectionMultiplier(Vector2 towerPosition) {
    var multiplier = 1.0;
    for (final hero in _heroes) {
      if (hero.definition.kind != HeroKind.knight) {
        continue;
      }
      if (hero.position.distanceTo(towerPosition) > _heroCurrentRange(hero)) {
        continue;
      }
      final aura = 0.82 - (metaUpgrades.guardDrillLevel * 0.015);
      multiplier = math.min(multiplier, aura.clamp(0.72, 0.82));
    }
    return multiplier;
  }

  double _enemyHeroContactDamage(_Enemy enemy) {
    final multiplier = switch (stage.number) {
      <= 5 => 0.70,
      <= 10 => 0.78,
      <= 15 => 0.84,
      <= 20 => 0.90,
      <= 25 => 0.95,
      _ => 1.0,
    };
    return math.max(
      5.0 * multiplier,
      enemy.currentBaseDamage * 6.0 * multiplier,
    );
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
    final target = _pickTarget(tower.position, _towerCurrentRange(tower));
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
    tower.shotCounter += 1;
    var damage =
        _towerCurrentDamage(tower) * metaUpgrades.archerDamageMultiplier;
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
      effectId: EffectVisualCatalog.arrowProjectile,
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
          effectId: EffectVisualCatalog.arrowProjectile,
        );
      }
    }

    audioService.play(tower.definition.attackEvent);
  }

  void _fireBarracksTower(_TowerPlacement tower) {
    final target = _pickTarget(tower.position, _towerCurrentRange(tower));
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
    final damage =
        _towerCurrentDamage(tower) * metaUpgrades.barracksDamageMultiplier;
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
    final target = _pickTarget(tower.position, _towerCurrentRange(tower));
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
    final baseDamage =
        _towerCurrentDamage(tower) * metaUpgrades.mageDamageMultiplier;
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
    _spawnImpact(
      target.position,
      tower.definition.color,
      22,
      0.20,
      effectId: EffectVisualCatalog.arcaneBoltProjectile,
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
              tower.position.distanceTo(enemy.position) <=
              _towerCurrentRange(tower),
        )
        .toList();
    if (enemiesInRange.isEmpty) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
    _spawnPulse(
      center: tower.position,
      color: tower.definition.color,
      maxRadius: _towerCurrentRange(tower) * 0.82,
      lifetime: 0.34,
      strokeWidth: 3,
    );
    _spawnImpact(
      tower.position,
      tower.definition.color,
      24,
      0.24,
      effectId: EffectVisualCatalog.frostImpact,
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
            _towerCurrentDamage(tower) *
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
    final target = _pickBallistaTarget(
      tower.position,
      _towerCurrentRange(tower),
    );
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
    final damage =
        _towerCurrentDamage(tower) * metaUpgrades.archerDamageMultiplier;

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
      effectId: EffectVisualCatalog.siegeBoltProjectile,
    );
    _spawnImpact(
      target.position,
      tower.definition.color,
      32,
      0.24,
      effectId: EffectVisualCatalog.siegeBoltProjectile,
    );

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
    final target = _pickClusterTarget(
      tower.position,
      _towerCurrentRange(tower),
    );
    if (target == null) {
      return;
    }

    tower.cooldownRemaining = _towerCurrentCooldown(tower);
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
        damage: _towerCurrentDamage(tower) * (isPrimaryTarget ? 1.0 : 0.7),
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
    _spawnImpact(
      target.position,
      tower.definition.color,
      28,
      0.28,
      effectId: EffectVisualCatalog.flameImpact,
    );
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
    _recordEnemyDamage(
      target,
      adjustedDamage,
      damageType == _DamageType.magic
          ? tower.definition.color
          : const Color(0xFFFFF1CC),
    );
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

    if (damageType == _DamageType.physical) {
      adjusted *= _physicalDamageMultiplierForEnemyKind(
        target.definition.kind,
        stageEvent: target.stageEventLabel != null,
      );
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

  double _physicalDamageMultiplierForEnemyKind(
    EnemyKind kind, {
    required bool stageEvent,
  }) {
    if (stageEvent) {
      return _stageEventBossPhysicalDamageMultiplier;
    }
    return switch (kind) {
      EnemyKind.shieldInfantry ||
      EnemyKind.corruptedKnight ||
      EnemyKind.bastionOverlord => 0.55,
      _ => 1.0,
    };
  }

  bool _resolveEnemyDefeatIfNeeded(_Enemy target) {
    if (target.hitPoints > 0) {
      return false;
    }

    if (target.definition.kind == EnemyKind.skeleton && !target.reviveUsed) {
      target.reviveUsed = true;
      target.hitPoints = target.definition.hitPoints * 0.4;
      target.staggerTimer = 0.4;
      _logEnemyEvent(
        'REVIVE_SKELETON',
        target,
        'revivedHp=${target.hitPoints.toStringAsFixed(1)}',
      );
      _spawnImpact(target.position, const Color(0xFFDDD7C2), 26, 0.35);
      return false;
    }

    if (target.definition.kind == EnemyKind.boneArcher &&
        !target.deathSpawnUsed) {
      target.deathSpawnUsed = true;
      _logEnemyEvent('DEATH_SPAWN_TRIGGER', target, 'summon=skeleton');
      _spawnSummonedEnemy(summoner: target, kind: EnemyKind.skeleton);
    }

    _logEnemyEvent(
      'DEFEAT_ENEMY',
      target,
      'reward=${target.definition.rewardCoins} coinsBefore=$_coins',
    );
    _coins += target.definition.rewardCoins;
    _spawnFloatingText(
      target.position + Vector2(0, -16),
      '+${target.definition.rewardCoins}',
      const Color(0xFFE4C67A),
    );
    if (target.definition.kind == EnemyKind.corruptedKnight ||
        target.definition.kind == EnemyKind.graveGuard ||
        target.definition.kind == EnemyKind.warlock ||
        target.definition.kind == EnemyKind.bastionPriest ||
        target.definition.kind == EnemyKind.bastionOverlord) {
      audioService.play(AudioEvent.enemyDeathElite);
    } else {
      audioService.play(AudioEvent.coinGain);
    }
    _consumeRemainingEnemy('defeat');
    _enemies.remove(target);
    _spawnImpact(target.position, const Color(0x88FFD27A), 22, 0.24);
    _spawnImpact(target.position, const Color(0x66FFFFFF), 14, 0.18);
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
      final isStageEventBoss = enemy.stageEventLabel != null;
      enemy.bossPulseTimer -= dt;

      if (!enemy.bossPhaseOneTriggered &&
          enemy.hitPoints <= enemy.definition.hitPoints * 0.72) {
        enemy.bossPhaseOneTriggered = true;
        enemy.wardCharges = isStageEventBoss ? 1 : 2;
        enemy.wardVisualTimer = isStageEventBoss ? 4.5 : 6.0;
        enemy.wardFlashTimer = 0.35;
        enemy.bossAuraVisualTimer = 1.1;
        enemy.hasteMultiplier = math.max(
          enemy.hasteMultiplier,
          isStageEventBoss ? 1.06 : 1.12,
        );
        enemy.hasteTimer = 99;
        _spawnBossEscort(enemy, EnemyKind.graveGuard);
        if (!isStageEventBoss) {
          _spawnBossEscort(enemy, EnemyKind.warlock);
        }
      }

      if (!enemy.bossPhaseTwoTriggered &&
          enemy.hitPoints <= enemy.definition.hitPoints * 0.36) {
        enemy.bossPhaseTwoTriggered = true;
        enemy.wardCharges = isStageEventBoss ? 1 : 3;
        enemy.wardVisualTimer = isStageEventBoss ? 4.8 : 7.5;
        enemy.wardFlashTimer = 0.45;
        enemy.bossAuraVisualTimer = 1.4;
        enemy.hasteMultiplier = math.max(
          enemy.hasteMultiplier,
          isStageEventBoss ? 1.12 : 1.24,
        );
        enemy.hasteTimer = 99;
        enemy.bonusBaseDamage = isStageEventBoss ? 1 : 2;
        _spawnBossEscort(enemy, EnemyKind.corruptedKnight);
        if (!isStageEventBoss) {
          _spawnBossEscort(enemy, EnemyKind.graveGuard);
        }
      }

      if (enemy.bossPulseTimer <= 0) {
        enemy.bossPulseTimer = enemy.bossPhaseTwoTriggered
            ? (isStageEventBoss ? 5.0 : 4.0)
            : (isStageEventBoss ? 6.0 : 5.6);
        enemy.bossAuraVisualTimer = 0.95;
        enemy.wardCharges = math.max(
          enemy.wardCharges,
          isStageEventBoss
              ? 1
              : enemy.bossPhaseTwoTriggered
              ? 2
              : 1,
        );
        enemy.wardVisualTimer = math.max(
          enemy.wardVisualTimer,
          isStageEventBoss ? 2.8 : 3.6,
        );
        _spawnPulse(
          center: enemy.position,
          color: const Color(0xFFB85749),
          maxRadius: enemy.bossPhaseTwoTriggered
              ? (isStageEventBoss ? 82 : 94)
              : 72,
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
      routeId: summoner.routeId,
    );
    enemy.debugId = _nextEnemyDebugId++;
    final summonPath = _pathForEnemy(summoner);
    enemy.customPath = summonPath;
    enemy.breachTargetCell = summoner.breachTargetCell;
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
    _logEnemyEvent(
      'SPAWN_SUMMONED',
      enemy,
      'summoner=#${summoner.debugId}:${summoner.definition.kind.name} '
          'remainingIncrementedTo=$_remainingEnemiesInCycle',
    );
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
      final route = enemy.routeId == null
          ? null
          : stage.spawnRoutes
                .where((entry) => entry.id == enemy.routeId)
                .cast<SpawnRouteDefinition?>()
                .firstWhere((entry) => entry != null, orElse: () => null);
      final entryCell =
          route?.entryCell ??
          _middleEntryForDirectionRuntime(enemy.spawnDirection);
      enemy.position.setFrom(
        _edgeAnchorForFront(enemy.spawnDirection, entryCell),
      );
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
    for (var index = _slashes.length - 1; index >= 0; index -= 1) {
      final slash = _slashes[index];
      slash.age += dt;
      if (slash.age >= slash.lifetime) {
        _slashes.removeAt(index);
      }
    }
    for (var index = _strikes.length - 1; index >= 0; index -= 1) {
      final strike = _strikes[index];
      strike.age += dt;
      if (strike.age >= strike.lifetime) {
        _strikes.removeAt(index);
      }
    }
    for (var index = _floatingTexts.length - 1; index >= 0; index -= 1) {
      final text = _floatingTexts[index];
      text.age += dt;
      if (text.age >= text.lifetime) {
        _floatingTexts.removeAt(index);
      }
    }
  }

  void _checkWaveResolution() {
    if (!_waveActive || _currentWaveIndex < 0) {
      return;
    }

    final wave = _waveForIndex(_currentWaveIndex);
    final finishedSpawning = _currentSpawnGroupIndex >= wave.groups.length;
    if (!finishedSpawning) {
      return;
    }
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
          ? 'Stage clear! 모든 공세를 막아냈습니다.'
          : 'STAGE 클리어! 다음 전장으로 진격하세요.';
      audioService.play(AudioEvent.stageClear);
      _syncSession();
      _sessionDirty = false;
      _flushSession();
      return;
    }

    if (_isSiegeMode) {
      final finishedCycle = _assaultCycleForIndex(_currentWaveIndex);
      _recoveryActive = true;
      _recoveryTimer = finishedCycle?.recoverySeconds ?? 30;
      _activeFronts = const [];
      _nextFronts = _nextFrontsForIndex(_currentWaveIndex);
      final recoveryPayout = finishedCycle?.recoveryGoldBonus ?? 0;
      if (recoveryPayout > 0) {
        _coins += recoveryPayout;
        _spawnFloatingText(
          _citadelCenter + Vector2(0, -42),
          '+$recoveryPayout',
          const Color(0xFFE4C67A),
          lifetime: 0.85,
        );
        audioService.play(AudioEvent.coinGain);
      }
      _statusText =
          'WAVE ${_currentWaveIndex + 1} 방어 성공! 다음 WAVE: ${_threatPreviewForIndex(_currentWaveIndex + 1)}';
    } else {
      _statusText =
          'WAVE ${_currentWaveIndex + 1} 방어 성공! 다음 WAVE: ${_threatPreviewForIndex(_currentWaveIndex + 1)}';
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
          entry.key: _vectorPathFromCells(entry.value, direction: entry.key),
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

  String? _routeIdForSpawn(
    SpawnDirection direction,
    int waveIndex,
    int spawnedInGroup,
  ) {
    final activeRouteIds = _assaultCycleForIndex(waveIndex)?.activeRouteIds;
    final routes = stage.spawnRoutes
        .where((route) {
          if (route.direction != direction) {
            return false;
          }
          return activeRouteIds == null ||
              activeRouteIds.isEmpty ||
              activeRouteIds.contains(route.id);
        })
        .toList(growable: false);
    if (routes.isEmpty) {
      return null;
    }
    final unlockedCount = _activeRouteCountForStage().clamp(1, routes.length);
    final availableRoutes = routes.take(unlockedCount).toList(growable: false);
    final index = (waveIndex + spawnedInGroup) % availableRoutes.length;
    return availableRoutes[index].id;
  }

  List<int> _middleEntryForDirectionRuntime(SpawnDirection direction) {
    return switch (direction) {
      SpawnDirection.north => const [6, 0],
      SpawnDirection.south => const [6, 13],
      SpawnDirection.west => const [0, 6],
      SpawnDirection.east => const [13, 6],
    };
  }

  int _activeRouteCountForStage() {
    return 3;
  }

  List<Vector2> _pathForEnemy(_Enemy enemy) {
    if (enemy.customPath != null) return enemy.customPath!;
    return _pathsByDirection[enemy.spawnDirection] ?? _pathPoints;
  }

  void _assignSiegePathForEnemy(_Enemy enemy, {bool preservePosition = false}) {
    enemy.breachTargetCell = null;
    final routeBarrierCell = _firstBarrierCellOnAssignedRoute(
      enemy.spawnDirection,
      routeId: enemy.routeId,
      afterPosition: preservePosition ? enemy.position : null,
    );
    if (routeBarrierCell != null) {
      _logEnemyEvent(
        'TARGET_BARRIER',
        enemy,
        'source=route '
            'cell=${_formatCell(routeBarrierCell)} preserve=$preservePosition '
            'wallBehavior=${enemy.definition.wallBehavior.name}',
      );
      _assignBreachPathForEnemy(
        enemy,
        routeBarrierCell,
        preservePosition: preservePosition,
      );
      return;
    }

    final path = _spawnPathForDirection(
      enemy.spawnDirection,
      routeId: enemy.routeId,
    );
    enemy.customPath = preservePosition && path.length >= 2
        ? _pathFromCurrentPosition(enemy.position, path)
        : path;
    enemy.segmentIndex = 0;
    enemy.segmentProgress = 0;
    enemy.reachedGoal = false;
    _logEnemyEvent(
      'PATH_TO_CITADEL',
      enemy,
      'preserve=$preservePosition pathPoints=${path.length} '
          'wallBehavior=${enemy.definition.wallBehavior.name}',
    );
  }

  void _assignBreachPathForEnemy(
    _Enemy enemy,
    (int, int) barrierCell, {
    required bool preservePosition,
  }) {
    enemy.breachTargetCell = barrierCell;
    final approachPath = _approachPathToBarrierCell(
      enemy.spawnDirection,
      barrierCell,
      routeId: enemy.routeId,
    );
    enemy.customPath = preservePosition && approachPath.length >= 2
        ? _pathFromCurrentPosition(enemy.position, approachPath)
        : approachPath;
    enemy.segmentIndex = 0;
    enemy.segmentProgress = 0;
    enemy.reachedGoal = false;
  }

  List<Vector2> _pathFromCurrentPosition(
    Vector2 currentPosition,
    List<Vector2> path,
  ) {
    var nearestIndex = 1;
    var nearestDistance = double.infinity;
    for (var i = 1; i < path.length; i += 1) {
      final distance = currentPosition.distanceTo(path[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
    return [
      currentPosition.clone(),
      for (var i = nearestIndex; i < path.length; i += 1) path[i],
    ];
  }

  SpawnDirection _directionFromDelta(Vector2 delta) {
    if (delta.x.abs() > delta.y.abs()) {
      return delta.x >= 0 ? SpawnDirection.east : SpawnDirection.west;
    }
    return delta.y >= 0 ? SpawnDirection.south : SpawnDirection.north;
  }

  List<Vector2> _spawnPathForDirection(SpawnDirection dir, {String? routeId}) {
    final authoredCells = _authoredRouteCellsForDirection(
      dir,
      routeId: routeId,
    );
    if (authoredCells.isNotEmpty) {
      // Keep live spawns aligned to the visible authored road. Re-solving this
      // as a free-grid shortest path makes enemies look like they ignore lanes.
      return _vectorPathFromCells(
        authoredCells,
        direction: dir,
        randomizeEdgeAnchor: false,
        appendCitadelCenter: false,
      );
    }
    if (_barriers.isNotEmpty) {
      return const [];
    }
    final authoredPath = _pathsByDirection[dir];
    if (authoredPath != null && authoredPath.length >= 2) {
      return authoredPath;
    }
    return _randomEdgePathToCitadel(dir);
  }

  (int, int)? _firstBarrierCellOnAssignedRoute(
    SpawnDirection dir, {
    String? routeId,
    Vector2? afterPosition,
  }) {
    final routeCells = _authoredRouteCellsForDirection(dir, routeId: routeId);
    var startIndex = 0;
    if (afterPosition != null && routeCells.isNotEmpty) {
      var nearestIndex = 0;
      var nearestDistance = double.infinity;
      for (var i = 0; i < routeCells.length; i += 1) {
        final distance = _cellCenter(routeCells[i]).distanceTo(afterPosition);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = i;
        }
      }
      startIndex = nearestIndex;
    }

    for (var i = startIndex; i < routeCells.length; i += 1) {
      final cell = routeCells[i];
      if (_barrierIndexAtCell(cell[0], cell[1]) != null) {
        return (cell[0], cell[1]);
      }
    }
    return null;
  }

  List<Vector2> _approachPathToBarrierCell(
    SpawnDirection dir,
    (int, int) barrierCell, {
    String? routeId,
  }) {
    final routeCells = _authoredRouteCellsForDirection(dir, routeId: routeId);
    if (routeCells.isEmpty) {
      return const [];
    }

    final cells = <List<int>>[];
    for (final cell in routeCells) {
      cells.add(cell);
      if (cell[0] == barrierCell.$1 && cell[1] == barrierCell.$2) {
        break;
      }
    }
    if (cells.isEmpty) {
      cells.add(routeCells.first);
    }
    return _vectorPathFromCells(
      cells,
      direction: dir,
      randomizeEdgeAnchor: false,
      appendCitadelCenter: false,
    );
  }

  List<List<int>> _authoredRouteCellsForDirection(
    SpawnDirection dir, {
    String? routeId,
  }) {
    final routeEntry = _spawnRouteById(routeId);
    if (routeEntry != null) {
      return _routeCellsForSpawnRoute(routeEntry);
    }
    return stage.pathsByDirection?[dir] ?? const [];
  }

  @visibleForTesting
  List<Vector2> debugSpawnPathForRoute(SpawnRouteDefinition route) {
    return _vectorPathFromCells(
      _routeCellsForSpawnRoute(route),
      direction: route.direction,
      randomizeEdgeAnchor: false,
      appendCitadelCenter: false,
    );
  }

  @visibleForTesting
  List<Vector2> debugBarrierApproachPathForRoute(
    SpawnRouteDefinition route,
    List<int> barrierCell,
  ) {
    return _approachPathToBarrierCell(route.direction, (
      barrierCell[0],
      barrierCell[1],
    ), routeId: route.id);
  }

  @visibleForTesting
  ({String? routeId, Vector2 position, Vector2 expectedPosition})
  debugSummonedEnemyPlacementForRoute(SpawnRouteDefinition route) {
    final definition = CampaignData.enemyForKind(
      EnemyKind.boneArcher,
      stageNumber: stage.number,
      intensity: 1,
    );
    final summoner = _Enemy.fromDefinition(
      definition,
      spawnDirection: route.direction,
      routeId: route.id,
    );
    summoner.customPath = debugSpawnPathForRoute(route);
    summoner.segmentIndex = math.max(0, summoner.customPath!.length - 3);
    summoner.segmentProgress = 0.5;
    _placeEnemyOnPath(summoner);

    final beforeCount = _enemies.length;
    _spawnSummonedEnemy(summoner: summoner, kind: EnemyKind.skeleton);
    final spawned = _enemies.removeLast();
    _remainingEnemiesInCycle = math.max(0, _remainingEnemiesInCycle - 1);
    assert(_enemies.length == beforeCount);

    final spawnedPath = _pathForEnemy(spawned);
    final expectedSegmentIndex = spawned.segmentIndex
        .clamp(0, math.max(0, spawnedPath.length - 2))
        .toInt();
    final expectedStart = spawnedPath[expectedSegmentIndex];
    final expectedEnd = spawnedPath[expectedSegmentIndex + 1];
    final expectedPosition =
        expectedStart +
        ((expectedEnd - expectedStart) * spawned.segmentProgress);

    return (
      routeId: spawned.routeId,
      position: spawned.position.clone(),
      expectedPosition: expectedPosition,
    );
  }

  @visibleForTesting
  Vector2 debugCitadelCenter() => _citadelCenter.clone();

  SpawnRouteDefinition? _spawnRouteById(String? routeId) {
    if (routeId == null) {
      return null;
    }
    for (final route in stage.spawnRoutes) {
      if (route.id == routeId) {
        return route;
      }
    }
    return null;
  }

  List<List<int>> _routeCellsForSpawnRoute(SpawnRouteDefinition route) {
    final citadelCell = stage.citadelCell;
    if (citadelCell == null) {
      return stage.pathsByDirection?[route.direction] ?? const [];
    }
    final goal = switch (route.direction) {
      SpawnDirection.north => [citadelCell[0], math.max(0, citadelCell[1] - 1)],
      SpawnDirection.south => [
        citadelCell[0],
        math.min(13, citadelCell[1] + 1),
      ],
      SpawnDirection.west => [math.max(0, citadelCell[0] - 1), citadelCell[1]],
      SpawnDirection.east => [math.min(13, citadelCell[0] + 1), citadelCell[1]],
    };
    final routeCells = <List<int>>[];
    var col = route.entryCell[0];
    var row = route.entryCell[1];
    routeCells.add([col, row]);
    void addStep(int nextCol, int nextRow) {
      col = nextCol;
      row = nextRow;
      routeCells.add([col, row]);
    }

    if (route.direction == SpawnDirection.north ||
        route.direction == SpawnDirection.south) {
      while (row != goal[1]) {
        addStep(col, row + (row < goal[1] ? 1 : -1));
      }
      while (col != goal[0]) {
        addStep(col + (col < goal[0] ? 1 : -1), row);
      }
    } else {
      while (col != goal[0]) {
        addStep(col + (col < goal[0] ? 1 : -1), row);
      }
      while (row != goal[1]) {
        addStep(col, row + (row < goal[1] ? 1 : -1));
      }
    }
    return routeCells;
  }

  (int, int)? _cellForWorldPosition(Vector2 position) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return null;
    }
    final col = ((position.x - _gridOrigin.x) / _tileSize).floor();
    final row = ((position.y - _gridOrigin.y) / _tileSize).floor();
    if (row < 0 ||
        row >= tileGrid.length ||
        col < 0 ||
        col >= tileGrid[row].length) {
      return null;
    }
    return (col, row);
  }

  void _rerouteEnemies() {
    for (final enemy in _enemies) {
      _assignSiegePathForEnemy(enemy, preservePosition: true);
    }
  }

  List<Vector2> _vectorPathFromCells(
    List<List<int>> cells, {
    required SpawnDirection direction,
    bool randomizeEdgeAnchor = false,
    bool appendCitadelCenter = true,
  }) {
    if (cells.isEmpty) {
      return const [];
    }
    final citadelCenter = _resolvedCitadelCenter();
    final points = <Vector2>[
      for (final cell in cells)
        Vector2(
          _gridOrigin.x + (cell[0] * _tileSize) + (_tileSize / 2),
          _gridOrigin.y + (cell[1] * _tileSize) + (_tileSize / 2),
        ),
    ];
    if (appendCitadelCenter && points.last.distanceTo(citadelCenter) > 1) {
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

  void _drawRoadTiles(Canvas canvas) {
    final tileGrid = stage.tileGrid;
    if (tileGrid == null || tileGrid.isEmpty) {
      return;
    }
    final roadPaths = _visibleRoadPaths();
    if (roadPaths.isEmpty) {
      return;
    }

    final isAssaultRoute = _waveActive && _currentWaveIndex >= 0;
    final roadPaint = Paint()
      ..color = const Color(
        0xFFB99663,
      ).withValues(alpha: isAssaultRoute ? 0.82 : 0.70)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _tileSize * 0.58;
    final dustPaint = Paint()
      ..color = const Color(
        0xFFE0C284,
      ).withValues(alpha: isAssaultRoute ? 0.10 : 0.07)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _tileSize * 0.20;

    for (final points in roadPaths) {
      if (points.length < 2) {
        continue;
      }
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (var i = 1; i < points.length; i += 1) {
        path.lineTo(points[i].x, points[i].y);
      }
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, dustPaint);
    }
  }

  List<List<Vector2>> _visibleRoadPaths() {
    if (_stageCleared || _stageFailed) {
      return const [];
    }
    final visibleWaveIndex = _waveActive && _currentWaveIndex >= 0
        ? _currentWaveIndex
        : _currentWaveIndex + 1;
    if (visibleWaveIndex < 0 || visibleWaveIndex >= stage.waves.length) {
      return const [];
    }
    return _roadPathsForWaveIndex(visibleWaveIndex);
  }

  List<List<Vector2>> _roadPathsForWaveIndex(int waveIndex) {
    return _roadRouteCellsForWaveIndex(waveIndex)
        .map((path) => path.map(_cellCenter).toList())
        .where((path) => path.length >= 2)
        .toList(growable: false);
  }

  @visibleForTesting
  List<List<List<int>>> debugRoadRouteCellsForWaveIndex(int waveIndex) {
    return _roadRouteCellsForWaveIndex(waveIndex);
  }

  List<List<List<int>>> _roadRouteCellsForWaveIndex(int waveIndex) {
    final cycle = _assaultCycleForIndex(waveIndex);
    final wave = _waveForIndex(waveIndex);
    final cycleRouteIds = cycle?.activeRouteIds.toSet() ?? const <String>{};
    final groupRouteIds = wave.groups
        .map((group) => group.routeId)
        .whereType<String>()
        .toSet();
    final routeIds = cycleRouteIds.isNotEmpty ? cycleRouteIds : groupRouteIds;

    if (stage.spawnRoutes.isNotEmpty) {
      final fronts =
          cycle?.activeFronts.toSet() ?? _frontsForWave(wave).toSet();
      return stage.spawnRoutes
          .where(
            (route) =>
                fronts.contains(route.direction) &&
                (routeIds.isEmpty || routeIds.contains(route.id)),
          )
          .map(_routeCellsForSpawnRoute)
          .where((path) => path.length >= 2)
          .toList(growable: false);
    }

    final pathsByDirection =
        stage.pathsByDirection ?? const <SpawnDirection, List<List<int>>>{};
    final fronts = cycle?.activeFronts.toSet() ?? _frontsForWave(wave).toSet();
    return pathsByDirection.entries
        .where((entry) => fronts.contains(entry.key))
        .map((entry) => entry.value)
        .where((path) => path.length >= 2)
        .toList(growable: false);
  }

  void _drawSlots(Canvas canvas) {
    if (_waveActive) {
      return;
    }
    final isHeroMove = sessionController.heroMoveMode;
    final isHeroPlacement = sessionController.selectedHeroBuildable != null;
    final isBarrierPlacement =
        sessionController.selectedBarrierBuildable != null;
    final selection = sessionController.selectedBuildable;
    if (selection == null &&
        !isBarrierPlacement &&
        !isHeroMove &&
        !isHeroPlacement) {
      return;
    }
    final fillColor = isHeroMove || isHeroPlacement
        ? const Color(0x224FC9FF)
        : isBarrierPlacement
        ? const Color(0x26E4C67A)
        : _slotFillColor();
    final ringColor = isHeroMove || isHeroPlacement
        ? const Color(0xFF4FC9FF)
        : isBarrierPlacement
        ? const Color(0xFFE4C67A)
        : _slotRingColor();
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final cell in _buildGridPositions()) {
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
      final size = _obstacleVisualSize(obstacle);
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: center,
          size: size,
          fallbackTint: Colors.white,
          opacity: obstacle.opacity,
        );
      }
    }
  }

  void _drawBarriers(Canvas canvas) {
    for (var i = 0; i < _barriers.length; i += 1) {
      final barrier = _barriers[i];
      final center = barrier.position.toOffset();
      final isFortressWall =
          barrier.definition.kind == BarrierKind.fortressWall;
      final isSelected = i == _selectedBarrierIndex;
      final sprite = _visualRegistry.barrierSprite(barrier.definition.kind);
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: center,
          size: _tileSize * (isFortressWall ? 0.98 : 0.90),
          fallbackTint: barrier.definition.color,
          opacity: isSelected ? 1 : 0.94,
        );
      } else {
        final rect = Rect.fromCenter(
          center: center,
          width: _tileSize * (isFortressWall ? 0.86 : 0.78),
          height: _tileSize * (isFortressWall ? 0.86 : 0.78),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()
            ..color = barrier.definition.color.withValues(
              alpha: isSelected ? 0.98 : 0.88,
            ),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(4)),
          Paint()
            ..color = Colors.black.withValues(
              alpha: isFortressWall ? 0.24 : 0.10,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = isFortressWall ? 3 : 2,
        );
      }
      if (isSelected) {
        canvas.drawCircle(
          center,
          _tileSize * 0.47,
          Paint()
            ..color = const Color(0xFFE4C67A).withValues(alpha: 0.78)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      final hpRatio = (barrier.hitPoints / barrier.maxHitPoints).clamp(
        0.0,
        1.0,
      );
      if (hpRatio < 0.98) {
        final barRect = Rect.fromLTWH(
          center.dx - (_tileSize * 0.28),
          center.dy - (_tileSize * 0.48),
          _tileSize * 0.56,
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
          Paint()..color = const Color(0xFF98D67C),
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

  double _obstacleVisualSize(StageObstacleDefinition obstacle) {
    var minCol = 999;
    var maxCol = -999;
    var minRow = 999;
    var maxRow = -999;
    for (final cell in obstacle.occupiedCells) {
      if (cell.length < 2) {
        continue;
      }
      minCol = math.min(minCol, cell[0]);
      maxCol = math.max(maxCol, cell[0]);
      minRow = math.min(minRow, cell[1]);
      maxRow = math.max(maxRow, cell[1]);
    }
    if (maxCol < minCol || maxRow < minRow) {
      return _tileSize * obstacle.scale;
    }
    final spanCols = maxCol - minCol + 1;
    final spanRows = maxRow - minRow + 1;
    return math.max(spanCols, spanRows) * _tileSize * obstacle.scale;
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
    _drawCitadelGates(canvas);
  }

  Set<SpawnDirection> _visibleCitadelGateFronts() {
    final fronts = <SpawnDirection>{};
    if (_waveActive) {
      fronts.addAll(_activeFronts);
    }
    if (!_waveActive || _recoveryActive) {
      fronts.addAll(_nextFronts);
    }
    if (fronts.isEmpty && _isSiegeMode) {
      fronts.addAll(_nextFronts);
    }
    if (fronts.isEmpty && _isSiegeMode) {
      fronts.addAll(_pathsByDirection.keys);
    }
    return fronts;
  }

  void _drawCitadelGates(Canvas canvas) {
    for (final front in _visibleCitadelGateFronts()) {
      final center = _citadelGateCenterForDirection(front);
      if (center == null) {
        continue;
      }
      final isActive = _activeFronts.contains(front);
      final isNext = _nextFronts.contains(front);
      final color = _frontColor(front);
      final alpha = isActive ? 0.56 : (isNext ? 0.42 : 0.24);
      final horizontal =
          front == SpawnDirection.north || front == SpawnDirection.south;
      final thresholdRect = Rect.fromCenter(
        center: center.toOffset(),
        width: horizontal ? _tileSize * 0.72 : _tileSize * 0.22,
        height: horizontal ? _tileSize * 0.22 : _tileSize * 0.72,
      );
      canvas.drawCircle(
        center.toOffset(),
        _tileSize * 0.42,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.24)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(thresholdRect, const Radius.circular(5)),
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(thresholdRect, const Radius.circular(5)),
        Paint()
          ..color = const Color(
            0xFFFFF1B8,
          ).withValues(alpha: math.min(0.72, alpha + 0.16))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.3 : 1.7,
      );

      final intoCitadel = -_directionOffset(front);
      final tip = center + intoCitadel * (_tileSize * 0.25);
      final side = Vector2(-intoCitadel.y, intoCitadel.x) * (_tileSize * 0.13);
      final tail = center - intoCitadel * (_tileSize * 0.13);
      final arrow = Path()
        ..moveTo(tip.x, tip.y)
        ..lineTo(tail.x + side.x, tail.y + side.y)
        ..lineTo(tail.x - side.x, tail.y - side.y)
        ..close();
      canvas.drawPath(
        arrow,
        Paint()
          ..color = const Color(
            0xFFFFF1B8,
          ).withValues(alpha: math.min(0.74, alpha + 0.12))
          ..style = PaintingStyle.fill,
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

  List<Vector2> _buildGridPositions() {
    final cells = <Vector2>[];
    final tileGrid = stage.tileGrid;
    if (tileGrid != null && tileGrid.isNotEmpty) {
      for (var row = 0; row < tileGrid.length; row += 1) {
        for (var col = 0; col < tileGrid[row].length; col += 1) {
          final tileType = tileGrid[row][col];
          if (tileType != TileType.buildable) {
            continue;
          }
          if (_isStaticObjectCell(col, row)) {
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

  bool _isStaticObjectCell(int col, int row) {
    if (stageCitadelBuildBlockedCells(stage.citadelCell).contains((col, row))) {
      return true;
    }
    for (final obstacle in stage.obstacles) {
      for (final cell in obstacle.occupiedCells) {
        if (cell.length >= 2 && cell[0] == col && cell[1] == row) {
          return true;
        }
      }
    }
    for (final decoration in stage.decorations) {
      if (stageDecorationFootprintCells(decoration).contains((col, row))) {
        return true;
      }
    }
    return false;
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
    for (final barrier in _barriers) {
      if (barrier.position.distanceTo(pos) < (_tileSize * 0.72)) return true;
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
        if (_moveHeroToward(hero, hero.walkTarget!, dt)) {
          hero.walkTarget = null;
        }
      } else {
        _updateHeroGuardMovement(hero, dt);
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
      final target = _pickHeroGuardTarget(hero);
      if (target != null &&
          hero.position.distanceTo(target.position) <=
              _heroCurrentRange(hero)) {
        _fireHero(hero, target);
      }
    }
  }

  void _updateHeroGuardMovement(_HeroPlacement hero, double dt) {
    final target = _pickHeroGuardTarget(hero);
    if (target != null) {
      final distance = hero.position.distanceTo(target.position);
      final stopDistance = math.max(
        _tileSize * 0.48,
        _heroCurrentRange(hero) * 0.78,
      );
      if (distance > stopDistance) {
        _moveHeroToward(hero, target.position, dt, stopDistance: stopDistance);
      }
      return;
    }

    if (hero.position.distanceTo(hero.guardAnchor) > 1.5) {
      _moveHeroToward(hero, hero.guardAnchor, dt);
    }
  }

  bool _moveHeroToward(
    _HeroPlacement hero,
    Vector2 target,
    double dt, {
    double stopDistance = 0,
  }) {
    _walkDelta.setFrom(target);
    _walkDelta.sub(hero.position);
    final dist = _walkDelta.length;
    final step = _HeroPlacement.walkSpeed * dt;
    if (dist <= stopDistance + step || dist <= 0.001) {
      if (stopDistance > 0 && dist > 0.001) {
        _walkDelta.scale(1.0 / dist);
        hero.position.setFrom(target - (_walkDelta * stopDistance));
        hero.facing = _directionFromDelta(_walkDelta);
      } else {
        hero.position.setFrom(target);
      }
      return true;
    }

    _walkDelta.scale(1.0 / dist);
    hero.position.addScaled(_walkDelta, step);
    hero.facing = _directionFromDelta(_walkDelta);
    return false;
  }

  _Enemy? _pickHeroGuardTarget(_HeroPlacement hero) {
    if (!_waveActive) {
      return null;
    }
    final guardRadius = _heroGuardRadius(hero);
    _Enemy? target;
    var bestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (enemy.hitPoints <= 0 || enemy.reachedGoal) {
        continue;
      }
      if (enemy.position.distanceTo(hero.guardAnchor) > guardRadius) {
        continue;
      }
      final distance = hero.position.distanceTo(enemy.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        target = enemy;
      }
    }
    return target;
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
      if (tower.position.distanceTo(hero.position) > _heroCurrentRange(hero)) {
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

  void _fireHero(_HeroPlacement hero, _Enemy target) {
    hero.cooldownRemaining = hero.currentCooldown;
    hero.attackVisualTimer = 0.22;
    final attackDirection = target.position - hero.position;
    if (attackDirection.length2 > 0.0001) {
      hero.attackDirection.setFrom(attackDirection);
      hero.attackDirection.normalize();
    }
    hero.facing = _directionFromDelta(attackDirection);

    final damageType = switch (hero.definition.kind) {
      HeroKind.mage => _DamageType.magic,
      _ => _DamageType.physical,
    };
    final baseDamage =
        _heroCurrentDamage(hero) * _heroMetaDamageMultiplier(hero);
    final adjustedDamage = _adjustDamageForEnemy(
      target: target,
      damage: baseDamage,
      damageType: damageType,
    );
    target.hitPoints -= adjustedDamage;
    _recordEnemyDamage(
      target,
      adjustedDamage,
      damageType == _DamageType.magic
          ? hero.definition.color
          : const Color(0xFFFFF1CC),
    );

    switch (hero.definition.kind) {
      case HeroKind.mage:
        _spawnBeam(
          from: hero.position,
          to: target.position,
          color: hero.definition.color,
          lifetime: 0.32,
          strokeWidth: 5.2,
        );
        _spawnBeam(
          from: hero.position,
          to: target.position,
          color: Colors.white.withValues(alpha: 0.82),
          lifetime: 0.18,
          strokeWidth: 2.4,
        );
        _spawnPulse(
          center: target.position,
          color: hero.definition.color,
          maxRadius: 28,
          lifetime: 0.30,
          strokeWidth: 3.2,
        );
        _spawnImpact(
          target.position,
          hero.definition.color,
          18,
          0.20,
          effectId: EffectVisualCatalog.arcaneBoltProjectile,
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
            _recordEnemyDamage(splash, splashDamage, hero.definition.color);
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
          lifetime: 0.20,
          radius: 3.0,
          effectId: EffectVisualCatalog.arrowProjectile,
        );
        target.heroMarkedTimer = math.max(target.heroMarkedTimer, 3.2);
        break;
      case HeroKind.ninja:
        _spawnProjectile(
          from: hero.position,
          to: target.position,
          color: hero.definition.color,
          lifetime: 0.16,
          radius: 4.2,
          effectId: EffectVisualCatalog.shurikenProjectile,
        );
        _spawnImpact(target.position, hero.definition.color, 20, 0.14);
        if (target.hitPoints > 0 &&
            target.hitPoints / target.definition.hitPoints <=
                (0.28 + (metaUpgrades.frostFocusLevel * 0.01))) {
          target.hitPoints -= target.definition.hitPoints * 0.18;
          _recordEnemyDamage(
            target,
            target.definition.hitPoints * 0.18,
            const Color(0xFFFFD1D6),
          );
          target.staggerTimer = math.max(target.staggerTimer, 0.14);
          _spawnImpact(target.position, const Color(0xFFFFD1D6), 26, 0.18);
        }
        break;
      case HeroKind.knight:
      case HeroKind.paladin:
        _spawnSlash(
          center: hero.position,
          direction: attackDirection,
          color: hero.definition.color,
          radius: 26,
          lifetime: 0.18,
        );
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

  void _drawSelectionRanges(Canvas canvas) {
    final tower = _selectedTower;
    if (tower != null) {
      _drawRangeCircle(
        canvas,
        center: tower.position,
        radius: _towerCurrentRange(tower),
        color: const Color(0xFFE4C67A),
      );
    }

    final hero = _selectedHero;
    if (hero != null) {
      _drawRangeCircle(
        canvas,
        center: hero.position,
        radius: _heroSelectionRange(hero),
        color: const Color(0xFFE4C67A),
      );
    }
  }

  void _drawRangeCircle(
    Canvas canvas, {
    required Vector2 center,
    required double radius,
    required Color color,
  }) {
    if (radius <= 0) {
      return;
    }
    final offset = center.toOffset();
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
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
      final towerRenderSize = _tileSize * 1.12;
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
        final attackProgress = hero.attackVisualTimer > 0
            ? 1 - (hero.attackVisualTimer / 0.22).clamp(0.0, 1.0)
            : 0.0;
        final lunge = math.sin(attackProgress * math.pi) * 8;
        final attackOffset = hero.attackDirection * lunge;
        _drawSprite(
          canvas,
          sprite,
          center: Offset(
            center.dx + attackOffset.x,
            center.dy + attackOffset.y,
          ),
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
      final hpRatio = (hero.hitPoints / hero.maxHitPoints).clamp(0.0, 1.0);
      if (hpRatio < 0.98) {
        final barRect = Rect.fromLTWH(
          center.dx - (_tileSize * 0.24),
          center.dy - (_tileSize * 0.50),
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
          Paint()..color = const Color(0xFF77A7FF),
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
      final center = isLandmark
          ? Offset(
              decoration.position.dx * size.x,
              decoration.position.dy * size.y,
            )
          : _decorationCellCenter(decoration);
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

  Offset _decorationCellCenter(StageDecorationDefinition decoration) {
    final rows = stage.tileGrid?.length ?? 14;
    final columns = stage.tileGrid?.isNotEmpty ?? false
        ? stage.tileGrid!.first.length
        : 14;
    final cells = stageDecorationFootprintCells(
      decoration,
      columns: columns,
      rows: rows,
      tileSize: _tileSize,
    );
    if (cells.isEmpty) {
      return Offset(
        decoration.position.dx * size.x,
        decoration.position.dy * size.y,
      );
    }
    final averageCol =
        cells.map((cell) => cell.$1).reduce((a, b) => a + b) / cells.length;
    final averageRow =
        cells.map((cell) => cell.$2).reduce((a, b) => a + b) / cells.length;
    return Offset(
      _gridOrigin.x + ((averageCol + 0.5) * _tileSize),
      _gridOrigin.y + ((averageRow + 0.5) * _tileSize),
    );
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
      1 => 17.0,
      2 => 18.5,
      _ => 20.0,
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
      final travel = projectile.to - projectile.from;
      final position = projectile.from + (travel * t);
      final trailStart = projectile.from + (travel * math.max(0.0, t - 0.18));
      canvas.drawLine(
        trailStart.toOffset(),
        position.toOffset(),
        Paint()
          ..color = projectile.color.withValues(alpha: (1 - t) * 0.52)
          ..strokeWidth = projectile.radius * 1.25
          ..strokeCap = StrokeCap.round,
      );
      final sprite = projectile.effectId == null
          ? null
          : _visualRegistry.effectSprite(projectile.effectId!);
      if (sprite != null) {
        _drawOrientedSpriteRect(
          canvas,
          sprite,
          center: position.toOffset(),
          width: 22 + (projectile.radius * 4.4),
          height: 8 + projectile.radius,
          angle: math.atan2(travel.y, travel.x),
          opacity: 1 - (t * 0.22),
          tintColor: projectile.color,
        );
      } else {
        canvas.drawCircle(
          position.toOffset(),
          projectile.radius,
          Paint()..color = projectile.color.withValues(alpha: 1 - (t * 0.3)),
        );
      }
    }
  }

  void _drawBombardments(Canvas canvas) {
    final sprite = _visualRegistry.effectSprite(
      EffectVisualCatalog.cannonballProjectile,
    );
    for (final bombardment in _bombardments) {
      if (bombardment.age < 0) {
        continue;
      }
      final warningT = (bombardment.age / bombardment.warningSeconds)
          .clamp(0.0, 1.0)
          .toDouble();
      final warningAlpha = bombardment.impacted ? 0.0 : (0.58 - warningT * 0.3);
      if (!bombardment.impacted) {
        canvas.drawCircle(
          bombardment.to.toOffset(),
          bombardment.radius,
          Paint()
            ..color = const Color(0xFFFF6B4A).withValues(alpha: warningAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
        canvas.drawCircle(
          bombardment.to.toOffset(),
          bombardment.radius * 0.28,
          Paint()..color = const Color(0xFFFFB05F).withValues(alpha: 0.16),
        );
      }

      if (!bombardment.impacted) {
        final travel = bombardment.to - bombardment.from;
        final position = bombardment.from + (travel * warningT);
        position.y -= math.sin(warningT * math.pi) * 54;
        final trailStart =
            bombardment.from + (travel * math.max(0.0, warningT - 0.16));
        canvas.drawLine(
          trailStart.toOffset(),
          position.toOffset(),
          Paint()
            ..color = const Color(0xFFFFB05F).withValues(alpha: 0.42)
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        if (sprite != null) {
          _drawOrientedSpriteRect(
            canvas,
            sprite,
            center: position.toOffset(),
            width: 42,
            height: 42,
            angle: math.atan2(travel.y, travel.x),
          );
        } else {
          canvas.drawCircle(
            position.toOffset(),
            11,
            Paint()..color = const Color(0xFF2F2B2A),
          );
          canvas.drawCircle(
            position.toOffset() + const Offset(-3, -3),
            4,
            Paint()..color = const Color(0xFFFFB05F),
          );
        }
        continue;
      }

      final impactT =
          ((bombardment.age - bombardment.warningSeconds) /
                  (bombardment.lifetime - bombardment.warningSeconds))
              .clamp(0.0, 1.0);
      final impactProgress = impactT.toDouble();
      canvas.drawCircle(
        bombardment.to.toOffset(),
        bombardment.radius * (0.35 + impactProgress * 0.65),
        Paint()
          ..color = const Color(
            0xFFFF8C46,
          ).withValues(alpha: (1 - impactProgress) * 0.34),
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
      final attackVisualDuration = _enemyAttackVisualDuration(enemy);
      final attackProgress = enemy.towerAttackVisualTimer > 0
          ? 1 -
                (enemy.towerAttackVisualTimer / attackVisualDuration).clamp(
                  0.0,
                  1.0,
                )
          : 0.0;
      final attackLunge =
          math.sin(attackProgress * math.pi) * (_isBossEnemy(enemy) ? 20 : 7);
      final attackOffset = enemy.attackDirection * attackLunge;
      final renderCenter = Offset(
        enemy.position.x + attackOffset.x,
        enemy.position.y + attackOffset.y,
      );
      final visualSize = visual.baseSize * enemy.visualScale;
      final rect = Rect.fromCenter(
        center: enemy.position.toOffset(),
        width: visualSize,
        height: visualSize,
      );
      if (_isFastEnemy(enemy.definition.kind)) {
        final trailStep = _directionOffset(enemy.currentDirection);
        for (var i = 1; i <= 2; i += 1) {
          canvas.drawCircle(
            (enemy.position - (trailStep * (i * 7))).toOffset(),
            visual.baseSize * (0.22 - (i * 0.04)),
            Paint()
              ..color = visual.primaryColor.withValues(
                alpha: 0.16 - (i * 0.05),
              ),
          );
        }
      }
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: renderCenter,
          size: visual.baseSize * visual.renderScale * enemy.visualScale,
          fallbackTint: visual.primaryColor,
          flipX: direction == SpawnDirection.east,
        );
      } else {
        _drawTokenShape(
          canvas,
          renderCenter,
          shape: visual.shape,
          size: visualSize,
          fillColor: visual.primaryColor,
          accentColor: visual.accentColor,
        );
      }
      if (enemy.hitFlashTimer > 0) {
        final flash = (enemy.hitFlashTimer / 0.14).clamp(0.0, 1.0);
        canvas.drawCircle(
          enemy.position.toOffset(),
          visualSize * 0.34,
          Paint()..color = Colors.white.withValues(alpha: flash * 0.24),
        );
        if (_isArmoredEnemy(enemy.definition.kind)) {
          canvas.drawCircle(
            enemy.position.toOffset(),
            visualSize * 0.42,
            Paint()
              ..color = const Color(0xFFA7C5FF).withValues(alpha: flash * 0.50)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }
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
        final isBoss = _isBossEnemy(enemy);
        canvas.drawCircle(
          enemy.position.toOffset(),
          (isBoss ? 24 : 15) +
              (enemy.towerAttackVisualTimer * (isBoss ? 28 : 12)),
          Paint()
            ..color = const Color(0x66FF7043)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isBoss ? 4.0 : 2.5,
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
        visualSize * hpRatio,
        4,
      );
      canvas.drawRect(hpRect, Paint()..color = const Color(0xFF88D66C));
    }
  }

  bool _isFastEnemy(EnemyKind kind) {
    return kind == EnemyKind.scout ||
        kind == EnemyKind.raider ||
        kind == EnemyKind.wolfScout;
  }

  bool _isArmoredEnemy(EnemyKind kind) {
    return kind == EnemyKind.shieldInfantry ||
        kind == EnemyKind.corruptedKnight ||
        kind == EnemyKind.graveGuard ||
        kind == EnemyKind.bastionOverlord;
  }

  Vector2 _directionOffset(SpawnDirection direction) {
    return switch (direction) {
      SpawnDirection.north => Vector2(0, -1),
      SpawnDirection.south => Vector2(0, 1),
      SpawnDirection.east => Vector2(1, 0),
      SpawnDirection.west => Vector2(-1, 0),
    };
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

  void _drawSlashes(Canvas canvas) {
    for (final slash in _slashes) {
      final t = (slash.age / slash.lifetime).clamp(0.0, 1.0);
      final angle = math.atan2(slash.direction.y, slash.direction.x);
      final center = slash.center + (slash.direction * slash.radius * 0.28);
      canvas.drawArc(
        Rect.fromCircle(center: center.toOffset(), radius: slash.radius),
        angle - 0.85,
        1.7,
        false,
        Paint()
          ..color = slash.color.withValues(alpha: (1 - t) * 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0 * (1 - (t * 0.45))
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawStrikes(Canvas canvas) {
    for (final strike in _strikes) {
      final t = (strike.age / strike.lifetime).clamp(0.0, 1.0);
      final direction = strike.to - strike.from;
      final start = strike.from + (direction * (0.22 * t));
      final end = strike.from + (direction * (0.70 + (0.20 * t)));
      canvas.drawLine(
        start.toOffset(),
        end.toOffset(),
        Paint()
          ..color = strike.color.withValues(alpha: (1 - t) * 0.72)
          ..strokeWidth = strike.strokeWidth * (1 - (t * 0.35))
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawImpacts(Canvas canvas) {
    for (final impact in _impacts) {
      final t = (impact.age / impact.lifetime).clamp(0.0, 1.0);
      final sprite = impact.effectId == null
          ? null
          : _visualRegistry.effectSprite(impact.effectId!);
      if (sprite != null) {
        _drawSprite(
          canvas,
          sprite,
          center: impact.center.toOffset(),
          size: impact.maxRadius * (1.0 + (t * 0.65)),
          fallbackTint: impact.color,
          opacity: (1 - t) * 0.9,
          tintColor: impact.color,
        );
      } else {
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
  }

  void _drawFloatingTexts(Canvas canvas) {
    for (final text in _floatingTexts) {
      final t = (text.age / text.lifetime).clamp(0.0, 1.0);
      final position = text.origin + Vector2(0, -18 * t);
      final painter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(
            color: text.color.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          position.x - (painter.width / 2),
          position.y - (painter.height / 2),
        ),
      );
    }
  }

  void _spawnProjectile({
    required Vector2 from,
    required Vector2 to,
    required Color color,
    required double lifetime,
    required double radius,
    String? effectId,
  }) {
    _projectiles.add(
      _ProjectileVisual(
        from: from.clone(),
        to: to.clone(),
        color: color,
        lifetime: lifetime,
        radius: radius,
        effectId: effectId,
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
    double lifetime, {
    String? effectId,
  }) {
    _impacts.add(
      _ImpactVisual(
        center: center.clone(),
        color: color,
        maxRadius: maxRadius,
        lifetime: lifetime,
        effectId: effectId,
      ),
    );
  }

  void _spawnSlash({
    required Vector2 center,
    required Vector2 direction,
    required Color color,
    required double radius,
    required double lifetime,
  }) {
    final normalized = direction.clone();
    if (normalized.length2 <= 0.0001) {
      normalized.setValues(0, 1);
    } else {
      normalized.normalize();
    }
    if (_slashes.length >= 32) {
      _slashes.removeAt(0);
    }
    _slashes.add(
      _SlashVisual(
        center: center.clone(),
        direction: normalized,
        color: color,
        radius: radius,
        lifetime: lifetime,
      ),
    );
  }

  void _spawnStrike({
    required Vector2 from,
    required Vector2 to,
    required Color color,
    required double lifetime,
    double strokeWidth = 3.0,
  }) {
    if (_strikes.length >= 32) {
      _strikes.removeAt(0);
    }
    _strikes.add(
      _StrikeVisual(
        from: from.clone(),
        to: to.clone(),
        color: color,
        lifetime: lifetime,
        strokeWidth: strokeWidth,
      ),
    );
  }

  void _recordEnemyDamage(
    _Enemy enemy,
    double damage,
    Color color, {
    bool showNumber = true,
  }) {
    if (damage <= 0) {
      return;
    }
    enemy.hitFlashTimer = math.max(enemy.hitFlashTimer, 0.14);
    enemy.lastDamageTaken = damage;
    if (showNumber && damage >= 3 && _floatingTexts.length < 48) {
      _spawnFloatingText(
        enemy.position + Vector2(0, -18),
        damage.round().toString(),
        color,
        lifetime: 0.52,
      );
    }
  }

  void _spawnFloatingText(
    Vector2 origin,
    String text,
    Color color, {
    double lifetime = 0.62,
  }) {
    if (_floatingTexts.length >= 64) {
      _floatingTexts.removeAt(0);
    }
    _floatingTexts.add(
      _FloatingTextVisual(
        origin: origin.clone(),
        text: text,
        color: color,
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

  void _drawOrientedSpriteRect(
    Canvas canvas,
    ui.Image image, {
    required Offset center,
    required double width,
    required double height,
    required double angle,
    double opacity = 1.0,
    Color? tintColor,
  }) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
    if (tintColor != null) {
      paint.colorFilter = ColorFilter.mode(tintColor, BlendMode.modulate);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawImageRect(image, src, dst, paint);
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

  void _syncSelectedBarrier() {
    sessionController.setSelectedBarrier(_selectedBarrier?.details);
  }

  void _syncHeroStatus() {
    _HeroPlacement? hero;
    for (final candidate in _heroes) {
      if (candidate.definition.kind == chosenHeroKind) {
        hero = candidate;
        break;
      }
    }
    sessionController.setChosenHeroStatus(
      alive: hero != null,
      reviveAvailable:
          hero == null && _heroSummonedThisStage && !_heroReviveUsed,
      hitPoints: hero?.hitPoints ?? 0,
      maxHitPoints: hero?.maxHitPoints ?? 0,
    );
  }

  /// Marks session state as needing a sync.
  /// Actual Flutter notification happens in the 15fps throttle (update loop).
  void _syncSession() {
    _sessionDirty = true;
  }

  /// Performs the actual session sync — called only from the 15fps throttle.
  void _flushSession() {
    _syncHeroStatus();
    final battleState = _stageCleared
        ? 'clear'
        : _stageFailed
        ? 'fail'
        : _waveActive
        ? 'assault'
        : _recoveryActive
        ? 'manual_ready'
        : (_currentWaveIndex < 0 ? 'prep' : 'idle');
    final runtimeRemaining = _stageFailed ? 0 : _remainingEnemiesInCycle;
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
      loopLabel: 'WAVE',
      activeFronts: _activeFronts.map((front) => _frontLabel([front])).toList(),
      nextFronts: _nextFronts.map((front) => _frontLabel([front])).toList(),
      recoverySecondsRemaining: _recoveryTimer,
      recoveryActive: _recoveryActive,
      battleState: battleState,
      remainingEnemies: runtimeRemaining,
    );
    _logUiSnapshotIfChanged(battleState, runtimeRemaining);
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

  _BarrierPlacement? get _selectedBarrier {
    final index = _selectedBarrierIndex;
    if (index == null || index < 0 || index >= _barriers.length) {
      return null;
    }
    return _barriers[index];
  }
}

class _HeroPlacement {
  _HeroPlacement({
    required this.definition,
    required this.position,
    this.initialLevel = 1,
    Vector2? guardAnchor,
  }) : guardAnchor = (guardAnchor ?? position).clone(),
       level = initialLevel,
       totalSpent = definition.cost,
       hitPoints = 160 + (definition.cost * 0.45) + ((initialLevel - 1) * 45);

  static const double walkSpeed = 90.0;

  final HeroDefinition definition;
  final Vector2 position;
  final int initialLevel;
  final Vector2 guardAnchor;
  final Vector2 attackDirection = Vector2(0, 1);
  Vector2? walkTarget;
  int level;
  int totalSpent;
  double hitPoints;
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
  bool get canUpgrade => level < _maxCombatUnitLevel;
  double get maxHitPoints =>
      160 + (definition.cost * 0.45) + ((level - 1) * 45);

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
  _TowerPlacement({
    required this.definition,
    required this.position,
    this.initialLevel = 1,
    int? totalSpent,
  }) : level = initialLevel,
       totalSpent = totalSpent ?? definition.cost,
       hitPoints = 120 + (definition.cost * 0.65) + ((initialLevel - 1) * 55);

  final TowerDefinition definition;
  final Vector2 position;
  final int initialLevel;
  int level;
  int totalSpent;
  double hitPoints;
  double cooldownRemaining = 0;
  double economyTimer = 1.5;
  double attackVisualTimer = 0;
  int shotCounter = 0;
  int economyIncomeBonus = 0;
  String? branchId;

  double get currentDamage => _towerDamageForLevel(definition, level);
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
  bool get canUpgrade => level < _maxCombatUnitLevel;
  bool get canChooseBranch => level >= 2 && branchId == null;
  int get economyWaveStartBonus => definition.kind == TowerKind.coinMill
      ? _coinMillWaveStartBonusFor(
          level: level,
          incomeBonus: economyIncomeBonus,
          branchId: branchId,
        )
      : 0;
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
    economyCycleBonus: definition.economyIncome == null
        ? null
        : economyWaveStartBonus,
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

class _BarrierPlacement {
  _BarrierPlacement({
    required this.definition,
    required this.position,
    required this.maxHitPoints,
    required this.repairCost,
  }) : hitPoints = maxHitPoints;

  final BarrierDefinition definition;
  final Vector2 position;
  final double maxHitPoints;
  final int repairCost;
  double hitPoints;

  int get sellValue => (definition.cost * 0.7).round();

  SelectedBarrierDetails get details => SelectedBarrierDetails(
    kind: definition.kind,
    label: definition.label,
    hitPoints: hitPoints,
    maxHitPoints: maxHitPoints,
    sellValue: sellValue,
    shortDescription: '적을 붙잡아 타워가 공격할 시간을 벌어줍니다.',
  );
}

class _Enemy {
  _Enemy.fromDefinition(
    this.definition, {
    required this.spawnDirection,
    this.routeId,
  }) : hitPoints = definition.hitPoints.toDouble(),
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
  final String? routeId;
  SpawnDirection currentDirection;
  final Vector2 position;
  int debugId = 0;
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
  (int, int)? breachTargetCell;
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
  final Vector2 attackDirection = Vector2(0, 1);
  double visualScale = 1.0;
  String? stageEventLabel;
  double heroMarkedTimer = 0;
  double hitFlashTimer = 0;
  double lastDamageTaken = 0;
  bool debugTouchBlockedLogged = false;

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
    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
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
        _enemyMoveSpeedMultiplier *
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
    this.effectId,
  });

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double lifetime;
  final double radius;
  final String? effectId;
  double age = 0;
}

class _BombardmentVisual {
  _BombardmentVisual({
    required this.from,
    required this.to,
    required this.radius,
    required this.damage,
    required this.warningSeconds,
    required this.lifetime,
    this.launchDelay = 0,
  }) : age = -launchDelay;

  final Vector2 from;
  final Vector2 to;
  final double radius;
  final int damage;
  final double warningSeconds;
  final double lifetime;
  final double launchDelay;
  bool impacted = false;
  double age;
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
    this.effectId,
  });

  final Vector2 center;
  final Color color;
  final double maxRadius;
  final double lifetime;
  final String? effectId;
  double age = 0;
}

class _SlashVisual {
  _SlashVisual({
    required this.center,
    required this.direction,
    required this.color,
    required this.radius,
    required this.lifetime,
  });

  final Vector2 center;
  final Vector2 direction;
  final Color color;
  final double radius;
  final double lifetime;
  double age = 0;
}

class _StrikeVisual {
  _StrikeVisual({
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

class _FloatingTextVisual {
  _FloatingTextVisual({
    required this.origin,
    required this.text,
    required this.color,
    required this.lifetime,
  });

  final Vector2 origin;
  final String text;
  final Color color;
  final double lifetime;
  double age = 0;
}
