// SPEC-150 §7.1: tests del HydrationMessagePool.

import 'package:elena_app/src/features/hydration/domain/hydration_message.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_message_pool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-150 §7.1 — Pool estructura', () {
    test('Total 12 mensajes (3 por período × 4 períodos)', () {
      expect(HydrationMessagePool.totalMessages, 12);
    });

    test('Cada DayPeriod tiene exactamente 3 mensajes', () {
      for (final period in DayPeriod.values) {
        expect(
          HydrationMessagePool.messagesFor(period).length,
          3,
          reason: 'period $period debería tener 3 mensajes',
        );
      }
    });

    test('Todos los mensajes tienen id único', () {
      final allIds = <String>{};
      for (final period in DayPeriod.values) {
        for (final m in HydrationMessagePool.messagesFor(period)) {
          expect(
            allIds.add(m.id),
            isTrue,
            reason: 'ID duplicado: ${m.id}',
          );
        }
      }
    });

    test('Todos los mensajes tienen citation no vacía', () {
      for (final period in DayPeriod.values) {
        for (final m in HydrationMessagePool.messagesFor(period)) {
          expect(m.citation, isNotEmpty);
        }
      }
    });

    test('Cada mensaje pertenece al period del array que lo contiene', () {
      for (final period in DayPeriod.values) {
        for (final m in HydrationMessagePool.messagesFor(period)) {
          expect(m.period, period);
        }
      }
    });
  });

  group('SPEC-150 §7.1 — periodFor', () {
    test('Horas del rango → período correcto', () {
      expect(HydrationMessagePool.periodFor(5), DayPeriod.morning);
      expect(HydrationMessagePool.periodFor(8), DayPeriod.morning);
      expect(HydrationMessagePool.periodFor(10), DayPeriod.morning);
      expect(HydrationMessagePool.periodFor(11), DayPeriod.midday);
      expect(HydrationMessagePool.periodFor(13), DayPeriod.midday);
      expect(HydrationMessagePool.periodFor(14), DayPeriod.afternoon);
      expect(HydrationMessagePool.periodFor(17), DayPeriod.afternoon);
      expect(HydrationMessagePool.periodFor(18), DayPeriod.evening);
      expect(HydrationMessagePool.periodFor(20), DayPeriod.evening);
    });

    test('Horas fuera de ventana activa → evening (default)', () {
      expect(HydrationMessagePool.periodFor(2), DayPeriod.evening);
      expect(HydrationMessagePool.periodFor(22), DayPeriod.evening);
      expect(HydrationMessagePool.periodFor(0), DayPeriod.evening);
    });
  });

  group('SPEC-150 §7.1 — selectFor determinístico', () {
    test('Mismo slot mismo día → mismo mensaje', () {
      final now = DateTime(2026, 6, 1, 8);
      final m1 = HydrationMessagePool.selectFor(
        scheduledTime: now,
        slotIndex: 0,
      );
      final m2 = HydrationMessagePool.selectFor(
        scheduledTime: now,
        slotIndex: 0,
      );
      expect(m1.id, m2.id);
    });

    test('Slot 8:00 del 1-Jun-2026 retorna mensaje de morning', () {
      final m = HydrationMessagePool.selectFor(
        scheduledTime: DateTime(2026, 6, 1, 8),
        slotIndex: 0,
      );
      expect(m.period, DayPeriod.morning);
    });

    test('Slot 13:00 → midday', () {
      final m = HydrationMessagePool.selectFor(
        scheduledTime: DateTime(2026, 6, 1, 13),
        slotIndex: 0,
      );
      expect(m.period, DayPeriod.midday);
    });

    test('Slot 16:00 → afternoon', () {
      final m = HydrationMessagePool.selectFor(
        scheduledTime: DateTime(2026, 6, 1, 16),
        slotIndex: 0,
      );
      expect(m.period, DayPeriod.afternoon);
    });

    test('Slot 19:00 → evening', () {
      final m = HydrationMessagePool.selectFor(
        scheduledTime: DateTime(2026, 6, 1, 19),
        slotIndex: 0,
      );
      expect(m.period, DayPeriod.evening);
    });

    test(
      'Día consecutivo mismo slot → mensaje distinto (rotación por day_of_year)',
      () {
        final day1 = HydrationMessagePool.selectFor(
          scheduledTime: DateTime(2026, 6, 1, 8),
          slotIndex: 0,
        );
        final day2 = HydrationMessagePool.selectFor(
          scheduledTime: DateTime(2026, 6, 2, 8),
          slotIndex: 0,
        );
        expect(day1.id, isNot(day2.id));
      },
    );

    test('Slots distintos del mismo día → mensajes potencialmente distintos',
        () {
      // 3 slots seguidos del mismo período. Como el pool tiene 3 mensajes
      // y la fórmula es (dayOfYear + slotIndex) % 3, los 3 slots cubren
      // los 3 mensajes posibles del período.
      final results = <String>{};
      for (int i = 0; i < 3; i++) {
        final m = HydrationMessagePool.selectFor(
          scheduledTime: DateTime(2026, 6, 1, 8),
          slotIndex: i,
        );
        results.add(m.id);
      }
      expect(results.length, 3, reason: '3 slots → 3 mensajes distintos');
    });
  });
}
