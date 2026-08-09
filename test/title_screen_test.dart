import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/title_screen.dart';
import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progression_models.dart';
import 'package:depense_game/data/persistence/store_models.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
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

    await _pumpMenu(tester, store);

    final continueTop = tester.getTopLeft(_continueButtonFinder);
    final newGameTop = tester.getTopLeft(_newGameButtonFinder);
    expect(continueTop.dy, lessThan(newGameTop.dy));

    await tester.tap(_newGameButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(store.resetCount, 0);

    await tester.tap(find.byType(TextButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(store.resetCount, 0);

    await tester.tap(_newGameButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(store.resetCount, 1);
    expect(
      find.byKey(const ValueKey('tutorial-guidance-card')),
      findsOneWidget,
    );
  });

  testWidgets('main menu exposes tutorial as a first-class action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _CountingProgressStore(await InMemoryProgressStore.open());

    await _pumpMenu(tester, store);

    final tutorialButton = find.byKey(const ValueKey('main-menu-tutorial'));
    expect(tutorialButton, findsOneWidget);
    await tester.tap(tutorialButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('훈련장'), findsWidgets);
    expect(
      find.byKey(const ValueKey('tutorial-guidance-card')),
      findsOneWidget,
    );
  });

  testWidgets('continue is available for noncontiguous review progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _CountingProgressStore(await InMemoryProgressStore.open());
    await store.recordStageCompletion(
      stageNumber: 5,
      evaluation: const StageEvaluationResult(
        starsAwarded: 2,
        objectiveResults: [],
      ),
      totalStages: CampaignData.totalStages,
    );

    await _pumpMenu(tester, store);

    final continueTop = tester.getTopLeft(_continueButtonFinder);
    final newGameTop = tester.getTopLeft(_newGameButtonFinder);
    expect(continueTop.dy, lessThan(newGameTop.dy));

    await tester.tap(_continueButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('STAGE 6'), findsOneWidget);
  });

  testWidgets('main menu stat chips reflect campaign overview progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _CountingProgressStore(
      await InMemoryProgressStore.open(),
      overview: _overviewWithNineteenClears(),
    );

    await _pumpMenu(tester, store);

    expect(find.text('Lv.19'), findsOneWidget);
    expect(find.text('55'), findsOneWidget);
    expect(find.text('19/30'), findsNothing);
    expect(find.text('스테이지 20부터 재개'), findsOneWidget);
  });
}

Finder get _continueButtonFinder =>
    find.byKey(const ValueKey('main-menu-continue'));

Finder get _newGameButtonFinder =>
    find.byKey(const ValueKey('main-menu-new-game'));

Future<void> _pumpMenu(WidgetTester tester, ProgressStore store) async {
  await tester.pumpWidget(
    MaterialApp(home: TitleScreen(bootstrap: _TestBootstrap(store))),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await tester.tap(find.text('PIXEL GUARD : WAVE').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

class _TestBootstrap extends AppBootstrap {
  _TestBootstrap(this._store) {
    audioSettingsController = AudioSettingsController();
    audioService = GameAudioService(audioSettingsController);
  }

  final ProgressStore _store;

  @override
  ProgressStore get progressStore => _store;
}

class _CountingProgressStore implements ProgressStore {
  _CountingProgressStore(this._inner, {CampaignOverview? overview})
    : _overview = overview;

  final ProgressStore _inner;
  final CampaignOverview? _overview;
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
      _overview != null
      ? Future.value(_overview)
      : _inner.loadCampaignOverview(totalStages: totalStages);

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

CampaignOverview _overviewWithNineteenClears() {
  final stages = List<StageProgressSnapshot>.generate(30, (index) {
    final stageNumber = index + 1;
    final cleared = stageNumber <= 19;
    final stars = switch (stageNumber) {
      <= 18 => 3,
      19 => 1,
      _ => 0,
    };
    return StageProgressSnapshot(
      stageNumber: stageNumber,
      unlocked: stageNumber <= 20,
      stars: stars,
      cleared: cleared,
      description: 'Stage $stageNumber',
      objectives: const [],
      unlockRequirementLabels: const [],
      lockReason: null,
    );
  });

  return CampaignOverview(
    player: const PlayerProgressSnapshot(
      accountLevel: 26,
      totalXp: 3750,
      softCurrency: 0,
      premiumCurrency: 0,
      currentCampaignStage: 20,
      clearedStageCount: 19,
      hasResumableRun: true,
    ),
    stages: stages,
    metaUpgrades: const [],
  );
}
