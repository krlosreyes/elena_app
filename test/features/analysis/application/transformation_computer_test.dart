// SPEC-148 §RF-148-02 (2026-06-05): tests del TransformationComputer.
//
// Pure Dart — sin Riverpod, sin Firestore. Valida que el computer
// produce el snapshot correcto a partir de listas inyectadas.

import 'package:elena_app/src/features/analysis/application/transformation_computer.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _ago(DateTime now, int days) => now.subtract(Duration(days: days));

String _isoDate(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

BiometricCheckIn _bio(
  DateTime now,
  int daysAgo, {
  double weight = 80.0,
  double? bodyFat,
  double? waist,
}) {
  final at = _ago(now, daysAgo);
  return BiometricCheckIn(
    date: _isoDate(at),
    userId: 'u1',
    weight: weight,
    bodyFatPercentage: bodyFat,
    waistCircumference: waist,
    createdAt: at,
    recordedAt: at,
  );
}

Map<String, dynamic> _imrDoc(
  DateTime now,
  int daysAgo, {
  required int score,
}) {
  return {
    'imrScore': score,
    'computedAt': _ago(now, daysAgo).toIso8601String(),
  };
}

StreakEntry _streakEntry(
  DateTime now,
  int daysAgo, {
  double? sleep,
  double? fasting,
}) {
  return StreakEntry(
    date: _isoDate(_ago(now, daysAgo)),
    fastingCompleted: (fasting ?? 0) >= 0.8,
    sleepCompleted: (sleep ?? 0) >= 0.8,
    hydrationCompleted: false,
    exerciseLogged: false,
    nutritionLogged: false,
    imrScore: 60,
    fastingMagnitude: fasting,
    sleepQualityScore: sleep,
  );
}

void main() {
  final fixedNow = DateTime.utc(2026, 6, 5, 12, 0, 0);

  group('SPEC-148 §RF-148-02 — listas vacías', () {
    test('todas vacías → snapshot.isEmpty', () {
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.isEmpty, isTrue);
      expect(snap.visible, isEmpty);
    });
  });

  group('SPEC-148 §RF-148-02 — biometric delta (peso)', () {
    test('past en ventana 30d + current reciente → delta computado', () {
      // Past hace 30 días = 85kg, current hace 3 días = 84kg → Δ -1.
      final history = [
        _bio(fixedNow, 3, weight: 84.0),
        _bio(fixedNow, 30, weight: 85.0),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: history,
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.weightKg.past, 85.0);
      expect(snap.weightKg.current, 84.0);
      expect(snap.weightKg.delta, -1.0);
      expect(snap.weightKg.hasBoth, isTrue);
    });

    test('sin past en ventana → past null pero current sí', () {
      // Solo current. Past queda null.
      final history = [_bio(fixedNow, 5, weight: 80.0)];
      final snap = TransformationComputer.compute(
        biometricHistory: history,
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.weightKg.past, isNull);
      expect(snap.weightKg.current, 80.0);
      expect(snap.weightKg.delta, isNull);
      expect(snap.weightKg.hasBoth, isFalse);
    });

    test('past fuera de ventana (40 días) → past null', () {
      final history = [
        _bio(fixedNow, 3, weight: 80.0),
        _bio(fixedNow, 40, weight: 85.0), // fuera de [25, 35]
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: history,
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.weightKg.past, isNull);
      expect(snap.weightKg.current, 80.0);
    });

    test('campo bodyFat opcional null → delta null para bodyFat solo', () {
      // Past tiene bodyFat, current no.
      final history = [
        _bio(fixedNow, 3, weight: 80.0), // current sin bodyFat
        _bio(fixedNow, 30, weight: 80.0, bodyFat: 22.0),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: history,
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.weightKg.hasBoth, isTrue);
      expect(snap.bodyFatPct.current, isNull); // no medida reciente
      expect(snap.bodyFatPct.hasBoth, isFalse);
    });

    test('cintura: past y current con valor → delta correcto', () {
      final history = [
        _bio(fixedNow, 3, weight: 80.0, waist: 94.0),
        _bio(fixedNow, 30, weight: 80.0, waist: 96.0),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: history,
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.waistCm.past, 96.0);
      expect(snap.waistCm.current, 94.0);
      expect(snap.waistCm.delta, -2.0);
    });
  });

  group('SPEC-148 §RF-148-02 — IMR delta', () {
    test('imr_history con past y current → delta computado', () {
      final history = [
        _imrDoc(fixedNow, 2, score: 64),
        _imrDoc(fixedNow, 30, score: 58),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: history,
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.imr.past, 58);
      expect(snap.imr.current, 64);
      expect(snap.imr.delta, 6);
    });

    test('imr_history vacío → ambos null', () {
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: fixedNow,
      );
      expect(snap.imr.hasBoth, isFalse);
    });
  });

  group('SPEC-148 §RF-148-02 — sleep average', () {
    test('promedio últimos 30d vs 30d previos', () {
      // 5 entradas recientes con sleep 0.875 (7h), 5 entradas hace 30-60d
      // con sleep 0.625 (5h).
      final history = <StreakEntry>[];
      for (var i = 0; i < 5; i++) {
        history.add(_streakEntry(fixedNow, i, sleep: 0.875));
      }
      for (var i = 35; i < 40; i++) {
        history.add(_streakEntry(fixedNow, i, sleep: 0.625));
      }
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: history,
        now: fixedNow,
      );
      expect(snap.sleepHoursAvg.current, closeTo(7.0, 0.01));
      expect(snap.sleepHoursAvg.past, closeTo(5.0, 0.01));
    });
  });

  group('SPEC-148 §RF-148-02 — fasting days/7', () {
    test('5 días recientes cumplidos + 2 días hace 30d cumplidos', () {
      final history = <StreakEntry>[];
      for (var i = 0; i < 5; i++) {
        history.add(_streakEntry(fixedNow, i, fasting: 0.85));
      }
      for (var i = 30; i < 32; i++) {
        history.add(_streakEntry(fixedNow, i, fasting: 0.90));
      }
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: history,
        now: fixedNow,
      );
      expect(snap.fastingDaysOf7.current, 5);
      expect(snap.fastingDaysOf7.past, 2);
      expect(snap.fastingDaysOf7.delta, 3);
    });
  });

  group('SPEC-148 — case usuario completo', () {
    test('snapshot tiene los 6 indicadores con datos', () {
      final bioHistory = [
        _bio(fixedNow, 3, weight: 84.0, bodyFat: 22.0, waist: 94.0),
        _bio(fixedNow, 30, weight: 85.2, bodyFat: 23.5, waist: 96.0),
      ];
      final imrHistory = [
        _imrDoc(fixedNow, 2, score: 64),
        _imrDoc(fixedNow, 30, score: 58),
      ];
      final streakHistory = <StreakEntry>[];
      for (var i = 0; i < 7; i++) {
        streakHistory.add(_streakEntry(
          fixedNow,
          i,
          sleep: 0.85,
          fasting: 0.85,
        ));
      }
      for (var i = 30; i < 37; i++) {
        streakHistory.add(_streakEntry(
          fixedNow,
          i,
          sleep: 0.625,
          fasting: 0.50,
        ));
      }
      final snap = TransformationComputer.compute(
        biometricHistory: bioHistory,
        imrHistory: imrHistory,
        streakHistory: streakHistory,
        now: fixedNow,
      );
      expect(snap.weightKg.hasBoth, isTrue);
      expect(snap.imr.hasBoth, isTrue);
      expect(snap.waistCm.hasBoth, isTrue);
      expect(snap.bodyFatPct.hasBoth, isTrue);
      expect(snap.sleepHoursAvg.hasBoth, isTrue);
      expect(snap.fastingDaysOf7.hasBoth, isTrue);
      // SPEC-138: sin nutritionHistory inyectada, upfSharePct queda
      // empty → no entra a visible. Conteo sigue siendo 6.
      expect(snap.upfSharePct.hasBoth, isFalse);
      expect(snap.visible.length, 6);
    });
  });

  // ── SPEC-138 §16.4: delta UPF ────────────────────────────────────────

  NutritionLog nLog(DateTime now, int daysAgo,
      {int? upfSlots, int? totalSlots}) {
    return NutritionLog(
      id: 'log-$daysAgo',
      timestamp: _ago(now, daysAgo),
      label: 'Almuerzo',
      withinCircadianWindow: true,
      upfSlots: upfSlots,
      totalSlots: totalSlots,
    );
  }

  group('SPEC-138 §16.4 — _upfDelta', () {
    test('sin nutritionHistory → upfSharePct empty', () {
      final now = DateTime(2026, 6, 5, 12);
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: now,
        // nutritionHistory: default const []
      );
      expect(snap.upfSharePct.past, isNull);
      expect(snap.upfSharePct.current, isNull);
      expect(snap.upfSharePct.hasBoth, isFalse);
    });

    test('pocos logs (<3) en cada ventana → ambos lados null', () {
      final now = DateTime(2026, 6, 5, 12);
      final logs = [
        nLog(now, 1, upfSlots: 1, totalSlots: 4),
        nLog(now, 30, upfSlots: 2, totalSlots: 5),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: now,
        nutritionHistory: logs,
      );
      expect(snap.upfSharePct.past, isNull);
      expect(snap.upfSharePct.current, isNull);
    });

    test('5 logs en ambas ventanas → delta visible', () {
      final now = DateTime(2026, 6, 5, 12);
      final logs = <NutritionLog>[
        // Ventana current: días 1-7. 5 logs con datos NOVA.
        // 5 platos con (1/4) = 25% cada uno → agregado 25%.
        for (int d = 1; d <= 5; d++) nLog(now, d, upfSlots: 1, totalSlots: 4),
        // Ventana past: días 28-35. 5 logs con (3/4) = 75% cada uno → 75%.
        for (int d = 28; d <= 32; d++) nLog(now, d, upfSlots: 3, totalSlots: 4),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: now,
        nutritionHistory: logs,
      );
      expect(snap.upfSharePct.past, 75);
      expect(snap.upfSharePct.current, 25);
      expect(snap.upfSharePct.hasBoth, isTrue);
      // delta = current - past = 25 - 75 = -50 → mejora.
      expect(snap.upfSharePct.delta, -50);
    });

    test('logs pre-138 (sin NOVA) en current → current null', () {
      final now = DateTime(2026, 6, 5, 12);
      final logs = <NutritionLog>[
        // 5 logs pre-138 en ventana current (sin NOVA)
        for (int d = 1; d <= 5; d++) nLog(now, d),
        // 5 logs NOVA en ventana past
        for (int d = 28; d <= 32; d++) nLog(now, d, upfSlots: 0, totalSlots: 5),
      ];
      final snap = TransformationComputer.compute(
        biometricHistory: const [],
        imrHistory: const [],
        streakHistory: const [],
        now: now,
        nutritionHistory: logs,
      );
      expect(snap.upfSharePct.current, isNull,
          reason: 'sin NOVA en current, no opinamos');
      expect(snap.upfSharePct.past, 0);
    });
  });
}
