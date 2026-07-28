// SPEC-148 §RF-148-03 (2026-06-05): tests del TransformationNarrator.
//
// Validan:
//   - Selección por categoría (peso ↓ + ayuno alto → copy progreso A).
//   - Cooldown vía recentIds (mismo snapshot + skip → siguiente copy).
//   - Snapshot vacío → null (caller muestra placeholder).
//   - Default cuando nada matchea (snapshot con datos pero deltas neutros).

import 'package:elena_app/src/features/analysis/application/transformation_narrator.dart';
import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper para construir un snapshot con solo los campos relevantes.
TransformationSnapshot _snap({
  double? weightPast,
  double? weightCurrent,
  int? imrPast,
  int? imrCurrent,
  double? waistPast,
  double? waistCurrent,
  double? bodyFatPast,
  double? bodyFatCurrent,
  double? sleepPast,
  double? sleepCurrent,
  int? fastingPast,
  int? fastingCurrent,
}) {
  return TransformationSnapshot(
    weightKg: TransformationDelta<double>(
      past: weightPast,
      current: weightCurrent,
      label: 'Peso',
      unit: 'kg',
    ),
    imr: TransformationDelta<int>(
      past: imrPast,
      current: imrCurrent,
      label: 'IMR',
      unit: '',
    ),
    waistCm: TransformationDelta<double>(
      past: waistPast,
      current: waistCurrent,
      label: 'Cintura',
      unit: 'cm',
    ),
    bodyFatPct: TransformationDelta<double>(
      past: bodyFatPast,
      current: bodyFatCurrent,
      label: '% Grasa',
      unit: '%',
    ),
    sleepHoursAvg: TransformationDelta<double>(
      past: sleepPast,
      current: sleepCurrent,
      label: 'Sueño',
      unit: 'h prom',
    ),
    fastingDaysOf7: TransformationDelta<int>(
      past: fastingPast,
      current: fastingCurrent,
      label: 'Ayuno',
      unit: 'd/7',
    ),
    // SPEC-138 (2026-06-05): el narrador no usa el delta UPF en su
    // pool actual (categorías categorizadas con peso/IMR/ayuno).
    // Quedamos en empty para no romper los tests existentes.
    upfSharePct: TransformationDelta.empty(
      label: 'Ultraprocesado',
      unit: '%',
    ),
  );
}

void main() {
  group('SPEC-148 §RF-148-03 — TransformationNarrator.pick', () {
    test('snapshot vacío → null (el caller muestra placeholder)', () {
      final result = TransformationNarrator.pick(
        TransformationSnapshot.empty(),
      );
      expect(result, isNull);
    });
  });

  group('Categoría 1 — Progreso claro', () {
    test('peso ↓1.5kg + ayuno 6/7 → copy "ayuno haciendo el trabajo"', () {
      final s = _snap(
        weightPast: 85.0,
        weightCurrent: 83.5,
        fastingPast: 3,
        fastingCurrent: 6,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'progress-weight-down-fasting-high');
      expect(n.citation, 'Mattson 2017');
      expect(n.headline, contains('ayuno está haciendo'));
    });

    test('IMR ↑6 + sueño ↑0.6h → copy "sueño empujando"', () {
      final s = _snap(
        imrPast: 58,
        imrCurrent: 64,
        sleepPast: 6.2,
        sleepCurrent: 6.8,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'progress-imr-up-sleep-up');
      expect(n.citation, 'Walker 2017');
    });

    test('cintura ↓2cm + bodyfat ↓1.5% → copy "visceral y composición"', () {
      final s = _snap(
        waistPast: 96.0,
        waistCurrent: 94.0,
        bodyFatPast: 24.0,
        bodyFatCurrent: 22.5,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'progress-waist-down-bf-down');
      expect(n.citation, 'Lopez-Minguez 2018');
    });

    test('ayuno creció +3 días + actual 6/7 → copy "disciplina"', () {
      final s = _snap(
        fastingPast: 3,
        fastingCurrent: 6,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'progress-fasting-streak-grew');
      // Verifica interpolación de currentFasting en headline.
      expect(n.headline, contains('6 de 7'));
    });
  });

  group('Categoría 2 — Cambio silente', () {
    test('peso estable + cintura ↓1cm → copy "visceral antes que magra"', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 80.1, // dentro de epsilon
        waistPast: 96.0,
        waistCurrent: 95.0,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'silent-weight-stable-waist-down');
      expect(n.citation, 'Petersen-Shulman 2018');
    });

    test('peso ↑0.6kg + bodyfat ↓0.7% → copy "músculo pesa más"', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 80.6,
        bodyFatPast: 22.0,
        bodyFatCurrent: 21.3,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'silent-weight-up-bf-down');
      expect(n.citation, 'ACSM 2021');
    });

    test('cintura estable + sueño ↑0.3h → copy "sueño consolidando"', () {
      final s = _snap(
        waistPast: 96.0,
        waistCurrent: 96.2, // dentro de epsilon
        sleepPast: 6.5,
        sleepCurrent: 6.8,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'silent-waist-stable-sleep-up');
    });
  });

  group('Categoría 3 — Estancamiento legítimo', () {
    test('todo estable + ayuno 5/7 → copy "consistencia paga"', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 80.1,
        waistPast: 96.0,
        waistCurrent: 96.1,
        sleepPast: 6.8,
        sleepCurrent: 6.9,
        fastingPast: 5,
        fastingCurrent: 5,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'plateau-discipline-pays');
      expect(n.citation, 'Sutton 2018');
    });

    test('todo estable + ayuno bajo → copy "próxima ola"', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 80.1,
        waistPast: 96.0,
        waistCurrent: 96.1,
        sleepPast: 6.8,
        sleepCurrent: 6.9,
        fastingPast: 2,
        fastingCurrent: 2,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'plateau-next-wave');
      expect(n.citation, 'Mattson 2017');
    });
  });

  group('Categoría 4 — Retroceso sin culpa', () {
    test('peso ↑1.5kg + ayuno ↓2 días → copy "comidas social, sin culpa"', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 81.5,
        fastingPast: 5,
        fastingCurrent: 3,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'setback-weight-up-fasting-down');
      expect(n.headline, contains('sin culpa'));
      expect(n.citation, isNull);
    });

    test('sueño ↓0.7h → copy "acostarte 20 min antes"', () {
      final s = _snap(
        sleepPast: 7.0,
        sleepCurrent: 6.3,
      );
      final n = TransformationNarrator.pick(s)!;
      expect(n.id, 'setback-sleep-dropped');
    });
  });

  group('SPEC-148 — cooldown anti-repetición', () {
    test('recentIds skip del primer candidato → segundo en orden', () {
      // Snapshot que activa 2 categorías a la vez: progreso de peso +
      // estancamiento del resto.
      final s = _snap(
        weightPast: 85.0,
        weightCurrent: 83.5,
        fastingPast: 3,
        fastingCurrent: 6,
        // También cumple ayuno-grew → 2 copies disponibles.
      );
      final first = TransformationNarrator.pick(s)!;
      final second = TransformationNarrator.pick(
        s,
        recentIds: {first.id},
      );
      expect(second, isNotNull);
      expect(second!.id, isNot(first.id));
    });

    test('todos en recentIds → devuelve el primero igual (no null)', () {
      final s = _snap(
        weightPast: 80.0,
        weightCurrent: 80.1,
        waistPast: 96.0,
        waistCurrent: 96.1,
        sleepPast: 6.8,
        sleepCurrent: 6.9,
        fastingPast: 5,
        fastingCurrent: 5,
      );
      final first = TransformationNarrator.pick(s)!;
      final repeated = TransformationNarrator.pick(
        s,
        recentIds: {first.id, 'plateau-next-wave'},
      );
      expect(repeated, isNotNull);
      // Devuelve el primero aunque esté en recentIds (mejor repetir).
      expect(repeated!.id, first.id);
    });
  });

  group('SPEC-148 — fallback default', () {
    test('snapshot con un solo indicador no significativo → default', () {
      // Solo IMR con delta 0 → ninguna regla matchea fuerte.
      final s = _snap(imrPast: 60, imrCurrent: 60);
      final n = TransformationNarrator.pick(s);
      expect(n, isNotNull);
      expect(n!.id, 'default');
      expect(n.citation, isNull);
    });
  });
}
