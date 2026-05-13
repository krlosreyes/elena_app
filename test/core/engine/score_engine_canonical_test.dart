// SPEC-82 §6 — Tests de los campos canónicos derivados en IMRv2Result
// y del modo `calculateBaseline`.

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-82 — IMRv2Result.empty', () {
    test('incluye los nuevos campos derivados en 0', () {
      final empty = IMRv2Result.empty();
      expect(empty.imc, 0);
      expect(empty.tmb, 0);
      expect(empty.metabolicAge, 0);
      expect(empty.ica, 0);
      expect(empty.ffmi, 0);
      expect(empty.whtr, 0);
    });
  });

  group('SPEC-82 — calculateBaseline campos derivados', () {
    test('imc se computa con weight y height', () {
      final user = _testUser(
        gender: 'M',
        weight: 80,
        height: 180,
      );
      final result = ScoreEngine.calculateBaseline(user);
      // 80 / (1.8 ^ 2) = 24.6913580...
      expect(result.imc, closeTo(24.69, 0.01));
    });

    test('tmb usa Mifflin-St Jeor para hombre', () {
      final user = _testUser(
        gender: 'M',
        weight: 80,
        height: 180,
        age: 35,
      );
      final result = ScoreEngine.calculateBaseline(user);
      // 10*80 + 6.25*180 - 5*35 + 5 = 800 + 1125 - 175 + 5 = 1755
      expect(result.tmb, closeTo(1755, 0.5));
    });

    test('tmb usa Mifflin-St Jeor para mujer', () {
      final user = _testUser(
        gender: 'F',
        weight: 60,
        height: 165,
        age: 30,
      );
      final result = ScoreEngine.calculateBaseline(user);
      // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      expect(result.tmb, closeTo(1320.25, 0.5));
    });

    test('ica = waist / height; whtr = ica', () {
      final user = _testUser(
        gender: 'M',
        weight: 80,
        height: 180,
        waist: 90,
      );
      final result = ScoreEngine.calculateBaseline(user);
      // 90 / 180 = 0.5
      expect(result.ica, closeTo(0.5, 0.01));
      expect(result.whtr, equals(result.ica));
    });

    test('ica = 0 cuando waistCircumference es null', () {
      final user = _testUser(
        gender: 'M',
        weight: 80,
        height: 180,
        waist: null,
      );
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.ica, 0);
      expect(result.whtr, 0);
    });

    test('metabolicAge dentro de rango [age-10, age+25]', () {
      // Escenario extremo: usuario con estructura muy degradada.
      final user = _testUser(
        gender: 'M',
        weight: 200,
        height: 160,
        age: 50,
        waist: 130,
      );
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.metabolicAge, greaterThanOrEqualTo(40));
      expect(result.metabolicAge, lessThanOrEqualTo(75));
    });

    test('metabolicAge ≈ age cuando estructura es saludable', () {
      // structureBlock ≈ 0.87 con estos inputs (s1=1.0 por WHtR óptimo,
      // s2≈0.64 por FFMI 20.8 vs baseFFMI 17). delta = round(20 * 0.13)
      // = 3, metabolicAge = 35 + 3 = 38. Tolerancia ±5 captura este
      // caso y otros similares sin sobre-especificar.
      final user = _testUser(
        gender: 'M',
        weight: 75,
        height: 180,
        age: 35,
        waist: 72,
        bodyFat: 10,
      );
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.metabolicAge, lessThanOrEqualTo(user.age + 5));
      expect(result.metabolicAge, greaterThanOrEqualTo(user.age - 5));
    });
  });

  group('SPEC-82 — calculateBaseline scoring', () {
    test('totalScore baseline nunca excede 50 (solo bloque Estructura)', () {
      // Estructura óptima → score = 0.5 * 1.0 = 0.5 → 50 puntos.
      final user = _testUser(
        gender: 'M',
        weight: 75,
        height: 180,
        waist: 72,
        bodyFat: 10,
      );
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.totalScore, lessThanOrEqualTo(50));
    });

    test('metabolicScore y behaviorScore son 0 en baseline', () {
      final user = _testUser(gender: 'M', weight: 75, height: 180);
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.metabolicScore, 0);
      expect(result.behaviorScore, 0);
      expect(result.circadianAlignment, 0);
    });

    test('zone es un label del set válido', () {
      const validZones = {
        'DETERIORADO',
        'INESTABLE',
        'FUNCIONAL',
        'EFICIENTE',
        'OPTIMIZADO',
      };
      final user = _testUser(gender: 'M', weight: 80, height: 180);
      final result = ScoreEngine.calculateBaseline(user);
      expect(validZones.contains(result.zone), isTrue,
          reason: 'zone "${result.zone}" no está en el set canónico');
    });

    test('description marca el caso baseline', () {
      final user = _testUser(gender: 'M', weight: 75, height: 180);
      final result = ScoreEngine.calculateBaseline(user);
      expect(result.description, contains('Baseline'));
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Helper: construye un UserModel mínimo válido para los tests.
// ─────────────────────────────────────────────────────────────────────

UserModel _testUser({
  String id = 'test-uid',
  String name = 'Test',
  required String gender,
  required double weight,
  required double height,
  int age = 30,
  double? waist,
  double? neck,
  double bodyFat = 20.0,
}) {
  return UserModel(
    id: id,
    name: name,
    age: age,
    gender: gender,
    weight: weight,
    height: height,
    waistCircumference: waist,
    neckCircumference: neck,
    bodyFatPercentage: bodyFat,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 1, 1, 6),
      sleepTime: DateTime(2026, 1, 1, 22),
      firstMealGoal: DateTime(2026, 1, 1, 8),
      lastMealGoal: DateTime(2026, 1, 1, 18),
    ),
  );
}
