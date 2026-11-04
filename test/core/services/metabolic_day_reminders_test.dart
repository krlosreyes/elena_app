// Día metabólico (2026-11-04): planificador de los 3 avisos del ciclo.

import 'package:elena_app/src/core/services/metabolic_day_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetabolicDayReminders.plan — 16:8, despierta 6:00', () {
    MetabolicDayReminderPlan plan({
      required bool isFasting,
      required DateTime anchor,
      required DateTime now,
      int target = 16,
    }) =>
        MetabolicDayReminders.plan(
          isFasting: isFasting,
          anchor: anchor,
          targetHours: target,
          wakeHour: 6,
          wakeMinute: 0,
          now: now,
        );

    test('en ayuno desde las 8 p. m.: ventana 12 p. m., cierre 8:30 p. m., '
        'rescate 6:30 a. m. siguiente', () {
      final p = plan(
        isFasting: true,
        anchor: DateTime(2026, 11, 4, 20, 0),
        now: DateTime(2026, 11, 4, 21, 0),
      );
      expect(p.windowOpensAt, DateTime(2026, 11, 5, 12, 0));
      expect(p.closeDayAt, DateTime(2026, 11, 5, 20, 30));
      expect(p.rescueAt, DateTime(2026, 11, 6, 6, 30));
    });

    test('ventana abierta a las 11 a. m. (terminó ayuno antes): cierre 7:30 '
        'p. m., sin aviso de ventana', () {
      final p = plan(
        isFasting: false,
        anchor: DateTime(2026, 11, 5, 11, 0),
        now: DateTime(2026, 11, 5, 11, 5),
      );
      expect(p.windowOpensAt, isNull);
      expect(p.closeDayAt, DateTime(2026, 11, 5, 19, 30));
      expect(p.rescueAt, DateTime(2026, 11, 6, 6, 30));
    });

    test('el olvido: ya pasó el cierre → solo queda el rescate', () {
      final p = plan(
        isFasting: false,
        anchor: DateTime(2026, 11, 5, 12, 0),
        now: DateTime(2026, 11, 5, 23, 0),
      );
      expect(p.closeDayAt, isNull);
      expect(p.rescueAt, DateTime(2026, 11, 6, 6, 30));
    });

    test('si pasaron más de 36 h, no insiste', () {
      final p = plan(
        isFasting: false,
        anchor: DateTime(2026, 11, 1, 12, 0),
        now: DateTime(2026, 11, 4, 9, 0),
      );
      expect(p.windowOpensAt, isNull);
      expect(p.closeDayAt, isNull);
      expect(p.rescueAt, isNull);
    });

    test('protocolo "Ninguno" (0 h) → ningún aviso', () {
      final p = plan(
        isFasting: false,
        anchor: DateTime(2026, 11, 5, 12, 0),
        now: DateTime(2026, 11, 5, 13, 0),
        target: 0,
      );
      expect(p.closeDayAt, isNull);
      expect(p.rescueAt, isNull);
    });

    test('ventana por protocolo', () {
      expect(MetabolicDayReminders.windowFor(16), const Duration(hours: 8));
      expect(MetabolicDayReminders.windowFor(23), const Duration(hours: 1));
      expect(MetabolicDayReminders.windowFor(36), const Duration(hours: 1));
    });
  });
}
