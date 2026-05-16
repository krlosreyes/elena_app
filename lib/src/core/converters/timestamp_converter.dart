import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converter para campos `DateTime?` (nullable).
class OptionalTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const OptionalTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;
}

/// Converter para campos `DateTime` requeridos (no-null).
///
/// Permite a Freezed/json_serializable deserializar campos `DateTime`
/// cuando el origen es Firestore (que entrega `Timestamp`, no `String`).
/// Si el campo viene null o malformado, lanza un fallback a epoch (Unix 0).
/// SPEC-60 compliant: el fallback es una constante, no `DateTime.now()`.
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  /// Sentinel epoch (1970-01-01 UTC) — usado cuando el dato persistido
  /// es inválido. No es `DateTime.now()` por la Ley de Factories Puras.
  static final DateTime _epoch =
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) {
      return DateTime.tryParse(json) ?? _epoch;
    }
    return _epoch;
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}
