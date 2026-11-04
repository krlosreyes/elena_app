// Rediseño Hoy (2026-11-04): lógica pura de las piezas nuevas.

import 'package:elena_app/src/features/dashboard/presentation/widgets/hoy_cards.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_day_ring.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _closed(int day, ClosureReason reason) => MetabolicCycle(
      cycleId: 'c$day',
      startedAt: DateTime(2026, 11, day, 20),
      closedAt: DateTime(2026, 11, day + 1, 20),
      closureReason: reason,
      fastingProtocol: '16:8',
      tzOffsetMinutes: -300,
    );

void main() {
  group('MetabolicDayRingPainter.fractionFor', () {
    test('16:8: 12 h es la mitad del día', () {
      expect(
        MetabolicDayRingPainter.fractionFor(
            hours: 12, fastHours: 16, windowHours: 8),
        0.5,
      );
    });

    test('nunca pasa de 1 ni baja de 0', () {
      expect(
        MetabolicDayRingPainter.fractionFor(
            hours: 30, fastHours: 16, windowHours: 8),
        1.0,
      );
      expect(
        MetabolicDayRingPainter.fractionFor(
            hours: -2, fastHours: 16, windowHours: 8),
        0.0,
      );
    });
  });

  group('buildWeekDots', () {
    test('ordena del más viejo al más nuevo y termina en Hoy', () {
      final dots = buildWeekDots([
        _closed(3, ClosureReason.manualNextFasting), // martes
        _closed(1, ClosureReason.fallbackAbsolute), // domingo
        _closed(2, ClosureReason.manualNextFasting), // lunes
      ]);
      expect(dots.map((d) => d.label), ['D', 'L', 'M', 'Hoy']);
      expect(dots.map((d) => d.closedByYou), [false, true, true, false]);
      expect(dots.last.isToday, isTrue);
    });

    test('máximo 6 días + hoy', () {
      final dots = buildWeekDots([
        for (var d = 1; d <= 9; d++)
          _closed(d, ClosureReason.manualNextFasting),
      ]);
      expect(dots.length, 7);
      expect(dots.first.label, 'M'); // 4 nov 2026 = miércoles
    });
  });

  group('bodyNowText', () {
    test('al cumplir la meta invita a romper el ayuno', () {
      expect(
        bodyNowText(FastingPhase.transition, goalReached: true),
        contains('Cumpliste tu meta'),
      );
    });

    test('ayuno largo advierte síntomas de alarma', () {
      expect(
        bodyNowText(FastingPhase.autophagy, goalReached: false),
        contains('mareo'),
      );
    });
  });

  testWidgets('el anillo se pinta sin errores', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MetabolicDayRing(
          fastHours: 16,
          windowHours: 8,
          elapsedHours: 18,
          fastColor: Color(0xFF1D9E75),
          windowColor: Color(0xFF00C49A),
          child: Text('centro'),
        ),
      ),
    ));
    expect(find.text('centro'), findsOneWidget);
  });
}
