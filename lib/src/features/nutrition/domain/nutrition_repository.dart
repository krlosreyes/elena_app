// SPEC-63: contrato de persistencia para NutritionLog.
//
// Capa domain — Dart puro, sin Firestore ni SharedPreferences. La
// implementación concreta orquesta DataSource + Mapper en `data/`.
//
// La capa application/presentation consume esta interfaz, nunca la
// implementación. SPEC-49 (R3) intercambiará el DataSource interno
// (de v1 a v2 con aggregate `daily_records`) sin tocar este contrato
// ni a sus consumidores.

import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Persiste registros diarios de nutrición.
abstract class NutritionRepository {
  /// Stream de los logs del día actual para `userId`.
  /// Re-emite cuando se añaden o eliminan registros. Devuelve lista vacía
  /// si el usuario aún no ha registrado nada hoy.
  Stream<List<NutritionLog>> watchTodayLogs(String userId);

  /// SPEC-149.2: stream de logs filtrado por ventana [since, since + 28h].
  /// Anclado al ciclo metabólico — el conteo de comidas del Día Metabólico
  /// no se ve afectado por la medianoche calendárica.
  ///
  /// SPEC-149.2.bugfix (2026-06-02): si se pasa `until` se sobrescribe
  /// el cap de 28h. Necesario para análisis histórico.
  Stream<List<NutritionLog>> watchSinceLogs(
    String userId,
    DateTime since, {
    DateTime? until,
  });

  /// Persiste un nuevo registro. Usa `log.id` como clave del documento.
  Future<void> saveMeal(String userId, NutritionLog log);

  /// Elimina el log más reciente del día (acción "deshacer").
  /// Si el usuario no tiene logs hoy, es no-op.
  Future<void> removeLastMeal(String userId);
}
