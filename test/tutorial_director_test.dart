import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'camera step can be skipped after five seconds into the wall lesson',
    () {
      final director = TutorialDirector();

      director.advanceTime(const Duration(seconds: 4));
      expect(director.snapshot.canSkip, isFalse);

      director.advanceTime(const Duration(seconds: 1));
      expect(director.snapshot.canSkip, isTrue);

      director.skipCurrentStep();
      expect(director.snapshot.step, TutorialStep.lessonWallPlacement);
    },
  );

  test(
    'wall lesson accepts only the wood wall on the highlighted road cell',
    () {
      final director = TutorialDirector(
        initialStep: TutorialStep.lessonWallPlacement,
      );
      final target = TutorialStageDefinition.lessonWallCell;

      director.record(
        TutorialEvent.barrierPlaced(
          kind: BarrierKind.stoneWall,
          col: target.col,
          row: target.row,
        ),
      );
      director.record(
        const TutorialEvent.barrierPlaced(
          kind: BarrierKind.woodFence,
          col: 0,
          row: 0,
        ),
      );
      expect(director.snapshot.step, TutorialStep.lessonWallPlacement);

      director.record(
        TutorialEvent.barrierPlaced(
          kind: BarrierKind.woodFence,
          col: target.col,
          row: target.row,
        ),
      );
      expect(director.snapshot.step, TutorialStep.lessonWallObservation);

      director.record(const TutorialEvent.enemyBlockedByWall());
      expect(director.snapshot.step, TutorialStep.lessonTowerPlacement);
    },
  );

  test('tower lesson waits for a real pass-through observation', () {
    final director = TutorialDirector(
      initialStep: TutorialStep.lessonTowerPlacement,
    );
    final target = TutorialStageDefinition.lessonTowerCell;

    director.record(
      TutorialEvent.towerPlaced(
        kind: TowerKind.guardBarracks,
        col: target.col,
        row: target.row,
      ),
    );
    expect(director.snapshot.step, TutorialStep.lessonTowerPlacement);

    director.record(
      TutorialEvent.towerPlaced(
        kind: TowerKind.archer,
        col: target.col,
        row: target.row,
      ),
    );
    expect(director.snapshot.step, TutorialStep.lessonTowerObservation);
    expect(director.snapshot.simulationSpeed, 1.5);

    director.record(const TutorialEvent.enemyPassedTower());
    expect(director.snapshot.step, TutorialStep.practiceWallPlacement);
  });

  test('final practice guides three exact builds before enabling defense', () {
    final director = TutorialDirector(
      initialStep: TutorialStep.practiceWallPlacement,
    );

    _placeBarrier(director, TutorialStageDefinition.practiceWallCell);
    expect(director.snapshot.step, TutorialStep.practiceRoadTowerPlacement);

    _placeTower(director, TutorialStageDefinition.practiceRoadTowerCell);
    expect(director.snapshot.step, TutorialStep.practiceGrassTowerPlacement);

    _placeTower(director, TutorialStageDefinition.practiceGrassTowerCell);
    expect(director.snapshot.step, TutorialStep.practiceDefense);
    expect(
      director.snapshot.allowedActions,
      contains(TutorialEventType.waveStarted),
    );

    director.record(const TutorialEvent.waveCleared());
    expect(director.snapshot.step, TutorialStep.recap);
    director.continueCurrentStep();
    expect(director.snapshot.step, TutorialStep.complete);
  });

  test('pause freezes camera skip timer', () {
    final director = TutorialDirector();

    director.setPaused(true);
    director.advanceTime(const Duration(seconds: 30));

    expect(director.snapshot.canSkip, isFalse);
    expect(director.snapshot.step, TutorialStep.cameraControls);
  });
}

void _placeBarrier(TutorialDirector director, TutorialCell cell) {
  director.record(
    TutorialEvent.barrierPlaced(
      kind: BarrierKind.woodFence,
      col: cell.col,
      row: cell.row,
    ),
  );
}

void _placeTower(TutorialDirector director, TutorialCell cell) {
  director.record(
    TutorialEvent.towerPlaced(
      kind: TowerKind.archer,
      col: cell.col,
      row: cell.row,
    ),
  );
}
