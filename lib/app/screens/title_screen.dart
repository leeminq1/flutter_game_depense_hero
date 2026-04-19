import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/routing/app_flow_state.dart';
import 'package:depense_game/app/screens/game_screen.dart';
import 'package:depense_game/app/screens/help_screen.dart';
import 'package:depense_game/app/screens/home_screen.dart';
import 'package:depense_game/app/screens/settings_screen.dart';
import 'package:depense_game/app/theme/app_theme.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:flutter/material.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  CampaignOverview? _overview;
  AppFlowState _flow = AppFlowState.splash;
  int _selectedStage = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshOverview();
  }

  Future<void> _refreshOverview() async {
    final overview = await widget.bootstrap.progressStore.loadCampaignOverview(
      totalStages: CampaignData.totalStages,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _overview = overview;
      _selectedStage = overview.player.currentCampaignStage;
    });
  }

  Future<void> _startNewGame() async {
    final overview = _overview;
    if (overview == null || _busy) {
      return;
    }

    var shouldReset = true;
    if (overview.hasMeaningfulProgress) {
      shouldReset =
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('새 게임 시작'),
                content: const Text(
                  '기존 진행 데이터를 지우고 스테이지 1부터 다시 시작합니다. '
                  '튜토리얼 흐름과 잠금 해제도 처음 상태로 돌아갑니다.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('새로 시작'),
                  ),
                ],
              );
            },
          ) ??
          false;
    }

    if (!shouldReset) {
      return;
    }

    setState(() => _busy = true);
    await widget.bootstrap.progressStore.resetCampaignProgress();
    await _refreshOverview();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _selectedStage = 1;
      _flow = AppFlowState.camp;
    });
  }

  void _continueGame() {
    final overview = _overview;
    if (overview == null || !overview.player.hasResumableRun) {
      return;
    }
    setState(() {
      _selectedStage = overview.player.currentCampaignStage;
      _flow = AppFlowState.camp;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(bootstrap: widget.bootstrap),
      ),
    );
  }

  Future<void> _openHelp() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const HelpScreen()));
  }

  Future<void> _returnFromBattle() async {
    await _refreshOverview();
    if (!mounted) {
      return;
    }
    setState(() => _flow = AppFlowState.camp);
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    if (overview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.backgroundGradient,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_flow) {
            AppFlowState.splash => _ResponsiveTitleSplash(
              key: const ValueKey('splash'),
              onTap: () => setState(() => _flow = AppFlowState.menu),
            ),
            AppFlowState.menu => _MainMenu(
              key: const ValueKey('menu'),
              overview: overview,
              busy: _busy,
              onNewGame: _startNewGame,
              onContinue: _continueGame,
              onSettings: _openSettings,
            ),
            AppFlowState.camp => HomeScreen(
              key: const ValueKey('camp'),
              overview: overview,
              onDeployNext: () => setState(() {
                _selectedStage = overview.recommendedStage?.stageNumber ?? 1;
                _flow = AppFlowState.battle;
              }),
              onReplayStage: (stageNumber) => setState(() {
                _selectedStage = stageNumber;
                _flow = AppFlowState.battle;
              }),
              onOpenHelp: _openHelp,
              onBackToMenu: () => setState(() => _flow = AppFlowState.menu),
            ),
            AppFlowState.battle => GameScreen(
              key: ValueKey('battle-$_selectedStage'),
              bootstrap: widget.bootstrap,
              initialStageNumber: _selectedStage,
              onExitToCamp: _returnFromBattle,
            ),
          },
        ),
      ),
    );
  }
}

class _ResponsiveTitleSplash extends StatefulWidget {
  const _ResponsiveTitleSplash({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ResponsiveTitleSplash> createState() => _ResponsiveTitleSplashState();
}

class _ResponsiveTitleSplashState extends State<_ResponsiveTitleSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth <= 420;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: AppTheme.moss.withValues(alpha: 0.12),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 5),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      final glow = 0.15 + (_ctrl.value * 0.35);
                      return Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 320 : 420,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 36,
                          vertical: isCompact ? 20 : 24,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.moss.withValues(alpha: glow),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) {
                            final glow = 0.4 + (_ctrl.value * 0.6);
                            return Text(
                              'PIXEL GUARD : WAVE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isCompact ? 22 : 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: AppTheme.ink,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.moss.withValues(
                                      alpha: glow,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/splash.png',
                          width: isCompact ? 300 : 340,
                          height: isCompact ? 300 : 340,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.4 + (_ctrl.value * 0.6),
                        child: child,
                      );
                    },
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 20,
                          color: AppTheme.inkMuted,
                        ),
                        Text(
                          '화면을 터치하세요',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.inkMuted,
                                fontSize: isCompact ? 16 : 20,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenu extends StatelessWidget {
  const _MainMenu({
    super.key,
    required this.overview,
    required this.busy,
    required this.onNewGame,
    required this.onContinue,
    required this.onSettings,
  });

  final CampaignOverview overview;
  final bool busy;
  final Future<void> Function() onNewGame;
  final VoidCallback onContinue;
  final Future<void> Function() onSettings;

  @override
  Widget build(BuildContext context) {
    final canContinue = overview.player.hasResumableRun && !busy;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const Spacer(flex: 4),
            Text(
              'PIXEL GUARD : WAVE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.play_arrow_rounded,
              iconColor: AppTheme.moss,
              label: busy ? '로딩 중...' : '새 게임',
              subtitle: '스테이지 1부터 다시 시작',
              glowColor: AppTheme.moss,
              onTap: busy ? null : onNewGame,
            ),
            const SizedBox(height: 14),
            _MenuButton(
              icon: Icons.fast_forward_rounded,
              iconColor: canContinue ? AppTheme.ember : AppTheme.inkMuted,
              label: '이어하기',
              subtitle: canContinue
                  ? '스테이지 ${overview.currentCampaignStage}부터 재개'
                  : '이어할 진행이 없습니다',
              glowColor: canContinue ? AppTheme.ember : null,
              onTap: canContinue ? onContinue : null,
            ),
            const SizedBox(height: 14),
            _MenuButton(
              icon: Icons.settings_rounded,
              iconColor: AppTheme.steel,
              label: '설정',
              subtitle: '환경 설정과 도움말',
              onTap: busy ? null : onSettings,
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.person_rounded,
                  label: 'Lv.${overview.player.accountLevel}',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.star_rounded,
                  label: '${overview.totalStars}',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: '${overview.player.clearedStageCount}/30',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.glowColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: enabled
                  ? (glowColor ?? AppTheme.line).withValues(alpha: 0.5)
                  : AppTheme.line.withValues(alpha: 0.2),
            ),
            boxShadow: enabled && glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: enabled ? iconColor : AppTheme.inkMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: enabled ? AppTheme.ink : AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppTheme.inkMuted : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.inkMuted),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
