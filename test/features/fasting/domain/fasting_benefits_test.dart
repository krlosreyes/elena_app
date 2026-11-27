// SPEC-101: tests puros del FastingBenefits helper.

import 'package:elena_app/src/features/fasting/domain/fasting_benefits.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingBenefits.benefitsFor — cada fase tiene beneficios', () {
    test('FastingPhase.none → al menos 1 item de reconocimiento', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.none,
        const Duration(minutes: 30),
      );
      expect(list, isNotEmpty);
      expect(list.first.toLowerCase(), contains('insulina'));
    });

    test('postAbsorption (0-12h) cita glucógeno e insulina', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.postAbsorption,
        const Duration(hours: 6),
      );
      expect(list, isNotEmpty);
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('insulina'));
      expect(joined, contains('glucógeno'));
    });

    test('transition (12-18h): uso gradual de grasa (SPEC-309)', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.transition,
        const Duration(hours: 14),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('grasa'));
      expect(joined, contains('gradual'));
    });

    test('fatBurning (18-24h) cita cuerpos cetónicos y grasa', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.fatBurning,
        const Duration(hours: 20),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('cetónicos'));
      expect(joined, contains('grasa'));
    });

    test('autophagy (24-48h): autofagia sin hora exacta (SPEC-309)', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.autophagy,
        const Duration(hours: 30),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('autofagia'));
      expect(joined, contains('no hay una hora exacta'));
    });

    test('survival (48h+) pide supervisión médica', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.survival,
        const Duration(hours: 60),
      );
      expect(list, isNotEmpty);
      expect(list.join(' ').toLowerCase(), contains('supervisión médica'));
    });
  });

  group('FastingBenefits.milestoneLabel', () {
    test('cada fase devuelve label no vacío', () {
      for (final phase in FastingPhase.values) {
        final label = FastingBenefits.milestoneLabel(phase);
        expect(label, isNotEmpty, reason: 'phase=$phase');
      }
    });
  });
}
