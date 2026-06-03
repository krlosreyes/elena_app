// SPEC-152: tests del enum BodyCompositionMetric.

import 'package:elena_app/src/features/analysis/domain/body_composition_metric.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

BiometricCheckIn _checkIn({
  required double weight,
  double? waist,
  double? bodyFat,
}) {
  return BiometricCheckIn(
    date: '2026-06-02',
    userId: 'u1',
    weight: weight,
    waistCircumference: waist,
    bodyFatPercentage: bodyFat,
    createdAt: DateTime(2026, 6, 2),
  );
}

void main() {
  group('SPEC-152 — BodyCompositionMetric.selectValue', () {
    test('weight retorna peso del check-in', () {
      final ci = _checkIn(weight: 84.3);
      expect(BodyCompositionMetric.weight.selectValue(ci), 84.3);
    });

    test('waistCm retorna cintura cuando está presente', () {
      final ci = _checkIn(weight: 80, waist: 92.5);
      expect(BodyCompositionMetric.waistCm.selectValue(ci), 92.5);
    });

    test('waistCm retorna null cuando cintura no se registró', () {
      final ci = _checkIn(weight: 80);
      expect(BodyCompositionMetric.waistCm.selectValue(ci), isNull);
    });

    test('bodyFatPct retorna % grasa cuando está presente', () {
      final ci = _checkIn(weight: 80, bodyFat: 22.4);
      expect(BodyCompositionMetric.bodyFatPct.selectValue(ci), 22.4);
    });

    test('bodyFatPct retorna null cuando %grasa no se registró', () {
      final ci = _checkIn(weight: 80);
      expect(BodyCompositionMetric.bodyFatPct.selectValue(ci), isNull);
    });
  });

  group('SPEC-152 — formatValue', () {
    test('todos los formatos retornan 1 decimal', () {
      expect(BodyCompositionMetric.weight.formatValue(84.27), '84.3');
      expect(BodyCompositionMetric.waistCm.formatValue(92.0), '92.0');
      expect(BodyCompositionMetric.bodyFatPct.formatValue(22.55), '22.6');
    });
  });

  group('SPEC-152 — deltaCopyFor (copy neutro)', () {
    test('delta negativo dice "menos"', () {
      final copy = BodyCompositionMetric.weight.deltaCopyFor(-2.4);
      expect(copy, contains('menos'));
      expect(copy, contains('2.4'));
      expect(copy, contains('kg'));
    });

    test('delta positivo dice "más"', () {
      final copy = BodyCompositionMetric.weight.deltaCopyFor(1.8);
      expect(copy, contains('más'));
      expect(copy, contains('1.8'));
    });

    test('delta cero retorna "Sin cambios"', () {
      expect(
        BodyCompositionMetric.weight.deltaCopyFor(0),
        'Sin cambios',
      );
    });

    test('copy es neutro — no debe valorar (no "ganaste"/"perdiste")', () {
      final negative = BodyCompositionMetric.bodyFatPct.deltaCopyFor(-1.5);
      final positive = BodyCompositionMetric.bodyFatPct.deltaCopyFor(1.5);
      expect(negative, isNot(contains('perdiste')));
      expect(negative, isNot(contains('bajaste')));
      expect(positive, isNot(contains('ganaste')));
      expect(positive, isNot(contains('subiste')));
    });
  });

  group('SPEC-152 — labels y unidades', () {
    test('labels son los visibles en las tabs', () {
      expect(BodyCompositionMetric.weight.label, 'Peso');
      expect(BodyCompositionMetric.waistCm.label, 'Cintura');
      expect(BodyCompositionMetric.bodyFatPct.label, 'Grasa');
    });

    test('unidades son consistentes', () {
      expect(BodyCompositionMetric.weight.unit, 'kg');
      expect(BodyCompositionMetric.waistCm.unit, 'cm');
      expect(BodyCompositionMetric.bodyFatPct.unit, '%');
    });
  });

  group('SPEC-152 — empty state messages', () {
    test('mensaje distinto por métrica', () {
      expect(
        BodyCompositionMetric.weight.emptyStateMessage,
        contains('peso'),
      );
      expect(
        BodyCompositionMetric.waistCm.emptyStateMessage,
        contains('cintura'),
      );
      expect(
        BodyCompositionMetric.bodyFatPct.emptyStateMessage,
        contains('grasa'),
      );
    });
  });

  // ─── SPEC-157: WHTR + Masa magra ──────────────────────────────────

  group('SPEC-157 — WHTR.selectValue', () {
    test('retorna cintura/altura cuando ambos presentes', () {
      final ci = _checkIn(weight: 80, waist: 90);
      final v = BodyCompositionMetric.whtr
          .selectValue(ci, heightCm: 175);
      expect(v, closeTo(90 / 175, 0.0001));
    });

    test('retorna null cuando heightCm es null', () {
      final ci = _checkIn(weight: 80, waist: 90);
      expect(
        BodyCompositionMetric.whtr.selectValue(ci, heightCm: null),
        isNull,
      );
    });

    test('retorna null cuando heightCm es 0 (sentinel)', () {
      final ci = _checkIn(weight: 80, waist: 90);
      expect(
        BodyCompositionMetric.whtr.selectValue(ci, heightCm: 0),
        isNull,
      );
    });

    test('retorna null cuando cintura es null', () {
      final ci = _checkIn(weight: 80);
      expect(
        BodyCompositionMetric.whtr.selectValue(ci, heightCm: 175),
        isNull,
      );
    });
  });

  group('SPEC-157 — leanMassKg.selectValue', () {
    test('retorna weight * (1 - bf/100) cuando bf presente', () {
      final ci = _checkIn(weight: 80, bodyFat: 20);
      // 80 * 0.80 = 64
      final v = BodyCompositionMetric.leanMassKg.selectValue(ci);
      expect(v, closeTo(64.0, 0.0001));
    });

    test('retorna null cuando %grasa no se registró', () {
      final ci = _checkIn(weight: 80);
      expect(BodyCompositionMetric.leanMassKg.selectValue(ci), isNull);
    });
  });

  group('SPEC-157 — labels y unidades de las nuevas métricas', () {
    test('WHTR label y unidad adimensional', () {
      expect(BodyCompositionMetric.whtr.label, 'WHTR');
      expect(BodyCompositionMetric.whtr.unit, '');
    });

    test('Masa magra label y unidad kg', () {
      expect(BodyCompositionMetric.leanMassKg.label, 'Masa magra');
      expect(BodyCompositionMetric.leanMassKg.unit, 'kg');
    });
  });

  group('SPEC-157 — formato WHTR 2 decimales', () {
    test('WHTR usa 2 decimales', () {
      expect(BodyCompositionMetric.whtr.formatValue(0.487), '0.49');
      expect(BodyCompositionMetric.whtr.formatValue(0.5), '0.50');
    });

    test('Masa magra usa 1 decimal', () {
      expect(BodyCompositionMetric.leanMassKg.formatValue(64.27), '64.3');
    });
  });

  group('SPEC-157 — deltaCopyFor para WHTR sin unidad', () {
    test('delta WHTR no incluye unidad textual', () {
      final copy = BodyCompositionMetric.whtr.deltaCopyFor(-0.03);
      // No tiene "kg" ni "cm" ni "%" — adimensional.
      expect(copy, isNot(contains('kg')));
      expect(copy, isNot(contains('cm')));
      expect(copy, isNot(contains('%')));
      expect(copy, contains('0.03'));
      expect(copy, contains('menos'));
    });
  });

  group('SPEC-157 — empty state messages nuevos', () {
    test('WHTR menciona cintura/altura', () {
      expect(
        BodyCompositionMetric.whtr.emptyStateMessage,
        contains('cintura'),
      );
    });

    test('Masa magra menciona % de grasa', () {
      expect(
        BodyCompositionMetric.leanMassKg.emptyStateMessage,
        contains('grasa'),
      );
    });
  });
}
