// SPEC-261.4: contrato de almacenamiento del documento de sesión.
//
// A diferencia de los consumos (colección con auto-id), los metadatos de la
// ocasión viven en UN solo documento (`current`): fase, plan, insumos. Así la
// sesión sobrevive al cierre de la app y es consistente entre dispositivos.

abstract class ConsumptionSessionDataSource {
  /// Stream del documento de sesión actual (null si no existe).
  Stream<Map<String, dynamic>?> watch(String userId);

  /// Guarda (sobrescribe) el documento de sesión.
  Future<void> save(
      {required String userId, required Map<String, dynamic> data});

  /// Borra el documento de sesión (al cerrar el protocolo).
  Future<void> clear(String userId);
}
