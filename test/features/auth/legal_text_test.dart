// SPEC-77 §6 — verifica que las constantes legales tienen el shape y
// la cobertura mínima esperada.

import 'package:elena_app/src/features/auth/domain/legal_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-77 — kPrivacyPolicySections', () {
    test('cobertura mínima de secciones (≥ 5)', () {
      expect(kPrivacyPolicySections.length, greaterThanOrEqualTo(5));
    });

    test('cada sección tiene title y body no vacíos', () {
      for (final s in kPrivacyPolicySections) {
        expect(s.title.trim().isNotEmpty, isTrue);
        expect(s.body.trim().isNotEmpty, isTrue);
      }
    });

    test('contiene secciones clave esperadas por GDPR', () {
      final titles =
          kPrivacyPolicySections.map((s) => s.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('datos')), isTrue);
      expect(titles.any((t) => t.contains('derechos')), isTrue);
      expect(titles.any((t) => t.contains('retención') || t.contains('eliminación')), isTrue);
    });
  });

  group('SPEC-77 — kTermsOfServiceSections', () {
    test('cobertura mínima de secciones (≥ 4)', () {
      expect(kTermsOfServiceSections.length, greaterThanOrEqualTo(4));
    });

    test('cada sección tiene title y body no vacíos', () {
      for (final s in kTermsOfServiceSections) {
        expect(s.title.trim().isNotEmpty, isTrue);
        expect(s.body.trim().isNotEmpty, isTrue);
      }
    });

    test('contiene aceptación, limitación de responsabilidad y disclaimer médico-like', () {
      final titles =
          kTermsOfServiceSections.map((s) => s.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('aceptación')), isTrue);
      expect(titles.any((t) => t.contains('responsabilidad')), isTrue);
    });
  });

  group('SPEC-77 — versiones', () {
    test('kPrivacyPolicyVersion es entero positivo', () {
      expect(kPrivacyPolicyVersion, greaterThanOrEqualTo(1));
    });

    test('kTermsOfServiceVersion es entero positivo', () {
      expect(kTermsOfServiceVersion, greaterThanOrEqualTo(1));
    });
  });
}
