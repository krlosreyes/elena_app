// SPEC-73: AuthController orquesta sign-in / sign-up / sign-out usando
// el contrato `AppAccount` en lugar del legacy `UserModel?`.
//
// El estado del controller sigue siendo `AsyncValue<void>` porque la UI
// reacciona al `authStateProvider` (que ya emite AppAccount); el
// controller sólo expone progreso/error de la operación en curso.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
// SPEC-11: providers a invalidar en logout para garantizar estado limpio
// del próximo usuario que use el mismo dispositivo.
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';

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
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        ));
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
  Future<void> signOut() async {
    state = const AsyncLoading();

    _ref.invalidate(fastingProvider);
    _ref.invalidate(sleepProvider);
    _ref.invalidate(hydrationProvider);
    _ref.invalidate(exerciseProvider);
    _ref.invalidate(nutritionProvider);
    _ref.invalidate(streakProvider);
    _ref.invalidate(engagementProvider);

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
