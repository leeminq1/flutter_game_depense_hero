import 'dart:ui';

import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
import 'package:depense_game/game/audio/audio_catalog.dart';
import 'package:depense_game/game/audio/audio_event.dart';

enum TowerKind {
  archer,
  guardBarracks,
  mageObelisk,
  frostShrine,
  coinMill,
  ballista,
  emberkeep,
}

class TowerBranchDefinition {
  const TowerBranchDefinition({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class TowerDefinition {
  const TowerDefinition({
    required this.kind,
    required this.label,
    required this.shortLabel,
    required this.shortDescription,
    required this.abilityDescription,
    required this.cost,
    required this.range,
    required this.damage,
    required this.cooldown,
    required this.color,
    required this.attackEvent,
    required this.branches,
    this.slowFactor,
    this.economyIncome,
    this.economyInterval,
    this.unlockHint,
  });

  final TowerKind kind;
  final String label;
  final String shortLabel;
  final String shortDescription;
  final String abilityDescription;
  final int cost;
  final double range;
  final double damage;
  final double cooldown;
  final Color color;
  final AudioEvent attackEvent;
  final List<TowerBranchDefinition> branches;
  final double? slowFactor;
  final int? economyIncome;
  final double? economyInterval;
  final String? unlockHint;

  bool isUnlocked(ResolvedMetaUpgrades metaUpgrades) {
    switch (kind) {
      case TowerKind.ballista:
        return metaUpgrades.ballistaUnlocked;
      case TowerKind.emberkeep:
        return metaUpgrades.emberkeepUnlocked;
      case TowerKind.archer:
      case TowerKind.guardBarracks:
      case TowerKind.mageObelisk:
      case TowerKind.frostShrine:
      case TowerKind.coinMill:
        return true;
    }
  }
}

class TowerCatalog {
  static const List<TowerDefinition> buildMenu = [
    TowerDefinition(
      kind: TowerKind.archer,
      label: 'Archer',
      shortLabel: 'AR',
      shortDescription: 'Cheap single-target DPS',
      abilityDescription: 'Every third shot becomes a piercing critical volley.',
      cost: 55,
      range: 135,
      damage: 16,
      cooldown: 0.85,
      color: AudioCatalog.archerColor,
      attackEvent: AudioEvent.arrowShot,
      branches: [
        TowerBranchDefinition(
          id: 'ranger',
          label: 'Ranger',
          description: 'Longer range and heavier critical volleys.',
        ),
        TowerBranchDefinition(
          id: 'multishot',
          label: 'Multishot',
          description: 'Stronger split volleys against clustered enemies.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.guardBarracks,
      label: 'Barracks',
      shortLabel: 'BK',
      shortDescription: 'Lane control and steady hits',
      abilityDescription: 'Strikes stagger enemies and cleave nearby targets.',
      cost: 70,
      range: 90,
      damage: 20,
      cooldown: 1.15,
      color: AudioCatalog.barracksColor,
      attackEvent: AudioEvent.slashHit,
      branches: [
        TowerBranchDefinition(
          id: 'vanguard',
          label: 'Vanguard',
          description: 'Harder strikes with longer stagger duration.',
        ),
        TowerBranchDefinition(
          id: 'sentinel',
          label: 'Sentinel',
          description: 'Wider cleave coverage and lane reach.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.mageObelisk,
      label: 'Mage',
      shortLabel: 'MG',
      shortDescription: 'Anti-armor magic burst',
      abilityDescription: 'Arcane bolts chain across clustered enemies.',
      cost: 95,
      range: 125,
      damage: 28,
      cooldown: 1.25,
      color: AudioCatalog.mageColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'storm',
          label: 'Storm',
          description: 'More chain targets and faster burst cadence.',
        ),
        TowerBranchDefinition(
          id: 'rune',
          label: 'Rune',
          description: 'Amplified armor-breaking and execute pressure.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.frostShrine,
      label: 'Frost',
      shortLabel: 'FR',
      shortDescription: 'Slow and control',
      abilityDescription: 'Pulses an icy field that slows all enemies in range.',
      cost: 80,
      range: 115,
      damage: 10,
      cooldown: 1.05,
      color: AudioCatalog.frostColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'glacier',
          label: 'Glacier',
          description: 'Stronger slow and larger control radius.',
        ),
        TowerBranchDefinition(
          id: 'shatter',
          label: 'Shatter',
          description: 'Higher damage against already slowed enemies.',
        ),
      ],
      slowFactor: 0.55,
    ),
    TowerDefinition(
      kind: TowerKind.coinMill,
      label: 'Coin Mill',
      shortLabel: 'CM',
      shortDescription: 'Generates gold over time',
      abilityDescription: 'Pays interest over time and a bonus when waves begin.',
      cost: 90,
      range: 0,
      damage: 0,
      cooldown: 0,
      color: AudioCatalog.millColor,
      attackEvent: AudioEvent.coinGain,
      branches: [
        TowerBranchDefinition(
          id: 'mint',
          label: 'Mint',
          description: 'Improves passive interest income each cycle.',
        ),
        TowerBranchDefinition(
          id: 'tribute',
          label: 'Tribute',
          description: 'Bigger wave-start payouts and better sell value.',
        ),
      ],
      economyIncome: 4,
      economyInterval: 4.5,
    ),
    TowerDefinition(
      kind: TowerKind.ballista,
      label: 'Ballista',
      shortLabel: 'BL',
      shortDescription: 'Long-range anti-elite siege',
      abilityDescription: 'Heavy bolts hit hard and pin priority targets in place.',
      cost: 125,
      range: 175,
      damage: 58,
      cooldown: 1.95,
      color: AudioCatalog.ballistaColor,
      attackEvent: AudioEvent.armorHit,
      branches: [
        TowerBranchDefinition(
          id: 'siege',
          label: 'Siege',
          description: 'Harder anti-elite damage and stronger armor cracking.',
        ),
        TowerBranchDefinition(
          id: 'harpoon',
          label: 'Harpoon',
          description: 'Longer pin duration and stronger follow-up control.',
        ),
      ],
      unlockHint: 'Unlock with Bow Mastery level 2.',
    ),
    TowerDefinition(
      kind: TowerKind.emberkeep,
      label: 'Emberkeep',
      shortLabel: 'EM',
      shortDescription: 'Area denial and burn damage',
      abilityDescription: 'Ignites a zone, burning clustered enemies over time.',
      cost: 115,
      range: 118,
      damage: 18,
      cooldown: 1.30,
      color: AudioCatalog.emberkeepColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'inferno',
          label: 'Inferno',
          description: 'Larger blast radius with hotter burn damage.',
        ),
        TowerBranchDefinition(
          id: 'cinder',
          label: 'Cinder',
          description: 'Longer burn duration and better crowd attrition.',
        ),
      ],
      unlockHint: 'Unlock with Arcane Mastery level 2.',
    ),
  ];

  static TowerDefinition byKind(TowerKind kind) {
    return buildMenu.firstWhere((tower) => tower.kind == kind);
  }

  static bool isUnlocked(TowerKind kind, ResolvedMetaUpgrades metaUpgrades) {
    return byKind(kind).isUnlocked(metaUpgrades);
  }
}
