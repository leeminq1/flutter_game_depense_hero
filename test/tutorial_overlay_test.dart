import 'package:depense_game/app/tutorial/tutorial_overlay.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a compact transparent five-part guide', (tester) async {
    final director = TutorialDirector();
    await _pumpOverlay(tester, director);

    expect(
      find.byKey(const ValueKey('tutorial-guidance-card')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('1 / 5'), findsOneWidget);
  });

  testWidgets(
    'wall lesson explains the single north entrance and exact action',
    (tester) async {
      final director = TutorialDirector(
        initialStep: TutorialStep.lessonWallPlacement,
      );
      await _pumpOverlay(tester, director);

      expect(find.textContaining('북쪽 입구'), findsOneWidget);
      expect(find.textContaining('빛나는 길 칸'), findsOneWidget);
      expect(find.textContaining('나무 울타리'), findsOneWidget);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('tutorial-guidance-card')))
            .center
            .dy,
        greaterThan(450),
      );
    },
  );

  testWidgets('tower observation uses real-game copy and no fake animation', (
    tester,
  ) async {
    final director = TutorialDirector(
      initialStep: TutorialStep.lessonTowerObservation,
    );
    await _pumpOverlay(tester, director);

    expect(find.text('1.5× 실제 시범'), findsOneWidget);
    expect(find.textContaining('타워는 적을 막지 못합니다'), findsOneWidget);
    expect(find.textContaining('에너지가 줄어듭니다'), findsOneWidget);
    expect(find.byKey(const ValueKey('danger-placement-demo')), findsNothing);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  TutorialDirector director,
) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TutorialOverlay(director: director, onComplete: () {}),
      ),
    ),
  );
  await tester.pump();
}
