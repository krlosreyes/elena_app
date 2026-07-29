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
        'SPEC-250 inc3: un error genérico del repo dispara signOut() local '
        '— mismo recovery que el timeout (repro Carlos, simulador Xcode, '
        '2026-07-08, 2do caso)', () async {
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
          reason: 'ante un error indeterminado no sabemos si el borrado se '
              'completó; sin signOut() la pantalla puede quedar sin salida');
    });
  });

  // ── Reautenticación (27-jul-2026) ──────────────────────────────────
  //
  // El nombre de este grupo importa: hasta hoy, `requires-recent-login`
  // caía en el `catch` genérico y disparaba `signOut()`. Tenía sentido
  // con el orden antiguo, donde una excepción implicaba que Firestore ya
  // estaba borrado y la pantalla quedaba colgada. Invertido el orden, el
  // significado es el contrario: no se ha borrado nada, y el usuario
  // necesita SEGUIR autenticado para escribir su contraseña y
  // reintentar. Sacarlo a /login aquí sería reproducir el mismo mal
  // remedio que veníamos de quitar.
  group('requires-recent-login: no expulsa al usuario', () {
    late ProviderContainer container;
    tearDown(() => container.dispose());

    test('ReauthRequiredException se propaga SIN cerrar sesión', () async {
      final repo = _FakeAuthRepository()..throwReauthRequired = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await expectLater(
        container.read(profileControllerProvider.notifier).deleteAccount(),
        throwsA(isA<ReauthRequiredException>()),
      );

      expect(repo.signOutCalled, isFalse,
          reason: 'el usuario debe seguir autenticado para reintentar');
      expect(container.read(profileControllerProvider).isSaving, isFalse,
          reason: 'el spinner debe soltarse igual');
    });

    test('reauthenticate() pasa la contraseña al repositorio', () async {
      final repo = _FakeAuthRepository();
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);

      await container
          .read(profileControllerProvider.notifier)
          .reauthenticate('mi-clave');

      expect(repo.reauthCalled, isTrue);
      expect(repo.lastPassword, 'mi-clave');
      expect(container.read(profileControllerProvider).isSaving, isFalse);
    });

    test('tras reautenticar, el borrado se completa', () async {
      final repo = _FakeAuthRepository()..throwReauthRequired = true;
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ]);
      final controller = container.read(profileControllerProvider.notifier);

      // 1er intento: Firebase pide sesión reciente.
      await expectLater(
        controller.deleteAccount(),
        throwsA(isA<ReauthRequiredException>()),
      );

      // El usuario confirma su identidad y se reintenta.
      await controller.reauthenticate('mi-clave');
      repo.throwReauthRequired = false;
      await controller.deleteAccount();

      expect(repo.deleteCalled, isTrue);
      expect(repo.signOutCalled, isFalse,
          reason: 'el signOut del camino feliz lo hace el repositorio, no '
              'el recovery de error');
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

  /// 27-jul-2026: permite simular `requires-recent-login`, el camino que
  /// ahora NO debe cerrar sesión.
  bool throwReauthRequired = false;
  bool reauthCalled = false;
  String? lastPassword;

  @override
  Stream<AppAccount?> get authStateChanges => Stream.value(null);

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    reauthCalled = true;
    lastPassword = password;
  }

  // ── Google (29-jul-2026) ────────────────────────────────────────────
  //
  // `providersDelUsuario` es configurable porque el borrado de cuenta
  // decide CÓMO reautenticar según el proveedor: pedirle la contraseña a
  // quien solo entró con Google lo dejaría sin poder borrar su cuenta.
  List<AuthProviderKind> providersDelUsuario = const [
    AuthProviderKind.password
  ];
  bool reauthGoogleCalled = false;
  bool googleReauthCancelada = false;

  @override
  List<AuthProviderKind> currentUserProviders() => providersDelUsuario;

  @override
  Future<bool> reauthenticateWithGoogle() async {
    reauthGoogleCalled = true;
    return !googleReauthCancelada;
  }

  @override
  Future<AppAccount?> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AppAccount> linkPendingGoogleCredential({
    required String pendingCredentialToken,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount() async {
    deleteCalled = true;
    if (throwReauthRequired) {
      throw const ReauthRequiredException(email: 'test@elena.app');
    }
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
