// SPEC-262: tests de la tabla de recompensas.

import 'package:elena_app/src/features/gamification/domain/star_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recompensas concretas', () {
    expect(StarAction.water.reward.stars, 2);
    expect(StarAction.water.reward.xp, 5);
    expect(StarAction.fastingCompleted.reward.stars, 15);
    expect(StarAction.fastingCompleted.reward.xp, 40);
    expect(StarAction.dayQualified.reward.stars, 10);
    expect(StarAction.dayQualified.reward.xp, 30);
  });

  test('toda acción da estrellas y XP positivos', () {
    for (final a in StarAction.values) {
      expect(a.reward.stars, greaterThan(0), reason: '$a stars');
      expect(a.reward.xp, greaterThan(0), reason: '$a xp');
    }
  });
}
