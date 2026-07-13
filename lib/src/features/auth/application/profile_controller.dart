import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
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

    // SPEC-143: la edición de biometría desde Profile pasa por el
    // servicio canónico. Garantiza dos cosas que el `saveProfile`
    // anterior no daba: (a) versionado automático en
    // `biometric_history/{today}` con `source: 'profile_edit'`, y
    // (b) escritura atómica de ambos lugares vía WriteBatch.
    //
    // La signature pública se preserva — los callsites de Profile
    // no necesitan saber del refactor.
    //
    // FB-06 (auditoría independiente 2026-07-11): antes este método hacía
    // `await` directo a la escritura Firestore, sin el patrón offline-first
    // (unawaited+catchError) que SPEC-206 ya aplicó al check-in sheet — si
    // el dispositivo estaba offline, `batch.commit()` nunca resolvía y la
    // pantalla de Perfil quedaba con el spinner de guardado colgado
    // indefinidamente. Se replica ahora el mismo patrón fire-and-forget: el
    // estado se marca "guardado" de inmediato (consistente con lo que el
    // usuario ve en el resto de los pilares) y la escritura real continúa
    // en segundo plano.
    final delta = BiometricDelta(
      weight: weight,
      waistCircumference: waistCircumference,
      neckCircumference: neckCircumference,
      bodyFatPercentage: bodyFatPercentage,
    );

    state = state.copyWith(isSaving: false, savedSuccessfully: true);

    unawaited(
      ref
          .read(biometricHistoryServiceProvider)
          .updateFromProfileEdit(currentUser: currentUser, delta: delta)
          .then((_) {
        // SPEC-BUG7: persiste la fecha del edit para el lock semanal.
        // Se guarda DESPUÉS de la escritura exitosa — si el write falla,
        // el lock no se activa y el usuario puede reintentar.
        return ref.read(sharedPreferencesProvider).setString(
            BiometricLockService.kLastEditKey,
            DateTime.now().toIso8601String());
      }).catchError((Object e) {
        // flutter analyze (2026-07-11, primera corrida real): el `.then`
        // previo retorna `Future<bool>` (de `setString`), así que
        // `catchError` debe devolver un `bool` para no dejar la cadena en
        // un estado que "podría completar normalmente" sin valor.
        AppLogger.error('[ProfileController] updateBiometry falló', e);
        return false;
      }),
    );
  }

  /// Actualiza el protocolo de ayuno del usuario y lo persiste en Firestore.
  ///
  /// SPEC-257 Eje C: `protocolWarningAccepted` opcional — se pasa cuando
  /// el usuario confirmó el guardrail de sistema nervioso desde el
  /// dashboard (mismo campo que el onboarding usa para no repetir el
  /// aviso una vez aceptado).
  Future<void> updateFastingProtocol({
    required UserModel currentUser,
    required String protocol,
    String? protocolWarningAccepted,
  }) async {
    state = state.copyWith(
        isSaving: true, errorMessage: null, savedSuccessfully: false);

    try {
      final updatedUser = currentUser.copyWith(
        fastingProtocol: protocol,
        protocolWarningAccepted:
            protocolWarningAccepted ?? currentUser.protocolWarningAccepted,
      );
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
  /// SPEC-250 inc1: `AuthRepository.deleteAccount()` encadena ~18
  /// llamadas a Firestore (borrado de 15 subcolecciones + doc raíz +
  /// legacy + Auth), ninguna con timeout propio. Si una sola se queda
  /// esperando respuesta de red (el `await` que no resuelve hasta
  /// reconectar, causa raíz ya documentada en SPEC-206), el spinner de
  /// "Eliminar cuenta" queda trabado indefinidamente — reproducido por
  /// Carlos en simulador de Xcode. El `.timeout()` acota el peor caso.
  ///
  /// SPEC-250 inc3 (repro Carlos 2026-07-08, dos veces — ver
  /// `_recoverFromPartialDelete`): CUALQUIER excepción que llegue hasta
  /// acá, no solo el timeout, implica que Firestore ya fue borrado.
  /// `FirebaseAuthRepository.deleteAccount` ejecuta sus pasos 1-3
  /// (subcolecciones + doc raíz + legacy) envueltos en try/catch que
  /// nunca relanza ("best-effort") — así que SIEMPRE corren antes de
  /// llegar al paso 4 (`user.delete()` de Firebase Auth), que es el
  /// ÚNICO punto que puede lanzar (p.ej. `requires-recent-login` si la
  /// sesión tiene más de ~5 min). Por eso el recovery de
  /// `_recoverFromPartialDelete()` se aplica en AMBOS catch — timeout y
  /// error real — no solo en el de timeout.
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
      await _recoverFromPartialDelete();
      state = state.copyWith(isSaving: false, errorMessage: message);
      throw Exception(message);
    } catch (e) {
      // SPEC-250 inc3: mismo recovery que el timeout — ver doc del
      // método. Este catch también atrapa 'requires-recent-login'
      // (Firestore ya borrado, solo Auth falló) y cualquier otro error
      // real del paso 4.
      await _recoverFromPartialDelete();
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// SPEC-250 inc2+inc3: cuando `deleteAccount()` del repo falla o hace
  /// timeout, `users/{uid}` casi con certeza ya fue borrado (ver doc de
  /// `deleteAccount` arriba), pero `authStateProvider` nunca se invalida
  /// en un camino de error — solo en el éxito. Sin este recovery,
  /// `currentUserStreamProvider` queda emitiendo `null` para siempre y
  /// `ProfileScreen.build` (línea ~90, `if (user == null) return
  /// CircularProgressIndicator()`) se queda en un spinner sin salida,
  /// reproducido dos veces por Carlos en simulador de Xcode
  /// (2026-07-08): una vía timeout, otra vía `requires-recent-login`.
  ///
  /// `signOut()` local (no reintenta borrar nada, solo cierra la sesión
  /// en el dispositivo) + invalidar `authStateProvider` fuerza al router
  /// a mandar a `/login` y desmonta la pantalla rota. Es además
  /// coherente con el propio mensaje de `requires-recent-login`
  /// ("cierra sesión, vuelve a iniciar sesión y reintenta"): antes el
  /// usuario no tenía cómo cerrar sesión desde una pantalla congelada en
  /// un spinner; ahora la sesión se cierra sola y puede seguir la
  /// instrucción.
  ///
  /// Riesgo aceptado (ya documentado en SPEC-83 para este mismo caso):
  /// si el paso 4 (Auth) no llegó a completarse, la cuenta de Auth queda
  /// residual sin doc de Firestore — cubierto por la Cloud Function
  /// `onUserDeleted` (SPEC-207/248) si el borrado eventualmente se
  /// completa, o por un reintento manual del usuario tras re-login.
  Future<void> _recoverFromPartialDelete() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Best-effort — no bloqueamos la salida del usuario por esto.
    }
    ref.invalidate(authStateProvider);
  }

  void clearFeedback() {
    state = state.copyWith(errorMessage: null, savedSuccessfully: false);
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileEditState>((ref) {
  return ProfileController(ref: ref);
});
