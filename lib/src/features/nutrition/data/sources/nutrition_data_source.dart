// SPEC-63: contrato de almacenamiento físico para registros de nutrición.
//
// Abstracción de `data/sources/`. La implementación concreta de R1 es
// `firestore_nutrition_v1_source.dart` (escribe a la colección legacy
// `users/{uid}/nutrition_history/`). En R3, SPEC-49 introducirá
// `firestore_nutrition_v2_source.dart` (al aggregate `daily_records/`)
// y solo se cambiará el provider — sin tocar el dominio ni los consumidores.

/// Operaciones físicas sobre los registros de nutrición. Trabaja a nivel
/// de mapas serializados — no conoce el modelo `NutritionLog` ni la lógica
/// de validación. El mapper se encarga de la traducción.
abstract class NutritionDataSource {
  /// Stream con los logs del día actual del usuario. Cada elemento de la
  /// lista es un par `(docId, payload)` para que el mapper componga el
  /// `NutritionLog` con el id correcto incluso si falta en el payload.
  Stream<List<({String docId, Map<String, dynamic> data})>> watchTodayLogs(
    String userId,
  );

  /// Persiste el `data` con `docId` como clave del documento.
  Future<void> saveLog(
    String userId,
    String docId,
    Map<String, dynamic> data,
  );

  /// Elimina el documento con `docId`. No-op si no existe.
  Future<void> deleteLog(String userId, String docId);

  /// Devuelve el documento más reciente del día actual (mayor timestamp)
  /// para resolver `removeLastMeal()`. Retorna null si no hay logs hoy.
  Future<({String docId, Map<String, dynamic> data})?> latestTodayLog(
    String userId,
  );
}
