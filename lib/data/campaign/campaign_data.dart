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
      stageEvents: _stageEventsForStage(safeStage),
      bombardment: _bombardmentForStage(safeStage, waveCount),
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
    int scaled(int coins) => ((coins * 0.85) / 5).round() * 5;
    if (stageNumber <= 5) return scaled(300 + ((stageNumber - 1) * 20));
    if (stageNumber <= 10) return scaled(410 + ((stageNumber - 6) * 20));
    if (stageNumber <= 15) return scaled(520 + ((stageNumber - 11) * 24));
    if (stageNumber <= 20) return scaled(650 + ((stageNumber - 16) * 28));
    if (stageNumber <= 25) return scaled(800 + ((stageNumber - 21) * 32));
    return scaled(970 + ((stageNumber - 26) * 36));
  }

  static int _baseHealthForStage(int stageNumber) {
    return 3;
  }

  static double _enemyHpBalanceMultiplier(int stageNumber) {
    if (stageNumber <= 5) return 0.50;
    if (stageNumber <= 10) return 0.62;
    if (stageNumber <= 15) return 0.72;
    if (stageNumber <= 20) return 0.82;
    if (stageNumber <= 25) return 0.92;
    return 1.0;
  }

  static double _enemyContactDamageMultiplier(int stageNumber) {
    if (stageNumber <= 5) return 0.70;
    if (stageNumber <= 10) return 0.78;
    if (stageNumber <= 15) return 0.84;
    if (stageNumber <= 20) return 0.90;
    if (stageNumber <= 25) return 0.95;
    return 1.0;
  }

  static int _scaledStructureDamageFor(EnemyKind kind, double multiplier) {
    final damage = EnemyDefinition.defaultStructureDamageFor(kind);
    return (damage * multiplier).round().clamp(1, damage);
  }

  static int _scaledTowerContactDamageFor(EnemyKind kind, double multiplier) {
    final damage = EnemyDefinition.defaultTowerContactDamageFor(kind);
    return (damage * multiplier).round().clamp(1, damage);
  }

  static int _recoveryGoldBonusForStage(int stageNumber, int cycleNumber) {
    final actNumber = ((stageNumber - 1) ~/ 5) + 1;
    final base = switch (actNumber) {
      1 => 70,
      2 => 90,
      3 => 115,
      4 => 145,
      5 => 180,
      _ => 220,
    };
    final perCycle = switch (actNumber) {
      1 => 15,
      2 => 18,
      3 => 22,
      4 => 26,
      5 => 30,
      _ => 35,
    };
    return base + (perCycle * cycleNumber);
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
              count: 4,
              spawnInterval: 0.82,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 0.88,
              ),
              count: 2,
              spawnInterval: 0.95,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 1,
                intensity: 1.0,
              ),
              count: 5,
              spawnInterval: 0.78,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 0.95,
              ),
              count: 3,
              spawnInterval: 0.88,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 1,
                intensity: 1.08,
              ),
              count: 6,
              spawnInterval: 0.74,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 1,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.82,
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
              count: 5,
              spawnInterval: 0.78,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 2,
                intensity: 0.92,
              ),
              count: 3,
              spawnInterval: 0.88,
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
              spawnInterval: 0.74,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 2,
                intensity: 1.0,
              ),
              count: 4,
              spawnInterval: 0.82,
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
              spawnInterval: 0.76,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 2,
                intensity: 1.08,
              ),
              count: 5,
              spawnInterval: 0.74,
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
              count: 5,
              spawnInterval: 0.76,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 3,
                intensity: 0.96,
              ),
              count: 3,
              spawnInterval: 0.82,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 3,
                intensity: 1.0,
              ),
              count: 5,
              spawnInterval: 0.78,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 3,
                intensity: 0.78,
              ),
              count: 2,
              spawnInterval: 1.1,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 3,
                intensity: 1.06,
              ),
              count: 5,
              spawnInterval: 0.72,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 3,
                intensity: 0.84,
              ),
              count: 3,
              spawnInterval: 1.05,
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
              count: 5,
              spawnInterval: 0.74,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.82,
              ),
              count: 2,
              spawnInterval: 1.05,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 4,
                intensity: 1.02,
              ),
              count: 5,
              spawnInterval: 0.74,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.88,
              ),
              count: 2,
              spawnInterval: 1.0,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 4,
                intensity: 1.08,
              ),
              count: 5,
              spawnInterval: 0.70,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 4,
                intensity: 1.04,
              ),
              count: 4,
              spawnInterval: 0.74,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 4,
                intensity: 0.92,
              ),
              count: 2,
              spawnInterval: 0.95,
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
              spawnInterval: 0.72,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 0.86,
              ),
              count: 2,
              spawnInterval: 1.0,
            ),
          ],
          2 => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 5,
                intensity: 1.08,
              ),
              count: 6,
              spawnInterval: 0.72,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 0.92,
              ),
              count: 2,
              spawnInterval: 0.95,
            ),
          ],
          _ => [
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.raider,
                stageNumber: 5,
                intensity: 1.12,
              ),
              count: 5,
              spawnInterval: 0.68,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.scout,
                stageNumber: 5,
                intensity: 1.08,
              ),
              count: 5,
              spawnInterval: 0.70,
            ),
            SpawnGroupDefinition(
              enemy: enemyForKind(
                EnemyKind.shieldInfantry,
                stageNumber: 5,
                intensity: 1.0,
              ),
              count: 3,
              spawnInterval: 0.90,
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
    final durabilityMultiplier = stageNumber <= 5
        ? 1.75
        : stageNumber <= 15
        ? 1.55
        : 1.40;
    final hpMultiplier =
        (1 + ((stageNumber - 1) * 0.18)) *
        durabilityMultiplier *
        _enemyHpBalanceMultiplier(stageNumber);
    final actNumber = ((stageNumber - 1) ~/ 5) + 1;
    final moveSpeedMultiplier = 1 + ((actNumber - 1) * 0.06);
    final killRewardMultiplier = 0.82 + ((stageNumber - 1) * 0.025);
    int scaledKillReward(int baseReward, {double minimumIntensity = 0.95}) {
      return math.max(
        1,
        (baseReward *
                killRewardMultiplier *
                math.max(minimumIntensity, intensity))
            .round(),
      );
    }

    final contactDamageMultiplier = _enemyContactDamageMultiplier(stageNumber);
    final structureDamage = _scaledStructureDamageFor(
      kind,
      contactDamageMultiplier,
    );
    final towerContactDamage = _scaledTowerContactDamageFor(
      kind,
      contactDamageMultiplier,
    );

    switch (kind) {
      case EnemyKind.raider:
        return EnemyDefinition(
          kind: kind,
          label: 'Raider',
          specialDescription: 'Enrages below half health and runs faster.',
          hitPoints: (57 * hpMultiplier * intensity).round(),
          speed: 48 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(6),
          citadelDamage: 1,
          color: const Color(0xFFB85C38),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.scout:
        return EnemyDefinition(
          kind: kind,
          label: 'Scout',
          specialDescription: 'Dodges the first physical hit that lands on it.',
          hitPoints: (39 * hpMultiplier * math.max(0.9, intensity)).round(),
          speed: 68 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(5),
          citadelDamage: 1,
          color: const Color(0xFFD89C45),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.bannerCaptain:
        return EnemyDefinition(
          kind: kind,
          label: 'Banner Captain',
          specialDescription:
              'Periodically rallies nearby bandits with speed and damage buffs.',
          hitPoints: (78 * hpMultiplier * intensity).round(),
          speed: 44 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(9),
          citadelDamage: 2,
          color: const Color(0xFF9E523C),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.wolfScout:
        return EnemyDefinition(
          kind: kind,
          label: 'Wolf Scout',
          specialDescription:
              'Dodges its first physical hit and sprints harder when wounded.',
          hitPoints: (49 * hpMultiplier * math.max(0.95, intensity)).round(),
          speed: 74 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(7),
          citadelDamage: 1,
          color: const Color(0xFF8B7A57),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.shieldInfantry:
        return EnemyDefinition(
          kind: kind,
          label: 'Shield Infantry',
          specialDescription: 'Reduces damage from physical towers.',
          hitPoints: (112 * hpMultiplier * intensity).round(),
          speed: 34 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(10),
          citadelDamage: 2,
          color: const Color(0xFF7D8EA3),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.cultAdept:
        return EnemyDefinition(
          kind: kind,
          label: 'Cult Adept',
          specialDescription: 'Periodically hastes nearby allies.',
          hitPoints: (75 * hpMultiplier * intensity).round(),
          speed: 42 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(10),
          citadelDamage: 2,
          color: const Color(0xFF6E4EAA),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.skeleton:
        return EnemyDefinition(
          kind: kind,
          label: 'Skeleton',
          specialDescription: 'Revives once with partial health.',
          hitPoints: (101 * hpMultiplier * intensity).round(),
          speed: 40 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(11),
          citadelDamage: 1,
          color: const Color(0xFFBDB9AA),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.boneArcher:
        return EnemyDefinition(
          kind: kind,
          label: 'Bone Archer',
          specialDescription:
              'Leaves a fresh skeleton behind when it is destroyed.',
          hitPoints: (86 * hpMultiplier * intensity).round(),
          speed: 44 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(13),
          citadelDamage: 1,
          color: const Color(0xFFC8C1AF),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.graveGuard:
        return EnemyDefinition(
          kind: kind,
          label: 'Grave Guard',
          specialDescription:
              'Resists slows and pushes through control effects.',
          hitPoints: (224 * hpMultiplier * (intensity + 0.08)).round(),
          speed: 26 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(20),
          citadelDamage: 3,
          color: const Color(0xFF63705F),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.plagueBearer:
        return EnemyDefinition(
          kind: kind,
          label: 'Plague Bearer',
          specialDescription:
              'Heals nearby undead and shrouds them in brief damage reduction.',
          hitPoints: (135 * hpMultiplier * intensity).round(),
          speed: 34 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(21),
          citadelDamage: 2,
          color: const Color(0xFF5E7152),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.corruptedKnight:
        return EnemyDefinition(
          kind: kind,
          label: 'Corrupted Knight',
          specialDescription:
              'Charges harder when wounded and resists physical fire.',
          hitPoints: (189 * hpMultiplier * (intensity + 0.15)).round(),
          speed: 30 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(18),
          citadelDamage: 4,
          color: const Color(0xFF7A5151),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.hexSniper:
        return EnemyDefinition(
          kind: kind,
          label: 'Hex Sniper',
          specialDescription:
              'Refreshes a ward for itself and the most important nearby ally.',
          hitPoints: (120 * hpMultiplier * intensity).round(),
          speed: 38 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(25),
          citadelDamage: 2,
          color: const Color(0xFF5C4B73),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.warlock:
        return EnemyDefinition(
          kind: kind,
          label: 'Warlock',
          specialDescription:
              'Wards allies and summons skeleton reinforcements.',
          hitPoints: (127 * hpMultiplier * intensity).round(),
          speed: 33 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(22),
          citadelDamage: 3,
          color: const Color(0xFF5E3E88),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.bastionPriest:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Priest',
          specialDescription:
              'Heals elite allies and restores a ward to keep the line standing.',
          hitPoints: (179 * hpMultiplier * (intensity + 0.06)).round(),
          speed: 28 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(29),
          citadelDamage: 3,
          color: const Color(0xFF8A7A5E),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
        );
      case EnemyKind.bastionOverlord:
        return EnemyDefinition(
          kind: kind,
          label: 'Bastion Overlord',
          specialDescription:
              'Final boss that phases, wards itself, and summons defenders.',
          hitPoints: (1430 * hpMultiplier * math.max(1.0, intensity)).round(),
          speed: 24 * moveSpeedMultiplier,
          rewardCoins: scaledKillReward(180, minimumIntensity: 1.0),
          citadelDamage: 10,
          color: const Color(0xFF8C3F34),
          structureDamage: structureDamage,
          towerContactDamage: towerContactDamage,
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

  static List<StageDecorationDefinition> _fortressDecorationsForStage(
    int stage,
    List<int> citadelCell,
    StageEnvironmentTheme theme,
  ) {
    final citadelCenter = Offset(
      (citadelCell[0] + 0.5) / 14,
      (citadelCell[1] + 0.5) / 14,
    );
    final decorations = [
      ..._decorationsForStage(stage, theme),
      ..._edgeSetDressingForTheme(theme),
    ];
    final selected = <StageDecorationDefinition>[];
    final usedSlots = <String>{};
    final usedFootprintCells = {...stageCitadelFootprintCells(citadelCell)};

    for (final decoration in decorations) {
      if (!_keepsCitadelReadable(decoration, citadelCenter, stage)) {
        continue;
      }
      final slotKey =
          '${decoration.assetPath}:${decoration.position.dx.toStringAsFixed(2)}:'
          '${decoration.position.dy.toStringAsFixed(2)}';
      if (!usedSlots.add(slotKey)) {
        continue;
      }
      final footprint = stageDecorationFootprintCells(decoration);
      if (footprint.any(usedFootprintCells.contains)) {
        continue;
      }
      usedFootprintCells.addAll(footprint);
      selected.add(decoration);
      if (selected.length >= 6) {
        break;
      }
    }

    return selected;
  }

  static bool _keepsCitadelReadable(
    StageDecorationDefinition decoration,
    Offset citadelCenter,
    int stageNumber,
  ) {
    final dx = decoration.position.dx - citadelCenter.dx;
    final dy = decoration.position.dy - citadelCenter.dy;
    final isLandmark = decoration.assetPath.contains('/landmarks/');
    final nearEdge =
        citadelCenter.dx < 0.25 ||
        citadelCenter.dx > 0.75 ||
        citadelCenter.dy < 0.25 ||
        citadelCenter.dy > 0.75;
    var minDistance = isLandmark ? 0.25 : 0.19;
    if (stageNumber <= 5 && nearEdge) {
      minDistance += isLandmark ? 0.08 : 0.04;
    }
    return dx * dx + dy * dy >= minDistance * minDistance;
  }

  static List<StageDecorationDefinition> _edgeSetDressingForTheme(
    StageEnvironmentTheme theme,
  ) {
    switch (theme) {
      case StageEnvironmentTheme.frontierRoad:
        return [
          _dec(
            'assets/sprites/environment/landmarks/village_gate.png',
            0.52,
            0.08,
            scale: 1.16,
            opacity: 0.86,
          ),
          _dec(
            'assets/sprites/environment/props/supply_crate.png',
            0.91,
            0.58,
            scale: 0.82,
            opacity: 0.88,
          ),
        ];
      case StageEnvironmentTheme.banditCrossroads:
        return [
          _dec(
            'assets/sprites/environment/landmarks/bandit_stockade.png',
            0.53,
            0.08,
            scale: 1.14,
            opacity: 0.86,
          ),
          _dec(
            'assets/sprites/environment/props/broken_barrel.png',
            0.91,
            0.58,
            scale: 0.9,
            opacity: 0.88,
          ),
        ];
      case StageEnvironmentTheme.graveFields:
        return [
          _dec(
            'assets/sprites/environment/landmarks/mausoleum_gate.png',
            0.53,
            0.08,
            scale: 1.14,
            opacity: 0.84,
          ),
          _dec(
            'assets/sprites/environment/props/bone_pile.png',
            0.91,
            0.58,
            scale: 0.86,
            opacity: 0.86,
          ),
        ];
      case StageEnvironmentTheme.cursedChapel:
        return [
          _dec(
            'assets/sprites/environment/landmarks/cursed_chapel_front.png',
            0.53,
            0.08,
            scale: 1.12,
            opacity: 0.84,
          ),
          _dec(
            'assets/sprites/environment/props/candle_cluster.png',
            0.91,
            0.58,
            scale: 0.86,
            opacity: 0.86,
          ),
        ];
      case StageEnvironmentTheme.bastionApproach:
        return [
          _dec(
            'assets/sprites/environment/landmarks/bastion_wall_chunk.png',
            0.53,
            0.08,
            scale: 1.16,
            opacity: 0.84,
          ),
          _dec(
            'assets/sprites/environment/props/chain_post.png',
            0.91,
            0.58,
            scale: 0.92,
            opacity: 0.86,
          ),
        ];
      case StageEnvironmentTheme.throneMarch:
        return [
          _dec(
            'assets/sprites/environment/landmarks/throne_road_monument.png',
            0.53,
            0.08,
            scale: 1.12,
            opacity: 0.84,
          ),
          _dec(
            'assets/sprites/environment/props/siege_crate.png',
            0.91,
            0.58,
            scale: 0.88,
            opacity: 0.86,
          ),
        ];
    }
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

  static List<Offset> _normalizedBuildSlots(
    List<List<TileType>> tileGrid, {
    Set<(int, int)> blockedCells = const {},
  }) {
    final rowCount = tileGrid.length;
    final columnCount = tileGrid.isEmpty ? 0 : tileGrid.first.length;
    final slots = <Offset>[];
    for (var row = 0; row < tileGrid.length; row += 1) {
      for (var col = 0; col < tileGrid[row].length; col += 1) {
        if (tileGrid[row][col] != TileType.buildable) {
          continue;
        }
        if (blockedCells.contains((col, row))) {
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
    if (stageNumber < 1 || stageNumber > totalStages) {
      return null;
    }

    final citadelCell = _fortressCitadelCellForStage(stageNumber);
    final spawnRoutes = _fortressSpawnRoutes();
    final pathsByDirection = _fortressRepresentativePaths(citadelCell);
    for (final entry in pathsByDirection.entries) {
      _validateSiegeRoute(
        route: entry.value,
        direction: entry.key,
        columns: 14,
        rows: 14,
        citadelCell: citadelCell,
      );
    }

    final primaryFront = _primaryFrontForStage(stageNumber);
    final primaryRoute = pathsByDirection[primaryFront]!;
    final legacyPathSequence = _legacyPathSequenceForSiege(
      primaryRoute,
      citadelCell: citadelCell,
    );
    final tileGrid = _buildCitadelTileGrid(
      columns: 14,
      rows: 14,
      citadelCell: citadelCell,
    );
    final assaultCycles = _fortressAssaultCycles(
      stageNumber,
      citadelCell,
      _buildAuthoredCitadelAssaultCycles(stageNumber),
    );
    final baseHealth = _baseHealthForStage(stageNumber);
    final environmentTheme = _environmentThemeForStage(stageNumber);
    final decorationCandidates = _fortressDecorationsForStage(
      stageNumber,
      citadelCell,
      environmentTheme,
    );
    final obstacles = _fortressObstaclesForStage(
      stageNumber,
      decorationCandidates,
      citadelCell,
    );
    final obstacleAssetPaths = {
      for (final obstacle in obstacles) obstacle.assetPath,
    };
    final decorations = decorationCandidates
        .where(
          (decoration) => !obstacleAssetPaths.contains(decoration.assetPath),
        )
        .toList(growable: false);
    final decorationBlockedCells = {
      ...stageCitadelBuildBlockedCells(citadelCell),
      for (final obstacle in obstacles)
        for (final cell in obstacle.occupiedCells)
          if (cell.length >= 2) (cell[0], cell[1]),
      for (final decoration in decorations)
        ...stageDecorationFootprintCells(decoration),
    };

    return StageDefinition(
      number: stageNumber,
      actNumber: ((stageNumber - 1) ~/ 5) + 1,
      title: _authoredCitadelTitle(stageNumber),
      description: _authoredCitadelDescription(stageNumber),
      startingCoins: _startingCoinsForStage(stageNumber),
      baseHealth: baseHealth,
      citadelHp: baseHealth,
      citadelCell: citadelCell,
      environmentTheme: environmentTheme,
      pathNodes: _normalizedPathNodes(
        legacyPathSequence,
        columns: 14,
        rows: 14,
      ),
      buildSlots: _normalizedBuildSlots(
        tileGrid,
        blockedCells: decorationBlockedCells,
      ),
      buildZones: const [
        StageBuildZoneDefinition(region: Rect.fromLTWH(0, 0, 1080, 1920)),
      ],
      pathClearance: 45.0,
      buildGridSpacing: 12.0,
      decorations: decorations,
      objectives: _authoredCitadelObjectives(stageNumber),
      unlockRequirements: _unlockRequirementsForStage(stageNumber),
      tileGrid: tileGrid,
      pathSequence: legacyPathSequence,
      pathsByDirection: pathsByDirection,
      obstacles: obstacles,
      supplyNodeCells: const [],
      assaultCycles: assaultCycles,
      spawnRoutes: spawnRoutes,
      initialBarrierOptions: const [],
      stageEvents: _stageEventsForStage(stageNumber),
      bombardment: _bombardmentForStage(stageNumber, assaultCycles.length),
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
                  routeId: group.routeId,
                ),
            ],
          ),
      ],
    );
  }

  static List<StageObstacleDefinition> _fortressObstaclesForStage(
    int stageNumber,
    List<StageDecorationDefinition> decorations,
    List<int> citadelCell,
  ) {
    final usedCells = {...stageCitadelFootprintCells(citadelCell)};
    final obstacles = <StageObstacleDefinition>[];
    for (final decoration in decorations) {
      if (!_shouldPromoteDecorationToObstacle(decoration)) {
        continue;
      }
      final footprint = _obstacleFootprintForDecoration(decoration);
      if (footprint.isEmpty || footprint.any(usedCells.contains)) {
        continue;
      }
      usedCells.addAll(footprint);
      obstacles.add(
        StageObstacleDefinition(
          assetPath: decoration.assetPath,
          occupiedCells: [
            for (final cell in footprint) [cell.$1, cell.$2],
          ],
          scale: decoration.scale,
          opacity: decoration.opacity,
        ),
      );
      if (obstacles.length >= (stageNumber <= 5 ? 1 : 2)) {
        break;
      }
    }
    return obstacles;
  }

  static bool _shouldPromoteDecorationToObstacle(
    StageDecorationDefinition decoration,
  ) {
    return decoration.assetPath.contains('/landmarks/') ||
        decoration.assetPath.contains('wagon_wreck') ||
        decoration.assetPath.contains('fort_wall_breach') ||
        decoration.assetPath.contains('gate_ruin') ||
        decoration.assetPath.contains('chapel_rubble');
  }

  static Set<(int, int)> _obstacleFootprintForDecoration(
    StageDecorationDefinition decoration,
  ) {
    final centerCol = (decoration.position.dx * 14)
        .floor()
        .clamp(0, 13)
        .toInt();
    final centerRow = (decoration.position.dy * 14)
        .floor()
        .clamp(0, 13)
        .toInt();
    final isLandmark = decoration.assetPath.contains('/landmarks/');
    final spanCols = isLandmark ? 2 : 1;
    final spanRows = isLandmark ? 3 : 1;
    final startCol = (centerCol - ((spanCols - 1) ~/ 2)).clamp(0, 13).toInt();
    final startRow = (centerRow - ((spanRows - 1) ~/ 2)).clamp(0, 13).toInt();
    return {
      for (var row = startRow; row < startRow + spanRows && row < 14; row += 1)
        for (
          var col = startCol;
          col < startCol + spanCols && col < 14;
          col += 1
        )
          (col, row),
    };
  }

  static List<StageEventDefinition> _stageEventsForStage(int stageNumber) {
    if (!StageEventGenerator.usesStageEventDice(stageNumber)) {
      return const [];
    }
    return StageEventGenerator.poolForStage(stageNumber);
  }

  static StageBombardmentDefinition? _bombardmentForStage(
    int stageNumber,
    int waveCount,
  ) {
    if (stageNumber < 2 || waveCount < 3) {
      return null;
    }
    final targetWaveNumber =
        waveCount >= 4 && math.Random(stageNumber * 9151).nextBool() ? 4 : 3;
    final chance = (0.22 + (stageNumber * 0.008)).clamp(0.24, 0.48);
    return StageBombardmentDefinition(
      id: 'stage_${stageNumber}_bombardment',
      targetWaveNumber: targetWaveNumber,
      rollChance: chance.toDouble(),
      damage: 54 + (stageNumber * 4),
      radiusTiles: 1.05,
      warningSeconds: 1.05,
    );
  }

  static List<int> _fortressCitadelCellForStage(int stageNumber) {
    const cells = {
      1: [1, 12],
      2: [1, 12],
      3: [1, 12],
      4: [1, 12],
      5: [1, 12],
      6: [12, 12],
      7: [11, 12],
      8: [11, 11],
      9: [10, 10],
      10: [9, 9],
      11: [12, 1],
      12: [12, 2],
      13: [11, 2],
      14: [10, 3],
      15: [9, 4],
      16: [1, 1],
      17: [2, 1],
      18: [2, 2],
      19: [3, 3],
      20: [4, 4],
      21: [6, 6],
      22: [7, 6],
      23: [6, 7],
      24: [7, 7],
      25: [6, 6],
      26: [6, 6],
      27: [7, 6],
      28: [6, 7],
      29: [7, 7],
      30: [6, 6],
    };
    return cells[stageNumber] ?? const [6, 6];
  }

  static SpawnDirection _primaryFrontForStage(int stageNumber) {
    if (stageNumber <= 5) return SpawnDirection.north;
    if (stageNumber <= 10) return SpawnDirection.north;
    if (stageNumber <= 15) return SpawnDirection.south;
    if (stageNumber <= 20) return SpawnDirection.south;
    return SpawnDirection.north;
  }

  static List<SpawnRouteDefinition> _fortressSpawnRoutes() {
    const entries = <(SpawnDirection, List<List<int>>)>[
      (
        SpawnDirection.north,
        [
          [3, 0],
          [6, 0],
          [10, 0],
        ],
      ),
      (
        SpawnDirection.south,
        [
          [3, 13],
          [6, 13],
          [10, 13],
        ],
      ),
      (
        SpawnDirection.west,
        [
          [0, 3],
          [0, 6],
          [0, 10],
        ],
      ),
      (
        SpawnDirection.east,
        [
          [13, 3],
          [13, 6],
          [13, 10],
        ],
      ),
    ];
    return [
      for (final entry in entries)
        for (var index = 0; index < entry.$2.length; index += 1)
          SpawnRouteDefinition(
            id: '${entry.$1.name}_${index + 1}',
            direction: entry.$1,
            routeIndex: index,
            entryCell: entry.$2[index],
          ),
    ];
  }

  static List<int> _entryCellForRoute(
    SpawnDirection direction,
    int routeIndex,
  ) {
    const entries = {
      SpawnDirection.north: [
        [3, 0],
        [6, 0],
        [10, 0],
      ],
      SpawnDirection.south: [
        [3, 13],
        [6, 13],
        [10, 13],
      ],
      SpawnDirection.west: [
        [0, 3],
        [0, 6],
        [0, 10],
      ],
      SpawnDirection.east: [
        [13, 3],
        [13, 6],
        [13, 10],
      ],
    };
    final directionEntries = entries[direction]!;
    final index = (routeIndex - 1).clamp(0, directionEntries.length - 1);
    return directionEntries[index];
  }

  static Map<SpawnDirection, List<List<int>>> _fortressRepresentativePaths(
    List<int> citadelCell,
  ) {
    return {
      for (final direction in SpawnDirection.values)
        direction: _routeFromEdgeToCitadelRing(
          _middleEntryForDirection(direction),
          direction,
          citadelCell,
        ),
    };
  }

  static List<int> _middleEntryForDirection(SpawnDirection direction) {
    return switch (direction) {
      SpawnDirection.north => const [6, 0],
      SpawnDirection.south => const [6, 13],
      SpawnDirection.west => const [0, 6],
      SpawnDirection.east => const [13, 6],
    };
  }

  static List<List<int>> _routeFromEdgeToCitadelRing(
    List<int> entry,
    SpawnDirection direction,
    List<int> citadelCell,
  ) {
    final goal = switch (direction) {
      SpawnDirection.north => [citadelCell[0], math.max(0, citadelCell[1] - 1)],
      SpawnDirection.south => [
        citadelCell[0],
        math.min(13, citadelCell[1] + 1),
      ],
      SpawnDirection.west => [math.max(0, citadelCell[0] - 1), citadelCell[1]],
      SpawnDirection.east => [math.min(13, citadelCell[0] + 1), citadelCell[1]],
    };
    final route = <List<int>>[];
    var col = entry[0];
    var row = entry[1];
    route.add([col, row]);

    void stepCol() {
      if (col < goal[0]) {
        col += 1;
      } else if (col > goal[0]) {
        col -= 1;
      }
      route.add([col, row]);
    }

    void stepRow() {
      if (row < goal[1]) {
        row += 1;
      } else if (row > goal[1]) {
        row -= 1;
      }
      route.add([col, row]);
    }

    if (direction == SpawnDirection.north ||
        direction == SpawnDirection.south) {
      while (row != goal[1]) {
        stepRow();
      }
      while (col != goal[0]) {
        stepCol();
      }
    } else {
      while (col != goal[0]) {
        stepCol();
      }
      while (row != goal[1]) {
        stepRow();
      }
    }
    return route;
  }

  static List<StageObjectiveDefinition> _authoredCitadelObjectives(
    int stageNumber,
  ) {
    final keepThreshold = stageNumber <= 5 ? 2 : 1;

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

  static List<AssaultCycleDefinition> _fortressAssaultCycles(
    int stageNumber,
    List<int> citadelCell,
    List<AssaultCycleDefinition> source,
  ) {
    final activeRouteIds = _routeIdsForStage(stageNumber, citadelCell);
    if (stageNumber <= 5) {
      return [
        for (final cycle in _earlyFortressAssaultCycles(stageNumber))
          AssaultCycleDefinition(
            number: cycle.number,
            activeFronts: cycle.activeFronts,
            groups: cycle.groups,
            recoverySeconds: cycle.recoverySeconds,
            recoveryGoldBonus: _recoveryGoldBonusForStage(
              stageNumber,
              cycle.number,
            ),
            isFinalBreach: cycle.isFinalBreach,
            activeRouteIds: activeRouteIds,
            variants: cycle.variants,
          ),
      ];
    }
    return [
      for (final cycle in source)
        AssaultCycleDefinition(
          number: cycle.number,
          activeFronts: _frontsForFortressCycle(stageNumber, cycle.number),
          groups: cycle.groups
              .where(
                (group) => _frontsForFortressCycle(
                  stageNumber,
                  cycle.number,
                ).contains(group.front),
              )
              .toList(growable: false),
          recoverySeconds: cycle.recoverySeconds,
          recoveryGoldBonus: _recoveryGoldBonusForStage(
            stageNumber,
            cycle.number,
          ),
          isFinalBreach: cycle.isFinalBreach,
          activeRouteIds: activeRouteIds,
          variants: cycle.variants,
        ),
    ];
  }

  static List<AssaultCycleDefinition> _earlyFortressAssaultCycles(
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

    WaveVariantDefinition variant(
      String id,
      String label,
      List<String> tags,
      List<FrontSpawnGroupDefinition> groups,
    ) {
      return WaveVariantDefinition(
        id: id,
        label: label,
        threatTags: tags,
        groups: groups,
      );
    }

    final northOnly = const [SpawnDirection.north];
    final northEast = const [SpawnDirection.north, SpawnDirection.east];

    switch (stageNumber) {
      case 1:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: northOnly,
            recoveryGoldBonus: 40,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.86),
              spawn(SpawnDirection.north, EnemyKind.scout, 3, interval: 0.78),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: northOnly,
            recoveryGoldBonus: 45,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.82),
              spawn(SpawnDirection.north, EnemyKind.scout, 4, interval: 0.76),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: northOnly,
            recoveryGoldBonus: 50,
            isFinalBreach: true,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.8),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.34,
              ),
              spawn(SpawnDirection.north, EnemyKind.scout, 4, interval: 0.74),
            ],
          ),
        ];
      case 2:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: northOnly,
            recoveryGoldBonus: 40,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.82),
              spawn(SpawnDirection.north, EnemyKind.scout, 4, interval: 0.74),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: northEast,
            recoveryGoldBonus: 45,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.82),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                4,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.cultAdept,
                1,
                interval: 1.55,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: northEast,
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                5,
                interval: 0.72,
              ),
              spawn(SpawnDirection.east, EnemyKind.cultAdept, 2, interval: 1.5),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: northEast,
            recoveryGoldBonus: 54,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.22,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                6,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.cultAdept,
                2,
                interval: 1.48,
              ),
            ],
          ),
        ];
      case 3:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: northOnly,
            recoveryGoldBonus: 45,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 5, interval: 0.82),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                4,
                interval: 0.95,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.25,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: northEast,
            recoveryGoldBonus: 50,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                6,
                interval: 0.92,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                4,
                interval: 0.86,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                4,
                interval: 0.72,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: northEast,
            recoveryGoldBonus: 55,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.skeleton, 6, interval: 0.9),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                5,
                interval: 0.84,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.18,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: northEast,
            recoveryGoldBonus: 60,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                4,
                interval: 1.15,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                5,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                5,
                interval: 0.72,
              ),
            ],
          ),
        ];
      case 4:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: northEast,
            recoveryGoldBonus: 45,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                5,
                interval: 0.72,
              ),
              spawn(SpawnDirection.north, EnemyKind.skeleton, 4, interval: 0.9),
            ],
            variants: [
              variant(
                'fast',
                '빠른 압박',
                ['빠른 압박'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.scout,
                    6,
                    interval: 0.72,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.wolfScout,
                    6,
                    interval: 0.72,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.raider,
                    4,
                    interval: 0.82,
                  ),
                ],
              ),
              variant(
                'breaker',
                '성벽 파괴',
                ['성벽 파괴'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.shieldInfantry,
                    4,
                    interval: 1.18,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.raider,
                    6,
                    interval: 0.82,
                  ),
                ],
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: northEast,
            recoveryGoldBonus: 50,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                7,
                interval: 0.88,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                5,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.cultAdept,
                2,
                interval: 1.45,
              ),
            ],
            variants: [
              variant(
                'support',
                '지원몹',
                ['지원몹'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.cultAdept,
                    3,
                    interval: 1.4,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.boneArcher,
                    6,
                    interval: 0.82,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.skeleton,
                    5,
                    interval: 0.88,
                  ),
                ],
              ),
              variant(
                'mixed',
                '혼합 압박',
                ['빠른 압박', '혼합 압박'],
                [
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.wolfScout,
                    6,
                    interval: 0.72,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.raider,
                    7,
                    interval: 0.8,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.skeleton,
                    4,
                    interval: 0.9,
                  ),
                ],
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: northEast,
            recoveryGoldBonus: 55,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                2,
                interval: 1.6,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                6,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.15,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: northEast,
            recoveryGoldBonus: 60,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                3,
                interval: 1.55,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                6,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.cultAdept,
                2,
                interval: 1.42,
              ),
            ],
          ),
        ];
      case 5:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: northOnly,
            recoveryGoldBonus: 50,
            groups: [
              spawn(SpawnDirection.north, EnemyKind.raider, 6, interval: 0.8),
              spawn(SpawnDirection.north, EnemyKind.scout, 5, interval: 0.72),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                5,
                interval: 0.88,
              ),
            ],
            variants: [
              variant(
                'fast',
                '빠른 압박',
                ['빠른 압박'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.scout,
                    7,
                    interval: 0.72,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.wolfScout,
                    6,
                    interval: 0.72,
                  ),
                ],
              ),
              variant(
                'breakers',
                '성벽 파괴',
                ['성벽 파괴'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.shieldInfantry,
                    4,
                    interval: 1.16,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.raider,
                    6,
                    interval: 0.8,
                  ),
                ],
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: northEast,
            recoveryGoldBonus: 55,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                6,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                6,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.cultAdept,
                2,
                interval: 1.42,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: northEast,
            recoveryGoldBonus: 60,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                2,
                interval: 1.55,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                6,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                6,
                interval: 0.88,
              ),
            ],
            variants: [
              variant(
                'support',
                '지원몹',
                ['지원몹', '혼합 압박'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.cultAdept,
                    3,
                    interval: 1.38,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.boneArcher,
                    7,
                    interval: 0.82,
                  ),
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.raider,
                    6,
                    interval: 0.8,
                  ),
                ],
              ),
              variant(
                'heavy',
                '성벽 파괴',
                ['성벽 파괴'],
                [
                  spawn(
                    SpawnDirection.north,
                    EnemyKind.graveGuard,
                    3,
                    interval: 1.5,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.shieldInfantry,
                    4,
                    interval: 1.12,
                  ),
                  spawn(
                    SpawnDirection.east,
                    EnemyKind.wolfScout,
                    4,
                    interval: 0.72,
                  ),
                ],
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: northEast,
            recoveryGoldBonus: 65,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                3,
                interval: 1.45,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.shieldInfantry,
                4,
                interval: 1.08,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.wolfScout,
                7,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.cultAdept,
                2,
                interval: 1.38,
              ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }

  static List<SpawnDirection> _frontsForFortressCycle(
    int stageNumber,
    int cycleNumber,
  ) {
    if (stageNumber <= 5) {
      return switch (stageNumber) {
        1 => const [SpawnDirection.north],
        2 =>
          cycleNumber == 1
              ? const [SpawnDirection.north]
              : const [SpawnDirection.north, SpawnDirection.east],
        3 =>
          cycleNumber == 1
              ? const [SpawnDirection.north]
              : const [SpawnDirection.north, SpawnDirection.east],
        4 => const [SpawnDirection.north, SpawnDirection.east],
        _ =>
          cycleNumber == 1
              ? const [SpawnDirection.north]
              : const [SpawnDirection.north, SpawnDirection.east],
      };
    }
    if (stageNumber <= 10) {
      return cycleNumber <= 2
          ? const [SpawnDirection.north, SpawnDirection.west]
          : const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
            ];
    }
    if (stageNumber <= 15) {
      return cycleNumber <= 2
          ? const [SpawnDirection.south, SpawnDirection.west]
          : const [
              SpawnDirection.south,
              SpawnDirection.west,
              SpawnDirection.east,
            ];
    }
    if (stageNumber <= 20) {
      return cycleNumber <= 2
          ? const [SpawnDirection.south, SpawnDirection.east]
          : const [
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.north,
            ];
    }
    return const [
      SpawnDirection.north,
      SpawnDirection.south,
      SpawnDirection.east,
      SpawnDirection.west,
    ];
  }

  static List<String> _routeIdsForStage(
    int stageNumber,
    List<int> citadelCell,
  ) {
    const routeCount = 3;
    const noSpawnBuffer = 4;
    final routeIds = <String>[];
    for (final direction in SpawnDirection.values) {
      final candidates = [
        for (var index = 1; index <= routeCount; index += 1)
          (
            id: '${direction.name}_$index',
            entry: _entryCellForRoute(direction, index),
          ),
      ];
      final safeCandidates = candidates
          .where((candidate) {
            final distance =
                (candidate.entry[0] - citadelCell[0]).abs() +
                (candidate.entry[1] - citadelCell[1]).abs();
            return distance > noSpawnBuffer;
          })
          .toList(growable: false);
      if (safeCandidates.isNotEmpty) {
        routeIds.addAll(safeCandidates.map((candidate) => candidate.id));
        continue;
      }
      candidates.sort((a, b) {
        final aDistance =
            (a.entry[0] - citadelCell[0]).abs() +
            (a.entry[1] - citadelCell[1]).abs();
        final bDistance =
            (b.entry[0] - citadelCell[0]).abs() +
            (b.entry[1] - citadelCell[1]).abs();
        return bDistance.compareTo(aDistance);
      });
      routeIds.add(candidates.first.id);
    }
    return routeIds;
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
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 54,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.scout,
                4,
                interval: 0.7,
                intensity: 1.10,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.raider,
                4,
                interval: 0.86,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.raider,
                4,
                interval: 0.86,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.scout,
                3,
                interval: 0.82,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                1,
                interval: 1.12,
                intensity: 1.06,
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
      case 11:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 50,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                4,
                interval: 0.86,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 3, interval: 0.78),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.88),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.14,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 55,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.skeleton, 5, interval: 0.84),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                1,
                interval: 1.28,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.76),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 60,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                5,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                2,
                interval: 0.74,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.08,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                1,
                interval: 1.9,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 65,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.skeleton,
                6,
                interval: 0.8,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.22,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                2,
                interval: 0.72,
                intensity: 1.04,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.18,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.82),
            ],
          ),
        ];
      case 12:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 52,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                4,
                interval: 0.84,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.76),
              spawn(SpawnDirection.south, EnemyKind.raider, 3, interval: 0.86),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.1,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 57,
            groups: [
              spawn(SpawnDirection.east, EnemyKind.skeleton, 6, interval: 0.82),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                1,
                interval: 1.24,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                2,
                interval: 0.74,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.82),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 62,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.2,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 5, interval: 0.74),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.04,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                1,
                interval: 1.82,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 67,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.east,
                EnemyKind.skeleton,
                6,
                interval: 0.78,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.18,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                3,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.1,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.8),
            ],
          ),
        ];
      case 13:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 54,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                5,
                interval: 0.82,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 4, interval: 0.74),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.84),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                2,
                interval: 1.08,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 59,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.18,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 6, interval: 0.8),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                2,
                interval: 0.72,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                1,
                interval: 1.78,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 64,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                6,
                interval: 0.78,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 5, interval: 0.72),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 1.0,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                2,
                interval: 1.72,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 69,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.15,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                3,
                interval: 0.7,
                intensity: 1.05,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 0.98,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.05,
              ),
              spawn(SpawnDirection.south, EnemyKind.raider, 5, interval: 0.78),
            ],
          ),
        ];
      case 14:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 56,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                2,
                interval: 0.72,
              ),
              spawn(SpawnDirection.north, EnemyKind.skeleton, 5, interval: 0.8),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 5, interval: 0.8),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.82),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 61,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.14,
              ),
              spawn(SpawnDirection.west, EnemyKind.scout, 5, interval: 0.72),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 0.98,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                2,
                interval: 1.7,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 66,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.wolfScout, 3, interval: 0.7),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.12,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                3,
                interval: 0.96,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.corruptedKnight,
                1,
                interval: 2.35,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 71,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                3,
                interval: 0.68,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                3,
                interval: 1.1,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                4,
                interval: 0.94,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 2.0,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.corruptedKnight,
                1,
                interval: 2.3,
              ),
            ],
          ),
        ];
      case 15:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 60,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.wolfScout, 3, interval: 0.7),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                5,
                interval: 0.78,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 6, interval: 0.78),
              spawn(SpawnDirection.south, EnemyKind.raider, 4, interval: 0.8),
            ],
          ),
          AssaultCycleDefinition(
            number: 2,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 65,
            groups: [
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                3,
                interval: 1.08,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                3,
                interval: 0.68,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                4,
                interval: 0.94,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.cultAdept,
                2,
                interval: 1.65,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 3,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 70,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                4,
                interval: 0.66,
                intensity: 1.06,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                3,
                interval: 1.05,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                4,
                interval: 0.92,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.corruptedKnight,
                1,
                interval: 2.25,
              ),
            ],
          ),
          AssaultCycleDefinition(
            number: 4,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.west,
              SpawnDirection.south,
              SpawnDirection.east,
            ],
            recoveryGoldBonus: 80,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.wolfScout,
                4,
                interval: 0.64,
                intensity: 1.1,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                3,
                interval: 1.02,
                intensity: 1.08,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.shieldInfantry,
                4,
                interval: 0.9,
                intensity: 1.12,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.bannerCaptain,
                1,
                interval: 1.95,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.corruptedKnight,
                2,
                interval: 2.2,
              ),
            ],
          ),
        ];
      case 16:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 72,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                4,
                interval: 0.92,
              ),
              spawn(SpawnDirection.west, EnemyKind.skeleton, 3, interval: 0.96),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.12,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                2,
                interval: 1.10,
              ),
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
            recoveryGoldBonus: 76,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                5,
                interval: 0.88,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.boneArcher,
                3,
                interval: 0.92,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                1,
                interval: 1.52,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 3, interval: 0.9),
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
            recoveryGoldBonus: 80,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.84,
              ),
              spawn(SpawnDirection.west, EnemyKind.skeleton, 4, interval: 0.86),
              spawn(
                SpawnDirection.north,
                EnemyKind.plagueBearer,
                1,
                interval: 2.10,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 3, interval: 0.86),
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
            recoveryGoldBonus: 84,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.graveGuard,
                2,
                interval: 1.38,
              ),
              spawn(SpawnDirection.west, EnemyKind.skeleton, 5, interval: 0.82),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                4,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 2.05,
              ),
            ],
          ),
        ];
      case 17:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 74,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.skeleton, 4, interval: 0.9),
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                4,
                interval: 0.92,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                2,
                interval: 1.08,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 2, interval: 0.94),
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
            recoveryGoldBonus: 78,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.boneArcher,
                4,
                interval: 0.86,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                5,
                interval: 0.88,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                1,
                interval: 1.46,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 3, interval: 0.9),
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
            recoveryGoldBonus: 82,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.skeleton, 5, interval: 0.84),
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.84,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.plagueBearer,
                1,
                interval: 2.00,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                3,
                interval: 0.94,
              ),
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
            recoveryGoldBonus: 86,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.graveGuard,
                2,
                interval: 1.34,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                5,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                4,
                interval: 0.84,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 1.98,
              ),
            ],
          ),
        ];
      case 18:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 76,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.skeleton,
                5,
                interval: 0.88,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.boneArcher,
                3,
                interval: 0.96,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                3,
                interval: 0.92,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 3, interval: 0.92),
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
            recoveryGoldBonus: 80,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.82,
              ),
              spawn(SpawnDirection.west, EnemyKind.skeleton, 4, interval: 0.88),
              spawn(
                SpawnDirection.north,
                EnemyKind.graveGuard,
                1,
                interval: 1.44,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 2.10,
              ),
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
            recoveryGoldBonus: 84,
            groups: [
              spawn(SpawnDirection.south, EnemyKind.skeleton, 6, interval: 0.8),
              spawn(
                SpawnDirection.west,
                EnemyKind.boneArcher,
                4,
                interval: 0.90,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.plagueBearer,
                1,
                interval: 2.02,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 4, interval: 0.86),
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
            recoveryGoldBonus: 88,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.south,
                EnemyKind.graveGuard,
                2,
                interval: 1.28,
              ),
              spawn(
                SpawnDirection.west,
                EnemyKind.boneArcher,
                4,
                interval: 0.86,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                5,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 1.96,
              ),
            ],
          ),
        ];
      case 19:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 78,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.skeleton, 4, interval: 0.9),
              spawn(SpawnDirection.south, EnemyKind.skeleton, 4, interval: 0.9),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                3,
                interval: 0.96,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                3,
                interval: 0.92,
              ),
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
            recoveryGoldBonus: 82,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.graveGuard,
                1,
                interval: 1.44,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.84,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 4, interval: 0.86),
              spawn(
                SpawnDirection.north,
                EnemyKind.plagueBearer,
                1,
                interval: 2.08,
              ),
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
            recoveryGoldBonus: 86,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.skeleton, 5, interval: 0.82),
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.82,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.graveGuard,
                1,
                interval: 1.38,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                4,
                interval: 0.86,
              ),
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
            recoveryGoldBonus: 90,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.graveGuard,
                2,
                interval: 1.30,
              ),
              spawn(SpawnDirection.south, EnemyKind.skeleton, 5, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 1.98,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                4,
                interval: 0.84,
              ),
            ],
          ),
        ];
      case 20:
        return [
          AssaultCycleDefinition(
            number: 1,
            activeFronts: const [
              SpawnDirection.north,
              SpawnDirection.south,
              SpawnDirection.east,
              SpawnDirection.west,
            ],
            recoveryGoldBonus: 80,
            groups: [
              spawn(SpawnDirection.west, EnemyKind.skeleton, 4, interval: 0.88),
              spawn(SpawnDirection.south, EnemyKind.skeleton, 4, interval: 0.9),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                3,
                interval: 0.94,
              ),
              spawn(SpawnDirection.north, EnemyKind.skeleton, 3, interval: 0.9),
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
            recoveryGoldBonus: 84,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.graveGuard,
                1,
                interval: 1.40,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.boneArcher,
                4,
                interval: 0.82,
              ),
              spawn(SpawnDirection.east, EnemyKind.skeleton, 4, interval: 0.84),
              spawn(
                SpawnDirection.north,
                EnemyKind.plagueBearer,
                1,
                interval: 2.02,
              ),
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
            recoveryGoldBonus: 88,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.corruptedKnight,
                1,
                interval: 1.56,
              ),
              spawn(SpawnDirection.south, EnemyKind.skeleton, 5, interval: 0.8),
              spawn(
                SpawnDirection.east,
                EnemyKind.boneArcher,
                4,
                interval: 0.86,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.skeleton,
                4,
                interval: 0.84,
              ),
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
            recoveryGoldBonus: 92,
            isFinalBreach: true,
            groups: [
              spawn(
                SpawnDirection.west,
                EnemyKind.corruptedKnight,
                1,
                interval: 1.42,
                intensity: 1.05,
              ),
              spawn(
                SpawnDirection.south,
                EnemyKind.graveGuard,
                2,
                interval: 1.24,
              ),
              spawn(
                SpawnDirection.east,
                EnemyKind.plagueBearer,
                1,
                interval: 1.94,
              ),
              spawn(
                SpawnDirection.north,
                EnemyKind.boneArcher,
                4,
                interval: 0.82,
              ),
            ],
          ),
        ];
      default:
        if (stageNumber <= 10) {
          return [
            AssaultCycleDefinition(
              number: 1,
              activeFronts: const [SpawnDirection.north, SpawnDirection.west],
              groups: [
                spawn(
                  SpawnDirection.north,
                  EnemyKind.raider,
                  4,
                  interval: 0.88,
                ),
                spawn(
                  SpawnDirection.west,
                  EnemyKind.wolfScout,
                  3,
                  interval: 0.82,
                ),
              ],
            ),
            AssaultCycleDefinition(
              number: 2,
              activeFronts: const [SpawnDirection.north, SpawnDirection.west],
              groups: [
                spawn(
                  SpawnDirection.north,
                  EnemyKind.raider,
                  4,
                  interval: 0.86,
                ),
                spawn(
                  SpawnDirection.west,
                  EnemyKind.wolfScout,
                  4,
                  interval: 0.80,
                ),
                spawn(
                  SpawnDirection.north,
                  EnemyKind.shieldInfantry,
                  2,
                  interval: 1.16,
                ),
              ],
            ),
            AssaultCycleDefinition(
              number: 3,
              activeFronts: const [
                SpawnDirection.north,
                SpawnDirection.west,
                SpawnDirection.south,
              ],
              groups: [
                spawn(
                  SpawnDirection.north,
                  EnemyKind.raider,
                  5,
                  interval: 0.84,
                ),
                spawn(
                  SpawnDirection.west,
                  EnemyKind.wolfScout,
                  4,
                  interval: 0.78,
                ),
                spawn(
                  SpawnDirection.south,
                  EnemyKind.shieldInfantry,
                  2,
                  interval: 1.12,
                ),
                spawn(
                  SpawnDirection.west,
                  EnemyKind.cultAdept,
                  1,
                  interval: 2.05,
                ),
              ],
            ),
            AssaultCycleDefinition(
              number: 4,
              activeFronts: const [
                SpawnDirection.north,
                SpawnDirection.west,
                SpawnDirection.south,
              ],
              isFinalBreach: true,
              groups: [
                spawn(
                  SpawnDirection.north,
                  EnemyKind.raider,
                  5,
                  interval: 0.82,
                  intensity: 1.06,
                ),
                spawn(
                  SpawnDirection.west,
                  EnemyKind.wolfScout,
                  4,
                  interval: 0.76,
                  intensity: 1.04,
                ),
                spawn(
                  SpawnDirection.south,
                  EnemyKind.shieldInfantry,
                  3,
                  interval: 1.08,
                  intensity: 1.04,
                ),
                spawn(
                  SpawnDirection.south,
                  EnemyKind.bannerCaptain,
                  1,
                  interval: 2.15,
                ),
              ],
            ),
          ];
        }
        final common = stageNumber >= 26
            ? EnemyKind.corruptedKnight
            : stageNumber >= 21
            ? EnemyKind.corruptedKnight
            : stageNumber >= 16
            ? EnemyKind.skeleton
            : EnemyKind.raider;
        final fast = stageNumber >= 26
            ? EnemyKind.hexSniper
            : stageNumber >= 21
            ? EnemyKind.hexSniper
            : stageNumber >= 16
            ? EnemyKind.boneArcher
            : EnemyKind.scout;
        final tank = stageNumber >= 26
            ? EnemyKind.graveGuard
            : stageNumber >= 21
            ? EnemyKind.graveGuard
            : stageNumber >= 16
            ? EnemyKind.graveGuard
            : EnemyKind.shieldInfantry;
        final support = stageNumber >= 26
            ? EnemyKind.bastionPriest
            : stageNumber >= 21
            ? EnemyKind.warlock
            : stageNumber >= 16
            ? EnemyKind.plagueBearer
            : EnemyKind.bannerCaptain;
        final finalSupport = stageNumber >= 30
            ? EnemyKind.bastionOverlord
            : stageNumber >= 26
            ? EnemyKind.warlock
            : support;
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
              spawn(SpawnDirection.north, common, 4, interval: 0.88),
              spawn(SpawnDirection.west, fast, 3, interval: 0.86),
              spawn(SpawnDirection.east, tank, 2, interval: 1.12),
              spawn(SpawnDirection.south, common, 3, interval: 0.9),
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
              spawn(SpawnDirection.north, common, 4, interval: 0.86),
              spawn(SpawnDirection.west, fast, 4, interval: 0.82),
              spawn(SpawnDirection.east, tank, 2, interval: 1.08),
              spawn(SpawnDirection.south, common, 4, interval: 0.86),
              spawn(SpawnDirection.east, support, 1, interval: 2.2),
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
              spawn(SpawnDirection.north, common, 5, interval: 0.84),
              spawn(SpawnDirection.west, fast, 4, interval: 0.8),
              spawn(SpawnDirection.east, tank, 3, interval: 1.06),
              spawn(SpawnDirection.south, common, 4, interval: 0.84),
              spawn(SpawnDirection.south, support, 1, interval: 2.1),
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
                common,
                5,
                interval: 0.82,
                intensity: 1.08,
              ),
              spawn(SpawnDirection.west, fast, 4, interval: 0.78),
              spawn(
                SpawnDirection.east,
                tank,
                3,
                interval: 1.02,
                intensity: 1.08,
              ),
              spawn(SpawnDirection.south, finalSupport, 1, interval: 2.15),
              spawn(SpawnDirection.south, common, 4, interval: 0.84),
            ],
          ),
        ];
    }
  }

  static String _authoredCitadelTitle(int stageNumber) {
    const titles = [
      'Stage 1 - 성벽으로 늦추기',
      'Stage 2 - 타워 사거리 겹치기',
      'Stage 3 - 영웅 방어 위치',
      'Stage 4 - 첫 설계 카드',
      'Stage 5 - 초반 종합 시험',
      'Stage 6 - 우상단 첫 변형',
      'Stage 7 - 동측 성문 압박',
      'Stage 8 - 북동 압박 강화',
      'Stage 9 - 좌측 장거리 우회',
      'Stage 10 - 우상단 미니 보스전',
      'Stage 11 - 좌상단 첫 변형',
      'Stage 12 - 북쪽 성문 압박',
      'Stage 13 - 북서 동시 압박',
      'Stage 14 - 서쪽 긴급 방어',
      'Stage 15 - 좌상단 미니 보스전',
      'Stage 16 - 좌하단 첫 변형',
      'Stage 17 - 남서 보급로 압박',
      'Stage 18 - 하단 후퇴 거점',
      'Stage 19 - 서남 장거리 우회',
      'Stage 20 - 좌하단 성기사 시험',
      'Stage 21 - 우하단 첫 변형',
      'Stage 22 - 동남 관문 방어',
      'Stage 23 - 남쪽 넓은 킬존',
      'Stage 24 - 동측 성 앞 압박',
      'Stage 25 - 우하단 고급 업그레이드',
      'Stage 26 - 중앙 회귀 시험',
      'Stage 27 - 좌상단 재압박',
      'Stage 28 - 우상단 재압박',
      'Stage 29 - 좌하단 재압박',
      'Stage 30 - 최종 사방 공성전',
    ];
    if (stageNumber >= 1 && stageNumber <= titles.length) {
      return titles[stageNumber - 1];
    }
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
      11 => 'Stage 11 - 좌상단 첫 변형',
      12 => 'Stage 12 - 북쪽 성문 압박',
      13 => 'Stage 13 - 북서 동시 압박',
      14 => 'Stage 14 - 서쪽 긴급 방어',
      15 => 'Stage 15 - 좌상단 미니 보스형',
      _ => 'Stage $stageNumber',
    };
  }

  static String _authoredCitadelDescription(int stageNumber) {
    const descriptions = [
      '북쪽 적을 성벽으로 늦추고 궁수 사거리 안으로 끌어오는 첫 설계 퍼즐입니다.',
      '북쪽과 동쪽 압박을 한 킬존에 묶어 타워 사거리를 겹치는 법을 배웁니다.',
      '영웅 방어 위치를 성벽 뒤 교차로에 두고 소량의 장갑 적을 붙잡는 Stage입니다.',
      '첫 설계 카드가 열립니다. 선택한 작전에 맞춰 같은 맵의 방어망을 다르게 짜보세요.',
      '성벽, 타워 조합, 영웅 방어 위치를 모두 쓰는 초반 종합 시험입니다.',
      '성이 우상단으로 이동합니다. 하단 넓은 공간을 쓰고 북동 압박을 막으세요.',
      '성이 조금 더 오른쪽에 놓입니다. 동쪽 짧은 압박과 남쪽 우회를 동시에 봅니다.',
      '성이 북동쪽으로 올라갑니다. 북쪽과 동쪽 접근이 빨라져 선제 배치가 중요합니다.',
      '성이 오른쪽으로 더 밀립니다. 좌측 긴 우회와 동쪽 짧은 압박을 나눠 처리하세요.',
      '우상단 미니 보스형 Stage입니다. 세 방향 동시 압박과 짧은 성 앞 전투를 견디세요.',
      '성이 좌상단으로 이동합니다. 서쪽과 북쪽 긴급 압박을 막고 오른쪽 넓은 사선을 쓰세요.',
      '성이 북쪽으로 더 올라갑니다. 북쪽 성문 압박을 빠르게 막고 남동쪽 우회를 활용하세요.',
      '북쪽과 서쪽 압박이 동시에 빨라집니다. 아래쪽 후퇴 거점과 오른쪽 사선을 함께 쓰세요.',
      '성이 왼쪽 깊숙이 이동합니다. 서쪽 긴급 방어와 동쪽 장거리 물량을 동시에 처리하세요.',
      '좌상단 미니 보스형 Stage입니다. 북서쪽 짧은 압박과 남동쪽 물량을 모두 견디세요.',
      '성이 좌하단으로 내려갑니다. 아래쪽 짧은 압박과 북쪽 긴 사선을 처음으로 함께 다룹니다.',
      '남서 보급로가 흔들립니다. 남쪽 압박을 빠르게 정리하고 서쪽 방어를 보강하세요.',
      '하단 후퇴 거점이 핵심입니다. 성 앞 좁은 공간이 무너지기 전에 위쪽 사선을 만드세요.',
      '서남쪽 장거리 우회가 강해집니다. 서쪽에만 몰아짓지 말고 북동쪽 화력도 준비하세요.',
      '좌하단 구간의 정점입니다. 성기사 해금 이후의 방어 유지력을 시험합니다.',
      '성이 우하단으로 이동합니다. 동쪽 짧은 압박과 남쪽 성문 압박이 동시에 강해집니다.',
      '동남 관문 방어 Stage입니다. 오른쪽 전선을 늦추고 북서쪽 장거리 사선을 확보하세요.',
      '남쪽 넓은 킬존을 쓰는 Stage입니다. 빠른 적이 성 아래를 통과하기 전에 끊어내세요.',
      '동쪽 성 앞 압박이 가장 짧아집니다. 긴급 대응 타워와 영웅 이동 판단이 중요합니다.',
      '우하단 구간의 정점입니다. 고급 영웅 업그레이드와 경제 판단을 함께 시험합니다.',
      '성이 중앙으로 잠시 돌아오지만 적 조합은 후반형입니다. 네 전선을 모두 균형 있게 막으세요.',
      '좌상단 재압박입니다. 이전 좌상단 경험에 후반 지원 적이 섞여 들어옵니다.',
      '우상단 재압박입니다. 짧은 동쪽 압박과 강한 지원 적을 빠르게 제거하세요.',
      '좌하단 재압박입니다. 남쪽과 서쪽에서 성이 빠르게 노출됩니다.',
      '최종 사방 공성전입니다. 모든 전선과 보스 압박을 동시에 견디는 마지막 시험입니다.',
    ];
    if (stageNumber >= 1 && stageNumber <= descriptions.length) {
      return descriptions[stageNumber - 1];
    }
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
      11 => '성이 왼쪽 위로 이동합니다. 서쪽과 북쪽 긴급 압박을 막고 오른쪽 넓은 킬존을 활용하세요.',
      12 => '성이 북쪽으로 더 올라갑니다. 북쪽 성문 압박을 빠르게 막고 남동쪽 우회를 활용하세요.',
      13 => '북쪽과 서쪽 압박이 동시에 빨라집니다. 아래쪽 후퇴 거점과 오른쪽 킬존을 나눠 지키세요.',
      14 => '성이 왼쪽 깊숙이 이동합니다. 서쪽 긴급 방어와 동쪽 장거리 물량을 동시에 처리하세요.',
      15 => '좌상단 미니 보스형 Stage입니다. 북서쪽 짧은 압박과 남동쪽 물량을 모두 견디세요.',
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

    return grid;
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
