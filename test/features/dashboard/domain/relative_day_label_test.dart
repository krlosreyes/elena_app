// SPEC-102.1: tests puros del helper RelativeDayLabel.

import 'package:elena_app/src/features/dashboard/domain/relative_day_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 5, 14, 10, 0);

  group('RelativeDayLabel.qualifier', () {
    test('mismo día (cualquier hora) → string vacío', () {
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 14, 0, 0), today),
        '',
      );
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 14, 23, 59), today),
        '',
      );
    });

    test('día siguiente → "mañana"', () {
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 15, 0, 0), today),
        'mañana',
      );
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 15, 14, 30), today),
        'mañana',
      );
    });

    test('día anterior → "ayer"', () {
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 13, 20, 30), today),
        'ayer',
      );
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 13, 23, 59), today),
        'ayer',
      );
    });

    test('más de un día adelante → "en N días"', () {
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 16), today),
        'en 2 días',
      );
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 17), today),
        'en 3 días',
      );
    });

    test('más de un día atrás → "hace N días"', () {
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 12), today),
        'hace 2 días',
      );
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 5, 10), today),
        'hace 4 días',
      );
    });

    test(
        'cambio de mes: hoy 1 may, target 30 abr → "ayer"',
        () {
      final firstOfMay = DateTime(2026, 5, 1, 10, 0);
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 4, 30, 23, 59), firstOfMay),
        'ayer',
      );
    });

    test('cambio de año: hoy 1 ene 2027, target 31 dic 2026 → "ayer"', () {
      final firstOfYear = DateTime(2027, 1, 1, 0, 0);
      expect(
        RelativeDayLabel.qualifier(DateTime(2026, 12, 31, 23, 0), firstOfYear),
        'ayer',
      );
    });

    test(
        'caso bug reportado: empezó ayer 20:30, ahora son las 09:00 → start '
        '"ayer", end (14:30 hoy) → vacío',
        () {
      final nowToday = DateTime(2026, 5, 14, 9, 0);
      final startYesterday = DateTime(2026, 5, 13, 20, 30);
      final endToday = DateTime(2026, 5, 14, 14, 30);

      expect(RelativeDayLabel.qualifier(startYesterday, nowToday), 'ayer');
      expect(RelativeDayLabel.qualifier(endToday, nowToday), '');
    });
  });
}
