import 'package:depense_game/game/ui/spawn_front_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('front labels are shortened and joined in stable order', () {
    expect(formatSpawnFronts(const ['북쪽', '서쪽']), '북·서');
    expect(formatSpawnFronts(const ['동쪽', '남쪽']), '동·남');
  });

  test('empty front list uses the waiting label', () {
    expect(formatSpawnFronts(const []), '대기');
  });
}
