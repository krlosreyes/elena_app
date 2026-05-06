// Tests unitarios de MetabolicState (SPEC-60 cerrado).
//
// Cubre:
// - CA-60-01: dos llamadas a .empty() son ==.
// - Singleton const _empty (misma referencia en cada llamada).
// - Idempotencia de hashCode.
// - Nullable de lastMealTime y timestamp en estado vacío (Ley de Factories Puras).
//
// Funciones puras: no requieren mocks.

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetabolicState.empty()', () {
    test('CA-60-01: dos llamadas son == y mismo hashCode', () {
      final a = MetabolicState.empty();
      final b = MetabolicState.empty();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('SPEC-60 RF-60-02: retorna la misma instancia singleton', () {
      // Identidad referencial: misma instancia, no solo == iguales.
      final a = MetabolicState.empty();
      final b = MetabolicState.empty();
      expect(identical(a, b), isTrue);
    });

    test('Ley de Factories Puras: lastMealTime y timestamp son null', () {
      final s = MetabolicState.empty();
      expect(s.lastMealTime, isNull);
      expect(s.timestamp, isNull);
    });

    test('valores normalizados conocidos del estado vacío', () {
      final s = MetabolicState.empty();
      expect(s.fastingHours, 0.0);
      expect(s.glycogenLevel, 1.0);
      expect(s.circadianAlignment, 0.5);
      expect(s.sleepQuality, 0.0);
      expect(s.exerciseLoad, 0.0);
      expect(s.glycemicLoad, 0.0);
      expect(s.hydrationLevel, 0.0);
      expect(s.metabolicCoherence, 0.8);
    });

    test('valores crudos del estado vacío', () {
      final s = MetabolicState.empty();
      expect(s.fastingHoursRaw, 0.0);
      expect(s.sleepHoursRaw, 0.0);
      expect(s.exerciseMinutesRaw, 0.0);
      expect(s.nutritionScoreRaw, 0.0);
      expect(s.weeklyAdherence, 0.0);
    });

    test('isComplete es false cuando no hay datos crudos', () {
      expect(MetabolicState.empty().isComplete, isFalse);
    });
  });

  group('MetabolicState construido manualmente', () {
    test('overallScore se calcula como promedio de los 8 normalizados', () {
      final s = MetabolicState(
        fastingHours: 0.5,
        glycogenLevel: 0.5, // contribuye como 1 - 0.5 = 0.5
        circadianAlignment: 1.0,
        sleepQuality: 1.0,
        exerciseLoad: 0.5,
        glycemicLoad: 0.5,
        hydrationLevel: 0.5,
        metabolicCoherence: 1.0,
        fastingHoursRaw: 8.0,
        sleepHoursRaw: 8.0,
        exerciseMinutesRaw: 30.0,
        nutritionScoreRaw: 0.6,
        weeklyAdherence: 0.7,
        lastMealTime: DateTime(2026, 5, 6, 13),
        timestamp: DateTime(2026, 5, 6, 14),
      );
      // Suma = 0.5 + 0.5 + 1 + 1 + 0.5 + 0.5 + 0.5 + 1 = 5.5; /8 = 0.6875
      expect(s.overallScore, closeTo(0.6875, 1e-9));
    });

    test('isComplete es true cuando hay al menos un dato crudo', () {
      final s = MetabolicState(
        fastingHours: 0.0,
        glycogenLevel: 1.0,
        circadianAlignment: 0.5,
        sleepQuality: 0.0,
        exerciseLoad: 0.0,
        glycemicLoad: 0.0,
        hydrationLevel: 0.0,
        metabolicCoherence: 0.8,
        fastingHoursRaw: 0.0,
        sleepHoursRaw: 7.5,
        exerciseMinutesRaw: 0.0,
        nutritionScoreRaw: 0.0,
        weeklyAdherence: 0.0,
        lastMealTime: null,
        timestamp: null,
      );
      expect(s.isComplete, isTrue);
    });
  });
}
