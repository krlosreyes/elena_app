// Módulo "Tu Glucosa" — tests de GlucoseReading: getters derivados
// (hasSymptoms/isPlausible) y roundtrip toMap/fromMap (regresión: un
// fromMap(toMap(x)) debe reproducir x campo a campo, igual que el
// resto de modelos planos de la app — ExerciseProfile, StreakEntry).

import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:flutter_test/flutter_test.dart';

GlucoseReading _reading({
  int valueMgDl = 95,
  GlucoseReadingContext context = GlucoseReadingContext.ayunas,
  List<GlucoseSymptom> symptoms = const [],
}) {
  final now = DateTime(2026, 7, 23, 7, 15);
  return GlucoseReading(
    id: 'r1',
    userId: 'u1',
    valueMgDl: valueMgDl,
    context: context,
    measuredAt: now,
    minutesSinceLastMeal: 90,
    minutesSinceWaking: 15,
    relatedFastingHours: 14.5,
    relatedSleepHours: 7.2,
    relatedSleepGoalHours: 8.0,
    mealGlycemicIndex: 62,
    symptomsReported: symptoms,
    note: 'nota de prueba',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GlucoseReading.hasSymptoms', () {
    test('lista vacía → false', () {
      expect(_reading(symptoms: const []).hasSymptoms, isFalse);
    });

    test('[ninguno] → false (caso explícito, no solo vacío)', () {
      expect(
        _reading(symptoms: const [GlucoseSymptom.ninguno]).hasSymptoms,
        isFalse,
      );
    });

    test('con al menos un síntoma real → true', () {
      expect(
        _reading(symptoms: const [GlucoseSymptom.mareo]).hasSymptoms,
        isTrue,
      );
    });

    test('[ninguno, mareo] → true (mezcla cuenta como síntomas reales)', () {
      expect(
        _reading(symptoms: const [
          GlucoseSymptom.ninguno,
          GlucoseSymptom.mareo,
        ]).hasSymptoms,
        isTrue,
      );
    });
  });

  group('GlucoseReading.isPlausible (R9)', () {
    test('dentro de 40-400 → true', () {
      expect(_reading(valueMgDl: 40).isPlausible, isTrue);
      expect(_reading(valueMgDl: 400).isPlausible, isTrue);
    });

    test('fuera de 40-400 → false', () {
      expect(_reading(valueMgDl: 39).isPlausible, isFalse);
      expect(_reading(valueMgDl: 401).isPlausible, isFalse);
    });
  });

  group('GlucoseReading toMap/fromMap — roundtrip', () {
    test('reproduce todos los campos exactamente', () {
      final original = _reading(symptoms: const [GlucoseSymptom.temblor]);
      final rebuilt =
          GlucoseReading.fromMap(original.id, original.toMap());

      expect(rebuilt.id, original.id);
      expect(rebuilt.userId, original.userId);
      expect(rebuilt.valueMgDl, original.valueMgDl);
      expect(rebuilt.context, original.context);
      expect(rebuilt.measuredAt, original.measuredAt);
      expect(rebuilt.minutesSinceLastMeal, original.minutesSinceLastMeal);
      expect(rebuilt.minutesSinceWaking, original.minutesSinceWaking);
      expect(rebuilt.relatedFastingHours, original.relatedFastingHours);
      expect(rebuilt.relatedSleepHours, original.relatedSleepHours);
      expect(
          rebuilt.relatedSleepGoalHours, original.relatedSleepGoalHours);
      expect(rebuilt.mealGlycemicIndex, original.mealGlycemicIndex);
      expect(rebuilt.symptomsReported, original.symptomsReported);
      expect(rebuilt.note, original.note);
      expect(rebuilt.source, original.source);
      expect(rebuilt.createdAt, original.createdAt);
      expect(rebuilt.updatedAt, original.updatedAt);
    });

    test('fromMap con campos nulos/faltantes cae a defaults seguros, sin '
        'lanzar excepción', () {
      final rebuilt = GlucoseReading.fromMap('r2', const {});
      expect(rebuilt.userId, '');
      expect(rebuilt.valueMgDl, 0);
      expect(rebuilt.context, GlucoseReadingContext.otro);
      expect(rebuilt.symptomsReported, isEmpty);
      expect(rebuilt.source, GlucoseSource.manual);
    });

    test('fromMap con nombre de enum desconocido cae al fallback '
        '("otro"/"ninguno"), no revienta', () {
      final map = _reading().toMap()..['context'] = 'algo_inventado';
      final rebuilt = GlucoseReading.fromMap('r3', map);
      expect(rebuilt.context, GlucoseReadingContext.otro);
    });
  });

  group('GlucoseReading.copyWith', () {
    test('sin argumentos devuelve valores equivalentes', () {
      final original = _reading();
      final copy = original.copyWith();
      expect(copy.valueMgDl, original.valueMgDl);
      expect(copy.context, original.context);
    });

    test('cambia solo el campo indicado', () {
      final original = _reading(valueMgDl: 95);
      final copy = original.copyWith(valueMgDl: 110);
      expect(copy.valueMgDl, 110);
      expect(copy.userId, original.userId);
      expect(copy.measuredAt, original.measuredAt);
    });
  });
}
