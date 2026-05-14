// SPEC-80 §6 — tests del scrubber puro.

import 'package:elena_app/src/core/services/pii_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-80 — PiiScrubber.scrub email', () {
    test('email simple', () {
      expect(
        PiiScrubber.scrub('Error en carlos@example.com'),
        'Error en [REDACTED_EMAIL]',
      );
    });

    test('multiple emails en la misma frase', () {
      final r = PiiScrubber.scrub(
        'envío de a@x.com hacia b@y.org falló',
      );
      expect(r, contains('[REDACTED_EMAIL]'));
      expect(r.contains('a@x.com'), isFalse);
      expect(r.contains('b@y.org'), isFalse);
    });

    test('email con subdomain y plus addressing', () {
      expect(
        PiiScrubber.scrub('contact carlos+ops@metamorfosis.real.co please'),
        'contact [REDACTED_EMAIL] please',
      );
    });

    test('string sin email queda intacto', () {
      expect(
        PiiScrubber.scrub('error de red 500'),
        'error de red 500',
      );
    });
  });

  group('SPEC-80 — PiiScrubber.scrub Firebase UID', () {
    test('UID de 28 chars se reemplaza', () {
      // Ejemplo de UID Firebase Auth (28 alfanuméricos).
      final fakeUid = 'abc123XYZ456def789GHI012jkl3';
      final r = PiiScrubber.scrub('user $fakeUid not found');
      expect(r, contains('[REDACTED_UID]'));
      expect(r.contains(fakeUid), isFalse);
    });

    test('strings de menos de 28 chars no se tocan', () {
      // 26 chars: no debería matchear.
      const shortString = 'abcDEF123abcDEF123abcDEF12';
      expect(PiiScrubber.scrub(shortString), shortString);
    });

    test('strings de exactamente 28 chars que no son UID', () {
      // El scrubber no distingue contenido — cualquier alfanumérico
      // de 28 chars cae. Es trade-off conocido: falsos positivos OK,
      // falsos negativos (PII filtrada) NO.
      const candidate = 'thisIsExactlyTwentyEightLong';
      // 28 chars alphanumeric → será redacted.
      expect(PiiScrubber.scrub(candidate), '[REDACTED_UID]');
    });
  });

  group('SPEC-80 — PiiScrubber.scrub Bearer tokens', () {
    test('Authorization: Bearer xxx', () {
      expect(
        PiiScrubber.scrub('header Bearer eyJhbGc.fooBar.signature'),
        'header Bearer [REDACTED_TOKEN]',
      );
    });

    test('Bearer en medio de la frase', () {
      final r = PiiScrubber.scrub('attempted Bearer ABC123 was rejected');
      expect(r, contains('[REDACTED_TOKEN]'));
      expect(r.contains('ABC123 was'), isFalse);
    });
  });

  group('SPEC-80 — PiiScrubber edge cases', () {
    test('empty string', () {
      expect(PiiScrubber.scrub(''), '');
    });

    test('múltiples tipos de PII en el mismo mensaje', () {
      const input =
          'user carlos@x.com (uid: aaaaBBBB1111CCCC2222dddd3333) failed';
      final r = PiiScrubber.scrub(input);
      expect(r.contains('carlos@x.com'), isFalse);
      expect(r.contains('aaaaBBBB1111CCCC2222dddd3333'), isFalse);
      expect(r, contains('[REDACTED_EMAIL]'));
      expect(r, contains('[REDACTED_UID]'));
    });
  });
}
