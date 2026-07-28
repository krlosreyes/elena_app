// 17-jul: tests de `SleepCycleMembership.resolve` — la lógica pura
// (extraída de `currentCycleSleepProvider`) que decide si el sueño más
// reciente pertenece al "día metabólico" vigente y debe mostrarse en
// el anillo del Dashboard.
//
// Esta lógica lleva 3 rondas de bugs en la misma sesión (SPEC-245,
// BUG-02, y "MUESTRA CERO" reportado por Carlos) y nunca tuvo tests —
// estos cubren tanto los casos ya corregidos (para no regresarlos)
// como el caso nuevo (sin ciclo abierto, ventana de 20h en vez de
// comparación contra medianoche).

import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

SleepLog _log({
  required DateTime fellAsleep,
  required DateTime wokeUp,
}) {
  return SleepLog(
    id: 'sleep_test',
    fellAsleep: fellAsleep,
    wokeUp: wokeUp,
    lastMealTime: fellAsleep.subtract(const Duration(hours: 3)),
  );
}

MetabolicCycle _cycle({
  required DateTime startedAt,
  DateTime? closedAt,
}) {
  return MetabolicCycle(
    cycleId: startedAt.toIso8601String(),
    startedAt: startedAt,
    closedAt: closedAt,
    fastingProtocol: '16:8',
    tzOffsetMinutes: 0,
  );
}

void main() {
  group(
      'sin ciclo abierto (Carlos: "MUESTRA CERO" — está en ventana de alimentación)',
      () {
    test('sueño de anoche (dentro de las 20h) pertenece', () {
      // El escenario real reportado: sin ayuno activo, sueño capturado
      // por Apple Watch hace unas horas — debe mostrarse.
      final now = DateTime(2026, 7, 17, 15, 0); // 3pm
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0), // 11pm anoche
        wokeUp: DateTime(2026, 7, 17, 7, 0), // 7am hoy — hace 8h
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: null,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.id, 'sleep_test');
    });

    test('sueño de hace más de 20h NO pertenece', () {
      final now = DateTime(2026, 7, 17, 15, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 15, 23, 0),
        wokeUp: DateTime(2026, 7, 16, 7, 0), // hace 32h
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: null,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNull);
    });

    test('wokeUp en el futuro (dato corrupto) NO pertenece', () {
      final now = DateTime(2026, 7, 17, 7, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 17, 8, 0),
        wokeUp: DateTime(2026, 7, 17, 9, 0), // 2h en el futuro vs `now`
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: null,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNull);
    });

    test('exactamente en el borde de 20h SÍ pertenece (<=, inclusive)', () {
      final now = DateTime(2026, 7, 17, 15, 0);
      // wokeUp = now - 20h exacto.
      final wokeUp = now.subtract(const Duration(hours: 20));
      final log = _log(
        fellAsleep: wokeUp.subtract(const Duration(hours: 8)),
        wokeUp: wokeUp,
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: null,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNotNull);
    });
  });

  group('con ciclo abierto — comportamiento previo (no regresión)', () {
    test(
        'SPEC-245: ciclo abrió hoy DESPUÉS de despertar → no penaliza el sueño de hoy',
        () {
      final now = DateTime(2026, 7, 17, 12, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0), // despertó a las 7am
      );
      final cycle = _cycle(
        startedAt: DateTime(2026, 7, 17, 10, 0), // ayuno inició a las 10am
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: cycle,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNotNull,
          reason:
              'SPEC-245: sueño de hoy antes del inicio del ayuno debe contar');
    });

    test('ciclo multi-día (inició hace 2 días) — sueño de esta noche pertenece',
        () {
      final now = DateTime(2026, 7, 17, 12, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0),
      );
      final cycle = _cycle(
        startedAt: DateTime(2026, 7, 15, 20, 0), // ayuno extendido, 2 días
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: cycle,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNotNull);
    });

    test(
        'BUG-02: segundo ciclo del mismo día — el sueño de anoche NO pertenece al ciclo nuevo',
        () {
      // Usuario cerró un ayuno más temprano hoy (reclamando el sueño de
      // anoche) y abrió uno nuevo después. El ciclo nuevo debe arrancar
      // limpio (regla estricta, sin relajación).
      final now = DateTime(2026, 7, 17, 16, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 16, 23, 0),
        wokeUp: DateTime(2026, 7, 17, 7, 0),
      );
      final lastClosed = _cycle(
        startedAt: DateTime(2026, 7, 16, 20, 0),
        closedAt: DateTime(2026, 7, 17, 9, 0), // cerrado hoy a las 9am
      );
      final newCycle = _cycle(
        startedAt: DateTime(2026, 7, 17, 14, 0), // nuevo ayuno a las 2pm
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: newCycle,
        lastClosedCycle: lastClosed,
        now: now,
      );

      expect(result, isNull,
          reason:
              'BUG-02: el sueño de anoche ya fue reclamado por el ciclo cerrado, '
              'el ciclo nuevo arranca en 0');
    });

    test(
        'sueño de una noche anterior a la apertura del ciclo actual NO pertenece',
        () {
      final now = DateTime(2026, 7, 17, 16, 0);
      final log = _log(
        fellAsleep: DateTime(2026, 7, 14, 23, 0),
        wokeUp: DateTime(2026, 7, 15, 7, 0), // hace varios días
      );
      final cycle = _cycle(
        startedAt: DateTime(2026, 7, 17, 8, 0), // ciclo actual, hoy
      );

      final result = SleepCycleMembership.resolve(
        lastLog: log,
        cycle: cycle,
        lastClosedCycle: null,
        now: now,
      );

      expect(result, isNull);
    });
  });
}
