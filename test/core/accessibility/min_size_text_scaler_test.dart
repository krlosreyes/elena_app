import 'package:elena_app/src/core/accessibility/min_size_text_scaler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-309 — MinSizeTextScaler', () {
    test('sube los textos pequeños al mínimo legible', () {
      const s = MinSizeTextScaler(TextScaler.noScaling);
      expect(s.scale(8), kMinReadableFontSize);
      expect(s.scale(11), kMinReadableFontSize);
    });

    test('no toca los textos que ya son legibles', () {
      const s = MinSizeTextScaler(TextScaler.noScaling);
      expect(s.scale(14), 14);
      expect(s.scale(22), 22);
    });

    test('respeta el tamaño de texto elegido en el sistema', () {
      const s = MinSizeTextScaler(TextScaler.linear(1.3));
      expect(s.scale(14), closeTo(18.2, 0.001));
      expect(s.scale(8), kMinReadableFontSize);
    });
  });
}
