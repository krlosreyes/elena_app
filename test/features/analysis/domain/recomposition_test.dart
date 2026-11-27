// Progreso v4: tests de recomposición corporal (Dart puro).

import 'package:elena_app/src/features/analysis/domain/recomposition.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 5, 9);

BiometricCheckIn _c(
  int daysAgo, {
  required double w,
  double? bf,
  double? waist,
  String? source = 'manual',
  String? notes,
}) {
  final at = _now.subtract(Duration(days: daysAgo));
  return BiometricCheckIn(
    date: at.toIso8601String().substring(0, 10),
    userId: 'u1',
    weight: w,
    bodyFatPercentage: bf,
    waistCircumference: waist,
    notes: notes,
    createdAt: at,
    source: source,
  );
}

void main() {
  group('Recomposition.compute', () {
    test('null con menos de dos mediciones', () {
      expect(Recomposition.compute([]), isNull);
      expect(Recomposition.compute([_c(0, w: 80, bf: 30)]), isNull);
    });

    test('null si las mediciones están a menos de 6 días', () {
      expect(
        Recomposition.compute([_c(3, w: 80, bf: 30), _c(0, w: 79, bf: 29)]),
        isNull,
      );
    });

    test('grasa baja y masa magra se mantiene → fatLostMuscleKept', () {
      // Antes: 80 kg, 30% → 24 grasa / 56 magra.
      // Hoy: 78 kg, 28% → 21,84 grasa / 56,16 magra.
      final r = Recomposition.compute([
        _c(30, w: 80, bf: 30, waist: 100),
        _c(0, w: 78, bf: 28, waist: 97)
      ])!;
      expect(r.verdict, RecompositionVerdict.fatLostMuscleKept);
      expect(r.fatDeltaKg, closeTo(-2.16, 0.01));
      expect(r.leanDeltaKg, closeTo(0.16, 0.01));
      expect(r.days, 30);
      expect(r.headline, contains('2 kg de grasa'));
      expect(r.weightNote, contains('Casi todo fue grasa'));
      expect(r.benefits,
          [HealthBenefit.lessAbdominalFat, HealthBenefit.muscleKept]);
    });

    test('grasa y masa magra bajan → fatLostMuscleLost', () {
      // 80/30% → 24/56 ; 75/29% → 21,75/53,25
      final r =
          Recomposition.compute([_c(30, w: 80, bf: 30), _c(0, w: 75, bf: 29)])!;
      expect(r.verdict, RecompositionVerdict.fatLostMuscleLost);
      expect(r.benefits, isEmpty);
    });

    test('sin %grasa pero cintura baja → waistDown', () {
      final r = Recomposition.compute(
          [_c(20, w: 80, waist: 100), _c(0, w: 80, waist: 98)])!;
      expect(r.verdict, RecompositionVerdict.waistDown);
      expect(r.hasComposition, isFalse);
      expect(r.headline, 'Tu cintura bajó 2 cm.');
      expect(r.benefits, [HealthBenefit.lessAbdominalFat]);
    });

    test('cambios dentro del ruido → noImprovement', () {
      final r = Recomposition.compute([
        _c(14, w: 80, bf: 30, waist: 100),
        _c(0, w: 80, bf: 29.7, waist: 99.5)
      ])!;
      expect(r.verdict, RecompositionVerdict.noImprovement);
      expect(r.weightNote, contains('hábito'));
    });

    test('elige la medición "antes" más cercana a 30 días', () {
      final r = Recomposition.compute([
        _c(60, w: 90, bf: 35),
        _c(28, w: 82, bf: 31),
        _c(10, w: 80, bf: 30),
        _c(0, w: 79, bf: 29),
      ])!;
      expect(r.days, 28);
      expect(r.before.weightKg, 82);
    });

    test('ignora fuentes que no son medición del usuario', () {
      final r = Recomposition.compute([
        _c(30, w: 70, bf: 20, source: 'healthkit_sync'),
        _c(29, w: 70, bf: 20, source: 'bodyfat_recompute'),
        _c(28, w: 70, bf: 20, source: null, notes: 'Importado de Apple Salud'),
        _c(10, w: 80, bf: 30),
        _c(0, w: 79, bf: 29),
      ])!;
      expect(r.before.weightKg, 80);
      expect(r.days, 10);
    });
  });

  group('formato', () {
    test('half redondea a 0,5 con coma', () {
      expect(Recomposition.half(2.16), '2');
      expect(Recomposition.half(-1.3), '1,5');
      expect(Recomposition.half(0.2), '0');
    });

    test('signedKg y signedCm', () {
      expect(Recomposition.signedKg(-1.6), '−1,5 kg');
      expect(Recomposition.signedKg(0.5), '+0,5 kg');
      expect(Recomposition.signedKg(0.1), 'sin cambio');
      expect(Recomposition.signedCm(-2.6), '−3 cm');
      expect(Recomposition.signedCm(0.3), 'sin cambio');
    });

    test('benefitCopy tiene título y texto', () {
      for (final b in HealthBenefit.values) {
        final (t, x) = benefitCopy(b);
        expect(t, isNotEmpty);
        expect(x, isNotEmpty);
      }
    });
  });

  group('pilares', () {
    test('weakestPillar devuelve el de menos días (empate: primero)', () {
      expect(
        weakestPillar({
          ProgressPillar.ayuno: 6,
          ProgressPillar.sueno: 3,
          ProgressPillar.agua: 5,
          ProgressPillar.movimiento: 3,
          ProgressPillar.comida: 7,
        }),
        ProgressPillar.sueno,
      );
      expect(weakestPillar({}), ProgressPillar.ayuno);
    });

    test('pillarTip cambia si el músculo está en riesgo', () {
      expect(pillarTip(ProgressPillar.movimiento, muscleAtRisk: true),
          contains('fuerza'));
      expect(pillarTip(ProgressPillar.comida, muscleAtRisk: true),
          contains('proteína'));
      expect(pillarTip(ProgressPillar.movimiento, muscleAtRisk: false),
          isNot(contains('fuerza')));
    });
  });
}
