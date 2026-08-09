import 'dart:ui';

import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter/material.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.director,
    required this.onComplete,
  });

  final TutorialDirector director;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: director,
      builder: (context, _) {
        final snapshot = director.snapshot;
        if (snapshot.step == TutorialStep.complete) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                key: const ValueKey('tutorial-transparent-scrim'),
                painter: _TutorialSpotlightPainter(snapshot.step),
              ),
            ),
            if (snapshot.step == TutorialStep.enemyDirections)
              const IgnorePointer(child: _DirectionMarkers()),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Align(
                alignment: _cardAlignment(snapshot.step),
                child: _GuidanceCard(
                  snapshot: snapshot,
                  onContinue: director.continueCurrentStep,
                  onSkip: director.skipCurrentStep,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Alignment _cardAlignment(TutorialStep step) => switch (step) {
  TutorialStep.cameraControls ||
  TutorialStep.enemyDirections ||
  TutorialStep.dangerousTowerDemo => Alignment.bottomCenter,
  _ => Alignment.topCenter,
};

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.snapshot,
    required this.onContinue,
    required this.onSkip,
  });

  final TutorialSnapshot snapshot;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final showContinue =
        snapshot.step == TutorialStep.enemyDirections ||
        snapshot.step == TutorialStep.recap;
    final showSkip =
        snapshot.step == TutorialStep.cameraControls && snapshot.canSkip;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            key: const ValueKey('tutorial-guidance-card'),
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            decoration: BoxDecoration(
              color: const Color(0xEB0B1824),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF62D8B4), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8F75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${snapshot.displayStep} / 8',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        snapshot.title,
                        style: const TextStyle(
                          color: Color(0xFFFFE29A),
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (showSkip) ...[
                      const SizedBox(width: 6),
                      TextButton.icon(
                        key: const ValueKey('tutorial-skip-camera'),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD9C3FF),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: const Text(
                          '건너뛰기',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.body,
                  style: const TextStyle(
                    color: Color(0xFFE5ECF3),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (snapshot.step == TutorialStep.enemyDirections) ...[
                  const SizedBox(height: 5),
                  const Text(
                    '표시된 방향에서 적이 등장합니다.',
                    style: TextStyle(
                      color: Color(0xFF75E6C4),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (snapshot.step == TutorialStep.dangerousTowerDemo) ...[
                  const SizedBox(height: 10),
                  const _DangerPlacementDemo(),
                ],
                if (showContinue) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('tutorial-continue'),
                      onPressed: onContinue,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        snapshot.step == TutorialStep.recap ? '훈련 완료' : '확인',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerPlacementDemo extends StatelessWidget {
  const _DangerPlacementDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('danger-placement-demo'),
      height: 76,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101F2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF32495A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1.5× 자동 시범',
            style: TextStyle(
              color: Color(0xFFFFC96B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: TutorialDirector.dangerDemoDuration,
                  builder: (context, progress, _) {
                    final x = 8 + progress * (constraints.maxWidth - 42);
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned.fill(
                          top: 18,
                          bottom: 17,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9A8054),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * .47,
                          child: const Icon(
                            Icons.castle_rounded,
                            color: Color(0xFF72B9F1),
                            size: 31,
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * .43,
                          top: 0,
                          width: 52,
                          child: LinearProgressIndicator(
                            value: (1 - progress * .55).clamp(0, 1),
                            minHeight: 4,
                            color: const Color(0xFF7EDD85),
                            backgroundColor: const Color(0xFF4B2530),
                          ),
                        ),
                        Positioned(
                          left: x,
                          child: const Icon(
                            Icons.bug_report_rounded,
                            color: Color(0xFFF17872),
                            size: 25,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionMarkers extends StatelessWidget {
  const _DirectionMarkers();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Align(alignment: Alignment(0, -0.8), child: _DirectionBadge('북')),
        Align(alignment: Alignment(0, 0.25), child: _DirectionBadge('남')),
        Align(alignment: Alignment(0.88, -0.15), child: _DirectionBadge('동')),
        Align(alignment: Alignment(-0.88, -0.15), child: _DirectionBadge('서')),
      ],
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xE61A3D55),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF75E6C4), width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter(this.step);

  final TutorialStep step;

  @override
  void paint(Canvas canvas, Size size) {
    final spotlight = switch (step) {
      TutorialStep.cameraControls => Rect.fromLTWH(
        size.width * .08,
        size.height * .12,
        size.width * .84,
        size.height * .54,
      ),
      TutorialStep.enemyDirections => Rect.fromLTWH(
        size.width * .04,
        size.height * .08,
        size.width * .92,
        size.height * .63,
      ),
      TutorialStep.blockWithWall => Rect.fromLTWH(
        size.width * .38,
        size.height * .35,
        size.width * .24,
        size.height * .16,
      ),
      TutorialStep.safeTower || TutorialStep.combinedDefense => Rect.fromLTWH(
        size.width * .2,
        size.height * .3,
        size.width * .6,
        size.height * .28,
      ),
      _ => Rect.fromLTWH(
        12,
        size.height * .12,
        size.width - 24,
        size.height * .55,
      ),
    };
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(spotlight, const Radius.circular(20)));
    final scrim = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(scrim, Paint()..color = const Color(0x65000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlight, const Radius.circular(20)),
      Paint()
        ..color = const Color(0xFF75E6C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) =>
      oldDelegate.step != step;
}
