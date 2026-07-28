// Recorrido en Simulador, 27-jul-2026 — regresión del diálogo de borrado.
//
// EL FALLO QUE ESTE TEST IMPIDE QUE VUELVA
// ----------------------------------------
// Perfil → "Eliminar cuenta" → CANCELAR, sin escribir nada, reventaba:
//
//   A TextEditingController was used after being disposed.
//   'package:flutter/src/widgets/framework.dart': Failed assertion:
//   line 6268 pos 12: '_dependents.isEmpty': is not true.
//
// El segundo error no se quedaba en el diálogo: se llevaba por delante la
// pantalla de Perfil entera, y no se recuperaba cerrando y reabriendo la
// app — había que forzar el cierre del proceso.
//
// Causa: el `TextEditingController` se creaba en la función que abría el
// diálogo, y cada botón lo trataba distinto. CANCELAR llamaba a
// `dispose()` ANTES de `Navigator.pop`, con el TextField todavía montado;
// ELIMINAR CUENTA hacía `pop` y no liberaba nunca (fuga).
//
// El arreglo mueve el controller a un StatefulWidget que lo libera en su
// `dispose()`. Estos tests recorren las DOS ramas, porque el bug vivía en
// la asimetría entre ellas.
//
// Nota sobre cómo se detecta: en tests de widget una excepción lanzada
// durante el build no falla el test por sí sola — queda registrada y hay
// que reclamarla con `tester.takeException()`. Por eso cada caso lo
// comprueba explícitamente en vez de confiar en que el test "pase".

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Diálogo de eliminar cuenta — ciclo de vida del controller', () {
    testWidgets('CANCELAR cierra sin romper el árbol de widgets',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe ELIMINAR para confirmar:'), findsOneWidget);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      // Antes del arreglo, aquí saltaba "A TextEditingController was used
      // after being disposed" y detrás la aserción _dependents.isEmpty.
      expect(tester.takeException(), isNull,
          reason: 'CANCELAR no debe liberar el controller mientras el '
              'TextField sigue montado');

      // Y la pantalla de debajo debe seguir viva: el fallo original no se
      // quedaba en el diálogo, tumbaba Perfil entero.
      expect(find.text('Eliminar cuenta'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('abrir y cancelar varias veces no acumula fallos',
        (tester) async {
      await _pump(tester);

      // Si el controller se liberase antes de tiempo, la segunda apertura
      // reventaría aunque la primera pareciese sobrevivir.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Eliminar cuenta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CANCELAR'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'vuelta ${i + 1}');
      }
    });

    testWidgets('el botón destructivo solo se habilita con la palabra exacta',
        (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();

      TextButton botonDestructivo() => tester.widget<TextButton>(
            find.widgetWithText(TextButton, 'ELIMINAR CUENTA'),
          );

      expect(botonDestructivo().onPressed, isNull,
          reason: 'arranca deshabilitado');

      await tester.enterText(find.byType(TextField), 'ELIMIN');
      await tester.pump();
      expect(botonDestructivo().onPressed, isNull,
          reason: 'una palabra parcial no basta');

      await tester.enterText(find.byType(TextField), 'eliminar');
      await tester.pump();
      expect(botonDestructivo().onPressed, isNotNull,
          reason: 'se acepta en minúsculas: el campo fuerza mayúsculas '
              'visualmente, pero la comparación es case-insensitive');

      await tester.enterText(find.byType(TextField), '  ELIMINAR  ');
      await tester.pump();
      expect(botonDestructivo().onPressed, isNotNull,
          reason: 'los espacios sobrantes se recortan');

      expect(tester.takeException(), isNull);
    });

    testWidgets('confirmar cierra el diálogo y dispara el borrado una vez',
        (tester) async {
      final repo = _FakeAuthRepository();
      await _pump(tester, repo: repo);

      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ELIMINAR');
      await tester.pump();

      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();

      // La otra rama del bug: aquí no había dispose en absoluto. Que no
      // lance es la mitad; la otra mitad es que el diálogo se cierre y el
      // borrado se dispare exactamente una vez.
      expect(tester.takeException(), isNull);
      expect(find.text('Escribe ELIMINAR para confirmar:'), findsNothing);
      expect(repo.vecesBorrado, 1);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

/// Monta `ProfileDangerZoneActions` con el mínimo andamiaje que necesita:
/// un `GoRouter` (la confirmación llama a `GoRouter.of`) y el `Scaffold`
/// de la ruta, que es quien aporta el `ScaffoldMessenger`.
Future<void> _pump(WidgetTester tester, {_FakeAuthRepository? repo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo ?? _FakeAuthRepository()),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(null),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const Scaffold(
                body: Center(child: ProfileDangerZoneActions()),
              ),
            ),
            GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fake de `AuthRepository` que solo implementa lo que este test toca.
///
/// Usa `noSuchMethod` a propósito: la lección de
/// `feedback_interface_extension` es que los fakes que enumeran cada
/// miembro se rompen en cuanto la interfaz crece, aunque el test no tenga
/// nada que ver con el miembro nuevo. Así este sobrevive a eso.
class _FakeAuthRepository implements AuthRepository {
  int vecesBorrado = 0;

  @override
  Stream<AppAccount?> get authStateChanges => Stream<AppAccount?>.value(null);

  @override
  Future<void> deleteAccount() async => vecesBorrado++;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} no debería usarse en este test',
      );
}
