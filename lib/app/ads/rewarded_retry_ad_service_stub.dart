import 'rewarded_retry_ad_service.dart';

class UnsupportedRewardedRetryAdService implements RewardedRetryAdService {
  const UnsupportedRewardedRetryAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> preload() async {}

  @override
  Future<RewardedRetryAdResult> show() async {
    return RewardedRetryAdResult.unsupportedPlatform;
  }

  @override
  void dispose() {}
}

RewardedRetryAdService createRewardedRetryAdService() {
  return const UnsupportedRewardedRetryAdService();
}
