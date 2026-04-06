

enum RunAssistEffect {
  enemyHealthDown,
  towerDamageUp,
  bonusCoins,
}

class RunAssistChoice {
  const RunAssistChoice({
    required this.id,
    required this.label,
    required this.description,
    required this.effect,
    this.healthMultiplier = 1.0,
    this.damageMultiplier = 1.0,
    this.bonusCoins = 0,
  });

  final String id;
  final String label;
  final String description;
  final RunAssistEffect effect;
  final double healthMultiplier;
  final double damageMultiplier;
  final int bonusCoins;

  static const List<RunAssistChoice> options = [
    RunAssistChoice(
      id: 'enemy_health_down',
      label: '적군 약화',
      description: '이번 시도 동안 모든 적의 체력이 30% 감소합니다.',
      effect: RunAssistEffect.enemyHealthDown,
      healthMultiplier: 0.7,
    ),
    RunAssistChoice(
      id: 'tower_damage_up',
      label: '공격력 강화',
      description: '이번 시도 동안 모든 타워의 공격력이 30% 증가합니다.',
      effect: RunAssistEffect.towerDamageUp,
      damageMultiplier: 1.3,
    ),
    RunAssistChoice(
      id: 'bonus_coins',
      label: '긴급 자금',
      description: '시작 시 1200 코인을 추가로 획득합니다.',
      effect: RunAssistEffect.bonusCoins,
      bonusCoins: 1200,
    ),
  ];
}
