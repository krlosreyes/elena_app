// SPEC-250: tests del timeout guard en `ProfileController.deleteAccount`.
//
// Contexto: `AuthRepository.deleteAccount()` (impl real: SPEC-248b)
// encadena ~18 llamadas a Firestore/Auth sin timeout propio. Si una se
// cuelga (causa raíz ya documentada en SPEC-206: un `await` de Firestore
// que no resuelve hasta reconectar), el spinner de "Eliminar cuenta"
// quedaba trabado indefinidamente — reproducido por Carlos en simulador
// de Xcode. Estos tests verifican el guard sin depender de Firestore
// real: usan un `AuthRepository` fake con un `deleteAccount()`
// controlable (nunca resuelve / resuelve rápido / lanza error real).
//
// El parámetro `timeout` de `deleteAccount()` es inyectable justamente
// para poder testear el camino de timeout sin esperar los 25s reales
// del default de producción.

import 'dart:async';

import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-250 — ProfileController.deleteAccount timeout guard', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test(
        'deleteAccount() del repo nunca resuelve → timeout libera isSaving '
        'con mensaje legible (no TimeoutException crudo)', () async {
      final repo = _FakeAuthRepository()..neverResolveDelete = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await expectLater(
        container.read(profileControllerProvider.notifier).deleteAccount(
              timeout: const Duration(milliseconds: 50),
            ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(profileControllerProvider);
      expect(state.isSaving, isFalse,
          reason: 'El spinner no debe quedar colgado tras el timeout');
      expect(state.errorMessage, contains('tardando'));
      // No debe ser el toString() crudo de TimeoutException.
      expect(state.errorMessage, isNot(contains('TimeoutException')));
    });

    test(
        'SPEC-250 inc2: timeout dispara signOut() local — evita que '
        'ProfileScreen quede colgado en currentUserStreamProvider == null '
        '(repro Carlos, simulador Xcode, 2026-07-08)', () async {
      final repo = _FakeAuthRepository()..neverResolveDelete = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await expectLater(
        container.read(profileControllerProvider.notifier).deleteAccount(
              timeout: const Duration(milliseconds: 50),
            ),
        throwsA(isA<Exception>()),
      );

      expect(repo.signOutCalled, isTrue,
          reason: 'El timeout debe cerrar la sesión local para que el '
              'router redirija a /login y ProfileScreen se desmonte, en '
              'vez de quedar con user == null para siempre');
    });

    test('deleteAccount() del repo resuelve rápido → sin error, isSaving false',
        () async {
      final repo = _FakeAuthRepository();
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await container.read(profileControllerProvider.notifier).deleteAccount(
            timeout: const Duration(seconds: 5),
          );

      final state = container.read(profileControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, isNull);
      expect(repo.deleteCalled, isTrue);
    });

    test(
        'error real del repo (no timeout) se propaga con su propio mensaje, '
        'sin ser reinterpretado como timeout', () async {
      final repo = _FakeAuthRepository()..shouldThrow = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await expectLater(
        container.read(profileControllerProvider.notifier).deleteAccount(
              timeout: const Duration(seconds: 5),
            ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(profileControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, contains('boom'));
      expect(state.errorMessage, isNot(contains('tardando')));
    });

    test(
        'SPEC-250 inc3: error real (ej. requires-recent-login) también '
        'dispara signOut() local — mismo recovery que el timeout, no solo '
        'ese camino (repro Carlos, simulador Xcode, 2026-07-08, 2do caso)',
        () async {
      final repo = _FakeAuthRepository()..shouldThrow = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await expectLater(
        container.read(profileControllerProvider.notifier).deleteAccount(
              timeout: const Duration(seconds: 5),
            ),
        throwsA(isA<Exception>()),
      );

      expect(repo.signOutCalled, isTrue,
          reason: 'requires-recent-login solo puede ocurrir DESPUÉS de que '
              'Firestore ya fue borrado (pasos 1-3 son best-effort y nunca '
              'lanzan) — sin signOut(), ProfileScreen queda igual de '
              'colgado que en el caso de timeout');
    });
  });
}

/// Fake mínimo de `AuthRepository` — solo `deleteAccount()` es relevante
/// para estos tests. El resto de métodos no se usan pero deben
/// implementarse para satisfacer la interfaz.
class _FakeAuthRepository implements AuthRepository {
  bool neverResolveDelete = false;
  bool shouldThrow = false;
  bool deleteCalled = false;
  bool signOutCalled = false;

  @override
  Stream<AppAccount?> get authStateChanges => Stream.value(null);

  @override
  Future<void> deleteAccount() async {
    deleteCalled = true;
    if (shouldThrow) {
      throw Exception('boom');
    }
    if (neverResolveDelete) {
      // Future que nunca completa — simula el `await` colgado offline
      // (causa raíz SPEC-206).
      return Completer<void>().future;
    }
  }

  @override
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setPassword(String newPassword) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> sendSignInLinkToEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<int?> getTrialExpiresAtClaimMillis({bool forceRefresh = false}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) =>
      throw UnimplementedError();
}
