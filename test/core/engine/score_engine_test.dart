// Tests unitarios de ScoreEngine (SPEC-46/52/59 cerrado).
//
// Cubre:
// - SPEC-59: comparación de bloqueo intestinal por minutos totales
//   (22:00 NO penaliza, 22:30 SÍ penaliza, 23:00 SÍ penaliza).
// - Determinismo: mismo input -> mismo output (función pura).
// - Zonas del IMR (DETERIORADO/INESTABLE/FUNCIONAL/EFICIENTE/OPTIMIZADO).
// - Escenarios congelados que sirven como baseline para SPEC-52
//   (cuando el ScoreEngine pase a recibir MetabolicState).

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String gender = 'M',
  double weight = 75,
  double height = 175,
  double bodyFatPct = 20,
  double? waist,
  DateTime? lastMealGoal,
}) {
  return UserModel(
    id: 'test',
    age: 30,
    gender: gender,
    weight: weight,
    height: height,
    bodyFatPercentage: bodyFatPct,
    waistCircumference: waist,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 5, 6, 6),
      sleepTime: DateTime(2026, 5, 6, 22),
      lastMealGoal: lastMealGoal,
    ),
  );
}

void main() {
  final engine = ScoreEngine();

  group('Determinismo', () {
    test('Mismo input produce el mismo output (función pura)', () {
      final user = _user(weight: 80, height: 180, waist: 90);
      final lastMeal = DateTime(2026, 5, 6, 19);
      final r1 = engine.calculateIMR(
        user,
        fastingHours: 14,
        weeklyAdherence: 0.8,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: lastMeal,
        nutritionScore: 0.6,
      );
      final r2 = engine.calculateIMR(
        user,
        fastingHours: 14,
        weeklyAdherence: 0.8,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: lastMeal,
        nutritionScore: 0.6,
      );
      expect(r1.totalScore, r2.totalScore);
      expect(r1.zone, r2.zone);
    });
  });

  group('SPEC-59: penalización por bloqueo intestinal', () {
    final user = _user(waist: 90);

    test('22:00 NO penaliza (caso roto del bug original)', () {
      final r = engine.calculateIMR(
        user,
        fastingHours: 12,
        weeklyAdherence: 0.7,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: DateTime(2026, 5, 6, 22),
        nutritionScore: 0.5,
      );
      expect(r.circadianAlignment, isNot(0.5),
          reason: '22:00 está antes de las 22:30, NO debe penalizar');
    });

    test('22:30 SÍ penaliza (frontera incluida)', () {
      final r = engine.calculateIMR(
        user,
        fastingHours: 12,
        weeklyAdherence: 0.7,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: DateTime(2026, 5, 6, 22, 30),
        nutritionScore: 0.5,
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('23:00 SÍ penaliza', () {
      final r = engine.calculateIMR(
        user,
        fastingHours: 12,
        weeklyAdherence: 0.7,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: DateTime(2026, 5, 6, 23),
        nutritionScore: 0.5,
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('22:29 NO penaliza', () {
      final r = engine.calculateIMR(
        user,
        fastingHours: 12,
        weeklyAdherence: 0.7,
        exerciseMin: 30,
        sleepHours: 8,
        lastMealTime: DateTime(2026, 5, 6, 22, 29),
        nutritionScore: 0.5,
      );
      expect(r.circadianAlignment, isNot(0.5));
    });
  });

  group('Zonas del IMR', () {
    test('Score < 40 = DETERIORADO', () {
      final user = _user(
        weight: 100,
        height: 165,
        bodyFatPct: 35,
        waist: 110,
      );
      final r = engine.calculateIMR(
        user,
        fastingHours: 0,
        weeklyAdherence: 0.0,
        exerciseMin: 0,
        sleepHours: 4,
        lastMealTime: DateTime(2026, 5, 6, 23),
        nutritionScore: 0.0,
      );
      expect(r.totalScore, lessThan(40));
      expect(r.zone, 'DETERIORADO');
    });

    test('Composición saludable + protocolo bueno = FUNCIONAL o mejor', () {
      final user = _user(
        weight: 75,
        height: 180,
        bodyFatPct: 14,
        waist: 78,
      );
      final r = engine.calculateIMR(
        user,
        fastingHours: 16,
        weeklyAdherence: 0.9,
        exerciseMin: 45,
        sleepHours: 8,
        lastMealTime: DateTime(2026, 5, 6, 19),
        nutritionScore: 0.8,
      );
      expect(r.totalScore, greaterThan(60));
      expect(r.zone, anyOf(['FUNCIONAL', 'EFICIENTE', 'OPTIMIZADO']));
    });
  });

  group('Estructura (50% del IMR) responde a cintura', () {
    test('Cintura saludable (WHtR 0.45) genera mejor estructura que 0.55', () {
      final low = _user(weight: 75, height: 180, waist: 81); // 0.45
      final high = _user(weight: 75, height: 180, waist: 99); // 0.55
      final base = {
        'fastingHours': 12.0,
        'weeklyAdherence': 0.5,
        'exerciseMin': 0.0,
        'sleepHours': 7.0,
        'nutritionScore': 0.5,
      };
      final lastMeal = DateTime(2026, 5, 6, 18);

      final rLow = engine.calculateIMR(
        low,
        fastingHours: base['fastingHours'] as double,
        weeklyAdherence: base['weeklyAdherence'] as double,
        exerciseMin: base['exerciseMin'] as double,
        sleepHours: base['sleepHours'] as double,
        lastMealTime: lastMeal,
        nutritionScore: base['nutritionScore'] as double,
      );
      final rHigh = engine.calculateIMR(
        high,
        fastingHours: base['fastingHours'] as double,
        weeklyAdherence: base['weeklyAdherence'] as double,
        exerciseMin: base['exerciseMin'] as double,
        sleepHours: base['sleepHours'] as double,
        lastMealTime: lastMeal,
        nutritionScore: base['nutritionScore'] as double,
      );
      expect(rLow.structureScore, greaterThan(rHigh.structureScore));
      expect(rLow.totalScore, greaterThan(rHigh.totalScore));
    });
  });

  group('Bloque metabólico responde a horas de ayuno', () {
    test('14h de ayuno genera mejor metabolicScore que 4h', () {
      final user = _user(waist: 85);
      final lastMeal = DateTime(2026, 5, 6, 18);
      final low = engine.calculateIMR(
        user,
        fastingHours: 4,
        weeklyAdherence: 0.5,
        exerciseMin: 0,
        sleepHours: 7,
        lastMealTime: lastMeal,
        nutritionScore: 0.5,
      );
      final high = engine.calculateIMR(
        user,
        fastingHours: 14,
        weeklyAdherence: 0.5,
        exerciseMin: 0,
        sleepHours: 7,
        lastMealTime: lastMeal,
        nutritionScore: 0.5,
      );
      expect(high.metabolicScore, greaterThan(low.metabolicScore));
    });
  });
}
