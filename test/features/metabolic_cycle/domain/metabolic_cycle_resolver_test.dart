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

    test('protocolChanged dispara cuando protocol del ciclo != actual', () {
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
      expect(result, ClosureReason.protocolChanged);
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

    test('fallbackAbsolute dispara con 28h sin nada', () {
      final cycle = _openCycle(startedAt: DateTime(2026, 6, 1, 21, 0));
      final result = MetabolicCycleResolver.shouldClose(
        openCycle: cycle,
        now: DateTime(2026, 6, 3, 2, 0),
        currentProtocol: '16:8',
        expectedWindowCloseTime: null,
        lastMealTime: null,
        sleepDetectedAfterLastMeal: false,
        newFastingStartedExplicitly: false,
        newFastingStartedAt: null,
      );
      expect(result, ClosureReason.fallbackAbsolute);
    });

    test('fallbackCalendar dispara para "Ninguno" al pasar el día', () {
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
      expect(result, ClosureReason.fallbackCalendar);
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

    test('Prioridad: protocolChanged gana sobre manualNextFasting', () {
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
      expect(result, ClosureReason.protocolChanged);
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
}

