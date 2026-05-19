import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_initializer.dart';
import 'result_banner_ad_service.dart';

const String _androidTestBannerAdUnitId =
    'ca-app-pub-3940256099942544/6300978111';
const String _androidProductionBannerAdUnitId =
    'ca-app-pub-9991463854626958/8810477080';

class MobileResultBannerAdService implements ResultBannerAdService {
  bool _isInitialized = false;

  bool get _isSupportedPlatform => Platform.isAndroid;

  String get _adUnitId {
    if (!kReleaseMode) {
      return _androidTestBannerAdUnitId;
    }
    return _androidProductionBannerAdUnitId;
  }

  @override
  Future<void> initialize() async {
    if (!_isSupportedPlatform || _isInitialized) {
      return;
    }
    await ensureMobileAdsInitialized();
    _isInitialized = true;
  }

  @override
  Future<ResultBannerAdHandle?> load() async {
    if (!_isSupportedPlatform) {
      return null;
    }
    if (!_isInitialized) {
      await initialize();
    }

    final completer = Completer<ResultBannerAdHandle?>();
    final ad = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(_MobileResultBannerAdHandle(ad as BannerAd));
          }
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );

    await ad.load();
    return completer.future;
  }

  @override
  void dispose() {}
}

class _MobileResultBannerAdHandle implements ResultBannerAdHandle {
  _MobileResultBannerAdHandle(this._ad);

  final BannerAd _ad;

  @override
  Widget buildWidget() => AdWidget(ad: _ad);

  @override
  void dispose() {
    _ad.dispose();
  }
}

ResultBannerAdService createResultBannerAdService() {
  return MobileResultBannerAdService();
}
