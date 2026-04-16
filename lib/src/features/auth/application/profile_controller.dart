import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Estado del ProfileController
class ProfileEditState {
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  const ProfileEditState({
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  ProfileEditState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool? savedSuccessfully,
  }) {
    return ProfileEditState(
      isSaving: isSaving ?? this.isSaving,
      // Pasar null explícitamente limpia el error
      errorMessage: errorMessage,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

/// ProfileController
/// Gestiona la edición y persistencia de los datos editables del perfil:
/// - Perfil circadiano (horarios de sueño y ventana de alimentación)
/// - Protocolo de ayuno
///
/// NO gestiona datos biométricos (peso, altura, etc.) — eso es responsabilidad
/// del OnboardingController y se editará en una futura pantalla de re-onboarding.
class ProfileController extends StateNotifier<ProfileEditState> {
  ProfileController({required this.ref}) : super(const ProfileEditState());

  final Ref ref;

  /// Actualiza el perfil circadiano del usuario y lo persiste en Firestore.
  /// Recibe el UserModel completo para hacer un copyWith limpio del CircadianProfile.
  Future<void> updateCircadianProfile({
    required UserModel currentUser,
    required DateTime wakeUpTime,
    required DateTime sleepTime,
    required DateTime firstMealGoal,
    required DateTime lastMealGoal,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, savedSuccessfully: false);

    try {
      final updatedProfile = currentUser.profile.copyWith(
        wakeUpTime: wakeUpTime,
        sleepTime: sleepTime,
        firstMealGoal: firstMealGoal,
        lastMealGoal: lastMealGoal,
      );

      final updatedUser = currentUser.copyWith(profile: updatedProfile);
      await ref.read(userRepositoryProvider).saveUser(updatedUser);

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar el perfil circadiano.',
        savedSuccessfully: false,
      );
    }
  }

  /// Actualiza el protocolo de ayuno del usuario y lo persiste en Firestore.
  Future<void> updateFastingProtocol({
    required UserModel currentUser,
    required String protocol,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, savedSuccessfully: false);

    try {
      final updatedUser = currentUser.copyWith(fastingProtocol: protocol);
      await ref.read(userRepositoryProvider).saveUser(updatedUser);

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar el protocolo.',
        savedSuccessfully: false,
      );
    }
  }

  /// Cierra la sesión del usuario usando Firebase Auth.
  Future<void> signOut() async {
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  /// Elimina la cuenta del usuario de Firebase Auth y Firestore.
  /// Requiere que el llamador haya confirmado la acción con "ELIMINAR".
  Future<void> deleteAccount() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void clearFeedback() {
    state = state.copyWith(errorMessage: null, savedSuccessfully: false);
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileEditState>((ref) {
  return ProfileController(ref: ref);
});
