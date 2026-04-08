import 'package:depense_game/app/theme/app_theme.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.overview,
    required this.onDeployNext,
    required this.onReplayStage,
    required this.onOpenHelp,
    required this.onBackToMenu,
  });

  final CampaignOverview overview;
  final VoidCallback onDeployNext;
  final ValueChanged<int> onReplayStage;
  final VoidCallback onOpenHelp;
  final VoidCallback onBackToMenu;

  @override
  Widget build(BuildContext context) {
    final nextStage = overview.recommendedStage;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildNextMissionCard(context, nextStage),
                  const SizedBox(height: 24),
                  _buildSecondaryActions(context),
                  const SizedBox(height: 24),
                  _buildStageHistoryGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.6),
        border: const Border(
          bottom: BorderSide(color: AppTheme.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackToMenu,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppTheme.inkMuted,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAMP HUB',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.moss,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '작전 기지',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
              ),
            ],
          ),
          const Spacer(),
          _buildStatIndicator(
            context,
            icon: Icons.star_rounded,
            color: Colors.amber,
            value: '${overview.totalStars}',
          ),
          const SizedBox(width: 12),
          _buildStatIndicator(
            context,
            icon: Icons.monetization_on_rounded,
            color: AppTheme.moss,
            value: '${overview.player.softCurrency}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMissionCard(
    BuildContext context,
    StageProgressSnapshot? nextStage,
  ) {
    if (nextStage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.moss.withValues(alpha: 0.2),
            AppTheme.glowBox.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.moss.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.moss.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.moss,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STAGE ${nextStage.stageNumber}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.shield_rounded, color: AppTheme.moss, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '다음 작전 구역',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextStage.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onDeployNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.moss,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppTheme.moss.withValues(alpha: 0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded),
                  SizedBox(width: 12),
                  Text(
                    '작전 개시',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return _buildActionButton(
      context,
      icon: Icons.help_outline_rounded,
      label: '가이드',
      subLabel: '게임 시스템과 타워 역할 보기',
      color: AppTheme.steel,
      onTap: onOpenHelp,
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              subLabel,
              style: TextStyle(color: AppTheme.inkMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageHistoryGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppTheme.inkMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '스테이지 선택',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.inkMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overview.stages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final stage = overview.stages[index];
            final isUnlocked = stage.unlocked;
            final isCleared = stage.cleared;

            return InkWell(
              onTap: isUnlocked ? () => onReplayStage(stage.stageNumber) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? (isCleared
                            ? AppTheme.moss.withValues(alpha: 0.1)
                            : AppTheme.panel)
                      : Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? (isCleared
                              ? AppTheme.moss.withValues(alpha: 0.4)
                              : AppTheme.line)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${stage.stageNumber}',
                        style: TextStyle(
                          color: isUnlocked
                              ? AppTheme.ink
                              : AppTheme.inkMuted.withValues(alpha: 0.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCleared)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            children: List.generate(
                              3,
                              (i) => Icon(
                                Icons.star_rounded,
                                size: 8,
                                color: i < stage.stars
                                    ? Colors.amber
                                    : AppTheme.inkMuted.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      if (!isUnlocked)
                        const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: AppTheme.line,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
