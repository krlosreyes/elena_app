import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
// SPEC-11: Imports de providers a invalidar en logout
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  // SPEC-11: Ref inyectado para poder invalidar providers en logout,
  // siguiendo el mismo patrón que FastingNotifier y SleepNotifier.
  AuthController({required this.repository, required Ref ref})
      : _ref = ref,
        super(const AsyncData(null));

  final AuthRepository repository;
  final Ref _ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      repository.signInWithEmail(email: email, password: password)
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      repository.signUpWithEmail(email: email, password: password, name: name)
    );
  }

  // SPEC-11: signOut invalida todos los StateNotifiers antes de cerrar Firebase.
  // Esto garantiza que un nuevo usuario que inicia sesión en el mismo dispositivo
  // recibe siempre un estado limpio, sin datos residuales del usuario anterior.
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

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    ref: ref, // SPEC-11: necesario para invalidar providers en logout
  );
});