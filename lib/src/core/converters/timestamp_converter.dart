import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class OptionalTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const OptionalTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    // Si el JSON es un Timestamp de Firestore
    if (json is Timestamp) return json.toDate();
    // Si el JSON ya viene como String ISO8601 (caso raro en Firestore pero posible en mocks)
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) => date != null ? Timestamp.fromDate(date) : null;
}