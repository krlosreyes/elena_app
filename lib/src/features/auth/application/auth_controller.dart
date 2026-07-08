// SPEC-73: AuthController orquesta sign-in / sign-up / sign-out usando
// el contrato `AppAccount` en lugar del legacy `UserModel?`.
//
// El estado del controller sigue siendo `AsyncValue<void>` porque la UI
// reacciona al `authStateProvider` (que ya emite AppAccount); el
// controller sólo expone progreso/error de la operación en curso.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
// SPEC-11: providers a invalidar en logout para garantizar estado limpio
// del próximo usuario que use el mismo dispositivo.
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
// SPEC-247: el tour persiste en SharedPreferences — limpiarlo en signOut
// garantiza que un usuario nuevo en el mismo dispositivo vea el tour.
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({required this.repository, required Ref ref})
      : _ref = ref,
        super(const AsyncData(null));

  final AuthRepository repository;
  final Ref _ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => repository.signInWithEmail(email: email, password: password));
    // SPEC-193: evento de embudo. Solo en éxito; logEvent nunca lanza.
    if (!state.hasError) {
      AnalyticsService.logEvent(
        AnalyticsEvents.login,
        params: const {AnalyticsParams.method: 'email'},
      );
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        ));
    // SPEC-193: evento de embudo. Solo en éxito; logEvent nunca lanza.
    if (!state.hasError) {
      AnalyticsService.logEvent(
        AnalyticsEvents.signupComplete,
        params: const {AnalyticsParams.method: 'email'},
      );
    }
  }

  /// SPEC-73 §RF-73-09: dispara magic link para usuarios MR sin pwd.
  Future<void> sendSignInLink(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.sendSignInLinkToEmail(email),
    );
  }

  Future<void> setPasswordFromLink({
    required String email,
    required String emailLink,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signInWithEmailLink(email: email, emailLink: emailLink);
      await repository.setPassword(newPassword);
    });
  }

  /// SPEC-11: signOut invalida todos los StateNotifiers antes de cerrar
  /// Firebase, así un nuevo usuario en el mismo dispositivo recibe
  /// estado limpio sin datos residuales.
  // SPEC-212: signOut invalida TODOS los providers con estado de usuario
  // para garantizar estado limpio en el mismo dispositivo.
  Future<void> signOut() async {
    state = const AsyncLoading();

    // Pilares
    _ref.invalidate(fastingProvider);
    _ref.invalidate(sleepProvider);
    _ref.invalidate(hydrationProvider);
    _ref.invalidate(exerciseProvider);
    _ref.invalidate(nutritionProvider);
    _ref.invalidate(streakProvider);
    _ref.invalidate(engagementProvider);

    // SPEC-212: providers faltantes en la implementación original
    _ref.invalidate(lastFastingIntervalProvider);
    _ref.invalidate(lastCompletedFastingProvider);
    _ref.invalidate(currentMetabolicCycleProvider);
    _ref.invalidate(lastClosedMetabolicCycleProvider);
    _ref.invalidate(metabolicCyclesHistoryProvider);
    _ref.invalidate(last7ClosedCyclesProvider);
    _ref.invalidate(last14ClosedCyclesProvider);
    _ref.invalidate(progressProvider);

    // SPEC-247: limpiar el flag del tour en SharedPreferences al cerrar sesión.
    // El tour vive en SharedPreferences (no en Firestore), por eso no basta
    // con invalidar providers — si no se limpia, el próximo usuario en el mismo
    // dispositivo nunca verá el tour aunque sea su primera vez.
    await _ref.read(appTourProvider.notifier).forceReset();

    state = await AsyncValue.guard(() => repository.signOut());
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});
