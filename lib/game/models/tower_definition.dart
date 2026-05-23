import 'dart:ui';

import 'package:depense_game/data/meta/meta_upgrade_definitions.dart';
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
      case TowerKind.emberkeep:
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
      label: '궁수',
      shortLabel: 'AR',
      shortDescription: '저렴한 단일 화력',
      abilityDescription: '세 번째 화살마다 치명적인 관통 사격을 날립니다.',
      cost: 35,
      range: 4,
      damage: 9.5,
      cooldown: 0.85,
      color: Color(0xFF8BC34A),
      attackEvent: AudioEvent.arrowShot,
      branches: [
        TowerBranchDefinition(
          id: 'ranger',
          label: '레인저',
          description: '사거리가 늘고 치명타 화살의 피해가 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'multishot',
          label: '멀티샷',
          description: '치명타 발사 시 주변 적에게 추가 화살을 퍼뜨립니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.guardBarracks,
      label: '병영',
      shortLabel: 'BK',
      shortDescription: '전선 유지와 안정적인 근접 대응',
      abilityDescription: '적을 비틀거리게 만들고 주변 적까지 함께 벱니다.',
      cost: 45,
      range: 3,
      damage: 13.5,
      cooldown: 1.15,
      color: Color(0xFF5C8FC9),
      attackEvent: AudioEvent.slashHit,
      branches: [
        TowerBranchDefinition(
          id: 'vanguard',
          label: '뱅가드',
          description: '공격이 더 무거워지고 기절 시간이 길어집니다.',
        ),
        TowerBranchDefinition(
          id: 'sentinel',
          label: '센티널',
          description: '베기 범위와 주변 타격 범위가 넓어집니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.mageObelisk,
      label: '마법사',
      shortLabel: 'MG',
      shortDescription: '방어 관통 마법 화력',
      abilityDescription: '비전 전류가 여러 적 사이를 연쇄하며 번집니다.',
      cost: 65,
      range: 6,
      damage: 17.5,
      cooldown: 1.25,
      color: Color(0xFF9C27B0),
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'storm',
          label: '스톰',
          description: '연쇄 대상이 늘어나고 공격 주기가 빨라집니다.',
        ),
        TowerBranchDefinition(
          id: 'rune',
          label: '룬',
          description: '방어 관통력과 마무리 화력이 강화됩니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.frostShrine,
      label: '빙결',
      shortLabel: 'FR',
      shortDescription: '감속과 구역 제어',
      abilityDescription: '범위 안의 적 전체를 얼리는 냉기 파동을 방출합니다.',
      cost: 55,
      range: 6,
      damage: 3.5,
      cooldown: 1.05,
      color: Color(0xFF80DEEA),
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'glacier',
          label: '글레이셔',
          description: '감속 효과와 얼음 파동 반경이 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'shatter',
          label: '샤터',
          description: '이미 얼어붙은 적에게 추가 피해를 줍니다.',
        ),
      ],
      slowFactor: 0.55,
    ),
    TowerDefinition(
      kind: TowerKind.coinMill,
      label: '금화 방앗간',
      shortLabel: 'CM',
      shortDescription: '시간에 따라 금화를 생산',
      abilityDescription: '주기적으로 수익을 내고 Wave 시작 때 보너스를 줍니다.',
      cost: 65,
      range: 0,
      damage: 0,
      cooldown: 0,
      color: Color(0xFFFFD54F),
      attackEvent: AudioEvent.coinGain,
      branches: [
        TowerBranchDefinition(
          id: 'mint',
          label: '민트',
          description: '주기마다 얻는 기본 수익이 늘어납니다.',
        ),
        TowerBranchDefinition(
          id: 'tribute',
          label: '트리뷰트',
          description: 'Wave 시작 보너스와 판매 환급이 좋아집니다.',
        ),
      ],
      economyIncome: 4,
      economyInterval: 4.5,
    ),
    TowerDefinition(
      kind: TowerKind.ballista,
      label: '발리스타',
      shortLabel: 'BL',
      shortDescription: '장거리 대형 적 특화 화력',
      abilityDescription: '무거운 볼트로 돌격 적을 강하게 묶어 둡니다.',
      cost: 85,
      range: 8,
      damage: 13.5,
      cooldown: 1.75,
      color: Color(0xFF8D6E63),
      attackEvent: AudioEvent.armorHit,
      branches: [
        TowerBranchDefinition(
          id: 'siege',
          label: '시즈',
          description: '중장갑 대상 피해와 방어 관통이 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'harpoon',
          label: '하푼',
          description: '고정 시간이 길어지고 연속 제어가 좋아집니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.emberkeep,
      label: '엠버킵',
      shortLabel: 'EM',
      shortDescription: '지속 폭발과 화상 피해',
      abilityDescription: '지면을 불태워 여러 적을 지속적으로 소각합니다.',
      cost: 80,
      range: 6,
      damage: 9.5,
      cooldown: 1.35,
      color: Color(0xFFFF5722),
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'inferno',
          label: '인페르노',
          description: '폭발 반경과 화상 피해가 크게 늘어납니다.',
        ),
        TowerBranchDefinition(
          id: 'cinder',
          label: '신더',
          description: '화상 지속시간이 길어지고 구역 억제가 강해집니다.',
        ),
      ],
    ),
  ];

  static TowerDefinition byKind(TowerKind kind) {
    return buildMenu.firstWhere((tower) => tower.kind == kind);
  }

  static bool isUnlocked(TowerKind kind, ResolvedMetaUpgrades metaUpgrades) {
    return byKind(kind).isUnlocked(metaUpgrades);
  }
}
