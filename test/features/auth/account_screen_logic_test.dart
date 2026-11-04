// Rediseño Perfil (2026-11-04): lógica pura de Cuenta y datos personales.

import 'package:elena_app/src/features/auth/data/account_email_service.dart';
import 'package:elena_app/src/features/auth/presentation/account_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maskEmail oculta el usuario', () {
    expect(maskEmail('krlosreyes2@gmail.com'), 'krl•••@gmail.com');
    expect(maskEmail('ab@x.co'), 'a•••@x.co');
  });

  test('initialsOf', () {
    expect(initialsOf('Carlos Manuel Reyes'), 'CR');
    expect(initialsOf('  carlos '), 'C');
    expect(initialsOf(''), '?');
  });

  group('AccountEmailService.validate', () {
    test('vacío o mal formado', () {
      expect(AccountEmailService.validate(''), isNotNull);
      expect(AccountEmailService.validate('carlos@'), isNotNull);
      expect(AccountEmailService.validate('carlos@correo'), isNotNull);
    });

    test('igual al actual (sin importar mayúsculas)', () {
      expect(
        AccountEmailService.validate('Carlos@Correo.com',
            currentEmail: 'carlos@correo.com'),
        'Ese ya es tu correo actual.',
      );
    });

    test('válido', () {
      expect(
        AccountEmailService.validate('nuevo@correo.com',
            currentEmail: 'viejo@correo.com'),
        isNull,
      );
    });
  });
}
