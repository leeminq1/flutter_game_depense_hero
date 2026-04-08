import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter/foundation.dart';

class TowerBranchChoiceDetails {
  const TowerBranchChoiceDetails({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class SelectedTowerDetails {
  const SelectedTowerDetails({
    required this.kind,
    required this.label,
    required this.level,
    required this.upgradeCost,
    required this.sellValue,
    required this.shortDescription,
    required this.abilityDescription,
    required this.canUpgrade,
    required this.canChooseBranch,
    required this.branchChoices,
    this.branchId,
    this.branchLabel,
  });

  final TowerKind kind;
  final String label;
  final int level;
  final int upgradeCost;
  final int sellValue;
  final String shortDescription;
  final String abilityDescription;
  final bool canUpgrade;
  final bool canChooseBranch;
  final List<TowerBranchChoiceDetails> branchChoices;
  final String? branchId;
  final String? branchLabel;
}

class GameSessionController extends ChangeNotifier {
  int stageNumber = 1;
  int totalStages = 30;
  String stageTitle = 'Stage 1 - Forest Edge';
  int currentWave = 0;
  int totalWaves = 0;
  int coins = 0;
  int baseHealth = 0;
  int maxBaseHealth = 0;
  bool waveInProgress = false;
  bool stageCleared = false;
  bool stageFailed = false;
  bool isPaused = false;
  int towersBuilt = 0;
  int maxTowerLevel = 1;
  TowerKind? selectedBuildable;
  SelectedTowerDetails? selectedTower;
  Set<String> builtTowerKinds = const {};
  String statusText = '전장에 타워를 배치하거나 설치된 타워를 선택하세요.';

  // UI helper fields mirrored from the live game session.
  int _remainingEnemies = 0;
  double _speedMultiplier = 1.0;

  int get remainingEnemies => _remainingEnemies;
  double get speedMultiplier => _speedMultiplier;
  String get speedLabel => '${_speedMultiplier.toStringAsFixed(1)}x';

  void hydrate({
    required int stageNumber,
    required int totalStages,
    required String stageTitle,
    required int totalWaves,
    required int coins,
    required int baseHealth,
  }) {
    this.stageNumber = stageNumber;
    this.totalStages = totalStages;
    this.stageTitle = stageTitle;
    this.totalWaves = totalWaves;
    this.coins = coins;
    this.baseHealth = baseHealth;
    maxBaseHealth = baseHealth;
    towersBuilt = 0;
    maxTowerLevel = 1;
    builtTowerKinds = const {};
    selectedTower = null;
    selectedBuildable = null;
    _speedMultiplier = 1.0;
    _remainingEnemies = 0;
    notifyListeners();
  }

  void setSelectedBuildable(TowerKind? towerKind) {
    selectedBuildable = towerKind;
    if (towerKind != null) {
      selectedTower = null;
    }
    notifyListeners();
  }

  void setSelectedTower(SelectedTowerDetails? details) {
    selectedTower = details;
    if (details != null) {
      selectedBuildable = null;
    }
    notifyListeners();
  }

  void setSpeedMultiplier(double speed) {
    _speedMultiplier = speed;
    notifyListeners();
  }

  void updateRuntime({
    required int currentWave,
    required int coins,
    required int baseHealth,
    required bool waveInProgress,
    required bool stageCleared,
    required bool stageFailed,
    required bool isPaused,
    required int towersBuilt,
    required int maxTowerLevel,
    required Set<String> builtTowerKinds,
    required String statusText,
    int remainingEnemies = 0,
  }) {
    this.currentWave = currentWave;
    this.coins = coins;
    this.baseHealth = baseHealth;
    this.waveInProgress = waveInProgress;
    this.stageCleared = stageCleared;
    this.stageFailed = stageFailed;
    this.isPaused = isPaused;
    this.towersBuilt = towersBuilt;
    this.maxTowerLevel = maxTowerLevel;
    this.builtTowerKinds = Set<String>.from(builtTowerKinds);
    this.statusText = statusText;
    _remainingEnemies = remainingEnemies;
    notifyListeners();
  }
}
