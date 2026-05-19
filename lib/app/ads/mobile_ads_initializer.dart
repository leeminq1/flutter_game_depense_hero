import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<InitializationStatus>? _initialization;

Future<void> ensureMobileAdsInitialized() {
  _initialization ??= MobileAds.instance.initialize();
  return _initialization!.then((_) {});
}
