import 'dart:math' as math;
import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';

class SampleCampaign {
  static const int totalStages = 30;

  static StageDefinition stage(int number) {
    final safeStage = number.clamp(1, totalStages);
    final biome = _biomeForStage(safeStage);
    final environmentTheme = _environmentThemeForStage(safeStage);
    final pathTemplate =
        _pathTemplates[(safeStage - 1) % _pathTemplates.length];
    final buildZones =
        _buildZoneTemplates[(safeStage - 1) % _buildZoneTemplates.length];
    final waveCount = 5;
    final title = safeStage == 30
        ? '스테이지 30 - 성주의 왕좌'
        : '스테이지 $safeStage - ${biome.title}';

    return StageDefinition(
      number: safeStage,
      title: title,
      description: _stageDescription(safeStage, biome),
      startingCoins: _startingCoinsForStage(safeStage),
      baseHealth: _baseHealthForStage(safeStage),
      environmentTheme: environmentTheme,
      pathNodes: pathTemplate,
      buildSlots: const [], // Added missing required parameter
      buildZones: buildZones,
      decorations: _decorationsForStage(safeStage, environmentTheme),
      objectives: _objectivesForStage(safeStage),
      unlockRequirements: _unlockRequirementsForStage(safeStage),
      waves: List.generate(
        waveCount,
        (index) => _buildWave(
          stageNumber: safeStage,
          waveNumber: index + 1,
          waveCount: waveCount,
          biome: biome,
        ),
      ),
    );
  }

  static List<StageDefinition> allStages() {
    return List.generate(totalStages, (index) => stage(index + 1));
  }

  static WaveDefinition _buildWave({
    required int stageNumber,
    required int waveNumber,
    required int waveCount,
    required _BiomeProfile biome,
  }) {
    if (stageNumber <= 5) {
      return _buildEarlyGameWave(
        stageNumber: stageNumber,
        waveNumber: waveNumber,
      );
    }

    if (stageNumber <= 10) {
      return _buildMidGameWave(
        stageNumber: stageNumber,
        waveNumber: waveNumber,
      );
    }

    if (stageNumber <= 20) {
      return _buildUpperMidGameWave(
        stageNumber: stageNumber,
        waveNumber: waveNumber,
      );
    }

    if (stageNumber == 30 && waveNumber == waveCount) {
      return _buildFinalBossWave(
        stageNumber: stageNumber,
        waveNumber: waveNumber,
      );
    }

    if (stageNumber >= 21) {
      return _buildLateGameWave(
        stageNumber: stageNumber,
        waveNumber: waveNumber,
      );
    }

    throw StateError('Unhandled stage band for stage $stageNumber');
  }

  static WaveDefinition _buildFinalBossWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    return WaveDefinition(
      number: waveNumber,
      groupGap: 1.95,
      groups: [
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.graveGuard,
            stageNumber: stageNumber,
            intensity: 1.6,
          ),
          count: 2,
          spawnInterval: 1.7,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.warlock,
            stageNumber: stageNumber,
            intensity: 1.2,
          ),
          count: 1,
          spawnInterval: 2.6,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.corruptedKnight,
            stageNumber: stageNumber,
            intensity: 1.45,
          ),
          count: 2,
          spawnInterval: 1.55,
        ),
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.bastionOverlord,
            stageNumber: stageNumber,
            intensity: 1.0,
          ),
          count: 1,
          spawnInterval: 3.6,
        ),
      ],
    );
  }

  static WaveDefinition _buildMidGameWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    final groups = <SpawnGroupDefinition>[];
    final shield = enemyForKind(
      EnemyKind.shieldInfantry,
      stageNumber: stageNumber,
      intensity: 0.94 + (waveNumber * 0.08),
    );
    final raider = enemyForKind(
      EnemyKind.raider,
      stageNumber: stageNumber,
      intensity: 0.96 + (waveNumber * 0.08),
    );
    final scout = enemyForKind(
      EnemyKind.scout,
      stageNumber: stageNumber,
      intensity: 0.94 + (waveNumber * 0.07),
    );
    final cult = enemyForKind(
      EnemyKind.cultAdept,
      stageNumber: stageNumber,
      intensity: 0.90 + (waveNumber * 0.08),
    );

    groups.add(
      SpawnGroupDefinition(
        enemy: shield,
        count: switch (stageNumber) {
          6 => [2, 2, 3, 3, 4][waveNumber - 1],
          7 => [2, 3, 3, 4, 4][waveNumber - 1],
          8 => [3, 3, 4, 4, 5][waveNumber - 1],
          9 => [3, 4, 4, 5, 5][waveNumber - 1],
          _ => [3, 4, 5, 5, 6][waveNumber - 1],
        },
        spawnInterval: math.max(0.82, 1.1 - (stageNumber * 0.015)),
      ),
    );

    groups.add(
      SpawnGroupDefinition(
        enemy: waveNumber.isEven ? raider : scout,
        count: switch (stageNumber) {
          6 => [4, 4, 5, 5, 6][waveNumber - 1],
          7 => [4, 5, 5, 6, 6][waveNumber - 1],
          8 => [4, 5, 6, 6, 7][waveNumber - 1],
          9 => [5, 5, 6, 7, 7][waveNumber - 1],
          _ => [5, 6, 6, 7, 8][waveNumber - 1],
        },
        spawnInterval: math.max(0.76, 1.0 - (stageNumber * 0.012)),
      ),
    );

    if ((stageNumber == 7 && waveNumber >= 3) ||
        (stageNumber == 8 && waveNumber >= 4) ||
        stageNumber >= 9) {
      groups.add(
        SpawnGroupDefinition(
          enemy: cult,
          count: switch (stageNumber) {
            6 => 0,
            7 => waveNumber == 3 ? 1 : 2,
            8 => waveNumber == 4 ? 1 : 0,
            9 => waveNumber >= 3 ? (waveNumber == 4 ? 2 : 1) : 0,
            _ => waveNumber >= 3 ? 1 : 0,
          },
          spawnInterval: 2.0,
        ),
      );
    }

    if (stageNumber == 10 && waveNumber == 5) {
      groups.add(
        SpawnGroupDefinition(
          enemy: enemyForKind(
            EnemyKind.corruptedKnight,
            stageNumber: stageNumber,
            intensity: 1.02,
          ),
          count: 1,
          spawnInterval: 2.3,
        ),
      );
    }

    groups.removeWhere((group) => group.count <= 0);

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber >= 4 ? 1.45 : 1.18,
    );
  }

  static WaveDefinition _buildUpperMidGameWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    final groups = <SpawnGroupDefinition>[];
    final skeleton = enemyForKind(
      EnemyKind.skeleton,
      stageNumber: stageNumber,
      intensity: 0.98 + (waveNumber * 0.08),
    );
    final shield = enemyForKind(
      EnemyKind.shieldInfantry,
      stageNumber: stageNumber,
      intensity: 0.98 + (waveNumber * 0.07),
    );
    final cult = enemyForKind(
      EnemyKind.cultAdept,
      stageNumber: stageNumber,
      intensity: 0.96 + (waveNumber * 0.08),
    );
    final knight = enemyForKind(
      EnemyKind.corruptedKnight,
      stageNumber: stageNumber,
      intensity: 0.94 + (waveNumber * 0.08),
    );
    final graveGuard = enemyForKind(
      EnemyKind.graveGuard,
      stageNumber: stageNumber,
      intensity: 0.92 + (waveNumber * 0.08),
    );

    switch (stageNumber) {
      case 11:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [5, 6, 6, 7, 8][waveNumber - 1],
            spawnInterval: 0.92,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 2, 3, 3, 4][waveNumber - 1],
            spawnInterval: 1.06,
          ),
          if (waveNumber >= 3)
            SpawnGroupDefinition(
              enemy: cult,
              count: waveNumber >= 4 ? 2 : 1,
              spawnInterval: 2.1,
            ),
        ]);
        break;
      case 12:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [5, 6, 7, 7, 8][waveNumber - 1],
            spawnInterval: 0.9,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 3, 3, 4, 4][waveNumber - 1],
            spawnInterval: 1.04,
          ),
          if (waveNumber >= 2)
            SpawnGroupDefinition(
              enemy: cult,
              count: waveNumber >= 3 ? 2 : 1,
              spawnInterval: 2.0,
            ),
        ]);
        break;
      case 13:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 6, 7, 8, 8][waveNumber - 1],
            spawnInterval: 0.88,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 1, 2, 2, 2][waveNumber - 1],
            spawnInterval: 2.0,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 3, 3, 3, 4][waveNumber - 1],
            spawnInterval: 1.02,
          ),
          if (waveNumber >= 4)
            SpawnGroupDefinition(enemy: knight, count: 1, spawnInterval: 2.2),
        ]);
        break;
      case 14:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 7, 8, 9][waveNumber - 1],
            spawnInterval: 0.86,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [3, 3, 4, 4, 5][waveNumber - 1],
            spawnInterval: 1.0,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.95,
          ),
          if (waveNumber >= 3)
            SpawnGroupDefinition(enemy: knight, count: 1, spawnInterval: 2.25),
        ]);
        break;
      case 15:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 8, 8, 9][waveNumber - 1],
            spawnInterval: 0.84,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.92,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [3, 3, 4, 4, 5][waveNumber - 1],
            spawnInterval: 1.0,
          ),
          if (waveNumber >= 4)
            SpawnGroupDefinition(enemy: knight, count: 2, spawnInterval: 2.05),
        ]);
        break;
      case 16:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 7, 8, 8][waveNumber - 1],
            spawnInterval: 0.84,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.9,
          ),
          if (waveNumber >= 2)
            SpawnGroupDefinition(
              enemy: knight,
              count: waveNumber >= 3 ? 2 : 1,
              spawnInterval: 2.15,
            ),
        ]);
        break;
      case 17:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 8, 8, 9][waveNumber - 1],
            spawnInterval: 0.82,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.88,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 2.08,
          ),
        ]);
        break;
      case 18:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 8, 8, 9][waveNumber - 1],
            spawnInterval: 0.8,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.86,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 2, 3][waveNumber - 1],
            spawnInterval: 2.04,
          ),
          if (waveNumber >= 3)
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: waveNumber >= 4 ? 2 : 1,
              spawnInterval: 2.35,
            ),
        ]);
        break;
      case 19:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [7, 7, 8, 9, 10][waveNumber - 1],
            spawnInterval: 0.78,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3, 4][waveNumber - 1],
            spawnInterval: 1.82,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 2, 3][waveNumber - 1],
            spawnInterval: 2.0,
          ),
          if (waveNumber >= 2)
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: waveNumber >= 3 ? 2 : 1,
              spawnInterval: 2.28,
            ),
        ]);
        break;
      default:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [7, 8, 8, 9, 10][waveNumber - 1],
            spawnInterval: 0.76,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 3, 3, 4][waveNumber - 1],
            spawnInterval: 1.8,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.96,
          ),
          SpawnGroupDefinition(
            enemy: graveGuard,
            count: [1, 1, 2, 2, 2][waveNumber - 1],
            spawnInterval: 2.22,
          ),
        ]);
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber >= 4 ? 1.5 : 1.2,
    );
  }

  static WaveDefinition _buildLateGameWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    final groups = <SpawnGroupDefinition>[];
    final graveGuard = enemyForKind(
      EnemyKind.graveGuard,
      stageNumber: stageNumber,
      intensity: 1.02 + (waveNumber * 0.09),
    );
    final knight = enemyForKind(
      EnemyKind.corruptedKnight,
      stageNumber: stageNumber,
      intensity: 1.0 + (waveNumber * 0.09),
    );
    final warlock = enemyForKind(
      EnemyKind.warlock,
      stageNumber: stageNumber,
      intensity: 0.98 + (waveNumber * 0.08),
    );
    final skeleton = enemyForKind(
      EnemyKind.skeleton,
      stageNumber: stageNumber,
      intensity: 1.0 + (waveNumber * 0.08),
    );

    if (stageNumber <= 25) {
      switch (stageNumber) {
        case 21:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 2, 3, 3, 4][waveNumber - 1],
              spawnInterval: 1.9,
            ),
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [1, 1, 1, 2, 2][waveNumber - 1],
              spawnInterval: 2.2,
            ),
            if (waveNumber >= 3)
              SpawnGroupDefinition(
                enemy: warlock,
                count: waveNumber >= 4 ? 2 : 1,
                spawnInterval: 3.0,
              ),
          ]);
          break;
        case 22:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.84,
            ),
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [1, 1, 2, 2, 2][waveNumber - 1],
              spawnInterval: 2.16,
            ),
            if (waveNumber >= 2)
              SpawnGroupDefinition(
                enemy: warlock,
                count: waveNumber >= 4 ? 2 : 1,
                spawnInterval: 2.95,
              ),
          ]);
          break;
        case 23:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.8,
            ),
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [1, 2, 2, 2, 3][waveNumber - 1],
              spawnInterval: 2.1,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 1, 1, 2, 2][waveNumber - 1],
              spawnInterval: 2.9,
            ),
          ]);
          break;
        case 24:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 3, 4, 4, 5][waveNumber - 1],
              spawnInterval: 1.78,
            ),
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [1, 2, 2, 3, 3][waveNumber - 1],
              spawnInterval: 2.04,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 1, 2, 2, 2][waveNumber - 1],
              spawnInterval: 2.86,
            ),
          ]);
          break;
        default:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: knight,
              count: [3, 3, 4, 4, 5][waveNumber - 1],
              spawnInterval: 1.74,
            ),
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [1, 2, 2, 3, 3][waveNumber - 1],
              spawnInterval: 2.0,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 1, 2, 2, 3][waveNumber - 1],
              spawnInterval: 2.8,
            ),
          ]);
      }
    } else {
      switch (stageNumber) {
        case 26:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [2, 2, 3, 3, 3][waveNumber - 1],
              spawnInterval: 1.98,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 1, 2, 2, 2][waveNumber - 1],
              spawnInterval: 2.75,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.78,
            ),
          ]);
          break;
        case 27:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [2, 2, 3, 3, 4][waveNumber - 1],
              spawnInterval: 1.94,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 2, 2, 2, 3][waveNumber - 1],
              spawnInterval: 2.7,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.74,
            ),
          ]);
          break;
        case 28:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.9,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 2, 2, 3, 3][waveNumber - 1],
              spawnInterval: 2.66,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [3, 3, 4, 4, 5][waveNumber - 1],
              spawnInterval: 1.72,
            ),
            if (waveNumber >= 3)
              SpawnGroupDefinition(
                enemy: skeleton,
                count: waveNumber == 5 ? 5 : 4,
                spawnInterval: 1.05,
              ),
          ]);
          break;
        case 29:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.86,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 2, 2, 3, 3][waveNumber - 1],
              spawnInterval: 2.6,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [3, 3, 4, 5, 5][waveNumber - 1],
              spawnInterval: 1.68,
            ),
            SpawnGroupDefinition(
              enemy: skeleton,
              count: [3, 4, 4, 5, 5][waveNumber - 1],
              spawnInterval: 1.0,
            ),
          ]);
          break;
        default:
          groups.addAll([
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: [2, 3, 3, 4, 4][waveNumber - 1],
              spawnInterval: 1.84,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 2, 2, 3, 3][waveNumber - 1],
              spawnInterval: 2.55,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [3, 3, 4, 5, 5][waveNumber - 1],
              spawnInterval: 1.64,
            ),
            SpawnGroupDefinition(
              enemy: skeleton,
              count: [4, 4, 5, 5, 6][waveNumber - 1],
              spawnInterval: 0.98,
            ),
          ]);
      }
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber >= 4 ? 1.7 : 1.28,
    );
  }

  static int _startingCoinsForStage(int stageNumber) {
    if (stageNumber <= 5) {
      return switch (stageNumber) {
        1 => 240,
        2 => 235,
        3 => 230,
        4 => 225,
        _ => 220,
      };
    }
    if (stageNumber <= 10) {
      return switch (stageNumber) {
        6 => 250,
        7 => 248,
        8 => 246,
        9 => 244,
        _ => 242,
      };
    }
    if (stageNumber <= 15) {
      return switch (stageNumber) {
        11 => 255,
        12 => 252,
        13 => 250,
        14 => 248,
        _ => 246,
      };
    }
    if (stageNumber <= 20) {
      return switch (stageNumber) {
        16 => 244,
        17 => 242,
        18 => 240,
        19 => 238,
        _ => 236,
      };
    }
    if (stageNumber <= 25) {
      return switch (stageNumber) {
        21 => 232,
        22 => 230,
        23 => 228,
        24 => 226,
        _ => 224,
      };
    }
    return switch (stageNumber) {
      26 => 222,
      27 => 220,
      28 => 218,
      29 => 216,
      _ => 214,
    };
  }

  static int _baseHealthForStage(int stageNumber) {
    if (stageNumber <= 5) {
      return switch (stageNumber) {
        1 => 24,
        2 => 23,
        3 => 22,
        4 => 21,
        _ => 20,
      };
    }
    if (stageNumber <= 10) {
      return switch (stageNumber) {
        6 => 19,
        7 => 18,
        8 => 18,
        9 => 17,
        _ => 17,
      };
    }
    if (stageNumber <= 15) {
      return switch (stageNumber) {
        11 => 16,
        12 => 16,
        13 => 15,
        14 => 15,
        _ => 14,
      };
    }
    if (stageNumber <= 20) {
      return switch (stageNumber) {
        16 => 14,
        17 => 13,
        18 => 13,
        19 => 12,
        _ => 12,
      };
    }
    if (stageNumber <= 25) {
      return switch (stageNumber) {
        21 => 11,
        22 => 11,
        23 => 10,
        24 => 10,
        _ => 9,
      };
    }
    return switch (stageNumber) {
      26 => 9,
      27 => 9,
      28 => 8,
      29 => 8,
      _ => 10,
    };
  }

  static WaveDefinition _buildEarlyGameWave({
    required int stageNumber,
    required int waveNumber,
  }) {
    List<SpawnGroupDefinition> groups;
    switch (stageNumber) {
      case 1:
        groups = switch (waveNumber) {
          1 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 1,
                intensity: 0.92,
              ),
              count: 3,
              spawnInterval: 1.05,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 0.88,
              ),
              count: 2,
              spawnInterval: 1.2,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 1,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.98,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 0.95,
              ),
              count: 3,
              spawnInterval: 1.08,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 1,
                intensity: 1.08,
              ),
              count: 5,
              spawnInterval: 0.92,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 1.0,
              ),
              count: 3,
              spawnInterval: 1.0,
            ),
          ],
        };
        break;
      case 2:
        groups = switch (waveNumber) {
          1 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 2,
                intensity: 0.96,
              ),
              count: 4,
              spawnInterval: 0.98,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 2,
                intensity: 0.92,
              ),
              count: 3,
              spawnInterval: 1.08,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 2,
                intensity: 1.05,
              ),
              count: 5,
              spawnInterval: 0.9,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 2,
                intensity: 1.0,
              ),
              count: 3,
              spawnInterval: 0.98,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 2,
                intensity: 1.05,
              ),
              count: 5,
              spawnInterval: 0.94,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 2,
                intensity: 1.08,
              ),
              count: 4,
              spawnInterval: 0.92,
            ),
          ],
        };
        break;
      case 3:
        groups = switch (waveNumber) {
          1 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 3,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.94,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 3,
                intensity: 0.96,
              ),
              count: 3,
              spawnInterval: 1.0,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 3,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.95,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 3,
                intensity: 0.78,
              ),
              count: 1,
              spawnInterval: 1.4,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 3,
                intensity: 1.06,
              ),
              count: 4,
              spawnInterval: 0.9,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 3,
                intensity: 0.84,
              ),
              count: 2,
              spawnInterval: 1.35,
            ),
          ],
        };
        break;
      case 4:
        groups = switch (waveNumber) {
          1 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 4,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.92,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.82,
              ),
              count: 1,
              spawnInterval: 1.3,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 4,
                intensity: 1.02,
              ),
              count: 4,
              spawnInterval: 0.92,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.88,
              ),
              count: 2,
              spawnInterval: 1.28,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 4,
                intensity: 1.08,
              ),
              count: 4,
              spawnInterval: 0.88,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 4,
                intensity: 1.04,
              ),
              count: 3,
              spawnInterval: 0.92,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.92,
              ),
              count: 2,
              spawnInterval: 1.22,
            ),
          ],
        };
        break;
      default:
        groups = switch (waveNumber) {
          1 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 5,
                intensity: 1.06,
              ),
              count: 5,
              spawnInterval: 0.9,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 0.86,
              ),
              count: 1,
              spawnInterval: 1.26,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 5,
                intensity: 1.08,
              ),
              count: 5,
              spawnInterval: 0.9,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 0.92,
              ),
              count: 2,
              spawnInterval: 1.22,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 5,
                intensity: 1.12,
              ),
              count: 4,
              spawnInterval: 0.86,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 5,
                intensity: 1.08,
              ),
              count: 4,
              spawnInterval: 0.88,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 1.0,
              ),
              count: 2,
              spawnInterval: 1.15,
            ),
          ],
        };
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber >= 3 ? 1.4 : 1.1,
    );
  }

  static EnemyDefinition enemyForKind(
    EnemyKind kind, {
    required int stageNumber,
    required double intensity,
  }) {
    final hpMultiplier = 1 + ((stageNumber - 1) * 0.11);
    final speedStep = 1 + (((stageNumber - 1) ~/ 5) * 0.05);

    switch (kind) {
      case EnemyKind.raider:
        return EnemyDefinition(
          kind: kind,
          label: '습격병',
          specialDescription: '체력이 반 이하로 떨어지면 광분하여 더 빠르게 달립니다.',
          hitPoints: (44 * hpMultiplier * intensity).round(),
          speed: 48 * speedStep,
          rewardCoins: math.max(6, (6 + stageNumber * 0.8).round()),
          baseDamage: 1,
          color: const Color(0xFFB85C38),
        );
      case EnemyKind.scout:
        return EnemyDefinition(
          kind: kind,
          label: '정찰병',
          specialDescription: '처음 받는 물리 공격을 회피합니다.',
          hitPoints: (30 * hpMultiplier * math.max(0.9, intensity)).round(),
          speed: 68 * speedStep,
          rewardCoins: math.max(5, (5 + stageNumber * 0.75).round()),
          baseDamage: 1,
          color: const Color(0xFFD89C45),
        );
      case EnemyKind.shieldInfantry:
        return EnemyDefinition(
          kind: kind,
          label: '방패병',
          specialDescription: '물리 타워의 피해를 감소시킵니다.',
          hitPoints: (86 * hpMultiplier * intensity).round(),
          speed: 34 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFF7D8EA3),
        );
      case EnemyKind.cultAdept:
        return EnemyDefinition(
          kind: kind,
          label: '사이비 신봉',
          specialDescription: '주기적으로 근처 아군을 가속시킵니다.',
          hitPoints: (58 * hpMultiplier * intensity).round(),
          speed: 42 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber * 0.9).round()),
          baseDamage: 1,
          color: const Color(0xFF6E4EAA),
        );
      case EnemyKind.skeleton:
        return EnemyDefinition(
          kind: kind,
          label: '해골',
          specialDescription: '죽은 후 부분 체력으로 한 번 부활합니다.',
          hitPoints: (78 * hpMultiplier * intensity).round(),
          speed: 40 * speedStep,
          rewardCoins: math.max(11, (11 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFFBDB9AA),
        );
      case EnemyKind.graveGuard:
        return EnemyDefinition(
          kind: kind,
          label: '묘지기',
          specialDescription:
              '감속에 저항하고 제어 효과를 돌파합니다.',
          hitPoints: (172 * hpMultiplier * (intensity + 0.08)).round(),
          speed: 26 * speedStep,
          rewardCoins: math.max(20, (20 + stageNumber * 1.15).round()),
          baseDamage: 3,
          color: const Color(0xFF63705F),
        );
      case EnemyKind.corruptedKnight:
        return EnemyDefinition(
          kind: kind,
          label: '타락 기사',
          specialDescription:
              '부상 시 더 강하게 돌격하며 물리 공격에 저항합니다.',
          hitPoints: (145 * hpMultiplier * (intensity + 0.15)).round(),
          speed: 30 * speedStep,
          rewardCoins: math.max(18, (18 + stageNumber * 1.2).round()),
          baseDamage: 3,
          color: const Color(0xFF7A5151),
        );
      case EnemyKind.warlock:
        return EnemyDefinition(
          kind: kind,
          label: '흑마법사',
          specialDescription:
              '아군에게 보호막을 씨우고 해골 지원군을 소환합니다.',
          hitPoints: (98 * hpMultiplier * intensity).round(),
          speed: 33 * speedStep,
          rewardCoins: math.max(22, (22 + stageNumber * 1.25).round()),
          baseDamage: 2,
          color: const Color(0xFF5E3E88),
        );
      case EnemyKind.bastionOverlord:
        return EnemyDefinition(
          kind: kind,
          label: '성주',
          specialDescription:
              '변신, 보호막, 수비대 소환 능력을 가진 최종 보스입니다.',
          hitPoints: (1100 * math.max(1.0, intensity)).round(),
          speed: 24 * speedStep,
          rewardCoins: 180,
          baseDamage: 6,
          color: const Color(0xFF8C3F34),
        );
    }
  }

  static StageEnvironmentTheme _environmentThemeForStage(int stage) {
    if (stage <= 5) {
      return StageEnvironmentTheme.frontierRoad;
    }
    if (stage <= 10) {
      return StageEnvironmentTheme.banditCrossroads;
    }
    if (stage <= 15) {
      return StageEnvironmentTheme.graveFields;
    }
    if (stage <= 20) {
      return StageEnvironmentTheme.cursedChapel;
    }
    if (stage <= 25) {
      return StageEnvironmentTheme.bastionApproach;
    }
    return StageEnvironmentTheme.throneMarch;
  }

  static _BiomeProfile _biomeForStage(int stage) {
    if (stage <= 5) {
      return const _BiomeProfile(
        title: '숲 변경',
        primary: EnemyKind.raider,
        secondary: EnemyKind.scout,
        support: EnemyKind.shieldInfantry,
        elite: EnemyKind.shieldInfantry,
      );
    }
    if (stage <= 10) {
      return const _BiomeProfile(
        title: '폐허 길',
        primary: EnemyKind.shieldInfantry,
        secondary: EnemyKind.cultAdept,
        support: EnemyKind.raider,
        elite: EnemyKind.corruptedKnight,
      );
    }
    if (stage <= 20) {
      return const _BiomeProfile(
        title: '묘지 행군',
        primary: EnemyKind.skeleton,
        secondary: EnemyKind.shieldInfantry,
        support: EnemyKind.cultAdept,
        elite: EnemyKind.graveGuard,
      );
    }
    if (stage <= 25) {
      return const _BiomeProfile(
        title: '저주받은 성채',
        primary: EnemyKind.graveGuard,
        secondary: EnemyKind.corruptedKnight,
        support: EnemyKind.warlock,
        elite: EnemyKind.corruptedKnight,
      );
    }
    return const _BiomeProfile(
      title: '왕좌 행군',
      primary: EnemyKind.graveGuard,
      secondary: EnemyKind.corruptedKnight,
      support: EnemyKind.warlock,
      elite: EnemyKind.corruptedKnight,
    );
  }

  static String _stageDescription(int stage, _BiomeProfile biome) {
    switch (stage) {
      case 1:
        return '기본 공방 방법을 배우세요: 궁수를 배치하고, 웨이브를 시작하고, 첫 경로를 방어하세요.';
      case 2:
        return '정찰병이 더 빨라졌습니다. 깨끗한 배치로 안정적인 피해를 내세요.';
      case 3:
        return '방패병이 등장합니다. 갑옷을 돌파하려면 마법사를 추가하세요.';
      case 4:
        return '복합 압박이 시작됩니다. 병영이나 빙결로 적을 데미지 존 안에 묶어두세요.';
      case 5:
        return '첫 도전 스테이지입니다. 밀집된 최종 공세를 막고 경제를 안정시키세요.';
    }
    switch (stage) {
      case 6:
        return '중반 전환점입니다. 지원 적이 등장하기 전에 긴 전투를 버티세요.';
      case 7:
        return '첫 지원 압박입니다. 사이비 신봉을 조기에 제거하세요.';
      case 8:
        return '라인 안정성 테스트입니다. 방패병과 빠른 유닛이 섬이는 동안 향을 깨끗하게 지키세요.';
      case 9:
        return '세력 전환 스테이지입니다. 갑옷과 지원 적이 함께 밀려옵니다.';
      case 10:
        return '중반 도전 스테이지입니다. 조기에 안정시킨 후 혼합 압박 최종 웨이브를 버티세요.';
      case 11:
        return '묘지 전선이 시작됩니다. 부활하는 해골과 갑옷 호위대가 약한 정리를 응징합니다.';
      case 12:
        return '지원 중첩이 중요해집니다. 해골 압박이 두 배가 되기 전에 사이비 신봉을 처리하세요.';
      case 13:
        return '복합 언데드 위협이 제어 타이밍을 시험합니다. 하나의 라인을 진정한 킬 존으로 만드세요.';
      case 14:
        return '타락 기사가 공세에 합류합니다. 최종 회전에 대응할 코인을 남겨두세요.';
      case 15:
        return '묘지 도전 스테이지입니다. 긴 의식 행군을 버티고 패닉 지출 없이 엘리트 마무리를 연명하세요.';
      case 16:
        return '예배당 전선이 열립니다. 빠른 지원과 기사 압박이 의도적으로 겹칩니다.';
      case 17:
        return '늦은 대응을 응징하는 스테이지입니다. 3웨이브 전에 제어와 대갑 라인을 구축하세요.';
      case 18:
        return '묘지기가 등장합니다. 단순한 감속과 약한 공격으로는 전선을 유지할 수 없습니다.';
      case 19:
        return '복합 저항 압박이 더 깨끗한 타워 시너지와 낭비 없는 업그레이드를 요구합니다.';
      case 20:
        return '예배당 도전 스테이지입니다. 지속적인 엘리트 압박을 버티고 최종 웨이브까지 라인을 안정시키세요.';
      case 21:
        return '성벽이 반격합니다. 흑마법사가 더 강한 전선 뒤에서 등장하므로 후방 대응이 더 중요해집니다.';
      case 22:
        return '보호막 압박을 배우는 스테이지입니다. 흑마법사가 오래 살아남으면 갑옷 공세를 막기가 훨씬 어려워집니다.';
      case 23:
        return '성채 중첩이 시작됩니다. 묘지기와 흑마법사가 느린 소모전 대신 더 깨끗한 처치 타이밍을 요구합니다.';
      case 24:
        return '루트가 바이터 테스트로 압축됩니다. 마지막 2웨이브에 충분한 코인을 남겨두세요.';
      case 25:
        return '성채 도전 스테이지입니다. 지속적인 지원 압박을 버티고 최종 군사 공세에서 주력 타워를 지키세요.';
      case 26:
        return '왕좌 행군이 시작됩니다. 내성 탱크와 흑마법사가 약한 시작을 응징합니다.';
      case 27:
        return '늦은 대응은 실패합니다. 내성 압박이 라인을 고정하기 전에 대지원 라인을 구축하세요.';
      case 28:
        return '회복력을 시험하는 스테이지입니다. 소환수, 탱크, 바이터가 동시에 분산된 피해를 응징합니다.';
      case 29:
        return '최종 접근입니다. 이제는 매 웨이브 위기 재건 대신 진짜 후반 캠페인 능력이 필요합니다.';
    }
    if (stage <= 5) {
      return '초반 습격병과 정찰병으로부터 ${biome.title.toLowerCase()}을(를) 지키세요.';
    }
    if (stage <= 10) {
      return '갑옷 전선과 사이비 지원이 등장합니다. 일찍 건설하고 마법 피해를 확보하세요.';
    }
    if (stage <= 15) {
      return '언데드 압박이 더 강한 라인 정리력, 대갑 답변, 안정적인 경제 타이밍을 요구합니다.';
    }
    if (stage <= 20) {
      return '제어 저항 위협과 엘리트 바이터가 더 깨끗한 타워 시너지와 늦은 웨이브 코인 절약을 요구합니다.';
    }
    if (stage <= 25) {
      return '흑마법사와 바이터 전선이 함께 등장합니다. 더 깨끗한 대지원 타이밍과 강한 엘리트 대미지가 필요합니다.';
    }
    if (stage == 30) {
      return '최종 공성전입니다. 성주와 소환된 수비대를 이기고 캠페인을 완료하세요.';
    }
    return '왕좌 행군 스테이지는 소환수, 내성 탱크, 엘리트 바이터를 한 공세에 모두 넣어 회복 시간을 최소화합니다.';
  }

  static List<StageObjectiveDefinition> _objectivesForStage(int stage) {
    if (stage == 30) {
      return const [
        StageObjectiveDefinition(
          type: StageObjectiveType.clearStage,
          label: '성주를 처치하세요',
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.keepBaseHealth,
          label: '기지 체력 8 이상으로 완료',
          threshold: 8,
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: '발리스타 건설',
          towerKindId: 'ballista',
        ),
      ];
    }

    if (stage <= 5) {
      return switch (stage) {
        1 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 18 이상으로 완료',
            threshold: 18,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '궁수 건설',
            towerKindId: 'archer',
          ),
        ],
        2 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 17 이상으로 완료',
            threshold: 17,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: '타워 판매 금지',
            threshold: 0,
          ),
        ],
        3 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 16 이상으로 완료',
            threshold: 16,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        4 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 16 이상으로 완료',
            threshold: 16,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 15 이상으로 완료',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '금화 제조소 건설',
            towerKindId: 'coinMill',
          ),
        ],
      };
    }

    if (stage <= 10) {
      return switch (stage) {
        6 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 15 이상으로 완료',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        7 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 15 이상으로 완료',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '병영 건설',
            towerKindId: 'guardBarracks',
          ),
        ],
        8 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 14 이상으로 완료',
            threshold: 14,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        9 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 14 이상으로 완료',
            threshold: 14,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 13 이상으로 완료',
            threshold: 13,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '금화 제조소 건설',
            towerKindId: 'coinMill',
          ),
        ],
      };
    }

    if (stage <= 20) {
      return switch (stage) {
        11 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 11 이상으로 완료',
            threshold: 11,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        12 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 11 이상으로 완료',
            threshold: 11,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '병영 건설',
            towerKindId: 'guardBarracks',
          ),
        ],
        13 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 10 이상으로 완료',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        14 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 10 이상으로 완료',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: '타워 판매 금지',
            threshold: 0,
          ),
        ],
        15 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 10 이상으로 완료',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '금화 제조소 건설',
            towerKindId: 'coinMill',
          ),
        ],
        16 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 9 이상으로 완료',
            threshold: 9,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        17 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 9 이상으로 완료',
            threshold: 9,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildAtMost,
            label: '타워 최대 6개 건설',
            threshold: 6,
          ),
        ],
        18 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 8 이상으로 완료',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        19 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 8 이상으로 완료',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '병영 건설',
            towerKindId: 'guardBarracks',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 8 이상으로 완료',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
      };
    }

    if (stage <= 29) {
      return switch (stage) {
        21 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 7 이상으로 완료',
            threshold: 7,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '발리스타 건설',
            towerKindId: 'ballista',
          ),
        ],
        22 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 7 이상으로 완료',
            threshold: 7,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        23 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 6 이상으로 완료',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '병영 건설',
            towerKindId: 'guardBarracks',
          ),
        ],
        24 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 6 이상으로 완료',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: '타워 판매 금지',
            threshold: 0,
          ),
        ],
        25 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 6 이상으로 완료',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '발리스타 건설',
            towerKindId: 'ballista',
          ),
        ],
        26 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 5 이상으로 완료',
            threshold: 5,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '마법사 건설',
            towerKindId: 'mageObelisk',
          ),
        ],
        27 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 5 이상으로 완료',
            threshold: 5,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildAtMost,
            label: '타워 최대 6개 건설',
            threshold: 6,
          ),
        ],
        28 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 4 이상으로 완료',
            threshold: 4,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '빙결 건설',
            towerKindId: 'frostShrine',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: '스테이지 클리어',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: '기지 체력 4 이상으로 완료',
            threshold: 4,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: '발리스타 건설',
            towerKindId: 'ballista',
          ),
        ],
      };
    }

    final healthThreshold = switch (stage) {
      <= 5 => 16,
      <= 10 => 13,
      <= 20 => 10,
      _ => 8,
    };

    final objectives = <StageObjectiveDefinition>[
      const StageObjectiveDefinition(
        type: StageObjectiveType.clearStage,
        label: '스테이지 클리어',
      ),
      StageObjectiveDefinition(
        type: StageObjectiveType.keepBaseHealth,
        label: '기지 체력 $healthThreshold 이상으로 완료',
        threshold: healthThreshold,
      ),
    ];

    if (stage % 3 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: '마법사 건설',
          towerKindId: 'mageObelisk',
        ),
      );
    } else if (stage % 4 == 0) {
      objectives.add(
        StageObjectiveDefinition(
          type: StageObjectiveType.buildAtMost,
          label: '타워 최대 5개 건설',
          threshold: 5,
        ),
      );
    } else if (stage % 5 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: '금화 제조소 건설',
          towerKindId: 'coinMill',
        ),
      );
    } else {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.sellAtMost,
          label: '타워 판매 금지',
          threshold: 0,
        ),
      );
    }

    return objectives;
  }

  static List<StageUnlockRequirement> _unlockRequirementsForStage(int stage) {
    if (stage <= 1) {
      return const [];
    }

    final requirements = <StageUnlockRequirement>[
      StageUnlockRequirement(
        type: StageUnlockRequirementType.previousStageStars,
        label: '스테이지 ${stage - 1}에서 별 1개 이상 획득',
        stageNumber: stage - 1,
        threshold: 1,
      ),
    ];

    if (stage == 6) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: '총 별 10개 이상 획득',
          threshold: 10,
        ),
      );
    }
    if (stage == 11) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: '성벽 강화 1레벨 달성',
          upgradeId: 'stronghold',
          threshold: 1,
        ),
      );
    }
    if (stage == 16) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: '총 별 24개 이상 획득',
          threshold: 24,
        ),
      );
    }
    if (stage == 21) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: '궁술 숙련 2레벨 달성',
          upgradeId: 'bow_mastery',
          threshold: 2,
        ),
      );
    }
    if (stage == 26) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: '총 별 45개 이상 획득',
          threshold: 45,
        ),
      );
    }

    return requirements;
  }

  static List<StageDecorationDefinition> _decorationsForStage(
    int stage,
    StageEnvironmentTheme theme,
  ) {
    if (stage == 30 || stage % 5 == 0) {
      return _crestDecorationsForStage(stage, theme);
    }

    final variant = (stage - 1) % 3;

    switch (theme) {
      case StageEnvironmentTheme.frontierRoad:
        return [
          _dec(
            'assets/sprites/environment/props/road_signpost.png',
            0.09,
            variant == 0 ? 0.17 : 0.22,
            scale: 0.86,
          ),
          _dec(
            'assets/sprites/environment/props/wooden_fence_segment.png',
            0.11,
            0.83,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/well.png',
            0.84,
            0.18,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/wagon_wreck.png',
            0.88,
            0.82,
            scale: 1.08,
          ),
          if (variant == 2)
            _dec(
              'assets/sprites/environment/landmarks/watch_post.png',
              0.56,
              0.15,
              scale: 1.18,
            ),
        ];
      case StageEnvironmentTheme.banditCrossroads:
        return [
          _dec(
            'assets/sprites/environment/props/spike_barricade.png',
            0.10,
            0.18,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/wagon_wreck.png',
            0.14,
            0.84,
            scale: 1.04,
          ),
          _dec(
            'assets/sprites/environment/props/campfire.png',
            0.85,
            variant == 1 ? 0.21 : 0.17,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/supply_crate.png',
            0.88,
            0.79,
            scale: 0.84,
          ),
          if (variant == 2)
            _dec(
              'assets/sprites/environment/landmarks/checkpoint_tower.png',
              0.58,
              0.15,
              scale: 1.22,
            ),
        ];
      case StageEnvironmentTheme.graveFields:
        return [
          _dec(
            'assets/sprites/environment/props/grave_marker_tall.png',
            0.09,
            0.18,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/dead_tree_twisted.png',
            0.12,
            0.83,
            scale: 1.04,
          ),
          _dec(
            'assets/sprites/environment/props/broken_coffin.png',
            0.88,
            0.18,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/candle_cluster.png',
            0.90,
            0.82,
            scale: 0.94,
          ),
          if (variant == 1)
            _dec(
              'assets/sprites/environment/landmarks/cemetery_statue.png',
              0.57,
              0.16,
              scale: 1.18,
            ),
        ];
      case StageEnvironmentTheme.cursedChapel:
        return [
          if (variant == 0)
            _dec(
              'assets/sprites/environment/landmarks/ritual_arch.png',
              0.57,
              0.15,
              scale: 1.16,
            ),
          _dec(
            'assets/sprites/environment/props/chapel_rubble.png',
            0.10,
            0.18,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/ward_stone.png',
            0.13,
            0.84,
            scale: 1.02,
          ),
          _dec(
            'assets/sprites/environment/props/dead_tree_twisted.png',
            0.88,
            0.17,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/brazier_stand.png',
            0.89,
            0.83,
            scale: 0.92,
          ),
        ];
      case StageEnvironmentTheme.bastionApproach:
        return [
          _dec(
            'assets/sprites/environment/props/fort_wall_breach.png',
            0.11,
            0.18,
            scale: 1.02,
          ),
          _dec(
            'assets/sprites/environment/props/spear_rack.png',
            0.13,
            0.84,
            scale: 0.96,
          ),
          _dec(
            'assets/sprites/environment/props/siege_crate.png',
            0.87,
            0.18,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/brazier_stand.png',
            0.90,
            0.82,
            scale: 0.96,
          ),
          if (variant == 1)
            _dec(
              'assets/sprites/environment/landmarks/gate_ruin.png',
              0.57,
              0.15,
              scale: 1.22,
            ),
        ];
      case StageEnvironmentTheme.throneMarch:
        return [
          if (variant == 2)
            _dec(
              'assets/sprites/environment/landmarks/throne_road_monument.png',
              0.58,
              0.15,
              scale: 1.18,
            ),
          _dec(
            'assets/sprites/environment/props/chain_post_heavy.png',
            0.10,
            0.17,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/brazier_large.png',
            0.12,
            0.84,
            scale: 1.02,
          ),
          _dec(
            'assets/sprites/environment/props/obsidian_stake.png',
            0.87,
            0.18,
            scale: 0.96,
          ),
          _dec(
            'assets/sprites/environment/props/ember_pile.png',
            0.90,
            0.83,
            scale: 1.0,
          ),
        ];
    }
  }

  static List<StageDecorationDefinition> _crestDecorationsForStage(
    int stage,
    StageEnvironmentTheme theme,
  ) {
    switch (stage) {
      case 5:
        return [
          _dec(
            'assets/sprites/environment/landmarks/village_gate.png',
            0.55,
            0.14,
            scale: 1.38,
          ),
          _dec(
            'assets/sprites/environment/props/wagon_wreck.png',
            0.10,
            0.20,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/wooden_fence_segment.png',
            0.16,
            0.82,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/road_signpost.png',
            0.77,
            0.20,
            scale: 0.85,
          ),
          _dec(
            'assets/sprites/environment/props/well.png',
            0.86,
            0.79,
            scale: 0.94,
          ),
          _dec(
            'assets/sprites/environment/props/wooden_fence_segment.png',
            0.93,
            0.92,
            scale: 1.04,
            opacity: 0.95,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      case 10:
        return [
          _dec(
            'assets/sprites/environment/landmarks/bandit_stockade.png',
            0.56,
            0.15,
            scale: 1.42,
          ),
          _dec(
            'assets/sprites/environment/props/spike_barricade.png',
            0.10,
            0.20,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/campfire.png',
            0.17,
            0.80,
            scale: 0.95,
          ),
          _dec(
            'assets/sprites/environment/props/supply_crate.png',
            0.78,
            0.25,
            scale: 0.95,
          ),
          _dec(
            'assets/sprites/environment/props/road_signpost.png',
            0.89,
            0.72,
            scale: 0.85,
          ),
          _dec(
            'assets/sprites/environment/props/spike_barricade.png',
            0.93,
            0.90,
            scale: 1.02,
            opacity: 0.95,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      case 15:
        return [
          _dec(
            'assets/sprites/environment/landmarks/mausoleum_gate.png',
            0.55,
            0.14,
            scale: 1.42,
          ),
          _dec(
            'assets/sprites/environment/props/broken_coffin.png',
            0.14,
            0.23,
            scale: 0.96,
          ),
          _dec(
            'assets/sprites/environment/props/dead_tree_twisted.png',
            0.19,
            0.79,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/bone_pile.png',
            0.77,
            0.22,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/candle_cluster.png',
            0.88,
            0.76,
            scale: 0.9,
          ),
          _dec(
            'assets/sprites/environment/props/grave_marker_tall.png',
            0.93,
            0.90,
            scale: 1.0,
            opacity: 0.94,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      case 20:
        return [
          _dec(
            'assets/sprites/environment/landmarks/cursed_chapel_front.png',
            0.55,
            0.14,
            scale: 1.46,
          ),
          _dec(
            'assets/sprites/environment/landmarks/ritual_arch.png',
            0.15,
            0.77,
            scale: 1.08,
          ),
          _dec(
            'assets/sprites/environment/props/brazier_stand.png',
            0.20,
            0.24,
            scale: 0.92,
          ),
          _dec(
            'assets/sprites/environment/props/chapel_rubble.png',
            0.79,
            0.24,
            scale: 0.95,
          ),
          _dec(
            'assets/sprites/environment/props/ward_stone.png',
            0.88,
            0.79,
            scale: 0.94,
          ),
          _dec(
            'assets/sprites/environment/props/candle_cluster.png',
            0.92,
            0.90,
            scale: 0.98,
            opacity: 0.95,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      case 25:
        return [
          _dec(
            'assets/sprites/environment/landmarks/bastion_wall_chunk.png',
            0.55,
            0.14,
            scale: 1.5,
          ),
          _dec(
            'assets/sprites/environment/props/fort_wall_breach.png',
            0.11,
            0.22,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/siege_crate.png',
            0.18,
            0.79,
            scale: 0.96,
          ),
          _dec(
            'assets/sprites/environment/props/spear_rack.png',
            0.79,
            0.23,
            scale: 0.95,
          ),
          _dec(
            'assets/sprites/environment/props/brazier_stand.png',
            0.89,
            0.76,
            scale: 0.94,
          ),
          _dec(
            'assets/sprites/environment/props/chain_post.png',
            0.93,
            0.90,
            scale: 1.0,
            opacity: 0.95,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      case 30:
        return [
          _dec(
            'assets/sprites/environment/landmarks/infernal_gate.png',
            0.55,
            0.13,
            scale: 1.52,
          ),
          _dec(
            'assets/sprites/environment/landmarks/throne_road_monument.png',
            0.18,
            0.76,
            scale: 1.12,
          ),
          _dec(
            'assets/sprites/environment/props/chain_post_heavy.png',
            0.10,
            0.21,
            scale: 0.98,
          ),
          _dec(
            'assets/sprites/environment/props/obsidian_stake.png',
            0.80,
            0.21,
            scale: 0.95,
          ),
          _dec(
            'assets/sprites/environment/props/ember_pile.png',
            0.90,
            0.78,
            scale: 1.0,
          ),
          _dec(
            'assets/sprites/environment/props/chain_post_heavy.png',
            0.93,
            0.90,
            scale: 1.02,
            opacity: 0.96,
            layer: StageDecorationLayer.foreground,
          ),
        ];
      default:
        return _decorationsForStage(stage, theme);
    }
  }

  static StageDecorationDefinition _dec(
    String assetPath,
    double x,
    double y, {
    double scale = 1.0,
    double opacity = 1.0,
    StageDecorationLayer layer = StageDecorationLayer.background,
  }) {
    return StageDecorationDefinition(
      assetPath: assetPath,
      position: Offset(x, y),
      scale: scale,
      opacity: opacity,
      layer: layer,
    );
  }

  static const List<List<Offset>> _pathTemplates = [
    [
      Offset(0.03, 0.68),
      Offset(0.23, 0.68),
      Offset(0.23, 0.32),
      Offset(0.49, 0.32),
      Offset(0.49, 0.72),
      Offset(0.75, 0.72),
      Offset(0.75, 0.44),
      Offset(0.95, 0.44),
    ],
    [
      Offset(0.02, 0.48),
      Offset(0.18, 0.48),
      Offset(0.18, 0.18),
      Offset(0.45, 0.18),
      Offset(0.45, 0.82),
      Offset(0.72, 0.82),
      Offset(0.72, 0.28),
      Offset(0.97, 0.28),
    ],
    [
      Offset(0.05, 0.22),
      Offset(0.28, 0.22),
      Offset(0.28, 0.75),
      Offset(0.55, 0.75),
      Offset(0.55, 0.35),
      Offset(0.82, 0.35),
      Offset(0.82, 0.65),
      Offset(0.95, 0.65),
    ],
    [
      Offset(0.04, 0.58),
      Offset(0.20, 0.58),
      Offset(0.20, 0.86),
      Offset(0.52, 0.86),
      Offset(0.52, 0.18),
      Offset(0.78, 0.18),
      Offset(0.78, 0.55),
      Offset(0.96, 0.55),
    ],
    [
      Offset(0.03, 0.38),
      Offset(0.18, 0.38),
      Offset(0.18, 0.74),
      Offset(0.40, 0.74),
      Offset(0.40, 0.24),
      Offset(0.67, 0.24),
      Offset(0.67, 0.70),
      Offset(0.95, 0.70),
    ],
  ];

  static const List<List<StageBuildZoneDefinition>> _buildZoneTemplates = [
    [
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.08, 0.10, 0.26, 0.74)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.40, 0.10, 0.20, 0.22)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.40, 0.54, 0.20, 0.28)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.70, 0.18, 0.18, 0.58)),
    ],
    [
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.08, 0.08, 0.22, 0.68)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.36, 0.10, 0.18, 0.26)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.36, 0.58, 0.24, 0.26)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.68, 0.10, 0.22, 0.72)),
    ],
    [
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.10, 0.08, 0.20, 0.22)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.10, 0.44, 0.22, 0.38)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.40, 0.18, 0.20, 0.64)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.70, 0.08, 0.18, 0.72)),
    ],
    [
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.08, 0.10, 0.24, 0.70)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.38, 0.14, 0.18, 0.24)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.38, 0.56, 0.18, 0.24)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.66, 0.12, 0.22, 0.68)),
    ],
    [
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.10, 0.08, 0.22, 0.74)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.38, 0.08, 0.18, 0.22)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.38, 0.56, 0.22, 0.26)),
      StageBuildZoneDefinition(region: Rect.fromLTWH(0.68, 0.14, 0.20, 0.66)),
    ],
  ];
}

class _BiomeProfile {
  const _BiomeProfile({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.support,
    required this.elite,
  });

  final String title;
  final EnemyKind primary;
  final EnemyKind secondary;
  final EnemyKind support;
  final EnemyKind elite;
}
