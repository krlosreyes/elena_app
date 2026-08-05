// SPEC-262: contrato de persistencia del wallet de gamificación.
//
// Documento único por usuario (users/{uid}/gamification/state). El source es
// agnóstico de dominio: mueve Map<String, dynamic>.

abstract class GamificationDataSource {
  /// Stream del documento (null si aún no existe).
  Stream<Map<String, dynamic>?> watch(String userId);

  /// Guarda (merge) el estado.
  Future<void> save({
    required String userId,
    required Map<String, dynamic> data,
  });
}
