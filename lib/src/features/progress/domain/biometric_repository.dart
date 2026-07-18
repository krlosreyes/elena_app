// SPEC-15: Road Map de Avance Personal
// ARCH-05 (auditoría 2026-07-11): interfaz abstracta para invertir la
// dependencia domain→data. Antes `features/progress/data/biometric_repository.dart`
// no tenía contrato en `domain/`, así que otras features (health_sync,
// analysis) importaban la implementación Firestore directo desde `data/`.
//
// La clase concreta `BiometricRepository` en `data/biometric_repository.dart`
// se mantiene con ese mismo nombre (NO se renombró: tiene múltiples
// consumidores que la nombran por su tipo concreto — `health_import_service.dart`,
// `biometric_history_service.dart` y varios tests instancian
// `BiometricRepository(firestore)` directo). Para evitar colisión de nombres
// dentro del propio archivo de datos, este contrato se importa ahí con
// prefijo (`as domain`).

import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

abstract class BiometricRepository {
  /// Guarda o sobreescribe el check-in del día dado.
  Future<void> saveCheckIn(BiometricCheckIn checkIn);

  /// Escritura atómica del doc raíz del usuario + snapshot histórico
  /// (SPEC-143).
  Future<void> applyBiometricUpdate({
    required String userId,
    required BiometricCheckIn historySnapshot,
    required Map<String, dynamic> userDocUpdates,
  });

  /// Stream de los últimos [limit] check-ins ordenados por fecha
  /// descendente.
  Stream<List<BiometricCheckIn>> watchHistory(
    String userId, {
    int limit = 2000,
  });

  /// Devuelve el check-in más reciente (1 lectura — para inicialización).
  Future<BiometricCheckIn?> fetchLatest(String userId);

  /// Check-in del día de hoy si existe.
  Future<BiometricCheckIn?> fetchToday(String userId);

  /// Check-in para una fecha específica (yyyy-MM-dd) si existe.
  Future<BiometricCheckIn?> fetchByDate(String userId, String date);
}
