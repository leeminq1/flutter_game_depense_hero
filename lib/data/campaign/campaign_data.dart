import 'dart:math' as math;
import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';

/// Canonical authored campaign data for the playable game.
class CampaignData {
  static const int totalStages = 30;
  static const int totalSieges = totalStages;
  static const int _tileColumns = 8;
  static const int _tileRows = 14;
  static const int _buildableTopRow = 1;
  static const int _buildableBottomRow = 12;

  static StageDefinition stage(int number) {
    final safeStage = number.clamp(1, totalStages);
    final authoredCitadelStage = _buildAuthoredCitadelStage(safeStage);
    if (authoredCitadelStage != null) {
      return authoredCitadelStage;
    }
    final biome = _biomeForStage(safeStage);
    final environmentTheme = _environmentThemeForStage(safeStage);
    final templateIndex = (safeStage - 1) % _pathTemplates.length;
    final pathTemplate = _pathTemplates[templateIndex];
    final slotTemplate = _slotTemplates[templateIndex];
    final pathSequence = _buildPathSequence(pathTemplate);
    _validatePathSequence(pathSequence);
    final tileGrid = _buildTileGrid(pathSequence, slotTemplate);
    final waveCount = safeStage >= 21 ? 5 : (safeStage >= 6 ? 4 : 3);
    final title = safeStage == 30
        ? 'Stage 30 - Bastion Throne'
        : 'Stage $safeStage - ${biome.title}';

    return StageDefinition(
      number: safeStage,
      title: title,
      description: _stageDescription(safeStage, biome),
      startingCoins: _startingCoinsForStage(safeStage),
      baseHealth: _baseHealthForStage(safeStage),
      environmentTheme: environmentTheme,
      pathNodes: _normalizedPathNodes(pathSequence),
      buildSlots: _normalizedBuildSlots(tileGrid),
      buildZones: const [
        StageBuildZoneDefinition(
          region: Rect.fromLTWH(0, 0, 1080, 1920), // Default large build zone
        ),
      ],
      pathClearance: 45.0,
      buildGridSpacing: 12.0,
      decorations: _decorationsForStage(safeStage, environmentTheme),
      objectives: _objectivesForStage(safeStage),
      unlockRequirements: _unlockRequirementsForStage(safeStage),
      tileGrid: tileGrid,
      pathSequence: pathSequence,
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

  static SiegeDefinition siege(int number) => stage(number);

  static List<SiegeDefinition> allSieges() => allStages();

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
    final wolfScout = enemyForKind(
      EnemyKind.wolfScout,
      stageNumber: stageNumber,
      intensity: 0.92 + (waveNumber * 0.08),
    );
    final bannerCaptain = enemyForKind(
      EnemyKind.bannerCaptain,
      stageNumber: stageNumber,
      intensity: 0.88 + (waveNumber * 0.08),
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
          6 => [2, 2, 3, 3][waveNumber - 1],
          7 => [2, 3, 3, 4][waveNumber - 1],
          8 => [3, 3, 4, 4][waveNumber - 1],
          9 => [3, 4, 4, 5][waveNumber - 1],
          _ => [3, 4, 5, 5][waveNumber - 1],
        },
        spawnInterval: math.max(0.82, 1.1 - (stageNumber * 0.015)),
      ),
    );

    groups.add(
      SpawnGroupDefinition(
        enemy: waveNumber.isEven ? raider : scout,
        count: switch (stageNumber) {
          6 => [4, 4, 5, 5][waveNumber - 1],
          7 => [4, 5, 5, 6][waveNumber - 1],
          8 => [4, 5, 6, 6][waveNumber - 1],
          9 => [5, 5, 6, 7][waveNumber - 1],
          _ => [5, 6, 6, 7][waveNumber - 1],
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

    final wolfScoutCount = switch (stageNumber) {
      6 => [0, 0, 0, 1][waveNumber - 1],
      7 => [0, 0, 1, 1][waveNumber - 1],
      8 => [0, 1, 1, 2][waveNumber - 1],
      9 => [0, 1, 2, 2][waveNumber - 1],
      _ => [1, 1, 2, 2][waveNumber - 1],
    };
    if (wolfScoutCount > 0) {
      groups.add(
        SpawnGroupDefinition(
          enemy: wolfScout,
          count: wolfScoutCount,
          spawnInterval: 0.78,
        ),
      );
    }

    if (stageNumber >= 8 && waveNumber >= 2) {
      groups.add(
        SpawnGroupDefinition(
          enemy: bannerCaptain,
          count: waveNumber == 4 ? 2 : 1,
          spawnInterval: 2.2,
        ),
      );
    }

    if (stageNumber == 10 && waveNumber == 4) {
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
      groupGap: waveNumber == 4 ? 1.45 : 1.18,
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
    final boneArcher = enemyForKind(
      EnemyKind.boneArcher,
      stageNumber: stageNumber,
      intensity: 0.96 + (waveNumber * 0.08),
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
    final plagueBearer = enemyForKind(
      EnemyKind.plagueBearer,
      stageNumber: stageNumber,
      intensity: 0.90 + (waveNumber * 0.08),
    );

    switch (stageNumber) {
      case 11:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [5, 6, 6, 7][waveNumber - 1],
            spawnInterval: 0.92,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.06,
          ),
          if (waveNumber >= 3)
            SpawnGroupDefinition(
              enemy: cult,
              count: waveNumber == 4 ? 2 : 1,
              spawnInterval: 2.1,
            ),
        ]);
        break;
      case 12:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [5, 6, 7, 7][waveNumber - 1],
            spawnInterval: 0.9,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 3, 3, 4][waveNumber - 1],
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
            count: [6, 6, 7, 8][waveNumber - 1],
            spawnInterval: 0.88,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 1, 2, 2][waveNumber - 1],
            spawnInterval: 2.0,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [2, 3, 3, 3][waveNumber - 1],
            spawnInterval: 1.02,
          ),
          if (waveNumber == 4)
            SpawnGroupDefinition(enemy: knight, count: 1, spawnInterval: 2.2),
        ]);
        break;
      case 14:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 7, 8][waveNumber - 1],
            spawnInterval: 0.86,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [3, 3, 4, 4][waveNumber - 1],
            spawnInterval: 1.0,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 2][waveNumber - 1],
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
            count: [6, 7, 8, 8][waveNumber - 1],
            spawnInterval: 0.84,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.92,
          ),
          SpawnGroupDefinition(
            enemy: shield,
            count: [3, 3, 4, 4][waveNumber - 1],
            spawnInterval: 1.0,
          ),
          if (waveNumber == 4)
            SpawnGroupDefinition(enemy: knight, count: 2, spawnInterval: 2.05),
        ]);
        break;
      case 16:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 7, 8][waveNumber - 1],
            spawnInterval: 0.84,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 2][waveNumber - 1],
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
            count: [6, 7, 8, 8][waveNumber - 1],
            spawnInterval: 0.82,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.88,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 1, 2, 2][waveNumber - 1],
            spawnInterval: 2.08,
          ),
        ]);
        break;
      case 18:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [6, 7, 8, 8][waveNumber - 1],
            spawnInterval: 0.8,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.86,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 2][waveNumber - 1],
            spawnInterval: 2.04,
          ),
          if (waveNumber >= 3)
            SpawnGroupDefinition(
              enemy: graveGuard,
              count: waveNumber == 4 ? 2 : 1,
              spawnInterval: 2.35,
            ),
        ]);
        break;
      case 19:
        groups.addAll([
          SpawnGroupDefinition(
            enemy: skeleton,
            count: [7, 7, 8, 9][waveNumber - 1],
            spawnInterval: 0.78,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.82,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 2][waveNumber - 1],
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
            count: [7, 8, 8, 9][waveNumber - 1],
            spawnInterval: 0.76,
          ),
          SpawnGroupDefinition(
            enemy: cult,
            count: [1, 2, 3, 3][waveNumber - 1],
            spawnInterval: 1.8,
          ),
          SpawnGroupDefinition(
            enemy: knight,
            count: [1, 2, 2, 3][waveNumber - 1],
            spawnInterval: 1.96,
          ),
          SpawnGroupDefinition(
            enemy: graveGuard,
            count: [1, 1, 2, 2][waveNumber - 1],
            spawnInterval: 2.22,
          ),
        ]);
    }

    if (stageNumber >= 12) {
      final boneArcherCount = switch (stageNumber) {
        12 => waveNumber >= 3 ? 1 : 0,
        13 => waveNumber >= 2 ? 1 : 0,
        14 => waveNumber >= 2 ? (waveNumber == 4 ? 2 : 1) : 0,
        15 => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
        16 => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
        17 => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
        18 => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
        19 => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
        _ => waveNumber >= 2 ? 2 : 1,
      };
      if (boneArcherCount > 0) {
        groups.add(
          SpawnGroupDefinition(
            enemy: boneArcher,
            count: boneArcherCount,
            spawnInterval: 1.18,
          ),
        );
      }
    }

    if (stageNumber >= 17) {
      final plagueBearerCount = switch (stageNumber) {
        17 => waveNumber >= 3 ? 1 : 0,
        18 => waveNumber >= 2 ? 1 : 0,
        19 => waveNumber >= 2 ? (waveNumber == 4 ? 2 : 1) : 0,
        _ => waveNumber >= 2 ? (waveNumber >= 3 ? 2 : 1) : 0,
      };
      if (plagueBearerCount > 0) {
        groups.add(
          SpawnGroupDefinition(
            enemy: plagueBearer,
            count: plagueBearerCount,
            spawnInterval: 2.42,
          ),
        );
      }
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber == 4 ? 1.5 : 1.2,
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
    final hexSniper = enemyForKind(
      EnemyKind.hexSniper,
      stageNumber: stageNumber,
      intensity: 0.96 + (waveNumber * 0.08),
    );
    final bastionPriest = enemyForKind(
      EnemyKind.bastionPriest,
      stageNumber: stageNumber,
      intensity: 0.94 + (waveNumber * 0.08),
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
              count: [2, 3, 3, 4][waveNumber - 1],
              spawnInterval: 1.84,
            ),
            SpawnGroupDefinition(
              enemy: warlock,
              count: [1, 2, 2, 3][waveNumber - 1],
              spawnInterval: 2.55,
            ),
            SpawnGroupDefinition(
              enemy: knight,
              count: [3, 3, 4, 5][waveNumber - 1],
              spawnInterval: 1.64,
            ),
            SpawnGroupDefinition(
              enemy: skeleton,
              count: [4, 4, 5, 5][waveNumber - 1],
              spawnInterval: 0.98,
            ),
          ]);
      }
    }

    if (stageNumber <= 25) {
      final hexSniperCount = switch (stageNumber) {
        21 => waveNumber >= 4 ? 1 : 0,
        22 => waveNumber >= 3 ? 1 : 0,
        23 => waveNumber >= 2 ? 1 : 0,
        24 => waveNumber >= 2 ? (waveNumber >= 4 ? 2 : 1) : 0,
        _ => waveNumber >= 2 ? (waveNumber >= 4 ? 2 : 1) : 0,
      };
      if (hexSniperCount > 0) {
        groups.add(
          SpawnGroupDefinition(
            enemy: hexSniper,
            count: hexSniperCount,
            spawnInterval: 2.9,
          ),
        );
      }
    }

    if (stageNumber >= 24 && stageNumber <= 29) {
      final bastionPriestCount = switch (stageNumber) {
        24 => waveNumber >= 4 ? 1 : 0,
        25 => waveNumber >= 3 ? 1 : 0,
        26 => waveNumber >= 3 ? 1 : 0,
        27 => waveNumber >= 2 ? 1 : 0,
        28 => waveNumber >= 2 ? (waveNumber >= 4 ? 2 : 1) : 0,
        _ => waveNumber >= 2 ? (waveNumber >= 4 ? 2 : 1) : 0,
      };
      if (bastionPriestCount > 0) {
        groups.add(
          SpawnGroupDefinition(
            enemy: bastionPriest,
            count: bastionPriestCount,
            spawnInterval: 3.05,
          ),
        );
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

    if (stageNumber >= 4) {
      final bannerCaptainCount = switch (stageNumber) {
        4 => [0, 1, 1][waveNumber - 1],
        _ => [1, 1, 2][waveNumber - 1],
      };
      if (bannerCaptainCount > 0) {
        groups.add(
          SpawnGroupDefinition(
            enemy: enemyForKind(
              EnemyKind.bannerCaptain,
              stageNumber: stageNumber,
              intensity: 0.86 + (waveNumber * 0.08),
            ),
            count: bannerCaptainCount,
            spawnInterval: 2.1,
          ),
        );
      }
    }

    return WaveDefinition(
      number: waveNumber,
      groups: groups,
      groupGap: waveNumber == 3 ? 1.4 : 1.1,
    );
  }

  static EnemyDefinition enemyForKind(
    EnemyKind kind, {
    required int stageNumber,
    required double intensity,
  }) {
    final hpMultiplier = 1 + ((stageNumber - 1) * 0.11);
    final actNumber = ((stageNumber - 1) ~/ 5) + 1;
    final moveSpeedMultiplier = 1 + ((actNumber - 1) * 0.04);
    final killRewardMultiplier = 1 + ((stageNumber - 1) * 0.05);

    switch (kind) {
      case EnemyKind.raider:
        return EnemyDefinition(
          kind: kind,
          label: 'Raider',
          specialDescription: 'Enrages below half health and runs faster.',
          hitPoints: (57 * hpMultiplier * intensity).round(),
          speed: 48 * moveSpeedMultiplier,
          rewardCoins: math.max(
            6,
            (6 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 1,
          color: const Color(0xFFB85C38),
        );
      case EnemyKind.scout:
        return EnemyDefinition(
          kind: kind,
          label: 'Scout',
          specialDescription: 'Dodges the first physical hit that lands on it.',
          hitPoints: (39 * hpMultiplier * math.max(0.9, intensity)).round(),
          speed: 68 * moveSpeedMultiplier,
          rewardCoins: math.max(
            5,
            (5 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 1,
          color: const Color(0xFFD89C45),
        );
      case EnemyKind.bannerCaptain:
        return EnemyDefinition(
          kind: kind,
          label: 'Banner Captain',
          specialDescription:
              'Periodically rallies nearby bandits with speed and damage buffs.',
          hitPoints: (78 * hpMultiplier * intensity).round(),
          speed: 44 * moveSpeedMultiplier,
          rewardCoins: math.max(
            9,
            (9 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 2,
          color: const Color(0xFF9E523C),
        );
      case EnemyKind.wolfScout:
        return EnemyDefinition(
          kind: kind,
          label: 'Wolf Scout',
          specialDescription:
              'Dodges its first physical hit and sprints harder when wounded.',
          hitPoints: (49 * hpMultiplier * math.max(0.95, intensity)).round(),
          speed: 74 * moveSpeedMultiplier,
          rewardCoins: math.max(
            7,
            (7 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 1,
          color: const Color(0xFF8B7A57),
        );
      case EnemyKind.shieldInfantry:
        return EnemyDefinition(
          kind: kind,
          label: 'Shield Infantry',
          specialDescription: 'Reduces damage from physical towers.',
          hitPoints: (112 * hpMultiplier * intensity).round(),
          speed: 34 * moveSpeedMultiplier,
          rewardCoins: math.max(
            10,
            (10 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 2,
          color: const Color(0xFF7D8EA3),
        );
      case EnemyKind.cultAdept:
        return EnemyDefinition(
          kind: kind,
          label: 'Cult Adept',
          specialDescription: 'Periodically hastes nearby allies.',
          hitPoints: (75 * hpMultiplier * intensity).round(),
          speed: 42 * moveSpeedMultiplier,
          rewardCoins: math.max(
            10,
            (10 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 2,
          color: const Color(0xFF6E4EAA),
        );
      case EnemyKind.skeleton:
        return EnemyDefinition(
          kind: kind,
          label: 'Skeleton',
          specialDescription: 'Revives once with partial health.',
          hitPoints: (101 * hpMultiplier * intensity).round(),
          speed: 40 * moveSpeedMultiplier,
          rewardCoins: math.max(
            11,
            (11 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 1,
          color: const Color(0xFFBDB9AA),
        );
      case EnemyKind.boneArcher:
        return EnemyDefinition(
          kind: kind,
          label: 'Bone Archer',
          specialDescription:
              'Leaves a fresh skeleton behind when it is destroyed.',
          hitPoints: (86 * hpMultiplier * intensity).round(),
          speed: 44 * moveSpeedMultiplier,
          rewardCoins: math.max(
            13,
            (13 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 1,
          color: const Color(0xFFC8C1AF),
        );
      case EnemyKind.graveGuard:
        return EnemyDefinition(
          kind: kind,
          label: 'Grave Guard',
          specialDescription:
              'Resists slows and pushes through control effects.',
          hitPoints: (224 * hpMultiplier * (intensity + 0.08)).round(),
          speed: 26 * moveSpeedMultiplier,
          rewardCoins: math.max(
            20,
            (20 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 3,
          color: const Color(0xFF63705F),
        );
      case EnemyKind.plagueBearer:
        return EnemyDefinition(
          kind: kind,
          label: 'Plague Bearer',
          specialDescription:
              'Heals nearby undead and shrouds them in brief damage reduction.',
          hitPoints: (135 * hpMultiplier * intensity).round(),
          speed: 34 * moveSpeedMultiplier,
          rewardCoins: math.max(
            21,
            (21 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 2,
          color: const Color(0xFF5E7152),
        );
      case EnemyKind.corruptedKnight:
        return EnemyDefinition(
          kind: kind,
          label: 'Corrupted Knight',
          specialDescription:
              'Charges harder when wounded and resists physical fire.',
          hitPoints: (189 * hpMultiplier * (intensity + 0.15)).round(),
          speed: 30 * moveSpeedMultiplier,
          rewardCoins: math.max(
            18,
            (18 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 4,
          color: const Color(0xFF7A5151),
        );
      case EnemyKind.hexSniper:
        return EnemyDefinition(
          kind: kind,
          label: 'Hex Sniper',
          specialDescription:
              'Refreshes a ward for itself and the most important nearby ally.',
          hitPoints: (120 * hpMultiplier * intensity).round(),
          speed: 38 * moveSpeedMultiplier,
          rewardCoins: math.max(
            25,
            (25 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 2,
          color: const Color(0xFF5C4B73),
        );
      case EnemyKind.warlock:
        return EnemyDefinition(
          kind: kind,
          label: 'Warlock',
          specialDescription:
              'Wards allies and summons skeleton reinforcements.',
          hitPoints: (127 * hpMultiplier * intensity).round(),
          speed: 33 * moveSpeedMultiplier,
          rewardCoins: math.max(
            22,
            (22 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 3,
          color: const Color(0xFF5E3E88),
        );
      case EnemyKind.bastionPriest:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Priest',
          specialDescription:
              'Heals elite allies and restores a ward to keep the line standing.',
          hitPoints: (179 * hpMultiplier * (intensity + 0.06)).round(),
          speed: 28 * moveSpeedMultiplier,
          rewardCoins: math.max(
            29,
            (29 * killRewardMultiplier * math.max(0.95, intensity)).round(),
          ),
          citadelDamage: 3,
          color: const Color(0xFF8A7A5E),
        );
      case EnemyKind.bastionOverlord:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Overlord',
          specialDescription:
              'Final boss that phases, wards itself, and summons defenders.',
          hitPoints: (1430 * hpMultiplier * math.max(1.0, intensity)).round(),
          speed: 24 * moveSpeedMultiplier,
          rewardCoins: math.max(
            180,
            (180 * killRewardMultiplier * math.max(1.0, intensity)).round(),
          ),
          citadelDamage: 10,
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
        title: 'Forest Edge',
        commonKinds: [
          EnemyKind.raider,
          EnemyKind.scout,
          EnemyKind.shieldInfantry,
        ],
        supportKinds: [EnemyKind.bannerCaptain],
        eliteKinds: [EnemyKind.shieldInfantry],
        bossKind: EnemyKind.shieldInfantry,
      );
    }
    if (stage <= 10) {
      return const _BiomeProfile(
        title: 'Ruin Road',
        commonKinds: [
          EnemyKind.raider,
          EnemyKind.scout,
          EnemyKind.wolfScout,
          EnemyKind.shieldInfantry,
        ],
        supportKinds: [EnemyKind.bannerCaptain, EnemyKind.cultAdept],
        eliteKinds: [EnemyKind.corruptedKnight],
        bossKind: EnemyKind.corruptedKnight,
      );
    }
    if (stage <= 20) {
      return const _BiomeProfile(
        title: 'Grave March',
        commonKinds: [
          EnemyKind.skeleton,
          EnemyKind.boneArcher,
          EnemyKind.shieldInfantry,
        ],
        supportKinds: [EnemyKind.cultAdept, EnemyKind.plagueBearer],
        eliteKinds: [EnemyKind.corruptedKnight, EnemyKind.graveGuard],
        bossKind: EnemyKind.graveGuard,
      );
    }
    if (stage <= 25) {
      return const _BiomeProfile(
        title: 'Cursed Bastion',
        commonKinds: [
          EnemyKind.skeleton,
          EnemyKind.graveGuard,
          EnemyKind.corruptedKnight,
        ],
        supportKinds: [
          EnemyKind.warlock,
          EnemyKind.hexSniper,
          EnemyKind.bastionPriest,
        ],
        eliteKinds: [EnemyKind.corruptedKnight, EnemyKind.graveGuard],
        bossKind: EnemyKind.corruptedKnight,
      );
    }
    return const _BiomeProfile(
      title: 'Throne March',
      commonKinds: [
        EnemyKind.skeleton,
        EnemyKind.graveGuard,
        EnemyKind.corruptedKnight,
      ],
      supportKinds: [
        EnemyKind.warlock,
        EnemyKind.hexSniper,
        EnemyKind.bastionPriest,
      ],
      eliteKinds: [EnemyKind.corruptedKnight, EnemyKind.graveGuard],
      bossKind: EnemyKind.bastionOverlord,
    );
  }

  static String _stageDescription(int stage, _BiomeProfile biome) {
    switch (stage) {
      case 1:
        return '기본 흐름을 익히세요. 궁수를 배치하고 웨이브를 시작해 첫 번째 적의 공격을 막아내십시오.';
      case 2:
        return '척후병이 더 빠르게 몰려옵니다. 안정적인 공격력과 깔끔한 배치를 조합하십시오.';
      case 3:
        return '방패 보병이 등장합니다. 마법사를 추가해 방어구를 뚫으십시오.';
      case 4:
        return '깃발 대장이 전열에 합류합니다. 병영이나 냉기 타워로 버프받은 적을 공격 범위 안에 묶어두십시오.';
      case 5:
        return '첫 번째 정점 스테이지입니다. 마지막 대규모 공격을 막아내고 경제를 안정적으로 유지하십시오.';
    }
    switch (stage) {
      case 6:
        return '늑대 척후병이 전열에 끼어듭니다. 빠른 측면 돌파를 허용하지 않고 긴 전투를 버텨내십시오.';
      case 7:
        return '첫 번째 지원 압박입니다. 전선이 무너지기 전에 컬트 신도를 일찍 발견하십시오.';
      case 8:
        return '진형 안정성 시험입니다. 방패병과 빠른 유닛이 섞일 때 대형을 흐트러지지 않게 유지하십시오.';
      case 9:
        return '진영 전환 스테이지입니다. 방어구와 지원 유닛이 같은 웨이브에 겹쳐 등장하기 시작합니다.';
      case 10:
        return '첫 번째 중반 정점입니다. 초반을 안정시킨 뒤 혼합 압박의 마지막 웨이브를 버텨내십시오.';
      case 11:
        return '묘지 전선이 시작됩니다. 되살아나는 해골과 방어구를 갖춘 호위대는 약한 처치 능력을 가차없이 응징합니다.';
      case 12:
        return '뼈 궁수가 모든 언데드 전투를 길게 늘립니다. 해골 사체가 전선을 채우기 전에 지원 속도를 끊어내십시오.';
      case 13:
        return '혼합 언데드 물결이 제어 타이밍을 시험합니다. 한 방향만큼은 진짜 처치 구역으로 만들어두십시오.';
      case 14:
        return '타락한 기사가 전열에 합류하기 시작합니다. 마지막 전환에 대응할 코인을 충분히 남겨두십시오.';
      case 15:
        return '묘지 정점 스테이지입니다. 긴 의식 행진을 버텨내고 당황하지 않고 코인을 아끼며 엘리트 마무리를 막아내십시오.';
      case 16:
        return '예배당 전선이 열립니다. 더 빠른 지원과 기사 압박이 이제 의도적으로 겹쳐 몰려옵니다.';
      case 17:
        return '역병 보유자가 등장합니다. 언데드 생존 엔진이 작동하기 전에 제어 및 방어구 대응 라인을 구축하십시오.';
      case 18:
        return '묘지 수호자가 등장합니다. 순수한 둔화와 약한 견제만으로는 더 이상 전선을 홀로 지탱할 수 없습니다.';
      case 19:
        return '저항력 높은 혼합 압박이 더 깔끔한 타워 시너지와 낭비 없는 업그레이드를 요구합니다.';
      case 20:
        return '예배당 정점 스테이지입니다. 지속적인 엘리트 압박을 견디고 마지막 웨이브까지 전선을 안정적으로 유지하십시오.';
      case 21:
        return '마력 저격수가 요새 전선에 수호 마법을 겹겹이 쌓기 시작합니다. 엘리트가 장악하기 전에 후방 대응이 적중해야 합니다.';
      case 22:
        return '이 전선은 마법 압박을 가르칩니다. 마법사들이 너무 오래 살아남으면 방어구 전진이 훨씬 비싼 대가를 치르게 됩니다.';
      case 23:
        return '요새 중첩이 여기서 시작됩니다. 묘지 수호자와 마법사들이 이제 느린 소모전 대신 더 정확한 처치 타이밍을 강요합니다.';
      case 24:
        return '요새 사제가 경로에 등장합니다. 마지막 두 웨이브를 위해 코인을 충분히 남겨두지 않으면 치유된 전선이 손쓸 수 없이 커집니다.';
      case 25:
        return '요새 정점 스테이지입니다. 지속적인 지원 압박을 버텨내고 핵심 타워를 잃지 않으며 마지막 군사 돌격을 막아내십시오.';
      case 26:
        return '왕좌 행군이 시작됩니다. 저항력 높은 탱커와 마법사들이 이제 충분히 일찍 도착해 약한 시작을 응징합니다.';
      case 27:
        return '늦은 대응은 여기서 실패합니다. 전선이 저항력 높은 압박으로 가득 차기 전에 반지원 라인을 구축하십시오.';
      case 28:
        return '이 스테이지는 회복력을 시험합니다. 소환물, 탱커, 브루저가 분산된 피해를 응징할 만큼 오래 겹쳐 등장합니다.';
      case 29:
        return '최후의 접근입니다. 이제 게임은 매 웨이브마다 긴급 재건이 아닌 진정한 후반 전략적 규율을 요구합니다.';
    }
    if (stage <= 5) {
      return '${biome.title}에 몰려드는 초반 적의 압박과 첫 번째 집결 지원을 막아내십시오.';
    }
    if (stage <= 10) {
      return '방어구를 갖춘 전선, 빠른 측면 돌파, 지원 지휘관이 여기서 겹치기 시작합니다. 일찍 구축하고 마법 피해를 위한 여지를 남겨두십시오.';
    }
    if (stage <= 15) {
      return '언데드 압박은 이제 더 강한 처치 능력, 방어구 대응, 안정적인 경제 타이밍을 요구합니다.';
    }
    if (stage <= 20) {
      return '저항력 높은 위협, 엘리트 브루저, 역병 지속력이 더 깔끔한 타워 시너지와 후반 웨이브 코인 관리를 요구합니다.';
    }
    if (stage <= 25) {
      return '마법 중심 지원과 브루저 전선이 함께 도착합니다. 더 깔끔한 반지원 타이밍과 강력한 엘리트 피해가 필요합니다.';
    }
    if (stage == 30) {
      return '최후의 공성전입니다. 요새 군주와 소환된 수호자들을 물리쳐 전역을 완수하십시오.';
    }
    return '왕좌 행군 스테이지는 소환사, 저항력 높은 탱커, 엘리트 브루저를 회복 여지 없이 같은 파도에 몰아붙입니다.';
  }

  static List<StageObjectiveDefinition> _objectivesForStage(int stage) {
    if (stage == 30) {
      return const [
        StageObjectiveDefinition(
          type: StageObjectiveType.clearStage,
          label: 'Defeat the Bastion Overlord',
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.keepBaseHealth,
          label: 'Finish with at least 8 base health',
          threshold: 8,
        ),
        StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Ballista',
          towerKindId: 'ballista',
        ),
      ];
    }

    if (stage <= 5) {
      return switch (stage) {
        1 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 18 base health',
            threshold: 18,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build an Archer',
            towerKindId: 'archer',
          ),
        ],
        2 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 17 base health',
            threshold: 17,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: 'Do not sell any towers',
            threshold: 0,
          ),
        ],
        3 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 16 base health',
            threshold: 16,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        4 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 16 base health',
            threshold: 16,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 15 base health',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Coin Mill',
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
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 15 base health',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        7 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 15 base health',
            threshold: 15,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Guard Barracks',
            towerKindId: 'guardBarracks',
          ),
        ],
        8 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 14 base health',
            threshold: 14,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        9 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 14 base health',
            threshold: 14,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 13 base health',
            threshold: 13,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Coin Mill',
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
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 11 base health',
            threshold: 11,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        12 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 11 base health',
            threshold: 11,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Guard Barracks',
            towerKindId: 'guardBarracks',
          ),
        ],
        13 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 10 base health',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        14 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 10 base health',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: 'Do not sell any towers',
            threshold: 0,
          ),
        ],
        15 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 10 base health',
            threshold: 10,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Coin Mill',
            towerKindId: 'coinMill',
          ),
        ],
        16 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 9 base health',
            threshold: 9,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        17 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 9 base health',
            threshold: 9,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildAtMost,
            label: 'Build at most 6 towers',
            threshold: 6,
          ),
        ],
        18 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 8 base health',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        19 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 8 base health',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Guard Barracks',
            towerKindId: 'guardBarracks',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 8 base health',
            threshold: 8,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
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
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 7 base health',
            threshold: 7,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Ballista',
            towerKindId: 'ballista',
          ),
        ],
        22 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 7 base health',
            threshold: 7,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        23 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 6 base health',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Guard Barracks',
            towerKindId: 'guardBarracks',
          ),
        ],
        24 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 6 base health',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.sellAtMost,
            label: 'Do not sell any towers',
            threshold: 0,
          ),
        ],
        25 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 6 base health',
            threshold: 6,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Ballista',
            towerKindId: 'ballista',
          ),
        ],
        26 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 5 base health',
            threshold: 5,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Mage tower',
            towerKindId: 'mageObelisk',
          ),
        ],
        27 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 5 base health',
            threshold: 5,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildAtMost,
            label: 'Build at most 6 towers',
            threshold: 6,
          ),
        ],
        28 => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 4 base health',
            threshold: 4,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Frost tower',
            towerKindId: 'frostShrine',
          ),
        ],
        _ => const [
          StageObjectiveDefinition(
            type: StageObjectiveType.clearStage,
            label: 'Clear the stage',
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.keepBaseHealth,
            label: 'Finish with at least 4 base health',
            threshold: 4,
          ),
          StageObjectiveDefinition(
            type: StageObjectiveType.buildSpecificTower,
            label: 'Build a Ballista',
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
        label: 'Clear the stage',
      ),
      StageObjectiveDefinition(
        type: StageObjectiveType.keepBaseHealth,
        label: 'Finish with at least $healthThreshold base health',
        threshold: healthThreshold,
      ),
    ];

    if (stage % 3 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Mage tower',
          towerKindId: 'mageObelisk',
        ),
      );
    } else if (stage % 4 == 0) {
      objectives.add(
        StageObjectiveDefinition(
          type: StageObjectiveType.buildAtMost,
          label: 'Build at most 5 towers',
          threshold: 5,
        ),
      );
    } else if (stage % 5 == 0) {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.buildSpecificTower,
          label: 'Build a Coin Mill',
          towerKindId: 'coinMill',
        ),
      );
    } else {
      objectives.add(
        const StageObjectiveDefinition(
          type: StageObjectiveType.sellAtMost,
          label: 'Do not sell any towers',
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
        label: 'Earn at least 1 star on Stage ${stage - 1}',
        stageNumber: stage - 1,
        threshold: 1,
      ),
    ];

    if (stage == 6) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 10 total stars',
          threshold: 10,
        ),
      );
    }
    if (stage == 11) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: 'Upgrade Stronghold Masonry to level 1',
          upgradeId: 'stronghold',
          threshold: 1,
        ),
      );
    }
    if (stage == 16) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 24 total stars',
          threshold: 24,
        ),
      );
    }
    if (stage == 21) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.metaUpgradeLevel,
          label: 'Upgrade Bow Mastery to level 2',
          upgradeId: 'bow_mastery',
          threshold: 2,
        ),
      );
    }
    if (stage == 26) {
      requirements.add(
        const StageUnlockRequirement(
          type: StageUnlockRequirementType.totalStars,
          label: 'Collect at least 45 total stars',
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

  static const List<List<List<int>>> _pathTemplates = [
    [
      [7, 9],
      [5, 9],
      [5, 4],
      [2, 4],
      [2, 8],
      [0, 8],
    ],
    [
      [7, 4],
      [6, 4],
      [6, 10],
      [3, 10],
      [3, 3],
      [0, 3],
    ],
    [
      [7, 10],
      [4, 10],
      [4, 6],
      [1, 6],
      [1, 2],
      [0, 2],
    ],
    [
      [7, 3],
      [5, 3],
      [5, 8],
      [2, 8],
      [2, 5],
      [0, 5],
    ],
    [
      [7, 7],
      [6, 7],
      [6, 2],
      [4, 2],
      [4, 9],
      [1, 9],
      [1, 4],
      [0, 4],
    ],
  ];

  static const List<List<List<int>>> _slotTemplates = [
    [
      [6, 2],
      [4, 2],
      [3, 7],
      [4, 11],
      [1, 10],
      [0, 2],
    ],
    [
      [7, 2],
      [5, 6],
      [5, 11],
      [2, 9],
      [1, 1],
      [0, 11],
    ],
    [
      [6, 11],
      [5, 8],
      [3, 7],
      [2, 1],
      [0, 9],
      [6, 4],
    ],
    [
      [7, 10],
      [6, 5],
      [4, 10],
      [3, 4],
      [1, 7],
      [0, 1],
    ],
    [
      [7, 10],
      [5, 5],
      [3, 1],
      [3, 11],
      [2, 7],
      [0, 10],
    ],
  ];

  static List<List<int>> _buildPathSequence(List<List<int>> template) {
    final anchors = template;
    final sequence = <List<int>>[];
    for (var i = 0; i < anchors.length; i += 1) {
      final current = anchors[i];
      if (sequence.isEmpty) {
        sequence.add([current[0], current[1]]);
      }
      if (i == anchors.length - 1) {
        break;
      }

      final next = anchors[i + 1];
      final stepCol = (next[0] - current[0]).sign;
      final stepRow = (next[1] - current[1]).sign;
      if (stepCol != 0 && stepRow != 0) {
        throw StateError('Path template contains a diagonal segment.');
      }

      var col = current[0];
      var row = current[1];
      while (col != next[0] || row != next[1]) {
        col += stepCol;
        row += stepRow;
        sequence.add([col, row]);
      }
    }
    return sequence;
  }

  static List<List<TileType>> _buildTileGrid(
    List<List<int>> pathSequence,
    List<List<int>> slotTemplate,
  ) {
    final grid = List.generate(
      _tileRows,
      (_) => List.generate(_tileColumns, (_) => TileType.blocked),
    );
    final pathCells = {
      for (final cell in pathSequence) _cellKey(cell[0], cell[1]),
    };
    final slotCells = {
      for (final slot in slotTemplate) _cellKey(slot[0], slot[1]),
    };

    for (var row = 0; row < _tileRows; row += 1) {
      for (var col = 0; col < _tileColumns; col += 1) {
        final key = _cellKey(col, row);
        if (pathCells.contains(key)) {
          grid[row][col] = TileType.path;
          continue;
        }
        if (_isBuildableCell(col, row, pathCells, slotCells)) {
          grid[row][col] = TileType.buildable;
        }
      }
    }
    return grid;
  }

  static bool _isBuildableCell(
    int col,
    int row,
    Set<String> pathCells,
    Set<String> slotCells,
  ) {
    if (row < _buildableTopRow || row > _buildableBottomRow) {
      return false;
    }
    final key = _cellKey(col, row);
    if (slotCells.contains(key)) {
      return true;
    }
    const neighbors = <(int, int)>[(0, -1), (1, 0), (0, 1), (-1, 0)];
    for (final neighbor in neighbors) {
      final neighborCol = col + neighbor.$1;
      final neighborRow = row + neighbor.$2;
      if (neighborCol < 0 ||
          neighborCol >= _tileColumns ||
          neighborRow < 0 ||
          neighborRow >= _tileRows) {
        continue;
      }
      if (pathCells.contains(_cellKey(neighborCol, neighborRow))) {
        return true;
      }
    }
    return false;
  }

  static List<Offset> _normalizedPathNodes(
    List<List<int>> pathSequence, {
    int? columns,
    int? rows,
  }) {
    final resolvedColumns =
        columns ??
        pathSequence
                .map((cell) => cell[0])
                .fold<int>(0, (maxCol, col) => math.max(maxCol, col)) +
            1;
    final resolvedRows =
        rows ??
        pathSequence
                .map((cell) => cell[1])
                .fold<int>(0, (maxRow, row) => math.max(maxRow, row)) +
            1;
    return [
      for (final cell in pathSequence)
        Offset(
          resolvedColumns <= 1 ? 0 : cell[0] / (resolvedColumns - 1),
          resolvedRows <= 1 ? 0 : cell[1] / (resolvedRows - 1),
        ),
    ];
  }

  static void _validatePathSequence(List<List<int>> pathSequence) {
    if (pathSequence.isEmpty) {
      throw StateError('Path sequence cannot be empty.');
    }
    if (pathSequence.first[0] != _tileColumns - 1) {
      throw StateError('Path must start at the right edge.');
    }
    if (pathSequence.last[0] != 0) {
      throw StateError('Path must end at the left edge.');
    }

    final indexByCell = <String, int>{};
    for (var i = 0; i < pathSequence.length; i += 1) {
      final cell = pathSequence[i];
      final key = _cellKey(cell[0], cell[1]);
      if (indexByCell.containsKey(key)) {
        throw StateError('Path cannot revisit cell $key.');
      }
      indexByCell[key] = i;

      if (cell[0] < 0 ||
          cell[0] >= _tileColumns ||
          cell[1] < 0 ||
          cell[1] >= _tileRows) {
        throw StateError('Path cell $key is out of bounds.');
      }
      if (i == 0) {
        continue;
      }

      final previous = pathSequence[i - 1];
      final dx = cell[0] - previous[0];
      final dy = cell[1] - previous[1];
      if ((dx.abs() + dy.abs()) != 1) {
        throw StateError('Path must move one orthogonal cell at a time.');
      }
      if (dx > 0) {
        throw StateError('Path cannot move back toward the right edge.');
      }
    }

    for (final entry in indexByCell.entries) {
      final parts = entry.key.split(':');
      final col = int.parse(parts[0]);
      final row = int.parse(parts[1]);
      const neighbors = <List<int>>[
        [0, -1],
        [1, 0],
        [0, 1],
        [-1, 0],
      ];
      for (final neighbor in neighbors) {
        final neighborCol = col + neighbor[0];
        final neighborRow = row + neighbor[1];
        final neighborKey = _cellKey(neighborCol, neighborRow);
        final neighborIndex = indexByCell[neighborKey];
        if (neighborIndex == null) {
          continue;
        }
        if ((neighborIndex - entry.value).abs() != 1) {
          throw StateError(
            'Path cannot touch non-consecutive side neighbor $neighborKey.',
          );
        }
      }
    }

    for (var row = 0; row < _tileRows - 1; row += 1) {
      for (var col = 0; col < _tileColumns - 1; col += 1) {
        final keys = [
          _cellKey(col, row),
          _cellKey(col + 1, row),
          _cellKey(col, row + 1),
          _cellKey(col + 1, row + 1),
        ];
        final filled = keys.where(indexByCell.containsKey).length;
        if (filled == 4) {
          throw StateError('Path cannot form a 2x2 block at $col:$row.');
        }
      }
    }
  }

  static List<Offset> _normalizedBuildSlots(List<List<TileType>> tileGrid) {
    final rowCount = tileGrid.length;
    final columnCount = tileGrid.isEmpty ? 0 : tileGrid.first.length;
    final slots = <Offset>[];
    for (var row = 0; row < tileGrid.length; row += 1) {
      for (var col = 0; col < tileGrid[row].length; col += 1) {
        if (tileGrid[row][col] != TileType.buildable) {
          continue;
        }
        slots.add(
          Offset(
            columnCount <= 1 ? 0 : col / (columnCount - 1),
            rowCount <= 1 ? 0 : row / (rowCount - 1),
          ),
        );
      }
    }
    return slots;
  }

  static StageDefinition? _buildAuthoredCitadelStage(int stageNumber) {
    if (stageNumber < 1 || stageNumber > 10) {
      return null;
    }

    final layout = _authoredCitadelLayouts[stageNumber - 1];
    final citadelCell = layout.citadelCell;
    final pathsByDirection = layout.pathsByDirection;
    for (final entry in pathsByDirection.entries) {
      _validateSiegeRoute(
        route: entry.value,
        direction: entry.key,
        columns: 14,
        rows: 14,
        citadelCell: citadelCell,
      );
    }

    final primaryRoute = pathsByDirection[layout.primaryFront]!;
    final legacyPathSequence = _legacyPathSequenceForSiege(
      primaryRoute,
      citadelCell: citadelCell,
    );
    final obstacles = _authoredCitadelObstaclesForStage(stageNumber);
    final tileGrid = _buildCitadelTileGrid(
      columns: 14,
      rows: 14,
      citadelCell: citadelCell,
      obstacleCells: _obstacleCellsFromDefinitions(obstacles),
    );
    final assaultCycles = _buildAuthoredCitadelAssaultCycles(stageNumber);

    return StageDefinition(
      number: stageNumber,
      actNumber: 1,
      title: _authoredCitadelTitle(stageNumber),
      description: _authoredCitadelDescription(stageNumber),
      startingCoins: 380,
      baseHealth: 40,
      citadelHp: 40,
      citadelCell: citadelCell,
      environmentTheme: StageEnvironmentTheme.frontierRoad,
      pathNodes: _normalizedPathNodes(
        legacyPathSequence,
        columns: 14,
        rows: 14,
      ),
      buildSlots: _normalizedBuildSlots(tileGrid),
      buildZones: const [
        StageBuildZoneDefinition(region: Rect.fromLTWH(0, 0, 1080, 1920)),
      ],
      pathClearance: 45.0,
      buildGridSpacing: 12.0,
      decorations: const [],
      objectives: _authoredCitadelObjectives(stageNumber),
      unlockRequirements: _unlockRequirementsForStage(stageNumber),
      tileGrid: tileGrid,
      pathSequence: legacyPathSequence,
      pathsByDirection: pathsByDirection,
      obstacles: obstacles,
      supplyNodeCells: const [],
      assaultCycles: assaultCycles,
      waves: [
        for (final cycle in assaultCycles)
          WaveDefinition(
            number: cycle.number,
            groupGap: cycle.number == assaultCycles.length ? 1.35 : 1.1,
            groups: [
              for (final group in cycle.groups)
                SpawnGroupDefinition(
                  enemy: group.enemy,
                  count: group.count,
                  spawnInterval: group.spawnInterval,
                  direction: group.front,
                ),
            ],
          ),
      ],
    );
  }

  static List<StageObjectiveDefinition> _authoredCitadelObjectives(
    int stageNumber,
  ) {
    final keepThreshold = switch (stageNumber) {
      1 => 34,
      2 => 32,
      3 => 30,
      4 => 28,
      _ => 26,
    };

    return [
      const StageObjectiveDefinition(
        type: StageObjectiveType.clearStage,
        label: 'Clear the Stage',
      ),
      StageObjectiveDefinition(
        type: StageObjectiveType.keepBaseHealth,
        label: 'Keep the Citadel at $keepThreshold HP or higher',
        threshold: keepThreshold,
      ),
      StageObjectiveDefinition(
        type: StageObjectiveType.buildSpecificTower,
        label: 'Build at least one Archer Tower',
        towerKindId: 'archer',
      ),
    ];
  }

  static List<AssaultCycleDefinition> _buildAuthoredCitadelAssaultCycles(
    int stageNumber,
  ) {
    FrontSpawnGroupDefinition spawn(
      SpawnDirection front,
      EnemyKind kind,
      int count, {
      required double interval,
      double intensity = 1.0,
    }) {
      return FrontSpawnGroupDefinition(
        front: front,
        enemy: enemyForKind(
          kind,
          stageNumber: stageNumber,
          intensity: intensity,
        ),
        count: count,
        spawnInterval: interval,
      );
    }

    switch (stageNumber) {
      case 1:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 40,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 2, interval: 1.0),
              spawn(SpawnDirection.west, EnemyKind.raider, 2, interval: 1.0),
              spawn(SpawnDirection.east, EnemyKind.scout, 1, interval: 0.92),
              spawn(SpawnDirection.south, EnemyKind.scout, 1, interval: 0.92),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 45,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                3,
                interval: 0.95,
                intensity: 1.05,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.raider,
                3,
                interval: 0.95,
                intensity: 1.05,
              ),
              spawn(SpawnDirection.east, EnemyKind.scout, 2, interval: 0.9),
              spawn(SpawnDirection.south, EnemyKind.raider, 2, interval: 0.94),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 50,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                3,
                interval: 0.92,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.raider,
                3,
                interval: 0.92,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.16,
                intensity: 1.04,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.scout,
                2,
                interval: 0.88,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.25,
              ),
            ],
          ),
        ];
      case 2:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 40,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.scout, 3, interval: 0.78),
              spawn(SpawnDirection.north, EnemyKind.raider, 2, interval: 0.98),
              spawn(SpawnDirection.south, EnemyKind.raider, 2, interval: 1.0),
              spawn(SpawnDirection.west, EnemyKind.raider, 2, interval: 0.96),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 45,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.scout,
                4,
                interval: 0.74,
                intensity: 1.04,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 3, interval: 0.94),
              spawn(SpawnDirection.west, EnemyKind.raider, 3, interval: 0.94),
              spawn(SpawnDirection.south, EnemyKind.scout, 2, interval: 0.88),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 50,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.scout,
                4,
                interval: 0.72,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                4,
                interval: 0.9,
                intensity: 1.06,
              ),
              spawn(SpawnDirection.west, EnemyKind.raider, 3, interval: 0.9),
              spawn(SpawnDirection.south, EnemyKind.scout, 3, interval: 0.84),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.18,
              ),
            ],
          ),
        ];
      case 3:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 45,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.18,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 3, interval: 0.92),
              spawn(SpawnDirection.west, EnemyKind.scout, 2, interval: 0.8),
              spawn(SpawnDirection.south, EnemyKind.raider, 2, interval: 0.94),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.west,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.16,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.88),
              spawn(SpawnDirection.west, EnemyKind.scout, 3, interval: 0.78),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.9),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.west,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.12,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.86),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.76),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.88),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.west,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 60,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                5,
                interval: 0.84,
                intensity: 1.08,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.78),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.08,
                intensity: 1.06,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
            ],
          ),
        ];
      case 4:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 45,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 3, interval: 0.86),
              spawn(SpawnDirection.east, EnemyKind.raider, 3, interval: 0.86),
              spawn(SpawnDirection.south, EnemyKind.scout, 2, interval: 0.8),
              spawn(SpawnDirection.west, EnemyKind.scout, 2, interval: 0.8),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.west,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.88),
              spawn(SpawnDirection.west, EnemyKind.scout, 3, interval: 0.8),
              spawn(SpawnDirection.east, EnemyKind.raider, 4, interval: 0.88),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.9),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.86),
              spawn(SpawnDirection.west, EnemyKind.scout, 3, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.14,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.9),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 60,
            isFinalBreach: true,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.84),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.78),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.1,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.86),
            ],
          ),
        ];
      case 5:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.scout, 4, interval: 0.74),
              spawn(SpawnDirection.north, EnemyKind.raider, 3, interval: 0.86),
              spawn(SpawnDirection.west, EnemyKind.raider, 3, interval: 0.86),
              spawn(SpawnDirection.south, EnemyKind.scout, 2, interval: 0.8),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.scout, 5, interval: 0.72),
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.84),
              spawn(SpawnDirection.west, EnemyKind.raider, 4, interval: 0.84),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 60,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.08,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.82),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.76),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.82),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 65,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.02,
                intensity: 1.08,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.8),
              spawn(SpawnDirection.west, EnemyKind.scout, 5, interval: 0.74),
              spawn(SpawnDirection.south, EnemyKind.raider, 5, interval: 0.8),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.15,
              ),
            ],
          ),
        ];
      case 6:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.east,
              SpawnDirection.south,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.scout, 4, interval: 0.72),
              spawn(SpawnDirection.north, EnemyKind.raider, 3, interval: 0.84),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.88),
              spawn(SpawnDirection.west, EnemyKind.raider, 3, interval: 0.88),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.east,
              SpawnDirection.south,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                2,
                interval: 0.76,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.08,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
              spawn(SpawnDirection.west, EnemyKind.scout, 3, interval: 0.78),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.east,
              SpawnDirection.south,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 60,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.04,
              ),
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.82),
              spawn(SpawnDirection.south, EnemyKind.raider, 5, interval: 0.82),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.76),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.east,
              SpawnDirection.south,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 65,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.0,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.wolfScout,
                2,
                interval: 0.74,
                intensity: 1.04,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.raider,
                5,
                interval: 0.8,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.2,
              ),
            ],
          ),
        ];
      default:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.88),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.12,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.9),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 4, interval: 0.86),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.78),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.08,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.86),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 60,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.84),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.78),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.06,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.east,
              SpawnDirection.south,
            ],
            recoveryGoldBonus: 65,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                5,
                interval: 0.82,
                intensity: 1.08,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 5, interval: 0.76),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.02,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.15,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
            ],
          ),
        ];
    }
  }

  static String _authoredCitadelTitle(int stageNumber) {
    return switch (stageNumber) {
      1 => 'Stage 1 - 사방 방어 입문',
      2 => 'Stage 2 - 방향별 압박 차이',
      3 => 'Stage 3 - 첫 중장 체크',
      4 => 'Stage 4 - 성 주변 재정비',
      5 => 'Stage 5 - 초반 종합 시험',
      6 => 'Stage 6 - 우상단 첫 변형',
      7 => 'Stage 7 - 우측 성문 압박',
      8 => 'Stage 8 - 북동 압박 강화',
      9 => 'Stage 9 - 좌측 장거리 우회',
      10 => 'Stage 10 - 우상단 미니 보스형',
      _ => 'Stage $stageNumber',
    };
  }

  static String _authoredCitadelDescription(int stageNumber) {
    return switch (stageNumber) {
      1 => '첫 Stage부터 사방에서 적이 들어옵니다. 장애물 우회를 읽고 중앙 성을 지키세요.',
      2 => '사방 압박은 유지하되 동쪽 길이가 짧아집니다. 먼저 막을 방향을 판단하세요.',
      3 => '방패 보병이 본격적으로 등장합니다. 물리 피해만으로 버티기 어렵습니다.',
      4 => '성 주변 공간을 넓힌 재정비 Stage입니다. 바깥 성벽을 이용해 킬존을 만드세요.',
      5 => '초반 구간 종합 시험입니다. 빠른 적, 중장, 사방 분산을 모두 처리해야 합니다.',
      6 => '성이 우상단으로 이동합니다. 하단 넓은 공간을 활용하고 북동 압박을 막으세요.',
      7 => '성이 조금 더 오른쪽에 자리합니다. 동쪽 짧은 압박과 남쪽 우회를 동시에 봅니다.',
      8 => '성이 북동쪽으로 올라갑니다. 북쪽과 동쪽 접근이 빨라져 선제 배치가 중요합니다.',
      9 => '성이 오른쪽으로 더 밀립니다. 좌측 긴 우회와 동쪽 성 앞 압박을 나눠 처리하세요.',
      10 => '우상단 미니 보스형 Stage입니다. 세 방향 동시 압박과 짧은 성 앞 전투를 견디세요.',
      _ => 'Stage $stageNumber',
    };
  }

  static List<List<int>> _legacyPathSequenceForSiege(
    List<List<int>> route, {
    required List<int> citadelCell,
  }) {
    if (route.isEmpty) {
      return const [];
    }

    final sequence = [
      for (final cell in route) [cell[0], cell[1]],
    ];
    final tail = route.last;
    var col = tail[0];
    var row = tail[1];
    final citadelCol = citadelCell[0];
    final citadelRow = citadelCell[1];
    while (col != citadelCol || row != citadelRow) {
      if (col < citadelCol) {
        col += 1;
      } else if (col > citadelCol) {
        col -= 1;
      } else if (row < citadelRow) {
        row += 1;
      } else if (row > citadelRow) {
        row -= 1;
      }
      sequence.add([col, row]);
    }
    return sequence;
  }

  static List<List<TileType>> _buildCitadelTileGrid({
    required int columns,
    required int rows,
    required List<int> citadelCell,
    required List<List<int>> obstacleCells,
  }) {
    final grid = List.generate(
      rows,
      (_) => List.generate(columns, (_) => TileType.buildable),
    );

    final citadelCol = citadelCell[0];
    final citadelRow = citadelCell[1];
    if (citadelRow >= 0 &&
        citadelRow < rows &&
        citadelCol >= 0 &&
        citadelCol < columns) {
      grid[citadelRow][citadelCol] = TileType.citadel;
    }

    for (final cell in obstacleCells) {
      final col = cell[0];
      final row = cell[1];
      if (row < 0 || row >= rows || col < 0 || col >= columns) {
        continue;
      }
      if (grid[row][col] == TileType.citadel) {
        continue;
      }
      grid[row][col] = TileType.blocked;
    }

    return grid;
  }

  static List<List<int>> _obstacleCellsFromDefinitions(
    List<StageObstacleDefinition> obstacles,
  ) {
    final cells = <String, List<int>>{};
    for (final obstacle in obstacles) {
      for (final cell in obstacle.occupiedCells) {
        cells[_cellKey(cell[0], cell[1])] = [cell[0], cell[1]];
      }
    }
    return cells.values.toList();
  }

  static List<StageObstacleDefinition> _authoredCitadelObstaclesForStage(
    int stageNumber,
  ) {
    const wall = 'assets/sprites/environment/landmarks/bastion_wall_chunk.png';
    const sign = 'assets/sprites/environment/props/road_signpost.png';
    const well = 'assets/sprites/environment/props/well.png';
    const fence = 'assets/sprites/environment/props/wooden_fence_segment.png';
    const wagon = 'assets/sprites/environment/props/wagon_wreck.png';
    const supply = 'assets/sprites/environment/props/supply_crate.png';
    const siege = 'assets/sprites/environment/props/siege_crate.png';

    StageObstacleDefinition oneCell(
      String assetPath,
      int col,
      int row, {
      double scale = 1,
    }) {
      return StageObstacleDefinition(
        assetPath: assetPath,
        occupiedCells: [
          [col, row],
        ],
        scale: scale,
      );
    }

    List<StageObstacleDefinition> walls(List<List<int>> cells) {
      return [
        for (final cell in cells) oneCell(wall, cell[0], cell[1], scale: 0.51),
      ];
    }

    final outerProps = [
      oneCell(sign, 1, 2),
      oneCell(well, 12, 2),
      oneCell(fence, 1, 11),
      oneCell(wagon, 12, 11),
      oneCell(supply, 2, 9),
      oneCell(siege, 11, 9),
    ];

    return switch (stageNumber) {
      1 => [
        ...outerProps,
        ...walls([
          [5, 3],
          [6, 3],
          [7, 3],
          [8, 3],
          [3, 5],
          [3, 6],
          [3, 7],
          [9, 5],
          [9, 6],
          [9, 7],
          [5, 9],
          [6, 9],
          [7, 9],
          [8, 9],
        ]),
      ],
      2 => [
        ...outerProps,
        ...walls([
          [5, 3],
          [6, 3],
          [7, 3],
          [9, 5],
          [9, 7],
          [10, 5],
          [10, 7],
          [5, 9],
          [6, 9],
          [8, 9],
          [10, 8],
          [3, 5],
          [3, 6],
        ]),
      ],
      3 => [
        ...outerProps,
        ...walls([
          [6, 2],
          [8, 2],
          [9, 6],
          [9, 8],
          [10, 6],
          [10, 8],
          [5, 10],
          [6, 10],
          [7, 10],
          [3, 6],
          [4, 6],
        ]),
      ],
      4 => [
        ...outerProps,
        ...walls([
          [5, 3],
          [7, 3],
          [3, 5],
          [9, 5],
          [3, 7],
          [9, 7],
          [5, 9],
          [7, 9],
        ]),
      ],
      5 => [
        ...outerProps,
        ...walls([
          [5, 3],
          [6, 3],
          [7, 3],
          [8, 3],
          [10, 7],
          [11, 7],
          [5, 9],
          [7, 9],
          [8, 9],
          [3, 6],
          [3, 7],
        ]),
      ],
      6 => [
        ...outerProps,
        ...walls([
          [8, 3],
          [9, 3],
          [9, 4],
          [10, 4],
          [10, 6],
          [10, 7],
          [5, 8],
          [6, 8],
          [9, 8],
          [4, 5],
          [4, 7],
          [11, 6],
        ]),
      ],
      7 => [
        ...outerProps,
        ...walls([
          [10, 3],
          [10, 4],
          [11, 3],
          [11, 6],
          [11, 7],
          [6, 8],
          [7, 9],
          [8, 9],
          [10, 8],
          [5, 5],
          [5, 7],
        ]),
      ],
      8 => [
        ...outerProps,
        ...walls([
          [7, 2],
          [10, 3],
          [11, 5],
          [10, 6],
          [11, 7],
          [7, 7],
          [10, 8],
          [10, 9],
          [5, 4],
          [5, 6],
          [6, 9],
        ]),
      ],
      9 => [
        ...outerProps,
        ...walls([
          [8, 3],
          [10, 3],
          [11, 4],
          [11, 6],
          [10, 7],
          [8, 8],
          [11, 8],
          [6, 5],
          [5, 6],
          [4, 9],
          [7, 9],
        ]),
      ],
      10 => [
        ...outerProps,
        ...walls([
          [8, 2],
          [7, 2],
          [11, 3],
          [11, 5],
          [10, 6],
          [8, 7],
          [11, 7],
          [6, 4],
          [5, 5],
          [4, 8],
          [7, 9],
        ]),
      ],
      _ => const [],
    };
  }

  static void _validateSiegeRoute({
    required List<List<int>> route,
    required SpawnDirection direction,
    required int columns,
    required int rows,
    required List<int> citadelCell,
  }) {
    if (route.isEmpty) {
      throw StateError('Siege route for $direction cannot be empty.');
    }

    final seen = <String>{};
    for (var index = 0; index < route.length; index += 1) {
      final cell = route[index];
      final col = cell[0];
      final row = cell[1];
      final key = _cellKey(col, row);

      if (col < 0 || col >= columns || row < 0 || row >= rows) {
        throw StateError(
          'Siege route cell $key is out of bounds for $direction.',
        );
      }
      if (!seen.add(key)) {
        throw StateError('Siege route for $direction revisits $key.');
      }

      if (index > 0) {
        final previous = route[index - 1];
        final dx = (col - previous[0]).abs();
        final dy = (row - previous[1]).abs();
        if ((dx + dy) != 1) {
          throw StateError(
            'Siege route for $direction must move one orthogonal cell at a time.',
          );
        }
      }
    }

    final first = route.first;
    final startsOnExpectedEdge = switch (direction) {
      SpawnDirection.north => first[1] == 0,
      SpawnDirection.south => first[1] == rows - 1,
      SpawnDirection.east => first[0] == columns - 1,
      SpawnDirection.west => first[0] == 0,
    };
    if (!startsOnExpectedEdge) {
      throw StateError(
        'Siege route for $direction must start on the matching edge.',
      );
    }

    final tail = route.last;
    final citadelCol = citadelCell[0];
    final citadelRow = citadelCell[1];
    final touchesCitadel = switch (direction) {
      SpawnDirection.north =>
        tail[0] == citadelCol && tail[1] == citadelRow - 1,
      SpawnDirection.south =>
        tail[0] == citadelCol && tail[1] == citadelRow + 1,
      SpawnDirection.east => tail[0] == citadelCol + 1 && tail[1] == citadelRow,
      SpawnDirection.west => tail[0] == citadelCol - 1 && tail[1] == citadelRow,
    };
    if (!touchesCitadel) {
      throw StateError(
        'Siege route for $direction must end adjacent to the citadel ring.',
      );
    }
  }

  // ignore: unused_field
  static const List<String> _authoredCitadelTitles = [
    'Stage 1 - 사방 압박 입문',
    'Stage 2 - 방향별 강약 차이',
    'Stage 3 - 첫 중장 체크',
    'Stage 4 - 성 근처 압박',
    'Stage 5 - 초반 종합 시험',
    'Stage 6 - 오른쪽 위 성 첫 변형',
  ];

  // ignore: unused_field
  static const List<String> _authoredCitadelDescriptions = [
    '첫 Stage부터 사방에서 적이 들어옵니다. 장애물 우회를 읽고 중앙 성을 지키세요.',
    '사방 압박은 유지되지만 동쪽 길이 가장 짧습니다. 먼저 막을 방향을 판단하세요.',
    '방패 보병이 본격적으로 등장합니다. 저지와 마법 대응을 함께 준비하세요.',
    '성 근처까지 이어지는 짧은 직선 압박이 강해집니다. 마지막 방어선을 놓치지 마세요.',
    '초반 구간 종합 시험입니다. 빠른 압박, 중장, 사방 분산을 모두 처리해야 합니다.',
    '성이 오른쪽 위로 이동합니다. 짧은 북동 압박을 막고 아래쪽 넓은 킬존을 활용하세요.',
  ];

  static const List<_CitadelSiegeLayout> _authoredCitadelLayouts = [
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.north,
      pathsByDirection: {
        SpawnDirection.north: [
          [6, 0],
          [6, 1],
          [6, 2],
          [5, 2],
          [4, 2],
          [4, 3],
          [4, 4],
          [5, 4],
          [6, 4],
          [6, 5],
        ],
        SpawnDirection.south: [
          [7, 13],
          [7, 12],
          [7, 11],
          [8, 11],
          [9, 11],
          [9, 10],
          [9, 9],
          [9, 8],
          [8, 8],
          [7, 8],
          [6, 8],
          [6, 7],
        ],
        SpawnDirection.east: [
          [13, 6],
          [12, 6],
          [11, 6],
          [10, 6],
          [10, 7],
          [10, 8],
          [9, 8],
          [8, 8],
          [7, 8],
          [7, 7],
          [7, 6],
        ],
        SpawnDirection.west: [
          [0, 6],
          [1, 6],
          [2, 6],
          [2, 5],
          [2, 4],
          [3, 4],
          [4, 4],
          [5, 4],
          [5, 5],
          [5, 6],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.east,
      pathsByDirection: {
        SpawnDirection.north: [
          [5, 0],
          [5, 1],
          [5, 2],
          [4, 2],
          [3, 2],
          [3, 3],
          [3, 4],
          [4, 4],
          [5, 4],
          [6, 4],
          [6, 5],
        ],
        SpawnDirection.south: [
          [8, 13],
          [8, 12],
          [9, 12],
          [10, 12],
          [10, 11],
          [10, 10],
          [9, 10],
          [8, 10],
          [7, 10],
          [7, 9],
          [7, 8],
          [7, 7],
          [6, 7],
        ],
        SpawnDirection.east: [
          [13, 6],
          [12, 6],
          [11, 6],
          [10, 6],
          [9, 6],
          [8, 6],
          [7, 6],
        ],
        SpawnDirection.west: [
          [0, 7],
          [1, 7],
          [2, 7],
          [3, 7],
          [3, 8],
          [4, 8],
          [5, 8],
          [5, 7],
          [5, 6],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.east,
      pathsByDirection: {
        SpawnDirection.north: [
          [7, 0],
          [7, 1],
          [7, 2],
          [7, 3],
          [6, 3],
          [5, 3],
          [5, 4],
          [5, 5],
          [6, 5],
        ],
        SpawnDirection.south: [
          [5, 13],
          [5, 12],
          [5, 11],
          [4, 11],
          [3, 11],
          [3, 10],
          [3, 9],
          [4, 9],
          [5, 9],
          [6, 9],
          [6, 8],
          [6, 7],
        ],
        SpawnDirection.east: [
          [13, 7],
          [12, 7],
          [11, 7],
          [10, 7],
          [9, 7],
          [8, 7],
          [7, 7],
          [7, 6],
        ],
        SpawnDirection.west: [
          [0, 5],
          [1, 5],
          [2, 5],
          [3, 5],
          [4, 5],
          [5, 5],
          [5, 6],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.south,
      pathsByDirection: {
        SpawnDirection.north: [
          [6, 0],
          [6, 1],
          [6, 2],
          [6, 3],
          [6, 4],
          [6, 5],
        ],
        SpawnDirection.south: [
          [6, 13],
          [6, 12],
          [6, 11],
          [6, 10],
          [6, 9],
          [6, 8],
          [6, 7],
        ],
        SpawnDirection.east: [
          [13, 6],
          [12, 6],
          [11, 6],
          [10, 6],
          [9, 6],
          [8, 6],
          [7, 6],
        ],
        SpawnDirection.west: [
          [0, 6],
          [1, 6],
          [2, 6],
          [3, 6],
          [4, 6],
          [5, 6],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.north,
      pathsByDirection: {
        SpawnDirection.north: [
          [6, 0],
          [6, 1],
          [6, 2],
          [5, 2],
          [4, 2],
          [4, 3],
          [4, 4],
          [5, 4],
          [6, 4],
          [6, 5],
        ],
        SpawnDirection.south: [
          [7, 13],
          [7, 12],
          [8, 12],
          [9, 12],
          [9, 11],
          [9, 10],
          [8, 10],
          [7, 10],
          [6, 10],
          [6, 9],
          [6, 8],
          [6, 7],
        ],
        SpawnDirection.east: [
          [13, 5],
          [12, 5],
          [11, 5],
          [10, 5],
          [10, 6],
          [9, 6],
          [8, 6],
          [7, 6],
        ],
        SpawnDirection.west: [
          [0, 8],
          [1, 8],
          [2, 8],
          [3, 8],
          [4, 8],
          [4, 7],
          [4, 6],
          [5, 6],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.east,
      citadelCell: [7, 5],
      pathsByDirection: {
        SpawnDirection.north: [
          [7, 0],
          [7, 1],
          [8, 1],
          [9, 1],
          [9, 2],
          [8, 2],
          [7, 2],
          [7, 3],
          [7, 4],
        ],
        SpawnDirection.south: [
          [6, 13],
          [6, 12],
          [5, 12],
          [4, 12],
          [4, 11],
          [4, 10],
          [5, 10],
          [6, 10],
          [7, 10],
          [8, 10],
          [8, 9],
          [8, 8],
          [7, 8],
          [7, 7],
          [7, 6],
        ],
        SpawnDirection.east: [
          [13, 5],
          [12, 5],
          [11, 5],
          [10, 5],
          [9, 5],
          [8, 5],
        ],
        SpawnDirection.west: [
          [0, 7],
          [1, 7],
          [2, 7],
          [3, 7],
          [3, 6],
          [4, 6],
          [5, 6],
          [5, 5],
          [6, 5],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.east,
      citadelCell: [8, 5],
      pathsByDirection: {
        SpawnDirection.north: [
          [8, 0],
          [8, 1],
          [9, 1],
          [10, 1],
          [10, 2],
          [9, 2],
          [8, 2],
          [8, 3],
          [8, 4],
        ],
        SpawnDirection.south: [
          [7, 13],
          [7, 12],
          [6, 12],
          [5, 12],
          [5, 11],
          [5, 10],
          [6, 10],
          [7, 10],
          [8, 10],
          [9, 10],
          [9, 9],
          [9, 8],
          [8, 8],
          [8, 7],
          [8, 6],
        ],
        SpawnDirection.east: [
          [13, 5],
          [12, 5],
          [11, 5],
          [10, 5],
          [9, 5],
        ],
        SpawnDirection.west: [
          [0, 7],
          [1, 7],
          [2, 7],
          [3, 7],
          [4, 7],
          [4, 6],
          [5, 6],
          [6, 6],
          [7, 6],
          [7, 5],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.north,
      citadelCell: [8, 4],
      pathsByDirection: {
        SpawnDirection.north: [
          [8, 0],
          [8, 1],
          [9, 1],
          [10, 1],
          [10, 2],
          [9, 2],
          [8, 2],
          [8, 3],
        ],
        SpawnDirection.south: [
          [7, 13],
          [7, 12],
          [6, 12],
          [5, 12],
          [5, 11],
          [5, 10],
          [6, 10],
          [7, 10],
          [8, 10],
          [9, 10],
          [9, 9],
          [9, 8],
          [8, 8],
          [8, 7],
          [8, 6],
          [8, 5],
        ],
        SpawnDirection.east: [
          [13, 4],
          [12, 4],
          [11, 4],
          [10, 4],
          [9, 4],
        ],
        SpawnDirection.west: [
          [0, 6],
          [1, 6],
          [2, 6],
          [3, 6],
          [4, 6],
          [4, 5],
          [5, 5],
          [6, 5],
          [7, 5],
          [7, 4],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.west,
      citadelCell: [9, 5],
      pathsByDirection: {
        SpawnDirection.north: [
          [9, 0],
          [9, 1],
          [10, 1],
          [11, 1],
          [11, 2],
          [10, 2],
          [9, 2],
          [9, 3],
          [9, 4],
        ],
        SpawnDirection.south: [
          [8, 13],
          [8, 12],
          [7, 12],
          [6, 12],
          [6, 11],
          [6, 10],
          [7, 10],
          [8, 10],
          [9, 10],
          [10, 10],
          [10, 9],
          [10, 8],
          [9, 8],
          [9, 7],
          [9, 6],
        ],
        SpawnDirection.east: [
          [13, 5],
          [12, 5],
          [11, 5],
          [10, 5],
        ],
        SpawnDirection.west: [
          [0, 8],
          [1, 8],
          [2, 8],
          [3, 8],
          [4, 8],
          [4, 7],
          [5, 7],
          [6, 7],
          [7, 7],
          [8, 7],
          [8, 6],
          [8, 5],
        ],
      },
    ),
    _CitadelSiegeLayout(
      primaryFront: SpawnDirection.north,
      citadelCell: [9, 4],
      pathsByDirection: {
        SpawnDirection.north: [
          [9, 0],
          [9, 1],
          [10, 1],
          [11, 1],
          [11, 2],
          [10, 2],
          [9, 2],
          [9, 3],
        ],
        SpawnDirection.south: [
          [8, 13],
          [8, 12],
          [7, 12],
          [6, 12],
          [6, 11],
          [6, 10],
          [7, 10],
          [8, 10],
          [9, 10],
          [10, 10],
          [10, 9],
          [10, 8],
          [9, 8],
          [9, 7],
          [9, 6],
          [9, 5],
        ],
        SpawnDirection.east: [
          [13, 4],
          [12, 4],
          [11, 4],
          [10, 4],
        ],
        SpawnDirection.west: [
          [0, 7],
          [1, 7],
          [2, 7],
          [3, 7],
          [4, 7],
          [4, 6],
          [5, 6],
          [6, 6],
          [7, 6],
          [8, 6],
          [8, 5],
          [8, 4],
        ],
      },
    ),
  ];

  static String _cellKey(int col, int row) => '$col:$row';
}

@Deprecated(
  'Use CampaignData from lib/data/campaign/campaign_data.dart instead.',
)
class SampleCampaign {
  static const int totalStages = CampaignData.totalStages;

  static StageDefinition stage(int number) => CampaignData.stage(number);

  static List<StageDefinition> allStages() => CampaignData.allStages();

  static EnemyDefinition enemyForKind(
    EnemyKind kind, {
    required int stageNumber,
    double intensity = 1.0,
  }) {
    return CampaignData.enemyForKind(
      kind,
      stageNumber: stageNumber,
      intensity: intensity,
    );
  }
}

class _BiomeProfile {
  const _BiomeProfile({
    required this.title,
    required this.commonKinds,
    required this.supportKinds,
    required this.eliteKinds,
    required this.bossKind,
  });

  final String title;
  final List<EnemyKind> commonKinds;
  final List<EnemyKind> supportKinds;
  final List<EnemyKind> eliteKinds;
  final EnemyKind bossKind;
}

class _CitadelSiegeLayout {
  const _CitadelSiegeLayout({
    required this.primaryFront,
    this.citadelCell = const [6, 6],
    required this.pathsByDirection,
  });

  final SpawnDirection primaryFront;
  final List<int> citadelCell;
  final Map<SpawnDirection, List<List<int>>> pathsByDirection;
}
