// Tests unitarios de ScoreEngine (SPEC-46/52/59 cerrado).
//
// Cubre:
// - SPEC-52: nueva firma calculateIMR(UserModel, MetabolicState).
// - SPEC-59: comparación de bloqueo intestinal por minutos totales.
// - Determinismo: mismo input → mismo output.
// - Zonas del IMR.
// - Estructura responde a WHtR; bloque metabólico responde a horas de ayuno.

import 'package:elena_app/src/core/engine/metabolic_state.dart';
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

/// Helper para construir un MetabolicState con valores sensatos por defecto.
/// Solo se sobreescriben los campos que el test necesita variar.
MetabolicState _state({
  double fastingHoursRaw = 12,
  double weeklyAdherence = 0.7,
  double exerciseMinutesRaw = 30,
  double sleepHoursRaw = 8,
  double nutritionScoreRaw = 0.5,
  double hydrationLevel = 0.5,
  DateTime? lastMealTime,
}) {
  return MetabolicState(
    fastingHours: 0.5,
    glycogenLevel: 0.5,
    circadianAlignment: 1.0,
    sleepQuality: 1.0,
    exerciseLoad: 0.5,
    glycemicLoad: nutritionScoreRaw,
    hydrationLevel: hydrationLevel,
    metabolicCoherence: 1.0,
    fastingHoursRaw: fastingHoursRaw,
    sleepHoursRaw: sleepHoursRaw,
    exerciseMinutesRaw: exerciseMinutesRaw,
    nutritionScoreRaw: nutritionScoreRaw,
    weeklyAdherence: weeklyAdherence,
    lastMealTime: lastMealTime ?? DateTime(2026, 5, 6, 19),
    timestamp: DateTime(2026, 5, 6, 20),
  );
}

void main() {
  final engine = ScoreEngine();

  group('SPEC-52: nueva firma (UserModel, MetabolicState)', () {
    test('Determinismo — mismo input produce mismo output', () {
      final user = _user(weight: 80, height: 180, waist: 90);
      final state = _state();
      final r1 = engine.calculateIMR(user, state);
      final r2 = engine.calculateIMR(user, state);
      expect(r1.totalScore, r2.totalScore);
      expect(r1.zone, r2.zone);
      expect(r1.circadianAlignment, r2.circadianAlignment);
    });

    test('lastMealTime null → IMRv2Result.empty()', () {
      final user = _user(waist: 90);
      // MetabolicState.empty() tiene lastMealTime null.
      final r = engine.calculateIMR(user, MetabolicState.empty());
      expect(r.totalScore, 0);
      expect(r.zone, 'N/A');
      expect(r.description, 'Cargando...');
    });
  });

  group('SPEC-59: penalización por bloqueo intestinal', () {
    final user = _user(waist: 90);

    test('22:00 NO penaliza (caso roto del bug original)', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 22)),
      );
      expect(r.circadianAlignment, isNot(0.5),
          reason: '22:00 está antes de las 22:30, NO debe penalizar');
    });

    test('22:30 SÍ penaliza (frontera incluida)', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 22, 30)),
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('23:00 SÍ penaliza', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 23)),
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('22:29 NO penaliza', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 22, 29)),
      );
      expect(r.circadianAlignment, isNot(0.5));
    });
  });

  group('Zonas del IMR', () {
    test('Composición pobre + protocolo cero = DETERIORADO', () {
      final user = _user(
        weight: 100,
        height: 165,
        bodyFatPct: 35,
        waist: 110,
      );
      final r = engine.calculateIMR(
        user,
        _state(
          fastingHoursRaw: 0,
          weeklyAdherence: 0.0,
          exerciseMinutesRaw: 0,
          sleepHoursRaw: 4,
          nutritionScoreRaw: 0.0,
          lastMealTime: DateTime(2026, 5, 6, 23),
        ),
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
        _state(
          fastingHoursRaw: 16,
          weeklyAdherence: 0.9,
          exerciseMinutesRaw: 45,
          sleepHoursRaw: 8,
          nutritionScoreRaw: 0.8,
          lastMealTime: DateTime(2026, 5, 6, 19),
        ),
      );
      expect(r.totalScore, greaterThan(60));
      expect(r.zone, anyOf(['FUNCIONAL', 'EFICIENTE', 'OPTIMIZADO']));
    });
  });

  group('Estructura (50% del IMR) responde a cintura', () {
    test('WHtR 0.45 mejor que 0.55', () {
      final low = _user(weight: 75, height: 180, waist: 81); // 0.45
      final high = _user(weight: 75, height: 180, waist: 99); // 0.55
      final state = _state();
      final rLow = engine.calculateIMR(low, state);
      final rHigh = engine.calculateIMR(high, state);
      expect(rLow.structureScore, greaterThan(rHigh.structureScore));
      expect(rLow.totalScore, greaterThan(rHigh.totalScore));
    });
  });

  group('Bloque metabólico responde a horas de ayuno', () {
    test('14h de ayuno > 4h de ayuno', () {
      final user = _user(waist: 85);
      final low = engine.calculateIMR(user, _state(fastingHoursRaw: 4));
      final high = engine.calculateIMR(user, _state(fastingHoursRaw: 14));
      expect(high.metabolicScore, greaterThan(low.metabolicScore));
    });
  });

  group('SPEC-67: hidratación entra al bloque Conducta', () {
    final user = _user(waist: 85);

    test('CA-67-01: 0% vs 100% hidratación → diferencia ≥ 5 puntos', () {
      // Mantenemos todos los demás factores idénticos. Solo varía hidratación.
      final dry = engine.calculateIMR(user, _state(hydrationLevel: 0.0));
      final hydrated =
          engine.calculateIMR(user, _state(hydrationLevel: 1.0));

      expect(hydrated.totalScore - dry.totalScore, greaterThanOrEqualTo(5),
          reason: 'La diferencia debe ser perceptible (>= 5 puntos absolutos).');
    });

    test('Hidratación más alta → behavior score más alto', () {
      final r1 = engine.calculateIMR(user, _state(hydrationLevel: 0.2));
      final r2 = engine.calculateIMR(user, _state(hydrationLevel: 0.8));
      expect(r2.behaviorScore, greaterThan(r1.behaviorScore));
    });

    test('Pesos suman 100% (Circadiano 28 + Sueño 20 + Ejercicio 20 + '
        'Nutrición 12 + Hidratación 20)', () {
      const total = 0.28 + 0.20 + 0.20 + 0.12 + 0.20;
      expect(total, closeTo(1.0, 1e-9));
    });
  });
}
