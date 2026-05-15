// SPEC-112: tests puros del MonthKey (lógica de rango por mes).

import 'package:elena_app/src/features/analysis/application/monthly_summaries_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthKey navegación', () {
    test('previous en enero retrocede a diciembre del año anterior', () {
      const m = MonthKey(year: 2026, month: 1);
      final p = m.previous();
      expect(p.year, 2025);
      expect(p.month, 12);
    });

    test('next en diciembre avanza a enero del año siguiente', () {
      const m = MonthKey(year: 2026, month: 12);
      final n = m.next();
      expect(n.year, 2027);
      expect(n.month, 1);
    });

    test('navegación intra-año mantiene el año', () {
      const m = MonthKey(year: 2026, month: 5);
      expect(m.previous(), const MonthKey(year: 2026, month: 4));
      expect(m.next(), const MonthKey(year: 2026, month: 6));
    });
  });

  group('MonthKey rangos', () {
    test('firstDay y lastDay son correctos en mayo (31 días)', () {
      const m = MonthKey(year: 2026, month: 5);
      expect(m.firstDay(), DateTime(2026, 5, 1));
      expect(m.lastDay(), DateTime(2026, 5, 31));
      expect(m.daysInMonth(), 31);
    });

    test('febrero año bisiesto 2024 tiene 29 días', () {
      const m = MonthKey(year: 2024, month: 2);
      expect(m.daysInMonth(), 29);
    });

    test('febrero año no bisiesto 2026 tiene 28 días', () {
      const m = MonthKey(year: 2026, month: 2);
      expect(m.daysInMonth(), 28);
    });

    test('abril tiene 30 días', () {
      const m = MonthKey(year: 2026, month: 4);
      expect(m.daysInMonth(), 30);
    });
  });

  group('MonthKey claves de fecha (YYYY-MM-DD)', () {
    test('fromDateKey y toDateKey con pad de cero', () {
      const m = MonthKey(year: 2026, month: 5);
      expect(m.fromDateKey(), '2026-05-01');
      expect(m.toDateKey(), '2026-05-31');
    });

    test('enero con pad', () {
      const m = MonthKey(year: 2026, month: 1);
      expect(m.fromDateKey(), '2026-01-01');
      expect(m.toDateKey(), '2026-01-31');
    });

    test('febrero 2024 (bisiesto) → 29 días en toDateKey', () {
      const m = MonthKey(year: 2024, month: 2);
      expect(m.toDateKey(), '2024-02-29');
    });
  });

  group('MonthKey equality', () {
    test('mismo year+month son iguales', () {
      expect(
        const MonthKey(year: 2026, month: 5),
        const MonthKey(year: 2026, month: 5),
      );
    });

    test('distinto year o month no son iguales', () {
      expect(
        const MonthKey(year: 2026, month: 5) ==
            const MonthKey(year: 2026, month: 6),
        isFalse,
      );
    });
  });
}
