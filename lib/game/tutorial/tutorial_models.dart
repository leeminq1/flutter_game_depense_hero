enum TutorialLaunchSource { newGame, mainMenu }

enum TutorialStep {
  cameraControls,
  enemyDirections,
  blockWithWall,
  safeTower,
  dangerousTowerDemo,
  combinedDefense,
  miniWave,
  recap,
  complete,
}

enum TutorialEventType {
  cameraChanged,
  barrierPlaced,
  towerPlaced,
  waveStarted,
  waveCleared,
}

class TutorialEvent {
  const TutorialEvent._(
    this.type, {
    this.onRoad = false,
    this.behindWall = false,
  });

  const TutorialEvent.cameraChanged() : this._(TutorialEventType.cameraChanged);

  const TutorialEvent.barrierPlaced({required bool onRoad})
    : this._(TutorialEventType.barrierPlaced, onRoad: onRoad);

  const TutorialEvent.towerPlaced({
    required bool onRoad,
    required bool behindWall,
  }) : this._(
         TutorialEventType.towerPlaced,
         onRoad: onRoad,
         behindWall: behindWall,
       );

  const TutorialEvent.waveStarted() : this._(TutorialEventType.waveStarted);

  const TutorialEvent.waveCleared() : this._(TutorialEventType.waveCleared);

  final TutorialEventType type;
  final bool onRoad;
  final bool behindWall;
}

class TutorialSnapshot {
  const TutorialSnapshot({
    required this.step,
    required this.title,
    required this.body,
    required this.canSkip,
    required this.simulationSpeed,
    required this.allowedActions,
  });

  final TutorialStep step;
  final String title;
  final String body;
  final bool canSkip;
  final double simulationSpeed;
  final Set<TutorialEventType> allowedActions;

  int get displayStep => switch (step) {
    TutorialStep.cameraControls => 1,
    TutorialStep.enemyDirections => 2,
    TutorialStep.blockWithWall => 3,
    TutorialStep.safeTower => 4,
    TutorialStep.dangerousTowerDemo => 5,
    TutorialStep.combinedDefense => 6,
    TutorialStep.miniWave => 7,
    TutorialStep.recap || TutorialStep.complete => 8,
  };
}
