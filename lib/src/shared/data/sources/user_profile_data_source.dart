// SPEC-50.5: contrato de almacenamiento físico para perfil de usuario.

abstract class UserProfileDataSource {
  /// Stream del documento del perfil. `null` cuando el doc no existe.
  Stream<Map<String, dynamic>?> streamProfile(String userId);

  /// Persiste el documento completo del perfil con merge=true.
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Actualiza un subset de campos del perfil. Usa Firestore.update
  /// (NO crea el doc si no existe — saveProfile cubre ese caso).
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> updates,
  });

  /// Añade una entrada a la subcolección `protocol_adjustments` del
  /// usuario. La impl inyecta `timestamp` server-side.
  Future<void> appendProtocolAdjustment({
    required String userId,
    required Map<String, dynamic> adjustment,
  });

  /// SPEC-141 §RF-141-12 (2026-06-05): escribe un snapshot semanal del
  /// IMR longitudinal en `users/{userId}/imr_history/{weekISO}`.
  /// Set merge=false — el doc id es idempotente por semana ISO, así
  /// que re-snapshots dentro de la misma semana sobreescriben sin
  /// preservar campos previos.
  Future<void> writeImrHistory({
    required String userId,
    required String weekISO,
    required Map<String, dynamic> snapshot,
  });

  /// SPEC-148 §RF-148-04 (2026-06-05): stream de los últimos N
  /// snapshots semanales del IMR longitudinal, ordenados por
  /// `computedAt` descendente (más reciente primero). Default 12
  /// semanas (~3 meses) — suficiente para encontrar el doc de hace
  /// 30 días con margen.
  Stream<List<Map<String, dynamic>>> watchImrHistory({
    required String userId,
    int limit = 12,
  });
}
