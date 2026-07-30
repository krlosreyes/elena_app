// SPEC-261: contrato de almacenamiento físico de consumos de alcohol.
//
// Espejo de HydrationDataSource (SPEC-50.1): el source es agnóstico de
// zona horaria — el caller pasa los límites de la ventana. Firestore
// auto-genera el id en `append`.

abstract class ConsumptionDataSource {
  /// Stream de mapas crudos en la ventana `[startOfDay, endOfDay?)`.
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
    DateTime? endOfDay,
  });

  /// Añade una entrada nueva (auto-id).
  Future<void> append({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Borra el registro más reciente desde [since]. Idempotente.
  Future<void> deleteLatest({
    required String userId,
    required DateTime since,
  });
}
