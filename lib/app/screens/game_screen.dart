import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
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

      if (!mounted) {
        return;
      }

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
        child: AnimatedBuilder(
          animation: _sessionController,
          builder: (context, _) {
            final session = _sessionController;
            final showWaveButton =
                !session.waveInProgress &&
                !session.stageCleared &&
                !session.stageFailed &&
                session.currentWave < session.totalWaves;
            final waveButtonBottom = session.selectedTower != null
                ? 112.0
                : 16.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    _TopHud(
                      sessionController: session,
                      onBack: () => _confirmExit(context),
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
                          Positioned(
                            top: 12,
                            left: 16,
                            right: 16,
                            child: _StatusBanner(text: session.statusText),
                          ),
                          if (showWaveButton)
                            Positioned(
                              right: 16,
                              bottom: waveButtonBottom,
                              child: _WaveButton(
                                waveNumber: session.currentWave + 1,
                                onPressed: game.startNextWave,
                              ),
                            ),
                          if (session.selectedTower != null)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: _TowerActionBar(
                                sessionController: session,
                                onUpgrade: game.upgradeSelectedTower,
                                onSell: game.sellSelectedTower,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _BuildBar(
                      sessionController: session,
                      metaUpgrades: activeMetaUpgrades,
                      onSelect: game.selectBuildable,
                    ),
                  ],
                ),
                if (session.stageCleared || session.stageFailed)
                  Positioned.fill(
                    child: _ResultOverlay(
                      sessionController: session,
                      completionResult: _completionResult,
                      stage: currentStage,
                      hasNextStage: _stageNumber < CampaignData.totalStages,
                      onRetry: () => _loadStage(_stageNumber),
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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.64), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          _HudIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack),
          const SizedBox(width: 8),
          Expanded(
            child: _HealthHud(
              currentHealth: sessionController.baseHealth,
              maxHealth: sessionController.maxBaseHealth,
            ),
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFE4C67A),
            label: '${sessionController.coins}',
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: Icons.waves_rounded,
            color: Colors.white70,
            label:
                'Wave ${sessionController.currentWave}/${sessionController.totalWaves}',
          ),
          const SizedBox(width: 8),
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
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white70, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              fontSize: 13,
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
            size: 18,
            color: Color(0xFF98D67C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xCC0A1018),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 18,
                color: Color(0xFFE4C67A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2519).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF98D67C).withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF98D67C).withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Color(0xFF98D67C)),
              const SizedBox(width: 8),
              Text(
                'Wave $waveNumber 출격!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
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
        ? entries.firstWhere((tower) => tower.kind == _specKind)
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
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: specDef != null ? 84 : 0,
            child: specDef != null
                ? _TowerSpecPanel(definition: specDef)
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
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

  String _rating(double value, double max) {
    final score = ((value / max) * 5).clamp(0.0, 5.0);
    final rounded = (score * 2).round() / 2;
    return rounded == rounded.truncateToDouble()
        ? '${rounded.toInt()}/5'
        : '${rounded.toStringAsFixed(1)}/5';
  }

  @override
  Widget build(BuildContext context) {
    final rangeRating = _rating(definition.range, 175);
    final damageRating = _rating(definition.damage, 58);
    final speedRating = definition.cooldown > 0
        ? _rating(1 / definition.cooldown, 1 / 0.85)
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
                      _SpecMetric(label: '공격', value: damageRating),
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
      child: Text('·', style: TextStyle(color: Colors.white30, fontSize: 12)),
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
              '${tower.cost}',
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
    if (tower == null) {
      return const SizedBox.shrink();
    }

    final subtitle = tower.branchLabel != null
        ? '레벨 ${tower.level} · ${tower.branchLabel}'
        : '레벨 ${tower.level} · ${tower.shortDescription}';

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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tower.abilityDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              cleared ? '스테이지 클리어' : '스테이지 실패',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stage ${stage.stageNumber}',
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
              for (final objective in completionResult?.objectives ?? const [])
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
                      Expanded(
                        child: Text(
                          _localizeObjective(objective.label),
                          style: TextStyle(
                            color: objective.completed
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            if (cleared && hasNextStage)
              _LargeButton(
                label: '다음 Stage',
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

  String _localizeObjective(String label) {
    if (label.contains('Clear the stage')) {
      return '스테이지 클리어';
    }
    if (label.contains('Defeat the Bastion Overlord')) {
      return '기갑 군주 처치';
    }
    if (label.contains('Do not sell any towers')) {
      return '타워 판매 금지';
    }
    final healthMatch = RegExp(
      r'Finish with at least (\d+) base health',
    ).firstMatch(label);
    if (healthMatch != null) {
      return '기지 체력 ${healthMatch.group(1)} 이상으로 완료';
    }
    if (label.contains('Build an Archer')) {
      return '궁수 건설';
    }
    if (label.contains('Build a Guard Barracks')) {
      return '병영 건설';
    }
    if (label.contains('Build a Mage tower')) {
      return '마법사 건설';
    }
    if (label.contains('Build a Frost tower')) {
      return '빙결 건설';
    }
    if (label.contains('Build a Coin Mill')) {
      return '금화 방앗간 건설';
    }
    if (label.contains('Build a Ballista')) {
      return '발리스타 건설';
    }
    if (label.contains('Build an Emberkeep')) {
      return '엠버킵 건설';
    }
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
