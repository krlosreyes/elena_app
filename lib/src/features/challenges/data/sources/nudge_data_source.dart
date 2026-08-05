// SPEC-264: contrato de la fuente de datos de zumbidos.

abstract class NudgeDataSource {
  /// Envía una interacción (crea el doc en challenges/{code}/nudges).
  Future<void> send(String code, Map<String, dynamic> data);

  /// Interacciones dirigidas a [uid] en el reto (para mostrarlas in-app).
  Stream<List<Map<String, dynamic>>> watchForRecipient(String code, String uid);
}
