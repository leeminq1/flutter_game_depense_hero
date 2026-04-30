import 'dart:async';
import 'dart:math' as math;

import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.bootstrap,
    required this.onExitToCamp,
    this.initialStageNumber = 1,
  });

  final AppBootstrap bootstrap;
  final VoidCallback onExitToCamp;
  final int initialStageNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameSessionController _sessionController;
  DefensePrototypeGame? _game;
  CampaignOverview? _overview;
  StageCompletionResult? _completionResult;
  late int _stageNumber;
  int _gameEpoch = 0;
  bool _isEvaluating = false;
  ResolvedMetaUpgrades? _activeMetaUpgrades;
  HeroKind? _chosenHeroKind;

  bool _hintBannerVisible = true;
  Timer? _hintTimer;
  bool _towerActionBarVisible = false;
  bool _actionBarWasShownForCurrentSelection = false;
  int _lastSelectionVersion = -1;
  Timer? _towerActionBarTimer;
  String _lastStatusText = '';
  String? _lastSelectedTowerSignature;
  String? _lastSelectedHeroSignature;
  bool _isBackgroundPaused = false;
  int? _immediateStarsAwarded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stageNumber = widget.initialStageNumber;
    _sessionController = GameSessionController();
    _sessionController.addListener(_handleSessionChanged);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _towerActionBarTimer?.cancel();
    _sessionController.removeListener(_handleSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = _game;
    if (game == null) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        game.pauseEngine();
        widget.bootstrap.audioService.stopMusic();
        if (!_isBackgroundPaused) {
          setState(() => _isBackgroundPaused = true);
        }
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _initialize() async {
    await _refreshOverview();
    await _chooseHero(force: true);
    await _loadStage(_stageNumber);
  }

  Future<void> _chooseHero({bool force = false}) async {
    if (!force && _chosenHeroKind != null) {
      return;
    }
    final choice = await showDialog<HeroKind>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _HeroChoiceDialog(initialKind: _chosenHeroKind),
    );
    if (!mounted) {
      return;
    }
    setState(() => _chosenHeroKind = choice ?? HeroKind.knight);
  }

  Future<void> _refreshOverview() async {
    final overview = await widget.bootstrap.progressStore.loadCampaignOverview(
      totalStages: CampaignData.totalStages,
    );
    if (!mounted) {
      return;
    }
    setState(() => _overview = overview);
  }

  Future<void> _loadStage(int stageNumber) async {
    final overview =
        _overview ??
        await widget.bootstrap.progressStore.loadCampaignOverview(
          totalStages: CampaignData.totalStages,
        );

    final resolvedMeta = MetaUpgradeCatalog.resolve(overview.metaUpgrades);
    final stage = CampaignData.stage(stageNumber);

    if (!mounted) {
      return;
    }

    _hintTimer?.cancel();
    _towerActionBarTimer?.cancel();
    setState(() {
      _isBackgroundPaused = false;
      _activeMetaUpgrades = resolvedMeta;
      _stageNumber = stageNumber;
      _completionResult = null;
      _immediateStarsAwarded = null;
      _isEvaluating = false;
      _gameEpoch += 1;
      _hintBannerVisible = true;
      _towerActionBarVisible = false;
      _lastStatusText = '';
      _lastSelectedTowerSignature = null;
      _lastSelectedHeroSignature = null;
      _game = DefensePrototypeGame(
        stage: stage,
        sessionController: _sessionController,
        audioService: widget.bootstrap.audioService,
        metaUpgrades: resolvedMeta,
        chosenHeroKind: _chosenHeroKind ?? HeroKind.knight,
      );
    });
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintBannerVisible = false);
    });
  }

  void _showHintBanner() {
    _hintTimer?.cancel();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hintTimer?.cancel();
      setState(() => _hintBannerVisible = true);
      _hintTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _hintBannerVisible = false);
      });
    });
  }

  void _showTowerActionBar() {
    _towerActionBarTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _towerActionBarVisible = true);
    _actionBarWasShownForCurrentSelection = true;
    _towerActionBarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _towerActionBarVisible = false);
      }
    });
  }

  String? _selectedTowerSignature(SelectedTowerDetails? tower) {
    if (tower == null) {
      return null;
    }
    return [
      tower.kind.name,
      tower.level.toString(),
      tower.upgradeCost.toString(),
      tower.sellValue.toString(),
      tower.economyIncomePerTick?.toString() ?? '-',
      tower.economyCycleBonus?.toString() ?? '-',
      tower.branchId ?? '-',
    ].join(':');
  }

  String? _selectedHeroSignature(SelectedHeroDetails? hero) {
    if (hero == null) {
      return null;
    }
    return [
      hero.kind.name,
      hero.level.toString(),
      hero.upgradeCost.toString(),
      hero.abilityLabel,
    ].join(':');
  }

  void _handleTransientHud() {
    final statusText = _sessionController.statusText;
    if (statusText.isNotEmpty && statusText != _lastStatusText) {
      _lastStatusText = statusText;
      _showHintBanner();
    }

    final signature = _selectedTowerSignature(_sessionController.selectedTower);
    final heroSignature = _selectedHeroSignature(
      _sessionController.selectedHero,
    );
    final currentVersion = _sessionController.selectionVersion;
    final userTapped = currentVersion != _lastSelectionVersion;
    if (userTapped) {
      _lastSelectionVersion = currentVersion;
      _actionBarWasShownForCurrentSelection = false;
    }

    final sameSelection =
        signature == _lastSelectedTowerSignature &&
        heroSignature == _lastSelectedHeroSignature;
    if (sameSelection &&
        (_towerActionBarVisible || _actionBarWasShownForCurrentSelection)) {
      return;
    }

    _lastSelectedTowerSignature = signature;
    _lastSelectedHeroSignature = heroSignature;
    if (signature == null && heroSignature == null) {
      _towerActionBarTimer?.cancel();
      _actionBarWasShownForCurrentSelection = false;
      if (mounted && _towerActionBarVisible) {
        setState(() => _towerActionBarVisible = false);
      }
      return;
    }

    _showTowerActionBar();
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161D26),
        title: const Text('전투 종료', style: TextStyle(color: Colors.white)),
        content: const Text(
          '캠프로 돌아가시겠습니까?\n진행 중인 전투는 저장되지 않습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4E4E),
            ),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onExitToCamp();
    }
  }

  Future<void> _handleSessionChanged() async {
    final game = _game;
    if (game == null) {
      return;
    }

    _handleTransientHud();

    if ((_sessionController.stageCleared || _sessionController.stageFailed) &&
        !_isEvaluating &&
        _completionResult == null) {
      _isEvaluating = true;
      final evaluation = game.evaluateCurrentRun();

      if (mounted) {
        setState(() => _immediateStarsAwarded = evaluation.starsAwarded);
      }

      try {
        final result = await widget.bootstrap.progressStore
            .recordStageCompletion(
              stageNumber: _sessionController.stageNumber,
              evaluation: evaluation,
              totalStages: CampaignData.totalStages,
            );

        await _refreshOverview();

        if (!mounted) {
          return;
        }

        setState(() {
          _completionResult = result;
        });
      } catch (_) {
        // DB 저장 실패해도 별 표시는 유지됨
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final overview = _overview;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactBattlefield = screenWidth <= 420;

    if (game == null || overview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStage = overview.stages[_stageNumber - 1];
    final activeMetaUpgrades =
        _activeMetaUpgrades ??
        MetaUpgradeCatalog.resolve(overview.metaUpgrades);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071B2F),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _sessionController,
            builder: (context, _) {
              final session = _sessionController;
              final showWaveButton =
                  !session.waveInProgress &&
                  !session.stageCleared &&
                  !session.stageFailed &&
                  !session.mustResolveRunOffer &&
                  session.currentWave < session.totalWaves;
              final nextLoopNumber = session.currentWave + 1;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      _TopHud(
                        sessionController: session,
                        onBack: () => _showExitDialog(context),
                        onTogglePause: game.togglePaused,
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GameWidget(
                                key: ValueKey(_gameEpoch),
                                game: game,
                              ),
                            ),
                            if (_hintBannerVisible &&
                                session.statusText.isNotEmpty)
                              Positioned(
                                top: 4,
                                left: 12,
                                right: isCompactBattlefield ? 12 : 164,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: _StatusBanner(
                                    text: session.statusText,
                                    maxWidth: isCompactBattlefield ? 336 : 392,
                                  ),
                                ),
                              ),
                            if (_towerActionBarVisible &&
                                session.selectedTower != null)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: _TowerActionBar(
                                  sessionController: session,
                                  onUpgrade: game.upgradeSelectedTower,
                                  onSell: game.sellSelectedTower,
                                  onClose: game.clearSelectedTower,
                                ),
                              ),
                            if (_towerActionBarVisible &&
                                session.selectedHero != null &&
                                !session.heroMoveMode)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: _HeroActionBar(
                                  sessionController: session,
                                  onMove: game.enterHeroMoveMode,
                                  onUpgrade: game.upgradeSelectedHero,
                                  onDeselect: game.clearSelectedHero,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _BuildBar(
                        sessionController: session,
                        metaUpgrades: activeMetaUpgrades,
                        chosenHeroKind: _chosenHeroKind ?? HeroKind.knight,
                        onSelect: game.selectBuildable,
                        onSelectBarrier: game.selectBarrierBuildable,
                        onSelectHero: game.selectHeroBuildable,
                        showWaveButton: showWaveButton,
                        nextWaveLabel: session.recoveryActive
                            ? '다음 ${session.loopLabel}'
                            : '${session.loopLabel} $nextLoopNumber 시작',
                        onStartWave: game.startNextWave,
                        waveInProgress: session.waveInProgress,
                        isPaused: session.isPaused,
                        onTogglePause: game.togglePaused,
                      ),
                    ],
                  ),
                  if ((_isBackgroundPaused || session.isPaused) &&
                      !session.stageCleared &&
                      !session.stageFailed)
                    Positioned.fill(
                      child: _PauseOverlay(
                        isBackground: _isBackgroundPaused,
                        onResume: () {
                          if (_isBackgroundPaused) {
                            game.resumeEngine();
                            setState(() => _isBackgroundPaused = false);
                          }
                          if (session.isPaused) {
                            game.togglePaused();
                          }
                        },
                      ),
                    ),
                  if (session.mustResolveRunOffer &&
                      !session.stageCleared &&
                      !session.stageFailed)
                    Positioned.fill(
                      child: _RunOfferOverlay(
                        state: session.runOfferFlowState,
                        offers: session.pendingRunOffers,
                        onRoll: game.rollRunOfferDice,
                        onAccept: game.acceptRunOffer,
                      ),
                    ),
                  if (session.stageCleared || session.stageFailed)
                    Positioned.fill(
                      child: _ResultOverlay(
                        sessionController: session,
                        completionResult: _completionResult,
                        immediateStarsAwarded: _immediateStarsAwarded,
                        stage: currentStage,
                        hasNextStage: _stageNumber < CampaignData.totalStages,
                        onRetry: () async {
                          await _chooseHero(force: true);
                          await _loadStage(_stageNumber);
                        },
                        onNextStage: () => _loadStage(
                          (_stageNumber + 1).clamp(1, CampaignData.totalStages),
                        ),
                        onReturnToCamp: widget.onExitToCamp,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RunOfferOverlay extends StatelessWidget {
  const _RunOfferOverlay({
    required this.state,
    required this.offers,
    required this.onRoll,
    required this.onAccept,
  });

  final RunOfferFlowState state;
  final List<RunOfferDefinition> offers;
  final Future<void> Function() onRoll;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.38),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF101820),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.casino_rounded,
                    color: Color(0xFFE4C67A),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '작전 주사위',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    state == RunOfferFlowState.awaitingChoice ? '1개 선택' : '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state == RunOfferFlowState.awaitingRoll)
                _RunOfferRollPrompt(onRoll: onRoll)
              else if (state == RunOfferFlowState.rolling)
                const _RunOfferRollingView()
              else
                for (final offer in offers) ...[
                  _RunOfferCard(offer: offer, onTap: () => onAccept(offer.id)),
                  if (offer != offers.last) const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RunOfferRollPrompt extends StatelessWidget {
  const _RunOfferRollPrompt({required this.onRoll});

  final Future<void> Function() onRoll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이번 STAGE의 전술을 굴려보세요.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRoll,
          icon: const Icon(Icons.casino_rounded),
          label: const Text('굴리기'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E8F74),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _RunOfferRollingView extends StatelessWidget {
  const _RunOfferRollingView();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, value, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF18232C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: value * math.pi * 4,
                child: Icon(
                  Icons.casino_rounded,
                  size: 42 + (math.sin(value * math.pi) * 8),
                  color: const Color(0xFFE4C67A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '굴리는 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunOfferCard extends StatelessWidget {
  const _RunOfferCard({required this.offer, required this.onTap});

  final RunOfferDefinition offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (offer.rarity) {
      RunOfferRarity.common => const Color(0xFF98D67C),
      RunOfferRarity.rare => const Color(0xFF7BC6FF),
      RunOfferRarity.epic => const Color(0xFFC07BFF),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.38)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChoiceDialog extends StatefulWidget {
  const _HeroChoiceDialog({this.initialKind});

  final HeroKind? initialKind;

  @override
  State<_HeroChoiceDialog> createState() => _HeroChoiceDialogState();
}

class _HeroChoiceDialogState extends State<_HeroChoiceDialog> {
  late HeroKind _selectedKind = widget.initialKind ?? HeroKind.knight;

  @override
  Widget build(BuildContext context) {
    final selected = HeroCatalog.byKind(_selectedKind);
    return AlertDialog(
      backgroundColor: const Color(0xFF101822),
      title: const Text('영웅을 선택하세요.', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hero in HeroCatalog.buildMenu)
                  ChoiceChip(
                    selected: hero.kind == _selectedKind,
                    label: Text(hero.label),
                    avatar: Icon(_heroIcon(hero.kind), size: 18),
                    onSelected: (_) =>
                        setState(() => _selectedKind = hero.kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected.color.withValues(alpha: 0.35),
                ),
              ),
              child: Image.asset(
                'assets/sprites/heroes/${HeroCatalog.heroId(selected.kind)}/south/base.png',
                height: 86,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) => Icon(
                  _heroIcon(selected.kind),
                  color: selected.color,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.label,
                    style: const TextStyle(
                      color: Color(0xFFE4C67A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected.shortDescription,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selected.abilityLabel}: ${selected.abilityDescription}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedKind),
          child: const Text('시작'),
        ),
      ],
    );
  }

  IconData _heroIcon(HeroKind kind) {
    return switch (kind) {
      HeroKind.knight => Icons.security_rounded,
      HeroKind.archer => Icons.gps_fixed_rounded,
      HeroKind.mage => Icons.auto_fix_high_rounded,
      HeroKind.ninja => Icons.flash_on_rounded,
      HeroKind.paladin => Icons.shield_moon_rounded,
    };
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.sessionController,
    required this.onBack,
    required this.onTogglePause,
  });

  final GameSessionController sessionController;
  final VoidCallback onBack;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width <= 420;
    final statsRow = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _HudChip(
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFFE4C67A),
          label: '${sessionController.coins}',
        ),
        _HudChip(
          icon: Icons.waves_rounded,
          color: Colors.white70,
          label:
              '${sessionController.loopLabel} ${sessionController.currentWave}/${sessionController.totalWaves}',
        ),
        if (sessionController.waveInProgress &&
            sessionController.remainingEnemies > 0)
          _HudChip(
            icon: Icons.groups_rounded,
            color: const Color(0xFFFF6B6B),
            label: '${sessionController.remainingEnemies}',
          ),
        _HudChip(
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF7BC6FF),
          label: 'STAGE ${sessionController.stageNumber}',
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _HudIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _HealthHud(
                        currentHealth: sessionController.baseHealth,
                        maxHealth: sessionController.maxBaseHealth,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _HudIconButton(
                      icon: sessionController.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      onPressed: onTogglePause,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: statsRow),
              ],
            )
          : Row(
              children: [
                _HudIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _HealthHud(
                    currentHealth: sessionController.baseHealth,
                    maxHealth: sessionController.maxBaseHealth,
                  ),
                ),
                const SizedBox(width: 6),
                statsRow,
                const SizedBox(width: 6),
                _HudIconButton(
                  icon: sessionController.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onPressed: onTogglePause,
                ),
              ],
            ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthHud extends StatelessWidget {
  const _HealthHud({required this.currentHealth, required this.maxHealth});

  final int currentHealth;
  final int maxHealth;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxHealth <= 0 ? 1 : maxHealth;
    final progress = (currentHealth / safeMax).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 17,
            color: Color(0xFF98D67C),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.white10),
                    FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8AD66E), Color(0xFFC1F08D)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$currentHealth/$maxHealth',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text, this.maxWidth = 460});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xD60A1018),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.campaign_rounded,
                size: 16,
                color: Color(0xFFE4C67A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildBar extends StatefulWidget {
  const _BuildBar({
    required this.sessionController,
    required this.metaUpgrades,
    required this.chosenHeroKind,
    required this.onSelect,
    required this.onSelectBarrier,
    required this.onSelectHero,
    this.showWaveButton = false,
    this.nextWaveLabel = '',
    this.onStartWave,
    this.waveInProgress = false,
    this.isPaused = false,
    this.onTogglePause,
  });

  final GameSessionController sessionController;
  final ResolvedMetaUpgrades metaUpgrades;
  final HeroKind chosenHeroKind;
  final ValueChanged<TowerKind?> onSelect;
  final ValueChanged<BarrierKind?> onSelectBarrier;
  final ValueChanged<HeroKind?> onSelectHero;
  final bool showWaveButton;
  final String nextWaveLabel;
  final VoidCallback? onStartWave;
  final bool waveInProgress;
  final bool isPaused;
  final VoidCallback? onTogglePause;

  @override
  State<_BuildBar> createState() => _BuildBarState();
}

enum _BuildTab { towers, barriers, hero }

class _BuildBarState extends State<_BuildBar> {
  TowerKind? _specKind;
  BarrierKind? _specBarrierKind;
  _BuildTab _activeTab = _BuildTab.towers;

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (widget.sessionController.selectedBuildable == null &&
        _specKind != null) {
      setState(() => _specKind = null);
    }
    if (widget.sessionController.selectedBarrierBuildable == null &&
        _specBarrierKind != null) {
      setState(() => _specBarrierKind = null);
    }
  }

  void _handleCardTap(TowerKind kind) {
    final alreadySelected = widget.sessionController.selectedBuildable == kind;
    setState(() {
      _specKind = alreadySelected ? null : kind;
      _specBarrierKind = null;
      _activeTab = _BuildTab.towers;
    });
    widget.onSelect(alreadySelected ? null : kind);
  }

  void _handleBarrierCardTap(BarrierKind kind) {
    final alreadySelected =
        widget.sessionController.selectedBarrierBuildable == kind;
    setState(() {
      _specBarrierKind = alreadySelected ? null : kind;
      _specKind = null;
      _activeTab = _BuildTab.barriers;
    });
    widget.onSelectBarrier(alreadySelected ? null : kind);
  }

  void _handleHeroCardTap() {
    setState(() {
      _activeTab = _BuildTab.hero;
      _specKind = null;
      _specBarrierKind = null;
    });
    widget.onSelectHero(widget.chosenHeroKind);
  }

  Widget _buildActionButton() {
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    const labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);

    if (widget.waveInProgress) {
      // 웨이브 진행 중: 일시정지 ↔ 재개 토글
      final isPaused = widget.isPaused;
      return FilledButton.icon(
        onPressed: widget.onTogglePause,
        style: FilledButton.styleFrom(
          backgroundColor: isPaused
              ? const Color(0xFF1C7E62)
              : const Color(0xFFB8760B),
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: buttonShape,
        ),
        icon: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          size: 18,
        ),
        label: Text(isPaused ? '재개' : '일시정지', style: labelStyle),
      );
    }

    if (widget.showWaveButton) {
      // 웨이브 시작 전: 다음 WAVE 시작
      return FilledButton.icon(
        onPressed: widget.onStartWave,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1C7E62),
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: buttonShape,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text(widget.nextWaveLabel, style: labelStyle),
      );
    }

    // 스테이지 종료 후: 빈 자리 유지 (레이아웃 유지)
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final entries = TowerCatalog.buildMenu;
    final barrierEntries = BarrierCatalog.buildMenu;
    final chosenHero = HeroCatalog.byKind(widget.chosenHeroKind);
    final specDef = _specKind != null
        ? entries.firstWhere((tower) => tower.kind == _specKind)
        : null;
    final specBarrier = _specBarrierKind != null
        ? barrierEntries.firstWhere(
            (barrier) => barrier.kind == _specBarrierKind,
          )
        : null;
    final specHero = _activeTab == _BuildTab.hero ? chosenHero : null;
    final canBuild = !widget.waveInProgress;
    final canReviveHero =
        canBuild &&
        widget.sessionController.recoveryActive &&
        widget.sessionController.heroReviveAvailable;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1720),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 76,
            child: _BuildSummaryStrip(
              definition: specDef,
              barrierDefinition: specBarrier,
              heroDefinition: specHero,
              sessionController: widget.sessionController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _BuildTabSelector(
              activeTab: _activeTab,
              onChanged: (tab) {
                setState(() {
                  _activeTab = tab;
                  _specKind = null;
                  _specBarrierKind = null;
                });
                widget.onSelect(null);
                widget.onSelectBarrier(null);
                widget.onSelectHero(null);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_activeTab == _BuildTab.towers)
                    for (final tower in entries) ...[
                      _BuildCard(
                        tower: tower,
                        sessionController: widget.sessionController,
                        isUnlocked:
                            canBuild && tower.isUnlocked(widget.metaUpgrades),
                        isSelected:
                            widget.sessionController.selectedBuildable ==
                            tower.kind,
                        onPressed: () => _handleCardTap(tower.kind),
                      ),
                      const SizedBox(width: 12),
                    ],
                  if (_activeTab == _BuildTab.barriers)
                    for (final barrier in barrierEntries) ...[
                      _BarrierBuildCard(
                        barrier: barrier,
                        sessionController: widget.sessionController,
                        isEnabled: canBuild,
                        isSelected:
                            widget.sessionController.selectedBarrierBuildable ==
                            barrier.kind,
                        onPressed: () => _handleBarrierCardTap(barrier.kind),
                      ),
                      const SizedBox(width: 12),
                    ],
                  if (_activeTab == _BuildTab.hero) ...[
                    _HeroBuildCard(
                      hero: chosenHero,
                      isUnlocked: canReviveHero,
                      isSelected: false,
                      onPressed: canReviveHero ? _handleHeroCardTap : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: _buildActionButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildTabSelector extends StatelessWidget {
  const _BuildTabSelector({required this.activeTab, required this.onChanged});

  final _BuildTab activeTab;
  final ValueChanged<_BuildTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_BuildTab>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF1C7E62);
          }
          return const Color(0xFF161D26);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white70;
        }),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.white12)),
      ),
      segments: const [
        ButtonSegment(
          value: _BuildTab.towers,
          icon: Icon(Icons.account_balance_rounded, size: 16),
          label: Text('타워'),
        ),
        ButtonSegment(
          value: _BuildTab.barriers,
          icon: Icon(Icons.fence_rounded, size: 16),
          label: Text('성벽'),
        ),
        ButtonSegment(
          value: _BuildTab.hero,
          icon: Icon(Icons.person_rounded, size: 16),
          label: Text('영웅'),
        ),
      ],
      selected: {activeTab},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _BuildSummaryStrip extends StatelessWidget {
  const _BuildSummaryStrip({
    required this.definition,
    required this.sessionController,
    this.barrierDefinition,
    this.heroDefinition,
  });

  final TowerDefinition? definition;
  final GameSessionController sessionController;
  final BarrierDefinition? barrierDefinition;
  final HeroDefinition? heroDefinition;

  @override
  Widget build(BuildContext context) {
    final hero = heroDefinition;
    if (hero != null) {
      return _HeroCardSummary(
        definition: hero,
        sessionController: sessionController,
      );
    }
    final barrier = barrierDefinition;
    if (barrier != null) {
      return _BarrierCardSummary(
        definition: barrier,
        sessionController: sessionController,
      );
    }
    if (definition == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1018),
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '배치할 타워 카드를 선택해 역할을 미리 확인하세요.',
              style: TextStyle(
                color: Color(0xFFE4C67A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '아래 카드를 탭하여 비용, 사거리, 피해량, 속도를 확인하세요.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return _TowerCardSummary(
      definition: definition!,
      sessionController: sessionController,
    );
  }
}

class _TowerCardSummary extends StatelessWidget {
  const _TowerCardSummary({
    required this.definition,
    required this.sessionController,
  });

  final TowerDefinition definition;
  final GameSessionController sessionController;

  String _rating(double value, double max) {
    final score = ((value / max) * 5).clamp(0.0, 5.0);
    final rounded = (score * 2).round() / 2;
    return rounded == rounded.truncateToDouble()
        ? '${rounded.toInt()}/5'
        : '${rounded.toStringAsFixed(1)}/5';
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = sessionController.runModifiers;
    final range =
        definition.range * modifiers.towerRangeMultiplier(definition.kind);
    final damage =
        definition.damage * modifiers.towerDamageMultiplier(definition.kind);
    final cooldown =
        definition.cooldown *
        modifiers.towerCooldownMultiplier(definition.kind);
    final rangeRating = _rating(range, 175);
    final damageRating = _rating(damage, 58);
    final speedRating = definition.cooldown > 0
        ? _rating(1 / cooldown, 1 / 0.85)
        : '5/5';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1018),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                definition.label,
                style: const TextStyle(
                  color: Color(0xFFE4C67A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _SpecMetric(label: '사거리', value: rangeRating),
                      const _SpecDot(),
                      _SpecMetric(label: '피해량', value: damageRating),
                      const _SpecDot(),
                      _SpecMetric(label: '속도', value: speedRating),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            definition.shortDescription,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeroCardSummary extends StatelessWidget {
  const _HeroCardSummary({
    required this.definition,
    required this.sessionController,
  });

  final HeroDefinition definition;
  final GameSessionController sessionController;

  String _rating(double value, double max) {
    final score = ((value / max) * 5).clamp(0.0, 5.0);
    return '${score.round().clamp(1, 5)}/5';
  }

  @override
  Widget build(BuildContext context) {
    final rangeRating = _rating(definition.range, 150);
    final damageRating = _rating(
      definition.damage *
          sessionController.runModifiers.heroDamageMultiplier(definition.kind),
      42,
    );
    final speedRating = _rating(1 / definition.cooldown, 1 / 0.48);
    final hp = sessionController.chosenHeroHitPoints.round();
    final maxHp = sessionController.chosenHeroMaxHitPoints.round();
    final status = sessionController.chosenHeroAlive
        ? '전장 배치됨 HP $hp/$maxHp'
        : sessionController.heroReviveAvailable
        ? '사망 - 회복창에서 1회 무료 부활 가능'
        : '부활 사용 완료';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1018),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                definition.label,
                style: const TextStyle(
                  color: Color(0xFFE4C67A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _SpecMetric(label: '사거리', value: rangeRating),
                      const _SpecDot(),
                      _SpecMetric(label: '피해량', value: damageRating),
                      const _SpecDot(),
                      _SpecMetric(label: '속도', value: speedRating),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$status · ${definition.shortDescription}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BarrierCardSummary extends StatelessWidget {
  const _BarrierCardSummary({
    required this.definition,
    required this.sessionController,
  });

  final BarrierDefinition definition;
  final GameSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final modifiers = sessionController.runModifiers;
    final hitPoints =
        (definition.hitPoints *
                modifiers.barrierHitPointMultiplier(definition.kind))
            .round();
    final repairCost =
        (definition.repairCost *
                modifiers.barrierRepairCostMultiplier(definition.kind))
            .round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1018),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                definition.label,
                style: const TextStyle(
                  color: Color(0xFFE4C67A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              _SpecMetric(label: 'HP', value: '$hitPoints'),
              const _SpecDot(),
              _SpecMetric(label: '수리', value: '$repairCost'),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '적 이동을 막습니다. 모든 경로가 막히면 적이 성벽을 파괴합니다.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SpecMetric extends StatelessWidget {
  const _SpecMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: const TextStyle(
        color: Color(0xFFE4C67A),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SpecDot extends StatelessWidget {
  const _SpecDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '\u00b7',
        style: TextStyle(color: Colors.white30, fontSize: 12),
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.tower,
    required this.sessionController,
    required this.isUnlocked,
    required this.isSelected,
    required this.onPressed,
  });

  final TowerDefinition tower;
  final GameSessionController sessionController;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cost =
        (tower.cost *
                sessionController.runModifiers.towerCostMultiplier(tower.kind))
            .round();
    return InkWell(
      onTap: isUnlocked ? onPressed : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 104,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D2E1C) : const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF98D67C).withValues(alpha: 0.6)
                : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _towerIcon(tower.kind),
              color: isUnlocked
                  ? (isSelected ? const Color(0xFF98D67C) : tower.color)
                  : Colors.white24,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              tower.label,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$cost',
              style: TextStyle(
                color: isUnlocked ? const Color(0xFFE4C67A) : Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _towerIcon(TowerKind kind) {
    return switch (kind) {
      TowerKind.archer => Icons.gps_fixed_rounded,
      TowerKind.guardBarracks => Icons.shield_rounded,
      TowerKind.mageObelisk => Icons.auto_awesome_rounded,
      TowerKind.frostShrine => Icons.ac_unit_rounded,
      TowerKind.coinMill => Icons.monetization_on_rounded,
      TowerKind.ballista => Icons.architecture_rounded,
      TowerKind.emberkeep => Icons.local_fire_department_rounded,
    };
  }
}

class _BarrierBuildCard extends StatelessWidget {
  const _BarrierBuildCard({
    required this.barrier,
    required this.sessionController,
    required this.isEnabled,
    required this.isSelected,
    required this.onPressed,
  });

  final BarrierDefinition barrier;
  final GameSessionController sessionController;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cost =
        (barrier.cost *
                sessionController.runModifiers.barrierCostMultiplier(
                  barrier.kind,
                ))
            .round();
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 104,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B261B) : const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE4C67A).withValues(alpha: 0.7)
                : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _barrierIcon(barrier.kind),
              color: isEnabled ? barrier.color : Colors.white24,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              barrier.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$cost',
              style: TextStyle(
                color: isEnabled ? const Color(0xFFE4C67A) : Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _barrierIcon(BarrierKind kind) {
    return switch (kind) {
      BarrierKind.woodFence => Icons.fence_rounded,
      BarrierKind.stoneWall => Icons.grid_view_rounded,
      BarrierKind.reinforcedWall => Icons.account_balance_rounded,
      BarrierKind.gate => Icons.door_front_door_rounded,
    };
  }
}

class _HeroBuildCard extends StatelessWidget {
  const _HeroBuildCard({
    required this.hero,
    required this.isUnlocked,
    required this.isSelected,
    required this.onPressed,
  });

  final HeroDefinition hero;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUnlocked ? onPressed : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 104,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C2733) : const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? hero.color.withValues(alpha: 0.68)
                : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _heroIcon(hero.kind),
              color: isUnlocked
                  ? (isSelected ? const Color(0xFFE4C67A) : hero.color)
                  : Colors.white24,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              hero.label,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked ? '무료 부활' : '대기',
              style: TextStyle(
                color: isUnlocked ? const Color(0xFFE4C67A) : Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _heroIcon(HeroKind kind) {
    return switch (kind) {
      HeroKind.knight => Icons.security_rounded,
      HeroKind.archer => Icons.gps_fixed_rounded,
      HeroKind.mage => Icons.auto_fix_high_rounded,
      HeroKind.ninja => Icons.flash_on_rounded,
      HeroKind.paladin => Icons.shield_moon_rounded,
    };
  }
}

class _TowerActionBar extends StatelessWidget {
  const _TowerActionBar({
    required this.sessionController,
    required this.onUpgrade,
    required this.onSell,
    required this.onClose,
  });

  final GameSessionController sessionController;
  final VoidCallback onUpgrade;
  final VoidCallback onSell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tower = sessionController.selectedTower;
    if (tower == null) {
      return const SizedBox.shrink();
    }

    final subtitle = tower.branchLabel ?? tower.shortDescription;
    final economyIncome = tower.economyIncomePerTick;
    final economyInterval = tower.economyInterval;
    final economyPerSecond = tower.economyIncomePerSecond;
    final economyBreakEven = tower.economyBreakEvenSeconds;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF2161D26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tower.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: tower.canUpgrade ? onUpgrade : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: Text('${tower.upgradeCost}'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '판매',
                onPressed: onSell,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x22EF4E4E),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4E4E),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: '닫기',
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tower.abilityDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (economyIncome != null &&
              economyInterval != null &&
              economyPerSecond != null &&
              economyBreakEven != null) ...[
            const SizedBox(height: 8),
            Text(
              '수익 $economyIncome/${economyInterval.toStringAsFixed(1)}초 · 초당 ${economyPerSecond.toStringAsFixed(2)}골드 · 회수 약 ${economyBreakEven.round()}초 · WAVE 보너스 +${tower.economyCycleBonus ?? 0}',
              style: const TextStyle(color: Color(0xFFE4C67A), fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroActionBar extends StatelessWidget {
  const _HeroActionBar({
    required this.sessionController,
    required this.onMove,
    required this.onUpgrade,
    required this.onDeselect,
  });

  final GameSessionController sessionController;
  final VoidCallback onMove;
  final VoidCallback onUpgrade;
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) {
    final hero = sessionController.selectedHero;
    if (hero == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF2161D26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${hero.label} Lv.${hero.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: onDeselect,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x22EF4E4E),
                  minimumSize: const Size(40, 40),
                ),
                icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4E4E)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${hero.abilityLabel}: ${hero.abilityDescription}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.18,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onMove,
                icon: const Icon(Icons.open_with_rounded, size: 16),
                label: const Text('이동'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: hero.canUpgrade ? onUpgrade : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: Text('${hero.upgradeCost}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.sessionController,
    required this.completionResult,
    required this.immediateStarsAwarded,
    required this.stage,
    required this.hasNextStage,
    required this.onRetry,
    required this.onNextStage,
    required this.onReturnToCamp,
  });

  final GameSessionController sessionController;
  final StageCompletionResult? completionResult;
  final int? immediateStarsAwarded;
  final StageProgressSnapshot stage;
  final bool hasNextStage;
  final VoidCallback onRetry;
  final VoidCallback onNextStage;
  final VoidCallback onReturnToCamp;

  @override
  Widget build(BuildContext context) {
    final cleared = sessionController.stageCleared;

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cleared ? Icons.emoji_events_rounded : Icons.cancel_rounded,
              size: 64,
              color: cleared
                  ? const Color(0xFFE4C67A)
                  : const Color(0xFFEF4E4E),
            ),
            const SizedBox(height: 16),
            Text(
              cleared ? 'STAGE 클리어' : 'STAGE 실패',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'STAGE ${stage.stageNumber}',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (cleared) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i += 1)
                    Icon(
                      Icons.star_rounded,
                      color:
                          (completionResult?.starsAwarded ??
                                  immediateStarsAwarded ??
                                  0) >
                              i
                          ? const Color(0xFFE4C67A)
                          : Colors.white10,
                      size: 32,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _RewardRow(
                label: '메타 골드',
                value: '+${completionResult?.softCurrencyAwarded ?? 0}',
              ),
              const SizedBox(height: 8),
              _RewardRow(
                label: '기지 체력',
                value:
                    '${sessionController.baseHealth}/${sessionController.maxBaseHealth}',
              ),
            ],
            const SizedBox(height: 24),
            if (cleared && hasNextStage)
              _LargeButton(
                label: '다음 STAGE',
                color: const Color(0xFF98D67C),
                onPressed: onNextStage,
              ),
            if (cleared && hasNextStage) const SizedBox(height: 12),
            _LargeButton(
              label: '다시 도전',
              color: const Color(0xFF486581),
              onPressed: onRetry,
            ),
            const SizedBox(height: 12),
            _LargeButton(
              label: '캠프로 돌아가기',
              color: Colors.transparent,
              onPressed: onReturnToCamp,
              isOutline: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.isBackground, required this.onResume});

  final bool isBackground;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              size: 56,
              color: Color(0xFFE4C67A),
            ),
            const SizedBox(height: 16),
            const Text(
              '일시정지',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBackground
                  ? '앱이 백그라운드로 이동했습니다.\n재개하려면 아래 버튼을 눌러주세요.'
                  : '게임이 일시정지되었습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onResume,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7E62),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  '재개',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE4C67A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  const _LargeButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isOutline = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isOutline;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutline ? Border.all(color: Colors.white24) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isOutline ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
