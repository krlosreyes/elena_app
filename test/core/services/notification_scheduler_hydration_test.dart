// Fix notificaciones (2026-10-30): la hidratación pasó de ~20 avisos diarios
// (uno cada 45 min, SPEC-150/241) a UN solo recordatorio a mitad de la
// jornada, apagado por defecto. Estos tests reemplazan a los de la cadencia.

import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recordatorio único de agua', () {
    test('wake 7:00, sleep 23:00 → punto medio entre 7:30 y 21:00 (14:15)',
        () {
      final t = NotificationScheduler.hydrationReminderTime(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
      )!;
      expect(t.hour, 14);
      expect(t.minute, 15);
    });

    test('si duerme antes de las 21, el cutoff es su hora de dormir', () {
      final t = NotificationScheduler.hydrationReminderTime(
        wakeHour: 6,
        wakeMinute: 0,
        sleepHour: 19,
      )!;
      // 6:30 → 19:00 = 750 min; mitad = 375 min → 12:45.
      expect(t.hour, 12);
      expect(t.minute, 45);
    });

    test('sin ventana útil (despierta después del cutoff) → null', () {
      final t = NotificationScheduler.hydrationReminderTime(
        wakeHour: 21,
        wakeMinute: 0,
        sleepHour: 23,
      );
      expect(t, isNull);
    });
  });
}
