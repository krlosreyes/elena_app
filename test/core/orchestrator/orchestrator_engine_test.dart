// Tests unitarios de OrchestratorEngine (SPEC-46/60 cerrado).
//
// Cubre:
// - Determinismo: mismo input -> mismo output (función pura).
// - Guard de salida temprana cuando state.timestamp o state.lastMealTime
//   son null (SPEC-60).
// - Mapeo de fases circadianas según hora del timestamp.
// - Mapeo de fases de ayuno según horas de ayuno.

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_engine.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_state.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user() => UserModel(
      id: 'test',
      age: 30,
      gender: 'M',
      weight: 75,
      height: 175,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 5, 6, 6),
        sleepTime: DateTime(2026, 5, 6, 22),
        firstMealGoal: DateTime(2026, 5, 6, 8),
        lastMealGoal: DateTime(2026, 5, 6, 19),
      ),
    );

MetabolicState _state({
  required DateTime timestamp,
  DateTime? lastMealTime,
  double fastingHoursRaw = 0,
  double sleepQuality = 0.8,
  double hydrationLevel = 0.5,
  double exerciseMinutesRaw = 0,
  double nutritionScoreRaw = 0,
  double circadianAlignment = 1.0,
}) =>
    MetabolicState(
      fastingHours: 0.5,
      glycogenLevel: 0.7,
      circadianAlignment: circadianAlignment,
      sleepQuality: sleepQuality,
      exerciseLoad: 0.0,
      glycemicLoad: 0.0,
      hydrationLevel: hydrationLevel,
      metabolicCoherence: 0.9,
      fastingHoursRaw: fastingHoursRaw,
      sleepHoursRaw: 8,
      exerciseMinutesRaw: exerciseMinutesRaw,
      nutritionScoreRaw: nutritionScoreRaw,
      weeklyAdherence: 0.7,
      lastMealTime: lastMealTime ?? DateTime(2026, 5, 6, 19),
      timestamp: timestamp,
    );

void main() {
  group('Determinismo', () {
    test('Mismo input produce mismo output', () {
      final state = _state(timestamp: DateTime(2026, 5, 6, 12));
      final user = _user();
      const streak = StreakState();
      final r1 = OrchestratorEngine.calculate(
          state: state, user: user, streak: streak);
      final r2 = OrchestratorEngine.calculate(
          state: state, user: user, streak: streak);
      expect(r1.fastingPhase, r2.fastingPhase);
      expect(r1.circadianPhase, r2.circadianPhase);
      expect(r1.metabolicCoherence, r2.metabolicCoherence);
      expect(r1.fastedHours, r2.fastedHours);
    });
  });

  group('SPEC-60: guard de salida temprana con state nullable', () {
    test('timestamp null retorna OrchestratorState.initial()', () {
      final emptyState =
          MetabolicState.empty(); // tanto timestamp como lastMealTime nulls
      final out = OrchestratorEngine.calculate(
        state: emptyState,
        user: _user(),
        streak: const StreakState(),
      );
      // initial() trae fastingPhase.alerta y sourceTimestamp null
      expect(out.fastingPhase, FastingPhase.alerta);
      expect(out.circadianPhase, CircadianPhase.alerta);
      expect(out.sourceTimestamp, isNull);
      expect(out.fastedHours, 0.0);
    });
  });

  group('Fases de ayuno por horas crudas', () {
    final user = _user();
    const streak = StreakState();

    test('< 4h -> alerta', () {
      final s = _state(timestamp: DateTime(2026, 5, 6, 12), fastingHoursRaw: 2);
      final out =
          OrchestratorEngine.calculate(state: s, user: user, streak: streak);
      expect(out.fastingPhase, FastingPhase.alerta);
    });

    test('4..8h -> gluconeogenesis', () {
      final s = _state(timestamp: DateTime(2026, 5, 6, 12), fastingHoursRaw: 6);
      final out =
          OrchestratorEngine.calculate(state: s, user: user, streak: streak);
      expect(out.fastingPhase, FastingPhase.gluconeogenesis);
    });

    test('8..12h -> cetosis', () {
      final s =
          _state(timestamp: DateTime(2026, 5, 6, 12), fastingHoursRaw: 10);
      final out =
          OrchestratorEngine.calculate(state: s, user: user, streak: streak);
      expect(out.fastingPhase, FastingPhase.cetosis);
    });

    test('>= 12h -> autofagia', () {
      final s =
          _state(timestamp: DateTime(2026, 5, 6, 12), fastingHoursRaw: 16);
      final out =
          OrchestratorEngine.calculate(state: s, user: user, streak: streak);
      expect(out.fastingPhase, FastingPhase.autofagia);
    });
  });

  group('Fases circadianas por timestamp', () {
    final user = _user();
    const streak = StreakState();

    test('07:00 -> alerta', () {
      final out = OrchestratorEngine.calculate(
        state: _state(timestamp: DateTime(2026, 5, 6, 7)),
        user: user,
        streak: streak,
      );
      expect(out.circadianPhase, CircadianPhase.alerta);
    });

    test('10:00 -> cognitivo', () {
      final out = OrchestratorEngine.calculate(
        state: _state(timestamp: DateTime(2026, 5, 6, 10)),
        user: user,
        streak: streak,
      );
      expect(out.circadianPhase, CircadianPhase.cognitivo);
    });

    test('17:00 -> motorFuerza', () {
      final out = OrchestratorEngine.calculate(
        state: _state(timestamp: DateTime(2026, 5, 6, 17)),
        user: user,
        streak: streak,
      );
      expect(out.circadianPhase, CircadianPhase.motorFuerza);
    });

    test('23:00 -> sueno', () {
      final out = OrchestratorEngine.calculate(
        state: _state(timestamp: DateTime(2026, 5, 6, 23)),
        user: user,
        streak: streak,
      );
      expect(out.circadianPhase, CircadianPhase.sueno);
    });
  });

  group('Reglas de seguridad', () {
    final user = _user();
    const streak = StreakState();

    test('No se puede ejercitar en fase de sueno circadiano', () {
      final out = OrchestratorEngine.calculate(
        state: _state(timestamp: DateTime(2026, 5, 6, 23)),
        user: user,
        streak: streak,
      );
      expect(out.canExerciseNow, isFalse);
    });

    test('Autofagia + sueno deficiente bloquea ejercicio', () {
      final out = OrchestratorEngine.calculate(
        state: _state(
          timestamp: DateTime(2026, 5, 6, 12),
          fastingHoursRaw: 16, // autofagia
          sleepQuality: 0.3, // < 0.4
        ),
        user: user,
        streak: streak,
      );
      expect(out.canExerciseNow, isFalse);
    });
  });

  group('SPEC-71: orchestrator no descuenta por violations', () {
    final user = _user();
    const streak = StreakState();

    test(
        'orchestrator.metabolicCoherence == state.metabolicCoherence (sin ajuste)',
        () {
      // Construyo un state con un valor de coherencia conocido (0.6) y
      // varias dimensiones malas que el orchestrator detectará como
      // violations. Verifica que el orchestrator NO descuenta ese 0.6.
      final state = MetabolicState(
        fastingHours: 0.95,
        glycogenLevel: 0.1,
        circadianAlignment: 0.3,
        sleepQuality: 0.3,
        exerciseLoad: 0.9,
        glycemicLoad: 0.5,
        hydrationLevel: 0.3,
        metabolicCoherence: 0.6, // valor conocido
        fastingHoursRaw: 16,
        sleepHoursRaw: 5,
        exerciseMinutesRaw: 90,
        nutritionScoreRaw: 0.5,
        weeklyAdherence: 0.5,
        lastMealTime: DateTime(2026, 5, 6, 8),
        timestamp: DateTime(2026, 5, 6, 12),
      );

      final out = OrchestratorEngine.calculate(
        state: state,
        user: user,
        streak: streak,
      );
      expect(out.metabolicCoherence, 0.6,
          reason: 'No debe ajustarse downstream por violations.length');
      expect(out.activeSyncViolations, isNotEmpty,
          reason: 'Las violations siguen detectándose como info al usuario');
    });
  });

  group('OrchestratorState.initial() es const e idempotente', () {
    test('dos llamadas a initial() producen instancias idénticas', () {
      final a = OrchestratorState.initial();
      final b = OrchestratorState.initial();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('initial() tiene sourceTimestamp null (SPEC-60)', () {
      expect(OrchestratorState.initial().sourceTimestamp, isNull);
    });
  });
}
