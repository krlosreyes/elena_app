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

  /// SPEC-159: Stream de los últimos N ciclos de sueño ordenados por
  /// `wokeUp` descendente (más reciente primero). Cada doc incluye
  /// `__docId` inyectado por el source, igual que `streamLatest`.
  /// Devuelve lista vacía si el usuario no tiene historial.
  Stream<List<Map<String, dynamic>>> streamRecent({
    required String userId,
    required int limit,
  });

  /// 17-jul: lectura puntual (no stream) de UN documento por su id.
  /// Usado por `HealthImportService` para el guard "manual gana sobre
  /// auto" — antes de escribir un sample de HealthKit/Health Connect,
  /// hay que poder chequear si ya existe el doc manual de esa noche
  /// (`sleep_<attributionDayKey>`) sin suscribirse a un stream.
  /// Devuelve `null` si el doc no existe.
  Future<Map<String, dynamic>?> fetchById({
    required String userId,
    required String docId,
  });

  /// Persiste o sobrescribe un documento de sueño usando `docId` como
  /// clave. Idempotente: re-llamar con el mismo `data` produce el
  /// mismo estado (no duplica).
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  });

  /// SPEC-106: elimina un documento de sueño específico. Operación
  /// idempotente — eliminar un docId inexistente NO debe lanzar.
  Future<void> deleteDoc({
    required String userId,
    required String docId,
  });
}
