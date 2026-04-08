import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
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

class _GameScreenState extends State<GameScreen> {
  late final GameSessionController _sessionController;
  DefensePrototypeGame? _game;
  CampaignOverview? _overview;
  StageCompletionResult? _completionResult;
  late int _stageNumber;
  int _gameEpoch = 0;
  bool _isEvaluating = false;
  ResolvedMetaUpgrades? _activeMetaUpgrades;

  @override
  void initState() {
    super.initState();
    _stageNumber = widget.initialStageNumber;
    _sessionController = GameSessionController();
    _sessionController.addListener(_handleSessionChanged);
    _initialize();
  }

  @override
  void dispose() {
    _sessionController.removeListener(_handleSessionChanged);
    super.dispose();
  }

  Future<void> _initialize() async {
    await _refreshOverview();
    await _loadStage(_stageNumber);
  }

  Future<void> _refreshOverview() async {
    final overview = await widget.bootstrap.progressStore.loadCampaignOverview(
      totalStages: CampaignData.totalStages,
    );
    if (!mounted) return;
    setState(() => _overview = overview);
  }

  Future<void> _loadStage(int stageNumber) async {
    // Ensure we have current overview
    final overview =
        _overview ??
        await widget.bootstrap.progressStore.loadCampaignOverview(
          totalStages: CampaignData.totalStages,
        );

    final resolvedMeta = MetaUpgradeCatalog.resolve(overview.metaUpgrades);
    final stage = CampaignData.stage(stageNumber);

    if (!mounted) return;
    setState(() {
      _activeMetaUpgrades = resolvedMeta;
      _stageNumber = stageNumber;
      _completionResult = null;
      _isEvaluating = false;
      _gameEpoch += 1;
      _game = DefensePrototypeGame(
        stage: stage,
        sessionController: _sessionController,
        audioService: widget.bootstrap.audioService,
        metaUpgrades: resolvedMeta,
      );
    });
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161D26),
        title: const Text('게임 종료', style: TextStyle(color: Colors.white)),
        content: const Text(
          '캠프로 돌아가시겠습니까?\n진행 중인 웨이브는 저장되지 않습니다.',
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
    if (game == null) return;

    // Only proceed if stage ended and we aren't already evaluating
    if ((_sessionController.stageCleared || _sessionController.stageFailed) &&
        !_isEvaluating &&
        _completionResult == null) {
      _isEvaluating = true;
      final evaluation = game.evaluateCurrentRun();

      final result = await widget.bootstrap.progressStore.recordStageCompletion(
        stageNumber: _sessionController.stageNumber,
        evaluation: evaluation,
        totalStages: CampaignData.totalStages,
      );

      await _refreshOverview();

      if (!mounted) return;
      setState(() {
        _completionResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final overview = _overview;

    if (game == null || overview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStage = overview.stages[_stageNumber - 1];
    final activeMetaUpgrades =
        _activeMetaUpgrades ??
        MetaUpgradeCatalog.resolve(overview.metaUpgrades);

    return Scaffold(
      backgroundColor: const Color(0xFF071B2F),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Game World ──
            GameWidget(key: ValueKey(_gameEpoch), game: game),

            // ── UI Overlay ──
            AnimatedBuilder(
              animation: _sessionController,
              builder: (context, _) {
                return Stack(
                  children: [
                    // TOP BAR HUD
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopHud(
                        sessionController: _sessionController,
                        onBack: () => _confirmExit(context),
                        onTogglePause: game.togglePaused,
                      ),
                    ),

                    // FLOATING WAVE BUTTON
                    if (!_sessionController.waveInProgress &&
                        !_sessionController.stageCleared &&
                        !_sessionController.stageFailed)
                      Positioned(
                        bottom: 140,
                        right: 16,
                        child: _WaveButton(
                          waveNumber: _sessionController.currentWave + 1,
                          onPressed: game.startNextWave,
                        ),
                      ),

                    // BUILD BAR (BOTTOM)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BuildHint(statusText: _sessionController.statusText),
                          _BuildBar(
                            sessionController: _sessionController,
                            metaUpgrades: activeMetaUpgrades,
                            onSelect: game.selectBuildable,
                          ),
                        ],
                      ),
                    ),

                    // SELECTED TOWER ACTION BAR
                    if (_sessionController.selectedTower != null)
                      Positioned(
                        bottom: 130,
                        left: 16,
                        right: 16,
                        child: _TowerActionBar(
                          sessionController: _sessionController,
                          onUpgrade: game.upgradeSelectedTower,
                          onSell: game.sellSelectedTower,
                        ),
                      ),
                  ],
                );
              },
            ),

            // RESULT OVERLAY
            if (_sessionController.stageCleared ||
                _sessionController.stageFailed)
              _ResultOverlay(
                sessionController: _sessionController,
                completionResult: _completionResult,
                stage: currentStage,
                hasNextStage: _stageNumber < CampaignData.totalStages,
                onRetry: () => _loadStage(_stageNumber),
                onNextStage: () => _loadStage(
                  (_stageNumber + 1).clamp(1, CampaignData.totalStages),
                ),
                onReturnToCamp: widget.onExitToCamp,
              ),
          ],
        ),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 4),
          // HP
          _StatIconItem(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF98D67C),
            value:
                '${sessionController.baseHealth}/${sessionController.maxBaseHealth}',
            isBar: true,
            progress:
                sessionController.baseHealth / sessionController.maxBaseHealth,
          ),
          const Spacer(),
          // Coins
          _StatIconItem(
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFE4C67A),
            value: '${sessionController.coins}',
          ),
          const SizedBox(width: 12),
          // Wave
          _StatIconItem(
            icon: Icons.waves_rounded,
            color: Colors.white70,
            value:
                '${sessionController.currentWave}/${sessionController.totalWaves}',
          ),
          const SizedBox(width: 12),
          // Speed/Bug icon as per original
          const Icon(
            Icons.bug_report_rounded,
            size: 18,
            color: Color(0xFFEF4E4E),
          ),
          const SizedBox(width: 4),
          Text(
            '0',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _SmallButton(label: '1x', onPressed: () {}),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTogglePause,
            icon: Icon(
              sessionController.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatIconItem extends StatelessWidget {
  const _StatIconItem({
    required this.icon,
    required this.color,
    required this.value,
    this.isBar = false,
    this.progress = 1.0,
  });

  final IconData icon;
  final Color color;
  final String value;
  final bool isBar;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (isBar) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Stack(
            children: [
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100 * progress.clamp(0.0, 1.0),
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WaveButton extends StatelessWidget {
  const _WaveButton({required this.waveNumber, required this.onPressed});
  final int waveNumber;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2519).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF98D67C).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF98D67C).withValues(alpha: 0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Color(0xFF98D67C)),
            const SizedBox(width: 8),
            Text(
              '웨이브 $waveNumber 출격!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildHint extends StatelessWidget {
  const _BuildHint({required this.statusText});
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BuildBar extends StatefulWidget {
  const _BuildBar({
    required this.sessionController,
    required this.metaUpgrades,
    required this.onSelect,
  });

  final GameSessionController sessionController;
  final ResolvedMetaUpgrades metaUpgrades;
  final ValueChanged<TowerKind?> onSelect;

  @override
  State<_BuildBar> createState() => _BuildBarState();
}

class _BuildBarState extends State<_BuildBar> {
  TowerKind? _specKind;

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
  }

  void _handleCardTap(TowerKind kind) {
    final alreadySelected = widget.sessionController.selectedBuildable == kind;
    setState(() => _specKind = alreadySelected ? null : kind);
    widget.onSelect(alreadySelected ? null : kind);
  }

  @override
  Widget build(BuildContext context) {
    final entries = TowerCatalog.buildMenu;
    final specDef = _specKind != null
        ? entries.firstWhere((t) => t.kind == _specKind)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1720),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: specDef != null ? 72 : 0,
            child: specDef != null
                ? _TowerSpecPanel(definition: specDef)
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tower in entries) ...[
                    _BuildCard(
                      tower: tower,
                      isUnlocked: tower.isUnlocked(widget.metaUpgrades),
                      isSelected:
                          widget.sessionController.selectedBuildable ==
                          tower.kind,
                      onPressed: () => _handleCardTap(tower.kind),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerSpecPanel extends StatelessWidget {
  const _TowerSpecPanel({required this.definition});

  final TowerDefinition definition;

  String _koreanName(TowerKind kind) {
    return switch (kind) {
      TowerKind.archer => '궁수',
      TowerKind.guardBarracks => '병영',
      TowerKind.mageObelisk => '마법사',
      TowerKind.frostShrine => '빙결',
      TowerKind.coinMill => '금화 방앗간',
      TowerKind.ballista => '발리스타',
      TowerKind.emberkeep => '화염 요새',
    };
  }

  String _rating(double value, double max) {
    final score = ((value / max) * 5).clamp(0.0, 5.0);
    final rounded = (score * 2).round() / 2;
    if (rounded == rounded.truncateToDouble()) {
      return '${rounded.toInt()}/5';
    }
    return '${rounded.toStringAsFixed(1)}/5';
  }

  @override
  Widget build(BuildContext context) {
    final rangeRating = _rating(definition.range, 175);
    final dmgRating = _rating(definition.damage, 58);
    final spdRating = definition.cooldown > 0
        ? _rating(1 / definition.cooldown, 1 / 0.85)
        : '5/5';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1018),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '[${_koreanName(definition.kind)}]',
                style: const TextStyle(
                  color: Color(0xFFE4C67A),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '사거리 $rangeRating',
                      style: const TextStyle(
                        color: Color(0xFFE4C67A),
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                    Text(
                      '공격 $dmgRating',
                      style: const TextStyle(
                        color: Color(0xFFE4C67A),
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                    Text(
                      '속도 $spdRating',
                      style: const TextStyle(
                        color: Color(0xFFE4C67A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            definition.shortDescription,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.tower,
    required this.isUnlocked,
    required this.isSelected,
    required this.onPressed,
  });

  final TowerDefinition tower;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final name = _koreanName(tower.kind);
    final icon = _towerIcon(tower.kind);

    return InkWell(
      onTap: isUnlocked ? onPressed : null,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D2E1C) : const Color(0xFF161D26),
          borderRadius: BorderRadius.circular(12),
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
              icon,
              color: isUnlocked
                  ? (isSelected ? const Color(0xFF98D67C) : tower.color)
                  : Colors.white24,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${tower.cost}',
              style: TextStyle(
                color: isUnlocked ? const Color(0xFFE4C67A) : Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _koreanName(TowerKind kind) {
    return switch (kind) {
      TowerKind.archer => '궁수',
      TowerKind.guardBarracks => '병영',
      TowerKind.mageObelisk => '마법사',
      TowerKind.frostShrine => '빙결',
      TowerKind.coinMill => '금화',
      TowerKind.ballista => '발리스타',
      TowerKind.emberkeep => '화염',
    };
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

class _TowerActionBar extends StatelessWidget {
  const _TowerActionBar({
    required this.sessionController,
    required this.onUpgrade,
    required this.onSell,
  });

  final GameSessionController sessionController;
  final VoidCallback onUpgrade;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final tower = sessionController.selectedTower;
    if (tower == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161D26).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '레벨 ${tower.level} · ${tower.shortDescription}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: tower.canUpgrade ? onUpgrade : null,
            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
            label: Text('${tower.upgradeCost}'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSell,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4E4E),
            ),
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
    required this.stage,
    required this.hasNextStage,
    required this.onRetry,
    required this.onNextStage,
    required this.onReturnToCamp,
  });

  final GameSessionController sessionController;
  final StageCompletionResult? completionResult;
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
              cleared ? '스테이지 클리어!' : '스테이지 실패',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (cleared) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      color: (completionResult?.starsAwarded ?? 0) > i
                          ? const Color(0xFFE4C67A)
                          : Colors.white10,
                      size: 32,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _RewardRow(
                label: '경험치',
                value: '+${completionResult?.xpAwarded ?? 0}',
              ),
              _RewardRow(
                label: '메타 골드',
                value: '+${completionResult?.softCurrencyAwarded ?? 0}',
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              for (final objective in completionResult?.objectives ?? [])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        objective.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: objective.completed
                            ? const Color(0xFF98D67C)
                            : Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizeObjective(objective.label),
                        style: TextStyle(
                          color: objective.completed
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            if (cleared && hasNextStage)
              _LargeButton(
                label: '다음 스테이지',
                color: const Color(0xFF98D67C),
                onPressed: onNextStage,
              ),
            const SizedBox(height: 12),
            _LargeButton(
              label: '다시 시도',
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

  String _localizeObjective(String label) {
    if (label.contains('Clear the stage')) return '스테이지 클리어';
    if (label.contains('Defeat the Bastion Overlord')) return '기지 영주 처치';
    if (label.contains('Do not sell any towers')) return '타워 판매 금지';
    // "Finish with at least X base health" → dynamic threshold
    final healthMatch = RegExp(
      r'Finish with at least (\d+) base health',
    ).firstMatch(label);
    if (healthMatch != null) return '기지 체력 ${healthMatch.group(1)} 이상으로 완료';
    // Build specific tower
    if (label.contains('Build an Archer')) return '궁수 건설';
    if (label.contains('Build a Guard Barracks')) return '병영 건설';
    if (label.contains('Build a Mage tower')) return '마법사 건설';
    if (label.contains('Build a Frost tower')) return '빙결탑 건설';
    if (label.contains('Build a Coin Mill')) return '금화탑 건설';
    if (label.contains('Build a Ballista')) return '발리스타 건설';
    if (label.contains('Build an Emberkeep')) return '화염탑 건설';
    return label;
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
