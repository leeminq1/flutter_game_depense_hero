import 'package:depense_game/app/tutorial/tutorial_overlay.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a transparent guided card instead of a blocking dialog', (
    tester,
  ) async {
    final director = TutorialDirector();
    await _pumpOverlay(tester, director);

    expect(
      find.byKey(const ValueKey('tutorial-guidance-card')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('1 / 8'), findsOneWidget);
  });

  testWidgets('camera lesson keeps its skip control inside a compact card', (
    tester,
  ) async {
    final director = TutorialDirector();
    await _pumpOverlay(tester, director);
    director.advanceTime(TutorialDirector.cameraSkipDelay);
    await tester.pump();

    final card = find.byKey(const ValueKey('tutorial-guidance-card'));
    expect(tester.getSize(card).height, lessThanOrEqualTo(120));
    expect(find.byKey(const ValueKey('tutorial-skip-camera')), findsOneWidget);
  });

  testWidgets('direction lesson labels all four enemy fronts', (tester) async {
    final director = TutorialDirector();
    director.record(const TutorialEvent.cameraChanged());
    await _pumpOverlay(tester, director);

    expect(find.text('북'), findsOneWidget);
    expect(find.text('남'), findsOneWidget);
    expect(find.text('동'), findsOneWidget);
    expect(find.text('서'), findsOneWidget);
    expect(find.text('표시된 방향에서 적이 등장합니다.'), findsOneWidget);
    expect(
      tester.getCenter(find.text('남')).dy,
      lessThan(
        tester
                .getTopLeft(
                  find.byKey(const ValueKey('tutorial-guidance-card')),
                )
                .dy -
            12,
      ),
    );
  });

  testWidgets('danger lesson visibly compares pass-through contact damage', (
    tester,
  ) async {
    final director = TutorialDirector(
      initialStep: TutorialStep.dangerousTowerDemo,
    );
    await _pumpOverlay(tester, director);

    expect(find.byKey(const ValueKey('danger-placement-demo')), findsOneWidget);
    expect(find.text('1.5× 자동 시범'), findsOneWidget);
    expect(
      find.text('타워만으로는 몬스터를 막지 못합니다. 몬스터가 통과하면서 종류별 접촉 피해를 줍니다.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  TutorialDirector director,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TutorialOverlay(director: director, onComplete: () {}),
      ),
    ),
  );
  await tester.pump();
}
