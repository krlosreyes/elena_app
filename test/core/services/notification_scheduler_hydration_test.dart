// SPEC-150 §7.2: tests de la cadencia y cutoff del scheduler de hidratación.
//
// Estos tests verifican la lógica matemática del cálculo de slots
// directamente sin tocar el plugin flutter_local_notifications (que no
// funciona en testing). Replicamos la fórmula de scheduleHydrationReminders
// para probar inputs/outputs.

import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper que replica la matemática del scheduler — útil para validar
/// la cadencia sin invocar al plugin nativo de notificaciones.
List<DateTime> computeHydrationSlots({
  required int wakeHour,
  required int wakeMinute,
  required int sleepHour,
}) {
  final slots = <DateTime>[];
  final cutoffHour = sleepHour < NotificationScheduler.kHydrationCutoffHour
      ? sleepHour
      : NotificationScheduler.kHydrationCutoffHour;
  DateTime current = DateTime(2000, 1, 1, wakeHour, wakeMinute)
      .add(NotificationScheduler.kHydrationFirstSlotOffset);
  final endTime = DateTime(2000, 1, 1, cutoffHour, 0);
  final maxSlots =
      NotificationIds.hydrationEnd - NotificationIds.hydrationStart + 1;
  while (!current.isAfter(endTime) && slots.length < maxSlots) {
    slots.add(current);
    current = current.add(NotificationScheduler.kHydrationCadence);
  }
  return slots;
}

void main() {
  group('SPEC-150 §7.2 — Cadencia y cutoff', () {
    test('Wake 7:00 + sleep 23:00 → primer slot 7:30, último ≤ 21:00', () {
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      expect(slots.first.hour, 7);
      expect(slots.first.minute, 30);
      expect(slots.last.hour, lessThanOrEqualTo(21));
    });

    test('Wake 6:00 + sleep 19:00 → cutoff 19:00 (no 21)', () {
      final slots = computeHydrationSlots(
        wakeHour: 6,
        wakeMinute: 0,
        sleepHour: 19,
      );
      expect(slots.last.hour, lessThanOrEqualTo(19));
    });

    test('Cadencia exacta de 90 min entre slots consecutivos', () {
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      for (int i = 1; i < slots.length; i++) {
        final diff = slots[i].difference(slots[i - 1]);
        expect(
          diff,
          const Duration(minutes: 90),
          reason: 'cadencia entre slot $i y $i-1 debería ser 90 min',
        );
      }
    });

    test('Wake 7:00 sleep 23:00 → ~9-10 slots (matemáticamente esperado)', () {
      // De 7:30 a 21:00 son 13.5h. Con cadencia 90 min: 13.5 / 1.5 = 9.
      // Más el slot inicial = 10 si encaja exacto, 9 si redondeamos abajo.
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      expect(slots.length, anyOf(9, 10));
    });

    test('Wake 7:00 sleep 23:00 → todos los slots dentro de [7:30, 21:00]', () {
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      for (final s in slots) {
        // Está entre 7:30 y 21:00 (inclusive). Como manejamos DateTime
        // base 2000-01-01, comparamos por hour/minute.
        final inFirst = s.hour > 7 || (s.hour == 7 && s.minute >= 30);
        final inLast = s.hour < 21 || (s.hour == 21 && s.minute == 0);
        expect(inFirst, isTrue, reason: '$s antes de 7:30');
        expect(inLast, isTrue, reason: '$s después de 21:00');
      }
    });

    test('Sleep 5:00 (caso edge: sleep < wake nominal) → cutoff 5:00', () {
      // Usuario que duerme muy temprano (turnos noche). cutoff respeta su sleep.
      final slots = computeHydrationSlots(
        wakeHour: 22,
        wakeMinute: 0,
        sleepHour: 5,
      );
      // Como wake 22:30 > cutoff 5:00, no debería haber slots.
      expect(slots, isEmpty);
    });

    test('IDs reservados son 400-419 (20 slots)', () {
      expect(NotificationIds.hydrationStart, 400);
      expect(NotificationIds.hydrationEnd, 419);
      expect(
        NotificationIds.hydrationEnd - NotificationIds.hydrationStart + 1,
        20,
      );
    });
  });
}
