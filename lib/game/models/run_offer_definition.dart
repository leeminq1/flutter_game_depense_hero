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
    required this.effectLine,
    required this.operationLine,
    required this.rarity,
    required this.modifiers,
  });

  final String id;
  final String title;
  final String description;
  final String effectLine;
  final String operationLine;
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
      id: 'archer_wall_line',
      title: '성벽 뒤 궁수 라인',
      description: '성벽으로 늦춘 적을 궁수 사거리 안에서 오래 처리합니다.',
      effectLine: '궁수 사거리 +15%',
      operationLine: '성벽 뒤 궁수 라인',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerRangeMultiplier,
          towerKind: TowerKind.archer,
          multiplier: 1.15,
        ),
      ],
    ),
    RunOfferDefinition(
      id: 'hero_guard_anchor_${chosenHeroKind.name}',
      title: '영웅 방어 거점',
      description: '영웅을 성벽 뒤나 교차로에 세워 누수를 더 빠르게 정리합니다.',
      effectLine: '선택 영웅 피해 +15%',
      operationLine: '영웅 중심 방어 위치',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.heroDamageMultiplier,
          heroKind: chosenHeroKind,
          multiplier: 1.15,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'mage_first_level',
      title: '교차로 오벨리스크',
      description: '교차로 근처 첫 마법사 탑으로 장갑 적을 빨리 녹입니다.',
      effectLine: '첫 마법사 탑 Lv.2',
      operationLine: '교차로 마법사',
      rarity: RunOfferRarity.rare,
      modifiers: [
        RunModifier(
          type: RunModifierType.firstTowerLevelBonus,
          towerKind: TowerKind.mageObelisk,
          levelBonus: 1,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'wall_hp_network',
      title: '버티는 성벽망',
      description: '얇은 성벽 라인도 더 오래 버텨 타워 사거리를 살립니다.',
      effectLine: '모든 성벽 HP +20%',
      operationLine: '두꺼운 성벽 라인',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.barrierHitPointMultiplier,
          multiplier: 1.20,
        ),
      ],
    ),
    const RunOfferDefinition(
      id: 'barracks_fortress_hold',
      title: '요새 경비대',
      description: '병영이 두꺼운 성벽 뒤에서 빠른 적을 붙잡는 작전입니다.',
      effectLine: '병영 피해 +15%',
      operationLine: '요새 병영 대응',
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
      id: 'frost_chokepoint',
      title: '서리 교차로',
      description: '서리 제단을 적이 겹치는 길목에 두면 전선이 안정됩니다.',
      effectLine: '서리 제단 공격속도 +12%',
      operationLine: '서리 길목 제어',
      rarity: RunOfferRarity.common,
      modifiers: [
        RunModifier(
          type: RunModifierType.towerCooldownMultiplier,
          towerKind: TowerKind.frostShrine,
          multiplier: 0.88,
        ),
      ],
    ),
  ];
}
