import 'package:depense_game/data/persistence/game_collection_models.dart';
import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/local_progress_store.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local progress treats incomplete stage records as zero stars', () {
    final incompleteRecord = StageProgressRecord()..stageNumber = 1;

    expect(stageRecordStarsForTest(incompleteRecord), 0);
  });

  test('production profile starts with Stage 1 only', () async {
    final store = await InMemoryProgressStore.open();
    final overview = await store.loadCampaignOverview(totalStages: 30);

    expect(overview.stages, hasLength(30));
    expect(overview.stages.where((stage) => stage.unlocked), hasLength(1));
    expect(overview.stages.first.unlocked, isTrue);
    expect(overview.stages.skip(1).every((stage) => !stage.unlocked), isTrue);
  });

  test('stage failures do not downgrade stars', () async {
    final store = await InMemoryProgressStore.open();

    await store.recordStageCompletion(
      stageNumber: 1,
      evaluation: const StageEvaluationResult(
        starsAwarded: 2,
        objectiveResults: [],
      ),
      totalStages: 30,
    );

    var overview = await store.loadCampaignOverview(totalStages: 30);
    expect(overview.stages[0].stars, 2);
    expect(overview.stages[1].unlocked, isTrue);

    await store.recordStageCompletion(
      stageNumber: 1,
      evaluation: const StageEvaluationResult(
        starsAwarded: 1,
        objectiveResults: [],
      ),
      totalStages: 30,
    );

    overview = await store.loadCampaignOverview(totalStages: 30);
    expect(overview.stages[0].stars, 2);
    expect(overview.stages[1].unlocked, isTrue);
  });

  test('recorded completion result preserves awarded stars', () async {
    final store = await InMemoryProgressStore.open();

    final result = await store.recordStageCompletion(
      stageNumber: 17,
      evaluation: const StageEvaluationResult(
        starsAwarded: 3,
        objectiveResults: [],
      ),
      totalStages: 30,
    );

    expect(result.starsAwarded, 3);
    expect(result.totalStars, 3);
  });

  test('stage 1 failure rewards do not create a resumable run', () async {
    final store = await InMemoryProgressStore.open();

    await store.recordStageCompletion(
      stageNumber: 1,
      evaluation: const StageEvaluationResult(
        starsAwarded: 0,
        objectiveResults: [],
      ),
      totalStages: 30,
    );

    final overview = await store.loadCampaignOverview(totalStages: 30);

    expect(overview.player.softCurrency, greaterThan(0));
    expect(overview.player.currentCampaignStage, 1);
    expect(overview.player.hasResumableRun, isFalse);
  });

  test('clearing stage 1 makes stage 2 resumable', () async {
    final store = await InMemoryProgressStore.open();

    await store.recordStageCompletion(
      stageNumber: 1,
      evaluation: const StageEvaluationResult(
        starsAwarded: 1,
        objectiveResults: [],
      ),
      totalStages: 30,
    );

    final overview = await store.loadCampaignOverview(totalStages: 30);

    expect(overview.player.currentCampaignStage, 2);
    expect(overview.player.hasResumableRun, isTrue);
  });
}
