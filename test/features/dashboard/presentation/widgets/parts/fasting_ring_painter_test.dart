// SPEC-117: smoke tests del FastingRingPainter.
//
// El painter dibuja el aro del ayuno: track de fondo + arco coloreado
// según la duración + hitos metabólicos (12h, 18h, 24h) + indicador
// "ahora". Validamos paint sin excepción para varios casos.

import 'dart:ui';

import 'package:elena_app/src/features/dashboard/presentation/widgets/parts/fasting_ring_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingRingPainter.paint', () {
    test('ayuno recién iniciado (5 min) → no lanza', () {
      final painter = FastingRingPainter(
        startTime: DateTime(2026, 5, 16, 17, 0),
        duration: const Duration(minutes: 5),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final canvas = Canvas(PictureRecorder());
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('ayuno en autofagia (24h) → no lanza', () {
      final painter = FastingRingPainter(
        startTime: DateTime(2026, 5, 15, 17, 0),
        duration: const Duration(hours: 24),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final canvas = Canvas(PictureRecorder());
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('ayuno > 24h → sweepAngle se clampea a 2π sin lanzar', () {
      // Test crítico: el painter usa clamp(0, 2*pi) para evitar arcos
      // mayores a 360°. Verificamos que un ayuno de 30h pinta sin error.
      final painter = FastingRingPainter(
        startTime: DateTime(2026, 5, 14, 17, 0),
        duration: const Duration(hours: 30),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final canvas = Canvas(PictureRecorder());
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('duración cero → no dibuja arco pero tampoco lanza', () {
      final painter = FastingRingPainter(
        startTime: DateTime(2026, 5, 16, 17, 0),
        duration: Duration.zero,
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final canvas = Canvas(PictureRecorder());
      expect(
        () => painter.paint(canvas, const Size(300, 300)),
        returnsNormally,
      );
    });

    test('tamaño pequeño (100px) renderea sin errores', () {
      final painter = FastingRingPainter(
        startTime: DateTime(2026, 5, 16, 17, 0),
        duration: const Duration(hours: 12),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final canvas = Canvas(PictureRecorder());
      expect(
        () => painter.paint(canvas, const Size(100, 100)),
        returnsNormally,
      );
    });
  });

  group('FastingRingPainter.shouldRepaint', () {
    test('siempre true (el painter recalcula el indicador cada frame)', () {
      // El painter usa `shouldRepaint` => true sin condiciones porque
      // el indicador "vivo" depende de DateTime.now() y siempre debe
      // recalcularse. Si esto cambia, este test debe actualizarse.
      final a = FastingRingPainter(
        startTime: DateTime(2026, 5, 16, 17, 0),
        duration: const Duration(hours: 1),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      final b = FastingRingPainter(
        startTime: DateTime(2026, 5, 16, 17, 0),
        duration: const Duration(hours: 1),
        phaseColor: Colors.green,
        indicatorColor: Colors.white,
      );
      expect(b.shouldRepaint(a), isTrue);
    });
  });
}
