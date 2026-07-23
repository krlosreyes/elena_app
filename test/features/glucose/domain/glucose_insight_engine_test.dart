// Módulo "Tu Glucosa" — tests de GlucoseInsightEngine (propuesta §10,
// R8 mínimo de datos). Cubre los 3 correlatos MVP (ayuno, sueño,
// comida) en sus casos happy/insuficiente-datos/sin-diferencia-real,
// y la regla de honestidad del motor: nunca inventar un insight con
// menos de 7 días/lecturas de superposición.

import 'package:elena_app/src/features/glucose/domain/glucose_insight.dart';
import 'package:flutter_test/flutter_test.dart';

GlucoseReadingWithContext _fastingEntry({
  required int value,
  required double fastingHours,
  DateTime? date,
}) =>
    GlucoseReadingWithContext(
      valueMgDl: value,
      isFastingContext: true,
      dayContext: GlucoseDailyContext(
        date: date ?? DateTime(2026, 7, 1),
        fastingHoursCompleted: fastingHours,
      ),
    );

GlucoseReadingWithContext _sleepEntry({
  required int value,
  required double sleepHours,
  required double sleepGoalHours,
  DateTime? date,
}) =>
    GlucoseReadingWithContext(
      valueMgDl: value,
      isFastingContext: true,
      dayContext: GlucoseDailyContext(
        date: date ?? DateTime(2026, 7, 1),
        sleepHours: sleepHours,
        sleepGoalHours: sleepGoalHours,
      ),
    );

GlucoseReadingWithContext _mealEntry({
  required int value,
  required int glycemicIndex,
  DateTime? date,
}) =>
    GlucoseReadingWithContext(
      valueMgDl: value,
      isFastingContext: false,
      isPostprandialContext: true,
      mealGlycemicIndex: glycemicIndex,
      dayContext: GlucoseDailyContext(date: date ?? DateTime(2026, 7, 1)),
    );

void main() {
  group('GlucoseInsightEngine.analyze — sin datos suficientes (R8)', () {
    test('lista vacía → sin insights, sin excepción', () {
      expect(GlucoseInsightEngine.analyze(const []), isEmpty);
    });

    test('menos de 7 días con dato de ayuno → no genera insight de ayuno',
        () {
      final entries = [
        _fastingEntry(value: 90, fastingHours: 14),
        _fastingEntry(value: 100, fastingHours: 6),
        _fastingEntry(value: 92, fastingHours: 15),
        _fastingEntry(value: 98, fastingHours: 5),
        _fastingEntry(value: 91, fastingHours: 13),
        _fastingEntry(value: 97, fastingHours: 7),
        // 6 entradas — uno menos que kMinOverlapDays (7).
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any(
            (i) => i.type == GlucoseInsightType.ayunoVsGlucosaAyunas),
        isFalse,
      );
    });

    test('7 días pero TODOS con ayuno largo (sin grupo de comparación) → '
        'no genera insight', () {
      final entries = List.generate(
        7,
        (i) => _fastingEntry(value: 90 + i, fastingHours: 14),
      );
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any(
            (i) => i.type == GlucoseInsightType.ayunoVsGlucosaAyunas),
        isFalse,
      );
    });
  });

  group('GlucoseInsightEngine.analyze — correlato ayuno↔glucosa', () {
    test('7 días con diferencia real (≥3 mg/dL) → insight preliminar', () {
      final entries = [
        // Ayuno largo (≥12h): glucosa más baja.
        _fastingEntry(value: 88, fastingHours: 14),
        _fastingEntry(value: 90, fastingHours: 13),
        _fastingEntry(value: 89, fastingHours: 15),
        // Ayuno corto (<12h): glucosa más alta.
        _fastingEntry(value: 100, fastingHours: 6),
        _fastingEntry(value: 102, fastingHours: 8),
        _fastingEntry(value: 98, fastingHours: 5),
        _fastingEntry(value: 101, fastingHours: 7),
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      final insight = insights.firstWhere(
          (i) => i.type == GlucoseInsightType.ayunoVsGlucosaAyunas);
      expect(insight.confidence, GlucoseInsightConfidence.preliminar);
      expect(insight.sampleSize, 7);
      expect(insight.evidenceLevel, GlucoseEvidenceLevel.solida);
    });

    test('14+ días → confidence establecido', () {
      final entries = [
        for (int i = 0; i < 7; i++)
          _fastingEntry(value: 88, fastingHours: 14),
        for (int i = 0; i < 7; i++)
          _fastingEntry(value: 100, fastingHours: 6),
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      final insight = insights.firstWhere(
          (i) => i.type == GlucoseInsightType.ayunoVsGlucosaAyunas);
      expect(insight.confidence, GlucoseInsightConfidence.establecido);
      expect(insight.sampleSize, 14);
    });

    test('diferencia menor a 3 mg/dL (ruido) → no reporta insight', () {
      final entries = [
        _fastingEntry(value: 90, fastingHours: 14),
        _fastingEntry(value: 91, fastingHours: 13),
        _fastingEntry(value: 90, fastingHours: 15),
        _fastingEntry(value: 91, fastingHours: 6),
        _fastingEntry(value: 92, fastingHours: 8),
        _fastingEntry(value: 90, fastingHours: 5),
        _fastingEntry(value: 91, fastingHours: 7),
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any(
            (i) => i.type == GlucoseInsightType.ayunoVsGlucosaAyunas),
        isFalse,
      );
    });
  });

  group('GlucoseInsightEngine.analyze — correlato sueño↔glucosa', () {
    test('7 días con sueño corto vs. suficiente → insight', () {
      final entries = [
        _sleepEntry(value: 105, sleepHours: 5, sleepGoalHours: 8),
        _sleepEntry(value: 108, sleepHours: 5.5, sleepGoalHours: 8),
        _sleepEntry(value: 106, sleepHours: 6, sleepGoalHours: 8),
        _sleepEntry(value: 90, sleepHours: 8, sleepGoalHours: 8),
        _sleepEntry(value: 89, sleepHours: 8.5, sleepGoalHours: 8),
        _sleepEntry(value: 91, sleepHours: 9, sleepGoalHours: 8),
        _sleepEntry(value: 88, sleepHours: 8, sleepGoalHours: 8),
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      final insight = insights.firstWhere(
          (i) => i.type == GlucoseInsightType.suenoVsGlucosaAyunas);
      expect(insight.sampleSize, 7);
    });

    test('sin meta de sueño declarada (sleepGoalHours null) → se excluye '
        'del correlato', () {
      final entries = List.generate(
        7,
        (i) => GlucoseReadingWithContext(
          valueMgDl: 90 + i,
          isFastingContext: true,
          dayContext: GlucoseDailyContext(
            date: DateTime(2026, 7, 1 + i),
            sleepHours: 7,
            sleepGoalHours: null,
          ),
        ),
      );
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any((i) => i.type == GlucoseInsightType.suenoVsGlucosaAyunas),
        isFalse,
      );
    });
  });

  group('GlucoseInsightEngine.analyze — correlato comida↔postprandial', () {
    test('7 lecturas con IG alto vs. bajo → insight (unidad: lecturas, '
        'no días — adaptación documentada de R8)', () {
      final entries = [
        _mealEntry(value: 170, glycemicIndex: 80),
        _mealEntry(value: 165, glycemicIndex: 85),
        _mealEntry(value: 175, glycemicIndex: 90),
        _mealEntry(value: 130, glycemicIndex: 40),
        _mealEntry(value: 125, glycemicIndex: 45),
        _mealEntry(value: 128, glycemicIndex: 50),
        _mealEntry(value: 132, glycemicIndex: 55),
      ];
      final insights = GlucoseInsightEngine.analyze(entries);
      final insight = insights.firstWhere(
          (i) => i.type == GlucoseInsightType.comidaVsGlucosaPostprandial);
      expect(insight.sampleSize, 7);
    });

    test('comidas de IG medio (56-69) no cuentan en ningún grupo', () {
      final entries = [
        for (int i = 0; i < 4; i++)
          _mealEntry(value: 150, glycemicIndex: 60), // banda media
        _mealEntry(value: 170, glycemicIndex: 80),
        _mealEntry(value: 130, glycemicIndex: 40),
      ];
      // Solo 2 lecturas cuentan (1 alta + 1 baja) — muy por debajo de 7.
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any((i) =>
            i.type == GlucoseInsightType.comidaVsGlucosaPostprandial),
        isFalse,
      );
    });

    test('contexto no postprandial nunca entra al correlato de comida', () {
      final entries = List.generate(
        7,
        (i) => _fastingEntry(value: 90, fastingHours: 12),
      );
      final insights = GlucoseInsightEngine.analyze(entries);
      expect(
        insights.any((i) =>
            i.type == GlucoseInsightType.comidaVsGlucosaPostprandial),
        isFalse,
      );
    });
  });
}
