// SPEC-117: smoke tests del BiologicalCyclesPainter.
//
// El painter dibuja el fondo del reloj circadiano (24h con marcas,
// fases activas, símbolos sol/luna). Validamos que no lance excepción
// y que shouldRepaint detecte cambios de hora correctamente.

import 'dart:ui';

import 'package:elena_app/src/features/dashboard/presentation/widgets/parts/biological_cycles_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiologicalCyclesPainter.paint', () {
    test('no lanza excepción en horario diurno', () {
      final painter = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 12, 30),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('no lanza excepción en horario nocturno', () {
      final painter = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 3, 0),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('renderea correctamente con tamaños pequeños', () {
      final painter = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 9, 0),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(100, 100)),
        returnsNormally,
      );
    });
  });

  group('BiologicalCyclesPainter.shouldRepaint', () {
    test('true cuando cambia el minuto', () {
      final a = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 10, 0),
      );
      final b = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 10, 1),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('true cuando cambia la hora', () {
      final a = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 10, 0),
      );
      final b = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 11, 0),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('false cuando solo cambian los segundos (no repinta cada segundo)',
        () {
      final a = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 10, 0, 0),
      );
      final b = BiologicalCyclesPainter(
        indicatorColor: Colors.white,
        currentTime: DateTime(2026, 5, 16, 10, 0, 30),
      );
      expect(b.shouldRepaint(a), isFalse);
    });
  });
}
