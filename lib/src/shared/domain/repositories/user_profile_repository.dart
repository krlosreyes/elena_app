// SPEC-50.5: contrato de persistencia para perfil de usuario.
//
// Cierra la descomposición del UserRepository monolítico iniciada en
// SPEC-50. Los métodos que viven aquí son los que verdaderamente
// pertenecen al dominio "perfil de usuario":
//   - Datos del UserModel (perfil, biometría, configuración).
//   - Adherencia semanal agregada (campo del usuario).
//   - Historial y aplicación de ajustes de protocolo.
//
// Los pilares ya tienen su propio repositorio (Sleep, Hydration,
// Exercise, Streak, FastingInterval) — ninguno vive aquí.

import 'package:elena_app/src/shared/domain/models/user_model.dart';

abstract class UserProfileRepository {
  /// Stream del perfil del usuario. Emite `null` cuando el doc no
  /// existe (usuario sin onboarding completado, por ejemplo).
  Stream<UserModel?> watchProfile(String userId);

  /// Persiste o sobrescribe el perfil. Usa SetOptions(merge: true)
  /// internamente — campos no incluidos en el UserModel no se borran
  /// en Firestore (importante para preservar campos legacy o
  /// extensiones futuras).
  Future<void> saveProfile(UserModel user);

  /// Actualiza el campo `weeklyAdherence` del perfil. Llamado por el
  /// StreakNotifier cuando recomputa la adherencia binaria semanal.
  Future<void> updateWeeklyAdherence(String userId, double adherence);

  /// Registra una sugerencia de ajuste de protocolo en la subcolección
  /// `protocol_adjustments`. La impl añade `timestamp` server-side.
  Future<void> saveProtocolAdjustment(
    String userId,
    Map<String, dynamic> adjustment,
  );

  /// Aplica un cambio de protocolo físicamente al perfil del usuario.
  /// Solo actualiza los campos pasados (no-null).
  Future<void> applyProtocolAdjustment({
    required String userId,
    String? newFastingProtocol,
    int? newExerciseGoal,
  });
}
