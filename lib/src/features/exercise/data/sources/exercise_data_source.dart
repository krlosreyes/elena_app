// SPEC-50.2: contrato de almacenamiento físico para registros de
// ejercicio.

abstract class ExerciseDataSource {
  /// Stream de los registros en la ventana `[startOfDay, endOfDay)`.
  /// SPEC-138: `endOfDay` acota el día por arriba (ver `DayBoundaryResolver`).
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
    DateTime? endOfDay,
  });

  /// Persiste o sobrescribe un documento usando `docId` como clave.
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  });

  /// Borra el log más reciente en la ventana [since, ∞).
  /// No-op si no hay logs en la ventana.
  Future<void> deleteLatest({
    required String userId,
    required DateTime since,
  });

  /// Borra un log por ID determinístico (ej. `hk_steps_YYYY-MM-DD`).
  /// No-op si el documento no existe. Usado por HealthImportService para
  /// limpiar logs de pasos cuando se detecta un workout del mismo día.
  Future<void> deleteById({
    required String userId,
    required String logId,
  });
}
