import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/title_screen.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/persistence/store_models.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new game asks before clearing meaningful progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _CountingProgressStore(await InMemoryProgressStore.open());
    await store.recordStageCompletion(
      stageNumber: 1,
      evaluation: const StageEvaluationResult(
        starsAwarded: 2,
        objectiveResults: [],
      ),
      totalStages: CampaignData.totalStages,
    );

    await tester.pumpWidget(
      MaterialApp(home: TitleScreen(bootstrap: _TestBootstrap(store))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('PIXEL GUARD : WAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final continueTop = tester.getTopLeft(find.text('이어하기'));
    final newGameTop = tester.getTopLeft(find.text('새 게임'));
    expect(continueTop.dy, lessThan(newGameTop.dy));

    await tester.tap(find.text('새 게임'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('진행 기록을 삭제할까요?'), findsOneWidget);
    expect(store.resetCount, 0);

    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(store.resetCount, 0);

    await tester.tap(find.text('새 게임'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('삭제'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(store.resetCount, 1);
  });
}

class _TestBootstrap extends AppBootstrap {
  _TestBootstrap(this._store);

  final ProgressStore _store;

  @override
  ProgressStore get progressStore => _store;
}

class _CountingProgressStore implements ProgressStore {
  _CountingProgressStore(this._inner);

  final ProgressStore _inner;
  int resetCount = 0;

  @override
  Future<void> resetCampaignProgress() async {
    resetCount += 1;
    return _inner.resetCampaignProgress();
  }

  @override
  Future<AudioSettingsSnapshot> loadAudioSettings() =>
      _inner.loadAudioSettings();

  @override
  Future<void> saveAudioSettings(AudioSettingsController controller) =>
      _inner.saveAudioSettings(controller);

  @override
  Future<bool> isTutorialDismissed() => _inner.isTutorialDismissed();

  @override
  Future<void> setTutorialDismissed(bool dismissed) =>
      _inner.setTutorialDismissed(dismissed);

  @override
  Future<CampaignOverview> loadCampaignOverview({required int totalStages}) =>
      _inner.loadCampaignOverview(totalStages: totalStages);

  @override
  Future<StageCompletionResult> recordStageCompletion({
    required int stageNumber,
    required StageEvaluationResult evaluation,
    required int totalStages,
  }) => _inner.recordStageCompletion(
    stageNumber: stageNumber,
    evaluation: evaluation,
    totalStages: totalStages,
  );

  @override
  Future<RewardClaimResult> claimStageClearBonus({
    required int stageNumber,
    required int amount,
  }) => _inner.claimStageClearBonus(stageNumber: stageNumber, amount: amount);

  @override
  Future<bool> hasClaimedStageClearBonus(int stageNumber) =>
      _inner.hasClaimedStageClearBonus(stageNumber);

  @override
  Future<ResolvedMetaUpgrades> loadResolvedMetaUpgrades() =>
      _inner.loadResolvedMetaUpgrades();

  @override
  Future<MetaUpgradePurchaseResult> purchaseMetaUpgrade(String nodeId) =>
      _inner.purchaseMetaUpgrade(nodeId);
}
