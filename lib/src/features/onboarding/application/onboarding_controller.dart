// SPEC-73 BUGFIX (12-may-2026): después de saveProfile, el
// authStateProvider debe re-clasificar el AppAccount como
// completeProfile. Sin esto, el router seguía viendo el perfil viejo
// (partial/new) y devolvía al usuario a /onboarding en bucle.
//
// El stream de Firebase Auth NO se entera de cambios en Firestore —
// solo emite cuando cambia el estado de autenticación. Invalidando
// el provider forzamos una re-suscripción que vuelve a leer
// users/{uid} y reconstruye AppAccount con el nuevo shape.
//
// SPEC-82 (13-may-2026): tras saveProfile y antes del invalidate,
// calculamos un IMR baseline (solo bloque Estructura) y lo
// persistimos a `users/{uid}.imr.current`. Eso permite al sitio web
// Metamorfosis Real mostrar un score inicial inmediatamente, en
// lugar de "Sin diagnóstico". Si la escritura falla, no rompemos el
// flujo de onboarding — solo logueamos warning.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  // SPEC-50.5: UserProfileRepository (no UserRepository).
  final UserProfileRepository _repository;
  final Ref _ref;

  OnboardingController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> completeOnboarding(UserModel user) async {
    state = const AsyncValue.loading();

    // SPEC-193: capturar antes de escribir si el usuario ya traía un IMR
    // del sitio MR (señal "from_mr"). Tras persistir el baseline, imr.current
    // existiría para todos, así que se evalúa aquí, antes de saveProfile.
    final preAccount = _ref.read(authStateProvider).value;
    final fromMr = preAccount?.rawProfile?['imr'] is Map &&
        (preAccount!.rawProfile!['imr'] as Map)['current'] is Map;

    try {
      // SPEC-73 §RF-73-07: la preservación de campos MR pre-existentes
      // (subscription_active, purchases, programs, etc.) está
      // garantizada por `FirestoreUserProfileV1Source.saveProfile`, que
      // ya usa `set(..., SetOptions(merge: true))`. Los campos que el
      // UserModel no conoce se mantienen intactos en Firestore.
      //
      // SPEC-82: además del shape legacy, el mapper escribe el shape
      // canónico (`displayName, genderCanonical, bio, habits, meta`)
      // en el mismo write.
      await _repository.saveProfile(user);

      // SPEC-143: registrar baseline biométrico en `biometric_history`
      // para que SPEC-141 tenga punto de partida del historial de IMR
      // longitudinal. Mismo patrón try/catch que el IMR baseline más
      // abajo — un fallo de denormalización no debe bloquear el cierre
      // del onboarding.
      //
      // FB-07 (auditoría independiente 2026-07-11): try/catch solo atrapa
      // excepciones lanzadas, no un Future que nunca resuelve (offline). Se
      // agrega `.timeout(...)` para que el onboarding no quede bloqueado
      // indefinidamente si la conectividad es inestable justo al registrarse.
      try {
        await _ref
            .read(biometricHistoryServiceProvider)
            .writeOnboardingBaseline(currentUser: user)
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        AppLogger.warning(
          '[onboarding] No se persistió baseline biométrico: $e',
          e,
        );
      }

      // SPEC-82: persistir IMR baseline (solo bloque Estructura) para
      // que el sitio web tenga score visible inmediatamente. Si la
      // escritura falla, logueamos warning y seguimos — no bloquear
      // el cierre del onboarding por un side-effect de denormalización.
      //
      // SPEC-85 fix: si el sitio web ya escribió `imr.current` (caso
      // de usuario que se registró primero en metamorfosisreal.com),
      // NO pisamos su valor con un baseline parcial. El cálculo
      // completo del sitio es preferible al baseline solo-estructura
      // de la app. Cuando la app tenga data behavioral real, el
      // `imrPersistenceProvider` actualizará con un valor mejor.
      try {
        final accountAtOnboarding = _ref.read(authStateProvider).value;
        final hasPreviousImr = accountAtOnboarding?.rawProfile?['imr'] is Map &&
            (accountAtOnboarding!.rawProfile!['imr'] as Map)['current'] is Map;

        if (hasPreviousImr) {
          AppLogger.info(
            '[onboarding] imr.current ya existe (probablemente del sitio); '
            'no persistimos baseline.',
          );
        } else {
          final baseline = ScoreEngine.calculateBaseline(user);
          // FB-07: mismo fix de timeout que el baseline biométrico de arriba.
          await _repository
              .updateCurrentImr(user.id, imrToCanonicalMap(baseline))
              .timeout(const Duration(seconds: 6));
        }
      } catch (e) {
        AppLogger.warning(
          '[onboarding] No se persistió IMR baseline: $e',
          e,
        );
      }

      // SPEC-73 BUGFIX: forzar re-clasificación del AppAccount.
      // Sin esto, profileStatus queda en PARTIAL y el router
      // reenvía al usuario a /onboarding indefinidamente.
      _ref.invalidate(authStateProvider);

      // Esperar al primer emit del stream re-suscrito. Garantiza que
      // cuando la pantalla llame `context.go('/dashboard')`, el
      // redirect del router ya vea profileStatus == COMPLETE.
      await _ref.read(authStateProvider.future);

      // SPEC-193: evento de cierre de embudo de onboarding.
      AnalyticsService.logEvent(
        AnalyticsEvents.onboardingComplete,
        params: {AnalyticsParams.fromMr: fromMr},
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(
    ref.watch(userProfileRepositoryProvider),
    ref,
  );
});
