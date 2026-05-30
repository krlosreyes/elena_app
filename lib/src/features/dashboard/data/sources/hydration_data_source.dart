// SPEC-50.1: contrato de almacenamiento físico para registros de
// hidratación.
//
// Diferencias con SleepDataSource:
//   - `streamToday` filtra por ventana temporal (no "el último") y
//     retorna la lista completa.
//   - `append` crea una entrada nueva con auto-id (no toma docId).

abstract class HydrationDataSource {
  /// Stream de la lista de registros en la ventana `[startOfDay, endOfDay)`.
  /// El caller pasa ambos límites para que el source quede agnóstico de zona
  /// horaria (la decisión vive en la capa de aplicación, vía
  /// `DayBoundaryResolver`). SPEC-138: `endOfDay` acota el día por arriba para
  /// no filtrar timestamps futuros/desfasados hacia "hoy".
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
    DateTime? endOfDay,
  });

  /// Añade una entrada nueva. Firestore auto-genera el id.
  Future<void> append({
    required String userId,
    required Map<String, dynamic> data,
  });
}
