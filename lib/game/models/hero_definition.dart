import 'dart:ui';

import 'package:depense_game/game/audio/audio_event.dart';

enum HeroKind { knight, archer, mage, ninja, paladin }

class HeroDefinition {
  const HeroDefinition({
    required this.kind,
    required this.label,
    required this.shortDescription,
    required this.cost,
    required this.unlockStage,
    required this.range,
    required this.damage,
    required this.cooldown,
    required this.color,
    required this.attackEvent,
  });

  final HeroKind kind;
  final String label;
  final String shortDescription;
  final int cost;
  final int unlockStage;
  final double range;
  final double damage;
  final double cooldown;
  final Color color;
  final AudioEvent attackEvent;

  bool isUnlockedForStage(int stageNumber) => stageNumber >= unlockStage;
}

class HeroCatalog {
  static const List<HeroDefinition> buildMenu = [
    HeroDefinition(
      kind: HeroKind.knight,
      label: '기사',
      shortDescription: '성 주변을 오래 버티는 근접 영웅',
      cost: 120,
      unlockStage: 1,
      range: 72,
      damage: 24,
      cooldown: 0.95,
      color: Color(0xFF77A7FF),
      attackEvent: AudioEvent.slashHit,
    ),
    HeroDefinition(
      kind: HeroKind.archer,
      label: '궁사',
      shortDescription: '먼 거리에서 안정적으로 지원 사격',
      cost: 145,
      unlockStage: 5,
      range: 150,
      damage: 18,
      cooldown: 0.72,
      color: Color(0xFF9AD66F),
      attackEvent: AudioEvent.arrowShot,
    ),
    HeroDefinition(
      kind: HeroKind.mage,
      label: '마법사',
      shortDescription: '중장갑과 뭉친 적에게 강한 마법 피해',
      cost: 175,
      unlockStage: 10,
      range: 128,
      damage: 34,
      cooldown: 1.18,
      color: Color(0xFFC07BFF),
      attackEvent: AudioEvent.magicHit,
    ),
    HeroDefinition(
      kind: HeroKind.ninja,
      label: '닌자',
      shortDescription: '빠른 공격으로 새는 적을 정리',
      cost: 165,
      unlockStage: 15,
      range: 92,
      damage: 21,
      cooldown: 0.48,
      color: Color(0xFFFF6D7A),
      attackEvent: AudioEvent.slashHit,
    ),
    HeroDefinition(
      kind: HeroKind.paladin,
      label: '성기사',
      shortDescription: '단단한 전선 유지와 강한 일격',
      cost: 210,
      unlockStage: 20,
      range: 82,
      damage: 42,
      cooldown: 1.32,
      color: Color(0xFFFFD166),
      attackEvent: AudioEvent.armorHit,
    ),
  ];

  static HeroDefinition byKind(HeroKind kind) {
    return buildMenu.firstWhere((hero) => hero.kind == kind);
  }

  static String heroId(HeroKind kind) {
    return switch (kind) {
      HeroKind.knight => 'knight',
      HeroKind.archer => 'archer',
      HeroKind.mage => 'mage',
      HeroKind.ninja => 'ninja',
      HeroKind.paladin => 'paladin',
    };
  }
}
