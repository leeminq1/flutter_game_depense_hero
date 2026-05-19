import 'package:depense_game/app/ads/result_banner_ad_service_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported result banner service resolves without an ad', () async {
    const service = UnsupportedResultBannerAdService();

    await service.initialize();

    expect(await service.load(), isNull);
  });

  testWidgets('static result banner handle can occupy the reserved slot', (
    tester,
  ) async {
    const bannerKey = Key('result-banner-placeholder');
    const handle = StaticResultBannerAdHandle(
      ColoredBox(key: bannerKey, color: Colors.red),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(width: 320, height: 50, child: handle.buildWidget()),
        ),
      ),
    );

    expect(find.byKey(bannerKey), findsOneWidget);
    expect(tester.getSize(find.byType(SizedBox)), const Size(320, 50));
  });
}
