// SPEC-261.5: tests del motor en SERVIDAS físicas + tope por peso/sexo.

import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_recommendation.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vino = DrinkTypes.byId('vino')!; // copa 150 ml, ~1,54 UEA
  final cerveza = DrinkTypes.byId('cerveza')!; // 330 ml carbonatado
  final aguardiente = DrinkTypes.byId('aguardiente')!; // trago 30 ml
  final restBedtime = DateTime(2026, 8, 2, 2, 0); // madrugada

  DrinkRecommendation vinoAt(
    DateTime start, {
    double weightKg = 70,
    WidmarkSex sex = WidmarkSex.male,
  }) =>
      DrinkRecommendation.compute(
        type: vino,
        weightKg: weightKg,
        sex: sex,
        startTime: start,
        worksTomorrow: false,
        habitualBedtime: restBedtime,
      );

  group('cuenta en servidas físicas, no UEA', () {
    test('vino 70 kg hombre, ventana 5 h → 2 copas, ~2 h 12 min', () {
      final r = vinoAt(DateTime(2026, 8, 1, 18, 0));
      expect(r.drinks, 2); // 2 COPAS reales, no 2 UEA
      expect(r.spacingMinutes, 132); // 86 min/UEA × 1,54 UEA/copa
      expect(r.servingLabel, 'copa de vino (150 ml)');
      expect(r.waterGlasses, 2);
      expect(r.tight, isFalse);
      // budgetUnits es UEA (para el tracking): 2 copas × ~1,54.
      expect(r.budgetUnits, closeTo(3.08, 0.05));
    });

    test('último trago 3 h antes de dormir', () {
      final r = vinoAt(DateTime(2026, 8, 1, 18, 0));
      expect(r.bedtime.difference(r.lastCall), const Duration(hours: 3));
    });
  });

  group('tope personalizado por peso y sexo', () {
    test('ventana larga: mujer 60 kg recibe menos que hombre 80 kg', () {
      final start = DateTime(2026, 8, 1, 14, 0); // ventana ~9 h (tope manda)
      final hombre = vinoAt(start, weightKg: 80, sex: WidmarkSex.male);
      final mujer = vinoAt(start, weightKg: 60, sex: WidmarkSex.female);
      expect(mujer.drinks, lessThan(hombre.drinks));
      expect(mujer.budgetUnits, lessThan(hombre.budgetUnits));
    });
  });

  group('realismo y guardas', () {
    test('descanso con hábito temprano (22:00) NO colapsa la ventana', () {
      final r = DrinkRecommendation.compute(
        type: cerveza,
        weightKg: 70,
        sex: WidmarkSex.male,
        startTime: DateTime(2026, 8, 1, 20, 0),
        worksTomorrow: false,
        habitualBedtime: DateTime(2026, 8, 1, 22, 0),
      );
      expect(r.drinks, greaterThan(0));
      expect(r.lastCall.isAfter(DateTime(2026, 8, 1, 20, 0)), isTrue);
      expect(r.bedtime.isAfter(DateTime(2026, 8, 2, 0, 0)), isTrue);
    });

    test('piso de espaciado: nunca un shot cada <45 min', () {
      final r = DrinkRecommendation.compute(
        type: aguardiente, // servida chica → espaciado tiende a bajar
        weightKg: 120, // metaboliza rápido → espaciado por UEA bajo
        sex: WidmarkSex.male,
        startTime: DateTime(2026, 8, 1, 18, 0),
        worksTomorrow: false,
        habitualBedtime: restBedtime,
      );
      expect(r.spacingMinutes, greaterThanOrEqualTo(45));
    });

    test('inicio tarde (22:00) NO manda el dormir a la noche siguiente', () {
      // Regresión: antes bedtime saltaba a 22:00 del día siguiente (24 h) y el
      // plan mostraba horas absurdas (último trago antes del inicio).
      final r = vinoAt(DateTime(2026, 8, 1, 22, 0)); // sale a las 22:00
      expect(
          r.bedtime, DateTime(2026, 8, 2, 2, 0)); // dormir 02:00 esa madrugada
      expect(r.bedtime.difference(r.lastCall), const Duration(hours: 3));
      expect(r.tight, isTrue); // ventana chiquita: 0–1 servidas
    });

    test('noche laboral (madrugas 7:00) → plan mínimo', () {
      final r = DrinkRecommendation.compute(
        type: vino,
        weightKg: 70,
        sex: WidmarkSex.male,
        startTime: DateTime(2026, 8, 1, 20, 0),
        worksTomorrow: true,
        wakeTime: DateTime(2026, 8, 2, 7, 0),
        habitualBedtime: restBedtime,
      );
      expect(r.tight, isTrue);
      expect(r.drinks, lessThanOrEqualTo(1));
    });
  });
}
