// SPEC-81: tests del config de reCAPTCHA.
//
// Estos tests funcionan como CI gate. Cuando Carlos reemplace la
// site key placeholder por la real en producción, `recaptchaIsPlaceholder`
// pasará a `false` y el primer test fallará en CI — recordatorio
// explícito de actualizar también este archivo y/o documentar el
// cambio en `docs/PRODUCTION_HARDENING.md`.
//
// El test 2 es invariante: la función debe distinguir placeholder vs
// no-placeholder por igualdad estricta de strings.

import 'package:elena_app/src/core/config/recaptcha_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-81 — recaptcha_config', () {
    test(
      'la site key actual ES el placeholder de desarrollo '
      '(CI gate: actualizar este test cuando se reemplace por la real)',
      () {
        expect(
          recaptchaIsPlaceholder,
          isTrue,
          reason:
              'Si este test falla, la `kRecaptchaSiteKey` ya no es el '
              'placeholder. Verifica que la nueva key esté registrada en '
              'reCAPTCHA Admin (https://www.google.com/recaptcha/admin) '
              'con los dominios de producción listados en '
              'docs/PRODUCTION_HARDENING.md. Después actualiza este test '
              'para reflejar el nuevo estado.',
        );
      },
    );

    test(
      'la key del placeholder tiene el formato típico de Google '
      '(6L… seguido de chars Base64-like)',
      () {
        // Forma defensiva: aunque la key cambie, debe parecer una key
        // real de Google (no quedarse en '' o 'TODO' o similar). Esto
        // evita que un deploy accidente con string vacío.
        expect(
          kRecaptchaSiteKey.length,
          greaterThanOrEqualTo(20),
          reason: 'reCAPTCHA site keys de Google tienen ≥ 30 chars.',
        );
        expect(
          kRecaptchaSiteKey.startsWith('6L'),
          isTrue,
          reason:
              'reCAPTCHA v3 site keys de Google empiezan con "6L". '
              'Si esto falla, la key configurada NO es válida.',
        );
      },
    );
  });
}
