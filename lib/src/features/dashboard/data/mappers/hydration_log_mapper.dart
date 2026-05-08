// SPEC-50.1: traductor entre Map<String, dynamic> y HydrationLog.
//
// Validaciones SPEC-62 aplicadas: amountInLiters > 0, timestamp no
// puede estar más allá de la tolerancia desde ahora.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';

class HydrationLogMapper {
  const HydrationLogMapper();

  /// Convierte un `HydrationLog` al formato persistido en Firestore.
  /// Valida invariantes de negocio antes de serializar.
  Map<String, dynamic> toMap(HydrationLog log) {
    _validate(log);
    return {
      'amount': log.amountInLiters,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'type': log.type,
      'serverAt': FieldValue.serverTimestamp(),
    };
  }

  /// Reconstruye un `HydrationLog` desde un payload de Firestore.
  HydrationLog fromMap(Map<String, dynamic> map) {
    final amount = _toDouble(map['amount']) ?? 0.0;
    final timestamp = _toDateTime(map['timestamp']);
    final type = (map['type'] as String?) ?? 'Agua';

    return HydrationLog(
      amountInLiters: amount,
      timestamp: timestamp,
      type: type,
    );
  }

  void _validate(HydrationLog log) {
    if (log.amountInLiters <= 0) {
      throw OutOfRange(
        field: 'HydrationLog.amountInLiters',
        value: log.amountInLiters,
        min: 0.0001, // > 0 estrictamente
        max: double.infinity,
      );
    }
    const tolerance = Duration(seconds: 60);
    final maxAllowed = DateTime.now().add(tolerance);
    if (log.timestamp.isAfter(maxAllowed)) {
      throw FutureTimestamp(
        field: 'HydrationLog.timestamp',
        value: log.timestamp,
        toleranceFromNow: tolerance,
      );
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      return DateTime.tryParse(v) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
