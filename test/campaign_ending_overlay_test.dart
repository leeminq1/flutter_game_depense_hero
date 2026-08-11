import 'package:depense_game/app/widgets/campaign_ending_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpEnding(
    WidgetTester tester, {
    VoidCallback? onComplete,
    VoidCallback? onSkip,
  }) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampaignEndingOverlay(
            onComplete: onComplete ?? () {},
            onSkip: onSkip ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.drag(
      find.byKey(const Key('campaign-ending-overlay')),
      Offset(dx, 0),
    );
    await tester.pump();
  }

  testWidgets('bidirectional swipes reveal scenes and stay within bounds', (
    tester,
  ) async {
    await pumpEnding(tester);

    expect(find.byKey(const Key('campaign-ending-overlay')), findsOneWidget);
    expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);
    expect(find.text('마지막 공세가 멎었습니다.'), findsOneWidget);
    expect(
      find.byKey(const Key('campaign-ending-enemy-group')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('campaign-ending-citadel')), findsNothing);

    await swipe(tester, 90);
    expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);

    await swipe(tester, -90);
    expect(find.byKey(const Key('campaign-ending-scene-1')), findsOneWidget);
    expect(
      find.byKey(const Key('campaign-ending-hero-knight')),
      findsOneWidget,
    );

    await swipe(tester, 90);
    expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);

    await swipe(tester, -90);
    await swipe(tester, -90);
    expect(find.byKey(const Key('campaign-ending-scene-2')), findsOneWidget);
    expect(find.byKey(const Key('campaign-ending-citadel')), findsOneWidget);

    await swipe(tester, -90);
    expect(find.byKey(const Key('campaign-ending-scene-3')), findsOneWidget);
    expect(find.textContaining('힘든 하루를 지나'), findsOneWidget);
    expect(find.byKey(const Key('campaign-ending-result')), findsOneWidget);

    await swipe(tester, -90);
    expect(find.byKey(const Key('campaign-ending-scene-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waiting and tapping do not advance, while skip fires once', (
    tester,
  ) async {
    var skipCount = 0;
    await pumpEnding(tester, onSkip: () => skipCount += 1);

    await tester.pump(const Duration(seconds: 15));
    await tester.tap(find.byKey(const Key('campaign-ending-overlay')));
    await tester.pump();
    expect(find.byKey(const Key('campaign-ending-scene-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('campaign-ending-skip')));
    await tester.pump();
    expect(skipCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result button completes ending once', (tester) async {
    var completeCount = 0;
    await pumpEnding(tester, onComplete: () => completeCount += 1);

    for (var index = 0; index < 3; index += 1) {
      await swipe(tester, -90);
    }
    await tester.tap(find.byKey(const Key('campaign-ending-result')));
    await tester.pump();

    expect(completeCount, 1);
    expect(tester.takeException(), isNull);
  });
}
