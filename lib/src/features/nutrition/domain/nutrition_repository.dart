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
  ///
  /// SPEC-189 (2026-06-05): DEPRECADO. La definición de "día actual"
  /// vivía atada al `DayBoundaryResolver` calendárico y viola §1 de
  /// METABOLIC_DAY_CONSTITUTION.md (cero reloj). Usar `watchSinceLogs`
  /// con `cycle.startedAt` del ciclo metabólico abierto. Si no hay
  /// ciclo, el caller debe devolver lista vacía — no inventar un "día"
  /// con el reloj.
  @Deprecated(
    'SPEC-189: usar watchSinceLogs(userId, cycle.startedAt). '
    'Ver METABOLIC_DAY_CONSTITUTION.md §1.',
  )
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

  /// Elimina el log más reciente desde [since] hasta ahora (acción "deshacer").
  /// [since] debe ser el inicio del ciclo metabólico actual, no medianoche.
  /// SPEC-210: fix para ciclos que empiezan antes de medianoche.
  /// Si no hay logs desde [since], es no-op.
  Future<void> removeLastMeal(String userId, {required DateTime since});

  /// Elimina un log por su id. No-op si no existe.
  /// Usado para "editar plato": se elimina el viejo y se guarda el nuevo.
  Future<void> deleteMealById(String userId, String mealId);
}
