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

    test('Cadencia exacta de 30 min entre slots consecutivos', () {
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      for (int i = 1; i < slots.length; i++) {
        final diff = slots[i].difference(slots[i - 1]);
        expect(
          diff,
          const Duration(minutes: 30),
          reason: 'cadencia entre slot $i y $i-1 debería ser 30 min',
        );
      }
    });

    test('Wake 7:00 sleep 23:00 → ~28 slots (cadencia 30 min)', () {
      // De 7:30 a 21:00 son 13.5h. Con cadencia 30 min: 810/30 + 1 = 28 slots
      // (cabe holgado en los 40 IDs reservados).
      final slots = computeHydrationSlots(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      );
      expect(slots.length, anyOf(27, 28));
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

    test('IDs reservados son 400-439 (40 slots — cadencia 30 min)', () {
      expect(NotificationIds.hydrationStart, 400);
      expect(NotificationIds.hydrationEnd, 439);
      expect(
        NotificationIds.hydrationEnd - NotificationIds.hydrationStart + 1,
        40,
      );
    });
  });

  group('Audit notif — "modo reparación" anclado al sueño real', () {
    DateTime sleepAt(int h, int m) => DateTime(2000, 1, 1, h, m);

    test('Duerme temprano (20:00) → reparación 30 min antes (19:30)', () {
      // Antes le llegaba 21:30, ya dormido = fuera de tiempo. Ahora 19:30.
      final lock = NotificationScheduler.repairLockActiveTime(sleepAt(20, 0));
      expect(lock.hour, 19);
      expect(lock.minute, 30);
    });

    test('Duerme 21:00 → reparación 20:30 (antes de acostarse)', () {
      final lock = NotificationScheduler.repairLockActiveTime(sleepAt(21, 0));
      expect(lock.hour, 20);
      expect(lock.minute, 30);
    });

    test('Duerme tarde (23:00) → tope circadiano 21:30', () {
      final lock = NotificationScheduler.repairLockActiveTime(sleepAt(23, 0));
      expect(lock.hour, 21);
      expect(lock.minute, 30);
    });

    test('Duerme 22:00 (límite) → tope circadiano 21:30', () {
      final lock = NotificationScheduler.repairLockActiveTime(sleepAt(22, 0));
      expect(lock.hour, 21);
      expect(lock.minute, 30);
    });

    test('Duerme pasada la medianoche (01:00) → tope 21:30 (no 00:30)', () {
      final lock = NotificationScheduler.repairLockActiveTime(sleepAt(1, 0));
      expect(lock.hour, 21);
      expect(lock.minute, 30);
    });

    test('Reparación nunca supera el tope circadiano 21:30', () {
      for (var h = 18; h <= 23; h++) {
        final lock = NotificationScheduler.repairLockActiveTime(sleepAt(h, 45));
        final afterCap = lock.hour > 21 || (lock.hour == 21 && lock.minute > 30);
        expect(afterCap, isFalse, reason: 'sleep $h:45 → ${lock.hour}:${lock.minute}');
      }
    });
  });
}
