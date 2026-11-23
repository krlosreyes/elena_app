import 'package:elena_app/src/features/glucose/domain/glucose_chart_data.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:flutter_test/flutter_test.dart';

GlucoseReading _r(int v, DateTime at,
        [GlucoseReadingContext c = GlucoseReadingContext.ayunas]) =>
    GlucoseReading(
      id: 'r-${at.millisecondsSinceEpoch}-$v',
      userId: 'u1',
      valueMgDl: v,
      context: c,
      measuredAt: at,
      symptomsReported: const [],
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final now = DateTime(2026, 11, 23, 9);

  group('GlucoseReferenceBands', () {
    test('cortes ADA en ayunas: 70 / 100 / 126', () {
      final b = GlucoseReferenceBands.forContext(GlucoseReadingContext.ayunas)!;
      expect([b.lowBelow, b.inRangeBelow, b.highFrom], [70, 100, 126]);
    });

    test('cortes ADA 2 h: 70 / 140 / 200', () {
      final b = GlucoseReferenceBands.forContext(
          GlucoseReadingContext.postprandial2h)!;
      expect([b.lowBelow, b.inRangeBelow, b.highFrom], [70, 140, 200]);
    });

    test('contextos sin corte ADA no tienen bandas', () {
      for (final c in [
        GlucoseReadingContext.antesDeComer,
        GlucoseReadingContext.postprandial1h,
        GlucoseReadingContext.antesDeDormir,
        GlucoseReadingContext.otro,
      ]) {
        expect(GlucoseReferenceBands.forContext(c), isNull, reason: c.name);
      }
    });

    test('las bandas coinciden con GlucoseClassifier en 40–400 mg/dL', () {
      for (final c in kGlucoseChartContexts) {
        final b = GlucoseReferenceBands.forContext(c)!;
        for (var v = kGlucoseMinPlausibleMgDl;
            v <= kGlucoseMaxPlausibleMgDl;
            v++) {
          expect(b.classify(v), GlucoseClassifier.classify(v, c),
              reason: '${c.name} $v mg/dL');
        }
      }
    });
  });

  group('GlucoseChartData.build', () {
    test('null para un contexto sin corte ADA', () {
      expect(
        GlucoseChartData.build(
          readings: [_r(100, now, GlucoseReadingContext.antesDeDormir)],
          context: GlucoseReadingContext.antesDeDormir,
          windowDays: 30,
          now: now,
        ),
        isNull,
      );
    });

    test('filtra por contexto, ventana y plausibilidad, y ordena por fecha',
        () {
      final data = GlucoseChartData.build(
        readings: [
          _r(110, now.subtract(const Duration(days: 1))),
          _r(90, now.subtract(const Duration(days: 5))),
          _r(150, now.subtract(const Duration(days: 2)),
              GlucoseReadingContext.postprandial2h),
          _r(95, now.subtract(const Duration(days: 31))),
          _r(30, now.subtract(const Duration(days: 3))),
          _r(99, now.add(const Duration(hours: 1))),
        ],
        context: GlucoseReadingContext.ayunas,
        windowDays: 30,
        now: now,
      )!;
      expect(data.points.map((p) => p.valueMgDl), [90, 110]);
      expect(data.windowStart, now.subtract(const Duration(days: 30)));
      expect(data.windowEnd, now);
    });

    test('cuenta por zona, porcentaje en rango, promedio, mínimo y máximo',
        () {
      final data = GlucoseChartData.build(
        readings: [
          _r(65, now.subtract(const Duration(days: 4))),
          _r(85, now.subtract(const Duration(days: 3))),
          _r(95, now.subtract(const Duration(days: 2))),
          _r(110, now.subtract(const Duration(days: 1))),
          _r(130, now),
        ],
        context: GlucoseReadingContext.ayunas,
        windowDays: 14,
        now: now,
      )!;
      expect(data.count, 5);
      expect(data.countOf(GlucoseClassification.bajo), 1);
      expect(data.inRangeCount, 2);
      expect(data.countOf(GlucoseClassification.elevado), 1);
      expect(data.countOf(GlucoseClassification.alto), 1);
      expect(data.inRangePercent, 40);
      expect(data.mean, 97);
      expect(data.minValue, 65);
      expect(data.maxValue, 130);
    });

    test('sin lecturas en la ventana: vacío y sin estadísticas', () {
      final data = GlucoseChartData.build(
        readings: [_r(90, now.subtract(const Duration(days: 40)))],
        context: GlucoseReadingContext.ayunas,
        windowDays: 14,
        now: now,
      )!;
      expect(data.isEmpty, isTrue);
      expect(data.inRangePercent, isNull);
      expect(data.mean, isNull);
    });
  });
}
