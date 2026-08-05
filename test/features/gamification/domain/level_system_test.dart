// SPEC-262: tests de la curva de niveles.

import 'package:elena_app/src/features/gamification/domain/level_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('XP acumulado por nivel', () {
    expect(LevelSystem.cumulativeXpForLevel(1), 0);
    expect(LevelSystem.cumulativeXpForLevel(2), 200);
    expect(LevelSystem.cumulativeXpForLevel(3), 600);
    expect(LevelSystem.cumulativeXpForLevel(8), 5600);
  });

  test('nivel a partir del XP', () {
    expect(LevelSystem.levelForXp(0), 1);
    expect(LevelSystem.levelForXp(199), 1);
    expect(LevelSystem.levelForXp(200), 2);
    expect(LevelSystem.levelForXp(5039), 7); // 4200 ≤ 5039 < 5600
  });

  test('títulos por nivel', () {
    expect(LevelSystem.titleForLevel(1), 'Novato');
    expect(LevelSystem.titleForLevel(8), 'Gurú de la salud');
    expect(LevelSystem.titleForLevel(20), 'Leyenda');
  });

  test('info y barra de progreso', () {
    final info = LevelSystem.infoForXp(5039);
    expect(info.level, 7);
    expect(info.title, 'Élite');
    expect(info.xpIntoLevel, 839); // 5039 − 4200
    expect(info.xpForNext, 1400); // 5600 − 4200
    expect(info.progress, closeTo(0.599, 0.01));
  });

  test('XP negativo se trata como 0', () {
    expect(LevelSystem.infoForXp(-100).level, 1);
  });
}
