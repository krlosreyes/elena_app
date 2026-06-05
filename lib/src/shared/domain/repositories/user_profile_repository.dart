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

  /// SPEC-82: actualiza únicamente `imr.current` en el doc raíz del
  /// usuario. El sitio web Metamorfosis Real lee ese campo para mostrar
  /// el score actualizado del usuario. Usa dotted-path para tocar solo
  /// el subcampo `imr.current` sin afectar otros campos del doc.
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  );

  /// SPEC-86: stream del subcampo `imr.current` del doc del usuario.
  /// Emite null si el doc no existe o el subcampo no está presente.
  /// Útil para que el Dashboard muestre el valor persistido (puede
  /// venir del sitio web) cuando el cálculo local solo tiene baseline.
  Stream<Map<String, dynamic>?> watchCurrentImr(String userId);

  /// SPEC-141 §RF-141-12 (2026-06-05): escribe un snapshot semanal del
  /// IMR longitudinal en `users/{userId}/imr_history/{weekISO}`.
  ///
  /// `weekISO` tiene formato `YYYY-WNN` (ej. `2026-W23`). El doc id es
  /// idempotente — re-snapshots dentro de la misma semana ISO
  /// sobreescriben el anterior. Esto evita duplicados cuando el
  /// usuario hace múltiples check-ins biométricos en una semana.
  ///
  /// El payload usa el mismo shape de `imrToCanonicalMap` con campos
  /// adicionales: `weekISO`, `computedAt`, `trigger`.
  Future<void> writeImrHistorySnapshot({
    required String userId,
    required String weekISO,
    required Map<String, dynamic> snapshot,
  });

  /// SPEC-148 §RF-148-04 (2026-06-05): stream de últimos N snapshots
  /// semanales del IMR longitudinal. Ordenados por `computedAt` desc.
  /// Default 12 semanas (~3 meses) — suficiente para encontrar el doc
  /// de hace 30 días con margen para la `TransformationCard`.
  Stream<List<Map<String, dynamic>>> watchImrHistory(
    String userId, {
    int limit = 12,
  });
}
