// Tests de StreakEngine.computeNutritionQualityStreak — "Racha de
// Calidad" (25-jul-2026, diferenciador de mercado, ver diagnóstico
// "Pilar Nutrición: dos métricas paralelas").
//
// Cubre: racha simple, ruptura por día bajo el umbral, ruptura por
// hueco de calendario, entradas sin nutritionMagnitude (null) NO
// califican y rompen la cadena (a diferencia de dailyQualityScore, que
// hace fallback), umbral configurable, y que "hoy" incompleto no rompe
// la racha (se cuenta desde ayer) — mismo comportamiento que
// computeCurrentStreak.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ancla fija para que los tests sean deterministas.
  final asOf = DateTime(2026, 7, 25, 12);

  StreakEntry entry(String date, {double? nutritionMagnitude}) => StreakEntry(
        date: date,
        fastingCompleted: false,
        sleepCompleted: false,
        hydrationCompleted: false,
        exerciseLogged: false,
        nutritionLogged: nutritionMagnitude != null,
        imrScore: 0,
        nutritionMagnitude: nutritionMagnitude,
      );

  group('computeNutritionQualityStreak', () {
    test('historial vacío → 0', () {
      expect(StreakEngine.computeNutritionQualityStreak([], asOf: asOf), 0);
    });

    test('3 días consecutivos ≥0.60 terminando hoy → racha 3', () {
      final history = [
        entry('2026-07-23', nutritionMagnitude: 0.70),
        entry('2026-07-24', nutritionMagnitude: 0.65),
        entry('2026-07-25', nutritionMagnitude: 0.80),
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        3,
      );
    });

    test('día bajo el umbral rompe la cadena', () {
      final history = [
        entry('2026-07-22', nutritionMagnitude: 0.90),
        entry('2026-07-23', nutritionMagnitude: 0.20), // rompe acá
        entry('2026-07-24', nutritionMagnitude: 0.65),
        entry('2026-07-25', nutritionMagnitude: 0.80),
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        2,
        reason: 'solo cuentan 24 y 25 — 22 quedó del otro lado de la ruptura',
      );
    });

    test('hueco de calendario rompe la cadena', () {
      final history = [
        entry('2026-07-20', nutritionMagnitude: 0.90),
        // sin 07-21, 07-22
        entry('2026-07-23', nutritionMagnitude: 0.65),
        entry('2026-07-24', nutritionMagnitude: 0.65),
        entry('2026-07-25', nutritionMagnitude: 0.80),
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        3,
      );
    });

    test(
        'nutritionMagnitude null (legacy o sin registro) NO califica — '
        'sin fallback a pillarsCompleted, a diferencia de dailyQualityScore',
        () {
      final history = [
        entry('2026-07-24', nutritionMagnitude: 0.90),
        entry('2026-07-25', nutritionMagnitude: null),
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        0,
        reason: 'hoy (25) no calificó por magnitud null → cuenta desde '
            'ayer, pero ayer tampoco es el día de arranque válido tras '
            'el corte',
      );
    });

    test('hoy incompleto no rompe la racha — se cuenta desde ayer', () {
      final history = [
        entry('2026-07-23', nutritionMagnitude: 0.70),
        entry('2026-07-24', nutritionMagnitude: 0.65),
        entry('2026-07-25', nutritionMagnitude: 0.10), // hoy, bajo umbral
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        2,
        reason: 'mismo comportamiento que computeCurrentStreak: si hoy no '
            'califica, arranca desde ayer',
      );
    });

    test('umbral configurable — 0.75 excluye un día que pasaba con 0.60',
        () {
      final history = [
        entry('2026-07-24', nutritionMagnitude: 0.65),
        entry('2026-07-25', nutritionMagnitude: 0.80),
      ];
      expect(
        StreakEngine.computeNutritionQualityStreak(history,
            asOf: asOf, threshold: 0.60),
        2,
      );
      expect(
        StreakEngine.computeNutritionQualityStreak(history,
            asOf: asOf, threshold: 0.75),
        1,
        reason: 'con umbral 0.75, el 24 (0.65) ya no califica',
      );
    });

    test('exactamente en el umbral SÍ califica (>=, no >)', () {
      final history = [entry('2026-07-25', nutritionMagnitude: 0.60)];
      expect(
        StreakEngine.computeNutritionQualityStreak(history, asOf: asOf),
        1,
      );
    });
  });
}
