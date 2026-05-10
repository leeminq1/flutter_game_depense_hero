import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSessionController', () {
    test(
      'buildable selection can be cleared after the same card is tapped',
      () {
        final controller = GameSessionController();
        var notifications = 0;

        controller.addListener(() {
          notifications += 1;
        });

        controller.setSelectedBuildable(TowerKind.archer);
        expect(controller.selectedBuildable, TowerKind.archer);

        controller.setSelectedBuildable(null);
        expect(controller.selectedBuildable, isNull);
        expect(notifications, 2);
      },
    );

    test('barrier selection can be cleared after the same card is tapped', () {
      final controller = GameSessionController();
      var notifications = 0;

      controller.addListener(() {
        notifications += 1;
      });

      controller.setSelectedBarrierBuildable(BarrierKind.stoneWall);
      expect(controller.selectedBarrierBuildable, BarrierKind.stoneWall);

      controller.setSelectedBarrierBuildable(null);
      expect(controller.selectedBarrierBuildable, isNull);
      expect(notifications, 2);
    });

    test('updateRuntime only notifies when runtime values actually change', () {
      final controller = GameSessionController();
      var notifications = 0;

      controller.addListener(() {
        notifications += 1;
      });

      controller.hydrate(
        stageNumber: 1,
        totalStages: 30,
        stageTitle: 'Stage 1',
        totalWaves: 3,
        coins: 150,
        baseHealth: 24,
      );

      notifications = 0;

      controller.updateRuntime(
        currentWave: 1,
        coins: 120,
        baseHealth: 24,
        waveInProgress: true,
        stageCleared: false,
        stageFailed: false,
        isPaused: false,
        towersBuilt: 1,
        maxTowerLevel: 1,
        builtTowerKinds: const {'archer'},
        statusText: 'Cycle 1 진행 중',
        activeFronts: const ['북쪽'],
        nextFronts: const ['동쪽'],
        recoverySecondsRemaining: 0,
        recoveryActive: false,
        battleState: 'assault',
        remainingEnemies: 7,
      );

      expect(notifications, 1);

      controller.updateRuntime(
        currentWave: 1,
        coins: 120,
        baseHealth: 24,
        waveInProgress: true,
        stageCleared: false,
        stageFailed: false,
        isPaused: false,
        towersBuilt: 1,
        maxTowerLevel: 1,
        builtTowerKinds: const {'archer'},
        statusText: 'Cycle 1 진행 중',
        activeFronts: const ['북쪽'],
        nextFronts: const ['동쪽'],
        recoverySecondsRemaining: 0,
        recoveryActive: false,
        battleState: 'assault',
        remainingEnemies: 7,
      );

      expect(notifications, 1);

      controller.updateRuntime(
        currentWave: 1,
        coins: 120,
        baseHealth: 24,
        waveInProgress: true,
        stageCleared: false,
        stageFailed: false,
        isPaused: false,
        towersBuilt: 1,
        maxTowerLevel: 1,
        builtTowerKinds: const {'archer'},
        statusText: 'Cycle 1 진행 중',
        activeFronts: const ['북쪽'],
        nextFronts: const ['동쪽'],
        recoverySecondsRemaining: 0,
        recoveryActive: false,
        battleState: 'assault',
        remainingEnemies: 6,
      );

      expect(notifications, 2);
      expect(controller.remainingEnemies, 6);
    });

    test('selecting the same hero details twice does not notify again', () {
      final controller = GameSessionController();
      var notifications = 0;

      controller.addListener(() {
        notifications += 1;
      });

      final details = SelectedHeroDetails(
        kind: HeroKind.knight,
        label: '기사',
        level: 1,
        upgradeCost: 144,
        shortDescription: '근접 탱커',
        abilityLabel: '수호 오라',
        abilityDescription: '주변 타워 피해 감소',
        canUpgrade: true,
      );

      controller.setSelectedHero(details);
      expect(notifications, 1);

      controller.setSelectedHero(
        const SelectedHeroDetails(
          kind: HeroKind.knight,
          label: '기사',
          level: 1,
          upgradeCost: 144,
          shortDescription: '근접 탱커',
          abilityLabel: '수호 오라',
          abilityDescription: '주변 타워 피해 감소',
          canUpgrade: true,
        ),
      );

      expect(notifications, 1);
    });

    test('selecting the same tower details twice does not notify again', () {
      final controller = GameSessionController();
      var notifications = 0;

      controller.addListener(() {
        notifications += 1;
      });

      final details = SelectedTowerDetails(
        kind: TowerKind.coinMill,
        label: '금화 방앗간',
        level: 1,
        upgradeCost: 90,
        sellValue: 45,
        shortDescription: '경제 타워',
        abilityDescription: '주기적으로 골드를 생산합니다.',
        canUpgrade: true,
        canChooseBranch: false,
        branchChoices: const [],
        economyIncomePerTick: 4,
        economyInterval: 4,
        economyIncomePerSecond: 1,
        economyCycleBonus: 6,
        economyBreakEvenSeconds: 90,
      );

      controller.setSelectedTower(details);
      expect(notifications, 1);

      controller.setSelectedTower(
        const SelectedTowerDetails(
          kind: TowerKind.coinMill,
          label: '금화 방앗간',
          level: 1,
          upgradeCost: 90,
          sellValue: 45,
          shortDescription: '경제 타워',
          abilityDescription: '주기적으로 골드를 생산합니다.',
          canUpgrade: true,
          canChooseBranch: false,
          branchChoices: [],
          economyIncomePerTick: 4,
          economyInterval: 4,
          economyIncomePerSecond: 1,
          economyCycleBonus: 6,
          economyBreakEvenSeconds: 90,
        ),
      );

      expect(notifications, 1);
    });

    test('selecting the same barrier details twice does not notify again', () {
      final controller = GameSessionController();
      var notifications = 0;

      controller.addListener(() {
        notifications += 1;
      });

      const details = SelectedBarrierDetails(
        kind: BarrierKind.stoneWall,
        label: '돌 성벽',
        hitPoints: 160,
        maxHitPoints: 220,
        sellValue: 25,
        shortDescription: '적을 붙잡아 타워 공격 시간을 벌어줍니다.',
      );

      controller.setSelectedBarrier(details);
      expect(notifications, 1);

      controller.setSelectedBarrier(details);

      expect(notifications, 1);
    });
  });
}
