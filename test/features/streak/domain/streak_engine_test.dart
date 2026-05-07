// Tests unitarios de StreakEngine + StreakEntry (SPEC-65).
//
// Cubre:
// - Evaluadores por pilar (umbrales documentados).
// - StreakEntry.pillarsCompleted (booleans).
// - StreakEntry.dailyQualityScore + magnitudes (SPEC-65).
// - computeLongestStreak con historial sintético.
// - Round-trip JSON con magnitudes.
//
// Funciones puras: no requieren mocks ni reloj.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evaluadores por pilar', () {
    test('evaluateFasting con protocolo 16:8: requiere ≥ 12.8h', () {
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 12.8, fastingProtocol: '16:8'),
          isTrue);
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 12.7, fastingProtocol: '16:8'),
          isFalse);
    });

    test('evaluateFasting con protocolo Ninguno: requiere ≥ 10h', () {
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 10, fastingProtocol: 'Ninguno'),
          isTrue);
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 9.99, fastingProtocol: 'Ninguno'),
          isFalse);
    });

    test('evaluateSleep: requiere ≥ 6.5h (umbral AASM)', () {
      expect(StreakEngine.evaluateSleep(sleepHours: 6.5), isTrue);
      expect(StreakEngine.evaluateSleep(sleepHours: 6.4), isFalse);
    });

    test('evaluateHydration: requiere ≥ 75% de la meta', () {
      expect(
          StreakEngine.evaluateHydration(progressPercentage: 0.75), isTrue);
      expect(
          StreakEngine.evaluateHydration(progressPercentage: 0.74), isFalse);
    });

    test('evaluateExercise: requiere ≥ 20 min (dosis mínima ACSM)', () {
      expect(StreakEngine.evaluateExercise(exerciseMinutes: 20), isTrue);
      expect(StreakEngine.evaluateExercise(exerciseMinutes: 19), isFalse);
    });

    test('evaluateNutrition: requiere ≥ 1 comida registrada', () {
      expect(StreakEngine.evaluateNutrition(mealsLogged: 1), isTrue);
      expect(StreakEngine.evaluateNutrition(mealsLogged: 0), isFalse);
    });
  });

  group('StreakEntry.qualifiesForStreak', () {
    StreakEntry make({
      bool fasting = false,
      bool sleep = false,
      bool hydration = false,
      bool exercise = false,
      bool nutrition = false,
      int imr = 0,
    }) =>
        StreakEntry(
          date: '2026-05-06',
          fastingCompleted: fasting,
          sleepCompleted: sleep,
          hydrationCompleted: hydration,
          exerciseLogged: exercise,
          nutritionLogged: nutrition,
          imrScore: imr,
        );

    test('Cero pilares: no califica', () {
      expect(make().pillarsCompleted, 0);
      expect(make().qualifiesForStreak, isFalse);
    });

    test('2 pilares: aún no califica', () {
      final e = make(fasting: true, sleep: true);
      expect(e.pillarsCompleted, 2);
      expect(e.qualifiesForStreak, isFalse);
    });

    test('3 pilares: califica (umbral SPEC-06)', () {
      final e = make(fasting: true, sleep: true, hydration: true);
      expect(e.pillarsCompleted, 3);
      expect(e.qualifiesForStreak, isTrue);
    });

    test('5 pilares + IMR alto: engaged (SPEC-07)', () {
      final e = make(
        fasting: true,
        sleep: true,
        hydration: true,
        exercise: true,
        nutrition: true,
        imr: 75,
      );
      expect(e.pillarsCompleted, 5);
      expect(e.qualifiesForStreak, isTrue);
      expect(e.isEngaged, isTrue);
    });

    test('IMR bajo (< 60) NO está engaged aunque califique', () {
      final e = make(
        fasting: true,
        sleep: true,
        hydration: true,
        imr: 50,
      );
      expect(e.qualifiesForStreak, isTrue);
      expect(e.isEngaged, isFalse);
    });
  });

  group('computeLongestStreak', () {
    StreakEntry day(String date,
            {bool ok = true, int imr = 70, int pillars = 3}) =>
        StreakEntry(
          date: date,
          fastingCompleted: ok && pillars >= 1,
          sleepCompleted: ok && pillars >= 2,
          hydrationCompleted: ok && pillars >= 3,
          exerciseLogged: ok && pillars >= 4,
          nutritionLogged: ok && pillars >= 5,
          imrScore: imr,
        );

    test('Historial vacío -> 0', () {
      expect(StreakEngine.computeLongestStreak([]), 0);
    });

    test('1 día calificado -> 1', () {
      expect(StreakEngine.computeLongestStreak([day('2026-05-01')]), 1);
    });

    test('3 días consecutivos calificados -> 3', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        day('2026-05-03'),
      ];
      expect(StreakEngine.computeLongestStreak(h), 3);
    });

    test('Brecha rompe la racha -> max de los segmentos', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        // Salto el 03
        day('2026-05-04'),
        day('2026-05-05'),
        day('2026-05-06'),
        day('2026-05-07'),
      ];
      // Segmento 1: 2 días (01-02). Segmento 2: 4 días (04-07).
      expect(StreakEngine.computeLongestStreak(h), 4);
    });

    test('Día no calificado en medio rompe la racha', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        day('2026-05-03', pillars: 1), // 1 pilar, no califica
        day('2026-05-04'),
        day('2026-05-05'),
      ];
      expect(StreakEngine.computeLongestStreak(h), 2);
    });
  });

  group('SPEC-65: dailyQualityScore con magnitudes', () {
    StreakEntry entry({
      double? fastingMag,
      double? sleepScore,
      double? hydrationMag,
      double? exerciseMag,
      double? nutritionMag,
      bool legacy = false,
      int pillars = 0,
    }) =>
        StreakEntry(
          date: '2026-05-01',
          fastingCompleted: pillars >= 1,
          sleepCompleted: pillars >= 2,
          hydrationCompleted: pillars >= 3,
          exerciseLogged: pillars >= 4,
          nutritionLogged: pillars >= 5,
          imrScore: 70,
          fastingMagnitude: legacy ? null : fastingMag,
          sleepQualityScore: legacy ? null : sleepScore,
          hydrationMagnitude: legacy ? null : hydrationMag,
          exerciseMagnitude: legacy ? null : exerciseMag,
          nutritionMagnitude: legacy ? null : nutritionMag,
        );

    test('Todas las magnitudes en 1.0 → dailyQualityScore = 1.0', () {
      final e = entry(
        fastingMag: 1.0,
        sleepScore: 1.0,
        hydrationMag: 1.0,
        exerciseMag: 1.0,
        nutritionMag: 1.0,
      );
      expect(e.dailyQualityScore, 1.0);
      expect(e.hasMagnitudes, isTrue);
    });

    test('Todas las magnitudes en 0.0 → dailyQualityScore = 0.0', () {
      final e = entry(
        fastingMag: 0.0,
        sleepScore: 0.0,
        hydrationMag: 0.0,
        exerciseMag: 0.0,
        nutritionMag: 0.0,
      );
      expect(e.dailyQualityScore, 0.0);
    });

    test('Magnitudes superiores a 1.0 se clampean (no inflan score)', () {
      final e = entry(
        fastingMag: 1.5, // Overachiever
        sleepScore: 1.0,
        hydrationMag: 2.0,
        exerciseMag: 3.0,
        nutritionMag: 1.0,
      );
      expect(e.dailyQualityScore, 1.0);
    });

    test('Renormalización: solo sueño en 1.0 → score = 1.0', () {
      // Solo sueño presente — peso renormalizado a 1.0 sobre sí mismo.
      final e = entry(sleepScore: 1.0);
      expect(e.dailyQualityScore, 1.0);
    });

    test('Renormalización: sueño 1.0 + ayuno 0.5 → ≈0.78', () {
      // wSleep=0.25, wFasting=0.20. total=0.45.
      // weighted = 0.25*1.0 + 0.20*0.5 = 0.35.
      // result = 0.35/0.45 = 0.7777...
      final e = entry(sleepScore: 1.0, fastingMag: 0.5);
      expect(e.dailyQualityScore, closeTo(0.35 / 0.45, 1e-9));
    });

    test('Entrada legacy (sin magnitudes) → fallback pillars/5', () {
      final e = entry(legacy: true, pillars: 3);
      expect(e.hasMagnitudes, isFalse);
      expect(e.dailyQualityScore, 0.6);
    });

    test('Entrada legacy con 0 pilares → 0.0', () {
      final e = entry(legacy: true, pillars: 0);
      expect(e.dailyQualityScore, 0.0);
    });

    test('Entrada legacy con 5 pilares → 1.0', () {
      final e = entry(legacy: true, pillars: 5);
      expect(e.dailyQualityScore, 1.0);
    });

    test('Resultado siempre clamped en [0.0, 1.0]', () {
      final e = entry(
        fastingMag: -0.5,
        sleepScore: 2.0,
        hydrationMag: -1.0,
        exerciseMag: 5.0,
        nutritionMag: -10.0,
      );
      expect(e.dailyQualityScore, greaterThanOrEqualTo(0.0));
      expect(e.dailyQualityScore, lessThanOrEqualTo(1.0));
    });
  });

  group('SPEC-65: serialización JSON con magnitudes', () {
    test('Round-trip preserva todas las magnitudes', () {
      final original = StreakEntry(
        date: '2026-05-01',
        fastingCompleted: true,
        sleepCompleted: true,
        hydrationCompleted: true,
        exerciseLogged: false,
        nutritionLogged: true,
        imrScore: 72,
        fastingMagnitude: 0.85,
        sleepQualityScore: 0.92,
        hydrationMagnitude: 0.78,
        exerciseMagnitude: 0.40,
        nutritionMagnitude: 0.66,
      );
      final round = StreakEntry.fromJson(original.toJson());
      expect(round, original);
      expect(round.fastingMagnitude, 0.85);
      expect(round.sleepQualityScore, 0.92);
    });

    test('toJson omite magnitudes nulas', () {
      final e = StreakEntry(
        date: '2026-05-01',
        fastingCompleted: true,
        sleepCompleted: false,
        hydrationCompleted: true,
        exerciseLogged: false,
        nutritionLogged: false,
        imrScore: 50,
      );
      final json = e.toJson();
      expect(json.containsKey('fastingMagnitude'), isFalse);
      expect(json.containsKey('sleepQualityScore'), isFalse);
    });

    test('fromJson tolera ausencia de magnitudes (entrada legacy)', () {
      final json = <String, dynamic>{
        'date': '2025-12-01',
        'fastingCompleted': true,
        'sleepCompleted': true,
        'hydrationCompleted': true,
        'exerciseLogged': false,
        'nutritionLogged': false,
        'imrScore': 65,
      };
      final e = StreakEntry.fromJson(json);
      expect(e.fastingMagnitude, isNull);
      expect(e.sleepQualityScore, isNull);
      expect(e.hasMagnitudes, isFalse);
      // Fallback: 3 pilares completados → 0.6
      expect(e.dailyQualityScore, 0.6);
    });

    test('fromJson convierte int a double en magnitudes', () {
      final json = <String, dynamic>{
        'date': '2026-05-01',
        'fastingCompleted': true,
        'sleepCompleted': true,
        'hydrationCompleted': true,
        'exerciseLogged': true,
        'nutritionLogged': true,
        'imrScore': 80,
        'fastingMagnitude': 1, // entero — Firestore puede serializar así
      };
      final e = StreakEntry.fromJson(json);
      expect(e.fastingMagnitude, 1.0);
      expect(e.fastingMagnitude, isA<double>());
    });
  });

  group('SPEC-65: copyWith preserva y actualiza magnitudes', () {
    final base = StreakEntry(
      date: '2026-05-01',
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: false,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 60,
      fastingMagnitude: 0.8,
      sleepQualityScore: 0.9,
    );

    test('Sin args → copia idéntica', () {
      expect(base.copyWith(), base);
    });

    test('Actualiza magnitud específica sin tocar otras', () {
      final updated = base.copyWith(fastingMagnitude: 1.0);
      expect(updated.fastingMagnitude, 1.0);
      expect(updated.sleepQualityScore, 0.9);
    });
  });

  group('SPEC-53: computeWeeklyQualityScore', () {
    /// Crea una entrada con todas las magnitudes a un mismo valor `q`
    /// y fecha `date`. Útil para construir historiales donde el
    /// `dailyQualityScore` resultante coincide con `q`.
    StreakEntry uniformEntry(String date, double q) => StreakEntry(
          date: date,
          fastingCompleted: q >= 0.5,
          sleepCompleted: q >= 0.5,
          hydrationCompleted: q >= 0.5,
          exerciseLogged: q >= 0.5,
          nutritionLogged: q >= 0.5,
          imrScore: 70,
          fastingMagnitude: q,
          sleepQualityScore: q,
          hydrationMagnitude: q,
          exerciseMagnitude: q,
          nutritionMagnitude: q,
        );

    /// Clave de fecha relativa a hoy (0 = hoy, -1 = ayer, etc.).
    String dayKey(int offset) {
      final d = DateTime.now().add(Duration(days: offset));
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    test('Historial vacío → 0.0', () {
      expect(StreakEngine.computeWeeklyQualityScore([]), 0.0);
    });

    test('Solo entradas fuera de la ventana de 7 días → 0.0', () {
      // Entradas hace más de 7 días.
      final old = [
        uniformEntry(dayKey(-15), 1.0),
        uniformEntry(dayKey(-30), 1.0),
      ];
      expect(StreakEngine.computeWeeklyQualityScore(old), 0.0);
    });

    test('Una entrada en la ventana con q=0.8 → 0.8', () {
      final h = [uniformEntry(dayKey(-2), 0.8)];
      expect(
        StreakEngine.computeWeeklyQualityScore(h),
        closeTo(0.8, 1e-9),
      );
    });

    test('7 días llenos al tope → 1.0', () {
      final h = List.generate(7, (i) => uniformEntry(dayKey(-i), 1.0));
      expect(StreakEngine.computeWeeklyQualityScore(h), 1.0);
    });

    test('Promedio: 4 días a 1.0 + 3 días a 0.0 → 4/7', () {
      final h = [
        uniformEntry(dayKey(0), 1.0),
        uniformEntry(dayKey(-1), 1.0),
        uniformEntry(dayKey(-2), 1.0),
        uniformEntry(dayKey(-3), 1.0),
        uniformEntry(dayKey(-4), 0.0),
        uniformEntry(dayKey(-5), 0.0),
        uniformEntry(dayKey(-6), 0.0),
      ];
      expect(
        StreakEngine.computeWeeklyQualityScore(h),
        closeTo(4.0 / 7.0, 1e-9),
      );
    });

    test('Mezcla legacy (sin magnitudes) + modernas usa fallback', () {
      // Día legacy con 5 pilares completados → fallback 1.0.
      final legacy = StreakEntry(
        date: dayKey(-1),
        fastingCompleted: true,
        sleepCompleted: true,
        hydrationCompleted: true,
        exerciseLogged: true,
        nutritionLogged: true,
        imrScore: 80,
      );
      // Día moderno con magnitudes promedio 0.5.
      final modern = uniformEntry(dayKey(0), 0.5);

      final score = StreakEngine.computeWeeklyQualityScore([legacy, modern]);
      // (1.0 + 0.5) / 2 = 0.75
      expect(score, closeTo(0.75, 1e-9));
    });

    test('Divisor es nº de entradas en ventana, NO 7 (no penaliza usuario nuevo)',
        () {
      // Solo 3 días registrados, todos al tope → 1.0 (no 3/7).
      final h = [
        uniformEntry(dayKey(0), 1.0),
        uniformEntry(dayKey(-1), 1.0),
        uniformEntry(dayKey(-2), 1.0),
      ];
      expect(StreakEngine.computeWeeklyQualityScore(h), 1.0);
    });

    test('Resultado siempre clamped en [0.0, 1.0]', () {
      final h = [uniformEntry(dayKey(-1), 1.5)]; // valor fuera de rango
      final score = StreakEngine.computeWeeklyQualityScore(h);
      expect(score, lessThanOrEqualTo(1.0));
      expect(score, greaterThanOrEqualTo(0.0));
    });
  });
}
