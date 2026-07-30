// SPEC-149: tests del value object MetabolicCycle + sus componentes.

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-149 — MetabolicCycle', () {
    final started = DateTime(2026, 6, 1, 21, 0);

    test('open() crea ciclo abierto con cycleId canónico', () {
      final c = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      expect(c.isOpen, isTrue);
      expect(c.isClosed, isFalse);
      expect(c.cycleId, started.toUtc().toIso8601String());
      expect(c.closedAt, isNull);
      expect(c.closureReason, isNull);
      expect(c.dailyScore, isNull);
    });

    test('buildCycleId genera el mismo ID para el mismo startedAt UTC', () {
      final id1 = MetabolicCycle.buildCycleId(started);
      final id2 = MetabolicCycle.buildCycleId(started);
      expect(id1, id2);
    });

    test('close() retorna copia cerrada sin mutar el original', () {
      final open = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      final closed = open.close(
        closedAt: started.add(const Duration(hours: 24)),
        reason: ClosureReason.manualNextFasting,
        fastingDurationHours: 16,
        feedingWindowHours: 8,
        dailyScore: 87,
        pillarsCompleted: const CyclePillarsCompleted(
          fasting: true,
          sleep: true,
          hydration: false,
          exercise: true,
          nutrition: true,
        ),
        magnitudes: const CycleMagnitudes(
          fastingMagnitude: 1.0,
          sleepQualityScore: 0.85,
          hydrationMagnitude: 0.65,
          exerciseMagnitude: 1.0,
          nutritionMagnitude: 0.9,
        ),
        feedback: const CycleFeedback(
          achievements: [],
          gaps: [],
          insight: 'test',
        ),
      );
      expect(open.isOpen, isTrue, reason: 'original no debe mutarse');
      expect(closed.isClosed, isTrue);
      expect(closed.dailyScore, 87);
      expect(closed.closureReason, ClosureReason.manualNextFasting);
      expect(closed.cycleId, open.cycleId, reason: 'cycleId se preserva');
    });

    test('reanchor() mueve startedAt y preserva cycleId sin cerrar', () {
      final open = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: -300,
      );
      final nuevoInicio = started.subtract(const Duration(hours: 9));
      final reanchored = open.reanchor(newStartedAt: nuevoInicio);

      expect(open.startedAt, started, reason: 'original no debe mutarse');
      expect(reanchored.startedAt, nuevoInicio);
      expect(reanchored.isOpen, isTrue, reason: 'sigue abierto');
      expect(reanchored.closedAt, isNull);
      expect(reanchored.cycleId, open.cycleId,
          reason: 'el cycleId se preserva para actualizar el mismo doc');
      expect(reanchored.fastingProtocol, '16:8');
      expect(reanchored.tzOffsetMinutes, -300);
    });

    test('reanchor() preserva liveScore del ciclo abierto', () {
      final open = MetabolicCycle(
        cycleId: MetabolicCycle.buildCycleId(started),
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
        liveScore: 73,
      );
      final reanchored = open.reanchor(
          newStartedAt: started.subtract(const Duration(hours: 2)));
      expect(reanchored.liveScore, 73);
    });

    test('reanchor() lanza StateError si el ciclo ya está cerrado', () {
      final closed = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      ).close(
        closedAt: started.add(const Duration(hours: 20)),
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
        feedback: const CycleFeedback(achievements: [], gaps: [], insight: 'x'),
      );
      expect(
        () => closed.reanchor(newStartedAt: started),
        throwsStateError,
      );
    });

    test('reanchor() lanza ArgumentError si newStartedAt es futuro vs now', () {
      final open = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      );
      expect(
        () => open.reanchor(
          newStartedAt: started.add(const Duration(hours: 1)),
          now: started,
        ),
        throwsArgumentError,
      );
    });

    test('close() falla si closedAt <= startedAt', () {
      final open = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      );
      expect(
        () => open.close(
          closedAt: started.subtract(const Duration(hours: 1)),
          reason: ClosureReason.fallbackAbsolute,
          fastingDurationHours: 0,
          feedingWindowHours: 0,
          dailyScore: 50,
          pillarsCompleted: const CyclePillarsCompleted(
            fasting: false,
            sleep: false,
            hydration: false,
            exercise: false,
            nutrition: false,
          ),
          magnitudes: const CycleMagnitudes(
            fastingMagnitude: 0,
            sleepQualityScore: 0,
            hydrationMagnitude: 0,
            exerciseMagnitude: 0,
            nutritionMagnitude: 0,
          ),
          feedback: const CycleFeedback(
            achievements: [],
            gaps: [],
            insight: 'x',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('close() falla si dailyScore fuera de [0, 100]', () {
      final open = MetabolicCycle.open(
        startedAt: started,
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      );
      expect(
        () => open.close(
          closedAt: started.add(const Duration(hours: 24)),
          reason: ClosureReason.manualNextFasting,
          fastingDurationHours: 16,
          feedingWindowHours: 8,
          dailyScore: 150,
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
            insight: 'x',
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('SPEC-149 — CyclePillarsCompleted', () {
    test('count cuenta correctamente con 0/3/5 pilares', () {
      const empty = CyclePillarsCompleted(
        fasting: false,
        sleep: false,
        hydration: false,
        exercise: false,
        nutrition: false,
      );
      expect(empty.count, 0);
      expect(empty.isPerfect, isFalse);

      const partial = CyclePillarsCompleted(
        fasting: true,
        sleep: true,
        hydration: false,
        exercise: true,
        nutrition: false,
      );
      expect(partial.count, 3);
      expect(partial.isPerfect, isFalse);

      const all = CyclePillarsCompleted(
        fasting: true,
        sleep: true,
        hydration: true,
        exercise: true,
        nutrition: true,
      );
      expect(all.count, 5);
      expect(all.isPerfect, isTrue);
    });
  });

  group('SPEC-149 — CycleMagnitudes.weakest', () {
    test('identifica el pilar más débil', () {
      const m = CycleMagnitudes(
        fastingMagnitude: 0.9,
        sleepQualityScore: 0.7,
        hydrationMagnitude: 0.4,
        exerciseMagnitude: 0.85,
        nutritionMagnitude: 0.95,
      );
      final w = m.weakest;
      expect(w.pillar, 'hydration');
      expect(w.magnitude, 0.4);
    });

    test('con magnitudes iguales retorna el primero comparado', () {
      const m = CycleMagnitudes(
        fastingMagnitude: 0.5,
        sleepQualityScore: 0.5,
        hydrationMagnitude: 0.5,
        exerciseMagnitude: 0.5,
        nutritionMagnitude: 0.5,
      );
      // El primer comparado es fasting (no se reemplaza con iguales).
      expect(m.weakest.pillar, 'fasting');
    });
  });

  group('SPEC-149 — ClosureReason.serialization', () {
    test('roundtrip para todas las razones', () {
      for (final reason in ClosureReason.values) {
        final serialized = reason.value;
        final restored = ClosureReasonSerialization.fromString(serialized);
        expect(restored, reason);
      }
    });

    test('fromString retorna null para input inválido o null', () {
      expect(ClosureReasonSerialization.fromString(null), isNull);
      expect(ClosureReasonSerialization.fromString('invalid'), isNull);
    });
  });
}
