// SPEC-111: contrato de almacenamiento físico para los resúmenes
// diarios. Abstracción de bajo nivel — opera con `Map` y delega
// la traducción al mapper.

abstract class DailySummaryDataSource {
  /// Upsert por docId. `data` ya incluye los campos crudos listos
  /// para Firestore (Timestamps, etc.).
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  });

  /// Lee un doc puntual. Devuelve null si no existe.
  Future<Map<String, dynamic>?> readDoc({
    required String userId,
    required String docId,
  });

  /// Stream de docs cuyo `date` cae en `[fromIncl, toIncl]`. Emite
  /// la lista actualizada cada vez que cambia algún doc en el rango.
  Stream<List<Map<String, dynamic>>> watchRange({
    required String userId,
    required String fromIncl,
    required String toIncl,
  });
}
