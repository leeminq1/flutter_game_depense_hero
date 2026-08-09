import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';

enum TutorialLaunchSource { newGame, mainMenu }

enum TutorialStep {
  cameraControls,
  lessonWallPlacement,
  lessonWallObservation,
  lessonTowerPlacement,
  lessonTowerObservation,
  practiceWallPlacement,
  practiceRoadTowerPlacement,
  practiceGrassTowerPlacement,
  practiceDefense,
  recap,
  complete,
}

enum TutorialBuildChoice { woodFence, archer }

enum TutorialEventType {
  cameraChanged,
  barrierPlaced,
  towerPlaced,
  enemyBlockedByWall,
  enemyPassedTower,
  waveStarted,
  waveCleared,
}

class TutorialCell {
  const TutorialCell(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is TutorialCell && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);
}

class TutorialEvent {
  const TutorialEvent._(
    this.type, {
    this.barrierKind,
    this.towerKind,
    this.col,
    this.row,
  });

  const TutorialEvent.cameraChanged() : this._(TutorialEventType.cameraChanged);

  const TutorialEvent.barrierPlaced({
    required BarrierKind kind,
    required int col,
    required int row,
  }) : this._(
         TutorialEventType.barrierPlaced,
         barrierKind: kind,
         col: col,
         row: row,
       );

  const TutorialEvent.towerPlaced({
    required TowerKind kind,
    required int col,
    required int row,
  }) : this._(
         TutorialEventType.towerPlaced,
         towerKind: kind,
         col: col,
         row: row,
       );

  const TutorialEvent.enemyBlockedByWall()
    : this._(TutorialEventType.enemyBlockedByWall);

  const TutorialEvent.enemyPassedTower()
    : this._(TutorialEventType.enemyPassedTower);

  const TutorialEvent.waveStarted() : this._(TutorialEventType.waveStarted);

  const TutorialEvent.waveCleared() : this._(TutorialEventType.waveCleared);

  final TutorialEventType type;
  final BarrierKind? barrierKind;
  final TowerKind? towerKind;
  final int? col;
  final int? row;

  TutorialCell? get cell =>
      col == null || row == null ? null : TutorialCell(col!, row!);
}

class TutorialSnapshot {
  const TutorialSnapshot({
    required this.step,
    required this.title,
    required this.body,
    required this.canSkip,
    required this.simulationSpeed,
    required this.allowedActions,
    this.requiredBuild,
    this.targetCell,
  });

  final TutorialStep step;
  final String title;
  final String body;
  final bool canSkip;
  final double simulationSpeed;
  final Set<TutorialEventType> allowedActions;
  final TutorialBuildChoice? requiredBuild;
  final TutorialCell? targetCell;

  int get displayStep => switch (step) {
    TutorialStep.cameraControls => 1,
    TutorialStep.lessonWallPlacement || TutorialStep.lessonWallObservation => 2,
    TutorialStep.lessonTowerPlacement ||
    TutorialStep.lessonTowerObservation => 3,
    TutorialStep.practiceWallPlacement ||
    TutorialStep.practiceRoadTowerPlacement ||
    TutorialStep.practiceGrassTowerPlacement => 4,
    TutorialStep.practiceDefense ||
    TutorialStep.recap ||
    TutorialStep.complete => 5,
  };

  bool accepts(TutorialEvent event) {
    if (!allowedActions.contains(event.type)) {
      return false;
    }
    final expectedCell = targetCell;
    if (expectedCell != null && event.cell != expectedCell) {
      return false;
    }
    return switch (requiredBuild) {
      TutorialBuildChoice.woodFence =>
        event.barrierKind == BarrierKind.woodFence,
      TutorialBuildChoice.archer => event.towerKind == TowerKind.archer,
      null => true,
    };
  }
}
