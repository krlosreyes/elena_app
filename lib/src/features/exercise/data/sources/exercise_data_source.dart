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
}
