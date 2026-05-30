// Tests del DayBoundaryResolver — SPEC-138.
//
// Cubre:
// - Claves de día (compacta YYYYMMDD e ISO YYYY-MM-DD).
// - startOfDay / endOfDay (límites, fin de mes, fin de año).
// - isSameDay / isInDayOf (fronteras inclusiva/exclusiva).
// - Atribución por punto medio para eventos que cruzan medianoche
//   (sueño y ayuno): los casos CA del §8 de la SPEC.
// - tzOffsetMinutes.

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int y, int mo, int d, [int h = 0, int mi = 0]) =>
      DateTime(y, mo, d, h, mi);

  group('Claves de día', () {
    test('dayKey → YYYYMMDD con padding', () {
      expect(DayBoundaryResolver.dayKey(at(2026, 5, 9, 3)), '20260509');
      expect(DayBoundaryResolver.dayKey(at(2026, 12, 31, 23, 59)), '20261231');
    });

    test('dayKeyIso → YYYY-MM-DD con padding', () {
      expect(DayBoundaryResolver.dayKeyIso(at(2026, 5, 9)), '2026-05-09');
      expect(DayBoundaryResolver.dayKeyIso(at(2026, 1, 1)), '2026-01-01');
    });

    test('la hora no altera la clave (mismo día calendario)', () {
      expect(
        DayBoundaryResolver.dayKey(at(2026, 5, 9, 0, 1)),
        DayBoundaryResolver.dayKey(at(2026, 5, 9, 23, 59)),
      );
    });
  });

  group('Límites del día', () {
    test('startOfDay → 00:00 del mismo día', () {
      expect(
        DayBoundaryResolver.startOfDay(at(2026, 5, 9, 14, 30)),
        at(2026, 5, 9, 0, 0),
      );
    });

    test('endOfDay → 00:00 del día siguiente', () {
      expect(
        DayBoundaryResolver.endOfDay(at(2026, 5, 9, 14, 30)),
        at(2026, 5, 10, 0, 0),
      );
    });

    test('endOfDay cruza fin de mes', () {
      expect(
        DayBoundaryResolver.endOfDay(at(2026, 5, 31, 10)),
        at(2026, 6, 1, 0, 0),
      );
    });

    test('endOfDay cruza fin de año', () {
      expect(
        DayBoundaryResolver.endOfDay(at(2026, 12, 31, 10)),
        at(2027, 1, 1, 0, 0),
      );
    });
  });

  group('isSameDay / isInDayOf', () {
    test('isSameDay ignora la hora', () {
      expect(
        DayBoundaryResolver.isSameDay(at(2026, 5, 9, 1), at(2026, 5, 9, 23)),
        isTrue,
      );
      expect(
        DayBoundaryResolver.isSameDay(at(2026, 5, 9, 23), at(2026, 5, 10, 0)),
        isFalse,
      );
    });

    test('isInDayOf: 00:00 inclusivo, 24:00 exclusivo', () {
      final ref = at(2026, 5, 9, 12);
      expect(DayBoundaryResolver.isInDayOf(at(2026, 5, 9, 0, 0), ref), isTrue);
      expect(
        DayBoundaryResolver.isInDayOf(at(2026, 5, 9, 23, 59), ref),
        isTrue,
      );
      expect(DayBoundaryResolver.isInDayOf(at(2026, 5, 10, 0, 0), ref), isFalse);
      expect(DayBoundaryResolver.isInDayOf(at(2026, 5, 8, 23, 59), ref), isFalse);
    });
  });

  group('Atribución por punto medio (CA §8.2)', () {
    test('sueño 23:00 → 07:00 se atribuye al día del despertar', () {
      final start = at(2026, 5, 9, 23, 0);
      final end = at(2026, 5, 10, 7, 0); // punto medio 03:00 del día 10
      expect(
        DayBoundaryResolver.attributionDayKey(start: start, end: end),
        '20260510',
      );
    });

    test('sueño 23:00 → 00:30 se atribuye al día anterior', () {
      final start = at(2026, 5, 9, 23, 0);
      final end = at(2026, 5, 10, 0, 30); // punto medio 23:45 del día 9
      expect(
        DayBoundaryResolver.attributionDayKey(start: start, end: end),
        '20260509',
      );
    });

    test('ayuno 16:8 que cierra 00:30 cae el día previo (CA §8.3)', () {
      // Empieza 08:30 del día 9, cierra 00:30 del día 10 (16h).
      final start = at(2026, 5, 9, 8, 30);
      final end = at(2026, 5, 10, 0, 30); // punto medio ~16:30 del día 9
      expect(
        DayBoundaryResolver.attributionDayKey(start: start, end: end),
        '20260509',
      );
    });

    test('evento sin cruce queda en su propio día', () {
      final start = at(2026, 5, 9, 8, 0);
      final end = at(2026, 5, 9, 16, 0);
      expect(
        DayBoundaryResolver.attributionDayKey(start: start, end: end),
        '20260509',
      );
    });

    test('end antes de start (malformado) → ancla a start', () {
      final start = at(2026, 5, 9, 23, 0);
      final end = at(2026, 5, 9, 22, 0);
      expect(
        DayBoundaryResolver.attributionDayKey(start: start, end: end),
        '20260509',
      );
    });

    test('midpoint es simétrico', () {
      final start = at(2026, 5, 9, 0, 0);
      final end = at(2026, 5, 9, 10, 0);
      expect(
        DayBoundaryResolver.midpoint(start, end),
        at(2026, 5, 9, 5, 0),
      );
    });
  });

  group('tzOffsetMinutes', () {
    test('coincide con el offset local del DateTime', () {
      final t = at(2026, 5, 9, 12);
      expect(
        DayBoundaryResolver.tzOffsetMinutes(t),
        t.timeZoneOffset.inMinutes,
      );
    });
  });
}
