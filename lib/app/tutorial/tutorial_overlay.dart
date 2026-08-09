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
            if (snapshot.step == TutorialStep.cameraControls)
              const IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('tutorial-transparent-scrim'),
                  painter: _CameraGuidePainter(),
                ),
              ),
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
  TutorialStep.lessonWallObservation ||
  TutorialStep.lessonTowerObservation => Alignment.bottomCenter,
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
    final showContinue = snapshot.step == TutorialStep.recap;
    final showSkip =
        snapshot.step == TutorialStep.cameraControls && snapshot.canSkip;
    final isObservation =
        snapshot.step == TutorialStep.lessonWallObservation ||
        snapshot.step == TutorialStep.lessonTowerObservation;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            key: const ValueKey('tutorial-guidance-card'),
            padding: const EdgeInsets.fromLTRB(15, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xEE081824),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF62D8B4), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 7),
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
                        '${snapshot.displayStep} / 5',
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
                    if (showSkip)
                      TextButton.icon(
                        key: const ValueKey('tutorial-skip-camera'),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD9C3FF),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: const Text('건너뛰기'),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  snapshot.body,
                  style: const TextStyle(
                    color: Color(0xFFE5ECF3),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isObservation) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: Color(0xFFFFC96B),
                        size: 18,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '1.5× 실제 시범',
                        style: TextStyle(
                          color: Color(0xFFFFC96B),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
                if (showContinue) ...[
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('tutorial-continue'),
                      onPressed: onContinue,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('훈련 완료'),
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

class _CameraGuidePainter extends CustomPainter {
  const _CameraGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final battlefield = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, size.height * .1, size.width - 20, size.height * .58),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      battlefield,
      Paint()
        ..color = const Color(0xFF75E6C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
