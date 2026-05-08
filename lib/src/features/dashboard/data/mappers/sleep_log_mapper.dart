// SPEC-50: traductor entre Map<String, dynamic> de Firestore y SleepLog.
//
// Replica el patrón de SPEC-63 (NutritionLogMapper). Con un fix
// silencioso: el código previo en UserRepository.saveSleepLog
// persistía solo (fellAsleep, wokeUp, lastMealTime) + campos
// derivados, e ignoraba los 3 campos opcionales que SPEC-69 introdujo
// (sleepLatencyMinutes, nightAwakenings, subjectiveQuality). Eso
// significaba que un usuario que registrara con SPEC-69 metadata,
// al recargar, perdía esos datos — el SleepLog se reconstruía sin
// ellos. Bug latente cerrado aquí.
//
// El omit-if-null preserva la semántica RF-69: un campo ausente en el
// payload Firestore se lee como null = "no se midió", consistente con
// logs históricos pre-SPEC-69.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

class SleepLogMapper {
  const SleepLogMapper();

  /// Convierte un `SleepLog` del dominio al formato persistido en
  /// Firestore. Valida invariantes de negocio antes de serializar.
  Map<String, dynamic> toMap(SleepLog log) {
    _validate(log);
    final map = <String, dynamic>{
      'fellAsleep': Timestamp.fromDate(log.fellAsleep),
      'wokeUp': Timestamp.fromDate(log.wokeUp),
      'lastMealTime': Timestamp.fromDate(log.lastMealTime),
      // Campos derivados — útiles para queries de Firestore (filtrar
      // por duración, gap, etc.) sin recomputar en el cliente.
      'durationMinutes': log.duration.inMinutes,
      'metabolicGapMinutes': log.metabolicGap.inMinutes,
      'recoveryStatus': log.recoveryStatus,
      'createdAt': FieldValue.serverTimestamp(),
    };
    // SPEC-69: omit-if-null para los 3 campos opcionales. Logs viejos
    // (pre-SPEC-69) y registros rápidos sin metadata no inflan el doc
    // con `null`s explícitos.
    if (log.sleepLatencyMinutes != null) {
      map['sleepLatencyMinutes'] = log.sleepLatencyMinutes;
    }
    if (log.nightAwakenings != null) {
      map['nightAwakenings'] = log.nightAwakenings;
    }
    if (log.subjectiveQuality != null) {
      map['subjectiveQuality'] = log.subjectiveQuality;
    }
    return map;
  }

  /// Reconstruye un `SleepLog` desde un payload de Firestore.
  /// El `docId` se usa como `id` del log — Firestore es la fuente de
  /// verdad de la identidad.
  SleepLog fromMap(Map<String, dynamic> map, {required String docId}) {
    final fellAsleep = _toDateTime(map['fellAsleep']);
    final wokeUp = _toDateTime(map['wokeUp']);
    final lastMealTime = _toDateTime(map['lastMealTime']);

    return SleepLog(
      id: docId,
      fellAsleep: fellAsleep,
      wokeUp: wokeUp,
      lastMealTime: lastMealTime,
      sleepLatencyMinutes: _toInt(map['sleepLatencyMinutes']),
      nightAwakenings: _toInt(map['nightAwakenings']),
      subjectiveQuality: _toInt(map['subjectiveQuality']),
    );
    // No llamamos _validate aquí: el constructor de SleepLog ya valida
    // las invariantes SPEC-69 (rangos, no negativos) — duplicarlo aquí
    // sería redundante y la única invariante adicional de mapper
    // (`id` no vacío) ya está cubierta por el `required String docId`.
  }

  void _validate(SleepLog log) {
    // SPEC-62: errores tipados.
    if (log.id.isEmpty) {
      throw const EmptyField(field: 'SleepLog.id');
    }
    // El cruce de medianoche es válido (la propiedad `duration` lo
    // maneja añadiendo 1 día). Pero `wokeUp == fellAsleep` exacto es
    // sospechoso de error de captura.
    if (log.duration == Duration.zero) {
      throw InvalidValue(
        field: 'SleepLog.duration',
        value: '0 minutes',
      );
    }
  }

  static DateTime _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      return DateTime.tryParse(v) ?? _epoch();
    }
    return _epoch();
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime _epoch() =>
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
