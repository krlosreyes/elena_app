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
    // Hoy = viernes 6 nov 2026, 17:00.
    final now = DateTime(2026, 11, 6, 17);

    test('7 días del calendario que terminan hoy', () {
      final dots = buildWeekDots([], now);
      expect(dots.length, 7);
      expect(dots.first.date, DateTime(2026, 10, 31));
      expect(dots.last.date, DateTime(2026, 11, 6));
      expect(dots.map((d) => d.label), ['S', 'D', 'L', 'M', 'M', 'J', 'Hoy']);
      expect(
          dots.map((d) => d.dayNumber), ['31', '1', '2', '3', '4', '5', '6']);
      expect(dots.last.isToday, isTrue);
    });

    test('cada día metabólico cae en la fecha de su punto medio', () {
      // 3 nov 20:00 → 4 nov 20:00: se vive el 4.
      final dots = buildWeekDots([
        _closed(3, ClosureReason.manualNextFasting),
        _closed(4, ClosureReason.fallbackAbsolute),
      ], now);
      final byDay = {for (final d in dots) d.date.day: d.state};
      expect(byDay[4], WeekDayState.closedByYou);
      expect(byDay[5], WeekDayState.closedAuto);
      expect(byDay[3], WeekDayState.none);
    });

    test('los días sin registro quedan como hueco', () {
      final dots = buildWeekDots([
        _closed(1, ClosureReason.manualNextFasting), // se vive el 2
        _closed(4, ClosureReason.manualNextFasting), // se vive el 5
      ], now);
      expect(dots.map((d) => d.state), [
        WeekDayState.none, // 31
        WeekDayState.none, // 1
        WeekDayState.closedByYou, // 2
        WeekDayState.none, // 3
        WeekDayState.none, // 4
        WeekDayState.closedByYou, // 5
        WeekDayState.none, // hoy
      ]);
    });

    test('ignora días fuera de la ventana', () {
      final dots =
          buildWeekDots([_closed(20, ClosureReason.manualNextFasting)], now);
      expect(dots.where((d) => d.closedByYou), isEmpty);
    });
  });

  group('weekRangeLabel y weekClosedCount', () {
    test('rango con dos meses y con uno', () {
      expect(weekRangeLabel(buildWeekDots([], DateTime(2026, 11, 6))),
          '31 oct – 6 nov');
      expect(weekRangeLabel(buildWeekDots([], DateTime(2026, 11, 9))),
          '3 – 9 nov');
    });

    test('cuenta desde el primer día con registro', () {
      final now = DateTime(2026, 11, 6, 17);
      final dots = buildWeekDots([
        _closed(2, ClosureReason.manualNextFasting), // 3
        _closed(4, ClosureReason.fallbackAbsolute), // 5
      ], now);
      // Días contados: 3, 4, 5 → 1 cerrado por ti.
      expect(weekClosedCount(dots), (1, 3));
      expect(weekClosedCount(buildWeekDots([], now)), (0, 0));
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
