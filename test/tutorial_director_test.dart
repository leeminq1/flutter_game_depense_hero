import 'package:depense_game/game/tutorial/tutorial_director.dart';
import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera step can be skipped after five seconds', () {
    final director = TutorialDirector();

    director.advanceTime(const Duration(seconds: 4));
    expect(director.snapshot.canSkip, isFalse);

    director.advanceTime(const Duration(seconds: 1));
    expect(director.snapshot.canSkip, isTrue);

    director.skipCurrentStep();
    expect(director.snapshot.step, TutorialStep.enemyDirections);
  });

  test('required placement events advance wall and tower lessons', () {
    final director = TutorialDirector(initialStep: TutorialStep.blockWithWall);

    director.record(const TutorialEvent.barrierPlaced(onRoad: true));
    expect(director.snapshot.step, TutorialStep.safeTower);

    director.record(
      const TutorialEvent.towerPlaced(onRoad: false, behindWall: false),
    );
    expect(director.snapshot.step, TutorialStep.dangerousTowerDemo);
  });

  test('danger demo uses tutorial-only 1.5 speed and explicit copy', () {
    final director = TutorialDirector(
      initialStep: TutorialStep.dangerousTowerDemo,
    );

    expect(director.snapshot.simulationSpeed, 1.5);
    expect(
      director.snapshot.body,
      '타워만으로는 몬스터를 막지 못합니다. 몬스터가 통과하면서 종류별 접촉 피해를 줍니다.',
    );
  });

  test('pause freezes tutorial timers', () {
    final director = TutorialDirector();

    director.setPaused(true);
    director.advanceTime(const Duration(seconds: 30));

    expect(director.snapshot.canSkip, isFalse);
    expect(director.snapshot.step, TutorialStep.cameraControls);
  });

  test('finishing danger demo restores normal speed', () {
    final director = TutorialDirector(
      initialStep: TutorialStep.dangerousTowerDemo,
    );

    director.recordDangerDemoCompleted();

    expect(director.snapshot.step, TutorialStep.combinedDefense);
    expect(director.snapshot.simulationSpeed, 1.0);
  });

  test('danger comparison auto advances after the shortened 1.5x demo', () {
    final director = TutorialDirector(
      initialStep: TutorialStep.dangerousTowerDemo,
    );

    director.advanceTime(const Duration(milliseconds: 2399));
    expect(director.snapshot.step, TutorialStep.dangerousTowerDemo);

    director.advanceTime(const Duration(milliseconds: 1));
    expect(director.snapshot.step, TutorialStep.combinedDefense);
  });
}
