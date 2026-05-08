// SPEC-50.3: contrato de persistencia para historial de racha.
//
// Sigue el patrón de SPEC-50/50.1/50.2.
//
// Scope intencional: este repositorio cubre SOLO los datos del
// historial de racha (StreakEntry). Las operaciones que parecían
// "de Streak" en el UserRepository monolítico pero que en realidad
// son configuración del usuario — `updateWeeklyAdherence`,
// `saveProtocolAdjustment`, `applyProtocolAdjustment` — quedan
// territorio del UserProfileRepository (SPEC-50.5). Cohesión por
// dominio: streak_history vs user profile son colecciones distintas
// con semánticas distintas.

import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

abstract class StreakRepository {
  /// Stream de los últimos 30 días de historial, ordenados por fecha
  /// descendente. Cada emisión refleja el estado actual de Firestore.
  Stream<List<StreakEntry>> watchHistory(String userId);

  /// Persiste o actualiza un StreakEntry usando `entry.date`
  /// (formato 'yyyy-MM-dd') como clave. SetOptions(merge: true)
  /// para que las actualizaciones incrementales del día (más pilares
  /// completados) no sobrescriban campos previos como imrScore.
  Future<void> save(String userId, StreakEntry entry);
}
