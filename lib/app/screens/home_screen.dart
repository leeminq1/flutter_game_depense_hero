import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/game_screen.dart';
import 'package:depense_game/app/screens/help_screen.dart';
import 'package:depense_game/app/screens/meta_upgrades_screen.dart';
import 'package:depense_game/app/screens/settings_screen.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/sample/sample_campaign.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CampaignOverview? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
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

  Future<void> _openGame(int stageNumber) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen(
          bootstrap: widget.bootstrap,
          initialStageNumber: stageNumber,
        ),
      ),
    );
    await _loadOverview();
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
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _openGame(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    if (overview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalStars = overview.stages.fold<int>(
      0,
      (sum, item) => sum + item.stars,
    );
    final highestUnlocked =
        overview.stages.lastIndexWhere((stage) => stage.unlocked) + 1;
    final recommendedStage = _recommendedStage(overview);
    final lockedStages = overview.stages
        .where((stage) => !stage.unlocked)
        .toList();
    final nextLockedStage = lockedStages.isEmpty ? null : lockedStages.first;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF243846), Color(0xFF121A22)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Depense',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Return to camp, plan your meta upgrades, and push the next defense line when you are ready.',
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SummaryChip(
                            label: 'Account',
                            value: 'Lv.${overview.player.accountLevel}',
                          ),
                          _SummaryChip(
                            label: 'Meta Gold',
                            value: '${overview.player.softCurrency}',
                          ),
                          _SummaryChip(label: 'Stars', value: '$totalStars'),
                          _SummaryChip(
                            label: 'Unlocked',
                            value: '$highestUnlocked/30',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: () => _openGame(recommendedStage),
                            child: Text('Continue Stage $recommendedStage'),
                          ),
                          FilledButton.tonal(
                            onPressed: _openStagePicker,
                            child: const Text('Stage Select'),
                          ),
                          FilledButton.tonal(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => MetaUpgradesScreen(
                                    bootstrap: widget.bootstrap,
                                  ),
                                ),
                              );
                              await _loadOverview();
                            },
                            child: const Text('Meta Upgrades'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const HelpScreen(),
                                ),
                              );
                            },
                            child: const Text('Help'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => SettingsScreen(
                                    bootstrap: widget.bootstrap,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Goal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_goalText(nextLockedStage)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Investment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_recommendedInvestmentText(overview)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'First clears, stronger stars, and crest stages all pay extra Meta Gold now. The healthiest loop is clear a new stage, revisit one earlier stage for better stars if needed, then spend toward your next unlock gate.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Front',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_frontSummary(recommendedStage)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _recommendedStage(CampaignOverview overview) {
    for (final stage in overview.stages) {
      if (stage.unlocked && !stage.cleared) {
        return stage.stageNumber;
      }
    }
    return overview.stages.lastIndexWhere((stage) => stage.unlocked) + 1;
  }

  String _goalText(StageProgressSnapshot? nextLockedStage) {
    if (nextLockedStage == null) {
      return 'Campaign frontier is fully open. Push for stronger stars and finish the remaining meta tree.';
    }
    return 'Stage ${nextLockedStage.stageNumber} is your next gate. Current lock: ${nextLockedStage.lockReason ?? 'earn more stars and upgrades'}.';
  }

  String _recommendedInvestmentText(CampaignOverview overview) {
    final highestUnlocked =
        overview.stages.lastIndexWhere((stage) => stage.unlocked) + 1;
    final levelById = {
      for (final item in overview.metaUpgrades) item.id: item.level,
    };

    if (highestUnlocked <= 10) {
      return 'Lean into Arcane Mastery or Frost Focus so mixed armor and support waves stop dragging out.';
    }
    if (highestUnlocked <= 15) {
      return (levelById['guard_drill'] ?? 0) == 0
          ? 'Guard Drill level 1 helps hold revived fronts in stages 11-15.'
          : 'Commerce Guild or Arcane Mastery are good follow-ups if grave-stage clears feel expensive.';
    }
    if (highestUnlocked <= 20) {
      return (levelById['bow_mastery'] ?? 0) < 2
          ? 'Push Bow Mastery toward level 2 before the late-campaign elite wall.'
          : 'Frost Focus and Guard Drill are strong if Grave Guards are the first thing breaking your line.';
    }
    if (highestUnlocked <= 25) {
      return (levelById['commerce_guild'] ?? 0) < 2
          ? 'Commerce Guild helps fund expensive bastion retries, but do not skip core combat upgrades for it.'
          : 'Bow Mastery, Guard Drill, and Frost Focus are the strongest answers if Warlocks and bruisers are overlapping too cleanly.';
    }
    return 'Throne-march retries need clean anti-support damage first. Finish the weakest combat tree, then use Commerce Guild for steadier replay income.';
  }

  String _frontSummary(int recommendedStage) {
    if (recommendedStage <= 10) {
      return 'Ruin Road is about readable mixed-pressure waves. Build earlier and keep one anti-armor answer online.';
    }
    if (recommendedStage <= 15) {
      return 'Grave March is about revived skeleton cleanup, cult denial, and disciplined late-wave spending.';
    }
    if (recommendedStage <= 20) {
      return 'The chapel front introduces corrupted knights and Grave Guards. Control still matters, but damage overlap matters more.';
    }
    if (recommendedStage <= 25) {
      return 'Bastion stages layer Warlocks behind resistant bruisers. Anti-support timing and elite damage windows matter more than raw tower count.';
    }
    return 'Throne-march stages leave very little recovery room. Every build slot now has to earn its keep, and late-wave coin discipline matters more than ever.';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value'),
    );
  }
}
