import 'dart:ui';

import 'package:depense_game/game/audio/audio_event.dart';

enum HeroKind { knight, archer, mage, ninja, paladin }

class HeroDefinition {
  const HeroDefinition({
    required this.kind,
    required this.label,
    required this.shortDescription,
    required this.abilityLabel,
    required this.abilityDescription,
    required this.roleTags,
    required this.upgradeBranch,
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
  final String abilityLabel;
  final String abilityDescription;
  final List<String> roleTags;
  final String upgradeBranch;
  final int cost;
  final int unlockStage;
  final double range;
  final double damage;
  final double cooldown;
  final Color color;
  final AudioEvent attackEvent;

  bool isUnlockedForStage(int stageNumber) => true;
}

class HeroCatalog {
  static const List<HeroDefinition> buildMenu = [
    HeroDefinition(
      kind: HeroKind.knight,
      label: '기사',
      shortDescription: '성 주변을 오래 버티는 근접 영웅',
      abilityLabel: '수호 오라',
      abilityDescription: '주변 타워가 몬스터에게 받는 피해를 줄여 전선을 더 오래 유지합니다.',
      roleTags: ['방어', '근접', '타워 보호'],
      upgradeBranch: '수호 전위',
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
      abilityLabel: '표식 사격',
      abilityDescription: '공격한 적에게 표식을 남겨 잠시 동안 받는 피해를 증가시킵니다.',
      roleTags: ['원거리', '표식', '지원 화력'],
      upgradeBranch: '매의 눈',
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
      abilityLabel: '연쇄 폭발',
      abilityDescription: '세 번째 공격마다 대상 주변의 적에게 추가 마법 피해를 줍니다.',
      roleTags: ['마법', '광역', '중장갑 대응'],
      upgradeBranch: '비전 폭풍',
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
      abilityLabel: '마무리 일격',
      abilityDescription: '체력이 낮은 적을 공격하면 추가 피해로 빠르게 정리합니다.',
      roleTags: ['처형', '고속', '누수 대응'],
      upgradeBranch: '그림자 칼날',
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
      abilityLabel: '성역 수리',
      abilityDescription: '주기적으로 주변에서 가장 손상된 타워를 조금 회복합니다.',
      roleTags: ['유지력', '회복', '전선 안정'],
      upgradeBranch: '빛의 보루',
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
