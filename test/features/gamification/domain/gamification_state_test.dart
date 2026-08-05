// SPEC-262: tests de la aritmética de la economía (estado puro).

import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';
import 'package:elena_app/src/features/gamification/domain/shop_item.dart';
import 'package:elena_app/src/features/gamification/domain/star_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estado inicial', () {
    const s = GamificationState();
    expect(s.stars, 0);
    expect(s.xp, 0);
    expect(s.frosties, 0);
    expect(s.level, 1);
    expect(s.levelInfo.title, 'Novato');
  });

  test('earn suma estrellas (saldo + de por vida) y XP', () {
    final s = const GamificationState().earn(StarAction.water);
    expect(s.stars, 2);
    expect(s.totalStarsEarned, 2);
    expect(s.xp, 5);
    final s2 = s.earn(StarAction.meal);
    expect(s2.stars, 5);
    expect(s2.totalStarsEarned, 5);
    expect(s2.xp, 13);
  });

  test('cada 6 días que califican regala 1 congelador', () {
    var s = const GamificationState();
    for (var i = 0; i < 5; i++) {
      s = s.onDayQualified();
    }
    expect(s.daysTowardFrosty, 5);
    expect(s.frosties, 0);
    s = s.onDayQualified(); // sexto
    expect(s.daysTowardFrosty, 0);
    expect(s.frosties, 1);
    expect(s.stars, 60); // 6 × 10
    expect(s.xp, 180); // 6 × 30
  });

  test('horas de ayuno de por vida', () {
    var s = const GamificationState().addFastingHours(16);
    expect(s.lifetimeFastingHours, 16);
    s = s.addFastingHours(-5); // no-op
    expect(s.lifetimeFastingHours, 16);
  });

  group('tienda', () {
    final frosty1 = Shop.byId('frosty-1')!; // 50 estrellas → 1
    final frosty5 = Shop.byId('frosty-5')!; // 200 → 5

    test('canAfford', () {
      expect(const GamificationState(stars: 50).canAfford(frosty1), isTrue);
      expect(const GamificationState(stars: 49).canAfford(frosty1), isFalse);
    });

    test('purchase descuenta estrellas y suma congeladores', () {
      final s = const GamificationState(stars: 50).purchase(frosty1);
      expect(s, isNotNull);
      expect(s!.stars, 0);
      expect(s.frosties, 1);
      expect(s.totalStarsEarned, 0); // comprar no aumenta lo ganado
    });

    test('purchase devuelve null si no alcanza (no muta)', () {
      expect(const GamificationState(stars: 49).purchase(frosty1), isNull);
    });

    test('bundle grande', () {
      final s = const GamificationState(stars: 200).purchase(frosty5);
      expect(s!.stars, 0);
      expect(s.frosties, 5);
    });
  });

  test('useFrosty descuenta uno o devuelve null', () {
    expect(const GamificationState(frosties: 1).useFrosty()!.frosties, 0);
    expect(const GamificationState(frosties: 0).useFrosty(), isNull);
  });
}
