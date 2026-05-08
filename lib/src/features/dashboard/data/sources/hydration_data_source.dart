// SPEC-50.1: contrato de almacenamiento físico para registros de
// hidratación.
//
// Diferencias con SleepDataSource:
//   - `streamToday` filtra por ventana temporal (no "el último") y
//     retorna la lista completa.
//   - `append` crea una entrada nueva con auto-id (no toma docId).

abstract class HydrationDataSource {
  /// Stream de la lista de registros desde `startOfDay` hasta ahora.
  /// El caller pasa el inicio del día para que el source quede agnóstico
  /// de zona horaria (la decisión vive en la capa de aplicación).
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
  });

  /// Añade una entrada nueva. Firestore auto-genera el id.
  Future<void> append({
    required String userId,
    required Map<String, dynamic> data,
  });
}
