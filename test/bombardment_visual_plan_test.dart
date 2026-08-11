import 'package:depense_game/game/rendering/bombardment_visual_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell animation loops while the projectile is in flight', () {
    expect(BombardmentVisualPlan.shellFrame(age: 0, warningSeconds: 2.1), 0);
    expect(BombardmentVisualPlan.shellFrame(age: 0.11, warningSeconds: 2.1), 1);
    expect(BombardmentVisualPlan.shellFrame(age: 0.44, warningSeconds: 2.1), 0);
    expect(BombardmentVisualPlan.shellFrame(age: 2.1, warningSeconds: 2.1), 3);
  });

  test('impact animation advances once and clamps at its final frame', () {
    expect(
      BombardmentVisualPlan.impactFrame(
        age: 2.1,
        warningSeconds: 2.1,
        lifetime: 2.7,
      ),
      0,
    );
    expect(
      BombardmentVisualPlan.impactFrame(
        age: 2.41,
        warningSeconds: 2.1,
        lifetime: 2.7,
      ),
      3,
    );
    expect(
      BombardmentVisualPlan.impactFrame(
        age: 9,
        warningSeconds: 2.1,
        lifetime: 2.7,
      ),
      5,
    );
  });

  test('invalid visual frame inputs are rejected', () {
    expect(
      () => BombardmentVisualPlan.shellFrame(age: 0, warningSeconds: 0),
      throwsArgumentError,
    );
    expect(
      () => BombardmentVisualPlan.impactFrame(
        age: 0,
        warningSeconds: 1,
        lifetime: 1,
      ),
      throwsArgumentError,
    );
  });
}
