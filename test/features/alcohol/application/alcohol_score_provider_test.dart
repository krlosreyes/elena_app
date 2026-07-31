// SPEC-261.1: tests del enganche del costo del alcohol al Score del Día.

import 'package:elena_app/src/features/alcohol/application/alcohol_score_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyAlcoholPenalty', () {
    test('sin costo → score idéntico (backward-compatible)', () {
      expect(applyAlcoholPenalty(80, 0), 80);
      expect(applyAlcoholPenalty(100, 0), 100);
      expect(applyAlcoholPenalty(0, 0), 0);
    });

    test('resta el costo neto', () {
      expect(applyAlcoholPenalty(80, 10), 70);
      expect(applyAlcoholPenalty(55, 25), 30);
    });

    test('redondea el costo', () {
      expect(applyAlcoholPenalty(80, 10.4), 70); // 69.6 → 70
      expect(applyAlcoholPenalty(80, 10.6), 69); // 69.4 → 69
    });

    test('nunca baja de 0', () {
      expect(applyAlcoholPenalty(5, 10), 0);
      expect(applyAlcoholPenalty(0, 25), 0);
    });

    test('nunca sube de 100', () {
      // Un costo negativo no debería ocurrir, pero el clamp lo cubre.
      expect(applyAlcoholPenalty(100, -20), 100);
    });
  });
}
