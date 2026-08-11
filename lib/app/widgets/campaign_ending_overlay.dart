import 'dart:async';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/rendering/visual_catalog.dart';
import 'package:flutter/material.dart';

class CampaignEndingOverlay extends StatefulWidget {
  const CampaignEndingOverlay({
    required this.onComplete,
    required this.onSkip,
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  State<CampaignEndingOverlay> createState() => _CampaignEndingOverlayState();
}

class _CampaignEndingOverlayState extends State<CampaignEndingOverlay> {
  static const _sceneDurations = <Duration>[
    Duration(seconds: 4),
    Duration(seconds: 4),
    Duration(seconds: 5),
  ];

  Timer? _timer;
  int _scene = 0;
  bool _callbackFired = false;

  @override
  void initState() {
    super.initState();
    _scheduleNextScene();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextScene() {
    _timer?.cancel();
    if (_scene >= _sceneDurations.length) return;
    _timer = Timer(_sceneDurations[_scene], _advance);
  }

  void _advance() {
    if (!mounted || _scene >= 3) return;
    setState(() => _scene += 1);
    _scheduleNextScene();
  }

  void _skip() {
    if (_callbackFired) return;
    _callbackFired = true;
    _timer?.cancel();
    widget.onSkip();
  }

  void _complete() {
    if (_callbackFired) return;
    _callbackFired = true;
    _timer?.cancel();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('campaign-ending-overlay'),
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: ColoredBox(
        color: const Color(0xFF07111E),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/campaign_ending_dawn.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x42071523),
                    Color(0x12071523),
                    Color(0xC907111E),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildScene()),
                    if (_scene < 3)
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          key: const Key('campaign-ending-skip'),
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(
                              alpha: 0.82,
                            ),
                            backgroundColor: const Color(0x6607111E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                          ),
                          child: const Text('건너뛰기'),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _ProgressDots(activeScene: _scene),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScene() {
    return KeyedSubtree(
      key: Key('campaign-ending-scene-$_scene'),
      child: switch (_scene) {
        0 => _OpeningScene(),
        1 => _HeroesScene(),
        2 => _DawnScene(),
        _ => _FinalScene(onComplete: _complete),
      },
    );
  }
}

class _OpeningScene extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _EndingCopy(
          eyebrow: 'STAGE 30 · 최후의 밤',
          title: '마지막 공세가 멎었습니다.',
          body: '긴 밤을 메우던 발소리와 함성이\n마침내 고요해졌습니다.',
        ),
        const Spacer(flex: 2),
        Opacity(
          opacity: 0.72,
          child: _EnemyGroup(key: const Key('campaign-ending-enemy-group')),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _HeroesScene extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _EndingCopy(
          eyebrow: '함께 버틴 사람들',
          title: '우리가 지킨 것은\n성벽만이 아니었습니다.',
          body: '서로의 뒤를 지킨 마음이\n새벽까지 우리를 데려왔습니다.',
        ),
        const Spacer(flex: 2),
        const _HeroGroup(),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _DawnScene extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _EndingCopy(
          eyebrow: '다시 밝아오는 세계',
          title: '버텨낸 시간은\n결코 사라지지 않습니다.',
          body: '상처 난 성에도, 지친 마음에도\n다시 빛이 닿기 시작합니다.',
        ),
        const Spacer(),
        Image.asset(
          CampaignVisualCatalog.citadel.assetPath,
          key: const Key('campaign-ending-citadel'),
          width: 164,
          height: 164,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
        const _HeroGroup(compact: true),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _FinalScene extends StatelessWidget {
  const _FinalScene({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Image.asset(
          CampaignVisualCatalog.citadel.assetPath,
          width: 126,
          height: 126,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
        const SizedBox(height: 18),
        const Text(
          '힘든 하루를 지나 여기까지 온 당신에게.\n\n'
          '포기하지 않고 살아낸 오늘은\n'
          '이미 하나의 승리입니다.\n\n'
          '이 성과 이야기를 끝까지 지켜 주셔서 고맙습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.62,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: Color(0xDD07111E), blurRadius: 12),
              Shadow(color: Color(0xFF07111E), offset: Offset(0, 2)),
            ],
          ),
        ),
        const Spacer(),
        const Text(
          'PIXEL GUARD: WAVE',
          style: TextStyle(
            color: Color(0xFFFFD879),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            key: const Key('campaign-ending-result'),
            onPressed: onComplete,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF178D72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF67E6C2)),
              ),
            ),
            child: const Text(
              '결과 보기',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _EndingCopy extends StatelessWidget {
  const _EndingCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFD879),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.25,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Color(0xFF07111E), blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8EDF3),
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Color(0xFF07111E), blurRadius: 9)],
          ),
        ),
      ],
    );
  }
}

class _HeroGroup extends StatelessWidget {
  const _HeroGroup({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 47.0 : 62.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final kind in HeroKind.values)
          Transform.translate(
            offset: Offset(0, kind == HeroKind.knight ? -8 : 0),
            child: Image.asset(
              HeroVisualCatalog.byKind(kind).assetPath,
              key: Key('campaign-ending-hero-${kind.name}'),
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
      ],
    );
  }
}

class _EnemyGroup extends StatelessWidget {
  const _EnemyGroup({super.key});

  @override
  Widget build(BuildContext context) {
    const enemies = [
      EnemyKind.skeleton,
      EnemyKind.corruptedKnight,
      EnemyKind.bastionOverlord,
      EnemyKind.raider,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final kind in enemies)
          Image.asset(
            EnemyVisualCatalog.directionalBaseAssetPath(kind, 'south'),
            width: kind == EnemyKind.bastionOverlord ? 82 : 58,
            height: kind == EnemyKind.bastionOverlord ? 82 : 58,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => Image.asset(
              EnemyVisualCatalog.byKind(kind).assetPath,
              width: 58,
              height: 58,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.activeScene});

  final int activeScene;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final active = index == activeScene;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 22 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFFD879)
                : Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
