import 'package:depense_game/app/ads/rewarded_retry_bonus_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rewarded retry bonus stacks per stage', () {
    final tracker = RewardedRetryBonusTracker();

    expect(tracker.bonusForStage(1), 0);
    expect(tracker.addRewardForStage(1), 200);
    expect(tracker.addRewardForStage(1), 400);
    expect(tracker.bonusForStage(1), 400);
  });

  test('rewarded retry bonus resets when stage changes or tracker resets', () {
    final tracker = RewardedRetryBonusTracker();

    expect(tracker.addRewardForStage(1), 200);
    expect(tracker.bonusForStage(2), 0);
    expect(tracker.addRewardForStage(2), 200);
    expect(tracker.bonusForStage(1), 0);

    tracker.reset();
    expect(tracker.bonusForStage(2), 0);
  });
}
