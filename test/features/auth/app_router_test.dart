// SPEC-73 §CA-73-08: el router redirige UNA SOLA VEZ y no entra en
// loop cuando un usuario con perfil incompleto está en /login.
//
// TEST-05 (auditoría pre-producción 2026-07-11): el test estaba `skip:
// true` esperando "un harness de go_router con observer de redirects".
// Ese harness no hace falta: toda la lógica de decisión vive en
// `computeRedirect` (lib/src/router/router_redirect.dart), una función
// PURA sin dependencias de Flutter ni de GoRouter — el propio archivo la
// documenta como "función pura testeable". Se prueba directamente contra
// esa función, sin necesidad de montar un GoRouter real ni un widget
// tree.
//
// El anti-loop (CA-73-08) se verifica simulando la secuencia real de dos
// evaluaciones consecutivas del redirect (como haría GoRouter tras
// navegar): la primera evaluación en /login debe mandar a /onboarding
// exactamente una vez; la segunda evaluación, ya en /onboarding, debe
// devolver null (sin seguir redirigiendo) — eso es lo que prueba que no
// hay loop.

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/router/router_redirect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppAccount _account({
  required AppProfileStatus status,
  String uid = 'u1',
}) =>
    AppAccount(
      uid: uid,
      email: 'user@example.com',
      profileStatus: status,
    );

void main() {
  group('computeRedirect — CA-73-08 (usuario NEW en /login, sin loop)', () {
    test(
        'usuario NEW autenticado en /login es redirigido una vez a '
        '/onboarding', () {
      final authState = AsyncValue<AppAccount?>.data(
        _account(status: AppProfileStatus.newProfile),
      );

      final firstRedirect = computeRedirect(
        authState: authState,
        location: kLoginRoute,
      );

      expect(firstRedirect, kOnboardingRoute,
          reason: 'perfil NEW en ruta pública debe ir a onboarding');
    });

    test(
        'tras el redirect a /onboarding, una segunda evaluación en esa '
        'misma ruta NO vuelve a redirigir (sin loop)', () {
      final authState = AsyncValue<AppAccount?>.data(
        _account(status: AppProfileStatus.newProfile),
      );

      // Primera evaluación: /login → /onboarding.
      final firstRedirect = computeRedirect(
        authState: authState,
        location: kLoginRoute,
      );
      expect(firstRedirect, kOnboardingRoute);

      // Segunda evaluación: GoRouter ya navegó a /onboarding con el MISMO
      // authState (nada cambió). CA-73-08 exige que esto retorne null —
      // si retornara /onboarding o /login de nuevo, habría loop infinito.
      final secondRedirect = computeRedirect(
        authState: authState,
        location: firstRedirect!,
      );

      expect(secondRedirect, isNull,
          reason: 'CA-73-08: la segunda evaluación en /onboarding no debe '
              'volver a redirigir — de lo contrario el router entra en loop');
    });

    test(
        'perfil PARTIAL en /login también redirige una sola vez a '
        '/onboarding (mismo invariante que NEW)', () {
      final authState = AsyncValue<AppAccount?>.data(
        _account(status: AppProfileStatus.partialProfile),
      );

      final firstRedirect = computeRedirect(
        authState: authState,
        location: kLoginRoute,
      );
      expect(firstRedirect, kOnboardingRoute);

      final secondRedirect = computeRedirect(
        authState: authState,
        location: firstRedirect!,
      );
      expect(secondRedirect, isNull);
    });
  });

  group('computeRedirect — perfil COMPLETE en /login (sin loop)', () {
    test('usuario COMPLETE en /login va directo a /dashboard una vez', () {
      final authState = AsyncValue<AppAccount?>.data(
        _account(status: AppProfileStatus.completeProfile),
      );

      final firstRedirect = computeRedirect(
        authState: authState,
        location: kLoginRoute,
      );
      expect(firstRedirect, kDashboardRoute);

      final secondRedirect = computeRedirect(
        authState: authState,
        location: firstRedirect!,
      );
      expect(secondRedirect, isNull,
          reason: 'en /dashboard, ya destino final, no debe redirigir más');
    });
  });

  group('computeRedirect — loading y splash (SPEC-146)', () {
    test('auth loading fuera de /splash redirige a /splash', () {
      const authState = AsyncValue<AppAccount?>.loading();
      final redirect = computeRedirect(
        authState: authState,
        location: kDashboardRoute,
      );
      expect(redirect, kSplashRoute);
    });

    test('auth loading y ya en /splash no redirige', () {
      const authState = AsyncValue<AppAccount?>.loading();
      final redirect = computeRedirect(
        authState: authState,
        location: kSplashRoute,
      );
      expect(redirect, isNull);
    });

    test('sin cuenta (logout) en ruta privada redirige a /login', () {
      const authState = AsyncValue<AppAccount?>.data(null);
      final redirect = computeRedirect(
        authState: authState,
        location: kDashboardRoute,
      );
      expect(redirect, kLoginRoute);
    });

    test('sin cuenta en ruta pública (/register) no redirige', () {
      const authState = AsyncValue<AppAccount?>.data(null);
      final redirect = computeRedirect(
        authState: authState,
        location: '/register',
      );
      expect(redirect, isNull);
    });
  });
}
