import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:depense_game/game/tutorial/tutorial_stage_definition.dart';
import 'package:flutter/foundation.dart';

class TutorialDirector extends ChangeNotifier {
  TutorialDirector({TutorialStep initialStep = TutorialStep.cameraControls})
    : _step = initialStep;

  static const cameraSkipDelay = Duration(seconds: 5);

  TutorialStep _step;
  Duration _stepElapsed = Duration.zero;
  bool _paused = false;

  TutorialSnapshot get snapshot => _snapshotFor(
    _step,
    canSkip:
        _step == TutorialStep.cameraControls && _stepElapsed >= cameraSkipDelay,
  );

  bool get isComplete => _step == TutorialStep.complete;

  void setPaused(bool value) {
    _paused = value;
  }

  void advanceTime(Duration elapsed) {
    if (_paused || elapsed <= Duration.zero) {
      return;
    }
    final wasSkippable = snapshot.canSkip;
    _stepElapsed += elapsed;
    if (wasSkippable != snapshot.canSkip) {
      notifyListeners();
    }
  }

  void record(TutorialEvent event) {
    if (!snapshot.accepts(event)) {
      return;
    }
    switch ((_step, event.type)) {
      case (TutorialStep.cameraControls, TutorialEventType.cameraChanged):
        _moveTo(TutorialStep.lessonWallPlacement);
      case (TutorialStep.lessonWallPlacement, TutorialEventType.barrierPlaced):
        _moveTo(TutorialStep.lessonWallObservation);
      case (
        TutorialStep.lessonWallObservation,
        TutorialEventType.enemyBlockedByWall,
      ):
        _moveTo(TutorialStep.lessonTowerPlacement);
      case (TutorialStep.lessonTowerPlacement, TutorialEventType.towerPlaced):
        _moveTo(TutorialStep.lessonTowerObservation);
      case (
        TutorialStep.lessonTowerObservation,
        TutorialEventType.enemyPassedTower,
      ):
        _moveTo(TutorialStep.practiceWallPlacement);
      case (
        TutorialStep.practiceWallPlacement,
        TutorialEventType.barrierPlaced,
      ):
        _moveTo(TutorialStep.practiceRoadTowerPlacement);
      case (
        TutorialStep.practiceRoadTowerPlacement,
        TutorialEventType.towerPlaced,
      ):
        _moveTo(TutorialStep.practiceGrassTowerPlacement);
      case (
        TutorialStep.practiceGrassTowerPlacement,
        TutorialEventType.towerPlaced,
      ):
        _moveTo(TutorialStep.practiceDefense);
      case (TutorialStep.practiceDefense, TutorialEventType.waveCleared):
        _moveTo(TutorialStep.recap);
      default:
        break;
    }
  }

  void continueCurrentStep() {
    if (_step == TutorialStep.recap) {
      _moveTo(TutorialStep.complete);
    }
  }

  void skipCurrentStep() {
    if (snapshot.canSkip) {
      _moveTo(TutorialStep.lessonWallPlacement);
    }
  }

  void restart() {
    _step = TutorialStep.cameraControls;
    _stepElapsed = Duration.zero;
    _paused = false;
    notifyListeners();
  }

  void _moveTo(TutorialStep next) {
    if (_step == next) {
      return;
    }
    _step = next;
    _stepElapsed = Duration.zero;
    notifyListeners();
  }
}

TutorialSnapshot _snapshotFor(TutorialStep step, {required bool canSkip}) {
  return switch (step) {
    TutorialStep.cameraControls => TutorialSnapshot(
      step: step,
      title: '전장을 둘러보세요',
      body: '두 손가락으로 확대·축소하고, 한 손가락으로 전장을 이동해 보세요.',
      canSkip: canSkip,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.cameraChanged},
    ),
    TutorialStep.lessonWallPlacement => TutorialSnapshot(
      step: step,
      title: '① 성벽으로 길 막기',
      body: '적은 북쪽 입구에서 성으로 내려옵니다. 아래 나무 울타리 카드를 누르고 빛나는 길 칸에 놓으세요.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.barrierPlaced},
      requiredBuild: TutorialBuildChoice.woodFence,
      targetCell: TutorialStageDefinition.lessonWallCell,
    ),
    TutorialStep.lessonWallObservation => TutorialSnapshot(
      step: step,
      title: '성벽이 적을 멈춥니다',
      body: '1.5× 실제 시범입니다. 적이 성벽 앞에서 멈춰 공격하는 모습을 확인하세요.',
      canSkip: false,
      simulationSpeed: 1.5,
      allowedActions: const {TutorialEventType.enemyBlockedByWall},
    ),
    TutorialStep.lessonTowerPlacement => TutorialSnapshot(
      step: step,
      title: '② 타워는 공격하지만 막지 못해요',
      body: '이번에는 아래 궁수 카드를 누르고 빛나는 길 칸에 놓으세요.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.towerPlaced},
      requiredBuild: TutorialBuildChoice.archer,
      targetCell: TutorialStageDefinition.lessonTowerCell,
    ),
    TutorialStep.lessonTowerObservation => TutorialSnapshot(
      step: step,
      title: '타워만 지으면 적이 통과합니다',
      body: '1.5× 실제 시범입니다. 타워는 적을 막지 못합니다. 적이 지나가면 타워의 에너지가 줄어듭니다.',
      canSkip: false,
      simulationSpeed: 1.5,
      allowedActions: const {TutorialEventType.enemyPassedTower},
    ),
    TutorialStep.practiceWallPlacement => TutorialSnapshot(
      step: step,
      title: '③ 직접 방어선을 완성하세요',
      body: '먼저 나무 울타리를 빛나는 길 칸에 놓아 적을 막으세요.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.barrierPlaced},
      requiredBuild: TutorialBuildChoice.woodFence,
      targetCell: TutorialStageDefinition.practiceWallCell,
    ),
    TutorialStep.practiceRoadTowerPlacement => TutorialSnapshot(
      step: step,
      title: '성벽 바로 뒤에 궁수 배치',
      body: '성 쪽의 빛나는 길 칸에 궁수를 놓으세요. 성벽이 막는 동안 뒤에서 공격합니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.towerPlaced},
      requiredBuild: TutorialBuildChoice.archer,
      targetCell: TutorialStageDefinition.practiceRoadTowerCell,
    ),
    TutorialStep.practiceGrassTowerPlacement => TutorialSnapshot(
      step: step,
      title: '초록색 땅에도 궁수 배치',
      body: '옆의 빛나는 초록색 칸에 궁수를 하나 더 놓으세요. 길 밖에서도 사거리 안의 적을 공격합니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.towerPlaced},
      requiredBuild: TutorialBuildChoice.archer,
      targetCell: TutorialStageDefinition.practiceGrassTowerCell,
    ),
    TutorialStep.practiceDefense => TutorialSnapshot(
      step: step,
      title: '④ 적 2명을 막아보세요',
      body: '준비가 끝났습니다. 아래 방어 시작을 누르면 북쪽에서 적 2명이 옵니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {
        TutorialEventType.waveStarted,
        TutorialEventType.waveCleared,
      },
    ),
    TutorialStep.recap => TutorialSnapshot(
      step: step,
      title: '훈련 완료',
      body: '성벽은 길을 막고, 타워는 뒤나 초록색 땅에서 공격합니다. 이 조합이 기본 방어선입니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {},
    ),
    TutorialStep.complete => TutorialSnapshot(
      step: step,
      title: '훈련 완료',
      body: '이제 Stage 1에서 직접 방어선을 만들어 보세요.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {},
    ),
  };
}
