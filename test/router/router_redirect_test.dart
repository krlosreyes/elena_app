// SPEC-146 §8.1: tests del computeRedirect.
//
// Función pura sin dependencias de Flutter ni GoRouter. Tests directos
// que cubren los 4 estados clave: AsyncLoading, AsyncData(null),
// AsyncData(complete), AsyncData(partial).

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/router/router_redirect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppAccount _account({
  AppProfileStatus status = AppProfileStatus.completeProfile,
}) =>
    AppAccount(
      uid: 'u1',
      email: 'test@example.com',
      displayName: 'Test',
      profileStatus: status,
      rawProfile: null,
      createdAt: DateTime(2026, 6, 1),
    );

void main() {
  group('SPEC-146 §8.1 — computeRedirect: AsyncLoading', () {
    test('loading + location != /splash → /splash', () {
      final result = computeRedirect(
        authState: const AsyncLoading<AppAccount?>(),
        location: '/dashboard',
      );
      expect(result, '/splash');
    });

    test('loading + location == /splash → null (queda)', () {
      final result = computeRedirect(
        authState: const AsyncLoading<AppAccount?>(),
        location: '/splash',
      );
      expect(result, isNull);
    });

    test('loading + location == /login → /splash (mover a controlled loading)',
        () {
      final result = computeRedirect(
        authState: const AsyncLoading<AppAccount?>(),
        location: '/login',
      );
      expect(result, '/splash');
    });

    test('loading + location == /legal/privacy → /splash', () {
      final result = computeRedirect(
        authState: const AsyncLoading<AppAccount?>(),
        location: '/legal/privacy',
      );
      expect(result, '/splash');
    });
  });

  group('SPEC-146 §8.1 — computeRedirect: resolved sin account', () {
    test('AsyncData(null) + ruta privada → /login', () {
      final result = computeRedirect(
        authState: const AsyncData<AppAccount?>(null),
        location: '/dashboard',
      );
      expect(result, '/login');
    });

    test('AsyncData(null) + /login → null (queda)', () {
      final result = computeRedirect(
        authState: const AsyncData<AppAccount?>(null),
        location: '/login',
      );
      expect(result, isNull);
    });

    test('AsyncData(null) + /legal/privacy → null (público)', () {
      final result = computeRedirect(
        authState: const AsyncData<AppAccount?>(null),
        location: '/legal/privacy',
      );
      expect(result, isNull);
    });

    test('AsyncData(null) + /splash → /login (resolvió, no quedar atrapado)',
        () {
      final result = computeRedirect(
        authState: const AsyncData<AppAccount?>(null),
        location: '/splash',
      );
      expect(result, '/login');
    });

    test('AsyncData(null) + /open/imr → null (deep link público)', () {
      final result = computeRedirect(
        authState: const AsyncData<AppAccount?>(null),
        location: '/open/imr',
      );
      expect(result, isNull);
    });
  });

  group('SPEC-146 §8.1 — computeRedirect: resolved con account complete', () {
    test('complete + /splash → /dashboard', () {
      final result = computeRedirect(
        authState: AsyncData(_account()),
        location: '/splash',
      );
      expect(result, '/dashboard');
    });

    test('complete + /login → /dashboard (ya autenticado, sacar de auth)', () {
      final result = computeRedirect(
        authState: AsyncData(_account()),
        location: '/login',
      );
      expect(result, '/dashboard');
    });

    test('complete + /onboarding → /dashboard (perfil ya completo)', () {
      final result = computeRedirect(
        authState: AsyncData(_account()),
        location: '/onboarding',
      );
      expect(result, '/dashboard');
    });

    test('complete + /dashboard → null (queda)', () {
      final result = computeRedirect(
        authState: AsyncData(_account()),
        location: '/dashboard',
      );
      expect(result, isNull);
    });

    test('complete + /legal/privacy → null (puede leer desde Perfil)', () {
      final result = computeRedirect(
        authState: AsyncData(_account()),
        location: '/legal/privacy',
      );
      expect(result, isNull);
    });
  });

  group('SPEC-146 §8.1 — computeRedirect: resolved con account partial', () {
    test('partial + /splash → /onboarding', () {
      final result = computeRedirect(
        authState: AsyncData(
          _account(status: AppProfileStatus.partialProfile),
        ),
        location: '/splash',
      );
      expect(result, '/onboarding');
    });

    test('partial + /dashboard → /onboarding (forzar completar)', () {
      final result = computeRedirect(
        authState: AsyncData(
          _account(status: AppProfileStatus.partialProfile),
        ),
        location: '/dashboard',
      );
      expect(result, '/onboarding');
    });

    test('partial + /onboarding → null (queda en onboarding)', () {
      final result = computeRedirect(
        authState: AsyncData(
          _account(status: AppProfileStatus.partialProfile),
        ),
        location: '/onboarding',
      );
      expect(result, isNull);
    });

    test('newProfile + /splash → /onboarding', () {
      final result = computeRedirect(
        authState: AsyncData(
          _account(status: AppProfileStatus.newProfile),
        ),
        location: '/splash',
      );
      expect(result, '/onboarding');
    });
  });
}
