import 'package:depense_game/game/economy/coin_mill_income_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('periodic Coin Mill income advances only during an active Wave', () {
    expect(shouldAdvanceCoinMillIncome(waveActive: true), isTrue);
    expect(shouldAdvanceCoinMillIncome(waveActive: false), isFalse);
  });
}
