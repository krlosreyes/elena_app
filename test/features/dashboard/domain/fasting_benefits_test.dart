// SPEC-101: tests puros del FastingBenefits helper.

import 'package:elena_app/src/features/dashboard/domain/fasting_benefits.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
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

    test('transition (12-18h) cita cetogénesis y cambio de combustible', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.transition,
        const Duration(hours: 14),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, anyOf(contains('cetogén'), contains('cetog'),
          contains('gluconeogénesis')));
      expect(joined, contains('grasa'));
    });

    test('fatBurning (18-24h) cita cetosis y lipólisis', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.fatBurning,
        const Duration(hours: 20),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('cetosis'));
      expect(joined, contains('lipólisis'));
    });

    test('autophagy (24-48h) cita autofagia y IGF-1', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.autophagy,
        const Duration(hours: 30),
      );
      final joined = list.join(' ').toLowerCase();
      expect(joined, contains('autofagia'));
      expect(joined, contains('igf-1'));
    });

    test('survival (48h+) cita renovación celular', () {
      final list = FastingBenefits.benefitsFor(
        FastingPhase.survival,
        const Duration(hours: 60),
      );
      expect(list, isNotEmpty);
      expect(list.join(' ').toLowerCase(), contains('regen'));
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
