// SPEC-149 §8.1: tests exhaustivos del MetabolicCycleResolver.

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _openCycle({
  DateTime? startedAt,
  String protocol = '16:8',
}) =>
    MetabolicCycle.open(
      startedAt: startedAt ?? DateTime(2026, 6, 1, 21, 0),
      fastingProtocol: protocol,
      tzOffsetMinutes: -300,
    );

void main() {
  group('SPEC-149 — useCalendarFallback', () {
    test('"Ninguno" → true', () {
      expect(MetabolicCycleResolver.useCalendarFallback('Ninguno'), isTrue);
    });

    test('cualquier protocolo TRE → false', () {
      for (final p in ['12:12', '14:10', '16:8', '18:6', '20:4', '22:2', 'OMAD']) {
        expect(
          MetabolicCycleResolver.useCalendarFallback(p),
          isFalse,
          reason: 'protocolo $p no debería ser calendárico',
        );
      }
    });
  });

  group('SPEC-149 — calendarFallbackCloseAt', () {
    test('retorna 23:59:59.999 del día de now', () {
      final now = DateTime(2026, 6, 1, 14, 30);
      final close = MetabolicCycleResolver.calendarFallbackCloseAt(now);
      expect(close.year, 2026);
      expect(close.month, 6);
      expect(close.day, 1);
      expect(close.hour, 23);
      expect(close.minute, 59);
      expect(close.second, 59);
      expect(close.millisecond, 999);
    });

    test('preserva el día aún en últimos segundos', () {
      final now = DateTime(2026, 6, 1, 23, 59, 30);
      final close = MetabolicCycleResolver.calendarFallbackCloseAt(now);
      expect(close.day, 1);
    });
  });

  group('SPEC-149 — openCycle', () {
    test('construye ciclo válido con cycleId determinístico', () {
      final c = MetabolicCycleResolver.openCycle(
        startedAt: DateTime.utc(2026, 6, 1, 2, 0),
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      );
      expect(c.cycleId, '2026-06-01T02:00:00.000Z');
      expect(c.isOpen, isTrue);
    });
  });

  group('SPEC-149 — expectedCloseAt', () {
    test('Usuario calendárico → fin del día local de now', () {
      final cycle = _openCycle(protocol: 'Ninguno');
      final now = DateTime(2026, 6, 1, 14, 0);
      final expectedClose = MetabolicCycleResolver.expectedCloseAt(
        openCycle: cycle,
        expectedWindowCloseTime: null,
        now: now,
      );
      expect(expectedClose, DateTime(2026, 6, 1, 23, 59, 59, 999));
    });

    test('Usuario TRE → expectedWindowCloseTime', () {
      final cycle = _openCycle(protocol: '16:8');
      final windowClose = DateTime(2026, 6, 2, 21, 0);
      final result = MetabolicCycleResolver.expectedCloseAt(
        openCycle: cycle,
        expectedWindowCloseTime: windowClose,
        now: DateTime(2026, 6, 2, 14, 0),
      );
      expect(result, windowClose);
    });

    test('Usuario TRE sin info de ventana → null', () {
      final cycle = _openCycle(protocol: '16:8');
      final result = MetabolicCycleResolver.expectedCloseAt(
        openCycle: cycle,
        expectedWindowCloseTime: null,
        now: DateTime(2026, 6, 2, 14, 0),
      );
      expect(result, isNull);
    });
  });

  group('SPEC-149 §8.1 — shouldClose: triggers en orden de prioridad', () {
    test('Ciclo ya cerrado → null (no doble cierre)', () {
      final closed = _openCycle().close(
        closedAt: DateTime(2026, 6, 2, 21, 0),
        reason: ClosureReason.manualNextFasting,
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        dailyScore: 80,
        pillarsCompleted: const CyclePillarsCompleted(
          fasting: true,
          sleep: true,
          hydration: true,
          exercise: true,
          nutrition: true,
        ),
        magnitudes: const CycleMagnitudes(
          fastingMagnitude: 1,
          sleepQualityScore: 1,
          hydrationMagnitude: 1,
          exerciseMagnitude: 1,
          nutritionMagnitude: 1,
        ),
        feedback: const CycleFeedback(
          achievements: [],
          gaps: [],
          insight: 'test',
        ),
      );
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: closed,
        now: DateTime(2026, 6, 3, 0, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 3, 0, 0),
      );
      expect(result, isNull);
    });

    test('cambiar de protocolo NO cierra el ciclo en curso', () {
      // 27-jul (auditoría): este test afirmaba lo contrario
      // (`ClosureReason.protocolChanged`) y llevaba en rojo desde el
      // 20-jul, cuando el trigger se ELIMINÓ por decisión de producto de
      // Carlos: cerraba el día en curso apenas el usuario tocaba "cambiar
      // protocolo" en Configuración, aunque estuviera en plena ventana de
      // alimentación sin intención de ayunar. Ver la nota extensa en
      // `metabolic_cycle_resolver.dart`.
      //
      // El test no se borra: se invierte. Cambiar el protocolo es una
      // preferencia pura y el ciclo abierto conserva el suyo hasta que el
      // usuario inicia un ayuno nuevo a propósito. Blindar esa regla vale
      // más que blindar la función que se quitó.
      final cycle = _openCycle(protocol: '16:8');
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 22, 0),
        currentProtocol: '20:4',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull,
          reason: 'el protocolo nuevo aplica al ciclo SIGUIENTE, no al actual');
    });

    test('manualNextFasting dispara con nuevo ayuno y >=30 min', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 21, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 2, 21, 0),
      );
      expect(result, ClosureReason.manualNextFasting);
    });

    test('manualNextFasting NO dispara con duración <30 min (toque accidental)',
        () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 21, 10),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 1, 21, 10),
      );
      expect(result, isNull, reason: 'falso cierre por toque accidental');
    });

    test('fallbackSleepDetected dispara con sueño + >=2h desde lastMeal', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 23, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: DateTime(2026, 6, 2, 20, 0),
        sleepDetectedAfterLastMeal: true,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackSleepDetected);
    });

    test('fallbackSleepDetected NO dispara si lastMeal <2h atrás', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 22, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: DateTime(2026, 6, 2, 21, 0),
        sleepDetectedAfterLastMeal: true,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull, reason: 'lastMeal hace solo 1h, muy cerca');
    });

    test('fallback3hAfterWindow dispara cuando pasaron 3h desde ventana', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 22, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 2, 19, 0),
        lastMealTime: DateTime(2026, 6, 2, 18, 30),
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallback3hAfterWindow);
    });

    test('fallback3hAfterWindow NO dispara con <3h post-ventana', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 21, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 2, 19, 0),
        lastMealTime: DateTime(2026, 6, 2, 18, 30),
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });

    test('fallbackAbsolute dispara con 50h sin nada (SPEC-245)', () {
      // SPEC-245 (2026-07-07): límite subido de 28h a 50h para soportar
      // ayunos extendidos (Eat Stop Eat 36h, ayunos de 48h) sin corte
      // prematuro. Este test usaba el límite viejo de 28h.
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 3, 23, 0), // 50h desde start
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackAbsolute);
    });

    // SPEC-189 (2026-06-05): trigger `fallbackCalendar` ELIMINADO. Cruzar
    // medianoche con protocolo "Ninguno" ya NO cierra el ciclo — el día
    // metabólico es event-driven, sin referencia al reloj. shouldClose → null.
    test('"Ninguno" cruzando medianoche NO cierra (SPEC-189: sin reloj)', () {
      final cycle = _openCycle(
        startedAt: DateTime(2026, 6, 1, 6, 0),
        protocol: 'Ninguno',
      );
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 0, 0, 1),
        currentProtocol: 'Ninguno',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });

    test('fallbackCalendar NO dispara mientras sigue el mismo día calendario',
        () {
      final cycle = _openCycle(
        startedAt: DateTime(2026, 6, 1, 6, 0),
        protocol: 'Ninguno',
      );
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 14, 0),
        currentProtocol: 'Ninguno',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });

    test(
        'con protocolo cambiado Y ayuno nuevo, cierra por manualNextFasting '
        '(no por el cambio de protocolo)', () {
      // 27-jul (auditoría): antes esperaba `protocolChanged`, trigger
      // retirado el 20-jul. Lo que este caso protege ahora es que el
      // cambio de protocolo no "secuestre" el motivo de cierre: quien
      // cierra el ciclo es el ayuno que el usuario inició a propósito, y
      // el motivo registrado debe reflejar esa intención — no una
      // preferencia de configuración que tocó de paso.
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 22, 0),
        currentProtocol: '20:4', // diferente del ciclo
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 2, 22, 0),
      );
      expect(result, ClosureReason.manualNextFasting);
    });

    test('Prioridad: manualNextFasting gana sobre fallbackSleepDetected', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 23, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: DateTime(2026, 6, 2, 20, 0),
        sleepDetectedAfterLastMeal: true,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 2, 23, 0),
      );
      expect(result, ClosureReason.manualNextFasting);
    });
  });

  group('Auditoría 2026-06-08 — bordes exactos, precedencias y no-cierre espurio',
      () {
    // ── Bordes exactos (donde se esconden los bugs) ──────────────────────────
    test('manualNextFasting en EXACTAMENTE 30 min → cierra (límite inclusivo)',
        () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 21, 30),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: true,
        newFastingStartedAt: DateTime(2026, 6, 1, 21, 30),
      );
      expect(result, ClosureReason.manualNextFasting);
    });

    test('fallbackSleepDetected en EXACTAMENTE 2h desde lastMeal → cierra', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 22, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: DateTime(2026, 6, 2, 20, 0),
        sleepDetectedAfterLastMeal: true,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackSleepDetected);
    });

    test('fallbackAbsolute en EXACTAMENTE 50h → cierra (SPEC-245)', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 3, 23, 0), // 50h exactas
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackAbsolute);
    });

    test('fallbackAbsolute en 49h59m → todavía NO cierra (SPEC-245)', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 3, 22, 59),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });

    // ── Precedencias faltantes ───────────────────────────────────────────────
    test('Prioridad: fallbackSleepDetected gana sobre fallback3hAfterWindow', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 23, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 2, 19, 0), // >3h pasados
        lastMealTime: DateTime(2026, 6, 2, 20, 0), // >2h
        sleepDetectedAfterLastMeal: true,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackSleepDetected);
    });

    test('Prioridad: fallback3hAfterWindow gana sobre fallbackAbsolute', () {
      // SPEC-245: límite absoluto es 50h (no 28h) — para que este test siga
      // probando la precedencia real (orden 4<5) ambos triggers deben poder
      // dispararse a la vez. Ciclo de >50h Y >3h post-ventana: gana el de
      // la ventana.
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 4, 0, 0), // 51h desde start
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 2, 19, 0), // >3h pasados
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallback3hAfterWindow);
    });

    // ── No-cierre espurio (regresión del incidente de hoy) ───────────────────
    test(
        'ciclo largo (23h) SIN ningún trigger → NO cierra (no churn espurio)',
        () {
      // Reproduce el caso del "ayuno corregido a ayer": ciclo abierto de 23h,
      // mismo protocolo, sin sueño, sin ventana pasada, sin nuevo ayuno, <28h.
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 12, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 11, 0), // 23h
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull,
          reason: 'sin trigger real, un ciclo abierto NO debe cerrarse solo');
    });

    test('arranque limpio (5 min, sin señales) → NO cierra', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 21, 5),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });

    // ── Ventana TRE cruzando medianoche (sin manejo calendárico especial) ────
    test('ventana TRE cerró 21:00; a las 00:30 (3.5h, cruzó medianoche) → cierra',
        () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 12, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 2, 0, 30), // 3.5h tras ventana, ya cruzó medianoche
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 1, 21, 0),
        lastMealTime: DateTime(2026, 6, 1, 20, 30),
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallback3hAfterWindow);
    });

    test('ventana TRE cerró 21:00; a las 22:30 (1.5h) → NO cierra aún', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 12, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 1, 22, 30),
        currentProtocol: '16:8',
        expectedWindowCloseTime: DateTime(2026, 6, 1, 21, 0),
        lastMealTime: DateTime(2026, 6, 1, 20, 30),
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, isNull);
    });
  });
}

