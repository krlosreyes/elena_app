// Tests del CircadianEngine — SPEC-51.
//
// Cubre:
// - CA-51-01: 6:00 → CircadianPhase.alerta.
// - RF-51-06: cada frontera horaria del día (06, 09, 13, 15, 20, 22:30).
// - CA-51-03: equivalencia entre CircadianEngine.currentPhase y la fase
//   producida por OrchestratorEngine.calculate.
// - currentPhaseName (API legacy en string).
// - timeUntilLock, isIntestinalLockActive, isInWindow.

import 'package:elena_app/src/core/engine/circadian_engine.dart';
import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_engine.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int h, [int m = 0]) => DateTime(2026, 5, 6, h, m);

  group('CircadianEngine.currentPhase — fronteras (RF-51-06)', () {
    test('CA-51-01: 6:00 → alerta', () {
      expect(CircadianEngine.currentPhase(at(6)), CircadianPhase.alerta);
    });

    test('5:59 → sueno (justo antes de la frontera)', () {
      expect(CircadianEngine.currentPhase(at(5, 59)), CircadianPhase.sueno);
    });

    test('8:59 → alerta (final de ALERTA)', () {
      expect(CircadianEngine.currentPhase(at(8, 59)), CircadianPhase.alerta);
    });

    test('9:00 → cognitivo (frontera)', () {
      expect(CircadianEngine.currentPhase(at(9)), CircadianPhase.cognitivo);
    });

    test('12:59 → cognitivo', () {
      expect(
          CircadianEngine.currentPhase(at(12, 59)), CircadianPhase.cognitivo);
    });

    test('13:00 → receso (frontera)', () {
      expect(CircadianEngine.currentPhase(at(13)), CircadianPhase.receso);
    });

    test('14:59 → receso', () {
      expect(CircadianEngine.currentPhase(at(14, 59)), CircadianPhase.receso);
    });

    test('15:00 → motorFuerza (frontera)', () {
      expect(CircadianEngine.currentPhase(at(15)), CircadianPhase.motorFuerza);
    });

    test('19:59 → motorFuerza', () {
      expect(
          CircadianEngine.currentPhase(at(19, 59)), CircadianPhase.motorFuerza);
    });

    test('20:00 → creatividad (frontera)', () {
      expect(CircadianEngine.currentPhase(at(20)), CircadianPhase.creatividad);
    });

    test('22:29 → creatividad (justo antes de la fase SUEÑO)', () {
      expect(
          CircadianEngine.currentPhase(at(22, 29)), CircadianPhase.creatividad);
    });

    test(
        '22:30 → sueno (inicio de la fase SUEÑO; lock intestinal SPEC-70.5 ya activo desde 21:30)',
        () {
      expect(CircadianEngine.currentPhase(at(22, 30)), CircadianPhase.sueno);
    });

    test('23:00 → sueno', () {
      expect(CircadianEngine.currentPhase(at(23)), CircadianPhase.sueno);
    });

    test('00:00 → sueno', () {
      expect(CircadianEngine.currentPhase(at(0)), CircadianPhase.sueno);
    });
  });

  group('CircadianEngine.currentPhaseName (API legacy)', () {
    test('Devuelve el label en mayúsculas', () {
      expect(CircadianEngine.currentPhaseName(at(7)), 'ALERTA');
      expect(CircadianEngine.currentPhaseName(at(10)), 'COGNITIVO');
      expect(CircadianEngine.currentPhaseName(at(14)), 'RECESO');
      expect(CircadianEngine.currentPhaseName(at(17)), 'MOTOR / FUERZA');
      expect(CircadianEngine.currentPhaseName(at(21)), 'CREATIVIDAD');
      expect(CircadianEngine.currentPhaseName(at(23)), 'SUEÑO');
    });
  });

  group('CircadianEngine constantes', () {
    test('SPEC-70.5: intestinalLockMinutes = 1290 (21:30)', () {
      expect(CircadianEngine.intestinalLockMinutes, 1290);
      expect(CircadianEngine.intestinalLockHour, 21);
      expect(CircadianEngine.intestinalLockMinute, 30);
    });

    test('allPhases tiene exactamente 6 fases', () {
      expect(CircadianEngine.allPhases.length, 6);
    });

    test('allPhases cubre las 24h sin huecos', () {
      // Sumamos la duración de cada fase. Las que no cruzan medianoche son
      // (end - start). La de SUEÑO cruza: (24 - 22.5) + 6.0 = 7.5h.
      double total = 0;
      for (final p in CircadianEngine.allPhases) {
        if (p.startHour < p.endHour) {
          total += p.endHour - p.startHour;
        } else {
          total += (24.0 - p.startHour) + p.endHour;
        }
      }
      expect(total, 24.0);
    });
  });

  group('CircadianEngine.timeUntilLock (SPEC-70.5: lock at 21:30)', () {
    test('a las 12:30 faltan 9 horas exactas (12:30 → 21:30)', () {
      final d = CircadianEngine.timeUntilLock(at(12, 30));
      expect(d.inHours, 9);
      expect(d.inMinutes.remainder(60), 0);
    });

    test('a las 21:30 exactas: 0 (lock activo en este instante)', () {
      expect(CircadianEngine.timeUntilLock(at(21, 30)), Duration.zero);
    });

    test('a las 21:31 → cuenta hasta 21:30 de mañana (23h 59m)', () {
      final d = CircadianEngine.timeUntilLock(at(21, 31));
      expect(d.inHours, 23);
      expect(d.inMinutes.remainder(60), 59);
    });
  });

  group('CircadianEngine.isIntestinalLockActive (SPEC-70.5: 21:30)', () {
    test('21:30 activa lock (frontera incluida)', () {
      expect(CircadianEngine.isIntestinalLockActive(at(21, 30)), isTrue);
    });
    test('22:29 SÍ activa (SPEC-70.5: lock se movió a 21:30)', () {
      // Antes con lock 22:30, las 22:29 estaban justo antes del umbral.
      // Ahora con lock 21:30, las 22:29 caen dentro del bloqueo.
      expect(CircadianEngine.isIntestinalLockActive(at(22, 29)), isTrue);
    });
    test('21:29 NO activa (justo antes del umbral nuevo)', () {
      expect(CircadianEngine.isIntestinalLockActive(at(21, 29)), isFalse);
    });
    test('06:00 desactiva lock', () {
      expect(CircadianEngine.isIntestinalLockActive(at(6)), isFalse);
    });
    test('05:59 lock todavía activo', () {
      expect(CircadianEngine.isIntestinalLockActive(at(5, 59)), isTrue);
    });
  });

  group('CircadianEngine.isInWindow', () {
    final start = at(8); // 08:00
    final end = at(20); // 20:00

    test('dentro de la ventana', () {
      expect(CircadianEngine.isInWindow(at(12), start, end), isTrue);
      expect(CircadianEngine.isInWindow(at(8), start, end), isTrue);
      expect(CircadianEngine.isInWindow(at(20), start, end), isTrue);
    });

    test('fuera de la ventana', () {
      expect(CircadianEngine.isInWindow(at(7, 59), start, end), isFalse);
      expect(CircadianEngine.isInWindow(at(20, 1), start, end), isFalse);
    });

    test('ventana que cruza medianoche', () {
      final s = at(22); // 22:00
      final e = at(5); // 05:00
      expect(CircadianEngine.isInWindow(at(23), s, e), isTrue);
      expect(CircadianEngine.isInWindow(at(2), s, e), isTrue);
      expect(CircadianEngine.isInWindow(at(12), s, e), isFalse);
    });
  });

  group('CA-51-03: equivalencia con OrchestratorEngine', () {
    UserModel user() => UserModel(
          id: 'test',
          age: 30,
          gender: 'M',
          weight: 75,
          height: 175,
          profile: CircadianProfile(
            wakeUpTime: DateTime(2026, 5, 6, 6),
            sleepTime: DateTime(2026, 5, 6, 22),
          ),
        );

    MetabolicState stateAt(DateTime ts) => MetabolicState(
          fastingHours: 0.5,
          glycogenLevel: 0.7,
          circadianAlignment: 1.0,
          sleepQuality: 0.8,
          exerciseLoad: 0.0,
          glycemicLoad: 0.0,
          hydrationLevel: 0.5,
          metabolicCoherence: 0.9,
          fastingHoursRaw: 4,
          sleepHoursRaw: 8,
          exerciseMinutesRaw: 0,
          nutritionScoreRaw: 0,
          weeklyAdherence: 0.5,
          lastMealTime: ts.subtract(const Duration(hours: 4)),
          timestamp: ts,
        );

    void verifyAt(int hour, [int minute = 0]) {
      final ts = at(hour, minute);
      final fromEngine = CircadianEngine.currentPhase(ts);
      final fromOrchestrator = OrchestratorEngine.calculate(
        state: stateAt(ts),
        user: user(),
        streak: const StreakState(),
      ).circadianPhase;
      expect(
        fromOrchestrator,
        fromEngine,
        reason: 'A las $hour:${minute.toString().padLeft(2, "0")} '
            'OrchestratorEngine devolvió $fromOrchestrator pero '
            'CircadianEngine.currentPhase devolvió $fromEngine',
      );
    }

    test('Equivalencia en cada fase del día', () {
      verifyAt(7); // alerta
      verifyAt(10); // cognitivo
      verifyAt(14); // receso
      verifyAt(17); // motorFuerza
      verifyAt(21); // creatividad
      verifyAt(23); // sueno
      verifyAt(2); // sueno (madrugada)
    });

    test('Equivalencia en las fronteras', () {
      verifyAt(6); // alerta
      verifyAt(9); // cognitivo
      verifyAt(13); // receso
      verifyAt(15); // motorFuerza
      verifyAt(20); // creatividad
      verifyAt(22, 30); // sueno
    });
  });
}
