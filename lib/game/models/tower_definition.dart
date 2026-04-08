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
      label: '궁수',
      shortLabel: 'AR',
      shortDescription: '저렴한 단일 화력',
      abilityDescription: '세 번째 화살마다 치명적인 관통 사격을 날립니다.',
      cost: 55,
      range: 135,
      damage: 16,
      cooldown: 0.85,
      color: AudioCatalog.archerColor,
      attackEvent: AudioEvent.arrowShot,
      branches: [
        TowerBranchDefinition(
          id: 'ranger',
          label: '레인저',
          description: '사거리가 늘고 치명타 사격이 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'multishot',
          label: '멀티샷',
          description: '뭉친 적에게 퍼지는 연사가 더 강해집니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.guardBarracks,
      label: '병영',
      shortLabel: 'BK',
      shortDescription: '전선 유지와 안정적인 타격',
      abilityDescription: '적을 비틀거리게 만들고 주변 적까지 함께 벱니다.',
      cost: 70,
      range: 90,
      damage: 20,
      cooldown: 1.15,
      color: AudioCatalog.barracksColor,
      attackEvent: AudioEvent.slashHit,
      branches: [
        TowerBranchDefinition(
          id: 'vanguard',
          label: '뱅가드',
          description: '공격이 더 무거워지고 경직 시간이 길어집니다.',
        ),
        TowerBranchDefinition(
          id: 'sentinel',
          label: '센티널',
          description: '베기 범위와 전선 장악 범위가 넓어집니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.mageObelisk,
      label: '마법사',
      shortLabel: 'MG',
      shortDescription: '방어 관통 마법 폭딜',
      abilityDescription: '비전 탄환이 뭉친 적 사이를 연쇄합니다.',
      cost: 95,
      range: 125,
      damage: 28,
      cooldown: 1.25,
      color: AudioCatalog.mageColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'storm',
          label: '스톰',
          description: '연쇄 대상이 늘고 폭딜 주기가 빨라집니다.',
        ),
        TowerBranchDefinition(
          id: 'rune',
          label: '룬',
          description: '방어 파괴와 마무리 화력이 강화됩니다.',
        ),
      ],
    ),
    TowerDefinition(
      kind: TowerKind.frostShrine,
      label: '빙결',
      shortLabel: 'FR',
      shortDescription: '감속과 군중 제어',
      abilityDescription: '범위 안의 적 전체를 늦추는 냉기 파동을 방출합니다.',
      cost: 80,
      range: 115,
      damage: 10,
      cooldown: 1.05,
      color: AudioCatalog.frostColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'glacier',
          label: '글레이셔',
          description: '감속 효과와 제어 반경이 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'shatter',
          label: '셰터',
          description: '이미 느려진 적에게 더 큰 피해를 줍니다.',
        ),
      ],
      slowFactor: 0.55,
    ),
    TowerDefinition(
      kind: TowerKind.coinMill,
      label: '금화 방앗간',
      shortLabel: 'CM',
      shortDescription: '시간이 지날수록 금화를 생산',
      abilityDescription: '주기적으로 수익을 내고 Wave 시작 시 보너스를 줍니다.',
      cost: 90,
      range: 0,
      damage: 0,
      cooldown: 0,
      color: AudioCatalog.millColor,
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
          description: 'Wave 시작 보너스와 판매 환급이 더 좋아집니다.',
        ),
      ],
      economyIncome: 4,
      economyInterval: 4.5,
    ),
    TowerDefinition(
      kind: TowerKind.ballista,
      label: '발리스타',
      shortLabel: 'BL',
      shortDescription: '장거리 대정예 공성 화력',
      abilityDescription: '묵직한 볼트로 핵심 적을 강하게 묶어 둡니다.',
      cost: 125,
      range: 175,
      damage: 58,
      cooldown: 1.95,
      color: AudioCatalog.ballistaColor,
      attackEvent: AudioEvent.armorHit,
      branches: [
        TowerBranchDefinition(
          id: 'siege',
          label: '시즈',
          description: '정예 대상 화력과 방어 파괴가 더 강해집니다.',
        ),
        TowerBranchDefinition(
          id: 'harpoon',
          label: '하푼',
          description: '고정 시간이 길어지고 후속 제어가 좋아집니다.',
        ),
      ],
      unlockHint: '활 숙련 2레벨에서 해금됩니다.',
    ),
    TowerDefinition(
      kind: TowerKind.emberkeep,
      label: '엠버킵',
      shortLabel: 'EM',
      shortDescription: '지역 봉쇄와 화상 피해',
      abilityDescription: '지면을 불태워 뭉친 적을 지속적으로 태웁니다.',
      cost: 115,
      range: 118,
      damage: 18,
      cooldown: 1.30,
      color: AudioCatalog.emberkeepColor,
      attackEvent: AudioEvent.magicHit,
      branches: [
        TowerBranchDefinition(
          id: 'inferno',
          label: '인페르노',
          description: '폭발 반경과 화상 피해가 더 커집니다.',
        ),
        TowerBranchDefinition(
          id: 'cinder',
          label: '신더',
          description: '화상 지속시간이 길어지고 군중 견제가 강해집니다.',
        ),
      ],
      unlockHint: '비전 숙련 2레벨에서 해금됩니다.',
    ),
  ];

  static TowerDefinition byKind(TowerKind kind) {
    return buildMenu.firstWhere((tower) => tower.kind == kind);
  }

  static bool isUnlocked(TowerKind kind, ResolvedMetaUpgrades metaUpgrades) {
    return byKind(kind).isUnlocked(metaUpgrades);
  }
}
