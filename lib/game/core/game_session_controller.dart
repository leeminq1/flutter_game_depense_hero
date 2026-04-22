import 'package:depense_game/game/models/tower_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
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
    this.economyIncomePerTick,
    this.economyInterval,
    this.economyIncomePerSecond,
    this.economyCycleBonus,
    this.economyBreakEvenSeconds,
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
  final int? economyIncomePerTick;
  final double? economyInterval;
  final double? economyIncomePerSecond;
  final int? economyCycleBonus;
  final double? economyBreakEvenSeconds;
  final String? branchId;
  final String? branchLabel;
}

class SelectedHeroDetails {
  const SelectedHeroDetails({
    required this.kind,
    required this.label,
    required this.level,
    required this.upgradeCost,
    required this.shortDescription,
    required this.abilityLabel,
    required this.abilityDescription,
    required this.canUpgrade,
  });

  final HeroKind kind;
  final String label;
  final int level;
  final int upgradeCost;
  final String shortDescription;
  final String abilityLabel;
  final String abilityDescription;
  final bool canUpgrade;
}

class GameSessionController extends ChangeNotifier {
  int stageNumber = 1;
  int totalStages = 30;
  int actNumber = 1;
  String stageTitle = 'Stage 1';
  int currentWave = 0;
  int totalWaves = 0;
  String loopLabel = 'Wave';
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
  HeroKind? selectedHeroBuildable;
  SelectedTowerDetails? selectedTower;
  SelectedHeroDetails? selectedHero;
  bool heroMoveMode = false;
  Set<String> builtTowerKinds = const {};
  String statusText = '아래 카드를 클릭해서 건물을 배치하세요.';
  List<String> activeFronts = const [];
  List<String> nextFronts = const [];
  double recoverySecondsRemaining = 0;
  bool recoveryActive = false;
  String battleState = 'prep';

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
    int actNumber = 1,
    String loopLabel = 'Wave',
  }) {
    this.stageNumber = stageNumber;
    this.totalStages = totalStages;
    this.actNumber = actNumber;
    this.stageTitle = stageTitle;
    this.totalWaves = totalWaves;
    this.loopLabel = loopLabel;
    this.coins = coins;
    this.baseHealth = baseHealth;
    maxBaseHealth = baseHealth;
    towersBuilt = 0;
    maxTowerLevel = 1;
    builtTowerKinds = const {};
    selectedTower = null;
    selectedHero = null;
    heroMoveMode = false;
    selectedBuildable = null;
    selectedHeroBuildable = null;
    activeFronts = const [];
    nextFronts = const [];
    recoverySecondsRemaining = 0;
    recoveryActive = false;
    battleState = 'prep';
    _speedMultiplier = 1.0;
    _remainingEnemies = 0;
    stageCleared = false;
    stageFailed = false;
    waveInProgress = false;
    currentWave = 0;
    statusText = '아래 카드를 클릭해서 건물을 배치하세요.';
    notifyListeners();
  }

  void setSelectedBuildable(TowerKind? towerKind) {
    selectedBuildable = towerKind;
    if (towerKind != null) {
      selectedHeroBuildable = null;
      selectedTower = null;
      selectedHero = null;
    }
    notifyListeners();
  }

  void setSelectedHeroBuildable(HeroKind? heroKind) {
    selectedHeroBuildable = heroKind;
    if (heroKind != null) {
      selectedBuildable = null;
      selectedTower = null;
      selectedHero = null;
    }
    notifyListeners();
  }

  void setSelectedTower(SelectedTowerDetails? details) {
    selectedTower = details;
    if (details != null) {
      selectedBuildable = null;
      selectedHeroBuildable = null;
      selectedHero = null;
    }
    notifyListeners();
  }

  void setSelectedHero(SelectedHeroDetails? details) {
    selectedHero = details;
    if (details != null) {
      selectedBuildable = null;
      selectedHeroBuildable = null;
      selectedTower = null;
    }
    notifyListeners();
  }

  void setHeroMoveMode(bool value) {
    heroMoveMode = value;
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
    int actNumber = 1,
    String loopLabel = 'Wave',
    List<String> activeFronts = const [],
    List<String> nextFronts = const [],
    double recoverySecondsRemaining = 0,
    bool recoveryActive = false,
    String battleState = 'prep',
    int remainingEnemies = 0,
  }) {
    this.actNumber = actNumber;
    this.currentWave = currentWave;
    this.loopLabel = loopLabel;
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
    this.activeFronts = List<String>.from(activeFronts);
    this.nextFronts = List<String>.from(nextFronts);
    this.recoverySecondsRemaining = recoverySecondsRemaining;
    this.recoveryActive = recoveryActive;
    this.battleState = battleState;
    _remainingEnemies = remainingEnemies;
    notifyListeners();
  }
}
