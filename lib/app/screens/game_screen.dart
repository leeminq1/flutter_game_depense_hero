import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/meta_upgrades_screen.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/sample/sample_campaign.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.bootstrap,
    this.initialStageNumber = 1,
  });

  final AppBootstrap bootstrap;
  final int initialStageNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameSessionController _sessionController;
  DefensePrototypeGame? _game;
  CampaignOverview? _overview;
  StageCompletionResult? _completionResult;
  bool _rewardClaimed = false;
  String? _rewardMessage;
  late int _stageNumber;
  int _gameEpoch = 0;
  bool _completionRecording = false;
  ResolvedMetaUpgrades? _activeMetaUpgrades;
  final Set<int> _dismissedTutorialStages = {};
  bool _tutorialDismissed = false;

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
    _tutorialDismissed = await widget.bootstrap.progressStore
        .isTutorialDismissed();
    await _refreshOverview();
    await _loadStage(_stageNumber);
  }

  Future<void> _refreshOverview() async {
    final overview = await widget.bootstrap.progressStore.loadCampaignOverview(
      totalStages: SampleCampaign.totalStages,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _overview = overview;
    });
  }

  Future<void> _loadStage(int stageNumber) async {
    final currentOverview =
        _overview ??
        await widget.bootstrap.progressStore.loadCampaignOverview(
          totalStages: SampleCampaign.totalStages,
        );
    final resolvedMeta = MetaUpgradeCatalog.resolve(
      currentOverview.metaUpgrades,
    );
    final stage = SampleCampaign.stage(stageNumber);
    final rewardClaimed = await widget.bootstrap.progressStore
        .hasClaimedStageClearBonus(stageNumber);
    if (!mounted) {
      return;
    }
    setState(() {
      _activeMetaUpgrades = resolvedMeta;
      _stageNumber = stageNumber;
      _completionResult = null;
      _rewardMessage = null;
      _rewardClaimed = rewardClaimed;
      _completionRecording = false;
      _gameEpoch += 1;
      _game = DefensePrototypeGame(
        stage: stage,
        sessionController: _sessionController,
        audioService: widget.bootstrap.audioService,
        metaUpgrades: resolvedMeta,
      );
    });
  }

  Future<void> _handleSessionChanged() async {
    final game = _game;
    if (game == null ||
        !_sessionController.stageCleared ||
        _completionRecording ||
        _completionResult != null) {
      return;
    }

    _completionRecording = true;
    final evaluation = game.evaluateCurrentRun();
    final result = await widget.bootstrap.progressStore.recordStageCompletion(
      stageNumber: _sessionController.stageNumber,
      evaluation: evaluation,
      totalStages: SampleCampaign.totalStages,
    );
    await _refreshOverview();
    final rewardClaimed = await widget.bootstrap.progressStore
        .hasClaimedStageClearBonus(_sessionController.stageNumber);

    if (!mounted) {
      return;
    }
    setState(() {
      _completionResult = result;
      _rewardClaimed = rewardClaimed;
    });
  }

  Future<void> _claimRewardedBonus() async {
    final result = await widget.bootstrap.progressStore.claimStageClearBonus(
      stageNumber: _stageNumber,
      amount: 50 + (_stageNumber * 5),
    );
    await _refreshOverview();
    if (!mounted) {
      return;
    }
    setState(() {
      _rewardClaimed = true;
      _rewardMessage = result.claimedNow
          ? 'Rewarded bonus granted: +${result.amountAwarded} gold.'
          : 'Rewarded bonus already claimed for this stage.';
    });
  }

  Future<void> _dismissTutorial([int? stageNumber]) async {
    await widget.bootstrap.progressStore.setTutorialDismissed(true);
    if (!mounted) {
      return;
    }
    setState(() {
      _tutorialDismissed = true;
      if (stageNumber != null) {
        _dismissedTutorialStages.add(stageNumber);
      }
    });
  }

  Future<void> _openStagePicker() async {
    final overview = _overview;
    if (overview == null) {
      return;
    }

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF20180F),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campaign Stages',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: overview.stages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final stage = overview.stages[index];
                    return FilledButton.tonal(
                      onPressed: stage.unlocked
                          ? () => Navigator.of(context).pop(stage.stageNumber)
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Stage ${stage.stageNumber}'),
                          const SizedBox(height: 4),
                          Text(
                            stage.unlocked ? 'Stars ${stage.stars}' : 'Locked',
                          ),
                          if (!stage.unlocked && stage.lockReason != null)
                            Text(
                              stage.lockReason!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (overview.stages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Locked stages may require stars from earlier stages or specific meta upgrades.',
                ),
              ],
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _loadStage(selected);
    }
  }

  Future<void> _openMetaUpgrades() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MetaUpgradesScreen(bootstrap: widget.bootstrap),
      ),
    );
    await _refreshOverview();
  }

  bool _shouldShowTutorial(StageProgressSnapshot stage) {
    return stage.stageNumber <= 5 &&
        !stage.cleared &&
        !_tutorialDismissed &&
        !_dismissedTutorialStages.contains(stage.stageNumber) &&
        _completionResult == null;
  }

  String _nextGoalText(CampaignOverview overview) {
    final lockedStages = overview.stages
        .where((stage) => !stage.unlocked)
        .toList();
    final lockedStage = lockedStages.isEmpty ? null : lockedStages.first;
    if (lockedStage == null) {
      return 'Campaign frontier is fully open. Chase stronger stars or prepare your late-game build mix.';
    }
    return 'Next gate: Stage ${lockedStage.stageNumber} requires ${lockedStage.lockReason ?? 'more stars or upgrades'}.';
  }

  String _recommendedInvestmentText(CampaignOverview overview) {
    final highestUnlocked =
        overview.stages.lastIndexWhere((stage) => stage.unlocked) + 1;
    final levelById = {
      for (final item in overview.metaUpgrades) item.id: item.level,
    };

    if (highestUnlocked <= 10) {
      return 'Recommended investment: Arcane Mastery or Frost Focus if mixed armor waves are dragging out.';
    }
    if (highestUnlocked <= 15) {
      return (levelById['guard_drill'] ?? 0) == 0
          ? 'Recommended investment: Guard Drill level 1 for cleaner control against revived grave fronts.'
          : 'Recommended investment: Arcane Mastery or Commerce Guild if grave-stage clears feel too coin-hungry.';
    }
    if (highestUnlocked <= 20) {
      return (levelById['bow_mastery'] ?? 0) < 2
          ? 'Recommended investment: Bow Mastery level 2 before the late-elite transition.'
          : 'Recommended investment: Frost Focus or Guard Drill if Grave Guards are breaking your final bend.';
    }
    return 'Recommended investment: strengthen your weakest combat tree first, then grow Commerce Guild for replay efficiency.';
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
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF223340), Color(0xFF121A22)],
                ),
              ),
              child: GameWidget(key: ValueKey(_gameEpoch), game: game),
            ),
            AnimatedBuilder(
              animation: _sessionController,
              builder: (context, _) {
                return Column(
                  children: [
                    _TopHud(
                      sessionController: _sessionController,
                      player: overview.player,
                      stage: currentStage,
                      onReturnToCamp: () => Navigator.of(context).maybePop(),
                      onStartWave: game.startNextWave,
                      onTogglePause: game.togglePaused,
                      onOpenStages: _openStagePicker,
                      onOpenUpgrades: _openMetaUpgrades,
                    ),
                    if (_shouldShowTutorial(currentStage))
                      _TutorialPanel(
                        stageNumber: currentStage.stageNumber,
                        sessionController: _sessionController,
                        onDismiss: () =>
                            _dismissTutorial(currentStage.stageNumber),
                      ),
                    const Spacer(),
                    if (_sessionController.selectedTower != null)
                      _TowerActionBar(
                        sessionController: _sessionController,
                        onUpgrade: game.upgradeSelectedTower,
                        onSell: game.sellSelectedTower,
                        onChooseBranch: game.chooseBranchForSelectedTower,
                      ),
                    _BuildBar(
                      sessionController: _sessionController,
                      metaUpgrades: activeMetaUpgrades,
                      onSelect: game.selectBuildable,
                    ),
                  ],
                );
              },
            ),
            if (_sessionController.stageCleared ||
                _sessionController.stageFailed)
              _ResultOverlay(
                sessionController: _sessionController,
                completionResult: _completionResult,
                rewardClaimed: _rewardClaimed,
                rewardMessage: _rewardMessage,
                stage: currentStage,
                hasNextStage: _stageNumber < SampleCampaign.totalStages,
                nextGoalText: _nextGoalText(overview),
                recommendedInvestmentText: _recommendedInvestmentText(overview),
                onRetry: () => _loadStage(_stageNumber),
                onNextStage: () => _loadStage(
                  (_stageNumber + 1).clamp(1, SampleCampaign.totalStages),
                ),
                onOpenStages: _openStagePicker,
                onClaimRewardedBonus: _sessionController.stageCleared
                    ? _claimRewardedBonus
                    : null,
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
    required this.player,
    required this.stage,
    required this.onReturnToCamp,
    required this.onStartWave,
    required this.onTogglePause,
    required this.onOpenStages,
    required this.onOpenUpgrades,
  });

  final GameSessionController sessionController;
  final PlayerProgressSnapshot player;
  final StageProgressSnapshot stage;
  final VoidCallback onReturnToCamp;
  final VoidCallback onStartWave;
  final VoidCallback onTogglePause;
  final VoidCallback onOpenStages;
  final VoidCallback onOpenUpgrades;

  @override
  Widget build(BuildContext context) {
    final canStartWave =
        !sessionController.waveInProgress &&
        !sessionController.stageCleared &&
        !sessionController.stageFailed;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sessionController.stageTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onReturnToCamp,
                    child: const Text('Camp'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onOpenStages,
                    child: const Text('Stages'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onOpenUpgrades,
                    child: const Text('Upgrades'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canStartWave ? onStartWave : null,
                    child: const Text('Start Wave'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onTogglePause,
                    child: Text(
                      sessionController.isPaused ? 'Resume' : 'Pause',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: 'Stage',
                    value: '${sessionController.stageNumber}/30',
                  ),
                  _StatChip(
                    label: 'Wave',
                    value:
                        '${sessionController.currentWave}/${sessionController.totalWaves}',
                  ),
                  _StatChip(
                    label: 'Coins',
                    value: '${sessionController.coins}',
                  ),
                  _StatChip(
                    label: 'Base',
                    value: '${sessionController.baseHealth}',
                  ),
                  _StatChip(label: 'Level', value: '${player.accountLevel}'),
                  _StatChip(
                    label: 'Meta Gold',
                    value: '${player.softCurrency}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(sessionController.statusText),
              const SizedBox(height: 8),
              Text(stage.description),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final objective in stage.objectives)
                    _MiniChip(label: objective),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPanel extends StatelessWidget {
  const _TutorialPanel({
    required this.stageNumber,
    required this.sessionController,
    required this.onDismiss,
  });

  final int stageNumber;
  final GameSessionController sessionController;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final title = switch (stageNumber) {
      1 => 'Placement Basics',
      2 => 'Spend Before Pressure',
      3 => 'Armor Counter',
      4 => 'Economy Timing',
      _ => 'Crest Pressure',
    };
    final checklist = _checklistForStage();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        color: const Color(0xFF2A2117).withValues(alpha: 0.96),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Tutorial: $title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(onPressed: onDismiss, child: const Text('Hide')),
                ],
              ),
              const SizedBox(height: 6),
              for (final item in checklist) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        item.complete
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: item.complete
                            ? const Color(0xFF98D67C)
                            : const Color(0xFFE4C67A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.label)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_TutorialChecklistEntry> _checklistForStage() {
    switch (stageNumber) {
      case 1:
        return [
          _TutorialChecklistEntry(
            label: 'Select an Archer from the build bar',
            complete:
                sessionController.selectedBuildable == TowerKind.archer ||
                sessionController.builtTowerKinds.contains('archer'),
          ),
          _TutorialChecklistEntry(
            label: 'Place your first tower on a glowing slot',
            complete: sessionController.towersBuilt >= 1,
          ),
          _TutorialChecklistEntry(
            label: 'Press Start Wave when you are ready',
            complete:
                sessionController.currentWave >= 1 ||
                sessionController.waveInProgress,
          ),
        ];
      case 2:
        return [
          _TutorialChecklistEntry(
            label: 'Place at least 2 towers before the lane gets crowded',
            complete: sessionController.towersBuilt >= 2,
          ),
          _TutorialChecklistEntry(
            label: 'Upgrade one tower to level 2',
            complete: sessionController.maxTowerLevel >= 2,
          ),
          _TutorialChecklistEntry(
            label: 'Keep building during combat if you need to stabilize',
            complete:
                sessionController.currentWave >= 2 ||
                (sessionController.waveInProgress &&
                    sessionController.towersBuilt >= 2),
          ),
        ];
      case 3:
        return [
          _TutorialChecklistEntry(
            label: 'Build a Mage tower for armored enemies',
            complete: sessionController.builtTowerKinds.contains('mageObelisk'),
          ),
          _TutorialChecklistEntry(
            label: 'Keep at least 16 base health',
            complete: sessionController.baseHealth >= 16,
          ),
          _TutorialChecklistEntry(
            label: 'Clear the stage',
            complete: sessionController.stageCleared,
          ),
        ];
      case 4:
        return [
          _TutorialChecklistEntry(
            label: 'Build a Frost tower to slow mixed pressure',
            complete: sessionController.builtTowerKinds.contains('frostShrine'),
          ),
          _TutorialChecklistEntry(
            label: 'Reach level 2 on any tower',
            complete: sessionController.maxTowerLevel >= 2,
          ),
          _TutorialChecklistEntry(
            label: 'Do not let the lane get ahead of your upgrades',
            complete: sessionController.currentWave >= 2,
          ),
        ];
      default:
        return [
          _TutorialChecklistEntry(
            label: 'Build a Coin Mill once the lane is stable',
            complete: sessionController.builtTowerKinds.contains('coinMill'),
          ),
          _TutorialChecklistEntry(
            label:
                'Save coins before the final wave instead of overbuilding early',
            complete: sessionController.currentWave >= 2,
          ),
          _TutorialChecklistEntry(
            label: 'Finish the crest stage with your base intact',
            complete: sessionController.stageCleared,
          ),
        ];
    }
  }
}

class _TutorialChecklistEntry {
  const _TutorialChecklistEntry({required this.label, required this.complete});

  final String label;
  final bool complete;
}

class _TowerActionBar extends StatelessWidget {
  const _TowerActionBar({
    required this.sessionController,
    required this.onUpgrade,
    required this.onSell,
    required this.onChooseBranch,
  });

  final GameSessionController sessionController;
  final VoidCallback onUpgrade;
  final VoidCallback onSell;
  final ValueChanged<String> onChooseBranch;

  @override
  Widget build(BuildContext context) {
    final tower = sessionController.selectedTower;
    if (tower == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tower.label}  Lv.${tower.level}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(tower.shortDescription),
                    Text(tower.abilityDescription),
                    if (tower.branchLabel != null)
                      Text('Branch: ${tower.branchLabel}'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: tower.canUpgrade ? onUpgrade : null,
                        child: Text('Upgrade ${tower.upgradeCost}'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onSell,
                        child: Text('Sell ${tower.sellValue}'),
                      ),
                    ],
                  ),
                  if (tower.canChooseBranch) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final branch in tower.branchChoices)
                          FilledButton.tonal(
                            onPressed: () => onChooseBranch(branch.id),
                            child: Text(branch.label),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildBar extends StatelessWidget {
  const _BuildBar({
    required this.sessionController,
    required this.metaUpgrades,
    required this.onSelect,
  });

  final GameSessionController sessionController;
  final ResolvedMetaUpgrades metaUpgrades;
  final ValueChanged<TowerKind?> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = TowerCatalog.buildMenu;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Build During Waves',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    sessionController.selectedBuildable == null
                        ? 'Tap a card or a placed tower'
                        : TowerCatalog.byKind(
                            sessionController.selectedBuildable!,
                          ).label,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tower in entries) ...[
                      _BuildButton(
                        tower: tower,
                        isUnlocked: tower.isUnlocked(metaUpgrades),
                        isSelected:
                            sessionController.selectedBuildable == tower.kind,
                        onPressed: () => onSelect(
                          sessionController.selectedBuildable == tower.kind
                              ? null
                              : tower.kind,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildButton extends StatelessWidget {
  const _BuildButton({
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
    return SizedBox(
      width: 128,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: !isUnlocked
              ? const Color(0xFF3A322A)
              : (isSelected
                    ? tower.color
                    : tower.color.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
        onPressed: isUnlocked ? onPressed : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tower.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Cost ${tower.cost}'),
            Text(tower.shortDescription),
            if (!isUnlocked && tower.unlockHint != null) ...[
              const SizedBox(height: 6),
              Text(
                tower.unlockHint!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.sessionController,
    required this.completionResult,
    required this.rewardClaimed,
    required this.rewardMessage,
    required this.stage,
    required this.hasNextStage,
    required this.nextGoalText,
    required this.recommendedInvestmentText,
    required this.onRetry,
    required this.onNextStage,
    required this.onOpenStages,
    required this.onClaimRewardedBonus,
  });

  final GameSessionController sessionController;
  final StageCompletionResult? completionResult;
  final bool rewardClaimed;
  final String? rewardMessage;
  final StageProgressSnapshot stage;
  final bool hasNextStage;
  final String nextGoalText;
  final String recommendedInvestmentText;
  final VoidCallback onRetry;
  final VoidCallback onNextStage;
  final VoidCallback onOpenStages;
  final VoidCallback? onClaimRewardedBonus;

  List<String> _failureTips() {
    final stageNumber = stage.stageNumber;
    if (stageNumber <= 3) {
      return const [
        'Build earlier. Waiting too long for the first tower usually causes avoidable leaks.',
        'Overlap damage on one bend instead of spreading weak towers across the whole map.',
      ];
    }
    if (stageNumber <= 5) {
      return const [
        'Upgrade one core tower before adding too many weak extras.',
        'Use control towers to keep fast enemies inside your main damage zone.',
      ];
    }
    if (stageNumber <= 10) {
      return const [
        'Shield Infantry slow down pure physical builds. Add Mage or Frost support earlier.',
        'Save enough coins before the final wave so cult support and armored fronts do not stack unchecked.',
      ];
    }
    if (stageNumber <= 15) {
      return const [
        'Reviving skeleton lanes punish weak cleanup. Tighten one real damage bend instead of spreading towers evenly.',
        'If cult support survived too long, add a cleaner anti-support answer before buying extra economy.',
      ];
    }
    if (stageNumber <= 20) {
      return const [
        'Corrupted Knights and Grave Guards need stronger overlap, not only more slows.',
        'If the last wave broke you, hold more coins for wave three and four instead of over-upgrading too early.',
      ];
    }
    if (stageNumber <= 25) {
      return const [
        'Warlocks are the real tax here. If they live too long, even good fronts become too expensive to stop.',
        'Build one cleaner anti-support answer before adding extra filler towers to the lane.',
      ];
    }
    if (stageNumber <= 30) {
      return const [
        'Throne-march waves punish panic spending. Save enough for the last two waves and plan your anchor towers early.',
        'If Grave Guards reached the final bend, your lane needs stronger elite damage overlap, not just more control.',
      ];
    }
    return const [
      'Check which enemy role broke the lane first, then add one clearer counter instead of overbuilding everything.',
      'If the front line held but the base still fell, shift damage overlap closer to the final bend.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cleared = sessionController.stageCleared;
    final completedObjectives =
        completionResult?.objectives.where((item) => item.completed).length ??
        0;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleared ? 'Stage Cleared' : 'Stage Failed',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(stage.description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: 'Stage', value: '${stage.stageNumber}'),
                      _StatChip(
                        label: 'Wave',
                        value:
                            '${sessionController.currentWave}/${sessionController.totalWaves}',
                      ),
                      _StatChip(
                        label: 'Base',
                        value:
                            '${sessionController.baseHealth}/${sessionController.maxBaseHealth}',
                      ),
                      if (cleared && completionResult != null)
                        _StatChip(
                          label: 'Objectives',
                          value: '$completedObjectives/3',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (cleared && completionResult != null) ...[
                    Text('XP +${completionResult!.xpAwarded}'),
                    Text('Meta Gold +${completionResult!.softCurrencyAwarded}'),
                    const SizedBox(height: 8),
                    for (final objective in completionResult!.objectives)
                      Row(
                        children: [
                          Icon(
                            objective.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: objective.completed
                                ? const Color(0xFF96D67A)
                                : const Color(0xFFE6C67A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(objective.label)),
                        ],
                      ),
                    if (completionResult!.unlockedNextStage != null)
                      Text(
                        'Unlocked Stage ${completionResult!.unlockedNextStage}',
                      ),
                    if (completionResult!.objectives.any(
                      (objective) => !objective.completed,
                    )) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Next run tip: focus on the unfinished objective to convert this clear into a stronger reward.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: rewardClaimed ? null : onClaimRewardedBonus,
                      child: Text(
                        rewardClaimed
                            ? 'Rewarded Bonus Claimed'
                            : 'Rewarded Bonus +${50 + (sessionController.stageNumber * 5)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reward breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Base reward +${completionResult!.baseSoftCurrencyAwarded}',
                    ),
                    if (completionResult!.firstClearBonusAwarded > 0)
                      Text(
                        'First clear bonus +${completionResult!.firstClearBonusAwarded}',
                      ),
                    if (completionResult!.starUpgradeBonusAwarded > 0)
                      Text(
                        'Improved star bonus +${completionResult!.starUpgradeBonusAwarded}',
                      ),
                    if (completionResult!.crestBonusAwarded > 0)
                      Text(
                        'Crest bonus +${completionResult!.crestBonusAwarded}',
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'What to do next',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(nextGoalText),
                    const SizedBox(height: 4),
                    Text(recommendedInvestmentText),
                    if (rewardMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(rewardMessage!),
                    ],
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      sessionController.statusText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Likely fix for the next attempt',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    for (final tip in _failureTips()) ...[
                      Text('- $tip'),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Suggested camp action',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(recommendedInvestmentText),
                    const SizedBox(height: 8),
                    Text(
                      'Stage goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    for (final objective in stage.objectives)
                      Text('- $objective'),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                      if (sessionController.stageCleared && hasNextStage)
                        FilledButton.tonal(
                          onPressed: onNextStage,
                          child: const Text('Next Stage'),
                        ),
                      OutlinedButton(
                        onPressed: onOpenStages,
                        child: const Text('Stage Select'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
