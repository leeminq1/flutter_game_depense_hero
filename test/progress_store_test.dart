import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stage clears unlock the next stage and failures do not downgrade stars',
    () async {
      final store = await InMemoryProgressStore.open();

      await store.recordStageCompletion(
        stageNumber: 1,
        evaluation: const StageEvaluationResult(
          starsAwarded: 0,
          objectiveResults: [],
        ),
        totalStages: 30,
      );

      var overview = await store.loadCampaignOverview(totalStages: 30);
      expect(overview.stages[0].stars, 0);
      expect(overview.stages[1].unlocked, isFalse);

      await store.recordStageCompletion(
        stageNumber: 1,
        evaluation: const StageEvaluationResult(
          starsAwarded: 2,
          objectiveResults: [],
        ),
        totalStages: 30,
      );

      overview = await store.loadCampaignOverview(totalStages: 30);
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
    },
  );
}
