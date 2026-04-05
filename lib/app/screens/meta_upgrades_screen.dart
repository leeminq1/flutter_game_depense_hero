import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:flutter/material.dart';

class MetaUpgradesScreen extends StatefulWidget {
  const MetaUpgradesScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<MetaUpgradesScreen> createState() => _MetaUpgradesScreenState();
}

class _MetaUpgradesScreenState extends State<MetaUpgradesScreen> {
  CampaignOverview? _overview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final overview = await widget.bootstrap.progressStore.loadCampaignOverview(
      totalStages: 30,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _overview = overview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    if (overview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final levels = {
      for (final upgrade in overview.metaUpgrades) upgrade.id: upgrade.level,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Meta Upgrades')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta Gold: ${overview.player.softCurrency}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_upgradeRecommendation(overview)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final definition in MetaUpgradeCatalog.upgrades) ...[
            _UpgradeCard(
              definition: definition,
              level: levels[definition.id] ?? 0,
              remainingGold: overview.player.softCurrency,
              onBuy: () async {
                final result = await widget.bootstrap.progressStore
                    .purchaseMetaUpgrade(definition.id);
                await _load();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(result.message)));
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _upgradeRecommendation(CampaignOverview overview) {
    final highestUnlocked =
        overview.stages.lastIndexWhere((stage) => stage.unlocked) + 1;
    final levelById = {
      for (final item in overview.metaUpgrades) item.id: item.level,
    };

    if (highestUnlocked <= 5) {
      return levelById['supply_cache'] == 0
          ? 'Recommended next target: Supply Cache level 1 for smoother early starts.'
          : 'Recommended next target: Stronghold Masonry level 1 to reduce early mistakes.';
    }
    if (highestUnlocked <= 10) {
      return (levelById['arcane_mastery'] ?? 0) == 0
          ? 'Recommended next target: Arcane Mastery for cleaner anti-armor pacing.'
          : 'Recommended next target: Frost Focus or Guard Drill to stabilize midgame lanes.';
    }
    if (highestUnlocked <= 20) {
      return (levelById['bow_mastery'] ?? 0) < 2
          ? 'Recommended next target: Bow Mastery level 2 to unlock Ballista before late elites.'
          : 'Recommended next target: Commerce Guild to strengthen repeat-clear income.';
    }
    return 'Recommended next target: patch your weakest combat lane, then finish Commerce Guild for long-run returns.';
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.definition,
    required this.level,
    required this.remainingGold,
    required this.onBuy,
  });

  final MetaUpgradeDefinition definition;
  final int level;
  final int remainingGold;
  final Future<void> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    final canUpgrade = level < definition.maxLevel;
    final cost = canUpgrade ? definition.costForLevel(level) : 0;
    final milestonePending =
        definition.milestoneLevel != null &&
        level < (definition.milestoneLevel ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 120,
              decoration: BoxDecoration(
                color: definition.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${definition.label}  Lv.$level/${definition.maxLevel}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _UpgradeTag(label: definition.focusLabel),
                      if (milestonePending)
                        _UpgradeTag(
                          label: 'Milestone at Lv.${definition.milestoneLevel}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(definition.description),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${MetaUpgradeCatalog.effectSummary(definition.id, level)}',
                  ),
                  Text(
                    'Next: ${MetaUpgradeCatalog.nextEffectSummary(definition.id, level)}',
                  ),
                  if (milestonePending &&
                      definition.milestoneLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      definition.milestoneLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: canUpgrade && remainingGold >= cost ? onBuy : null,
              child: Text(canUpgrade ? 'Buy $cost' : 'Max'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeTag extends StatelessWidget {
  const _UpgradeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
