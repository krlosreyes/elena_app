// SPEC-76 §6 — tests del versionado del disclaimer médico.

import 'package:elena_app/src/features/auth/domain/health_disclaimer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-76 — kHealthDisclaimerConditions', () {
    test('contiene exactamente 5 condiciones (IMR_BIBLIOGRAPHY §11)', () {
      expect(kHealthDisclaimerConditions.length, 5);
    });

    test('cada condición tiene icon, title y body no vacíos', () {
      for (final c in kHealthDisclaimerConditions) {
        expect(c.title.isNotEmpty, isTrue);
        expect(c.body.isNotEmpty, isTrue);
      }
    });

    test('títulos esperados de §11', () {
      final titles = kHealthDisclaimerConditions.map((c) => c.title).toList();
      expect(titles, contains('Diabetes Tipo 1 / insulinodependiente'));
      expect(
        titles.any((t) => t.contains('TCA')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('renal')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Embarazo')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Sarcopenia')),
        isTrue,
      );
    });
  });

  group('SPEC-76 — needsDisclaimerReprompt', () {
    test('usuario nunca aceptó → reprompt true', () {
      expect(
        needsDisclaimerReprompt(accepted: false, acceptedVersion: 0),
        isTrue,
      );
    });

    test('usuario aceptó pero versión es null (legacy) → reprompt true', () {
      expect(
        needsDisclaimerReprompt(accepted: true, acceptedVersion: null),
        isTrue,
      );
    });

    test('usuario aceptó con versión menor → reprompt true', () {
      expect(
        needsDisclaimerReprompt(
          accepted: true,
          acceptedVersion: kHealthDisclaimerVersion - 1,
        ),
        isTrue,
      );
    });

    test('usuario aceptó con versión actual → reprompt false', () {
      expect(
        needsDisclaimerReprompt(
          accepted: true,
          acceptedVersion: kHealthDisclaimerVersion,
        ),
        isFalse,
      );
    });

    test('versión actual pero accepted false → reprompt true', () {
      expect(
        needsDisclaimerReprompt(
          accepted: false,
          acceptedVersion: kHealthDisclaimerVersion,
        ),
        isTrue,
      );
    });
  });
}
