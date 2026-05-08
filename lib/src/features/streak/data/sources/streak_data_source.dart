// SPEC-50.3: contrato de almacenamiento físico para historial de racha.

abstract class StreakDataSource {
  /// Stream de entradas con `date` >= cutoffDateKey, ordenadas por
  /// `date` descendente.
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required String cutoffDateKey,
  });

  /// Upserta un documento usando `dateKey` (formato yyyy-MM-dd) como
  /// clave. Merge habilitado para soportar updates incrementales
  /// (más pilares completados durante el día).
  Future<void> persistMerged({
    required String userId,
    required String dateKey,
    required Map<String, dynamic> data,
  });
}
