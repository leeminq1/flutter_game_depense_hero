import 'dart:math' as math;
import 'dart:ui';

import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';

/// Canonical authored campaign data for the playable game.
class CampaignData {
  static const int totalStages = 30;
  static const int _tileColumns = 8;
  static const int _tileRows = 14;
  static const int _buildableTopRow = 2;
  static const int _buildableBottomRow = 11;

  static StageDefinition stage(int number) {
    final safeStage = number.clamp(1, totalStages);
    final biome = _biomeForStage(safeStage);
    final environmentTheme = _environmentThemeForStage(safeStage);
    final templateIndex = (safeStage - 1) % _pathTemplates.length;
    final pathTemplate = _pathTemplates[templateIndex];
    final slotTemplate = _slotTemplates[templateIndex];
    final pathSequence = _buildPathSequence(pathTemplate);
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
    final speedStep = 1 + (((stageNumber - 1) ~/ 5) * 0.05);

    switch (kind) {
      case EnemyKind.raider:
        return EnemyDefinition(
          kind: kind,
          label: 'Raider',
          specialDescription: 'Enrages below half health and runs faster.',
          hitPoints: (44 * hpMultiplier * intensity).round(),
          speed: 48 * speedStep,
          rewardCoins: math.max(6, (6 + stageNumber * 0.8).round()),
          baseDamage: 1,
          color: const Color(0xFFB85C38),
        );
      case EnemyKind.scout:
        return EnemyDefinition(
          kind: kind,
          label: 'Scout',
          specialDescription: 'Dodges the first physical hit that lands on it.',
          hitPoints: (30 * hpMultiplier * math.max(0.9, intensity)).round(),
          speed: 68 * speedStep,
          rewardCoins: math.max(5, (5 + stageNumber * 0.75).round()),
          baseDamage: 1,
          color: const Color(0xFFD89C45),
        );
      case EnemyKind.bannerCaptain:
        return EnemyDefinition(
          kind: kind,
          label: 'Banner Captain',
          specialDescription:
              'Periodically rallies nearby bandits with speed and damage buffs.',
          hitPoints: (60 * hpMultiplier * intensity).round(),
          speed: 44 * speedStep,
          rewardCoins: math.max(9, (9 + stageNumber * 0.9).round()),
          baseDamage: 2,
          color: const Color(0xFF9E523C),
        );
      case EnemyKind.wolfScout:
        return EnemyDefinition(
          kind: kind,
          label: 'Wolf Scout',
          specialDescription:
              'Dodges its first physical hit and sprints harder when wounded.',
          hitPoints: (38 * hpMultiplier * math.max(0.95, intensity)).round(),
          speed: 74 * speedStep,
          rewardCoins: math.max(7, (7 + stageNumber * 0.85).round()),
          baseDamage: 1,
          color: const Color(0xFF8B7A57),
        );
      case EnemyKind.shieldInfantry:
        return EnemyDefinition(
          kind: kind,
          label: 'Shield Infantry',
          specialDescription: 'Reduces damage from physical towers.',
          hitPoints: (86 * hpMultiplier * intensity).round(),
          speed: 34 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFF7D8EA3),
        );
      case EnemyKind.cultAdept:
        return EnemyDefinition(
          kind: kind,
          label: 'Cult Adept',
          specialDescription: 'Periodically hastes nearby allies.',
          hitPoints: (58 * hpMultiplier * intensity).round(),
          speed: 42 * speedStep,
          rewardCoins: math.max(10, (10 + stageNumber * 0.9).round()),
          baseDamage: 1,
          color: const Color(0xFF6E4EAA),
        );
      case EnemyKind.skeleton:
        return EnemyDefinition(
          kind: kind,
          label: 'Skeleton',
          specialDescription: 'Revives once with partial health.',
          hitPoints: (78 * hpMultiplier * intensity).round(),
          speed: 40 * speedStep,
          rewardCoins: math.max(11, (11 + stageNumber).round()),
          baseDamage: 2,
          color: const Color(0xFFBDB9AA),
        );
      case EnemyKind.boneArcher:
        return EnemyDefinition(
          kind: kind,
          label: 'Bone Archer',
          specialDescription:
              'Leaves a fresh skeleton behind when it is destroyed.',
          hitPoints: (66 * hpMultiplier * intensity).round(),
          speed: 44 * speedStep,
          rewardCoins: math.max(13, (13 + stageNumber * 1.05).round()),
          baseDamage: 2,
          color: const Color(0xFFC8C1AF),
        );
      case EnemyKind.graveGuard:
        return EnemyDefinition(
          kind: kind,
          label: 'Grave Guard',
          specialDescription:
              'Resists slows and pushes through control effects.',
          hitPoints: (172 * hpMultiplier * (intensity + 0.08)).round(),
          speed: 26 * speedStep,
          rewardCoins: math.max(20, (20 + stageNumber * 1.15).round()),
          baseDamage: 3,
          color: const Color(0xFF63705F),
        );
      case EnemyKind.plagueBearer:
        return EnemyDefinition(
          kind: kind,
          label: 'Plague Bearer',
          specialDescription:
              'Heals nearby undead and shrouds them in brief damage reduction.',
          hitPoints: (104 * hpMultiplier * intensity).round(),
          speed: 34 * speedStep,
          rewardCoins: math.max(21, (21 + stageNumber * 1.15).round()),
          baseDamage: 2,
          color: const Color(0xFF5E7152),
        );
      case EnemyKind.corruptedKnight:
        return EnemyDefinition(
          kind: kind,
          label: 'Corrupted Knight',
          specialDescription:
              'Charges harder when wounded and resists physical fire.',
          hitPoints: (145 * hpMultiplier * (intensity + 0.15)).round(),
          speed: 30 * speedStep,
          rewardCoins: math.max(18, (18 + stageNumber * 1.2).round()),
          baseDamage: 3,
          color: const Color(0xFF7A5151),
        );
      case EnemyKind.hexSniper:
        return EnemyDefinition(
          kind: kind,
          label: 'Hex Sniper',
          specialDescription:
              'Refreshes a ward for itself and the most important nearby ally.',
          hitPoints: (92 * hpMultiplier * intensity).round(),
          speed: 38 * speedStep,
          rewardCoins: math.max(25, (25 + stageNumber * 1.3).round()),
          baseDamage: 2,
          color: const Color(0xFF5C4B73),
        );
      case EnemyKind.warlock:
        return EnemyDefinition(
          kind: kind,
          label: 'Warlock',
          specialDescription:
              'Wards allies and summons skeleton reinforcements.',
          hitPoints: (98 * hpMultiplier * intensity).round(),
          speed: 33 * speedStep,
          rewardCoins: math.max(22, (22 + stageNumber * 1.25).round()),
          baseDamage: 2,
          color: const Color(0xFF5E3E88),
        );
      case EnemyKind.bastionPriest:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Priest',
          specialDescription:
              'Heals elite allies and restores a ward to keep the line standing.',
          hitPoints: (138 * hpMultiplier * (intensity + 0.06)).round(),
          speed: 28 * speedStep,
          rewardCoins: math.max(29, (29 + stageNumber * 1.35).round()),
          baseDamage: 3,
          color: const Color(0xFF8A7A5E),
        );
      case EnemyKind.bastionOverlord:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Overlord',
          specialDescription:
              'Final boss that phases, wards itself, and summons defenders.',
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
        return 'Learn the core loop: place archers, start the wave, and hold the first road.';
      case 2:
        return 'Scouts come faster now. Mix steady damage with cleaner placement before the wave starts.';
      case 3:
        return 'Shield Infantry arrive. Add a Mage so armor does not stall your defense.';
      case 4:
        return 'Banner Captains join the lane here. Use Barracks or Frost to keep buffed raiders inside your damage zones.';
      case 5:
        return 'First crest stage. Hold the gate through a denser final push and keep your economy stable.';
    }
    switch (stage) {
      case 6:
        return 'Wolf Scouts begin slipping into the push. Survive the longer battle without letting the fast flankers leak through.';
      case 7:
        return 'First support pressure. Spot the Cult Adept early before the frontline snowballs.';
      case 8:
        return 'Lane stability test. Hold bends cleanly while shields and fast units mix together.';
      case 9:
        return 'Faction transition stage. Armor and support begin to overlap in the same push.';
      case 10:
        return 'First mid-game crest. Stabilize early, then survive a readable mixed-pressure final wave.';
      case 11:
        return 'The grave line begins. Reviving skeletons and armored escorts punish weak cleanup.';
      case 12:
        return 'Bone Archers extend every undead fight. Deny support pacing before the lane gets doubled by fresh skeleton bodies.';
      case 13:
        return 'Mixed undead traffic tests your control timing. Keep one lane as a true kill zone.';
      case 14:
        return 'Corrupted knights start joining the push. Save enough coins to answer the final turn.';
      case 15:
        return 'Grave crest stage. Hold a longer ritual march and survive the elite finish without panic spending.';
      case 16:
        return 'The chapel front opens. Faster support and knight pressure now overlap on purpose.';
      case 17:
        return 'Plague Bearers arrive now. Build your control and anti-armor line before the undead sustain engine turns on.';
      case 18:
        return 'Grave Guards arrive. Pure slows and weak poke no longer hold the frontline alone.';
      case 19:
        return 'Mixed resistant pressure asks for cleaner tower synergy and fewer wasted upgrades.';
      case 20:
        return 'Chapel crest stage. Endure sustained elite pressure and keep the lane stable through the final wave.';
      case 21:
        return 'Hex Snipers start layering wards into the bastion push. Your backline answers have to land before the elites take over.';
      case 22:
        return 'This lane teaches ward pressure. If Warlocks live too long, the armored push becomes much more expensive to stop.';
      case 23:
        return 'Bastion overlap begins here. Grave Guards and Warlocks now force cleaner kill windows instead of slow attrition.';
      case 24:
        return 'Bastion Priests enter the route here. Save enough for the last two waves or the healed frontline will snowball out of reach.';
      case 25:
        return 'Bastion crest stage. Endure sustained support pressure and hold the final military push without losing your anchor towers.';
      case 26:
        return 'The throne march opens. Resistant tanks and Warlocks now arrive early enough to punish weak starts.';
      case 27:
        return 'Late reactions fail here. Build the anti-support line before the lane fills with resistant pressure.';
      case 28:
        return 'This stage stresses recovery. Summons, tanks, and bruisers overlap long enough to punish scattered damage.';
      case 29:
        return 'Final approach. The game now expects real late-campaign discipline, not emergency rebuilding every wave.';
    }
    if (stage <= 5) {
      return 'Hold the ${biome.title.toLowerCase()} against early bandit pressure and its first rally support.';
    }
    if (stage <= 10) {
      return 'Armored fronts, fast wolf flankers, and support leaders begin to overlap here. Build earlier and leave room for magic damage.';
    }
    if (stage <= 15) {
      return 'Undead pressure now asks for stronger lane cleanup, armor answers, and steadier economy timing as Bone Archers lengthen fights.';
    }
    if (stage <= 20) {
      return 'Control-resistant threats, elite bruisers, and plague sustain demand cleaner tower synergy and better late-wave coin discipline.';
    }
    if (stage <= 25) {
      return 'Ward-heavy support and bruiser fronts now arrive together. You need cleaner anti-support timing and stronger elite damage.';
    }
    if (stage == 30) {
      return 'Final siege. Survive the Bastion Overlord and its summoned defenders to finish the campaign.';
    }
    return 'Throne-march stages layer summoners, control-resistant tanks, and elite bruisers into the same push with very little recovery room.';
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

  static const List<List<Offset>> _slotTemplates = [
    [
      Offset(0.14, 0.47),
      Offset(0.16, 0.83),
      Offset(0.33, 0.50),
      Offset(0.38, 0.18),
      Offset(0.58, 0.52),
      Offset(0.67, 0.86),
      Offset(0.84, 0.60),
    ],
    [
      Offset(0.12, 0.31),
      Offset(0.24, 0.66),
      Offset(0.35, 0.38),
      Offset(0.40, 0.90),
      Offset(0.62, 0.53),
      Offset(0.79, 0.36),
      Offset(0.86, 0.76),
    ],
    [
      Offset(0.15, 0.10),
      Offset(0.18, 0.54),
      Offset(0.39, 0.56),
      Offset(0.46, 0.88),
      Offset(0.63, 0.48),
      Offset(0.72, 0.16),
      Offset(0.89, 0.49),
    ],
    [
      Offset(0.11, 0.73),
      Offset(0.26, 0.44),
      Offset(0.34, 0.92),
      Offset(0.57, 0.57),
      Offset(0.63, 0.08),
      Offset(0.83, 0.32),
      Offset(0.88, 0.78),
    ],
    [
      Offset(0.11, 0.19),
      Offset(0.22, 0.56),
      Offset(0.33, 0.85),
      Offset(0.48, 0.48),
      Offset(0.58, 0.11),
      Offset(0.75, 0.58),
      Offset(0.89, 0.84),
    ],
  ];

  static List<List<int>> _buildPathSequence(List<Offset> template) {
    final anchors = template.map(_pathAnchorFromOffset).toList();
    final sequence = <List<int>>[];
    for (var i = 0; i < anchors.length; i += 1) {
      final current = anchors[i];
      if (sequence.isEmpty) {
        sequence.add([current.$1, current.$2]);
      }
      if (i == anchors.length - 1) {
        break;
      }

      final next = anchors[i + 1];
      final stepCol = (next.$1 - current.$1).sign;
      final stepRow = (next.$2 - current.$2).sign;
      if (stepCol != 0 && stepRow != 0) {
        throw StateError('Path template contains a diagonal segment.');
      }

      var col = current.$1;
      var row = current.$2;
      while (col != next.$1 || row != next.$2) {
        col += stepCol;
        row += stepRow;
        sequence.add([col, row]);
      }
    }
    return sequence;
  }

  static (int, int) _pathAnchorFromOffset(Offset node) {
    final col = (node.dx * (_tileColumns - 1)).round().clamp(
      0,
      _tileColumns - 1,
    );
    final row = (node.dy * (_tileRows - 1)).round().clamp(
      _buildableTopRow,
      _buildableBottomRow,
    );
    return (col, row);
  }

  static List<List<TileType>> _buildTileGrid(
    List<List<int>> pathSequence,
    List<Offset> slotTemplate,
  ) {
    final grid = List.generate(
      _tileRows,
      (_) => List.generate(_tileColumns, (_) => TileType.blocked),
    );
    final pathCells = {
      for (final cell in pathSequence) _cellKey(cell[0], cell[1]),
    };
    final slotCells = {
      for (final slot in slotTemplate) _slotCellFromOffset(slot),
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

  static String _slotCellFromOffset(Offset slot) {
    final col = (slot.dx * (_tileColumns - 1)).round().clamp(
      0,
      _tileColumns - 1,
    );
    final row = (slot.dy * (_tileRows - 1)).round().clamp(
      _buildableTopRow,
      _buildableBottomRow,
    );
    return _cellKey(col, row);
  }

  static List<Offset> _normalizedPathNodes(List<List<int>> pathSequence) {
    return [
      for (final cell in pathSequence)
        Offset(cell[0] / (_tileColumns - 1), cell[1] / (_tileRows - 1)),
    ];
  }

  static List<Offset> _normalizedBuildSlots(List<List<TileType>> tileGrid) {
    final slots = <Offset>[];
    for (var row = 0; row < tileGrid.length; row += 1) {
      for (var col = 0; col < tileGrid[row].length; col += 1) {
        if (tileGrid[row][col] != TileType.buildable) {
          continue;
        }
        slots.add(Offset(col / (_tileColumns - 1), row / (_tileRows - 1)));
      }
    }
    return slots;
  }

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
