// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:math' as math;

import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export difficulty audit', () {
    final buffer = StringBuffer()
      ..writeln('# Difficulty Audit')
      ..writeln()
      ..writeln(
        'Generated from current Dart definitions. Rerun '
        '`flutter test tool/export_difficulty_audit.dart` after balance changes.',
      )
      ..writeln()
      ..writeln('## Scale')
      ..writeln()
      ..writeln(
        '- Wave pressure uses the same formula as '
        '`current-game-data-snapshot.md`: HP 60%, wall damage 25%, '
        'tower contact damage 15%.',
      )
      ..writeln(
        '- Stage score is the rounded average of its wave pressure values.',
      )
      ..writeln(
        '- Peak is the highest wave pressure in the Stage, usually the final '
        'wave.',
      )
      ..writeln(
        '- Ramp is the percentage increase from Wave 1 to the peak wave.',
      )
      ..writeln(
        '- Event boss HP ratio compares boss HP to that Stage peak pressure. '
        'It is a rough tuning signal, not a combat simulation.',
      )
      ..writeln()
      ..writeln('## Stage And Wave Difficulty')
      ..writeln()
      ..writeln(
        '| Stage | Gold | W1 | W2 | W3 | W4 | Stage Score | Peak | Ramp | Flags |',
      )
      ..writeln(
        '| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |',
      );

    final stagePeaks = <int, int>{};
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final pressures = [
        for (final cycle in stage.assaultCycles)
          _pressureIndex(cycle.groups).round(),
      ];
      final stageScore =
          pressures.reduce((total, value) => total + value) / pressures.length;
      final peak = pressures.reduce(math.max);
      stagePeaks[stageNumber] = peak;
      final ramp = ((peak - pressures.first) / pressures.first * 100).round();
      final flags = [
        if (stage.stageEvents.isNotEmpty) 'event boss',
        if (stage.bombardment != null) 'bombardment',
        if (_hasFourFronts(stage)) '4 fronts',
        if (_hasNormalBoss(stage)) 'normal boss',
      ].join(', ');
      buffer.writeln(
        '| $stageNumber | ${stage.startingCoins} | '
        '${_waveValue(pressures, 0)} | ${_waveValue(pressures, 1)} | '
        '${_waveValue(pressures, 2)} | ${_waveValue(pressures, 3)} | '
        '${stageScore.round()} | $peak | $ramp% | '
        '${flags.isEmpty ? '-' : flags} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Event Boss Stats')
      ..writeln()
      ..writeln(
        '| Stage | Event ID | Boss | Enemy | HP | HP/Peak | Physical Taken | '
        'Wall | Shockwave | Tower Contact | HP Mult | Damage Mult | Scale |',
      )
      ..writeln(
        '| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | '
        '---: | ---: | ---: |',
      );

    for (final stageNumber in [4, 7, 10, 13, 16, 19, 22, 25, 28]) {
      final game = _debugGame(stageNumber);
      final peak = stagePeaks[stageNumber]!;
      for (final event in StageEventGenerator.poolForStage(stageNumber)) {
        final boss = game.debugStageEventEnemyDefinition(event);
        final physical = game.debugPhysicalDamageMultiplierForEnemyKind(
          boss.kind,
          stageEvent: true,
        );
        final shockwave = (boss.baseStructureDamage * 0.42).toStringAsFixed(1);
        final hpRatio = (boss.hitPoints / peak).toStringAsFixed(1);
        buffer.writeln(
          '| $stageNumber | `${event.id}` | ${event.title} | '
          '`${boss.kind.name}` | ${boss.hitPoints} | ${hpRatio}x | '
          '${(physical * 100).round()}% | ${boss.baseStructureDamage} | '
          '$shockwave | ${boss.baseTowerContactDamage} | '
          '${event.hitPointMultiplier} | ${event.damageMultiplier} | '
          '${event.visualScale} |',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Normal Boss Appearances')
      ..writeln()
      ..writeln(
        '| Stage | Wave | Boss | Count | HP Each | Physical Taken | Wall | '
        'Shockwave | Tower Contact |',
      )
      ..writeln(
        '| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |',
      );

    var normalBossRows = 0;
    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final game = _debugGame(stageNumber);
      for (final cycle in stage.assaultCycles) {
        for (final group in cycle.groups) {
          if (group.enemy.kind != EnemyKind.bastionOverlord) {
            continue;
          }
          normalBossRows += 1;
          final physical = game.debugPhysicalDamageMultiplierForEnemyKind(
            group.enemy.kind,
          );
          final shockwave = (group.enemy.baseStructureDamage * 0.42)
              .toStringAsFixed(1);
          buffer.writeln(
            '| $stageNumber | ${cycle.number} | `${group.enemy.kind.name}` | '
            '${group.count} | ${group.enemy.hitPoints} | '
            '${(physical * 100).round()}% | '
            '${group.enemy.baseStructureDamage} | $shockwave | '
            '${group.enemy.baseTowerContactDamage} |',
          );
        }
      }
    }
    if (normalBossRows == 0) {
      buffer.writeln('| - | - | - | - | - | - | - | - | - |');
    }

    buffer
      ..writeln()
      ..writeln('## Tuning Notes')
      ..writeln()
      ..writeln(
        '- Stage 1-10 now target about 160% intra-stage ramp, Stage 11-20 '
        'target about 145%, and Stage 21-30 target about 135%.',
      )
      ..writeln(
        '- Event boss HP now starts at 1000 on Stage 4, rises by 285 per '
        'event tier through Stage 10, by 370 per tier through Stage 19, and '
        'by 450 per tier through Stage 28.',
      )
      ..writeln(
        '- Stage 7 and Stage 10 `elite_grave_guard` no longer spike above '
        'other event bosses; their HP now matches the same Stage-based event '
        'boss curve.',
      )
      ..writeln(
        '- Event boss damage keeps low-damage casters/supports mostly intact '
        'and caps high-damage wall breakers so early bosses cannot out-damage '
        'late bosses.',
      )
      ..writeln(
        '- Stage 30 has the only normal `bastionOverlord` in assault cycle '
        'data, with physical resistance still active at 55%.',
      );

    File('docs/generated/difficulty-audit.md')
      ..createSync(recursive: true)
      ..writeAsStringSync(buffer.toString());
  });
}

DefensePrototypeGame _debugGame(int stageNumber) {
  return DefensePrototypeGame(
    stage: CampaignData.stage(stageNumber),
    sessionController: GameSessionController(),
    audioService: GameAudioService(AudioSettingsController()),
    metaUpgrades: const ResolvedMetaUpgrades(),
    chosenHeroKind: HeroKind.knight,
  );
}

double _pressureIndex(List<FrontSpawnGroupDefinition> groups) {
  const baseline = _PressureBudget(389, 96, 104);
  final budget = _pressureBudget(groups);
  return (budget.hitPoints / baseline.hitPoints) * 60 +
      (budget.structureDamage / baseline.structureDamage) * 25 +
      (budget.towerContactDamage / baseline.towerContactDamage) * 15;
}

_PressureBudget _pressureBudget(List<FrontSpawnGroupDefinition> groups) {
  var hitPoints = 0;
  var structureDamage = 0;
  var towerContactDamage = 0;
  for (final group in groups) {
    hitPoints += group.enemy.hitPoints * group.count;
    structureDamage += group.enemy.baseStructureDamage * group.count;
    towerContactDamage += group.enemy.baseTowerContactDamage * group.count;
  }
  return _PressureBudget(hitPoints, structureDamage, towerContactDamage);
}

String _waveValue(List<int> values, int index) {
  return index >= values.length ? '-' : values[index].toString();
}

bool _hasFourFronts(StageDefinition stage) {
  return stage.assaultCycles.any((cycle) => cycle.activeFronts.length >= 4);
}

bool _hasNormalBoss(StageDefinition stage) {
  return stage.assaultCycles.any(
    (cycle) => cycle.groups.any(
      (group) => group.enemy.kind == EnemyKind.bastionOverlord,
    ),
  );
}

class _PressureBudget {
  const _PressureBudget(
    this.hitPoints,
    this.structureDamage,
    this.towerContactDamage,
  );

  final int hitPoints;
  final int structureDamage;
  final int towerContactDamage;
}
