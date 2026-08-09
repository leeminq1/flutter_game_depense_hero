String formatSpawnFronts(List<String> fronts) {
  if (fronts.isEmpty) {
    return '대기';
  }
  return fronts.map(_shortFrontLabel).join('·');
}

String _shortFrontLabel(String front) {
  return switch (front.trim()) {
    '북쪽' || '북' => '북',
    '남쪽' || '남' => '남',
    '동쪽' || '동' => '동',
    '서쪽' || '서' => '서',
    final value => value,
  };
}
