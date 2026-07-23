// Módulo "Tu Glucosa" — contrato de persistencia (propuesta §8 y §9).
// Mismo patrón que exercise/domain/exercise_profile_repository.dart:
// abstracción sin dependencias de Firestore.

import 'package:elena_app/src/features/glucose/domain/glucose_protocol_state.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

abstract class GlucoseRepository {
  /// Persiste una nueva lectura. Retorna el id asignado.
  Future<String> saveReading(String userId, GlucoseReading reading);

  /// Historial ordenado por measuredAt descendente (más reciente
  /// primero), acotado a los últimos [days] días.
  Future<List<GlucoseReading>> fetchReadings(String userId, {int days = 90});

  /// Stream en vivo del historial reciente — para que el módulo
  /// "Tu Glucosa" y la tarjeta del Dashboard reaccionen sin refrescar.
  Stream<List<GlucoseReading>> watchReadings(String userId, {int days = 90});

  Future<GlucoseProtocolState?> fetchProtocolState(String userId);

  Future<void> saveProtocolState(String userId, GlucoseProtocolState state);

  Stream<GlucoseProtocolState?> watchProtocolState(String userId);
}
