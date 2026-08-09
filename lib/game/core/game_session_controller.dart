import 'package:depense_game/game/input/battlefield_camera_transform.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter/foundation.dart';

enum RunOfferFlowState { awaitingRoll, rolling, awaitingChoice, applied }

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

class SelectedBarrierDetails {
  const SelectedBarrierDetails({
    required this.kind,
    required this.label,
    required this.hitPoints,
    required this.maxHitPoints,
    required this.sellValue,
    required this.shortDescription,
  });

  final BarrierKind kind;
  final String label;
  final double hitPoints;
  final double maxHitPoints;
  final int sellValue;
  final String shortDescription;
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
  BarrierKind? selectedBarrierBuildable;
  HeroKind? selectedHeroBuildable;
  HeroKind? chosenHeroKind;
  bool heroSummoned = false;
  bool heroSummonAvailable = false;
  bool chosenHeroAlive = false;
  bool heroReviveAvailable = false;
  double chosenHeroHitPoints = 0;
  double chosenHeroMaxHitPoints = 0;
  SelectedTowerDetails? selectedTower;
  SelectedHeroDetails? selectedHero;
  SelectedBarrierDetails? selectedBarrier;
  bool heroMoveMode = false;
  Set<String> builtTowerKinds = const {};
  String statusText = '아래 카드를 탭해서 건물을 배치하세요.';
  BattlefieldCameraSnapshot cameraSnapshot = const BattlefieldCameraSnapshot();
  List<String> activeFronts = const [];
  List<String> nextFronts = const [];
  double recoverySecondsRemaining = 0;
  bool recoveryActive = false;
  String battleState = 'prep';
  int runOfferSeed = 0;
  RunOfferFlowState runOfferFlowState = RunOfferFlowState.applied;
  List<RunOfferDefinition> pendingRunOffers = const [];
  List<RunOfferDefinition> activeRunOffers = const [];

  int _remainingEnemies = 0;
  double _speedMultiplier = 1.0;
  int _selectionVersion = 0;

  int get remainingEnemies => _remainingEnemies;
  double get speedMultiplier => _speedMultiplier;
  String get speedLabel => '${_speedMultiplier.toStringAsFixed(1)}x';
  int get selectionVersion => _selectionVersion;

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
    selectedBarrier = null;
    heroMoveMode = false;
    selectedBuildable = null;
    selectedBarrierBuildable = null;
    selectedHeroBuildable = null;
    heroSummoned = false;
    heroSummonAvailable = false;
    chosenHeroAlive = false;
    heroReviveAvailable = false;
    chosenHeroHitPoints = 0;
    chosenHeroMaxHitPoints = 0;
    activeFronts = const [];
    nextFronts = const [];
    recoverySecondsRemaining = 0;
    recoveryActive = false;
    battleState = 'prep';
    runOfferSeed = 0;
    runOfferFlowState = RunOfferFlowState.applied;
    pendingRunOffers = const [];
    activeRunOffers = const [];
    _speedMultiplier = 1.0;
    _remainingEnemies = 0;
    stageCleared = false;
    stageFailed = false;
    waveInProgress = false;
    currentWave = 0;
    _selectionVersion = 0;
    cameraSnapshot = const BattlefieldCameraSnapshot();
    statusText = '아래 카드를 탭해서 건물을 배치하세요.';
    notifyListeners();
  }

  void setCameraSnapshot(
    BattlefieldCameraSnapshot value, {
    bool notify = true,
  }) {
    if (cameraSnapshot == value) {
      return;
    }
    cameraSnapshot = value;
    if (notify) {
      notifyListeners();
    }
  }

  RunModifierSet get runModifiers => RunModifierSet(activeRunOffers);

  bool get hasPendingRunOffer =>
      runOfferFlowState == RunOfferFlowState.awaitingChoice &&
      pendingRunOffers.isNotEmpty;

  bool get mustResolveRunOffer =>
      runOfferFlowState != RunOfferFlowState.applied;

  void setRunOfferSeed(int seed) {
    if (runOfferSeed == seed) {
      return;
    }
    runOfferSeed = seed;
    notifyListeners();
  }

  void prepareRunOfferRoll() {
    if (runOfferFlowState == RunOfferFlowState.awaitingRoll &&
        pendingRunOffers.isEmpty) {
      return;
    }
    runOfferFlowState = RunOfferFlowState.awaitingRoll;
    pendingRunOffers = const [];
    notifyListeners();
  }

  void setRunOfferRolling() {
    if (runOfferFlowState == RunOfferFlowState.rolling) {
      return;
    }
    runOfferFlowState = RunOfferFlowState.rolling;
    pendingRunOffers = const [];
    notifyListeners();
  }

  void setPendingRunOffers(List<RunOfferDefinition> offers) {
    final nextOffers = List<RunOfferDefinition>.unmodifiable(offers);
    if (_offerListsEqual(pendingRunOffers, nextOffers) &&
        runOfferFlowState == RunOfferFlowState.awaitingChoice) {
      return;
    }
    pendingRunOffers = nextOffers;
    runOfferFlowState = RunOfferFlowState.awaitingChoice;
    notifyListeners();
  }

  void acceptRunOffer(RunOfferDefinition offer) {
    final nextActive = List<RunOfferDefinition>.unmodifiable([
      ...activeRunOffers,
      offer,
    ]);
    activeRunOffers = nextActive;
    pendingRunOffers = const [];
    runOfferFlowState = RunOfferFlowState.applied;
    notifyListeners();
  }

  void bumpSelectionVersion() {
    _selectionVersion += 1;
    notifyListeners();
  }

  void setSelectedBuildable(TowerKind? towerKind) {
    final changed =
        selectedBuildable != towerKind ||
        (towerKind != null &&
            (selectedHeroBuildable != null ||
                selectedBarrierBuildable != null ||
                selectedTower != null ||
                selectedHero != null ||
                selectedBarrier != null));
    if (!changed) {
      return;
    }

    selectedBuildable = towerKind;
    if (towerKind != null) {
      selectedHeroBuildable = null;
      selectedBarrierBuildable = null;
      selectedTower = null;
      selectedHero = null;
      selectedBarrier = null;
    }
    notifyListeners();
  }

  void setSelectedBarrierBuildable(BarrierKind? barrierKind) {
    final changed =
        selectedBarrierBuildable != barrierKind ||
        (barrierKind != null &&
            (selectedBuildable != null ||
                selectedHeroBuildable != null ||
                selectedTower != null ||
                selectedHero != null ||
                selectedBarrier != null));
    if (!changed) {
      return;
    }

    selectedBarrierBuildable = barrierKind;
    if (barrierKind != null) {
      selectedBuildable = null;
      selectedHeroBuildable = null;
      selectedTower = null;
      selectedHero = null;
      selectedBarrier = null;
    }
    notifyListeners();
  }

  void setSelectedHeroBuildable(HeroKind? heroKind) {
    final changed =
        selectedHeroBuildable != heroKind ||
        (heroKind != null &&
            (selectedBuildable != null ||
                selectedBarrierBuildable != null ||
                selectedTower != null ||
                selectedHero != null ||
                selectedBarrier != null));
    if (!changed) {
      return;
    }

    selectedHeroBuildable = heroKind;
    if (heroKind != null) {
      selectedBuildable = null;
      selectedBarrierBuildable = null;
      selectedTower = null;
      selectedHero = null;
      selectedBarrier = null;
    }
    notifyListeners();
  }

  void setSelectedTower(SelectedTowerDetails? details) {
    final changed =
        !_towerDetailsEqual(selectedTower, details) ||
        (details != null &&
            (selectedBuildable != null ||
                selectedBarrierBuildable != null ||
                selectedHeroBuildable != null ||
                selectedHero != null ||
                selectedBarrier != null));
    if (!changed) {
      return;
    }

    selectedTower = details;
    if (details != null) {
      selectedBuildable = null;
      selectedBarrierBuildable = null;
      selectedHeroBuildable = null;
      selectedHero = null;
      selectedBarrier = null;
    }
    notifyListeners();
  }

  void setSelectedHero(SelectedHeroDetails? details) {
    final changed =
        !_heroDetailsEqual(selectedHero, details) ||
        (details != null &&
            (selectedBuildable != null ||
                selectedBarrierBuildable != null ||
                selectedHeroBuildable != null ||
                selectedTower != null ||
                selectedBarrier != null));
    if (!changed) {
      return;
    }

    selectedHero = details;
    if (details != null) {
      selectedBuildable = null;
      selectedBarrierBuildable = null;
      selectedHeroBuildable = null;
      selectedTower = null;
      selectedBarrier = null;
    }
    notifyListeners();
  }

  void setSelectedBarrier(SelectedBarrierDetails? details) {
    final changed =
        !_barrierDetailsEqual(selectedBarrier, details) ||
        (details != null &&
            (selectedBuildable != null ||
                selectedBarrierBuildable != null ||
                selectedHeroBuildable != null ||
                selectedTower != null ||
                selectedHero != null));
    if (!changed) {
      return;
    }

    selectedBarrier = details;
    if (details != null) {
      selectedBuildable = null;
      selectedBarrierBuildable = null;
      selectedHeroBuildable = null;
      selectedTower = null;
      selectedHero = null;
    }
    notifyListeners();
  }

  void setHeroMoveMode(bool value) {
    if (heroMoveMode == value) {
      return;
    }
    heroMoveMode = value;
    notifyListeners();
  }

  void setSpeedMultiplier(double speed) {
    if (_speedMultiplier == speed) {
      return;
    }
    _speedMultiplier = speed;
    notifyListeners();
  }

  void setChosenHero(HeroKind? heroKind) {
    if (chosenHeroKind == heroKind) {
      return;
    }
    chosenHeroKind = heroKind;
    notifyListeners();
  }

  void setHeroSummonState({required bool summoned, required bool available}) {
    if (heroSummoned == summoned && heroSummonAvailable == available) {
      return;
    }
    heroSummoned = summoned;
    heroSummonAvailable = available;
    notifyListeners();
  }

  void setChosenHeroStatus({
    required bool alive,
    required bool reviveAvailable,
    required double hitPoints,
    required double maxHitPoints,
  }) {
    if (chosenHeroAlive == alive &&
        heroReviveAvailable == reviveAvailable &&
        chosenHeroHitPoints == hitPoints &&
        chosenHeroMaxHitPoints == maxHitPoints) {
      return;
    }
    chosenHeroAlive = alive;
    heroReviveAvailable = reviveAvailable;
    chosenHeroHitPoints = hitPoints;
    chosenHeroMaxHitPoints = maxHitPoints;
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
    final nextBuiltKinds = Set<String>.from(builtTowerKinds);
    final nextActiveFronts = List<String>.from(activeFronts);
    final nextFrontsList = List<String>.from(nextFronts);

    final changed =
        this.actNumber != actNumber ||
        this.currentWave != currentWave ||
        this.loopLabel != loopLabel ||
        this.coins != coins ||
        this.baseHealth != baseHealth ||
        this.waveInProgress != waveInProgress ||
        this.stageCleared != stageCleared ||
        this.stageFailed != stageFailed ||
        this.isPaused != isPaused ||
        this.towersBuilt != towersBuilt ||
        this.maxTowerLevel != maxTowerLevel ||
        !setEquals(this.builtTowerKinds, nextBuiltKinds) ||
        this.statusText != statusText ||
        !listEquals(this.activeFronts, nextActiveFronts) ||
        !listEquals(this.nextFronts, nextFrontsList) ||
        this.recoverySecondsRemaining != recoverySecondsRemaining ||
        this.recoveryActive != recoveryActive ||
        this.battleState != battleState ||
        _remainingEnemies != remainingEnemies;

    if (!changed) {
      return;
    }

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
    this.builtTowerKinds = nextBuiltKinds;
    this.statusText = statusText;
    this.activeFronts = nextActiveFronts;
    this.nextFronts = nextFrontsList;
    this.recoverySecondsRemaining = recoverySecondsRemaining;
    this.recoveryActive = recoveryActive;
    this.battleState = battleState;
    _remainingEnemies = remainingEnemies;
    notifyListeners();
  }

  bool _towerDetailsEqual(SelectedTowerDetails? a, SelectedTowerDetails? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.kind == b.kind &&
        a.label == b.label &&
        a.level == b.level &&
        a.upgradeCost == b.upgradeCost &&
        a.sellValue == b.sellValue &&
        a.shortDescription == b.shortDescription &&
        a.abilityDescription == b.abilityDescription &&
        a.canUpgrade == b.canUpgrade &&
        a.canChooseBranch == b.canChooseBranch &&
        a.economyIncomePerTick == b.economyIncomePerTick &&
        a.economyInterval == b.economyInterval &&
        a.economyIncomePerSecond == b.economyIncomePerSecond &&
        a.economyCycleBonus == b.economyCycleBonus &&
        a.economyBreakEvenSeconds == b.economyBreakEvenSeconds &&
        a.branchId == b.branchId &&
        a.branchLabel == b.branchLabel &&
        _branchChoicesEqual(a.branchChoices, b.branchChoices);
  }

  bool _branchChoicesEqual(
    List<TowerBranchChoiceDetails> a,
    List<TowerBranchChoiceDetails> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].id != b[i].id ||
          a[i].label != b[i].label ||
          a[i].description != b[i].description) {
        return false;
      }
    }
    return true;
  }

  bool _heroDetailsEqual(SelectedHeroDetails? a, SelectedHeroDetails? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.kind == b.kind &&
        a.label == b.label &&
        a.level == b.level &&
        a.upgradeCost == b.upgradeCost &&
        a.shortDescription == b.shortDescription &&
        a.abilityLabel == b.abilityLabel &&
        a.abilityDescription == b.abilityDescription &&
        a.canUpgrade == b.canUpgrade;
  }

  bool _barrierDetailsEqual(
    SelectedBarrierDetails? a,
    SelectedBarrierDetails? b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.kind == b.kind &&
        a.label == b.label &&
        a.hitPoints == b.hitPoints &&
        a.maxHitPoints == b.maxHitPoints &&
        a.sellValue == b.sellValue &&
        a.shortDescription == b.shortDescription;
  }

  bool _offerListsEqual(
    List<RunOfferDefinition> a,
    List<RunOfferDefinition> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }
}
