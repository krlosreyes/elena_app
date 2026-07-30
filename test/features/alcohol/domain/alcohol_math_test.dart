// SPEC-261: tests de AlcoholMath (matemática pura del alcohol).

import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gramsOfAlcohol', () {
    test('cerveza 355 ml @5% ≈ 14 g', () {
      final g = AlcoholMath.gramsOfAlcohol(volumeMl: 355, abv: 0.05);
      expect(g, closeTo(14.00, 0.05));
    });

    test('trago 44 ml @40% ≈ 13,9 g', () {
      final g = AlcoholMath.gramsOfAlcohol(volumeMl: 44, abv: 0.40);
      expect(g, closeTo(13.89, 0.05));
    });

    test('entradas no positivas → 0', () {
      expect(AlcoholMath.gramsOfAlcohol(volumeMl: 0, abv: 0.40), 0);
      expect(AlcoholMath.gramsOfAlcohol(volumeMl: 100, abv: 0), 0);
      expect(AlcoholMath.gramsOfAlcohol(volumeMl: -1, abv: 0.4), 0);
    });
  });

  group('standardUnits', () {
    test('10 g = 1 UEA', () {
      expect(AlcoholMath.standardUnits(10), 1.0);
    });
    test('14 g = 1,4 UEA', () {
      expect(AlcoholMath.standardUnits(14), closeTo(1.4, 1e-9));
    });
    test('0 o negativo = 0', () {
      expect(AlcoholMath.standardUnits(0), 0);
      expect(AlcoholMath.standardUnits(-5), 0);
    });
  });

  group('eliminación y tiempo', () {
    test('tasa a 70 kg = 7 g/h', () {
      expect(AlcoholMath.eliminationRatePerHour(70), closeTo(7.0, 1e-9));
    });

    test('peso no positivo cae a la referencia (70 kg)', () {
      expect(AlcoholMath.eliminationRatePerHour(0), closeTo(7.0, 1e-9));
      expect(AlcoholMath.eliminationRatePerHour(-10), closeTo(7.0, 1e-9));
    });

    test('14 g a 70 kg ≈ 2 h', () {
      final h = AlcoholMath.hoursToMetabolize(grams: 14, weightKg: 70);
      expect(h, closeTo(2.0, 0.001));
    });

    test('más peso metaboliza más rápido', () {
      final light = AlcoholMath.hoursToMetabolize(grams: 20, weightKg: 55);
      final heavy = AlcoholMath.hoursToMetabolize(grams: 20, weightKg: 90);
      expect(heavy, lessThan(light));
    });

    test('0 g → 0 h', () {
      expect(AlcoholMath.hoursToMetabolize(grams: 0), 0);
    });
  });

  group('estimatedBac', () {
    test('pico sin tiempo transcurrido (hombre, 70 kg)', () {
      final bac = AlcoholMath.estimatedBac(
        grams: 14,
        weightKg: 70,
        sex: WidmarkSex.male,
        hoursElapsed: 0,
      );
      // 14 / (0.68 * 70) = 0.294 g/L
      expect(bac, closeTo(0.294, 0.005));
    });

    test('la mujer alcanza mayor BAC con la misma dosis', () {
      final male = AlcoholMath.estimatedBac(
          grams: 14, weightKg: 70, sex: WidmarkSex.male, hoursElapsed: 0);
      final female = AlcoholMath.estimatedBac(
          grams: 14, weightKg: 70, sex: WidmarkSex.female, hoursElapsed: 0);
      expect(female, greaterThan(male));
    });

    test('nunca es negativo tras metabolizar', () {
      final bac = AlcoholMath.estimatedBac(
        grams: 10,
        weightKg: 70,
        sex: WidmarkSex.male,
        hoursElapsed: 100,
      );
      expect(bac, 0);
    });
  });

  group('formatHours', () {
    test('formatea horas y minutos', () {
      expect(AlcoholMath.formatHours(2.0), '2 h');
      expect(AlcoholMath.formatHours(0.75), '45 min');
      expect(AlcoholMath.formatHours(0), '0 min');
    });
  });
}
