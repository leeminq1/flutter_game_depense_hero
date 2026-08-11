import 'package:depense_game/app/ending/campaign_ending_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only a successful unfinished Stage 30 run requests the ending', () {
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: false,
      ),
      isTrue,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 29,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: false,
      ),
      isFalse,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: false,
        stageFailed: true,
        endingCompleted: false,
      ),
      isFalse,
    );
    expect(
      shouldPlayCampaignEnding(
        stageNumber: 30,
        stageCleared: true,
        stageFailed: false,
        endingCompleted: true,
      ),
      isFalse,
    );
  });
}
