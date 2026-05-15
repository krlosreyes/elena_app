// SPEC-50: contrato de persistencia para registros de sueño.
//
// Antes: la persistencia de SleepLog vivía en UserRepository (313 líneas
// monolíticas mezclando 6 features). Cualquier cambio al schema de sueño
// arriesgaba acoplamiento con notifiers de hidratación, ejercicio, racha,
// etc. Tests requerían mockear los 30+ métodos del UserRepository aunque
// solo se necesitaran 2.
//
// Ahora: interface tipada, dedicada al dominio "sueño". Cualquier capa
// de datos (Firestore, in-memory para tests, futura migración a SQL local)
// puede implementarla sin tocar otros pilares.
//
// Sigue el patrón establecido por SPEC-63 (NutritionRepository):
//   domain/<feature>_repository.dart   → contrato puro (este archivo).
//   data/<feature>_repository_impl.dart → orquesta DataSource + Mapper.
//   data/sources/<feature>_data_source.dart → contrato de almacenamiento.
//   data/sources/firestore_*_source.dart    → impl Firestore concreta.
//   data/mappers/<feature>_log_mapper.dart  → Map ↔ Domain translation.

import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

/// Contrato de almacenamiento de sueño desde el punto de vista del
/// dominio. La capa de aplicación (notifiers) consume esta abstracción,
/// nunca Firestore directamente.
abstract class SleepRepository {
  /// Stream del último ciclo de sueño persistido para el usuario.
  /// Emite `null` si el usuario no tiene historial de sueño.
  Stream<SleepLog?> watchLatest(String userId);

  /// Persiste o sobrescribe un ciclo de sueño usando `log.id` como
  /// clave. Idempotente: re-llamar con el mismo `log` produce el mismo
  /// estado en Firestore (no duplica).
  Future<void> save(String userId, SleepLog log);

  /// SPEC-106: elimina un ciclo de sueño persistido por su `logId`.
  /// Idempotente: borrar un id inexistente NO debe lanzar.
  Future<void> delete(String userId, String logId);
}
