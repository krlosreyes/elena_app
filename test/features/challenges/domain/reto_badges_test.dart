// SPEC-264: tests de qué insignias de reto corresponden a cada récord.

import 'package:elena_app/src/features/challenges/domain/reto_badges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('participar y terminar el primer reto', () {
    final ids = RetoBadges.earnedIds(
      joined: 1,
      finished: 1,
      won: 0,
      rematches: 0,
    );
    expect(ids, containsAll(['retos_participar', 'retos_terminar']));
    expect(ids.contains('retos_ganar_1'), isFalse);
  });

  test('las victorias son acumulativas (1, 3, 10)', () {
    expect(
      RetoBadges.earnedIds(joined: 3, finished: 3, won: 3, rematches: 0),
      containsAll(['retos_ganar_1', 'retos_ganar_3']),
    );
    final diez =
        RetoBadges.earnedIds(joined: 10, finished: 10, won: 10, rematches: 0);
    expect(diez, contains('retos_ganar_10'));
  });

  test('la insignia de revancha requiere 3 revanchas', () {
    expect(
      RetoBadges.earnedIds(joined: 3, finished: 0, won: 0, rematches: 2)
          .contains('retos_revancha'),
      isFalse,
    );
    expect(
      RetoBadges.earnedIds(joined: 4, finished: 0, won: 0, rematches: 3)
          .contains('retos_revancha'),
      isTrue,
    );
  });

  test('récord en cero no otorga nada', () {
    expect(
      RetoBadges.earnedIds(joined: 0, finished: 0, won: 0, rematches: 0),
      isEmpty,
    );
  });
}
