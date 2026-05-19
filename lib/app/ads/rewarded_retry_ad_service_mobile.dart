import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_initializer.dart';
import 'rewarded_retry_ad_service.dart';

const String _androidTestInterstitialAdUnitId =
    'ca-app-pub-3940256099942544/1033173712';
const String _androidProductionInterstitialAdUnitId =
    'ca-app-pub-9991463854626958/6582278304';

class MobileRewardedRetryAdService implements RewardedRetryAdService {
  InterstitialAd? _ad;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get _isSupportedPlatform => Platform.isAndroid;

  String get _adUnitId {
    if (!kReleaseMode) {
      return _androidTestInterstitialAdUnitId;
    }
    return _androidProductionInterstitialAdUnitId;
  }

  @override
  Future<void> initialize() async {
    if (!_isSupportedPlatform || _isInitialized) {
      return;
    }
    await ensureMobileAdsInitialized();
    _isInitialized = true;
    await preload();
  }

  @override
  Future<void> preload() async {
    if (!_isSupportedPlatform || !_isInitialized || _ad != null || _isLoading) {
      return;
    }
    _isLoading = true;
    final completer = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (_) {
          _isLoading = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<RewardedRetryAdResult> show() async {
    if (!_isSupportedPlatform) {
      return RewardedRetryAdResult.unsupportedPlatform;
    }
    if (!_isInitialized) {
      await initialize();
    } else if (_ad == null) {
      await preload();
    }

    final ad = _ad;
    if (ad == null) {
      return RewardedRetryAdResult.loadFailed;
    }

    _ad = null;
    final completer = Completer<RewardedRetryAdResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(preload());
        if (!completer.isCompleted) {
          completer.complete(RewardedRetryAdResult.rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaited(preload());
        if (!completer.isCompleted) {
          completer.complete(RewardedRetryAdResult.showFailed);
        }
      },
    );

    try {
      await ad.show();
    } catch (_) {
      ad.dispose();
      unawaited(preload());
      if (!completer.isCompleted) {
        completer.complete(RewardedRetryAdResult.showFailed);
      }
    }
    return completer.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}

RewardedRetryAdService createRewardedRetryAdService() {
  return MobileRewardedRetryAdService();
}
