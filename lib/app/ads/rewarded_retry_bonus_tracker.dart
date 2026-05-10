class RewardedRetryBonusTracker {
  RewardedRetryBonusTracker({this.rewardCoins = 200});

  final int rewardCoins;
  int? _stageNumber;
  int _bonusCoins = 0;

  int bonusForStage(int stageNumber) {
    return _stageNumber == stageNumber ? _bonusCoins : 0;
  }

  int addRewardForStage(int stageNumber) {
    if (_stageNumber != stageNumber) {
      _stageNumber = stageNumber;
      _bonusCoins = 0;
    }
    _bonusCoins += rewardCoins;
    return _bonusCoins;
  }

  void reset() {
    _stageNumber = null;
    _bonusCoins = 0;
  }
}
