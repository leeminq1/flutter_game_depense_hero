// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:depense_game/data/campaign/campaign_data.dart';
import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_settings_controller.dart';
import 'package:depense_game/game/audio/game_audio_service.dart';
import 'package:depense_game/game/core/depense_game.dart';
import 'package:depense_game/game/core/game_session_controller.dart';
import 'package:depense_game/game/models/enemy_definition.dart';
import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/run_offer_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export current game data docs snapshot', () {
    final buffer = StringBuffer()
      ..writeln('# Current Game Data Snapshot')
      ..writeln()
      ..writeln(
        'Generated from current Dart definitions. Do not hand-edit '
        'numeric tables here; rerun `flutter test tool/export_game_data_docs.dart`.',
      )
      ..writeln()
      ..writeln('## Campaign Stage Atlas')
      ..writeln()
      ..writeln(
        '| Stage | Title | Theme | Citadel | Gold | Waves | Event Dice | Bombardment | Fronts | Main Enemies |',
      )
      ..writeln(
        '| ---: | --- | --- | --- | ---: | ---: | --- | --- | --- | --- |',
      );

    for (
      var stageNumber = 1;
      stageNumber <= CampaignData.totalStages;
      stageNumber += 1
    ) {
      final stage = CampaignData.stage(stageNumber);
      final events = stage.stageEvents.map((event) => event.title).join(', ');
      final bombardment = stage.bombardment == null
          ? '-'
          : 'W${stage.bombardment!.targetWaveNumber} / ${stage.bombardment!.damage} dmg / ${(stage.bombardment!.rollChance * 100).round()}%';
      final fronts = _frontsForStage(stage);
      final enemies = _enemyKindsForStage(
        stage,
      ).map((kind) => kind.name).join(', ');
      buffer.writeln(
        '| $stageNumber | ${_escape(stage.title)} | ${stage.environmentTheme.name} | ${_cell(stage.citadelCell)} | ${stage.startingCoins} | ${stage.cycleCount} | ${events.isEmpty ? '-' : _escape(events)} | ${_escape(bombardment)} | ${_escape(fronts)} | ${_escape(enemies)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Buildables')
      ..writeln()
      ..writeln('### Towers')
      ..writeln()
      ..writeln(
        '| Kind | Label | Cost | Range | Damage | Cooldown | Unlock | Branches |',
      )
      ..writeln('| --- | --- | ---: | ---: | ---: | ---: | --- | --- |');
    for (final tower in TowerCatalog.buildMenu) {
      buffer.writeln(
        '| `${tower.kind.name}` | ${tower.label} | ${tower.cost} | ${tower.range} | ${tower.damage} | ${tower.cooldown} | ${_escape(tower.unlockHint ?? '기본 해금')} | ${_escape(tower.branches.map((b) => '${b.label}(${b.id})').join(', '))} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Barriers')
      ..writeln()
      ..writeln('| Kind | Label | Cost | Base HP | Repair Cost |')
      ..writeln('| --- | --- | ---: | ---: | ---: |');
    for (final barrier in BarrierCatalog.buildMenu) {
      buffer.writeln(
        '| `${barrier.kind.name}` | ${barrier.label} | ${barrier.cost} | ${barrier.hitPoints} | ${barrier.repairCost} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Heroes')
      ..writeln()
      ..writeln(
        '| Kind | Label | Cost | Range | Damage | Cooldown | Ability | Tags |',
      )
      ..writeln('| --- | --- | ---: | ---: | ---: | ---: | --- | --- |');
    for (final hero in HeroCatalog.buildMenu) {
      buffer.writeln(
        '| `${hero.kind.name}` | ${hero.label} | ${hero.cost} | ${hero.range} | ${hero.damage} | ${hero.cooldown} | ${_escape(hero.abilityLabel)} | ${_escape(hero.roleTags.join(', '))} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Enemy Representative Stats')
      ..writeln()
      ..writeln('Values use `CampaignData.enemyForKind(kind, intensity: 1.0)`.')
      ..writeln()
      ..writeln(
        '| Kind | Special | Physical Damage Taken | S1 HP | S5 HP | S10 HP | S15 HP | S16 HP | S19 HP | S22 HP | S25 HP | S28 HP | S30 HP | S16 Wall | S16 Tower |',
      )
      ..writeln(
        '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
      );
    for (final kind in EnemyKind.values) {
      final s16 = CampaignData.enemyForKind(
        kind,
        stageNumber: 16,
        intensity: 1.0,
      );
      final physical = _debugGame(
        16,
      ).debugPhysicalDamageMultiplierForEnemyKind(kind);
      buffer.writeln(
        '| `${kind.name}` | ${_escape(_special(kind))} | ${(physical * 100).round()}% | ${_hp(kind, 1)} | ${_hp(kind, 5)} | ${_hp(kind, 10)} | ${_hp(kind, 15)} | ${_hp(kind, 16)} | ${_hp(kind, 19)} | ${_hp(kind, 22)} | ${_hp(kind, 25)} | ${_hp(kind, 28)} | ${_hp(kind, 30)} | ${s16.baseStructureDamage} | ${s16.baseTowerContactDamage} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Stage Event Boss Dice')
      ..writeln()
      ..writeln(
        '| Stage | Event ID | Title | Enemy | HP | Physical Damage Taken | Wall Damage | Shockwave Splash | Tower Contact | HP Mult | Damage Mult | Scale |',
      )
      ..writeln(
        '| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
      );
    for (final stageNumber in [4, 7, 10, 13, 16, 19, 22, 25, 28]) {
      final game = _debugGame(stageNumber);
      for (final event in StageEventGenerator.poolForStage(stageNumber)) {
        final boss = game.debugStageEventEnemyDefinition(event);
        final physical = game.debugPhysicalDamageMultiplierForEnemyKind(
          boss.kind,
          stageEvent: true,
        );
        final shockwave = (boss.baseStructureDamage * 0.42).toStringAsFixed(1);
        buffer.writeln(
          '| $stageNumber | `${event.id}` | ${event.title} | `${boss.kind.name}` | ${boss.hitPoints} | ${(physical * 100).round()}% | ${boss.baseStructureDamage} | $shockwave | ${boss.baseTowerContactDamage} | ${event.hitPointMultiplier} | ${event.damageMultiplier} | ${event.visualScale} |',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Run Offer Dice Cards')
      ..writeln()
      ..writeln('| ID | Title | Rarity | Effect | Operation |')
      ..writeln('| --- | --- | --- | --- | --- |');
    final offers = <String, RunOfferDefinition>{};
    for (var seed = 1; seed <= 60; seed += 1) {
      for (var offerIndex = 0; offerIndex < 6; offerIndex += 1) {
        for (final hero in HeroKind.values) {
          for (final offer in RunOfferGenerator.generate(
            seed: seed,
            stageNumber: 16,
            offerIndex: offerIndex,
            unlockedTowers: TowerKind.values.toSet(),
            chosenHeroKind: hero,
          )) {
            offers[offer.id] = offer;
          }
        }
      }
    }
    for (final offer
        in offers.values.toList()..sort((a, b) => a.id.compareTo(b.id))) {
      buffer.writeln(
        '| `${offer.id}` | ${offer.title} | ${offer.rarity.name} | ${_escape(offer.effectLine)} | ${_escape(offer.operationLine)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Meta Upgrades')
      ..writeln()
      ..writeln(
        '| ID | Label | Max | Base Cost | Cost Multipliers | Milestone | Level 5 Effect |',
      )
      ..writeln('| --- | --- | ---: | ---: | --- | --- | --- |');
    for (final upgrade in MetaUpgradeCatalog.upgrades) {
      buffer.writeln(
        '| `${upgrade.id}` | ${upgrade.label} | ${upgrade.maxLevel} | ${upgrade.baseCost} | ${upgrade.levelCostMultipliers.join(', ')} | ${_escape(upgrade.milestoneLabel ?? '-')} | ${_escape(MetaUpgradeCatalog.effectSummary(upgrade.id, upgrade.maxLevel))} |',
      );
    }

    File('docs/generated/current-game-data-snapshot.md')
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

int _hp(EnemyKind kind, int stageNumber) {
  return CampaignData.enemyForKind(
    kind,
    stageNumber: stageNumber,
    intensity: 1.0,
  ).hitPoints;
}

Set<EnemyKind> _enemyKindsForStage(StageDefinition stage) {
  return {
    for (final wave in stage.waves)
      for (final group in wave.groups) group.enemy.kind,
    for (final cycle in stage.assaultCycles)
      for (final group in cycle.groups) group.enemy.kind,
    for (final event in stage.stageEvents) event.enemyKind,
  };
}

String _frontsForStage(StageDefinition stage) {
  final fronts = <String>{};
  for (final cycle in stage.assaultCycles) {
    fronts.add(cycle.activeFronts.map((front) => front.name).join('+'));
  }
  if (fronts.isEmpty) {
    for (final wave in stage.waves) {
      for (final group in wave.groups) {
        final direction = group.direction;
        if (direction != null) {
          fronts.add(direction.name);
        }
      }
    }
  }
  return fronts.isEmpty ? '-' : fronts.join(' / ');
}

String _cell(List<int>? cell) {
  if (cell == null || cell.length < 2) {
    return '-';
  }
  return '[${cell[0]},${cell[1]}]';
}

String _escape(String value) {
  return value.replaceAll('|', '\\|').replaceAll('\n', ' ');
}

String _special(EnemyKind kind) {
  final enemy = CampaignData.enemyForKind(
    kind,
    stageNumber: 16,
    intensity: 1.0,
  );
  return enemy.specialDescription;
}
