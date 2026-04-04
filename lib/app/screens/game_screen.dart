import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/sample/sample_campaign.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

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
  int _stageNumber = 1;
  int _gameEpoch = 0;
  bool _completionRecording = false;
  ResolvedMetaUpgrades? _activeMetaUpgrades;

  @override
  void initState() {
    super.initState();
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
    final currentOverview = _overview ??
        await widget.bootstrap.progressStore.loadCampaignOverview(
          totalStages: SampleCampaign.totalStages,
        );
    final resolvedMeta = MetaUpgradeCatalog.resolve(currentOverview.metaUpgrades);
    final stage = SampleCampaign.stage(stageNumber);
    final rewardClaimed =
        await widget.bootstrap.progressStore.hasClaimedStageClearBonus(stageNumber);
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
                          Text(stage.unlocked ? 'Stars ${stage.stars}' : 'Locked'),
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
    final overview = _overview;
    if (overview == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF20180F),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentOverview = _overview ?? overview;
            final levels = {
              for (final upgrade in currentOverview.metaUpgrades) upgrade.id: upgrade.level,
            };

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta Upgrades',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Meta Gold: ${currentOverview.player.softCurrency}'),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: MetaUpgradeCatalog.upgrades.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final definition = MetaUpgradeCatalog.upgrades[index];
                        final level = levels[definition.id] ?? 0;
                        final canUpgrade = level < definition.maxLevel;
                        final cost = definition.costForLevel(level);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: definition.color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${definition.label}  Lv.$level/${definition.maxLevel}',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(definition.description),
                                    ],
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: canUpgrade
                                      ? () async {
                                          final result = await widget.bootstrap.progressStore
                                              .purchaseMetaUpgrade(definition.id);
                                          await _refreshOverview();
                                          setSheetState(() {});
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(result.message)),
                                          );
                                        }
                                      : null,
                                  child: Text(canUpgrade ? 'Buy $cost' : 'Max'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Meta upgrades apply when you start or reload a stage.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final overview = _overview;

    if (game == null || overview == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStage = overview.stages[_stageNumber - 1];
    final activeMetaUpgrades =
        _activeMetaUpgrades ?? MetaUpgradeCatalog.resolve(overview.metaUpgrades);

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
                  colors: [
                    Color(0xFF223340),
                    Color(0xFF121A22),
                  ],
                ),
              ),
              child: GameWidget(
                key: ValueKey(_gameEpoch),
                game: game,
              ),
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
                      onStartWave: game.startNextWave,
                      onTogglePause: game.togglePaused,
                      onOpenStages: _openStagePicker,
                      onOpenUpgrades: _openMetaUpgrades,
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
                    _AudioPanel(
                      bootstrap: widget.bootstrap,
                      game: game,
                    ),
                  ],
                );
              },
            ),
            if (_sessionController.stageCleared || _sessionController.stageFailed)
              _ResultOverlay(
                sessionController: _sessionController,
                completionResult: _completionResult,
                rewardClaimed: _rewardClaimed,
                rewardMessage: _rewardMessage,
                stage: currentStage,
                hasNextStage: _stageNumber < SampleCampaign.totalStages,
                onRetry: () => _loadStage(_stageNumber),
                onNextStage: () => _loadStage((_stageNumber + 1).clamp(1, SampleCampaign.totalStages)),
                onOpenStages: _openStagePicker,
                onClaimRewardedBonus: _sessionController.stageCleared ? _claimRewardedBonus : null,
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
    required this.onStartWave,
    required this.onTogglePause,
    required this.onOpenStages,
    required this.onOpenUpgrades,
  });

  final GameSessionController sessionController;
  final PlayerProgressSnapshot player;
  final StageProgressSnapshot stage;
  final VoidCallback onStartWave;
  final VoidCallback onTogglePause;
  final VoidCallback onOpenStages;
  final VoidCallback onOpenUpgrades;

  @override
  Widget build(BuildContext context) {
    final canStartWave = !sessionController.waveInProgress &&
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
                    child: Text(sessionController.isPaused ? 'Resume' : 'Pause'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _StatChip(label: 'Stage', value: '${sessionController.stageNumber}/30'),
                  _StatChip(
                    label: 'Wave',
                    value: '${sessionController.currentWave}/${sessionController.totalWaves}',
                  ),
                  _StatChip(label: 'Coins', value: '${sessionController.coins}'),
                  _StatChip(label: 'Base', value: '${sessionController.baseHealth}'),
                  _StatChip(label: 'Level', value: '${player.accountLevel}'),
                  _StatChip(label: 'Meta Gold', value: '${player.softCurrency}'),
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
                        : TowerCatalog.byKind(sessionController.selectedBuildable!).label,
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
                        isSelected: sessionController.selectedBuildable == tower.kind,
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
              : (isSelected ? tower.color : tower.color.withValues(alpha: 0.25)),
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

class _AudioPanel extends StatelessWidget {
  const _AudioPanel({
    required this.bootstrap,
    required this.game,
  });

  final AppBootstrap bootstrap;
  final DefensePrototypeGame game;

  @override
  Widget build(BuildContext context) {
    final settings = bootstrap.audioSettingsController;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
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
                        'Audio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Switch(
                        value: !settings.muted,
                        onChanged: (value) async {
                          settings.setMuted(!value);
                          await bootstrap.persistAudioSettings();
                          await game.refreshAudioSettings();
                        },
                      ),
                    ],
                  ),
                  _VolumeRow(
                    label: 'Master',
                    value: settings.masterVolume,
                    onChanged: (value) async {
                      settings.setMasterVolume(value);
                      await bootstrap.persistAudioSettings();
                    },
                  ),
                  _VolumeRow(
                    label: 'Music',
                    value: settings.musicVolume,
                    onChanged: (value) async {
                      settings.setMusicVolume(value);
                      await bootstrap.persistAudioSettings();
                    },
                  ),
                  _VolumeRow(
                    label: 'SFX',
                    value: settings.sfxVolume,
                    onChanged: (value) async {
                      settings.setSfxVolume(value);
                      await bootstrap.persistAudioSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final VoidCallback onRetry;
  final VoidCallback onNextStage;
  final VoidCallback onOpenStages;
  final VoidCallback? onClaimRewardedBonus;

  @override
  Widget build(BuildContext context) {
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
                    sessionController.stageCleared ? 'Stage Cleared' : 'Stage Failed',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  if (sessionController.stageCleared && completionResult != null) ...[
                    Text('Stars: ${completionResult!.totalStars}'),
                    Text('XP +${completionResult!.xpAwarded}'),
                    Text('Meta Gold +${completionResult!.softCurrencyAwarded}'),
                    const SizedBox(height: 8),
                    for (final objective in completionResult!.objectives)
                      Text(
                        objective.completed
                            ? '[Done] ${objective.label}'
                            : '[Open] ${objective.label}',
                      ),
                    if (completionResult!.unlockedNextStage != null)
                      Text('Unlocked Stage ${completionResult!.unlockedNextStage}'),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: rewardClaimed ? null : onClaimRewardedBonus,
                      child: Text(
                        rewardClaimed
                            ? 'Rewarded Bonus Claimed'
                            : 'Rewarded Bonus +${50 + (sessionController.stageNumber * 5)}',
                      ),
                    ),
                    if (rewardMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(rewardMessage!),
                    ],
                  ] else ...[
                    const Text('Retry the stage or review earlier stages to improve your build.'),
                    const SizedBox(height: 8),
                    for (final objective in stage.objectives) Text('[Open] $objective'),
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

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
      ],
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

