// SPEC-50: contrato de almacenamiento físico para registros de sueño.
//
// Abstracción de bajo nivel. Opera con `Map<String, dynamic>`
// directamente — la traducción a/desde el dominio (SleepLog) es
// responsabilidad del mapper, no de este source.
//
// Implementaciones esperadas:
//   - `firestore_sleep_v1_source.dart` (R3 actual): escribe a la
//     colección legacy users/{uid}/sleep_history/.
//   - SPEC-49 (R3 futuro): introducirá v2 que escribirá al aggregate
//     `daily_records/{uid}/{date}` con el campo `sleep`.

abstract class SleepDataSource {
  /// Stream del último ciclo de sueño persistido. Emite `null` cuando
  /// el usuario no tiene historial. Cada emisión es el snapshot crudo
  /// de Firestore — el mapper se encarga de traducir.
  Stream<Map<String, dynamic>?> streamLatest(String userId);

  /// Persiste o sobrescribe un documento de sueño usando `docId` como
  /// clave. Idempotente: re-llamar con el mismo `data` produce el
  /// mismo estado (no duplica).
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  });
}
