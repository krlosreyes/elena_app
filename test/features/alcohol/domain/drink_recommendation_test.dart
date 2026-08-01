// SPEC-261.4: tests del motor de recomendación (DrinkRecommendation).

import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_recommendation.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vino = DrinkTypes.byId('vino')!; // no carbonatado
  final cerveza = DrinkTypes.byId('cerveza')!; // carbonatado
  final start = DateTime(2026, 8, 1, 20, 0); // sábado 20:00
  final habitualBedtime = DateTime(2026, 8, 2, 2, 0); // 2:00 madrugada

  DrinkRecommendation rest({DrinkTypeOption? type, WidmarkSex? sex}) =>
      DrinkRecommendation.compute(
        type: type ?? vino,
        weightKg: 70,
        sex: sex ?? WidmarkSex.male,
        startTime: start,
        worksTomorrow: false,
        habitualBedtime: habitualBedtime,
      );

  group('espaciado', () {
    test('70 kg, no carbonatado, hombre → ~86 min', () {
      expect(rest().spacingMinutes, 86);
    });

    test('carbonatado espacia más (se topa en 90)', () {
      expect(rest(type: cerveza).spacingMinutes,
          greaterThanOrEqualTo(rest().spacingMinutes));
      expect(rest(type: cerveza).spacingMinutes, 90);
    });

    test('mujer espacia igual o más que hombre', () {
      expect(rest(sex: WidmarkSex.female).spacingMinutes,
          greaterThanOrEqualTo(rest(sex: WidmarkSex.male).spacingMinutes));
    });

    test('peso alto no baja de 45 min', () {
      final r = DrinkRecommendation.compute(
        type: vino,
        weightKg: 200,
        sex: WidmarkSex.male,
        startTime: start,
        worksTomorrow: false,
        habitualBedtime: habitualBedtime,
      );
      expect(r.spacingMinutes, greaterThanOrEqualTo(45));
    });
  });

  group('nº de tragos y ventana', () {
    test('noche libre (ventana 3 h) → 2 tragos, no apretado', () {
      final r = rest();
      // lastCall = 23:00; ventana 180 min; espaciado 86 → floor(180/86)=2
      expect(r.drinks, 2);
      expect(r.tight, isFalse);
      expect(r.waterGlasses, r.drinks); // regla 1:1
    });

    test('noche laboral (madrugas 7:00) → ventana mínima, plan apretado', () {
      final r = DrinkRecommendation.compute(
        type: vino,
        weightKg: 70,
        sex: WidmarkSex.male,
        startTime: start,
        worksTomorrow: true,
        wakeTime: DateTime(2026, 8, 2, 7, 0),
        habitualBedtime: habitualBedtime,
      );
      // bedtime = 7:00 − 7,5 h = 23:30; lastCall = 20:30; ventana 30 min → 0.
      expect(r.drinks, lessThanOrEqualTo(rest().drinks));
      expect(r.tight, isTrue);
    });

    test('último trago es 3 h antes de dormir', () {
      final r = rest();
      expect(r.bedtime.difference(r.lastCall), const Duration(hours: 3));
    });

    test('descanso con hábito temprano (22:00) NO colapsa la ventana', () {
      // Reproduce el bug del screenshot: cerveza 20:00, Descanso, hábito 22:00.
      final r = DrinkRecommendation.compute(
        type: cerveza,
        weightKg: 70,
        sex: WidmarkSex.male,
        startTime: start,
        worksTomorrow: false,
        habitualBedtime: DateTime(2026, 8, 1, 22, 0), // hábito temprano
      );
      expect(r.drinks, greaterThan(0)); // ya no es 0
      expect(r.lastCall.isAfter(start), isTrue); // último trago tras el inicio
      // Duerme en la madrugada (tope realista), no a las 22:00.
      expect(r.bedtime.isAfter(DateTime(2026, 8, 2, 0, 0)), isTrue);
    });
  });
}
