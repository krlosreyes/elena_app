// SPEC-79 smoke E2E: la LoginScreen monta y dispara AuthController.signIn
// con los valores ingresados. Cubre el contrato más sensible del Auth
// Bridge (SPEC-73): cualquier cambio en la firma de signIn rompe este
// test inmediatamente.

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/presentation/login_screen.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('SPEC-79 — LoginScreen renderiza inputs y botón', (tester) async {
    await _pump(tester, repo: _StubRepo());

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Iniciar METAMORFOSIS'), findsOneWidget);
    expect(find.text('Regístrate aquí'), findsOneWidget);
  });

  testWidgets(
    'SPEC-79 — Tap en login dispara signInWithEmail con valores ingresados',
    (tester) async {
      final repo = _StubRepo();
      await _pump(tester, repo: repo);

      // Inputs
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'carlos@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'pwd-12345',
      );

      // Submit
      await tester.tap(find.text('Iniciar METAMORFOSIS'));
      await tester.pump();

      expect(repo.lastEmail, 'carlos@example.com');
      expect(repo.lastPassword, 'pwd-12345');
    },
  );

  testWidgets(
    'SPEC-79 — Tap con email inválido no dispara repo (validator bloquea)',
    (tester) async {
      final repo = _StubRepo();
      await _pump(tester, repo: repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'no-arroba');
      await tester.enterText(find.byType(TextFormField).at(1), 'pwd-12345');

      await tester.tap(find.text('Iniciar METAMORFOSIS'));
      await tester.pump();

      expect(repo.lastEmail, isNull);
      expect(repo.lastPassword, isNull);
      // El validator del form mostró el error.
      expect(find.text('Email no válido'), findsOneWidget);
    },
  );
}

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, {required _StubRepo repo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(null),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, __) => const LoginScreen(),
            ),
            // Stubs para que las rutas internas (forgot, register) no
            // exploten al hacer push.
            GoRoute(
              path: '/forgot-password',
              builder: (_, __) => const Scaffold(),
            ),
            GoRoute(
              path: '/register',
              builder: (_, __) => const Scaffold(),
            ),
            GoRoute(
              path: '/legal/privacy',
              builder: (_, __) => const Scaffold(),
            ),
            GoRoute(
              path: '/legal/terms',
              builder: (_, __) => const Scaffold(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Stub del AuthRepository que registra las llamadas a `signInWithEmail`.
class _StubRepo implements AuthRepository {
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    return const AppAccount(
      uid: 'stub-uid',
      email: 'stub@x.com',
      profileStatus: AppProfileStatus.completeProfile,
    );
  }

  // ── No-ops para el contrato del repository ──────────────────────

  @override
  Stream<AppAccount?> get authStateChanges => Stream.value(null);

  @override
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async =>
      const AppAccount(
        uid: 'x',
        email: 'x',
        profileStatus: AppProfileStatus.newProfile,
      );

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendSignInLinkToEmail(String email) async {}

  @override
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async =>
      const AppAccount(
        uid: 'x',
        email: 'x',
        profileStatus: AppProfileStatus.newProfile,
      );

  @override
  Future<void> setPassword(String newPassword) async {}

  @override
  Future<void> deleteAccount() async {}
}
