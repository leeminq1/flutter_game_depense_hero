import 'dart:math' as math;

import 'package:depense_game/game/models/hero_definition.dart';
import 'package:depense_game/game/models/stage_definition.dart';
import 'package:depense_game/game/models/tower_definition.dart';

enum RunOfferRarity { common, rare, epic }

enum RunModifierType {
  towerCostMultiplier,
  towerRangeMultiplier,
  towerDamageMultiplier,
  towerCooldownMultiplier,
  firstTowerLevelBonus,
  barrierCostMultiplier,
  barrierHitPointMultiplier,
  barrierRepairCostMultiplier,
  heroDamageMultiplier,
  disableHeroRevive,
}

class RunModifier {
  const RunModifier({
    required this.type,
    this.towerKind,
    this.barrierKind,
    this.heroKind,
    this.multiplier = 1.0,
    this.levelBonus = 0,
  });

  final RunModifierType type;
  final TowerKind? towerKind;
  final BarrierKind? barrierKind;
  final HeroKind? heroKind;
  final double multiplier;
  final int levelBonus;
}

class RunOfferDefinition {
  const RunOfferDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.modifiers,
  });

  final String id;
  final String title;
  final String description;
  final RunOfferRarity rarity;
  final List<RunModifier> modifiers;
}

class RunModifierSet {
  const RunModifierSet(this.offers);

  static const empty = RunModifierSet([]);

  final List<RunOfferDefinition> offers;

  double towerCostMultiplier(TowerKind kind) =>
      _towerMultiplier(kind, RunModifierType.towerCostMultiplier);

  double towerRangeMultiplier(TowerKind kind) =>
      _towerMultiplier(kind, RunModifierType.towerRangeMultiplier);

  double towerDamageMultiplier(TowerKind kind) =>
      _towerMultiplier(kind, RunModifierType.towerDamageMultiplier);

  double towerCooldownMultiplier(TowerKind kind) =>
      _towerMultiplier(kind, RunModifierType.towerCooldownMultiplier);

  int firstTowerLevelBonus(TowerKind kind) {
    var bonus = 0;
    for (final modifier in _matchingTowerModifiers(
      kind,
      RunModifierType.firstTowerLevelBonus,
    )) {
      bonus += modifier.levelBonus;
    }
    return bonus;
  }

  double barrierCostMultiplier(BarrierKind kind) =>
      _barrierMultiplier(kind, RunModifierType.barrierCostMultiplier);

  double barrierHitPointMultiplier(BarrierKind kind) =>
      _barrierMultiplier(kind, RunModifierType.barrierHitPointMultiplier);

  double barrierRepairCostMultiplier(BarrierKind kind) =>
      _barrierMultiplier(kind, RunModifierType.barrierRepairCostMultiplier);

  double heroDamageMultiplier(HeroKind kind) =>
      _heroMultiplier(kind, RunModifierType.heroDamageMultiplier);

  bool get disablesHeroRevive {
    for (final offer in offers) {
      for (final modifier in offer.modifiers) {
        if (modifier.type == RunModifierType.disableHeroRevive) {
          return true;
        }
      }
    }
    return false;
  }

  double _towerMultiplier(TowerKind kind, RunModifierType type) {
    var multiplier = 1.0;
    for (final modifier in _matchingTowerModifiers(kind, type)) {
      multiplier *= modifier.multiplier;
    }
    return multiplier;
  }

  double _barrierMultiplier(BarrierKind kind, RunModifierType type) {
    var multiplier = 1.0;
    for (final offer in offers) {
      for (final modifier in offer.modifiers) {
        if (modifier.type == type &&
            (modifier.barrierKind == null || modifier.barrierKind == kind)) {
          multiplier *= modifier.multiplier;
        }
      }
    }
    return multiplier;
  }

  double _heroMultiplier(HeroKind kind, RunModifierType type) {
    var multiplier = 1.0;
    for (final offer in offers) {
      for (final modifier in offer.modifiers) {
        if (modifier.type == type &&
            (modifier.heroKind == null || modifier.heroKind == kind)) {
          multiplier *= modifier.multiplier;
        }
      }
    }
    return multiplier;
  }

  Iterable<RunModifier> _matchingTowerModifiers(
    TowerKind kind,
    RunModifierType type,
  ) sync* {
    for (final offer in offers) {
      for (final modifier in offer.modifiers) {
        if (modifier.type == type &&
            (modifier.towerKind == null || modifier.towerKind == kind)) {
          yield modifier;
        }
      }
    }
  }
}

class RunOfferGenerator {
  const RunOfferGenerator._();

  static List<RunOfferDefinition> generate({
    required int seed,
    required int stageNumber,
    required int offerIndex,
    required Set<TowerKind> unlockedTowers,
    required HeroKind chosenHeroKind,
  }) {
    final random = math.Random(
      seed + (stageNumber * 9973) + (offerIndex * 7919),
    );
    final pool = _pool(
      chosenHeroKind,
    ).where((offer) => _isOfferAvailable(offer, unlockedTowers)).toList();
    pool.shuffle(random);
    return pool.take(3).toList(growable: false);
  }

  static bool _isOfferAvailable(
    RunOfferDefinition offer,
    Set<TowerKind> unlockedTowers,
  ) {
    for (final modifier in offer.modifiers) {
      final towerKind = modifier.towerKind;
      if (towerKind != null && !unlockedTowers.contains(towerKind)) {
        return false;
      }
    }
    return true;
  }

  static List<RunOfferDefinition> _pool(HeroKind chosenHeroKind) => [
    const RunOfferDefinition(
      id: 'archer_range_15',
      title: '장궁 훈련',
      description: '이번 STAGE 동안 궁수 사거리 +15%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerRangeMultiplier,
          towerKind: TowerKind.archer,
          multiplier: 1.15,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'stone_wall_cost_20',
      title: '석공 할인',
      description: '이번 STAGE 동안 돌 성벽 비용 -20%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.barrierCostMultiplier,
          barrierKind: BarrierKind.stoneWall,
          multiplier: 0.80,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'mage_first_level',
      title: '준비된 오벨리스크',
      description: '처음 짓는 마법사 탑이 Lv.2로 시작',
      rarity: RunOfferRarity.rare,
      modifiers: [
        RunModifier(
          type: RunModifierType.firstTowerLevelBonus,
          towerKind: TowerKind.mageObelisk,
          levelBonus: 1,
        ),
      ],
    ),
    RunOfferDefinition(
      id: 'hero_damage_no_revive_${chosenHeroKind.name}',
      title: '영웅의 각오',
      description: '영웅 피해량 +20%, 대신 부활 불가',
      rarity: RunOfferRarity.rare,
      modifiers: [
        RunModifier(
          type: RunModifierType.heroDamageMultiplier,
          heroKind: chosenHeroKind,
          multiplier: 1.20,
        ),
        const RunModifier(type: RunModifierType.disableHeroRevive),
      ],
    ),
    const RunOfferDefinition(
      id: 'gate_hp_repair_trade',
      title: '두꺼운 성문',
      description: '성문 HP +40%, 수리 비용 +15%',
      rarity: RunOfferRarity.rare,
      modifiers: [
        RunModifier(
          type: RunModifierType.barrierHitPointMultiplier,
          barrierKind: BarrierKind.gate,
          multiplier: 1.40,
        ),
        RunModifier(
          type: RunModifierType.barrierRepairCostMultiplier,
          barrierKind: BarrierKind.gate,
          multiplier: 1.15,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'barracks_damage_15',
      title: '숙련 경비대',
      description: '이번 STAGE 동안 병영 피해량 +15%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerDamageMultiplier,
          towerKind: TowerKind.guardBarracks,
          multiplier: 1.15,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'frost_cooldown_10',
      title: '냉기 집중',
      description: '이번 STAGE 동안 서리 제단 공격 속도 +10%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerCooldownMultiplier,
          towerKind: TowerKind.frostShrine,
          multiplier: 0.90,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'reinforced_wall_hp_25',
      title: '철제 보강',
      description: '이번 STAGE 동안 보강 성벽 HP +25%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.barrierHitPointMultiplier,
          barrierKind: BarrierKind.reinforcedWall,
          multiplier: 1.25,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'ballista_damage_18',
      title: '공성 화살',
      description: '이번 STAGE 동안 발리스타 피해량 +18%',
      rarity: RunOfferRarity.rare,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerDamageMultiplier,
          towerKind: TowerKind.ballista,
          multiplier: 1.18,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'emberkeep_cost_15',
      title: '불씨 보급',
      description: '이번 STAGE 동안 화염 보루 비용 -15%',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerCostMultiplier,
          towerKind: TowerKind.emberkeep,
          multiplier: 0.85,
        ),
      ],
    ),
  ];
}
