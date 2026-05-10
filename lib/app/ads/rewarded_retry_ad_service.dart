import 'rewarded_retry_ad_service_stub.dart'
    if (dart.library.io) 'rewarded_retry_ad_service_mobile.dart'
    as platform;

enum RewardedRetryAdResult {
  rewarded,
  loadFailed,
  showFailed,
  unsupportedPlatform,
}

abstract class RewardedRetryAdService {
  Future<void> initialize();

  Future<void> preload();

  Future<RewardedRetryAdResult> show();

  void dispose();
}

RewardedRetryAdService createRewardedRetryAdService() {
  return platform.createRewardedRetryAdService();
}
