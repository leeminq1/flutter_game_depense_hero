import 'package:depense_game/game/tutorial/tutorial_models.dart';
import 'package:flutter/foundation.dart';

class TutorialDirector extends ChangeNotifier {
  TutorialDirector({TutorialStep initialStep = TutorialStep.cameraControls})
    : _step = initialStep;

  static const cameraSkipDelay = Duration(seconds: 5);
  static const dangerDemoDuration = Duration(milliseconds: 2400);

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
    if (_step == TutorialStep.dangerousTowerDemo &&
        _stepElapsed >= dangerDemoDuration) {
      _moveTo(TutorialStep.combinedDefense);
      return;
    }
    if (wasSkippable != snapshot.canSkip) {
      notifyListeners();
    }
  }

  void record(TutorialEvent event) {
    switch ((_step, event.type)) {
      case (TutorialStep.cameraControls, TutorialEventType.cameraChanged):
        _moveTo(TutorialStep.enemyDirections);
      case (TutorialStep.blockWithWall, TutorialEventType.barrierPlaced)
          when event.onRoad:
        _moveTo(TutorialStep.safeTower);
      case (TutorialStep.safeTower, TutorialEventType.towerPlaced)
          when !event.onRoad:
        _moveTo(TutorialStep.dangerousTowerDemo);
      case (TutorialStep.combinedDefense, TutorialEventType.towerPlaced)
          when event.behindWall:
        _moveTo(TutorialStep.miniWave);
      case (TutorialStep.miniWave, TutorialEventType.waveCleared):
        _moveTo(TutorialStep.recap);
      default:
        break;
    }
  }

  void continueCurrentStep() {
    switch (_step) {
      case TutorialStep.enemyDirections:
        _moveTo(TutorialStep.blockWithWall);
      case TutorialStep.recap:
        _moveTo(TutorialStep.complete);
      default:
        break;
    }
  }

  void skipCurrentStep() {
    if (snapshot.canSkip) {
      _moveTo(TutorialStep.enemyDirections);
    }
  }

  void recordDangerDemoCompleted() {
    if (_step == TutorialStep.dangerousTowerDemo) {
      _moveTo(TutorialStep.combinedDefense);
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
    TutorialStep.enemyDirections => TutorialSnapshot(
      step: step,
      title: '적이 오는 방향',
      body: '북·남·동·서 중 표시된 방향에서 적이 등장합니다. 길은 성채까지 이어집니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {},
    ),
    TutorialStep.blockWithWall => TutorialSnapshot(
      step: step,
      title: '성벽으로 길 막기',
      body: '길 위의 강조 칸에 성벽을 배치하세요. 몬스터는 성벽 앞에서 멈춰 공격합니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.barrierPlaced},
    ),
    TutorialStep.safeTower => TutorialSnapshot(
      step: step,
      title: '안전한 타워 배치',
      body: '초록색 땅에 타워를 배치하세요. 타워는 길 밖에서도 사거리 안의 적을 공격합니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.towerPlaced},
    ),
    TutorialStep.dangerousTowerDemo => TutorialSnapshot(
      step: step,
      title: '타워만 세우면 위험해요',
      body: '타워만으로는 몬스터를 막지 못합니다. 몬스터가 통과하면서 종류별 접촉 피해를 줍니다.',
      canSkip: false,
      simulationSpeed: 1.5,
      allowedActions: const {},
    ),
    TutorialStep.combinedDefense => TutorialSnapshot(
      step: step,
      title: '성벽 뒤에 타워 배치',
      body: '성벽은 길을 막고 타워는 뒤에서 공격합니다. 강조된 안전 칸에 타워를 배치하세요.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {TutorialEventType.towerPlaced},
    ),
    TutorialStep.miniWave => TutorialSnapshot(
      step: step,
      title: '미니 WAVE 방어',
      body: '직접 WAVE를 시작하고 방어를 확인하세요. 일시정지 버튼도 언제든 사용할 수 있습니다.',
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
      body: '출현 방향 확인 · 성벽으로 차단 · 타워는 길 밖이나 성벽 뒤 · 성벽과 타워를 함께 사용',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {},
    ),
    TutorialStep.complete => TutorialSnapshot(
      step: step,
      title: '훈련 완료',
      body: '이제 성채를 지킬 준비가 되었습니다.',
      canSkip: false,
      simulationSpeed: 1,
      allowedActions: const {},
    ),
  };
}
