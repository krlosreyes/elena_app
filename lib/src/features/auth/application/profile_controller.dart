import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

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
    state = state.copyWith(
        isSaving: true, errorMessage: null, savedSuccessfully: false);

    try {
      final updatedProfile = currentUser.profile.copyWith(
        wakeUpTime: wakeUpTime,
        sleepTime: sleepTime,
        firstMealGoal: firstMealGoal,
        lastMealGoal: lastMealGoal,
      );

      final updatedUser = currentUser.copyWith(profile: updatedProfile);
      await ref.read(userProfileRepositoryProvider).saveProfile(updatedUser);

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar el perfil circadiano.',
        savedSuccessfully: false,
      );
    }
  }

  /// SPEC-88: actualiza uno o más campos biométricos (peso, cintura,
  /// cuello, %grasa) y los persiste. Sigue el patrón de
  /// `updateCircadianProfile` — orquestación pura, sin lógica de
  /// dominio. La validación de rangos vive en
  /// `UserProfileMapper._validate` y se ejecuta al persistir.
  Future<void> updateBiometry({
    required UserModel currentUser,
    double? weight,
    double? waistCircumference,
    double? neckCircumference,
    double? bodyFatPercentage,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      savedSuccessfully: false,
    );
    try {
      // SPEC-143: la edición de biometría desde Profile pasa por el
      // servicio canónico. Garantiza dos cosas que el `saveProfile`
      // anterior no daba: (a) versionado automático en
      // `biometric_history/{today}` con `source: 'profile_edit'`, y
      // (b) escritura atómica de ambos lugares vía WriteBatch.
      //
      // La signature pública se preserva — los callsites de Profile
      // no necesitan saber del refactor.
      final delta = BiometricDelta(
        weight: weight,
        waistCircumference: waistCircumference,
        neckCircumference: neckCircumference,
        bodyFatPercentage: bodyFatPercentage,
      );
      await ref.read(biometricHistoryServiceProvider).updateFromProfileEdit(
            currentUser: currentUser,
            delta: delta,
          );
      // SPEC-BUG7: persiste la fecha del edit para el lock semanal.
      // Se guarda DESPUÉS de la escritura exitosa — si el write falla,
      // el lock no se activa y el usuario puede reintentar.
      await ref
          .read(sharedPreferencesProvider)
          .setString(BiometricLockService.kLastEditKey,
              DateTime.now().toIso8601String());
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar los datos biométricos.',
      );
    }
  }

  /// Actualiza el protocolo de ayuno del usuario y lo persiste en Firestore.
  Future<void> updateFastingProtocol({
    required UserModel currentUser,
    required String protocol,
  }) async {
    state = state.copyWith(
        isSaving: true, errorMessage: null, savedSuccessfully: false);

    try {
      final updatedUser = currentUser.copyWith(fastingProtocol: protocol);
      await ref.read(userProfileRepositoryProvider).saveProfile(updatedUser);

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
  ///
  /// SPEC-83 fix: setear `isSaving: false` también en el camino exitoso
  /// (antes solo se limpiaba en el catch, dejando el spinner colgado).
  /// Invalidar `authStateProvider` para que el stream re-emita el
  /// estado de no-autenticado y el router redirija a /login.
  ///
  /// SPEC-250: `AuthRepository.deleteAccount()` encadena ~18 llamadas a
  /// Firestore (borrado de 15 subcolecciones + doc raíz + legacy +
  /// Auth), ninguna con timeout propio. Si una sola se queda esperando
  /// respuesta de red (el `await` que no resuelve hasta reconectar,
  /// causa raíz ya documentada en SPEC-206), el spinner de "Eliminar
  /// cuenta" queda trabado indefinidamente — reproducido por Carlos en
  /// simulador de Xcode. El `.timeout()` acota el peor caso: si no
  /// resuelve en `timeout`, se libera la UI con un mensaje y el
  /// usuario puede reintentar. La operación original sigue corriendo
  /// en background (best-effort, ya cubierto por la Cloud Function
  /// `onUserDeleted` de SPEC-207/248 como red de seguridad) — no se
  /// cancela, solo se deja de esperar por ella.
  Future<void> deleteAccount({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).deleteAccount().timeout(timeout);
      ref.invalidate(authStateProvider);
      state = state.copyWith(isSaving: false);
    } on TimeoutException {
      // No relanzamos el TimeoutException crudo: profile_screen.dart
      // muestra `e.toString()` directo en un SnackBar (no lee
      // `state.errorMessage`), y el toString() de TimeoutException es
      // ilegible para el usuario ("TimeoutException after 0:00:25...").
      // Mismo patrón que firebase_auth_repository.dart usa para
      // 'requires-recent-login': Exception con mensaje en español.
      const message = 'La eliminación está tardando más de lo esperado. '
          'Verifica tu conexión e intenta de nuevo.';
      state = state.copyWith(isSaving: false, errorMessage: message);
      throw Exception(message);
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
