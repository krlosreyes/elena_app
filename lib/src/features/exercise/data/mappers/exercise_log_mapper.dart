// SPEC-50.2: traductor entre Map<String, dynamic> y ExerciseLog.
//
// Diferencia con SleepLogMapper / HydrationLogMapper: ExerciseLog es
// Freezed con `toJson`/`fromJson` autogenerados que ya manejan los
// `@TimestampConverter()` y los campos opcionales SPEC-68 (type,
// intensity, rpe, heartRateAvg). El mapper delega serialización a
// Freezed y solo añade:
//   - Validaciones SPEC-62 antes de escribir.
//   - `createdAt` como server timestamp (no es parte del modelo).
//
// Cierra un bug latente del UserRepository previo: el código hand-
// written ignoraba los 4 campos SPEC-68 al escribir (type, intensity,
// rpe, heartRateAvg). Un usuario que registrara con metadata SPEC-68
// perdía esos datos al recargar.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

class ExerciseLogMapper {
  const ExerciseLogMapper();

  Map<String, dynamic> toMap(ExerciseLog log) {
    _validate(log);
    // Freezed/json_serializable produce el payload con TimestampConverter
    // ya aplicado al campo timestamp. Solo añadimos createdAt como
    // server timestamp para auditoría.
    final map = log.toJson();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  ExerciseLog fromMap(Map<String, dynamic> map) {
    // Freezed se encarga del schema completo, incluyendo nullables y
    // defaults. createdAt no está en el modelo — se ignora silenciosamente.
    return ExerciseLog.fromJson(map);
  }

  void _validate(ExerciseLog log) {
    if (log.id.isEmpty) {
      throw const EmptyField(field: 'ExerciseLog.id');
    }
    if (log.userId.isEmpty) {
      throw const EmptyField(field: 'ExerciseLog.userId');
    }
    if (log.durationMinutes <= 0) {
      throw OutOfRange(
        field: 'ExerciseLog.durationMinutes',
        value: log.durationMinutes,
        min: 1,
        max: 1440, // un día completo
      );
    }
    if (log.rpe != null && (log.rpe! < 1 || log.rpe! > 10)) {
      throw OutOfRange(
        field: 'ExerciseLog.rpe',
        value: log.rpe!,
        min: 1,
        max: 10,
      );
    }
    if (log.heartRateAvg != null && log.heartRateAvg! < 30) {
      throw OutOfRange(
        field: 'ExerciseLog.heartRateAvg',
        value: log.heartRateAvg!,
        min: 30,
        max: 250,
      );
    }
    const tolerance = Duration(seconds: 60);
    final maxAllowed = DateTime.now().add(tolerance);
    if (log.timestamp.isAfter(maxAllowed)) {
      throw FutureTimestamp(
        field: 'ExerciseLog.timestamp',
        value: log.timestamp,
        toleranceFromNow: tolerance,
      );
    }
  }
}
